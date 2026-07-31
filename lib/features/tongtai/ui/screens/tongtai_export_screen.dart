import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../consumer/customer.dart';
import '../../consumer/customer_order.dart';
import '../../core/tongtai_formatters.dart';
import '../../providers/tongtai_consumer_provider.dart';
import '../../providers/tongtai_inventory_provider.dart';
import '../../providers/tongtai_orders_provider.dart';
import '../../export/backup_crypto.dart';
import '../../export/csv_delivery.dart';
import '../../export/csv_exporter.dart';
import '../../export/export_history_store.dart';
import '../../inventory/product.dart';
import '../../core/screen_data_controller.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../widgets/tongtai_screen_data.dart';

/// Date-range presets for the orders export (WTM-99 AC3).
enum ExportRange {
  all,
  last30Days,
  last90Days;

  String label(AppStrings l10n) => switch (this) {
    ExportRange.all => l10n.exportRangeAll,
    ExportRange.last30Days => l10n.exportRangeLast30,
    ExportRange.last90Days => l10n.exportRangeLast90,
  };

  DateTime? fromFor(DateTime now) => switch (this) {
    ExportRange.all => null,
    ExportRange.last30Days => now.subtract(const Duration(days: 30)),
    ExportRange.last90Days => now.subtract(const Duration(days: 90)),
  };
}

/// Data Export screen (WTM-99, Phase 2 per D-10).
///
/// Pick a data set (AC1), for orders pick a date range (AC3), then Export:
/// the CSV (headers + UTF-8 BOM — AC2) goes out through the OS share sheet —
/// the local-first email option (AC4) — and the run is logged into the
/// viewable history below (AC5). Local-first: data comes from the in-memory
/// sources; nothing leaves the device except through the app the seller
/// picks in the share sheet.
class TongtaiExportScreen extends ConsumerStatefulWidget {
  const TongtaiExportScreen({
    super.key,
    this.delivery,
    this.history,
    this.customers,
    this.products,
    this.orders,
    this.clock,
    this.crypto,
  });

  /// Injectable delivery; defaults to the share sheet.
  final TongtaiCsvDelivery? delivery;

  /// Injectable history store; defaults to an in-memory store owned by the
  /// screen (the SharedPreferences store is wired by the More screen).
  final TongtaiExportHistoryStore? history;

  final List<Customer>? customers;
  final List<Product>? products;
  final List<CustomerOrder>? orders;

  /// Injectable clock for range presets + timestamps.
  final DateTime Function()? clock;

  /// Injectable backup encryption (WTM-100); tests pass a low-iteration
  /// instance so PBKDF2 stays fast. Defaults to the production parameters.
  final BackupCrypto? crypto;

  @override
  ConsumerState<TongtaiExportScreen> createState() =>
      _TongtaiExportScreenState();
}

class _TongtaiExportScreenState extends ConsumerState<TongtaiExportScreen> {
  static const _exporter = TongtaiCsvExporter();

  late final TongtaiCsvDelivery _delivery;
  late final TongtaiExportHistoryStore _history;
  late final DateTime Function() _clock;

  TongtaiExportType _type = TongtaiExportType.customers;
  // WTM-144 (P0 §1): real mode exports the PRODUCTION repositories' rows —
  // the old kSample fallbacks silently exported fixture data instead of the
  // user's business.
  ExportRange _range = ExportRange.all;
  bool _busy = false;

  /// Everything the screen exports, read as one unit (WTM-148). Exporting a
  /// dataset we could not read would ship an empty CSV that looks like an
  /// empty business — so a failed read blocks the export and says why.
  late final ScreenDataController<_ExportData> _data;

  _ExportData get _loaded =>
      _data.state.value ??
      (
        customers: const [],
        products: const [],
        orders: const [],
        records: const [],
      );

  List<Customer> get _customers => _loaded.customers;
  List<Product> get _products => _loaded.products;
  List<CustomerOrder> get _orders => _loaded.orders;
  List<TongtaiExportRecord> get _records => _loaded.records;

  /// WTM-100 (Founder-approved): optionally encrypt the export with a
  /// passphrase before it leaves the app. The passphrase never leaves the
  /// device and is never stored.
  bool _encrypt = false;
  final TextEditingController _passphrase = TextEditingController();

  @override
  void dispose() {
    _data.dispose();
    _passphrase.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _delivery = widget.delivery ?? const ShareSheetCsvDelivery();
    _history = widget.history ?? InMemoryTongtaiExportHistoryStore();
    _clock = widget.clock ?? DateTime.now;
    _data = ScreenDataController<_ExportData>(
      _read,
      // Injected datasets ⇒ everything but the history is already in hand.
      initialValue: widget.customers == null
          ? null
          : (
              customers: widget.customers!,
              products: widget.products ?? const [],
              orders: widget.orders ?? const [],
              records: const <TongtaiExportRecord>[],
            ),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'export',
    )..start();
  }

  Future<_ExportData> _read() async {
    // Injected lists (tests) win; otherwise read the same repositories every
    // other screen uses (one source, WTM-144).
    return (
      customers:
          widget.customers ??
          await ref.read(customerRepositoryProvider).loadAll(),
      products:
          widget.products ??
          await ref.read(productRepositoryProvider).loadAll(),
      orders:
          widget.orders ?? await ref.read(orderRepositoryProvider).loadAll(),
      records: await _history.load(),
    );
  }

  TongtaiCsv _buildCsv() {
    switch (_type) {
      case TongtaiExportType.customers:
        return _exporter.customersCsv(_customers);
      case TongtaiExportType.products:
        return _exporter.productsCsv(_products);
      case TongtaiExportType.orders:
        return _exporter.ordersCsv(_orders, from: _range.fromFor(_clock()));
    }
  }

  Future<void> _export() async {
    if (_busy) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    // WTM-148: this used to be `try { … } finally { … }` with NO catch — a
    // failed encryption, a denied share sheet or an unwritable history file
    // stopped the spinner and looked exactly like a successful export.
    final failure = await runTongtaiAction(
      () => _runExport(l10n),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'export',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) showTongtaiFailure(context, failure, onRetry: _export);
  }

  Future<void> _runExport(AppStrings l10n) async {
    {
      final now = _clock();
      var csv = _buildCsv();
      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      var fileName = '${_type.fileStem}-$stamp.csv';
      if (_encrypt) {
        final passphrase = _passphrase.text;
        if (passphrase.length < 6) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(l10n.exportPassphraseTooShort)),
            );
          return;
        }
        // Armored container (WTM-100) — flows through the same delivery seam.
        csv = TongtaiCsv(
          content: await (widget.crypto ?? const BackupCrypto()).encryptArmored(
            csv.content,
            passphrase,
          ),
          rowCount: csv.rowCount,
        );
        fileName = '$fileName.ttbk';
      }
      await _delivery.deliver(
        csv,
        fileName,
        l10n.exportShareSubject(_type.label(l10n.languageCode), stamp),
      );
      await _history.add(
        TongtaiExportRecord(
          type: _type,
          fileName: fileName,
          rowCount: csv.rowCount,
          exportedAt: now,
        ),
      );
      await _data.refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.exportDoneSnack(csv.rowCount, fileName))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(l10n.titleExport),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _data,
          builder: (context, _) => TongtaiScreenData<_ExportData>(
            prefix: 'export',
            state: _data.state,
            onRetry: _data.retry,
            builder: (context, _) => _form(context, l10n),
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context, AppStrings l10n) {
    return ListView(
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      children: [
        Text(
          l10n.exportPickDataSet,
          style: TongtaiDesignTokens.smallStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: TongtaiDesignTokens.lightTextPrimary,
          ),
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing2),
        Wrap(
          spacing: TongtaiDesignTokens.spacing2,
          runSpacing: TongtaiDesignTokens.spacing1,
          children: [
            for (final type in TongtaiExportType.values)
              ChoiceChip(
                key: Key('export-type-${type.name}'),
                label: Text(type.label(l10n.languageCode)),
                selected: _type == type,
                onSelected: (_) => setState(() => _type = type),
              ),
          ],
        ),
        if (_type == TongtaiExportType.orders) ...[
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          Text(
            l10n.exportDateRange,
            style: TongtaiDesignTokens.smallStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          Wrap(
            spacing: TongtaiDesignTokens.spacing2,
            children: [
              for (final range in ExportRange.values)
                ChoiceChip(
                  key: Key('export-range-${range.name}'),
                  label: Text(range.label(l10n)),
                  selected: _range == range,
                  onSelected: (_) => setState(() => _range = range),
                ),
            ],
          ),
        ],
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        // ── Encryption (WTM-100) ─────────────────────────────────────
        SwitchListTile(
          key: const Key('export-encrypt-toggle'),
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.exportEncryptTitle,
            style: TongtaiDesignTokens.smallStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          subtitle: Text(
            l10n.exportEncryptHint,
            style: TongtaiDesignTokens.captionStyle.copyWith(
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
          value: _encrypt,
          onChanged: (v) => setState(() => _encrypt = v),
        ),
        if (_encrypt) ...[
          TextField(
            key: const Key('export-passphrase'),
            controller: _passphrase,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.exportPassphraseLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
        ],
        const SizedBox(height: TongtaiDesignTokens.spacing2),
        FilledButton.icon(
          key: const Key('export-run'),
          onPressed: _busy ? null : _export,
          style: FilledButton.styleFrom(
            backgroundColor: TongtaiDesignTokens.producerGreen,
            minimumSize: const Size.fromHeight(
              TongtaiDesignTokens.buttonHeight,
            ),
          ),
          icon: const Icon(Icons.ios_share),
          label: Text(_busy ? l10n.exportRunning : l10n.exportRun),
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing2),
        Text(
          l10n.exportCsvHint,
          style: TongtaiDesignTokens.captionStyle.copyWith(
            color: TongtaiDesignTokens.lightTextSecondary,
          ),
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing4),
        Text(
          l10n.exportHistory,
          style: TongtaiDesignTokens.smallStyle.copyWith(
            fontWeight: FontWeight.w700,
            color: TongtaiDesignTokens.lightTextPrimary,
          ),
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing2),
        if (_records.isEmpty)
          Text(
            l10n.exportHistoryEmpty,
            style: TongtaiDesignTokens.captionStyle.copyWith(
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          )
        else
          for (final record in _records)
            Padding(
              padding: const EdgeInsets.only(
                bottom: TongtaiDesignTokens.spacing2,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 18,
                    color: TongtaiDesignTokens.lightTextSecondary,
                  ),
                  const SizedBox(width: TongtaiDesignTokens.spacing2),
                  Expanded(
                    child: Text(
                      l10n.exportHistoryLine(
                        record.fileName,
                        record.type.label(l10n.languageCode),
                        record.rowCount,
                        TongtaiFormatters.isoDate(record.exportedAt),
                      ),
                      style: TongtaiDesignTokens.captionStyle.copyWith(
                        color: TongtaiDesignTokens.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// Everything the Export screen reads in one go.
typedef _ExportData = ({
  List<Customer> customers,
  List<Product> products,
  List<CustomerOrder> orders,
  List<TongtaiExportRecord> records,
});
