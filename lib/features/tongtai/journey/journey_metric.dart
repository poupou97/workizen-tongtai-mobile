import 'journey_node.dart';

/// The real numbers a journey step can complete itself against (WTM-220).
///
/// `JourneyNode.derivedMetric` has always been a **free string** written by the
/// planner and read by `JourneyController.refreshDerived` — the same shape as
/// `FinanceCategory` before WTM-197 and `SalesChannel` before WTM-209. The
/// codes below are exactly the strings already persisted, so this is a
/// vocabulary, not a migration.
///
/// An unknown code stays `null`: a journey restored from a `.ttbk` written by a
/// newer build may name a metric this build has never heard of, and guessing
/// which one it meant would send the seller off to do the wrong work
/// (ADR-TON-018 applied to a step instead of a row).
enum JourneyMetric {
  /// Số khoản thu chi đã ghi.
  expenses('expenses'),

  /// Số khách hàng trong danh bạ.
  customers('customers'),

  /// Số sản phẩm trong kho.
  products('products'),

  /// Doanh thu tính từ đơn hàng.
  revenue('revenue'),

  /// Tiền đang bị khách nợ.
  receivables('receivables');

  const JourneyMetric(this.code);

  /// Mã lưu xuống DB và `.ttbk`. **Không bao giờ là nhãn hiển thị.**
  final String code;

  static JourneyMetric? fromCode(String? code) {
    for (final m in JourneyMetric.values) {
      if (m.code == code) return m;
    }
    return null;
  }
}

/// Where a seller goes to actually do a step (WTM-220).
///
/// Nothing here is stored: the destination is **derived** from the metric the
/// step already declares. A `targetScreen` column would be a second truth able
/// to disagree with `derivedMetric` — the defect family this repo spent
/// WTM-196/200/201/205 removing.
enum JourneyDestination { finance, customers, inventory, opportunity }

/// The one rule mapping a step to the place its work happens.
///
/// Returns `null` when there is nowhere honest to send the seller — a
/// milestone, a step they wrote themselves, or a metric this build does not
/// know. A button that goes nowhere is worse than no button (WTM-169).
JourneyDestination? journeyNodeDestination(JourneyNode node) {
  // A step created from an opportunity belongs to that opportunity, whatever
  // it measures: the seller's question there is "what was this again?".
  if (node.isFromOpportunity) return JourneyDestination.opportunity;

  return switch (JourneyMetric.fromCode(node.derivedMetric)) {
    JourneyMetric.expenses => JourneyDestination.finance,
    // Receivables live on the Finance screen (WTM-211) — collecting a debt
    // starts by looking at who owes what.
    JourneyMetric.receivables => JourneyDestination.finance,
    JourneyMetric.customers => JourneyDestination.customers,
    JourneyMetric.products => JourneyDestination.inventory,
    // Revenue moves when a sale is recorded, and a sale is recorded against a
    // customer (the create-order flow launches from a customer's history), so
    // the honest first step is the customer list — not a Reports dashboard,
    // which only *shows* revenue that already happened.
    JourneyMetric.revenue => JourneyDestination.customers,
    null => null,
  };
}

/// The numbers a journey measures its steps against, keyed by
/// [JourneyMetric.code] — the shape `JourneyController.refreshDerived` reads.
///
/// One builder, so the journey cannot measure "customers" one way on Home and
/// another way on the journey screen. Every input arrives from the capability
/// that already owns it: revenue from `BusinessMetrics` (the KPI source of
/// truth, ADR-TON-011), counts from the repositories the screens read.
///
/// **[JourneyMetric.receivables] is deliberately absent.** It completes by
/// FALLING — a seller owed more money has not finished collecting — and
/// `refreshDerived` only ever moves steps forward. Feeding it in would mark
/// "thu nợ" done the moment debt grew. That step stays manual (WTM-211).
Map<String, double> journeyMetrics({
  required int productCount,
  required int customerCount,
  required int expenseCount,
  required double revenue,
}) => {
  JourneyMetric.products.code: productCount.toDouble(),
  JourneyMetric.customers.code: customerCount.toDouble(),
  JourneyMetric.expenses.code: expenseCount.toDouble(),
  JourneyMetric.revenue.code: revenue,
};
