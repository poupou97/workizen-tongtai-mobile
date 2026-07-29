import '../core/tongtai_formatters.dart';
import '../metrics/business_context.dart';
import '../metrics/business_context_service.dart';
import '../metrics/business_health.dart';
import 'business_ai_engine.dart';
import 'tongtai_ai_provider_kind.dart';
import 'tongtai_ai_service.dart';

/// G-3D — BusinessHealth AI (WTM-137, ADR-TON-013 pre-approved stage 4).
///
/// A deeper health **assessment** over the BusinessContext. **Assessment only:**
/// the AI contributes explanatory text — it never replaces the rule-based
/// [BusinessHealth]. The rule status remains what the app renders (Home badge)
/// and the default fallback; [BusinessHealthAssessment.ruleHealth] always
/// carries it, on both the AI and the rule path.

/// Where an assessment's text came from.
enum BusinessHealthAssessmentSource { ai, rule }

/// One health-assessment run (G-3D). [ruleHealth] is ALWAYS the rule-based
/// read from the snapshot — the AI only ever adds [text].
class BusinessHealthAssessment {
  const BusinessHealthAssessment({
    required this.ruleHealth,
    required this.text,
    required this.source,
    required this.generatedAt,
    this.provider,
  });

  /// The rule-based health (WTM-132) — the app's authoritative status.
  final BusinessHealth ruleHealth;

  /// The assessment narrative (AI, or the deterministic rule twin).
  final String text;

  final BusinessHealthAssessmentSource source;
  final DateTime generatedAt;

  /// The provider that answered when [source] is ai.
  final TongtaiAiProviderKind? provider;

  bool get isAi => source == BusinessHealthAssessmentSource.ai;
}

/// Deterministic assessment narrative — explains WHY health reads the way it
/// does, from the snapshot's own signals. The AI-off/offline answer and the
/// fallback when every provider fails. Pure.
String ruleBasedHealthAssessment(BusinessContext ctx) {
  final h = ctx.health;
  final b = StringBuffer()
    ..writeln('Trạng thái: ${h.label('vi')} — ${h.reason}');
  if (!ctx.hasData) {
    b.write(
      'Thêm khách hàng, sản phẩm và đơn hàng đầu tiên để bắt đầu đo sức '
      'khỏe kinh doanh. (Not enough data yet.)',
    );
    return b.toString();
  }
  b
    ..writeln(
      '• Doanh thu ${TongtaiFormatters.vnd(ctx.metrics.revenue)} / '
      '${ctx.metrics.ordersCount} đơn / ${ctx.metrics.customersCount} khách.',
    )
    ..writeln(
      '• Vận hành: ${ctx.orders.openCount} đơn đang mở · '
      '${ctx.inventory.lowStockCount + ctx.inventory.outOfStockCount} sản phẩm '
      'cần nhập · ${ctx.journey.atRiskCount} mục tiêu chậm.',
    )
    ..writeln('• Nhịp hoạt động 7 ngày: ${ctx.timeline.recentCount} sự kiện.')
    ..write(
      '(Đánh giá rule-based, độ tin cậy ${(h.confidence * 100).round()}% — '
      'trạng thái hiển thị luôn do rule engine quyết định.)',
    );
  return b.toString();
}

/// G-3D service: one [BusinessHealthAssessment] per call via the shared engine.
/// The rule-based status is read from the same snapshot and attached verbatim —
/// the AI cannot change it, only annotate it.
class BusinessHealthAiService {
  BusinessHealthAiService(
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
      'Bạn là Workizen AI. Đánh giá SỨC KHỎE kinh doanh từ số liệu dưới đây '
      'cho chủ shop SME Việt Nam: 1 dòng nhận định tổng quan, rồi 2–3 gạch '
      'đầu dòng lý do dựa trên số liệu (điểm mạnh trước, rủi ro sau). CHỈ '
      'dùng số liệu được cung cấp; không bịa. Đây CHỈ là đánh giá tham khảo — '
      'trạng thái chính thức của ứng dụng do rule engine quyết định.';

  /// Produces the assessment for the business's current snapshot. Read-only;
  /// the returned [BusinessHealthAssessment.ruleHealth] is always the
  /// rule-based read embedded in that same snapshot.
  Future<BusinessHealthAssessment> assess() async {
    final outcome = await _engine.run(
      instruction: _instruction,
      ruleFallback: ruleBasedHealthAssessment,
    );
    return BusinessHealthAssessment(
      // The authoritative status comes from the snapshot's rule-based read —
      // never from the AI (G-3D: assessment only).
      ruleHealth: outcome.context.health,
      text: outcome.text,
      source: outcome.isAi
          ? BusinessHealthAssessmentSource.ai
          : BusinessHealthAssessmentSource.rule,
      generatedAt: outcome.generatedAt,
      provider: outcome.provider,
    );
  }
}
