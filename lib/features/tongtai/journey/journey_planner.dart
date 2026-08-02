/// Rule Twin — turns a goal into a plan (WTM-186, ADR-TON-021 + ADR-TON-016).
///
/// ## This file never calls a model
/// ADR-TON-016 puts the Rule Twin in charge: it runs with **no network, no API
/// key and no AI**, and when the data is not there it says so rather than
/// inventing steps. AI, when a seller has it configured, may *explain* a plan;
/// it may not write one, change one, or tick anything off.
///
/// That is not a limitation to work around. Most of the target users have no
/// API key (WTM-176), so a planner that needed one would leave the majority of
/// sellers with an empty Journey — the capability the Concept calls P0.
///
/// ## Deterministic on purpose
/// Same goal + same profile + same numbers ⇒ byte-identical plan. A plan that
/// shifted between reads would read as the app changing its mind, and the
/// versioning in [JourneyPlan] would record noise instead of real adaptation.
library;

import '../profile/business_profile.dart';
import 'business_goal.dart';
import 'journey.dart';
import 'journey_metric.dart';
import 'journey_node.dart';

/// What the planner knows about the business right now.
///
/// Deliberately a small value object rather than `BusinessContext`: the planner
/// is a pure function, and passing the whole context would let it reach for
/// anything and make "same input, same plan" impossible to check.
class JourneyPlanInput {
  const JourneyPlanInput({
    required this.goal,
    this.profile = BusinessProfile.empty,
    this.productCount = 0,
    this.customerCount = 0,
    this.orderCount = 0,
    this.expenseCount = 0,
    this.receivables = 0,
    this.debtorCount = 0,
  });

  final BusinessGoal goal;
  final BusinessProfile profile;
  final int productCount;
  final int customerCount;
  final int orderCount;

  /// Money earned but not received, in đồng (WTM-211).
  ///
  /// Feeds the "collect the debt" step — the second money step after WTM-198,
  /// and the reason the receivables view exists at all (D-11: Finance does not
  /// get stronger, the Journey gets smarter).
  final double receivables;

  /// How many customers still owe money.
  final int debtorCount;

  /// How many expense rows the seller has recorded (WTM-198).
  ///
  /// Decides what the money milestone asks for: a ledger with nothing in it
  /// gets *"record your first expenses"* as a **measured** step, while a
  /// seller already recording gets the profit-reading steps. A plan that told
  /// everyone the same thing about money was a plan that had not looked.
  final int expenseCount;
}

/// Why a plan, or a step in it, looks the way it does.
///
/// Fixed tokens — never built from data — so they are safe to put in telemetry
/// and stable enough to translate. Same discipline as `TongtaiFailure.code`.
abstract final class JourneyReason {
  static const String goalRevenue = 'goal.revenue';
  static const String goalNewChannel = 'goal.new_channel';
  static const String goalCustomerGrowth = 'goal.customer_growth';
  static const String goalProductLaunch = 'goal.product_launch';

  static const String profileKnown = 'profile.known';
  static const String profileUnknown = 'profile.unknown';
  static const String profileSeasonal = 'profile.seasonal';
  static const String profileOnline = 'profile.channel_online';
  static const String profileOffline = 'profile.channel_offline';
  static const String profileSolo = 'profile.size_solo';
  static const String profileNoStock = 'profile.no_stock';

  static const String dataEmptyCatalog = 'data.empty_catalog';
  static const String dataEmptyExpenses = 'data.empty_expenses';
  static const String dataEmptyCustomers = 'data.empty_customers';
  static const String dataHasHistory = 'data.has_history';

  /// The seller turned an opportunity into this piece of work (WTM-191).
  /// Not produced by any rule — it records a decision, which is why the node
  /// carrying it survives a re-plan.
  static const String fromOpportunity = 'source.opportunity';

  /// The seller has material money stuck in unpaid orders (WTM-211).
  static const String dataReceivables = 'data.receivables';
}

/// The outcome of planning: either a plan, or an honest refusal.
///
/// `insufficient` is a real answer, not a failure (ADR-TON-017): a brand-new
/// business genuinely cannot be planned for yet, and saying so beats inventing
/// eight plausible steps that fit nobody.
class JourneyPlanResult {
  const JourneyPlanResult.ready(this.nodes, this.reasonCodes)
    : isSufficient = true;

  const JourneyPlanResult.insufficient(this.reasonCodes)
    : nodes = const [],
      isSufficient = false;

  final bool isSufficient;
  final List<JourneyNode> nodes;
  final List<String> reasonCodes;
}

/// Builds the plan for [input]. Pure — no clock, no I/O, no randomness.
///
/// [journeyId] and [idPrefix] are supplied by the caller so ids are stable and
/// testable; the planner never invents one.
JourneyPlanResult planJourney(
  JourneyPlanInput input, {
  required String journeyId,
  String idPrefix = 'n',
}) {
  final reasons = <String>[_goalReason(input.goal.type)];
  reasons.add(
    input.profile.isEmpty
        ? JourneyReason.profileUnknown
        : JourneyReason.profileKnown,
  );

  // A goal with no catalog and no customers has nothing to plan against. The
  // planner refuses rather than producing generic advice — the seller's first
  // real action is to put something in the app, and a plan cannot say that
  // more usefully than an empty state can.
  if (input.productCount == 0 && input.customerCount == 0) {
    return JourneyPlanResult.insufficient([
      ...reasons,
      JourneyReason.dataEmptyCatalog,
      JourneyReason.dataEmptyCustomers,
    ]);
  }

  if (input.orderCount > 0) reasons.add(JourneyReason.dataHasHistory);
  if (input.profile.seasonality != null &&
      input.profile.seasonality != BusinessSeasonality.none) {
    reasons.add(JourneyReason.profileSeasonal);
  }
  if (input.profile.size == BusinessSize.solo) {
    reasons.add(JourneyReason.profileSolo);
  }
  if (_sellsWithoutStock(input.profile)) {
    reasons.add(JourneyReason.profileNoStock);
  }
  if (_hasOnlineChannel(input.profile)) {
    reasons.add(JourneyReason.profileOnline);
  }
  if (_hasOfflineChannel(input.profile)) {
    reasons.add(JourneyReason.profileOffline);
  }

  final builder = _NodeBuilder(journeyId: journeyId, idPrefix: idPrefix);
  final blueprint = _blueprintFor(input);
  for (final milestone in blueprint) {
    final parent = builder.add(
      kind: JourneyNodeKind.milestone,
      title: milestone.title,
      reasonCodes: milestone.reasonCodes,
    );
    for (final step in milestone.steps) {
      builder.add(
        kind: JourneyNodeKind.step,
        title: step.title,
        parentId: parent.id,
        reasonCodes: step.reasonCodes,
        metric: step.metric,
        target: step.target,
      );
    }
  }

  return JourneyPlanResult.ready(builder.nodes, reasons);
}

// ── blueprint ───────────────────────────────────────────────────────────────

class _Step {
  const _Step(
    this.title, {
    this.reasonCodes = const [],
    this.metric,
    this.target,
  });
  final String title;
  final List<String> reasonCodes;
  final String? metric;
  final double? target;
}

class _Milestone {
  const _Milestone(this.title, this.steps, {this.reasonCodes = const []});
  final String title;
  final List<_Step> steps;
  final List<String> reasonCodes;
}

/// The plan shape per goal type, adjusted by what we know about the business.
///
/// Vietnamese text is fixed here rather than localized: a plan is **stored
/// data**, so its wording must not change when the seller switches interface
/// language — the same rule that keeps enum codes out of the display layer.
List<_Milestone> _blueprintFor(JourneyPlanInput input) =>
    switch (input.goal.type) {
      GoalType.revenue => _revenuePlan(input),
      GoalType.newChannel => _newChannelPlan(input),
      GoalType.customerGrowth => _customerGrowthPlan(input),
      GoalType.productLaunch => _productLaunchPlan(input),
    };

List<_Milestone> _revenuePlan(JourneyPlanInput input) {
  final target = input.goal.targetAmount;
  return [
    // WTM-198: what the money milestone asks depends on where the seller is.
    // An empty ledger gets a **measured** first step — five recorded expenses
    // is an observation, not a checkbox (ADR-TON-021: progress is measured,
    // not declared). A seller already recording is past that, and gets the
    // profit-reading steps instead. Before this, everyone got the same two
    // manual ticks regardless of their data.
    if (input.expenseCount == 0)
      _Milestone('Biết tiền đang đi đâu', [
        _Step(
          'Ghi 5 khoản chi đầu tiên',
          metric: JourneyMetric.expenses.code,
          target: 5,
          reasonCodes: [JourneyReason.dataEmptyExpenses],
        ),
      ])
    else
      const _Milestone('Biết tiền đang đi đâu', [
        _Step('Ghi đủ chi phí tháng này'),
        _Step('Xem lãi lỗ theo nhóm hàng'),
      ]),
    _Milestone('Bán được nhiều hơn cho khách đang có', [
      _Step(
        'Liên hệ lại 10 khách mua gần nhất',
        metric: JourneyMetric.customers.code,
        target: 10,
        reasonCodes: const [JourneyReason.dataHasHistory],
      ),
      const _Step('Gợi ý sản phẩm mua kèm cho đơn tiếp theo'),
    ]),
    // WTM-211 (D-11): money the seller already earned is the cheapest revenue
    // there is — collecting it beats finding new sales. The step is measured:
    // it completes when the receivables actually shrink, not when a box is
    // ticked. Only when the debt is material (> 10% of the target), so a shop
    // with one small unpaid order is not nagged.
    if (input.receivables > target * 0.1 && input.debtorCount > 0)
      _Milestone(
        'Thu tiền đang bị kẹt',
        [
          _Step(
            'Thu nợ ${input.debtorCount} khách đang thiếu tiền',
            metric: JourneyMetric.receivables.code,
            // Completion = the outstanding amount drops to under half of what
            // it is today. refreshDerived only moves forward, so a new debt
            // later does not un-finish the work.
            target: input.receivables / 2,
            reasonCodes: const [JourneyReason.dataReceivables],
          ),
        ],
        reasonCodes: const [JourneyReason.dataReceivables],
      ),
    _Milestone('Chạm mốc doanh thu', [
      _Step(
        'Đạt ${_money(target)} doanh thu',
        metric: JourneyMetric.revenue.code,
        target: target,
      ),
    ]),
  ];
}

List<_Milestone> _newChannelPlan(JourneyPlanInput input) {
  final online = _hasOnlineChannel(input.profile);
  return [
    _Milestone(
      online
          ? 'Chọn kênh mới ngoài kênh đang bán'
          : 'Chọn kênh bán online đầu tiên',
      [
        const _Step('Xem nhóm hàng nào bán chạy nhất hiện tại'),
        _Step(
          online
              ? 'Chọn một kênh chưa dùng để thử'
              : 'Chọn một sàn để mở gian hàng',
          reasonCodes: online
              ? const [JourneyReason.profileOnline]
              : const [JourneyReason.profileOffline],
        ),
      ],
      reasonCodes: const [JourneyReason.goalNewChannel],
    ),
    _Milestone('Đưa hàng lên kênh mới', [
      _Step(
        'Đăng 10 sản phẩm đầu tiên',
        metric: JourneyMetric.products.code,
        target: 10,
      ),
      const _Step('Đặt giá đã tính phí kênh và phí ship'),
    ]),
    _Milestone('Có đơn đầu tiên từ kênh mới', [
      const _Step('Ghi nhận đơn đầu tiên vào ứng dụng'),
      const _Step('So lãi kênh mới với kênh cũ'),
    ]),
  ];
}

List<_Milestone> _customerGrowthPlan(JourneyPlanInput input) {
  return [
    _Milestone('Giữ khách đang có trước', [
      const _Step('Xem danh sách khách sắp rời bỏ'),
      _Step(
        'Liên hệ lại 5 khách rủi ro cao nhất',
        metric: JourneyMetric.customers.code,
        target: 5,
      ),
    ]),
    _Milestone('Tìm khách mới', [
      if (_hasOfflineChannel(input.profile))
        const _Step(
          'Xin thông tin liên hệ của khách mua tại cửa hàng',
          reasonCodes: [JourneyReason.profileOffline],
        ),
      const _Step('Nhờ khách cũ giới thiệu'),
      // WTM-198: acquiring customers costs money (ads, ưu đãi, quà giới
      // thiệu), and a plan that never asks what that costs cannot answer
      // whether the growth was worth it. An empty ledger gets the measured
      // first-expenses step; a seller already recording is asked to book the
      // acquisition costs specifically.
      if (input.expenseCount == 0)
        _Step(
          'Ghi 5 khoản chi đầu tiên',
          metric: JourneyMetric.expenses.code,
          target: 5,
          reasonCodes: [JourneyReason.dataEmptyExpenses],
        )
      else
        const _Step('Ghi chi phí tìm khách (quảng cáo, ưu đãi) vào sổ chi'),
    ]),
    _Milestone('Chạm mốc số khách', [
      _Step(
        'Đạt ${input.goal.growthTarget} khách mới',
        metric: JourneyMetric.customers.code,
        target: input.goal.growthTarget.toDouble(),
      ),
    ]),
  ];
}

List<_Milestone> _productLaunchPlan(JourneyPlanInput input) {
  final seasonal =
      input.profile.seasonality != null &&
      input.profile.seasonality != BusinessSeasonality.none;
  // Dogfood finding (2026-08-01): running this planner against Workizen's own
  // shape — a solo services business — produced "nhập hàng và ghi giá vốn".
  // A business with nothing to warehouse does not import stock, and advice
  // that assumes it reads as software that has not understood you.
  final noStock = _sellsWithoutStock(input.profile);
  return [
    _Milestone(noStock ? 'Chọn thứ để ra mắt' : 'Chọn hàng để ra mắt', [
      if (noStock)
        const _Step(
          'Xem khách đang hỏi nhiều nhất về việc gì',
          reasonCodes: [JourneyReason.profileNoStock],
        )
      else
        const _Step('Xem nhóm hàng nào đang thiếu trong kho'),
      if (seasonal)
        const _Step(
          'Chọn thời điểm ra mắt hợp mùa cao điểm sắp tới',
          reasonCodes: [JourneyReason.profileSeasonal],
        ),
    ]),
    _Milestone('Chuẩn bị bán', [
      if (noStock)
        const _Step(
          'Xác định chi phí thật để làm ra nó',
          reasonCodes: [JourneyReason.profileNoStock],
        )
      else
        const _Step('Nhập hàng và ghi giá vốn'),
      const _Step('Đặt giá bán đã tính đủ chi phí'),
    ]),
    _Milestone('Ra mắt', [
      const _Step('Báo cho khách cũ trước khi mở bán'),
      const _Step('Ghi nhận đơn đầu tiên'),
    ]),
  ];
}

// ── helpers ─────────────────────────────────────────────────────────────────

class _NodeBuilder {
  _NodeBuilder({required this.journeyId, required this.idPrefix});

  final String journeyId;
  final String idPrefix;
  final List<JourneyNode> nodes = [];
  int _seq = 0;

  JourneyNode add({
    required JourneyNodeKind kind,
    required String title,
    String? parentId,
    List<String> reasonCodes = const [],
    String? metric,
    double? target,
  }) {
    final node = JourneyNode(
      id: '$idPrefix-${_seq++}',
      journeyId: journeyId,
      parentId: parentId,
      kind: kind,
      title: title,
      // Every node this file produces is authored by the rule, never by a
      // model. ADR-TON-016 lives or dies on this line being honest.
      origin: JourneyNodeOrigin.ruleTwin,
      orderIndex: _seq,
      completion: metric == null
          ? JourneyCompletion.manual
          : JourneyCompletion.derived,
      derivedMetric: metric,
      derivedTarget: target,
      reasonCodes: reasonCodes,
    );
    nodes.add(node);
    return node;
  }
}

String _goalReason(GoalType type) => switch (type) {
  GoalType.revenue => JourneyReason.goalRevenue,
  GoalType.newChannel => JourneyReason.goalNewChannel,
  GoalType.customerGrowth => JourneyReason.goalCustomerGrowth,
  GoalType.productLaunch => JourneyReason.goalProductLaunch,
};

bool _hasOnlineChannel(BusinessProfile p) => p.channels.any(
  (c) => const {
    SalesChannel.shopee,
    SalesChannel.tiktok,
    SalesChannel.facebook,
    SalesChannel.zalo,
  }.contains(c),
);

/// True for a trade with nothing to warehouse.
///
/// Services and digital work have no stock to import, no cost price per unit
/// and no warehouse — so every step written for physical goods is wrong for
/// them. Found by running the planner against Workizen's own shape.
bool _sellsWithoutStock(BusinessProfile p) => p.trade == BusinessTrade.services;

bool _hasOfflineChannel(BusinessProfile p) => p.channels.any(
  (c) => const {
    SalesChannel.shop,
    SalesChannel.market,
    SalesChannel.wholesale,
  }.contains(c),
);

/// Compact money for a step title. Not `TongtaiFormatters` because a plan is
/// stored text: it must read the same next year, regardless of locale.
String _money(double amount) {
  if (amount >= 1000000000) {
    return '${(amount / 1000000000).toStringAsFixed(1)} tỷ';
  }
  if (amount >= 1000000) return '${(amount / 1000000).round()} triệu';
  if (amount >= 1000) return '${(amount / 1000).round()} nghìn';
  return amount.round().toString();
}
