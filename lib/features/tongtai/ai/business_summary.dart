import '../core/tongtai_formatters.dart';
import '../metrics/business_context.dart';
import '../metrics/business_context_service.dart';
import 'business_ai_engine.dart';
import 'tongtai_ai_provider_kind.dart';
import 'tongtai_ai_service.dart';

/// G-3A — AI Business Summary (WTM-116, Founder pre-approved 2026-07-29).
///
/// **AI boundary (ADR-TON-012, absolute):** everything in this file reads ONLY
/// the [BusinessContext] snapshot — never a repository, store or Drift. The
/// service is read-only end to end: it mutates nothing, calls no workflow and
/// performs no action; its sole output is text.
///
/// Modes per ADR-TON-006 / D-9: BYOK + Local (Ollama). When no provider is
/// enabled or every provider fails, the deterministic [ruleBasedBusinessSummary]
/// answers — so the feature works AI-off/offline, like every rule-based seam.

/// Serializes the [BusinessContext] into the compact bilingual data block the
/// AI is allowed to see (its ENTIRE world). Pure — same context, same text.
String businessContextPromptText(BusinessContext ctx) {
  final b = StringBuffer()
    ..writeln('# Business Snapshot (v${ctx.version})')
    ..writeln(
      '- Doanh thu (billable): ${TongtaiFormatters.vnd(ctx.metrics.revenue)}',
    )
    ..writeln(
      '- Đơn hàng: ${ctx.metrics.ordersCount}'
      ' · Khách hàng: ${ctx.metrics.customersCount}'
      ' · AOV: ${TongtaiFormatters.vnd(ctx.metrics.averageOrderValue)}',
    )
    ..writeln('- Đơn đang mở: ${ctx.orders.openCount}/${ctx.orders.total}')
    ..writeln(
      '- Kho: ${ctx.inventory.productCount} sản phẩm'
      ' · sắp hết: ${ctx.inventory.lowStockCount}'
      ' · hết: ${ctx.inventory.outOfStockCount}'
      ' · giá trị tồn: ${TongtaiFormatters.vnd(ctx.inventory.stockValue)}',
    )
    ..writeln('- Cơ hội đang mở: ${ctx.opportunity.total}')
    ..writeln(
      '- Mục tiêu: ${ctx.journey.total}'
      ' (đang chạy: ${ctx.journey.activeCount}'
      ' · chậm: ${ctx.journey.atRiskCount}'
      ' · xong: ${ctx.journey.completedCount})',
    )
    ..writeln(
      '- Tài chính YTD: thu ${TongtaiFormatters.vnd(ctx.finance.incomeYtd)}'
      ' · chi ${TongtaiFormatters.vnd(ctx.finance.expenseYtd)}'
      ' · lợi nhuận ${TongtaiFormatters.vnd(ctx.finance.profitYtd)}',
    )
    ..writeln(
      '- Hoạt động 7 ngày: ${ctx.timeline.recentCount} sự kiện'
      ' (tổng ${ctx.timeline.totalEvents})',
    )
    ..writeln('- Sức khỏe: ${ctx.health.label('vi')} — ${ctx.health.reason}');
  return b.toString().trimRight();
}

/// Where a summary came from — an AI provider, or the deterministic rule.
enum BusinessSummarySource { ai, rule }

/// The result of a summary run (G-3A): plain text + provenance. Read-only.
class BusinessSummary {
  const BusinessSummary({
    required this.text,
    required this.source,
    required this.generatedAt,
    this.provider,
  });

  final String text;
  final BusinessSummarySource source;
  final DateTime generatedAt;

  /// The provider that answered when [source] is [BusinessSummarySource.ai].
  final TongtaiAiProviderKind? provider;

  bool get isAi => source == BusinessSummarySource.ai;
}

/// Deterministic summary over the snapshot — the AI-off/offline answer, and the
/// fallback when every provider fails. Pure Dart, no network.
String ruleBasedBusinessSummary(BusinessContext ctx) {
  if (!ctx.hasData) {
    return 'Chưa đủ dữ liệu để tóm tắt. Thêm khách hàng, sản phẩm và đơn hàng '
        'đầu tiên — tóm tắt kinh doanh sẽ xuất hiện ở đây. '
        '(Not enough data yet — add your first records.)';
  }
  final b = StringBuffer()
    ..writeln(
      'Doanh nghiệp ${ctx.health.isHealthy ? 'đang ghi nhận doanh thu' : 'chưa đủ dữ liệu bán hàng'}: '
      '${TongtaiFormatters.vnd(ctx.metrics.revenue)} từ ${ctx.metrics.ordersCount} đơn '
      'của ${ctx.metrics.customersCount} khách.',
    );
  if (ctx.orders.openCount > 0) {
    b.writeln('• ${ctx.orders.openCount} đơn đang mở cần theo dõi.');
  }
  if (ctx.inventory.lowStockCount + ctx.inventory.outOfStockCount > 0) {
    b.writeln(
      '• Kho: ${ctx.inventory.lowStockCount} sản phẩm sắp hết, '
      '${ctx.inventory.outOfStockCount} đã hết — cân nhắc nhập thêm.',
    );
  }
  if (ctx.journey.atRiskCount > 0) {
    b.writeln('• ${ctx.journey.atRiskCount} mục tiêu đang chậm tiến độ.');
  }
  if (ctx.opportunity.total > 0) {
    b.writeln('• ${ctx.opportunity.total} cơ hội đang mở.');
  }
  b.write(
    '(Tóm tắt rule-based — thêm API key trong More → AI Assistant để '
    'nhận phân tích AI sâu hơn.)',
  );
  return b.toString();
}

/// G-3A service: builds one [BusinessSummary] per call from the current
/// [BusinessContext] via the shared [BusinessAiEngine] (ADR-TON-013 runner —
/// context-only boundary, provider chain, rule fallback, zero-spend on empty).
class BusinessSummaryService {
  BusinessSummaryService(
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
      'Bạn là Workizen AI. Tóm tắt tình hình kinh doanh dưới đây cho chủ '
      'shop SME Việt Nam: 3–5 gạch đầu dòng ngắn, tiếng Việt, thực tế, '
      'nêu điểm cần chú ý nhất trước. CHỈ dùng số liệu được cung cấp; '
      'không bịa. Không đề xuất hành động cụ thể ngoài dữ liệu.';

  /// Produces the summary for the business's current snapshot. Read-only: the
  /// context is loaded once, serialized, and only that text reaches the AI.
  Future<BusinessSummary> summarize() async {
    final outcome = await _engine.run(
      instruction: _instruction,
      ruleFallback: ruleBasedBusinessSummary,
    );
    return BusinessSummary(
      text: outcome.text,
      source: outcome.isAi
          ? BusinessSummarySource.ai
          : BusinessSummarySource.rule,
      generatedAt: outcome.generatedAt,
      provider: outcome.provider,
    );
  }
}
