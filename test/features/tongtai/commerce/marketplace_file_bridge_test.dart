import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_profit.dart';
import 'package:tongtai/features/tongtai/commerce/import/commerce_import.dart';
import 'package:tongtai/features/tongtai/commerce/import/marketplace_export_source.dart';
import 'package:tongtai/features/tongtai/commerce/import/marketplace_profile.dart';
import 'package:tongtai/features/tongtai/core/provenance.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/settlement.dart';
import 'package:tongtai/features/tongtai/finance/true_profit.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/profile/business_profile.dart'
    show SalesChannel;

/// WTM-322 · C6 — File Bridge cho Shopee/TikTok.
///
/// ## ⚠️ Không có file thật để test
///
/// Tên cột trong `MarketplaceProfile` đến từ tài liệu, **chưa đối chiếu file
/// thật của Founder**. Suite này vì thế test hai thứ khác nhau:
///
/// 1. **Cơ chế** — nhận dạng · gom dòng · khớp SKU · chống trùng · phân loại
///    phí. Những thứ này đúng bất kể tên cột.
/// 2. **Cách xử khi KHÔNG nhận ra** — vì đó mới là tình huống nhiều khả năng
///    xảy ra với file thật đầu tiên.
void main() {
  final now = DateTime(2026, 8, 9, 12);

  /// Dựng một `.xlsx` tối giản trong bộ nhớ.
  ///
  /// Không dùng fixture trên đĩa: mỗi test cần một bộ tiêu đề khác nhau, và
  /// mười file fixture thì không ai đọc nổi cái nào khác cái nào.
  Uint8List xlsx(List<List<String>> rows) {
    String cell(String v, int col, int row) {
      final letter = String.fromCharCode(65 + col);
      final escaped = v
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;');
      return '<c r="$letter$row" t="inlineStr">'
          '<is><t>$escaped</t></is></c>';
    }

    final sheetRows = <String>[];
    for (var r = 0; r < rows.length; r++) {
      final cells = [
        for (var c = 0; c < rows[r].length; c++) cell(rows[r][c], c, r + 1),
      ].join();
      sheetRows.add('<row r="${r + 1}">$cells</row>');
    }

    final archive = Archive();
    void add(String name, String content) {
      // `utf8.encode`, KHÔNG `codeUnits`: `codeUnits` là UTF-16 và mọi chữ có
      // dấu sẽ hỏng — "Mã đơn hàng" thành "M? ?n h?ng", rồi nhận dạng trượt và
      // test đỏ vì một lý do không liên quan gì tới sản phẩm.
      final data = utf8.encode(content);
      archive.addFile(ArchiveFile(name, data.length, data));
    }

    add(
      '[Content_Types].xml',
      '<?xml version="1.0"?><Types xmlns="http://schemas.openxmlformats.org/'
          'package/2006/content-types"/>',
    );
    add(
      'xl/workbook.xml',
      '<?xml version="1.0"?><workbook><sheets>'
          '<sheet name="Sheet1" sheetId="1"/></sheets></workbook>',
    );
    add(
      'xl/worksheets/sheet1.xml',
      '<?xml version="1.0"?><worksheet><sheetData>'
          '${sheetRows.join()}</sheetData></worksheet>',
    );
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  Product product({String sku = 'TT-001', String id = 'p1'}) => Product(
    id: id,
    sku: sku,
    name: 'Áo thun cotton',
    category: 'Thời trang',
    pricePerUnit: 250000,
    costPrice: 120000,
    updatedAt: now,
  );

  Future<CommerceImportPreview> readFile(
    List<List<String>> rows, {
    List<Product> products = const [],
    Set<String> existing = const {},
  }) => MarketplaceExportSource(
    bytes: xlsx(rows),
    fileName: 'export.xlsx',
    now: now,
    knownProducts: products,
    existingOrderIds: existing,
  ).read();

  // ── nhận dạng ────────────────────────────────────────────────────────────

  group('nhận dạng file', () {
    test('nhận ra file đơn Shopee tiếng Việt', () {
      final match = MarketplaceMatch.detect(const [
        'Mã đơn hàng',
        'Ngày đặt hàng',
        'Trạng thái đơn hàng',
        'SKU phân loại hàng',
        'Số lượng',
        'Giá gốc',
      ]);

      expect(match, isNotNull);
      expect(match!.profile.vendor, 'shopee');
      expect(match.kind, MarketplaceFileKind.orders);
    });

    test('nhận ra báo cáo thu nhập, khác file đơn', () {
      final match = MarketplaceMatch.detect(const [
        'Mã đơn hàng',
        'Phí hoa hồng',
        'Phí thanh toán',
        'Phí vận chuyển',
        'Tổng số tiền người bán nhận được',
      ]);

      expect(match!.kind, MarketplaceFileKind.income);
    });

    test('nhận ra file TikTok tiếng Anh', () {
      final match = MarketplaceMatch.detect(const [
        'Order ID',
        'Created Time',
        'Order Status',
        'Seller SKU',
        'Quantity',
      ]);

      expect(match!.profile.vendor, 'tiktok_shop');
    });

    test('bỏ qua khác biệt hoa thường, gạch dưới, ngoặc', () {
      final match = MarketplaceMatch.detect(const [
        'order_id',
        'ORDER STATUS',
        'Seller SKU (*)',
        'quantity',
        'Created Time',
      ]);

      expect(match, isNotNull);
    });

    test('⭐ vài cột trùng tên tình cờ KHÔNG đủ để nhận nhầm', () {
      // Một file kho tự làm có "Số lượng" và "Tên sản phẩm" — hai cột thôi thì
      // chưa phải file sàn, và đoán bừa sẽ ánh xạ sai toàn bộ.
      final match = MarketplaceMatch.detect(const [
        'Tên sản phẩm',
        'Số lượng',
        'Ghi chú',
      ]);

      expect(match, isNull);
    });
  });

  group('không nhận ra ⇒ KỂ LẠI nó thấy gì', () {
    test('báo cáo tên cột thật thay vì chỉ nói "không đọc được"', () async {
      final preview = await readFile([
        ['Mã vận đơn', 'Người nhận', 'Ghi chú giao hàng'],
        ['VD-1', 'Anh Nam', 'Giao giờ hành chính'],
      ]);

      final issue = preview.errors.single;
      expect(issue.code, 'unknown_marketplace_file');
      // Đây là điểm: file thật sẽ TỰ NÓI cho ta biết tên cột đúng của nó.
      expect(issue.detail, contains('Mã vận đơn'));
      expect(issue.detail, contains('Người nhận'));
    });
  });

  // ── file đơn hàng ────────────────────────────────────────────────────────

  group('file đơn hàng', () {
    test('nhiều dòng cùng mã đơn gom thành MỘT đơn', () async {
      final preview = await readFile(
        [
          [
            'Mã đơn hàng',
            'Ngày đặt hàng',
            'Trạng thái đơn hàng',
            'SKU phân loại hàng',
            'Số lượng',
            'Giá gốc',
          ],
          ['SP-1', '2026-08-01', 'Hoàn thành', 'TT-001', '2', '250000'],
          ['SP-1', '2026-08-01', 'Hoàn thành', 'TT-002', '1', '180000'],
        ],
        products: [
          product(),
          product(sku: 'TT-002', id: 'p2'),
        ],
      );

      // Không gom thì số đơn nhân lên, và mọi chỉ số đếm theo đơn sai theo.
      expect(preview.orders, hasLength(1));
      expect(preview.orders.single.items, hasLength(2));
      expect(preview.orders.single.channel, SalesChannel.shopee);
      expect(
        preview.orders.single.provenance.source,
        ProvenanceSource.fileBridge,
      );
    });

    test(
      '⭐ SKU chưa có trong danh mục ⇒ CHẶN đơn, nói rõ phải làm gì',
      () async {
        final preview = await readFile(
          [
            [
              'Mã đơn hàng',
              'Ngày đặt hàng',
              'Trạng thái đơn hàng',
              'SKU phân loại hàng',
              'Số lượng',
              'Giá gốc',
            ],
            ['SP-1', '2026-08-01', 'Hoàn thành', 'LA-999', '1', '99000'],
          ],
          products: [product()],
        );

        // Tạo sản phẩm từ file đơn sẽ sinh danh mục toàn món không biết vốn, và
        // lợi nhuận cả danh mục lập tức thành "chưa tính được".
        expect(preview.orders, isEmpty);
        final issue = preview.errors.firstWhere((e) => e.code == 'unknown_sku');
        expect(issue.detail, contains('Nhập danh mục sản phẩm trước'));
      },
    );

    test('nhập lại cùng file KHÔNG đếm hai lần', () async {
      final preview = await readFile(
        [
          [
            'Mã đơn hàng',
            'Ngày đặt hàng',
            'Trạng thái đơn hàng',
            'SKU phân loại hàng',
            'Số lượng',
            'Giá gốc',
          ],
          ['SP-1', '2026-08-01', 'Hoàn thành', 'TT-001', '1', '250000'],
        ],
        products: [product()],
        existing: {'mkt-shopee-SP-1'},
      );

      expect(preview.orders, isEmpty);
      expect(preview.issues.any((i) => i.code == 'already_imported'), isTrue);
    });

    test('đơn đã huỷ/hoàn đọc đúng trạng thái', () async {
      final preview = await readFile(
        [
          [
            'Mã đơn hàng',
            'Ngày đặt hàng',
            'Trạng thái đơn hàng',
            'SKU phân loại hàng',
            'Số lượng',
            'Giá gốc',
          ],
          ['SP-1', '2026-08-01', 'Đã huỷ', 'TT-001', '1', '250000'],
          ['SP-2', '2026-08-01', 'Trạng thái lạ hoắc', 'TT-001', '1', '250000'],
        ],
        products: [product()],
      );

      final byNumber = {for (final o in preview.orders) o.orderNumber: o};
      expect(byNumber['SP-1']!.status, OrderStatus.cancelled);
      // Trạng thái lạ ⇒ `pending`: tính một đơn chưa rõ vào doanh thu là bịa
      // doanh thu.
      expect(byNumber['SP-2']!.status, OrderStatus.pending);
    });

    test('⭐ nhập file đơn xong CẢNH BÁO là chưa có phí sàn', () async {
      final preview = await readFile(
        [
          [
            'Mã đơn hàng',
            'Ngày đặt hàng',
            'Trạng thái đơn hàng',
            'SKU phân loại hàng',
            'Số lượng',
            'Giá gốc',
          ],
          ['SP-1', '2026-08-01', 'Hoàn thành', 'TT-001', '1', '250000'],
        ],
        products: [product()],
      );

      final warn = preview.warnings.firstWhere(
        (w) => w.code == 'income_report_missing',
      );
      expect(warn.detail, contains('báo cáo thu nhập'));
    });
  });

  // ── báo cáo thu nhập ─────────────────────────────────────────────────────

  group('báo cáo thu nhập', () {
    test('mỗi khoản một `kind` riêng, KHÔNG gộp thành "phí sàn"', () async {
      final preview = await readFile([
        [
          'Mã đơn hàng',
          'Phí hoa hồng',
          'Phí thanh toán',
          'Phí vận chuyển',
          'Tổng số tiền người bán nhận được',
        ],
        ['SP-1', '14245', '7252', '25000', '203503'],
      ]);

      final kinds = preview.settlements.map((s) => s.kind).toSet();
      // Gộp lại thì không ai trả lời được "hoa hồng bao nhiêu" — đúng câu
      // người bán hỏi khi thấy lợi nhuận mỏng.
      expect(kinds, contains(SettlementKind.commission));
      expect(kinds, contains(SettlementKind.platformFee));
      expect(kinds, contains(SettlementKind.shippingFee));
    });

    test('⭐ voucher SÀN tài trợ không phải chi phí người bán', () async {
      final preview = await readFile([
        [
          'Mã đơn hàng',
          'Phí hoa hồng',
          'Phí thanh toán',
          'Voucher từ Người bán',
          'Voucher từ Shopee',
        ],
        ['SP-1', '1000', '500', '20000', '50000'],
      ]);

      final byAmount = {
        for (final s in preview.settlements) s.amount: s.fundedBy,
      };
      expect(byAmount[20000], FundingSource.seller);
      // Nhầm chỗ này làm lợi nhuận sai theo **hướng tâng bốc** — kiểu sai
      // không ai đi kiểm (ADR-TON-024).
      expect(byAmount[50000], FundingSource.platform);
    });

    test('phí ghi số âm vẫn ra `amount` dương + chiều outbound', () async {
      final preview = await readFile([
        [
          'Mã đơn hàng',
          'Phí hoa hồng',
          'Phí thanh toán',
          'Phí vận chuyển',
          'Tổng số tiền người bán nhận được',
        ],
        ['SP-1', '-14245', '0', '0', '100000'],
      ]);

      final line = preview.settlements.single;
      expect(line.amount, 14245);
      expect(line.direction, SettlementDirection.outbound);
    });

    test('phí gắn đúng vào mã đơn canonical của sàn', () async {
      final preview = await readFile([
        [
          'Mã đơn hàng',
          'Phí hoa hồng',
          'Phí thanh toán',
          'Phí vận chuyển',
          'Tổng số tiền người bán nhận được',
        ],
        ['SP-1', '1000', '0', '0', '99000'],
      ]);

      expect(preview.settlements.first.orderId, 'mkt-shopee-SP-1');
    });

    test('cột chưa dùng tới được NÓI RA, không nuốt im lặng (§11)', () async {
      final preview = await readFile([
        [
          'Mã đơn hàng',
          'Phí hoa hồng',
          'Phí thanh toán',
          'Phí vận chuyển',
          'Mã kho vận',
          'Ghi chú nội bộ',
        ],
        ['SP-1', '1000', '500', '2000', 'KV-1', 'abc'],
      ]);

      final info = preview.issues.firstWhere(
        (i) => i.code == 'unmapped_columns',
      );
      expect(info.detail, contains('Mã kho vận'));
    });
  });

  // ── lời thật: doanh thu đúng mà lợi nhuận sai ────────────────────────────

  group('⭐ chặn "doanh thu đúng, lợi nhuận sai"', () {
    CustomerOrder order(SalesChannel? channel) => CustomerOrder(
      id: 'o1',
      customerId: 'c1',
      orderNumber: 'o1',
      date: now.subtract(const Duration(days: 2)),
      status: OrderStatus.delivered,
      channel: channel,
      items: [
        OrderItem(
          productId: 'p1',
          productName: 'Áo thun cotton',
          sku: 'TT-001',
          category: 'Thời trang',
          quantity: 1,
          unitPrice: 250000,
        ),
      ],
    );

    test('đơn Shopee chưa có phí sàn ⇒ TỪ CHỐI trả lợi nhuận', () {
      final context = CommerceProfitContext.derive(
        products: [product()],
        orders: [order(SalesChannel.shopee)],
        settlements: const [],
        now: now,
      );

      expect(context.overall, isA<ProfitInsufficient>());
      expect(
        (context.overall as ProfitInsufficient).blockers,
        contains(ProfitBlocker.missingMarketplaceFees),
      );
    });

    test('đơn bán tại quầy KHÔNG có phí sàn là bình thường', () {
      final context = CommerceProfitContext.derive(
        products: [product()],
        orders: [order(SalesChannel.shop)],
        settlements: const [],
        now: now,
      );

      // Suy ra từ **kênh bán**, không từ "không thấy dòng phí".
      expect(context.overall, isA<ProfitKnown>());
    });

    test('nhập tiếp báo cáo thu nhập ⇒ tính được lợi nhuận', () {
      final context = CommerceProfitContext.derive(
        products: [product()],
        orders: [order(SalesChannel.shopee)],
        settlements: [
          SettlementLine(
            id: 's1',
            orderId: 'o1',
            kind: SettlementKind.commission,
            direction: SettlementDirection.outbound,
            amount: 14245,
            currency: 'VND',
            occurredAt: now,
            fundedBy: FundingSource.seller,
          ),
        ],
        now: now,
      );

      expect(context.overall, isA<ProfitKnown>());
      expect(
        (context.overall as ProfitKnown).amount,
        closeTo(250000 - 120000 - 14245, 1),
      );
    });
  });
}
