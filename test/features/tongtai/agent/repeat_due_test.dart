import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/agent/business_brief.dart';
import 'package:tongtai/features/tongtai/agent/business_brief_service.dart';
import 'package:tongtai/features/tongtai/analytics/customer_rfm.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/predictive/customer_risk_rule.dart';

/// WTM-180 — **khách sắp tới nhịp mua lại**: mặt kia của cùng một tín hiệu.
///
/// Luật churn báo khách **đã** im lặng quá lâu — tin đến *sau* khi mất khách.
/// Cùng `gapRatio` đó, đọc ở đoạn ≈ 1.0, lại là tin đến *trước*.
void main() {
  final now = DateTime(2026, 8, 11);

  Customer customer(String id, String name) => Customer(
    id: id,
    name: name,
    phone: '0900000000',
    location: 'HCM',
    orderCount: 0,
    totalSpent: 0,
    lastPurchaseDate: null,
  );

  /// `gapRatio` = recency / medianGap.
  CustomerRfm rfm(
    String id, {
    required int gapDays,
    required int recency,
    int orders = 5,
  }) => CustomerRfm(
    customerId: id,
    recencyDays: recency,
    frequency: orders,
    monetary: 5000000,
    firstOrderAt: now.subtract(const Duration(days: 400)),
    lastOrderAt: now.subtract(Duration(days: recency)),
    medianGapDays: gapDays.toDouble(),
    ordersInWindow: orders,
  );

  List<BriefItem> brief(
    List<CustomerRfm> profiles, {
    CustomerRiskAssessment? risk,
  }) => const BusinessBriefService().derive(
    now: now,
    risk: risk,
    profiles: profiles,
    customers: [customer('c1', 'Chị Lan')],
  );

  List<BriefItem> repeatItems(List<BriefItem> items) => [
    for (final i in items)
      if (i.evidence.any((e) => e.source == 'rule:repeat-due')) i,
  ];

  test('⭐ tới đúng nhịp của chính khách đó ⇒ nhắc TRƯỚC khi họ quên', () {
    final items = repeatItems(brief([rfm('c1', gapDays: 30, recency: 28)]));

    expect(items, hasLength(1));
    expect(items.single.headline, contains('Chị Lan'));
    expect(items.single.headline, contains('30 ngày'));
    // Là cơ hội, không phải báo động — đẩy nó lên trên việc đang cháy là sai.
    expect(items.single.severity, BriefSeverity.info);
    expect(items.single.move, isNotNull);
  });

  test('⛔ còn sớm ⇒ im lặng, nhắc lúc đó chỉ làm phiền', () {
    expect(repeatItems(brief([rfm('c1', gapDays: 30, recency: 5)])), isEmpty);
  });

  test('⛔ đã trễ ⇒ thuộc về mục "khách đã im lặng", không phải mục này', () {
    expect(repeatItems(brief([rfm('c1', gapDays: 30, recency: 90)])), isEmpty);
  });

  test('⛔ chưa đủ đơn ⇒ chưa có NHỊP, không nhắc', () {
    // Hai đơn cho ra một khoảng cách, và một khoảng cách không phải thói quen.
    expect(
      repeatItems(brief([rfm('c1', gapDays: 30, recency: 28, orders: 2)])),
      isEmpty,
    );
  });

  test('⛔ chưa có nhịp (medianGapDays null) ⇒ không kết luận', () {
    final noCadence = CustomerRfm(
      customerId: 'c1',
      recencyDays: 28,
      frequency: 5,
      monetary: 1000000,
      firstOrderAt: now.subtract(const Duration(days: 100)),
      lastOrderAt: now.subtract(const Duration(days: 28)),
      medianGapDays: null,
      ordersInWindow: 5,
    );

    expect(repeatItems(brief([noCadence])), isEmpty);
  });
}
