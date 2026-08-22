import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_profit.dart';
import 'package:tongtai/features/tongtai/commerce/import/commerce_import.dart';
import 'package:tongtai/features/tongtai/commerce/import/commerce_source_resolver.dart';
import 'package:tongtai/features/tongtai/commerce/import/import_column_map.dart';
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
    List<ImportColumnMap> savedMaps = const [],
  }) => MarketplaceExportSource(
    bytes: xlsx(rows),
    fileName: 'export.xlsx',
    now: now,
    knownProducts: products,
    existingOrderIds: existing,
    savedMaps: savedMaps,
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

  // ── WTM-442 · bốn sàn thêm mới ───────────────────────────────────────────

  group('WTM-442 · nhận dạng bốn sàn thêm mới', () {
    // Bộ tiêu đề dưới đây mô phỏng bản xuất thật của từng sàn. Chúng vẫn là
    // **giả định** (không ai có file thật) — nên thứ suite này bảo vệ không
    // phải "tên cột đúng", mà là *cơ chế phân biệt sáu sàn không lẫn nhau*.

    test('file đơn eBay', () {
      final match = MarketplaceMatch.detect(const [
        'Sales Record Number',
        'Sale Date',
        'Order Status',
        'Custom Label',
        'Item Title',
        'Quantity',
        'Sold For',
        'Buyer Username',
      ]);

      expect(match?.profile.vendor, 'ebay');
      expect(match?.kind, MarketplaceFileKind.orders);
      expect(match?.profile.channel, SalesChannel.ebay);
    });

    test('file đơn Amazon — tên cột chữ-thường-nối-gạch', () {
      final match = MarketplaceMatch.detect(const [
        'amazon-order-id',
        'purchase-date',
        'order-status',
        'sku',
        'product-name',
        'quantity-purchased',
        'item-price',
        'buyer-name',
      ]);

      expect(match?.profile.vendor, 'amazon');
      expect(match?.profile.channel, SalesChannel.amazon);
    });

    test('file đơn Shopify — bốn cột `Lineitem *` là thứ nhận dạng', () {
      final match = MarketplaceMatch.detect(const [
        'Name',
        'Created at',
        'Financial Status',
        'Lineitem sku',
        'Lineitem name',
        'Lineitem quantity',
        'Lineitem price',
        'Billing Name',
      ]);

      expect(match?.profile.vendor, 'shopify');
      expect(match?.profile.channel, SalesChannel.shopify);
    });

    test('file đơn Lazada', () {
      final match = MarketplaceMatch.detect(const [
        'orderNumber',
        'createTime',
        'status',
        'sellerSku',
        'itemName',
        'Quantity',
        'paidPrice',
        'customerName',
      ]);

      expect(match?.profile.vendor, 'lazada');
      expect(match?.profile.channel, SalesChannel.lazada);
    });

    test('⭐ file eBay KHÔNG bị nhận nhầm thành Shopee', () {
      // Đây là lỗi mà việc thêm sàn suýt tạo ra: `Order ID` · `Quantity` ·
      // `SKU` · `Order Status` có ở nhiều sàn, và Shopee đứng đầu `all`.
      // Nhận nhầm ở đây không làm hỏng file — nó **gán sai kênh cho đơn**, và
      // doanh thu theo kênh sai vĩnh viễn mà không có dấu hiệu gì.
      final match = MarketplaceMatch.detect(const [
        'Order Number',
        'Sales Record Number',
        'Sale Date',
        'Custom Label',
        'Item Title',
        'Quantity',
        'Sold For',
      ]);

      expect(match?.profile.vendor, isNot('shopee'));
      expect(match?.profile.vendor, 'ebay');
    });

    test('⭐ hoà điểm giữa HAI sàn ⇒ không kết luận, không đoán bừa', () {
      // Chỉ toàn cột dùng chung: bốn cột đủ vượt ngưỡng `isConfident`, nhưng
      // không cột nào chỉ riêng một sàn có. Đoán bừa lúc này là im lặng gán
      // sai kênh — nên câu trả lời đúng là "chưa nhận ra".
      final headers = const [
        'Order ID',
        'Order Status',
        'SKU',
        'Quantity',
        'Product Name',
      ];

      final scores = <String, int>{};
      for (final profile in MarketplaceProfile.all) {
        for (final kind in MarketplaceFileKind.values) {
          final s = profile.scoreFor(headers, kind);
          if (s > (scores[profile.vendor] ?? 0)) scores[profile.vendor] = s;
        }
      }
      final top = scores.values.reduce((a, b) => a > b ? a : b);
      final tiedVendors = scores.entries.where((e) => e.value == top).length;

      // Tiền đề của test: bộ tiêu đề này THẬT SỰ hoà. Khẳng định ra để nếu một
      // ngày bí danh đổi và nó hết hoà, test hỏng ở đây — chứ không lặng lẽ
      // biến thành một test không kiểm gì.
      expect(top, greaterThanOrEqualTo(4));
      expect(tiedVendors, greaterThan(1));

      expect(MarketplaceMatch.detect(headers), isNull);
    });

    test('sáu hồ sơ, mã vendor không trùng nhau', () {
      final vendors = MarketplaceProfile.all.map((p) => p.vendor).toList();
      expect(vendors.toSet().length, vendors.length);
      expect(vendors, hasLength(6));
    });
  });

  group('WTM-442 · phí sàn — MỘT chủ, không bản chép', () {
    CustomerOrder orderOn(SalesChannel? channel) => CustomerOrder(
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

    test(
      '⭐ mọi kênh: CommerceProfit đồng ý với SalesChannel, không tự phán',
      () {
        // Trước WTM-442 có HAI bản của cùng luật này — một trên enum, một chép
        // riêng trong `commerce_profit.dart`. Bản chép mang `_ => false`, nên
        // thêm sàn mà quên sửa nó thì lợi nhuận sàn đó bị tính THỪA và không
        // màn nào đỏ. Test này khoá cửa: hai bên phải nói cùng một điều, cho
        // **mọi** giá trị enum — kể cả giá trị chưa ai nghĩ ra.
        for (final channel in SalesChannel.values) {
          final context = CommerceProfitContext.derive(
            products: [product()],
            orders: [orderOn(channel)],
            settlements: const [],
            now: now,
          );

          final blocked =
              context.overall is ProfitInsufficient &&
              (context.overall as ProfitInsufficient).blockers.contains(
                ProfitBlocker.missingMarketplaceFees,
              );

          expect(
            blocked,
            channel.chargesPlatformFee,
            reason:
                'Kênh ${channel.code}: SalesChannel.chargesPlatformFee = '
                '${channel.chargesPlatformFee} nhưng CommerceProfit '
                '${blocked ? "đòi" : "không đòi"} dòng đối soát.',
          );
        }
      },
    );

    test(
      '⭐ bốn sàn mới đều bị giữ tiền — quên phân loại là con số đẹp giả',
      () {
        for (final channel in [
          SalesChannel.ebay,
          SalesChannel.amazon,
          SalesChannel.shopify,
          SalesChannel.lazada,
        ]) {
          expect(
            channel.chargesPlatformFee,
            isTrue,
            reason: '${channel.code} phải đòi dòng đối soát trước khi báo lời.',
          );
        }
      },
    );

    test(
      'kênh chưa ghi (`null`) KHÔNG bị coi là miễn phí sàn một cách im lặng',
      () {
        final context = CommerceProfitContext.derive(
          products: [product()],
          orders: [orderOn(null)],
          settlements: const [],
          now: now,
        );

        // `null` = chưa ghi kênh. Không biết kênh thì không đòi được dòng đối
        // soát nào — nhưng đó là *thiếu thông tin*, không phải *đã đủ*.
        expect(context.overall, isA<ProfitKnown>());
      },
    );

    test('mọi kênh trong `MarketplaceProfile` đều thuộc nhóm bị giữ tiền', () {
      // Một hồ sơ File Bridge tồn tại nghĩa là có sàn ở giữa. Sàn ở giữa thì
      // luôn cắt một phần trước khi trả tiền.
      for (final profile in MarketplaceProfile.all) {
        expect(
          profile.channel.chargesPlatformFee,
          isTrue,
          reason: '${profile.vendor} có hồ sơ nhập file nhưng khai không phí.',
        );
      }
    });
  });

  // ── WTM-443 · người bán tự chỉ cột ───────────────────────────────────────

  group('WTM-443 · bản đồ cột do người bán chỉ', () {
    // Một file sàn lạ: không bí danh nào của sáu hồ sơ khớp.
    const strangeHeaders = [
      'Ma_Don',
      'Ngay',
      'Ma_Hang',
      'SL',
      'Don_Gia',
      'Ghi_Chu',
    ];

    ImportColumnMap mapFor({
      String vendor = ImportColumnMap.kOtherMarketplaceVendor,
      Map<MarketplaceField, String>? columns,
    }) => ImportColumnMap(
      vendor: vendor,
      kind: MarketplaceFileKind.orders,
      columns:
          columns ??
          const {
            MarketplaceField.orderId: 'Ma_Don',
            MarketplaceField.orderDate: 'Ngay',
            MarketplaceField.sku: 'Ma_Hang',
            MarketplaceField.quantity: 'SL',
            MarketplaceField.unitPrice: 'Don_Gia',
          },
    );

    test('⭐ file sàn lạ + bản đồ đã lưu ⇒ đọc được', () async {
      final preview = await readFile(
        [
          strangeHeaders,
          ['DH-1', '2026-08-09', 'TT-001', '2', '250000', ''],
        ],
        products: [product()],
        savedMaps: [mapFor()],
      );

      expect(preview.errors, isEmpty);
      expect(preview.orders, hasLength(1));
      expect(preview.orders.single.orderNumber, 'DH-1');
      expect(preview.orders.single.items.single.quantity, 2);
    });

    test('⭐ sàn lạ vẫn bị coi là CÓ phí sàn', () async {
      final preview = await readFile(
        [
          strangeHeaders,
          ['DH-1', '2026-08-09', 'TT-001', '1', '250000', ''],
        ],
        products: [product()],
        savedMaps: [mapFor()],
      );

      // Không biết sàn nào KHÔNG có nghĩa là không có sàn. Rơi vào một kênh
      // miễn phí sàn là đúng khuyết tật P-47 vừa gỡ.
      expect(preview.orders.single.channel, SalesChannel.marketplaceOther);
      expect(SalesChannel.marketplaceOther.chargesPlatformFee, isTrue);
    });

    test(
      '⭐ bản đồ thiếu vai trò BẮT BUỘC ⇒ không dùng, không nhập nửa vời',
      () async {
        final broken = mapFor(
          columns: const {
            MarketplaceField.orderId: 'Ma_Don',
            MarketplaceField.sku: 'Ma_Hang',
            // thiếu quantity + unitPrice
          },
        );
        expect(broken.isUsable, isFalse);
        expect(
          broken.missingRequired,
          containsAll(<MarketplaceField>[
            MarketplaceField.quantity,
            MarketplaceField.unitPrice,
          ]),
        );

        final preview = await readFile(
          [
            strangeHeaders,
            ['DH-1', '2026-08-09', 'TT-001', '2', '250000', ''],
          ],
          products: [product()],
          savedMaps: [broken],
        );

        expect(preview.errors.single.code, 'unknown_marketplace_file');
        expect(preview.orders, isEmpty);
      },
    );

    test('⭐ HAI bản đồ cùng khớp ⇒ không đoán bừa', () async {
      final preview = await readFile(
        [
          strangeHeaders,
          ['DH-1', '2026-08-09', 'TT-001', '2', '250000', ''],
        ],
        products: [product()],
        savedMaps: [
          mapFor(),
          mapFor(vendor: 'shopee'),
        ],
      );

      // Cùng luật với hoà điểm giữa hai sàn: thà hỏi lại còn hơn gán sai kênh
      // cho cả mẻ đơn.
      expect(preview.errors.single.code, 'unknown_marketplace_file');
    });

    test('bản đồ nhắc một cột KHÔNG có trong file ⇒ không áp dụng', () async {
      final other = mapFor(
        columns: const {
          MarketplaceField.orderId: 'Ma_Don',
          MarketplaceField.sku: 'Ma_Hang',
          MarketplaceField.quantity: 'SL',
          MarketplaceField.unitPrice: 'Don_Gia',
          MarketplaceField.buyerName: 'Ten_Khach', // file này không có
        },
      );

      final preview = await readFile(
        [
          strangeHeaders,
          ['DH-1', '2026-08-09', 'TT-001', '2', '250000', ''],
        ],
        products: [product()],
        savedMaps: [other],
      );

      expect(preview.errors.single.code, 'unknown_marketplace_file');
    });

    test('⭐ bản đồ KHÔNG ghi đè khi nhận dạng tự động đã thành công', () async {
      // Bản đồ tay là lưới an toàn, không phải đường chính. Nếu nó đi trước,
      // một hồ sơ đã sửa đúng vẫn bị bản đồ cũ ghi đè.
      final preview = await readFile(
        [
          const [
            'Mã đơn hàng',
            'Ngày đặt hàng',
            'SKU phân loại hàng',
            'Số lượng',
            'Giá gốc',
          ],
          ['SP-9', '2026-08-09', 'TT-001', '1', '250000'],
        ],
        products: [product()],
        savedMaps: [mapFor(vendor: 'lazada')],
      );

      expect(preview.orders.single.channel, SalesChannel.shopee);
    });

    test('⭐ cột chưa hiểu được trả ĐỦ, không cắt còn 8', () async {
      // 12 cột, không phải 30: helper `xlsx()` đặt tên ô bằng
      // `String.fromCharCode(65 + col)` nên chỉ dựng được tới cột Z. Giới hạn
      // của công cụ dựng file, không phải của sản phẩm — nhưng 12 > 8 là đủ
      // để chứng minh điều test này quan tâm.
      final many = List.generate(12, (i) => 'Cot_$i');
      final preview = await readFile([many, List.filled(12, 'x')]);

      expect(preview.errors.single.code, 'unknown_marketplace_file');
      // Câu tiếng Việt chỉ kể 8 cột đầu cho dễ đọc; danh sách cho màn hình
      // ghép cột phải đủ, kể cả cột thứ 12.
      expect(preview.unrecognisedHeaders, hasLength(12));
      expect(preview.unrecognisedHeaders.last, 'Cot_11');
    });

    test(
      'mã vai trò lạ trong bản đồ đã lưu ⇒ BỎ QUA, không rơi về vai trò khác',
      () {
        final decoded = ImportColumnMap.decodeColumns(
          '{"orderId":"Ma_Don","vaiTroTuTuongLai":"Cot_X","sku":"Ma_Hang"}',
        );

        expect(decoded[MarketplaceField.orderId], 'Ma_Don');
        expect(decoded[MarketplaceField.sku], 'Ma_Hang');
        expect(decoded, hasLength(2));
      },
    );

    test('mã hoá rồi giải mã lại giữ nguyên bản đồ', () {
      final map = mapFor();
      expect(ImportColumnMap.decodeColumns(map.encodeColumns()), map.columns);
    });

    test('⭐⭐ TỚI ĐƯỢC qua resolver, không chỉ chạy được khi gọi thẳng', () async {
      // Bài học của chính story này. Bản đầu truyền `savedMaps` vào bộ đọc,
      // và mọi test trên đây đều xanh — vì chúng dựng `MarketplaceExportSource`
      // THẲNG. Nhưng đường thật đi qua `CommerceSourceResolver`, và cổng định
      // tuyến ở đó chỉ hỏi `detect()`. Một file sàn lạ vì thế **không bao giờ
      // tới được** bộ đọc để mà dùng bản đồ.
      //
      // Test xanh chứng minh cơ chế CHẠY ĐƯỢC. Nó không chứng minh cơ chế
      // TỚI ĐƯỢC. Đây là test cho vế thứ hai.
      final source = CommerceSourceResolver.resolve(
        bytes: xlsx([
          strangeHeaders,
          ['DH-1', '2026-08-09', 'TT-001', '2', '250000', ''],
        ]),
        fileName: 'export.xlsx',
        now: now,
        knownProducts: [product()],
        savedMaps: [mapFor()],
      );

      expect(
        source,
        isA<MarketplaceExportSource>(),
        reason:
            'resolver phải định tuyến file sàn lạ tới bộ đọc sàn khi đã '
            'có bản đồ, nếu không thì bản đồ vô dụng',
      );

      final preview = await source.read();
      expect(preview.errors, isEmpty);
      expect(preview.orders.single.orderNumber, 'DH-1');
    });

    test('không có bản đồ ⇒ resolver KHÔNG đổi hành vi cũ', () {
      // Cổng định tuyến chỉ được nới đúng bằng phần bản đồ mở ra. File lạ mà
      // chưa ai chỉ cột thì vẫn đi đường cũ — không âm thầm đổi phân loại.
      final source = CommerceSourceResolver.resolve(
        bytes: xlsx([
          strangeHeaders,
          ['DH-1', '2026-08-09', 'TT-001', '2', '250000', ''],
        ]),
        fileName: 'export.xlsx',
        now: now,
        knownProducts: [product()],
      );

      expect(source, isNot(isA<MarketplaceExportSource>()));
    });

    test('JSON hỏng ⇒ bản đồ rỗng, không ném lỗi', () {
      expect(ImportColumnMap.decodeColumns('không phải json'), isEmpty);
      expect(ImportColumnMap.decodeColumns('[1,2,3]'), isEmpty);
    });
  });
}
