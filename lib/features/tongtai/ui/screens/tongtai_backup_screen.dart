library;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../core/screen_data_controller.dart';
import '../../core/tongtai_formatters.dart';
import '../../export/backup_format.dart';
import '../../export/backup_service.dart';
import '../../export/csv_delivery.dart';
import '../../export/csv_exporter.dart';
import '../../providers/tongtai_backup_provider.dart';
import '../../providers/tongtai_data_invalidation.dart';
import '../widgets/tongtai_screen_data.dart';

/// A backup file the user chose: where it came from, and what is in it.
@immutable
class TongtaiPickedBackup {
  const TongtaiPickedBackup({required this.path, required this.content});

  /// Shown to nobody and reported to nobody — kept only so a future "restore
  /// again" could reuse it.
  final String path;

  final String content;
}

/// Backup & restore (WTM-164, ADR-TON-018).
///
/// Restore is **Replace**: one complete snapshot goes in and the business
/// becomes exactly that. The screen is built around making that consequence
/// impossible to miss — the file is fully validated and *previewed* before any
/// confirmation is offered, the confirmation names what will happen, and the
/// safety-backup location is shown the moment it is done.
///
/// Failure states come from the shared seam (ADR-TON-017): a rejected file is
/// a classified refusal with a reason, never a silent no-op.
class TongtaiBackupScreen extends ConsumerStatefulWidget {
  const TongtaiBackupScreen({super.key, this.pickFile, this.delivery});

  /// Chooses a backup file **and reads it**.
  ///
  /// One seam rather than "pick a path, then read it in the widget": real file
  /// I/O started from a widget callback runs in the test framework's fake-async
  /// zone and never completes, so a widget that reads files cannot be widget
  /// tested at all. Production does picker + read here; tests hand back the
  /// content directly.
  final Future<TongtaiPickedBackup?> Function()? pickFile;

  /// Injectable delivery for the "create a backup" half.
  final TongtaiCsvDelivery? delivery;

  @override
  ConsumerState<TongtaiBackupScreen> createState() =>
      _TongtaiBackupScreenState();
}

class _TongtaiBackupScreenState extends ConsumerState<TongtaiBackupScreen> {
  final TextEditingController _passphrase = TextEditingController();

  TongtaiPickedBackup? _picked;
  BackupValidation? _validation;
  BackupRestoreReport? _report;
  bool _busy = false;

  @override
  void dispose() {
    _passphrase.dispose();
    super.dispose();
  }

  TongtaiBackupService get _service => ref.read(tongtaiBackupServiceProvider);

  /// The production chooser: `file_selector` (maintained by the Flutter team).
  ///
  /// Not `file_picker`: its Windows implementation pins `win32 ^5` while
  /// `share_plus` needs `^6`, and Dart compiles every platform's sources even
  /// for an Android build — so the app would not build at all. `file_selector`
  /// has no such conflict.
  ///
  /// No `XTypeGroup` filter: Android's document picker treats an unknown
  /// extension as "no matching files", which would leave the seller staring at
  /// an empty chooser holding a backup they can see in their file manager.
  /// The file is validated immediately anyway, so a wrong pick is a clear
  /// refusal rather than a silent one.
  Future<TongtaiPickedBackup?> _defaultPick() async {
    final file = await openFile();
    if (file == null) return null;
    return TongtaiPickedBackup(
      path: file.path,
      content: await file.readAsString(),
    );
  }

  // ── create ───────────────────────────────────────────────────────────────

  Future<void> _createBackup() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    final failure = await runTongtaiAction(
      () async {
        final passphrase = _passphrase.text.trim();
        final armored = await _service.createBackup(
          passphrase: passphrase.isEmpty ? null : passphrase,
        );
        final now = DateTime.now();
        String two(int v) => v.toString().padLeft(2, '0');
        final name =
            'tongtai-sao-luu-${now.year}${two(now.month)}${two(now.day)}.ttbk';
        await (widget.delivery ?? const ShareSheetCsvDelivery()).deliver(
          TongtaiCsv(content: armored, rowCount: 0),
          name,
          l10n.backupCreate,
        );
      },
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'backup',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) showTongtaiFailure(context, failure);
  }

  // ── choose + validate ────────────────────────────────────────────────────

  Future<void> _chooseFile() async {
    if (_busy) return;
    setState(() => _busy = true);
    TongtaiPickedBackup? picked;
    final failure = await runTongtaiAction(
      () async => picked = await (widget.pickFile ?? _defaultPick)(),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'backup',
    );
    if (!mounted) return;
    if (failure != null) {
      setState(() => _busy = false);
      showTongtaiFailure(context, failure);
      return;
    }
    if (picked == null) {
      setState(() => _busy = false);
      return;
    }
    setState(() {
      _picked = picked;
      _validation = null;
      _report = null;
    });
    await _validatePicked();
  }

  /// Reads and validates the chosen file. **Read-only** — nothing here can
  /// touch the database, which is why the preview can be shown before any
  /// warning is accepted.
  Future<void> _validatePicked() async {
    final picked = _picked;
    if (picked == null) return;
    setState(() => _busy = true);
    BackupValidation? validation;
    final failure = await runTongtaiAction(
      () async {
        final armored = picked.content;
        final passphrase = _passphrase.text.trim();
        validation = await _service.validate(
          armored,
          passphrase: passphrase.isEmpty ? null : passphrase,
        );
      },
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'backup',
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _validation = validation;
    });
    if (failure != null) showTongtaiFailure(context, failure);
  }

  /// Loads the pre-restore safety copy back into the preview (WTM-173).
  ///
  /// WTM-164 creates and verifies a safety copy before replacing anything, but
  /// it lands in the app's private documents directory — a place the system
  /// file picker cannot reach. So the one file that exists to undo a mistaken
  /// restore was the one file the seller could not open. This reads it through
  /// the same vault that wrote it.
  ///
  /// It deliberately stops at the preview: applying it is still a destructive
  /// Replace, and a one-tap undo that silently overwrites is the same mistake
  /// pointing the other way.
  Future<void> _openSafetyCopy(String path) async {
    if (_busy) return;
    setState(() => _busy = true);
    String? armored;
    final failure = await runTongtaiAction(
      () async => armored = await _service.vault.read(path),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'backup',
    );
    if (!mounted) return;
    if (failure != null) {
      setState(() => _busy = false);
      showTongtaiFailure(context, failure);
      return;
    }
    setState(() {
      _busy = false;
      _picked = TongtaiPickedBackup(path: path, content: armored!);
      _validation = null;
      _report = null;
    });
    await _validatePicked();
  }

  // ── restore ──────────────────────────────────────────────────────────────

  Future<void> _restore() async {
    final validation = _validation;
    if (validation == null || !validation.isRestorable) return;
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.backupConfirmTitle),
        content: Text(l10n.backupConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TtDangerButton(
            key: const Key('backup-confirm-replace'),
            label: l10n.backupReplaceAction,
            expand: false,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    BackupRestoreReport? report;
    final failure = await runTongtaiAction(
      () async => report = await _service.restore(validation),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'backup',
    );
    if (!mounted) return;
    if (failure != null) {
      setState(() => _busy = false);
      showTongtaiFailure(context, failure);
      return;
    }
    // Every cached context/twin/provider now describes a business that no
    // longer exists (WTM-149 defect 1) — drop them before anything repaints.
    invalidateBusinessDataProviders(ref);
    setState(() {
      _busy = false;
      _report = report;
    });
  }

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        title: Text(l10n.titleBackup),
        elevation: 0,
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(TtSpace.x4),
          children: [
            _Section(title: l10n.backupCreate, body: l10n.backupCreateHint),
            const SizedBox(height: TtSpace.x3),
            TextField(
              key: const Key('backup-passphrase-field'),
              controller: _passphrase,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.backupPassphraseLabel,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _validatePicked(),
            ),
            const SizedBox(height: TtSpace.x3),
            FilledButton.icon(
              key: const Key('backup-action-create'),
              onPressed: _busy ? null : _createBackup,
              icon: const Icon(Icons.save_alt),
              label: Text(l10n.backupCreate),
            ),
            const Divider(height: TtSpace.x8),
            _Section(title: l10n.backupRestore, body: l10n.backupRestoreHint),
            const SizedBox(height: TtSpace.x3),
            OutlinedButton.icon(
              key: const Key('backup-action-pick'),
              onPressed: _busy ? null : _chooseFile,
              icon: const Icon(Icons.folder_open),
              label: Text(l10n.backupPickFile),
            ),
            if (_busy) ...[
              const SizedBox(height: TtSpace.x4),
              Center(child: TongtaiInlineBusy(label: l10n.backupRestoring)),
            ],
            if (_report != null) ...[
              const SizedBox(height: TtSpace.x4),
              _RestoreDone(
                report: _report!,
                onUndo: () => _openSafetyCopy(_report!.safetyBackupPath),
              ),
            ] else if (_validation != null) ...[
              const SizedBox(height: TtSpace.x4),
              _Preview(
                validation: _validation!,
                onRetryPassphrase: _validatePicked,
                onReplace: _restore,
                busy: _busy,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TtType.bodyLarge.copyWith(
          fontWeight: FontWeight.w700,
          color: TtColors.textPrimary,
        ),
      ),
      const SizedBox(height: TtSpace.x1),
      Text(body, style: TtType.body.copyWith(color: TtColors.textSecondary)),
    ],
  );
}

/// Read-only preview: what the file is, whether it can be used, and — only
/// when it can — the destructive action, under its warning.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.validation,
    required this.onRetryPassphrase,
    required this.onReplace,
    required this.busy,
  });

  final BackupValidation validation;
  final Future<void> Function() onRetryPassphrase;
  final Future<void> Function() onReplace;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final manifest = validation.manifest;
    final contents = validation.contents;
    final problem = validation.firstProblem;

    return Container(
      key: const Key('backup-preview'),
      padding: const EdgeInsets.all(TtSpace.x4),
      decoration: BoxDecoration(
        color: TtColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(TtRadius.md),
        border: Border.all(color: TtColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.backupPreviewTitle,
            style: TtType.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: TtColors.textPrimary,
            ),
          ),
          const SizedBox(height: TtSpace.x3),
          if (manifest != null) ...[
            _Row(
              label: l10n.backupCreatedAt,
              value: TongtaiFormatters.isoDate(manifest.createdAt),
            ),
            _Row(
              label: l10n.backupAppVersion,
              value:
                  '${manifest.appVersion} / '
                  'v${manifest.databaseSchemaVersion}',
            ),
            _Row(
              label: manifest.encryption == BackupEncryption.aesGcm
                  ? l10n.backupEncrypted
                  : l10n.backupNotEncrypted,
              value: manifest.checksumAlgorithm,
            ),
            if (validation.compatibility?.canRestore ?? false)
              Row(
                key: const Key('backup-compatible'),
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: TtColors.success,
                  ),
                  const SizedBox(width: TtSpace.x2),
                  Expanded(
                    child: Text(
                      l10n.backupCompatible,
                      style: TtType.body.copyWith(color: TtColors.textPrimary),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: TtSpace.x2),
            Text(
              l10n.backupIntegrityNote,
              style: TtType.caption.copyWith(color: TtColors.textSecondary),
            ),
            const SizedBox(height: TtSpace.x3),
          ],
          if (problem != null) ...[
            Container(
              key: const Key('backup-rejected'),
              padding: const EdgeInsets.all(TtSpace.x3),
              decoration: BoxDecoration(
                color: TtColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(TtRadius.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.backupRejected,
                    style: TtType.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: TtColors.danger,
                    ),
                  ),
                  const SizedBox(height: TtSpace.x1),
                  Text(
                    l10n.backupProblem(problem.code),
                    key: const Key('backup-rejected-reason'),
                    style: TtType.body.copyWith(color: TtColors.textPrimary),
                  ),
                  // The machine-precise code, as everywhere else in the app:
                  // a technical failure is never traded for a vague sentence.
                  Text(
                    problem.code,
                    style: TtType.caption.copyWith(
                      color: TtColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (problem == BackupProblem.passphraseRequired ||
                problem == BackupProblem.wrongPassphrase) ...[
              const SizedBox(height: TtSpace.x3),
              Text(
                l10n.backupPassphraseNeeded,
                style: TtType.body.copyWith(color: TtColors.textSecondary),
              ),
              const SizedBox(height: TtSpace.x2),
              OutlinedButton(
                key: const Key('backup-action-unlock'),
                onPressed: busy ? null : () => onRetryPassphrase(),
                child: Text(l10n.stateRetry),
              ),
            ],
          ],
          if (contents != null) ...[
            Text(
              l10n.backupContents,
              style: TtType.body.copyWith(
                fontWeight: FontWeight.w700,
                color: TtColors.textPrimary,
              ),
            ),
            const SizedBox(height: TtSpace.x2),
            for (final entry in _labelled(l10n, contents.counts))
              _Row(
                key: Key('backup-count-${entry.key}'),
                label: entry.label,
                value: '${entry.value}',
              ),
            const SizedBox(height: TtSpace.x4),
            Container(
              key: const Key('backup-replace-warning'),
              padding: const EdgeInsets.all(TtSpace.x3),
              decoration: BoxDecoration(
                color: TtColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(TtRadius.sm),
              ),
              child: Text(
                l10n.backupReplaceWarning,
                style: TtType.body.copyWith(color: TtColors.textPrimary),
              ),
            ),
            const SizedBox(height: TtSpace.x3),
            TtDangerButton(
              key: const Key('backup-action-replace'),
              // Nhãn nói HẬU QUẢ, không nói cơ chế.
              label: l10n.backupReplaceAction,
              icon: Icons.swap_horiz,
              onPressed: busy ? null : () => onReplace(),
            ),
          ],
        ],
      ),
    );
  }
}

class _RestoreDone extends StatelessWidget {
  const _RestoreDone({required this.report, required this.onUndo});

  final VoidCallback onUndo;

  final BackupRestoreReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      key: const Key('backup-restore-done'),
      padding: const EdgeInsets.all(TtSpace.x4),
      decoration: BoxDecoration(
        color: TtColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TtRadius.md),
        border: Border.all(color: TtColors.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.backupRestoreDone,
            style: TtType.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: TtColors.textPrimary,
            ),
          ),
          const SizedBox(height: TtSpace.x2),
          for (final entry in _labelled(l10n, report.restored))
            _Row(label: entry.label, value: '${entry.value}'),
          const SizedBox(height: TtSpace.x3),
          Text(
            l10n.backupSafetyCopy,
            style: TtType.body.copyWith(
              fontWeight: FontWeight.w600,
              color: TtColors.textPrimary,
            ),
          ),
          Text(
            report.safetyBackupPath,
            key: const Key('backup-safety-path'),
            style: TtType.caption.copyWith(color: TtColors.textSecondary),
          ),
          const SizedBox(height: TtSpace.x3),
          Text(
            l10n.backupUndoHint,
            style: TtType.caption.copyWith(color: TtColors.textSecondary),
          ),
          const SizedBox(height: TtSpace.x2),
          OutlinedButton.icon(
            key: const Key('backup-action-undo'),
            onPressed: onUndo,
            icon: const Icon(Icons.history, size: 18),
            label: Text(l10n.backupUndoAction),
          ),
        ],
      ),
    );
  }
}

/// Dataset counts with their localized labels, in a stable order.
Iterable<({String key, String label, int value})> _labelled(
  AppStrings l10n,
  Map<String, int> counts,
) sync* {
  const labels = <String, String Function(AppStrings)>{
    BackupDatasets.customers: _customers,
    BackupDatasets.products: _products,
    BackupDatasets.orders: _orders,
    BackupDatasets.goals: _goals,
    BackupDatasets.transactions: _transactions,
    BackupDatasets.favourites: _favourites,
  };
  for (final key in BackupDatasets.all) {
    yield (key: key, label: labels[key]!(l10n), value: counts[key] ?? 0);
  }
}

String _customers(AppStrings l10n) => l10n.datasetCustomers;
String _products(AppStrings l10n) => l10n.datasetProducts;
String _orders(AppStrings l10n) => l10n.datasetOrders;
String _goals(AppStrings l10n) => l10n.datasetGoals;
String _transactions(AppStrings l10n) => l10n.datasetTransactions;
String _favourites(AppStrings l10n) => l10n.datasetFavourites;

class _Row extends StatelessWidget {
  const _Row({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TtType.body.copyWith(color: TtColors.textSecondary),
          ),
        ),
        const SizedBox(width: TtSpace.x2),
        Text(
          value,
          style: TtType.body.copyWith(
            fontWeight: FontWeight.w700,
            color: TtColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}
