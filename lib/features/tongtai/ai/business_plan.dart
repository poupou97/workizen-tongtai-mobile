import '../metrics/business_context.dart';
import '../metrics/business_context_service.dart';
import 'business_ai_engine.dart';
import 'tongtai_ai_provider_kind.dart';
import 'tongtai_ai_service.dart';

/// G-3C — AI Planner (WTM-136, ADR-TON-013 pre-approved stage 3).
///
/// Generates a **plan** — prioritized steps, a weekly cadence and KPIs to
/// watch — from the BusinessContext snapshot. The plan is text the seller
/// reads and acts on themself: **nothing is ever auto-executed.** Same engine
/// invariants as every stage (context-only boundary, rule twin, zero-spend).

/// Where a plan came from — an AI provider, or the deterministic rule.
enum BusinessPlanSource { ai, rule }

/// The result of a planning run (G-3C): plain text + provenance. Read-only.
class BusinessPlan {
  const BusinessPlan({
    required this.text,
    required this.source,
    required this.generatedAt,
    this.provider,
  });

  final String text;
  final BusinessPlanSource source;
  final DateTime generatedAt;

  /// The provider that answered when [source] is ai.
  final TongtaiAiProviderKind? provider;

  bool get isAi => source == BusinessPlanSource.ai;
}

/// Deterministic plan from the snapshot's signals — the AI-off/offline answer,
/// and the fallback when every provider fails. Steps are prioritized the way a
/// seller should act: stop losses first (stock-outs), then cash in flight
/// (open orders), then growth (goals/opportunities/repeat customers). Pure.
String ruleBasedBusinessPlan(BusinessContext ctx) {
  if (!ctx.hasData) {
    return 'Chưa có dữ liệu để lập kế hoạch. Bắt đầu bằng khách hàng, sản '
        'phẩm và đơn hàng đầu tiên — kế hoạch tuần sẽ xuất hiện ở đây. '
        '(No data yet — add your first records.)';
  }
  final steps = <String>[];
  if (ctx.inventory.outOfStockCount > 0) {
    steps.add(
      'Nhập lại ${ctx.inventory.outOfStockCount} sản phẩm đã hết hàng '
      '(chặn doanh thu bỏ lỡ).',
    );
  }
  if (ctx.orders.openCount > 0) {
    steps.add(
      'Chốt ${ctx.orders.openCount} đơn đang mở — xác nhận, giao và thu tiền.',
    );
  }
  if (ctx.inventory.lowStockCount > 0) {
    steps.add(
      'Đặt bổ sung ${ctx.inventory.lowStockCount} sản phẩm sắp hết trước khi '
      'đứt hàng.',
    );
  }
  if (ctx.journey.atRiskCount > 0) {
    steps.add(
      'Kéo lại ${ctx.journey.atRiskCount} mục tiêu đang chậm — chạy khuyến '
      'mãi hoặc mở thêm kênh bán.',
    );
  }
  if (ctx.opportunity.total > 0) {
    steps.add(
      'Duyệt ${ctx.opportunity.total} cơ hội đang mở, chọn 1 cơ hội để thử '
      'trong tuần.',
    );
  }
  if (ctx.customers.total > 0) {
    steps.add(
      'Nhắn lại nhóm khách cũ (${ctx.customers.total} khách) với 1 ưu đãi '
      'quay lại.',
    );
  }
  if (steps.isEmpty) {
    steps.add('Duy trì nhịp bán hiện tại và tiếp tục ghi nhận dữ liệu.');
  }

  final b = StringBuffer()..writeln('Kế hoạch tuần này (theo thứ tự ưu tiên):');
  for (var i = 0; i < steps.length; i++) {
    b.writeln('${i + 1}. ${steps[i]}');
  }
  b
    ..writeln(
      'KPI theo dõi: doanh thu · số đơn mới · đơn đang mở · tồn kho thấp.',
    )
    ..write(
      '(Kế hoạch rule-based — thêm API key trong More → AI Assistant để nhận '
      'kế hoạch AI cá nhân hoá. Không bước nào tự chạy — bạn quyết định.)',
    );
  return b.toString();
}

/// G-3C service: one [BusinessPlan] per call via the shared engine. The plan is
/// only ever rendered — never executed.
class BusinessPlanService {
  BusinessPlanService(
    TongtaiAiService ai,
    BusinessContextService context, {
    List<TongtaiAiProviderKind> preference = const [],
    DateTime Function()? clock,
  }) : _engine = BusinessAiEngine(
         ai,
         context,
         preference: preference,
         clock: clock,
       );

  final BusinessAiEngine _engine;

  static const String _instruction =
      'Bạn là Workizen AI. Từ tình hình kinh doanh dưới đây, lập KẾ HOẠCH '
      'TUẦN cho chủ shop SME Việt Nam: 3–6 bước đánh số theo thứ tự ưu tiên '
      '(mỗi bước 1 dòng, kèm lý do từ số liệu), sau đó 1 dòng "KPI theo dõi". '
      'CHỈ dùng số liệu được cung cấp; không bịa. Đây là kế hoạch để chủ shop '
      'tự thực hiện — không bước nào được thực thi tự động.';

  /// Produces the plan for the business's current snapshot. Read-only.
  Future<BusinessPlan> plan() async {
    final outcome = await _engine.run(
      instruction: _instruction,
      ruleFallback: ruleBasedBusinessPlan,
    );
    return BusinessPlan(
      text: outcome.text,
      source: outcome.isAi ? BusinessPlanSource.ai : BusinessPlanSource.rule,
      generatedAt: outcome.generatedAt,
      provider: outcome.provider,
    );
  }
}
