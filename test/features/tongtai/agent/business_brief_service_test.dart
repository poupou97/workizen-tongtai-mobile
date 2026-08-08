import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/action/business_action.dart';
import 'package:tongtai/features/tongtai/agent/business_brief.dart';
import 'package:tongtai/features/tongtai/agent/business_brief_service.dart';
import 'package:tongtai/features/tongtai/analytics/customer_rfm.dart';
import 'package:tongtai/features/tongtai/capability/customer_capability.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/external_identity.dart';
import 'package:tongtai/features/tongtai/core/provenance.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/predictive/business_alerts_rule.dart';
import 'package:tongtai/features/tongtai/predictive/customer_risk_rule.dart';
import 'package:tongtai/features/tongtai/predictive/rule_twin.dart';
import 'package:tongtai/features/tongtai/proposal/proposed_change.dart';

/// WTM-303 · động cơ Brief — **hàm thuần trên đầu ra của Rule Twin**.
void main() {
  final now = DateTime(2026, 8, 8, 14);

  CustomerRiskEntry entry({
    String id = 'cust-1',
    CustomerLifecycleStage stage = CustomerLifecycleStage.atRisk,
    int? recencyDays = 45,
    int orders = 8,
    double value = 12400000,
    bool winBack = true,
  }) => CustomerRiskEntry(
    customerId: id,
    stage: stage,
    recencyDays: recencyDays,
    lifetimeOrders: orders,
    lifetimeValue: value,
    riskScore: 72,
    reasonCodes: const [ReasonCode.purchaseGapExceeded],
    winBackCandidate: winBack,
  );

  CustomerRiskAssessment risk(List<CustomerRiskEntry> entries) =>
      CustomerRiskAssessment(
        entries: entries,
        stageCounts: {
          for (final s in CustomerLifecycleStage.values)
            s: entries.where((e) => e.stage == s).length,
        },
        atRiskCount: entries.where((e) => e.isLapsed).length,
        churnedCount: 0,
        winBackCount: entries.where((e) => e.winBackCandidate).length,
      );

  Customer customer({String id = 'cust-1', String name = 'Chị Phương'}) =>
      Customer(
        id: id,
        name: name,
        phone: '0900000001',
        location: 'Đà Nẵng',
        orderCount: 8,
        totalSpent: 12400000,
        lastPurchaseDate: now.subtract(const Duration(days: 45)),
      );

  Product product({
    String id = 'prod-1',
    String name = 'Nồi chiên không dầu',
    int? quantity = 2,
    int? reorder = 10,
    double price = 1890000,
    double? cost,
  }) => Product(
    id: id,
    sku: 'SKU-1',
    name: name,
    category: 'Gia dụng',
    pricePerUnit: price,
    quantity: quantity,
    reorderLevel: reorder,
    costPrice: cost,
    updatedAt: now,
  );

  const service = BusinessBriefService();

  // ────────────────────────────────────────────────────────────────────────
  group(
    '⭐ Khách quen im lặng — "vì sao" đi kèm, không phải một con số trần',
    () {
      test('dựng đúng một việc, có tên và số ngày', () {
        final items = service.derive(
          now: now,
          risk: risk([entry()]),
          customers: [customer()],
        );

        expect(items, hasLength(1));
        final item = items.single;
        expect(item.kind, BriefKind.customerAtRisk);
        expect(item.headline, 'Chị Phương đã 45 ngày chưa quay lại');
        expect(item.isActionable, isTrue);
      });

      test('bằng chứng mang câu người bán ĐỌC ĐƯỢC, không mang mã', () {
        final items = service.derive(
          now: now,
          risk: risk([entry()]),
          customers: [customer()],
          profiles: const [
            CustomerRfm(
              customerId: 'cust-1',
              recencyDays: 45,
              frequency: 8,
              monetary: 12400000,
              medianGapDays: 18,
              firstOrderAt: null,
              lastOrderAt: null,
              ordersInWindow: 8,
            ),
          ],
        );

        final details = items.single.evidence.map((e) => e.detail).toList();
        expect(details, contains('Đã mua 8 lần'));
        expect(details, contains('Thường quay lại sau khoảng 18.0 ngày'));
        expect(details, contains('Lần mua gần nhất cách đây 45 ngày'));
      });

      test('⭐ bốn câu về CÙNG sổ sách chỉ tính là MỘT quan sát', () {
        // Đây là luật chống cộng dồn giả (WTM-298) nhìn từ phía người dùng.
        // Brief nói bốn điều về khách, nhưng cả bốn đọc ra từ cùng bản ghi
        // nghiệp vụ của chính người bán — cùng `EvidenceFamily.behaviour`. Nên
        // nó KHÔNG được chắc chắn gấp bốn.
        //
        // Nói cách khác: viết thêm một dòng "vì sao" cho người đọc **không** làm
        // máy tự tin hơn. Nếu có, thì mọi luật mới sẽ đẩy được điểm lên tuỳ ý.
        final item = service
            .derive(now: now, risk: risk([entry()]), customers: [customer()])
            .single;

        expect(item.evidence.length, greaterThan(2));
        expect(item.scored.countedSources, 1);
        expect(item.confidence, IdentityConfidence.strong);
      });

      test('chưa từng mua ⇒ KHÔNG phải "đã im lặng"', () {
        final items = service.derive(
          now: now,
          risk: risk([entry(recencyDays: null)]),
          customers: [customer()],
        );
        expect(items, isEmpty);
      });

      test('Rule Twin từ chối trả lời ⇒ không có việc nào về khách', () {
        // `null` là "chưa đủ dữ liệu để nói", KHÔNG phải "không có ai rủi ro".
        expect(service.derive(now: now, customers: [customer()]), isEmpty);
      });

      test('không tra được tên ⇒ nói "một khách quen", không đọc id ra', () {
        final item = service.derive(now: now, risk: risk([entry()])).single;
        expect(item.headline, 'Một khách quen đã 45 ngày chưa quay lại');
        expect(item.headline, isNot(contains('cust-1')));
      });

      test('không quá hai khách trong một brief', () {
        final items = service.derive(
          now: now,
          risk: risk([for (var i = 0; i < 6; i++) entry(id: 'cust-$i')]),
        );
        expect(
          items.where((i) => i.kind == BriefKind.customerAtRisk),
          hasLength(2),
        );
      });
    },
  );

  // ────────────────────────────────────────────────────────────────────────
  group('Sắp hết hàng — dùng CHỦ SỞ HỮU của khái niệm, không tự so sánh', () {
    test('còn dưới mức đặt lại ⇒ cảnh báo kèm số cần nhập', () {
      final item = service.derive(now: now, products: [product()]).single;
      expect(item.kind, BriefKind.stockRunningOut);
      expect(item.headline, 'Nồi chiên không dầu sắp hết — còn 2');
      expect(item.suggestion, contains('8'));
      expect(item.severity, BriefSeverity.warning);
    });

    test('hết sạch ⇒ nghiêm trọng', () {
      final item = service
          .derive(now: now, products: [product(quantity: 0)])
          .single;
      expect(item.severity, BriefSeverity.critical);
      expect(item.headline, contains('đã hết hàng'));
    });

    test('sản phẩm SỐ không bao giờ "hết hàng"', () {
      // ADR-TON-023: loại này không quản tồn, nên nó không có mức nào để tụt
      // xuống dưới. Một brief nói "khoá học sắp hết hàng" là brief làm người
      // bán thôi tin cả màn hình.
      final items = service.derive(
        now: now,
        products: [
          Product(
            id: 'course-1',
            sku: 'SKU-D',
            name: 'Khoá học bán hàng',
            category: 'Số',
            kind: ProductKind.digital,
            pricePerUnit: 499000,
            updatedAt: now,
          ),
        ],
      );
      expect(items.where((i) => i.kind == BriefKind.stockRunningOut), isEmpty);
    });

    test('việc nhập hàng là HÀNH ĐỘNG, không phải đổi một con số', () {
      final item = service.derive(now: now, products: [product()]).single;
      final move = item.move! as DoSomething;
      expect(move.actionType, BusinessActionType.inventoryCreatePurchaseOrder);
      expect(move.risk, ActionRisk.high, reason: 'nhập hàng là tiêu tiền thật');
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Biên lợi nhuận mỏng — chưa nhập chi phí KHÔNG phải lỗ', () {
    test('chưa có chi phí ⇒ im lặng, không khẳng định gì', () {
      final items = service.derive(
        now: now,
        products: [product(quantity: 99, cost: null)],
      );
      expect(items, isEmpty, reason: '`null` chi phí không phải biên bằng 0');
    });

    test('biên mỏng ⇒ đề nghị GIÁ MỚI, tính ra chứ không phỏng đoán', () {
      final item = service
          .derive(
            now: now,
            products: [product(quantity: 99, price: 100000, cost: 95000)],
          )
          .single;

      expect(item.kind, BriefKind.marginTooThin);
      final move = item.move! as ChangeAFact;
      expect(move.domain, ProposalDomain.pricing);
      expect(move.field, 'pricePerUnit');
      // 95.000 / (1 − 0,15) = 111.764,7… ⇒ làm tròn lên nghìn.
      expect(move.proposedValue, '112000');
      expect(move.currentValue, '100000');
    });

    test('bán dưới giá vốn ⇒ nghiêm trọng', () {
      final item = service
          .derive(
            now: now,
            products: [product(quantity: 99, price: 80000, cost: 95000)],
          )
          .single;
      expect(item.severity, BriefSeverity.critical);
      expect(item.headline, contains('dưới giá vốn'));
    });

    test('biên khoẻ ⇒ không nói gì', () {
      final items = service.derive(
        now: now,
        products: [product(quantity: 99, price: 200000, cost: 80000)],
      );
      expect(items, isEmpty);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Cảnh báo vĩ mô — KHÔNG bịa ra một nút bấm', () {
    BusinessAlert alert(BusinessAlertKind kind) => BusinessAlert(
      kind: kind,
      severity: BusinessAlertSeverity.warning,
      reasonCodes: const [ReasonCode.revenueDropVsPrevious],
      metricValue: 8000000,
      comparisonValue: 12000000,
      affectedCount: 3,
    );

    test('doanh thu giảm ⇒ có việc để BIẾT, không có việc để BẤM', () {
      final item = service
          .derive(now: now, alerts: [alert(BusinessAlertKind.revenueDrop)])
          .single;
      expect(item.kind, BriefKind.businessSignal);
      expect(
        item.isActionable,
        isFalse,
        reason: 'không có một việc đúng duy nhất cho "doanh thu giảm"',
      );
    });

    test('cảnh báo đã có việc cụ thể hơn thì KHÔNG nhắc lại', () {
      final items = service.derive(
        now: now,
        alerts: [
          alert(BusinessAlertKind.stockBelowReorder),
          alert(BusinessAlertKind.customerRisk),
        ],
      );
      expect(items, isEmpty);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Thứ tự, số lượng, nguồn gốc', () {
    test('khẩn trước, và cùng dữ liệu ⇒ cùng thứ tự', () {
      final products = [
        product(id: 'p-low', quantity: 2),
        product(id: 'p-out', quantity: 0),
      ];
      final first = service.derive(now: now, products: products);
      final second = service.derive(
        now: now,
        products: products.reversed.toList(),
      );

      expect(first.first.subjectId, 'p-out');
      expect(first.map((i) => i.id), second.map((i) => i.id));
    });

    test('cắt còn tối đa maxItems', () {
      const small = BusinessBriefService(maxItems: 2);
      final items = small.derive(
        now: now,
        risk: risk([entry(id: 'c1'), entry(id: 'c2')]),
        products: [
          product(id: 'p1'),
          product(id: 'p2', quantity: 0),
        ],
      );
      expect(items, hasLength(2));
    });

    test('⭐ việc về dữ liệu MẪU khai đúng là mẫu', () {
      final item = service
          .derive(
            now: now,
            products: [product(id: 'sample-prod-1')],
          )
          .single;
      expect(item.isDemo, isTrue);
      expect(item.provenance.source, ProvenanceSource.sample);
      expect(
        item.provenance.inferred,
        isFalse,
        reason: 'bản ghi phải TỰ KHAI nguồn gốc, không để người sau đoán lại',
      );
    });

    test('việc về dữ liệu thật KHÔNG bị gắn nhãn mẫu', () {
      final item = service.derive(now: now, products: [product()]).single;
      expect(item.isDemo, isFalse);
      expect(item.provenance.source, ProvenanceSource.manual);
    });

    test('id tất định ⇒ dựng lại không sinh việc thứ hai', () {
      final a = service.derive(now: now, products: [product()]).single;
      final b = service
          .derive(now: now.add(const Duration(hours: 3)), products: [product()])
          .single;
      expect(a.id, b.id);
      expect(a, b);
    });

    test('mức tin cậy được TÍNH, đủ mạnh để mời người bán quyết', () {
      final item = service.derive(now: now, products: [product()]).single;
      expect(item.confidence, IdentityConfidence.strong);
    });
  });
}
