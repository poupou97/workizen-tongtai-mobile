/// AI providers Tổng Tài can talk to under BYOK (WTM-61).
///
/// xAI (Grok) is the only provider wired today; OpenRouter and OpenAI are
/// listed so the key store, validator and client can already be keyed per
/// provider — the "support multiple API keys for future multi-provider
/// scenarios" acceptance criterion — without a rewrite when they are enabled.
///
/// Every provider here is OpenAI-compatible: same `/chat/completions` shape,
/// only the base URL, default model and key prefix differ. Edge-First / BYOK:
/// the device talks straight to the provider and the user's key travels only in
/// the `Authorization` header (never to a Tổng Tài server, never logged).
enum TongtaiAiProviderKind {
  xai,
  openRouter,
  openAI;

  /// Human-facing provider name (same in EN/VI — these are brand names).
  String get displayName => switch (this) {
        TongtaiAiProviderKind.xai => 'Grok (xAI)',
        TongtaiAiProviderKind.openRouter => 'OpenRouter',
        TongtaiAiProviderKind.openAI => 'OpenAI',
      };

  /// OpenAI-compatible API base URL (no trailing slash).
  String get baseUrl => switch (this) {
        TongtaiAiProviderKind.xai => 'https://api.x.ai/v1',
        TongtaiAiProviderKind.openRouter => 'https://openrouter.ai/api/v1',
        TongtaiAiProviderKind.openAI => 'https://api.openai.com/v1',
      };

  /// Default chat model used for the connectivity test and as the fallback when
  /// a caller does not pass an explicit model. grok-3 is verified against xAI's
  /// live catalog and broadly available on a fresh key.
  String get defaultModel => switch (this) {
        TongtaiAiProviderKind.xai => 'grok-3',
        TongtaiAiProviderKind.openRouter =>
          'meta-llama/llama-3.3-70b-instruct:free',
        TongtaiAiProviderKind.openAI => 'gpt-4o-mini',
      };

  /// Expected prefix of a well-formed key for this provider. Empty means "no
  /// enforced prefix" (used only as a soft signal in the validator).
  String get keyPrefix => switch (this) {
        TongtaiAiProviderKind.xai => 'xai-',
        TongtaiAiProviderKind.openRouter => 'sk-or-',
        TongtaiAiProviderKind.openAI => 'sk-',
      };

  /// Console page where the user creates/copies their API key (BYOK onboarding).
  String get keyConsoleUrl => switch (this) {
        TongtaiAiProviderKind.xai => 'https://console.x.ai',
        TongtaiAiProviderKind.openRouter => 'https://openrouter.ai/keys',
        TongtaiAiProviderKind.openAI => 'https://platform.openai.com/api-keys',
      };

  /// Secure-storage key holding this provider's API key. Namespaced per provider
  /// so multiple keys coexist. Stored via [FlutterSecureStorage] only — never in
  /// SharedPreferences, never logged.
  String get storageKey => 'tongtai.ai.$name.api_key';

  /// Providers with a working client + UI today. Only xAI for WTM-61.
  bool get isImplemented => this == TongtaiAiProviderKind.xai;
}
