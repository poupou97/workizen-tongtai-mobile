import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../commerce/commerce_models.dart';
import '../../commerce/import/commerce_import.dart';
import '../../commerce/import/commerce_source_resolver.dart';
import '../../core/screen_data_controller.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../providers/tongtai_commerce_provider.dart';
import '../../providers/tongtai_inventory_provider.dart';
import '../../providers/tongtai_orders_provider.dart';
import '../../providers/tongtai_data_invalidation.dart';
import '../widgets/tongtai_screen_data.dart';

/// **Nhập dữ liệu cửa hàng** — WTM-326 (C2 · Epic WTM-324).
/// `IMPLEMENTATION_LEVEL=L3`.
///
/// ## Ngôn ngữ nghiệp vụ, không phải màn ETL (§27)
///
/// *"100 sản phẩm đã sẵn sàng"*, không phải *"parsed 100 rows"*. ⛔ Không
/// expose: CSV parser · schema · foreign key · canonical mapping · import job
/// internals.
///
/// Số dòng và tên bảng **có** hiện, nhưng ở cỡ chữ nhỏ dưới câu tiếng Việt —
/// dành cho ai muốn mở Excel ra sửa, không phải nội dung chính.
///
/// ## Xem trước là một bước riêng, không phải một hộp thoại
///
/// Người bán phải **thấy** trước khi nhập (§12). Gộp hai bước lại thành một
/// nút "Nhập" kèm hộp thoại xác nhận sẽ biến việc xem xét thành việc bấm OK.
class TongtaiImportScreen extends ConsumerStatefulWidget {
  const TongtaiImportScreen({super.key, this.pickFile});

  /// Chọn file **và đọc nội dung**.
  ///
  /// Một seam chứ không phải "chọn đường dẫn rồi đọc trong widget": I/O thật
  /// khởi động từ callback của widget chạy trong vùng fake-async của test và
  /// không bao giờ xong — cùng lý do `TongtaiBackupScreen` có seam này.
  final Future<PickedImportFile?> Function()? pickFile;

  @override
  ConsumerState<TongtaiImportScreen> createState() =>
      _TongtaiImportScreenState();
}

/// Một file người bán đã chọn.
@immutable
class PickedImportFile {
  const PickedImportFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class _TongtaiImportScreenState extends ConsumerState<TongtaiImportScreen> {
  bool _busy = false;
  CommerceImportPreview? _preview;
  CommerceImportResult? _result;

  /// `true` khi bộ đang xem trước là bộ mẫu — quyết định cờ `isDemo` của lần
  /// nhập. Cờ nằm ở **lần nhập**, không ở từng dòng.

  Future<PickedImportFile?> _defaultPick() async {
    final file = await openFile();
    if (file == null) return null;
    return PickedImportFile(name: file.name, bytes: await file.readAsBytes());
  }

  Future<void> _readPicked() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _result = null;
    });

    CommerceImportPreview? preview;
    final failure = await runTongtaiAction(
      () async {
        final picked = await (widget.pickFile ?? _defaultPick)();
        if (picked == null) return;

        // App tự nhận file danh mục hay file sàn (WTM-322). Bắt người bán tự
        // khai loại file là đẩy việc phân loại sang người ít có khả năng phân
        // loại nhất.
        final source = CommerceSourceResolver.resolve(
          bytes: picked.bytes,
          fileName: picked.name,
          now: DateTime.now(),
          knownProducts: await ref.read(productRepositoryProvider).loadAll(),
          existingOrderIds: {
            for (final o in await ref.read(orderRepositoryProvider).loadAll())
              o.id,
          },
        );
        preview = await source.read();
      },
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'import',
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      if (preview != null) {
        _preview = preview;
      }
    });
    if (failure != null) showTongtaiFailure(context, failure);
  }

  Future<void> _import() async {
    final preview = _preview;
    if (_busy || preview == null) return;
    setState(() => _busy = true);

    CommerceImportResult? result;
    final failure = await runTongtaiAction(
      () async => result = await ref
          .read(commerceImporterProvider)
          .apply(
            preview,
            // Màn này chỉ nhận file của người bán. Bộ đóng kèm đi đường
            // "Nạp dữ liệu mẫu" và tự khai `bundledDemo` ở đó.
            sourceVendor: ImportVendor.localFile,
          ),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'import',
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = result;
      if (result != null) _preview = null;
    });

    // Một lần nhập đổi Home, Inventory, Producer, Finance và mọi cơ hội. Chỉ
    // làm mới màn này sẽ để mọi màn khác nói con số cũ (WTM-149 defect 1).
    invalidateBusinessDataProviders(ref);
    ref.invalidate(importJobsProvider);

    if (failure != null) {
      showTongtaiFailure(context, failure);
      return;
    }
    final done = result;
    if (done != null) {
      _say(context.l10n.importDone(done.counts['products'] ?? 0));
    }
  }

  Future<void> _undo(ImportJob job) async {
    if (_busy) return;
    setState(() => _busy = true);

    var removed = 0;
    final failure = await runTongtaiAction(
      () async {
        final counts = await ref
            .read(commerceRepositoryProvider)
            .deleteImport(job.id);
        removed = counts.values.fold(0, (sum, v) => sum + v);
      },
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'import',
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = null;
    });
    invalidateBusinessDataProviders(ref);
    ref.invalidate(importJobsProvider);

    if (failure != null) {
      showTongtaiFailure(context, failure);
      return;
    }
    _say(context.l10n.importResetDone(removed));
  }

  void _say(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preview = _preview;
    final jobs = ref.watch(importJobsProvider);

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(l10n.titleImport),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('import-list'),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.importIntro,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // ⛔ WTM-343 — KHÔNG còn nút "Dùng bộ dữ liệu mẫu" ở đây.
            //
            // Bộ 100 sản phẩm là **dữ liệu mẫu**, và dữ liệu mẫu có đúng một
            // chủ: "Nạp dữ liệu mẫu" trong Thêm. Màn này chỉ làm một việc —
            // nhận file Excel **của người bán**. Hai lối vào cho một khái niệm
            // là hai chỗ để chọn nhầm (P-27).
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                key: const Key('import-pick-file'),
                onPressed: _busy ? null : _readPicked,
                child: Text(l10n.importPickFile),
              ),
            ),
            if (preview != null) ...[
              const SizedBox(height: 16),
              _PreviewCard(preview: preview, busy: _busy, onImport: _import),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              _ResultCard(result: _result!),
            ],
            const SizedBox(height: 24),
            Text(
              l10n.importHistory,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
            Text(
              // Luật "mỗi đường xoá khai phạm vi" (WTM-307) nói với con người
              // ở đây, không chỉ nói trong comment của repository.
              l10n.importResetConfirm,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            switch (jobs) {
              AsyncData(value: final list) when list.isEmpty => Text(
                l10n.stateEmpty,
                key: const Key('import-history-empty'),
                style: const TextStyle(
                  fontSize: 13,
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              ),
              AsyncData(value: final list) => Column(
                children: [
                  for (final job in list)
                    _JobRow(job: job, busy: _busy, onUndo: () => _undo(job)),
                ],
              ),
              _ => const SizedBox.shrink(),
            },
          ],
        ),
      ),
    );
  }
}

/// Xem trước — **cái gì có trong file**, bằng ngôn ngữ nghiệp vụ.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.preview,
    required this.busy,
    required this.onImport,
  });

  final CommerceImportPreview preview;
  final bool busy;
  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final counts = preview.counts;

    return Container(
      key: const Key('import-preview'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TongtaiDesignTokens.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preview.sourceName,
            style: const TextStyle(
              fontSize: 13,
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.importReadyProducts(counts['products'] ?? 0),
            key: const Key('import-preview-products'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          for (final line in [
            if ((counts['variants'] ?? 0) > 0)
              l10n.importReadyVariants(counts['variants']!),
            if ((counts['quotes'] ?? 0) > 0)
              l10n.importReadySuppliers(counts['quotes']!),
            if ((counts['orders'] ?? 0) > 0)
              l10n.importReadyOrders(counts['orders']!),
            if ((counts['customers'] ?? 0) > 0)
              l10n.importReadyCustomers(counts['customers']!),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '· $line',
                style: const TextStyle(
                  fontSize: 13,
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              ),
            ),
          if (preview.errors.isNotEmpty) ...[
            const SizedBox(height: 10),
            _IssueBlock(
              key: const Key('import-preview-errors'),
              headline: l10n.importBlocked(preview.errors.length),
              issues: preview.errors,
              color: Colors.red,
            ),
          ],
          if (preview.warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            _IssueBlock(
              key: const Key('import-preview-warnings'),
              headline: l10n.importWarned(preview.warnings.length),
              issues: preview.warnings,
              color: Colors.orange,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const Key('import-confirm'),
              // Có lỗi **không** chặn cả file: 100 sản phẩm không đáng bị từ
              // chối vì một đơn hàng hỏng. Chỉ khi không còn gì hợp lệ thì nút
              // mới tắt.
              onPressed: busy || !preview.hasAnythingToImport
                  ? null
                  : () => onImport(),
              child: Text(
                busy
                    ? l10n.importRunning
                    : preview.hasAnythingToImport
                    ? l10n.importConfirm
                    : l10n.importNothing,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueBlock extends StatelessWidget {
  const _IssueBlock({
    super.key,
    required this.headline,
    required this.issues,
    required this.color,
  });

  final String headline;
  final List<ImportIssue> issues;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Ba dòng đầu là đủ để hiểu chuyện gì; ba mươi dòng thì không ai đọc.
    final shown = issues.take(3).toList();
    final rest = issues.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headline,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        for (final issue in shown)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${issue.subject}: ${issue.detail}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TongtaiDesignTokens.lightTextPrimary,
                  ),
                ),
                // Chỗ sửa — nhỏ, cho ai muốn mở Excel ra. Không phải nội dung
                // chính (§27).
                if (issue.sheet != null && issue.rowNumber != null)
                  Text(
                    context.l10n.importIssueLocation(
                      issue.sheet!,
                      issue.rowNumber!,
                    ),
                    style: const TextStyle(
                      fontSize: 11,
                      color: TongtaiDesignTokens.lightTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
        if (rest > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              context.l10n.importMoreIssues(rest),
              style: const TextStyle(
                fontSize: 12,
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final CommerceImportResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      key: const Key('import-result'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.importDone(result.counts['products'] ?? 0),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          if (result.skipped.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l10n.importBlocked(result.skipped.length),
              style: const TextStyle(
                fontSize: 12,
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job, required this.busy, required this.onUndo});

  final ImportJob job;
  final bool busy;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.sourceFile ?? l10n.stateEmpty,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TongtaiDesignTokens.lightTextPrimary,
                  ),
                ),
                Text(
                  '${job.importedAt.day}/${job.importedAt.month} · '
                  '${l10n.importRecordCount(job.totalRecords)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TongtaiDesignTokens.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: TextButton(
              key: Key('import-undo-${job.id}'),
              onPressed: busy ? null : onUndo,
              child: Text(l10n.importReset),
            ),
          ),
        ],
      ),
    );
  }
}
