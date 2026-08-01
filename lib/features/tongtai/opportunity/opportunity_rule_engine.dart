import '../consumer/customer.dart';
import '../consumer/customer_order.dart';
import '../core/tongtai_enums.dart';
import '../inventory/product.dart';
import '../journey/business_goal.dart';
import '../journey/journey_progress.dart';
import '../metrics/business_metrics.dart';
import 'opportunity.dart';
import 'opportunity_score.dart';

/// The Opportunity **Rule Engine** (WTM-139, Founder default → ADR-TON-013):
/// generates real opportunities from the business's own data. The chain is
/// `Rule Engine → Opportunity → AI Scoring → AI Ranking → AI Explanation` —
/// the Rule Engine is **never replaced by AI**; AI only layers analysis on top.
///
/// Pure and deterministic: same inputs (+ the caller's `now`) → same
/// opportunities, same ids (`gen-…`), so reactions can be keyed against them.
/// **User Data First:** an empty business generates nothing. No AI, no network.
class OpportunityRuleEngine {
  const OpportunityRuleEngine({
    this.lapsedCustomerDays = 30,
    this.momentumWindowDays = 60,
  });

  /// A repeat customer counts as lapsed after this many days without an order.
  final int lapsedCustomerDays;

  /// Trailing window for product/category momentum.
  final int momentumWindowDays;

  /// Generates the current rule-based opportunities, strongest score first.
  List<Opportunity> generate({
    required List<Product> products,
    required List<Customer> customers,
    required List<CustomerOrder> orders,
    required List<BusinessGoal> goals,
    required DateTime now,
  }) {
    final billable = orders.billable.toList(growable: false);
    // What the business itself earns in the window. Every profit-potential
    // score is a ratio against this, because ₫5m means something different to
    // a ₫10m shop than to a ₫500m one (WTM-193).
    final baseline = _windowRevenue(billable, now);
    final result =
        <Opportunity>[
          ..._restock(products, billable, now, baseline),
          ..._winBack(customers, billable, now, baseline),
          ..._goalCatchUp(goals, billable, now, baseline),
          ..._categoryMomentum(billable, now, baseline),
        ]..sort((a, b) {
          // Unscorable last: an opportunity nobody can rank should not sit at the
          // top by accident.
          final c = (b.score.value ?? -1).compareTo(a.score.value ?? -1);
          return c != 0 ? c : a.id.compareTo(b.id);
        });
    return result;
  }

  /// The business's own revenue inside the momentum window — the yardstick
  /// every profit-potential score is measured against.
  double _windowRevenue(List<CustomerOrder> billable, DateTime now) {
    final cutoff = now.subtract(Duration(days: momentumWindowDays));
    var total = 0.0;
    for (final o in billable.where((o) => o.date.isAfter(cutoff))) {
      total += o.totalAmount;
    }
    return total;
  }

  /// Revenue per product name inside the momentum window.
  Map<String, double> _productRevenue(
    List<CustomerOrder> billable,
    DateTime now,
  ) {
    final cutoff = now.subtract(Duration(days: momentumWindowDays));
    final revenue = <String, double>{};
    for (final o in billable.where((o) => o.date.isAfter(cutoff))) {
      for (final item in o.items) {
        revenue.update(
          item.productName,
          (r) => r + item.lineTotal,
          ifAbsent: () => item.lineTotal,
        );
      }
    }
    return revenue;
  }

  /// Low/out-of-stock products that actually sell → restock before revenue is
  /// missed. Impact = the product's recent revenue; stronger when fully out.
  Iterable<Opportunity> _restock(
    List<Product> products,
    List<CustomerOrder> billable,
    DateTime now,
    double baseline,
  ) sync* {
    final revenue = _productRevenue(billable, now);
    final cutoff = now.subtract(Duration(days: momentumWindowDays));
    for (final p in products) {
      if (p.quantity > p.reorderLevel) continue;
      final recent = revenue[p.name] ?? 0;
      if (recent <= 0) continue; // no demand signal → no opportunity
      final out = p.quantity == 0;
      yield Opportunity(
        id: 'gen-restock-${p.id}',
        type: OpportunityType.trend,
        title: out ? 'Nhập lại ${p.name} (đã hết hàng)' : 'Sắp hết: ${p.name}',
        description:
            '${p.name} bán được ${_vnd(recent)} trong '
            '$momentumWindowDays ngày qua nhưng tồn kho còn ${p.quantity} '
            '(mức đặt lại ${p.reorderLevel}). '
            '${out ? 'Hết hàng là doanh thu bỏ lỡ mỗi ngày.' : 'Nhập thêm trước khi đứt hàng.'}',
        expectedImpact: recent,
        score: scoreOpportunity(
          impact: recent,
          baseline: baseline,
          // How many billable orders actually contained this product in the
          // window — the seller's own demand, not the market's.
          orders: billable
              .where(
                (o) =>
                    o.date.isAfter(cutoff) &&
                    o.items.any((i) => i.productName == p.name),
              )
              .length,
        ),
        discoveredAt: now,
      );
    }
  }

  /// Repeat customers who have gone quiet → a win-back nudge. Impact = their
  /// average order value (one comeback order).
  Iterable<Opportunity> _winBack(
    List<Customer> customers,
    List<CustomerOrder> billable,
    DateTime now,
    double baseline,
  ) sync* {
    final cutoff = now.subtract(Duration(days: lapsedCustomerDays));
    for (final c in customers) {
      final theirOrders = billable
          .where((o) => o.customerId == c.id)
          .toList(growable: false);
      if (theirOrders.length < 2) continue; // repeat customers only
      final last = theirOrders
          .map((o) => o.date)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      if (last.isAfter(cutoff)) continue; // still active
      final spend = theirOrders.fold<double>(0, (s, o) => s + o.totalAmount);
      final aov = spend / theirOrders.length;
      yield Opportunity(
        id: 'gen-winback-${c.id}',
        type: OpportunityType.trend,
        title: 'Chăm sóc lại ${c.name}',
        description:
            '${c.name} đã mua ${theirOrders.length} đơn (AOV ${_vnd(aov)}) '
            'nhưng im lặng hơn $lapsedCustomerDays ngày. Một tin nhắn kèm ưu '
            'đãi quay lại thường rẻ hơn nhiều so với tìm khách mới.',
        expectedImpact: aov,
        score: scoreOpportunity(
          impact: aov,
          baseline: baseline,
          // Their order history is the demand signal for winning them back.
          orders: theirOrders.length,
        ),
        discoveredAt: now,
      );
    }
  }

  /// Revenue goals behind pace → a catch-up push sized by the gap.
  Iterable<Opportunity> _goalCatchUp(
    List<BusinessGoal> goals,
    List<CustomerOrder> billable,
    DateTime now,
    double baseline,
  ) sync* {
    final cutoff = now.subtract(Duration(days: momentumWindowDays));
    for (final g in goals) {
      if (g.targetAmount <= 0) continue;
      final derived = deriveGoalProgress(g, billable, now);
      if (derived.pace(now) != GoalPace.behind) continue;
      final gap =
          g.targetAmount * derived.timelineElapsed(now) -
          derived.achievedAmount;
      if (gap <= 0) continue;
      yield Opportunity(
        id: 'gen-goal-${g.id}',
        type: OpportunityType.seasonal,
        title: 'Kéo lại mục tiêu: ${g.name}',
        description:
            'Mục tiêu đang chậm ${_vnd(gap)} so với nhịp thời gian '
            '(${(derived.progress * 100).round()}% sau '
            '${(derived.timelineElapsed(now) * 100).round()}% thời gian). '
            'Cân nhắc khuyến mãi ngắn hoặc mở thêm kênh bán.',
        expectedImpact: gap,
        score: scoreOpportunity(
          impact: gap,
          baseline: baseline,
          // Trading activity in the window is the demand signal behind a
          // catch-up push: a shop with no recent orders has no momentum to use.
          orders: billable.where((o) => o.date.isAfter(cutoff)).length,
        ),
        discoveredAt: now,
      );
    }
  }

  /// The strongest recent category → double down while it moves. Needs at
  /// least two billable orders in the window to count as momentum.
  Iterable<Opportunity> _categoryMomentum(
    List<CustomerOrder> billable,
    DateTime now,
    double baseline,
  ) sync* {
    final cutoff = now.subtract(Duration(days: momentumWindowDays));
    final recent = billable
        .where((o) => o.date.isAfter(cutoff))
        .toList(growable: false);
    if (recent.length < 2) return;
    final byCategory = <String, double>{};
    for (final o in recent) {
      for (final item in o.items) {
        byCategory.update(
          item.category,
          (r) => r + item.lineTotal,
          ifAbsent: () => item.lineTotal,
        );
      }
    }
    if (byCategory.isEmpty) return;
    final top = byCategory.entries.reduce((a, b) => a.value >= b.value ? a : b);
    yield Opportunity(
      id: 'gen-momentum-${top.key}',
      type: OpportunityType.trend,
      title: 'Đẩy thêm nhóm ${top.key}',
      description:
          'Nhóm ${top.key} dẫn đầu doanh thu $momentumWindowDays ngày qua '
          '(${_vnd(top.value)}). Cân nhắc thêm mẫu mới hoặc tăng hiển thị '
          'nhóm này khi đà còn tốt.',
      expectedImpact: top.value,
      score: scoreOpportunity(
        impact: top.value,
        baseline: baseline,
        orders: recent
            .where((o) => o.items.any((i) => i.category == top.key))
            .length,
      ),
      discoveredAt: now,
    );
  }

  static String _vnd(double amount) {
    final rounded = amount.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      if (i > 0 && (rounded.length - i) % 3 == 0) b.write('.');
      b.write(rounded[i]);
    }
    return '$b ₫';
  }
}
