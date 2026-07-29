import '../metrics/business_context.dart';
import '../metrics/business_context_service.dart';
import 'business_summary.dart' show businessContextPromptText;
import 'tongtai_ai_errors.dart';
import 'tongtai_ai_models.dart';
import 'tongtai_ai_provider_kind.dart';
import 'tongtai_ai_service.dart';
import 'workizen_ai_router.dart'
    show kWorkizenRoutingPreference, WorkizenQueryClass;

/// The shared runner behind every read-only AI feature (ADR-TON-013): load the
/// [BusinessContext] once → guard `hasData` → serialize the snapshot → try the
/// enabled BYOK/Local providers in order → deterministic rule fallback.
///
/// Every stage (G-3A Summary, G-3B Recommendation, G-3C Planner, G-3D Health)
/// differs only by its instruction + rule twin — the invariants live here:
/// - the AI's ENTIRE world is [businessContextPromptText] of one snapshot;
/// - no repository/DB access, no mutation, no workflow, no action;
/// - a brand-new business never spends a provider call.
class BusinessAiEngine {
  const BusinessAiEngine(
    this._ai,
    this._context, {
    this.preference = const [],
    this.clock,
  });

  final TongtaiAiService _ai;
  final BusinessContextService _context;

  /// Provider order to try; empty means the router's complex-query default.
  final List<TongtaiAiProviderKind> preference;

  /// Injectable clock for deterministic tests; defaults to [DateTime.now].
  final DateTime Function()? clock;

  List<TongtaiAiProviderKind> get _chain => preference.isNotEmpty
      ? preference
      : kWorkizenRoutingPreference[WorkizenQueryClass.complex]!;

  /// Runs one read-only AI task over the current snapshot. [ruleFallback]
  /// answers when the business has no data, no provider is enabled, or every
  /// provider fails — the feature always works.
  Future<BusinessAiOutcome> run({
    required String instruction,
    required String Function(BusinessContext) ruleFallback,
  }) async {
    final ctx = await _context.load();
    final now = (clock ?? DateTime.now)();

    // No data → deterministic answer; never spend a provider call on "empty".
    if (ctx.hasData) {
      final data = businessContextPromptText(ctx);
      for (final provider in _chain) {
        if (!await _ai.hasKey(provider: provider)) continue;
        try {
          final response = await _ai.chat(
            messages: [TongtaiAiMessage.user(data)],
            systemPrompt: instruction,
            provider: provider,
          );
          return BusinessAiOutcome(
            text: response.text,
            provider: provider,
            context: ctx,
            generatedAt: now,
          );
        } on TongtaiAiException {
          continue; // Next provider in the chain.
        }
      }
    }

    return BusinessAiOutcome(
      text: ruleFallback(ctx),
      provider: null,
      context: ctx,
      generatedAt: now,
    );
  }
}

/// The result of one engine run: text + provenance (+ the snapshot it was
/// generated from, for callers that want to render alongside it). Read-only.
class BusinessAiOutcome {
  const BusinessAiOutcome({
    required this.text,
    required this.provider,
    required this.context,
    required this.generatedAt,
  });

  final String text;

  /// The provider that answered; null when the rule-based twin did.
  final TongtaiAiProviderKind? provider;

  final BusinessContext context;
  final DateTime generatedAt;

  bool get isAi => provider != null;
}
