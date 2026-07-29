import '../core/tongtai_formatters.dart';
import '../metrics/business_context.dart';
import '../metrics/business_context_service.dart';
import 'business_ai_engine.dart';
import 'tongtai_ai_provider_kind.dart';
import 'tongtai_ai_service.dart';

/// G-3B — AI Recommendation (WTM-135, ADR-TON-013 pre-approved stage 2).
///
/// Generates **suggestions only**: no business-data mutation, nothing is
/// auto-executed, no side effects — the seller decides what to act on. Same
/// invariants as every stage: the AI sees only the serialized BusinessContext,
/// and the deterministic rule twin answers when AI is off/offline.

/// Where a recommendation came from — an AI provider, or the deterministic rule.
enum BusinessRecommendationSource { ai, rule }

/// The result of a recommendation run (G-3B): plain text + provenance.
/// Read-only — rendering it is the only thing that ever happens with it.
class BusinessRecommendation {
  const BusinessRecommendation({
    required this.text,
    required this.source,
    required this.generatedAt,
    this.provider,
  });

  final String text;
  final BusinessRecommendationSource source;
  final DateTime generatedAt;

  /// The provider that answered when [source] is ai.
  final TongtaiAiProviderKind? provider;

  bool get isAi => source == BusinessRecommendationSource.ai;
}

/// Deterministic, actionable suggestions from the snapshot's signals — the
/// AI-off/offline answer, and the fallback when every provider fails. Pure.
String ruleBasedBusinessRecommendations(BusinessContext ctx) {
  if (!ctx.hasData) {
    return 'Chưa có dữ liệu để gợi ý. Bắt đầu bằng cách thêm khách hàng, '
        'sản phẩm và ghi đơn hàng đầu tiên — gợi ý hành động sẽ xuất hiện '
        'ở đây. (No data yet — add your first records.)';
  }
  final b = StringBuffer();
  if (ctx.orders.openCount > 0) {
    b.writeln(
      '• Theo dõi ${ctx.orders.openCount} đơn đang mở — xác nhận/giao sớm '
      'để ghi nhận doanh thu.',
    );
  }
  if (ctx.inventory.outOfStockCount > 0) {
    b.writeln(
      '• Nhập lại ${ctx.inventory.outOfStockCount} sản phẩm đã hết hàng — '
      'hết hàng là doanh thu bỏ lỡ.',
    );
  }
  if (ctx.inventory.lowStockCount > 0) {
    b.writeln(
      '• Kiểm tra ${ctx.inventory.lowStockCount} sản phẩm sắp hết — đặt thêm '
      'trước khi đứt hàng.',
    );
  }
  if (ctx.journey.atRiskCount > 0) {
    b.writeln(
      '• ${ctx.journey.atRiskCount} mục tiêu đang chậm tiến độ — cân nhắc '
      'khuyến mãi hoặc thêm kênh bán.',
    );
  }
  if (ctx.opportunity.total > 0) {
    b.writeln(
      '• Xem lại ${ctx.opportunity.total} cơ hội đang mở trong Opportunity Hub.',
    );
  }
  if (ctx.metrics.hasSales && ctx.customers.total > 0) {
    b.writeln(
      '• Chăm sóc lại khách cũ (${ctx.customers.total} khách, AOV '
      '${TongtaiFormatters.vnd(ctx.metrics.averageOrderValue)}) — bán lại rẻ '
      'hơn tìm khách mới.',
    );
  }
  if (b.isEmpty) {
    b.writeln(
      '• Dữ liệu chưa đủ tín hiệu — tiếp tục ghi đơn và giao dịch để nhận '
      'gợi ý sát hơn.',
    );
  }
  b.write(
    '(Gợi ý rule-based — thêm API key trong More → AI Assistant để nhận '
    'gợi ý AI cá nhân hoá.)',
  );
  return b.toString();
}

/// G-3B service: one [BusinessRecommendation] per call via the shared
/// [BusinessAiEngine]. Suggestions only — nothing is executed.
class BusinessRecommendationService {
  BusinessRecommendationService(
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
      'Bạn là Workizen AI. Từ tình hình kinh doanh dưới đây, đưa ra 3–5 gợi ý '
      'hành động thiết thực cho chủ shop SME Việt Nam, xếp theo mức độ ưu '
      'tiên, mỗi gợi ý một gạch đầu dòng ngắn kèm lý do dựa trên số liệu. '
      'CHỈ dùng số liệu được cung cấp; không bịa. Đây là GỢI Ý để chủ shop '
      'tự quyết — không có hành động nào được thực thi tự động.';

  /// Produces suggestions for the business's current snapshot. Read-only.
  Future<BusinessRecommendation> recommend() async {
    final outcome = await _engine.run(
      instruction: _instruction,
      ruleFallback: ruleBasedBusinessRecommendations,
    );
    return BusinessRecommendation(
      text: outcome.text,
      source: outcome.isAi
          ? BusinessRecommendationSource.ai
          : BusinessRecommendationSource.rule,
      generatedAt: outcome.generatedAt,
      provider: outcome.provider,
    );
  }
}
