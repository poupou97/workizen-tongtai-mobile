import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/business_recommendation.dart';
import '../ai/business_summary.dart';
import '../ai/tongtai_ai_key_store.dart';
import '../ai/tongtai_ai_provider_kind.dart';
import '../ai/tongtai_ai_service.dart';
import 'tongtai_context_provider.dart';

/// Secure store holding the Tổng Tài BYOK AI API keys (WTM-61).
final tongtaiAiKeyStoreProvider = Provider<TongtaiAiKeyStore>(
  (ref) => SecureTongtaiAiKeyStore(),
);

/// Coordinator for validating, storing and using BYOK AI keys.
final tongtaiAiServiceProvider = Provider<TongtaiAiService>(
  (ref) => TongtaiAiService(ref.watch(tongtaiAiKeyStoreProvider)),
);

/// Whether a usable Grok (xAI) key is stored — drives the "key set" state on the
/// AI settings screen and gates AI features elsewhere. Refresh after saving or
/// deleting a key with `ref.invalidate(tongtaiHasAiKeyProvider)`.
final tongtaiHasAiKeyProvider = FutureProvider<bool>(
  (ref) => ref
      .watch(tongtaiAiServiceProvider)
      .hasKey(provider: TongtaiAiProviderKind.xai),
);

/// G-3A — AI Business Summary (WTM-116). Reads ONLY the BusinessContext
/// (ADR-TON-012 AI boundary); BYOK/Local via the routing preference; falls back
/// to the deterministic rule-based summary when no provider is enabled.
final businessSummaryServiceProvider = Provider<BusinessSummaryService>(
  (ref) => BusinessSummaryService(
    ref.watch(tongtaiAiServiceProvider),
    ref.watch(businessContextServiceProvider),
  ),
);

/// G-3B — AI Recommendation (WTM-135). Suggestions only over the
/// BusinessContext; nothing is mutated or executed (ADR-TON-013).
final businessRecommendationServiceProvider =
    Provider<BusinessRecommendationService>(
      (ref) => BusinessRecommendationService(
        ref.watch(tongtaiAiServiceProvider),
        ref.watch(businessContextServiceProvider),
      ),
    );
