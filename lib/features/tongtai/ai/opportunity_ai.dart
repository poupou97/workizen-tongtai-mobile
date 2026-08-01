import '../core/tongtai_formatters.dart';
import '../metrics/business_context_service.dart';
import '../opportunity/opportunity.dart';
import 'business_summary.dart' show businessContextPromptText;
import 'tongtai_ai_errors.dart';
import 'tongtai_ai_models.dart';
import 'tongtai_ai_provider_kind.dart';
import 'tongtai_ai_service.dart';
import 'workizen_ai_router.dart'
    show kWorkizenRoutingPreference, WorkizenQueryClass;

/// Opportunity AI layer (WTM-141, ADR-TON-013 Founder chain):
/// `Rule Engine → Opportunity → AI Scoring → AI Ranking → AI Explanation`.
///
/// The AI **layers on top** of the rule-generated opportunity — it never
/// replaces the Rule Engine, and the rule score stays the feed's authoritative
/// ranking; the AI score/explanation are annotation. Read-only end to end.
///
/// Provider input = the serialized BusinessContext + the opportunity block —
/// both are context/rule-engine products; no repository is ever touched.

/// Serializes a rule-generated opportunity for the provider. Pure.
String opportunityPromptBlock(Opportunity o) =>
    '# Cơ hội cần đánh giá\n'
    '- Tiêu đề: ${o.title}\n'
    '- Mô tả: ${o.description}\n'
    '- Tác động kỳ vọng: ${TongtaiFormatters.vnd(o.expectedImpact)}\n'
    '- Điểm rule-based: ${_scoreText(o)}';

/// Parses the trailing `ĐIỂM: NN` line of an AI answer; null when absent or
/// out of range after clamping is impossible (non-numeric).
double? parseAiScore(String text) {
  final match = RegExp(r'ĐIỂM:\s*(\d{1,3})').firstMatch(text);
  if (match == null) return null;
  final value = int.parse(match.group(1)!);
  return value.clamp(0, 100).toDouble();
}

/// Where an insight came from.
enum OpportunityAiInsightSource { ai, rule }

/// One AI read on a rule-generated opportunity: explanation + optional AI
/// score. Annotation only — the rule score keeps ranking the feed.
class OpportunityAiInsight {
  const OpportunityAiInsight({
    required this.text,
    required this.source,
    required this.generatedAt,
    this.aiScore,
    this.provider,
  });

  final String text;
  final OpportunityAiInsightSource source;
  final DateTime generatedAt;

  /// The AI's score (0..100) when it answered with a parsable `ĐIỂM:` line.
  final double? aiScore;

  final TongtaiAiProviderKind? provider;

  bool get isAi => source == OpportunityAiInsightSource.ai;
}

/// Deterministic insight — the AI-off/offline answer and the fallback when
/// every provider fails. Score = the rule score (the authoritative one).
String ruleBasedOpportunityInsight(Opportunity o) =>
    '${o.description}\n'
    'Đánh giá rule-based: điểm ${_scoreText(o)} · tác động '
    '${TongtaiFormatters.vnd(o.expectedImpact)}.\n'
    '(Thêm API key trong More → AI Assistant để nhận đánh giá AI sâu hơn.)';

/// The score, with its coverage — never a bare number (WTM-193).
///
/// A model told "82/100" will explain it as a complete judgement. Told
/// "82/100, dựa trên 70% yếu tố", it can only explain what was actually
/// measured — which is the ADR-TON-016 boundary written into the prompt itself.
String _scoreText(Opportunity o) {
  final value = o.score.value;
  if (value == null) return 'chưa đủ dữ liệu để chấm';
  final pct = (o.score.coverage * 100).round();
  return o.score.isPartial
      ? '${value.round()}/100 (dựa trên $pct% yếu tố — phần còn lại chưa có dữ liệu)'
      : '${value.round()}/100';
}

/// WTM-141 service: one [OpportunityAiInsight] per call. Read-only.
class OpportunityAiService {
  const OpportunityAiService(
    this._ai,
    this._context, {
    this.preference = const [],
    this.clock,
  });

  final TongtaiAiService _ai;
  final BusinessContextService _context;

  /// Provider order to try; empty means the router's complex-query default.
  final List<TongtaiAiProviderKind> preference;

  /// Injectable clock; defaults to [DateTime.now].
  final DateTime Function()? clock;

  List<TongtaiAiProviderKind> get _chain => preference.isNotEmpty
      ? preference
      : kWorkizenRoutingPreference[WorkizenQueryClass.complex]!;

  static const String _instruction =
      'Bạn là Workizen AI. Đánh giá CƠ HỘI kinh doanh dưới đây trong bối cảnh '
      'doanh nghiệp: đáng làm không, vì sao (2–3 gạch đầu dòng dựa trên số '
      'liệu), rủi ro chính. CHỈ dùng số liệu được cung cấp; không bịa. Đây là '
      'đánh giá tham khảo — điểm chính thức do rule engine quyết định. Kết '
      'thúc bằng đúng một dòng: "ĐIỂM: <số 0-100>".';

  /// Explains + scores one rule-generated opportunity against the business
  /// snapshot. Rule fallback keeps the feature working AI-off/offline.
  Future<OpportunityAiInsight> explain(Opportunity opportunity) async {
    final now = (clock ?? DateTime.now)();
    final ctx = await _context.load();

    if (ctx.hasData) {
      final input =
          '${businessContextPromptText(ctx)}\n\n'
          '${opportunityPromptBlock(opportunity)}';
      for (final provider in _chain) {
        if (!await _ai.hasKey(provider: provider)) continue;
        try {
          final response = await _ai.chat(
            messages: [TongtaiAiMessage.user(input)],
            systemPrompt: _instruction,
            provider: provider,
          );
          return OpportunityAiInsight(
            text: response.text,
            source: OpportunityAiInsightSource.ai,
            generatedAt: now,
            aiScore: parseAiScore(response.text),
            provider: provider,
          );
        } on TongtaiAiException {
          continue; // Next provider in the chain.
        }
      }
    }

    return OpportunityAiInsight(
      text: ruleBasedOpportunityInsight(opportunity),
      source: OpportunityAiInsightSource.rule,
      generatedAt: now,
      aiScore: opportunity.aiScore,
    );
  }
}
