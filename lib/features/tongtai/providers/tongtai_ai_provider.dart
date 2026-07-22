import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/tongtai_ai_key_store.dart';
import '../ai/tongtai_ai_provider_kind.dart';
import '../ai/tongtai_ai_service.dart';

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
