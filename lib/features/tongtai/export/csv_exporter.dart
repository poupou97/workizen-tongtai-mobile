import '../consumer/customer.dart';
import '../consumer/customer_order.dart';
import '../core/tongtai_formatters.dart';
import '../inventory/product.dart';

/// Which business data set an export covers (WTM-99 AC1 — every major data
/// type shipped so far). Bilingual labels per WTM-60 convention.
enum TongtaiExportType {
  customers,
  products,
  orders;

  String get labelEn => switch (this) {
    TongtaiExportType.customers => 'Customers',
    TongtaiExportType.products => 'Products',
    TongtaiExportType.orders => 'Orders',
  };

  String get labelVi => switch (this) {
    TongtaiExportType.customers => 'Khách hàng',
    TongtaiExportType.products => 'Sản phẩm',
    TongtaiExportType.orders => 'Đơn hàng',
  };

  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;

  /// Suggested file name, timestamped by the caller.
  String get fileStem => switch (this) {
    TongtaiExportType.customers => 'tongtai-khach-hang',
    TongtaiExportType.products => 'tongtai-san-pham',
    TongtaiExportType.orders => 'tongtai-don-hang',
  };
}

/// A generated CSV document plus its metadata (row count feeds the export
/// history — WTM-99 AC5).
class TongtaiCsv {
  const TongtaiCsv({required this.content, required this.rowCount});

  /// Full file content including the UTF-8 BOM and header line.
  final String content;

  /// Data rows (excluding the header).
  final int rowCount;
}

/// Builds CSV exports for the seller's business data (WTM-99) — pure Dart,
/// deterministic, no I/O, so every formatting rule is unit-testable.
///
/// Format (AC2): RFC-4180-style quoting (fields containing `"` `,` or
/// newlines are wrapped in double quotes with `""` escapes), CRLF row
/// endings, a header line, and a **UTF-8 BOM** so Excel opens Vietnamese
/// diacritics correctly — the single most common CSV complaint of VN
/// sellers. Money is exported as plain integer đồng (no formatting) so
/// spreadsheets can sum it; dates are ISO `yyyy-MM-dd`.
class TongtaiCsvExporter {
  const TongtaiCsvExporter();

  /// UTF-8 byte-order mark; makes Excel decode the file as UTF-8.
  static const String bom = '﻿';

  /// One CSV field, quoted only when needed.
  static String field(Object? value) {
    final text = value?.toString() ?? '';
    if (text.contains('"') ||
        text.contains(',') ||
        text.contains('\n') ||
        text.contains('\r')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  static String _rows(List<List<Object?>> rows) =>
      rows.map((r) => r.map(field).join(',')).join('\r\n');

  static String _document(List<Object?> header, List<List<Object?>> rows) =>
      '$bom${_rows([header, ...rows])}\r\n';

  /// Customers export (AC1).
  TongtaiCsv customersCsv(List<Customer> customers) {
    final rows = [
      for (final c in customers)
        [
          c.id,
          c.name,
          c.phone,
          c.email,
          c.location,
          c.addresses.join(' | '),
          c.tier.labelVi,
          c.segments.join(' | '),
          c.tags.join(' | '),
          c.orderCount,
          c.totalSpent.round(),
          c.lastPurchaseDate == null
              ? ''
              : TongtaiFormatters.isoDate(c.lastPurchaseDate!),
          c.notes,
        ],
    ];
    return TongtaiCsv(
      content: _document([
        'id',
        'ten',
        'dien_thoai',
        'email',
        'thanh_pho',
        'dia_chi',
        'hang',
        'phan_khuc',
        'the',
        'so_don',
        'tong_chi_dong',
        'mua_gan_nhat',
        'ghi_chu',
      ], rows),
      rowCount: rows.length,
    );
  }

  /// Products export (AC1).
  TongtaiCsv productsCsv(List<Product> products) {
    final rows = [
      for (final p in products)
        [
          p.id,
          p.sku,
          p.name,
          p.category,
          p.quantity,
          p.pricePerUnit.round(),
          p.reorderLevel,
          p.needsRestock ? 'CAN_NHAP_THEM' : 'DU_HANG',
          TongtaiFormatters.isoDate(p.updatedAt),
        ],
    ];
    return TongtaiCsv(
      content: _document([
        'id',
        'sku',
        'ten',
        'danh_muc',
        'ton_kho',
        'don_gia_dong',
        'muc_dat_lai',
        'trang_thai_kho',
        'cap_nhat',
      ], rows),
      rowCount: rows.length,
    );
  }

  /// Orders export with an optional inclusive date range (AC3). One row per
  /// order line (item), so spreadsheets can pivot by product.
  TongtaiCsv ordersCsv(
    List<CustomerOrder> orders, {
    DateTime? from,
    DateTime? to,
  }) {
    final filtered = [
      for (final o in orders)
        if ((from == null || !o.date.isBefore(from)) &&
            (to == null || !o.date.isAfter(to)))
          o,
    ]..sort((a, b) => b.date.compareTo(a.date));
    final rows = [
      for (final o in filtered)
        for (final item in o.items)
          [
            o.orderNumber,
            TongtaiFormatters.isoDate(o.date),
            o.status.labelVi,
            o.customerId,
            item.productName,
            item.category,
            item.quantity,
            item.unitPrice.round(),
            item.lineTotal.round(),
            o.totalAmount.round(),
          ],
    ];
    return TongtaiCsv(
      content: _document([
        'ma_don',
        'ngay',
        'trang_thai',
        'ma_khach',
        'san_pham',
        'danh_muc',
        'so_luong',
        'don_gia_dong',
        'thanh_tien_dong',
        'tong_don_dong',
      ], rows),
      rowCount: rows.length,
    );
  }
}
