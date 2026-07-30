import 'package:flutter/material.dart';

import '../../consumer/customer.dart';
import '../../consumer/customer_directory_service.dart';
import '../../consumer/customer_order.dart';
import '../../core/tongtai_formatters.dart';
import '../../export/backup_crypto.dart';
import '../../export/csv_delivery.dart';
import '../../export/csv_exporter.dart';
import '../../export/export_history_store.dart';
import '../../inventory/product.dart';
import '../../inventory/product_inventory_service.dart';
import '../../navigation/tongtai_design_tokens.dart';

/// Date-range presets for the orders export (WTM-99 AC3).
enum ExportRange {
  all,
  last30Days,
  last90Days;

  String get labelVi => switch (this) {
    ExportRange.all => 'Toàn bộ',
    ExportRange.last30Days => '30 ngày',
    ExportRange.last90Days => '90 ngày',
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
class TongtaiExportScreen extends StatefulWidget {
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
  State<TongtaiExportScreen> createState() => _TongtaiExportScreenState();
}

class _TongtaiExportScreenState extends State<TongtaiExportScreen> {
  static const _exporter = TongtaiCsvExporter();

  late final TongtaiCsvDelivery _delivery;
  late final TongtaiExportHistoryStore _history;
  late final DateTime Function() _clock;

  TongtaiExportType _type = TongtaiExportType.customers;
  ExportRange _range = ExportRange.all;
  List<TongtaiExportRecord> _records = const [];
  bool _busy = false;

  /// WTM-100 (Founder-approved): optionally encrypt the export with a
  /// passphrase before it leaves the app. The passphrase never leaves the
  /// device and is never stored.
  bool _encrypt = false;
  final TextEditingController _passphrase = TextEditingController();

  @override
  void dispose() {
    _passphrase.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _delivery = widget.delivery ?? const ShareSheetCsvDelivery();
    _history = widget.history ?? InMemoryTongtaiExportHistoryStore();
    _clock = widget.clock ?? DateTime.now;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final records = await _history.load();
    if (!mounted) return;
    setState(() => _records = records);
  }

  TongtaiCsv _buildCsv() {
    switch (_type) {
      case TongtaiExportType.customers:
        return _exporter.customersCsv(widget.customers ?? kSampleCustomers);
      case TongtaiExportType.products:
        return _exporter.productsCsv(widget.products ?? kSampleProducts);
      case TongtaiExportType.orders:
        return _exporter.ordersCsv(
          widget.orders ?? kSampleCustomerOrders,
          from: _range.fromFor(_clock()),
        );
    }
  }

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
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
              const SnackBar(
                content: Text('Mật khẩu mã hoá cần tối thiểu 6 ký tự.'),
              ),
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
        'Tổng Tài — xuất ${_type.labelVi} ($stamp)',
      );
      await _history.add(
        TongtaiExportRecord(
          type: _type,
          fileName: fileName,
          rowCount: csv.rowCount,
          exportedAt: now,
        ),
      );
      await _loadHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Đã xuất ${csv.rowCount} dòng — $fileName')),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: const Text('Export Data (CSV)'),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
          children: [
            Text(
              'Chọn dữ liệu cần xuất | Pick a data set',
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
                    label: Text(type.labelVi),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                  ),
              ],
            ),
            if (_type == TongtaiExportType.orders) ...[
              const SizedBox(height: TongtaiDesignTokens.spacing3),
              Text(
                'Khoảng thời gian | Date range',
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
                      label: Text(range.labelVi),
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
                'Mã hoá bằng mật khẩu | Encrypt with passphrase',
                style: TongtaiDesignTokens.smallStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: TongtaiDesignTokens.lightTextPrimary,
                ),
              ),
              subtitle: Text(
                'File .ttbk chỉ mở được bằng mật khẩu này. Mật khẩu không '
                'được lưu — quên là mất dữ liệu backup.',
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
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu (≥ 6 ký tự) | Passphrase',
                  border: OutlineInputBorder(),
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
              label: Text(
                _busy ? 'Đang xuất…' : 'Xuất & chia sẻ (email…) | Export',
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing2),
            Text(
              'File CSV mở đúng tiếng Việt trong Excel (UTF-8 BOM). Chia sẻ '
              'qua share sheet — chọn Mail/Gmail để gửi email; dữ liệu chỉ '
              'rời máy qua ứng dụng bạn chọn.',
              style: TongtaiDesignTokens.captionStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing4),
            Text(
              'Lịch sử xuất | Export history',
              style: TongtaiDesignTokens.smallStyle.copyWith(
                fontWeight: FontWeight.w700,
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing2),
            if (_records.isEmpty)
              Text(
                'Chưa có lần xuất nào.',
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
                          '${record.fileName} — ${record.type.labelVi}, '
                          '${record.rowCount} dòng, '
                          '${TongtaiFormatters.isoDate(record.exportedAt)}',
                          style: TongtaiDesignTokens.captionStyle.copyWith(
                            color: TongtaiDesignTokens.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
