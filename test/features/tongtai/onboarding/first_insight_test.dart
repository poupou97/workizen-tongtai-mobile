import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/true_profit.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/onboarding/first_insight.dart';
import 'package:tongtai/features/tongtai/onboarding/first_insight_input.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';

/// WTM-354 (S5) — First Insight engine.
///
/// Hai luật chống bịa được khoá ở đây, và chúng là lý do file này tồn tại:
///
/// 1. **Chưa đủ dữ liệu ⇒ TỪ CHỐI**, khác hẳn *"đã xét và không có gì"*.
/// 2. **Không luật ⇒ không dòng.** Mọi phát hiện phải chỉ ra được mã luật đã
///    sinh ra nó.
void main() {
  final now = DateTime(2026, 8, 11, 9);

  Product product({
    required String id,
    int? quantity,
    double? costPrice,
    double price = 100000,
    int? reorderLevel,
  }) => Product(
    id: id,
    sku: id.toUpperCase(),
    name: 'Hàng $id',
    category: 'test',
    pricePerUnit: price,
    quantity: quantity,
    reorderLevel: reorderLevel,
    costPrice: costPrice,
    updatedAt: now,
  );

  CustomerOrder order({
    required String id,
    required String customerId,
    required String productId,
    int quantity = 1,
    double unitPrice = 100000,
    DateTime? date,
    OrderStatus status = OrderStatus.delivered,
  }) => CustomerOrder(
    id: id,
    customerId: customerId,
    orderNumber: id,
    date: date ?? now.subtract(const Duration(days: 3)),
    status: status,
    items: [
      OrderItem(
        productId: productId,
        productName: 'Hàng $productId',
        sku: productId.toUpperCase(),
        category: 'test',
        quantity: quantity,
        unitPrice: unitPrice,
      ),
    ],
  );

  FirstInsightInput input({
    List<Product> products = const [],
    List<CustomerOrder> orders = const [],
    int marketplaceOrdersWithoutFees = 0,
  }) => FirstInsightInput(
    now: now,
    products: products,
    orders: orders,
    marketplaceOrdersWithoutFees: marketplaceOrdersWithoutFees,
  );

  const engine = FirstInsightEngine();

  group('⛔ ba trạng thái, không phải hai', () {
    test('không dữ liệu ⇒ TỪ CHỐI, không phải "mọi thứ ổn"', () {
      final result = engine.analyse(input());

      expect(result.isInsufficient, isTrue);
      expect(result.insufficientReason, isNotNull);
      expect(result.findings, isEmpty);
      // Và tuyệt đối không được đọc như "đã xét xong".
      expect(result.isQuiet, isFalse);
    });

    test('có dữ liệu nhưng luật không thấy gì ⇒ đã xét, rỗng', () {
      // Hàng còn nhiều, biên lợi nhuận dày, không khách nào — không luật nào
      // có gì để nói, và đó là một câu trả lời hợp lệ.
      final result = engine.analyse(
        input(
          products: [
            product(id: 'p1', quantity: 500, costPrice: 10000, reorderLevel: 5),
          ],
        ),
      );

      expect(result.isInsufficient, isFalse);
      expect(result.isQuiet, isTrue);
      expect(result.findings, isEmpty);
    });

    test('hai trạng thái đó KHÔNG bằng nhau', () {
      final refused = engine.analyse(input());
      final quiet = engine.analyse(
        input(products: [product(id: 'p1', quantity: 500, costPrice: 1000)]),
      );

      expect(refused.findings, isEmpty);
      expect(quiet.findings, isEmpty);
      // Cùng danh sách rỗng, khác hẳn ý nghĩa — gộp chúng lại là cách một màn
      // im lặng biến thành một lời trấn an sai.
      expect(refused.isInsufficient, isNot(quiet.isInsufficient));
    });
  });

  group('⛔ mọi phát hiện phải chỉ ra được LUẬT sinh ra nó', () {
    test('mã luật nằm trong danh sách đã khai', () {
      final result = engine.analyse(
        input(
          products: [
            product(id: 'p1', quantity: 1, costPrice: 90000, reorderLevel: 10),
            product(id: 'p2', quantity: 40, costPrice: 99000),
          ],
          orders: [order(id: 'o1', customerId: 'c1', productId: 'p1')],
        ),
      );

      expect(result.findings, isNotEmpty);
      for (final f in result.findings) {
        expect(
          isDeclaredRuleSource(f.ruleCode),
          isTrue,
          reason:
              'phát hiện "${f.headline}" mang mã luật lạ "${f.ruleCode}" — '
              'ai đó vừa thêm một nguồn kết luận mà không khai nó',
        );
        expect(f.reason, isNotEmpty);
        expect(f.headline, isNotEmpty);
      }
    });

    test('mỗi phát hiện mang số của chính doanh nghiệp này', () {
      final result = engine.analyse(
        input(
          products: [
            product(id: 'p1', quantity: 1, costPrice: 10000, reorderLevel: 10),
          ],
        ),
      );

      expect(result.findings, isNotEmpty);
      // Không phải một nhãn chung chung: câu phải nhắc tên mặt hàng thật.
      expect(
        result.findings.any((f) => f.headline.contains('Hàng p1')),
        isTrue,
        reason: result.findings.map((f) => f.headline).join(' | '),
      );
    });

    test('cùng dữ liệu ⇒ cùng thứ tự, chạy bao nhiêu lần cũng thế', () {
      final data = input(
        products: [
          product(id: 'p2', quantity: 1, costPrice: 90000, reorderLevel: 10),
          product(id: 'p1', quantity: 2, costPrice: 95000, reorderLevel: 10),
        ],
      );

      final a = engine.analyse(data).findings.map((f) => f.subjectId).toList();
      final b = engine.analyse(data).findings.map((f) => f.subjectId).toList();

      expect(a, b);
      expect(a, isNotEmpty);
    });

    test(
      'nhiều nhất bốn phát hiện — màn đầu tiên không phải bảng cảnh báo',
      () {
        final result = engine.analyse(
          input(
            products: [
              for (var i = 0; i < 12; i++)
                product(
                  id: 'p$i',
                  quantity: 0,
                  costPrice: 99000,
                  reorderLevel: 10,
                ),
            ],
          ),
        );

        expect(result.findings.length, lessThanOrEqualTo(kMaxFirstFindings));
      },
    );
  });

  group('ảnh chụp doanh nghiệp — null nghĩa CHƯA TÍNH ĐƯỢC', () {
    test('thiếu giá vốn ⇒ lời TỪ CHỐI, không phải bằng doanh thu', () {
      final result = engine.analyse(
        input(
          products: [product(id: 'p1', quantity: 5)], // không có costPrice
          orders: [order(id: 'o1', customerId: 'c1', productId: 'p1')],
        ),
      );

      final snap = result.snapshot;
      expect(snap.revenue, 100000);
      expect(snap.orders, 1);
      // ⭐ Chỗ nguy hiểm nhất: một con số lợi nhuận thiếu giá vốn luôn đẹp hơn
      // sự thật.
      expect(snap.profit, isNull);
      expect(snap.profitBlockers, contains(ProfitBlocker.missingCost));
      expect(snap.inventoryValue, isNull);
    });

    test('đủ giá vốn ⇒ lời tính được', () {
      final result = engine.analyse(
        input(
          products: [product(id: 'p1', quantity: 5, costPrice: 60000)],
          orders: [order(id: 'o1', customerId: 'c1', productId: 'p1')],
        ),
      );

      expect(result.snapshot.profit, 40000);
      expect(result.snapshot.inventoryValue, 300000);
    });

    test('đơn sàn chưa có phí ⇒ lời TỪ CHỐI dù giá vốn đủ', () {
      final result = engine.analyse(
        input(
          products: [product(id: 'p1', quantity: 5, costPrice: 60000)],
          orders: [order(id: 'o1', customerId: 'c1', productId: 'p1')],
          marketplaceOrdersWithoutFees: 1,
        ),
      );

      expect(result.snapshot.profit, isNull);
      expect(
        result.snapshot.profitBlockers,
        contains(ProfitBlocker.missingMarketplaceFees),
      );
    });

    test('đơn huỷ không tính vào doanh thu', () {
      final result = engine.analyse(
        input(
          products: [product(id: 'p1', quantity: 5, costPrice: 60000)],
          orders: [
            order(id: 'o1', customerId: 'c1', productId: 'p1'),
            order(
              id: 'o2',
              customerId: 'c1',
              productId: 'p1',
              status: OrderStatus.cancelled,
            ),
          ],
        ),
      );

      expect(result.snapshot.revenue, 100000);
      expect(result.snapshot.orders, 1);
    });

    test('một mặt hàng còn tồn mà thiếu giá vốn ⇒ vốn tồn kho là null', () {
      // Cộng phần biết được rồi gọi nó là "vốn tồn kho" cho ra một con số luôn
      // nhỏ hơn sự thật, và không ai nhận ra vì nó vẫn có nội dung.
      final result = engine.analyse(
        input(
          products: [
            product(id: 'p1', quantity: 5, costPrice: 60000),
            product(id: 'p2', quantity: 3),
          ],
        ),
      );

      expect(result.snapshot.inventoryValue, isNull);
    });

    test('chưa khai tồn kho nào ⇒ null, không phải 0', () {
      final result = engine.analyse(
        input(products: [product(id: 'p1', costPrice: 60000)]),
      );

      expect(result.snapshot.inventoryValue, isNull);
    });
  });

  group('⭐ governance · danh sách luật đối chiếu ngược với mã nguồn', () {
    // Một danh sách khai bằng tay chỉ chứng minh được điều gì đó khi có thứ
    // bắt nó lệch. Lần đầu viết test này, danh sách khai `rule:customer-risk`
    // và `rule:business-signal` — cả hai đều KHÔNG tồn tại, và test vẫn xanh
    // vì không fixture nào chạm tới hai đường đó.
    final sourcesInRules = <String>{};

    setUpAll(() {
      final pattern = RegExp("source: '(rule:[^']*)'");
      for (final path in const [
        'lib/features/tongtai/agent/business_brief_service.dart',
      ]) {
        final text = File(path).readAsStringSync();
        for (final m in pattern.allMatches(text)) {
          sourcesInRules.add(m.group(1)!);
        }
      }
    });

    test('quét được mã luật thật (chống PASS giả)', () {
      // Regex hỏng ⇒ tập rỗng ⇒ mọi khẳng định dưới đây thành vô nghĩa.
      expect(sourcesInRules, isNotEmpty);
      expect(sourcesInRules, contains('rule:repeat-due'));
    });

    test('mọi nguồn kết luận trong luật đều đã được khai', () {
      for (final code in sourcesInRules) {
        // Mã nội suy (`rule:business-alerts/\${...}`) rút về phần tĩnh.
        final stable = code.contains(r'$') ? code.split(r'$').first : code;
        expect(
          isDeclaredRuleSource(stable),
          isTrue,
          reason:
              'luật sinh ra mã "$code" nhưng First Insight chưa khai nó — '
              'thêm vào kFirstInsightRuleSources hoặc bỏ luật khỏi engine',
        );
      }
    });

    test('không mã nào được khai thừa', () {
      for (final declared in kFirstInsightRuleSources) {
        if (declared == kSeasonalRuleCode) continue; // sinh trong engine
        expect(
          sourcesInRules.any((c) => c.startsWith(declared)),
          isTrue,
          reason: 'khai "$declared" nhưng không luật nào sinh ra nó',
        );
      }
    });
  });

  group('⛔ không có xu hướng kênh', () {
    test('không phát hiện nào nói về tăng trưởng theo kênh', () {
      final result = engine.analyse(
        input(
          products: [
            product(id: 'p1', quantity: 1, costPrice: 10000, reorderLevel: 10),
          ],
          orders: [
            for (var i = 0; i < 6; i++)
              order(id: 'o$i', customerId: 'c$i', productId: 'p1'),
          ],
        ),
      );

      // Có `vendor`/`channel` trên đơn KHÔNG tương đương có luật xu hướng kênh.
      // Không luật ⇒ không dòng, kể cả khi dữ liệu trông như có xu hướng.
      expect(
        result.findings.any(
          (f) => f.ruleCode.contains('trend') || f.ruleCode.contains('channel'),
        ),
        isFalse,
      );
      expect(kFirstInsightRuleSources.any((c) => c.contains('trend')), isFalse);
    });
  });
}
