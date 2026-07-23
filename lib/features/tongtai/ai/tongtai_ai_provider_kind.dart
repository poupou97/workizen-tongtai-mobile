/// AI providers Workizen AI can talk to (WTM-61 BYOK foundation, extended for
/// the WTM-82 router per ADR-TON-006).
///
/// Every provider here speaks the OpenAI-compatible `/chat/completions` shape
/// — only the base URL, default model and key prefix differ — so one client
/// covers them all. Claude (Anthropic) uses a different API shape and joins
/// via its own adapter in a follow-up story (ADR-TON-006: "thêm adapter = 1
/// file"). Edge-First / BYOK: the device talks straight to the provider and
/// the user's key travels only in the `Authorization` header (never to a
/// Tổng Tài server, never logged). Ollama is the ADR-TON-006 "Local" mode —
/// an on-device/LAN endpoint that needs no key.
enum TongtaiAiProviderKind {
  xai,
  gemini,
  openRouter,
  cerebras,
  ollama,
  openAI;

  /// Human-facing provider name (same in EN/VI — these are brand names).
  String get displayName => switch (this) {
    TongtaiAiProviderKind.xai => 'Grok (xAI)',
    TongtaiAiProviderKind.gemini => 'Gemini (Google)',
    TongtaiAiProviderKind.openRouter => 'OpenRouter',
    TongtaiAiProviderKind.cerebras => 'Cerebras',
    TongtaiAiProviderKind.ollama => 'Ollama (local)',
    TongtaiAiProviderKind.openAI => 'OpenAI',
  };

  /// OpenAI-compatible API base URL (no trailing slash). For Ollama this is
  /// the default local endpoint.
  String get baseUrl => switch (this) {
    TongtaiAiProviderKind.xai => 'https://api.x.ai/v1',
    TongtaiAiProviderKind.gemini =>
      'https://generativelanguage.googleapis.com/v1beta/openai',
    TongtaiAiProviderKind.openRouter => 'https://openrouter.ai/api/v1',
    TongtaiAiProviderKind.cerebras => 'https://api.cerebras.ai/v1',
    TongtaiAiProviderKind.ollama => 'http://localhost:11434/v1',
    TongtaiAiProviderKind.openAI => 'https://api.openai.com/v1',
  };

  /// Default chat model used for the connectivity test and as the fallback when
  /// a caller does not pass an explicit model. grok-3 is verified against xAI's
  /// live catalog and broadly available on a fresh key.
  String get defaultModel => switch (this) {
    TongtaiAiProviderKind.xai => 'grok-3',
    TongtaiAiProviderKind.gemini => 'gemini-2.0-flash',
    TongtaiAiProviderKind.openRouter =>
      'meta-llama/llama-3.3-70b-instruct:free',
    TongtaiAiProviderKind.cerebras => 'llama-3.3-70b',
    TongtaiAiProviderKind.ollama => 'llama3.2',
    TongtaiAiProviderKind.openAI => 'gpt-4o-mini',
  };

  /// Expected prefix of a well-formed key for this provider. Empty means "no
  /// enforced prefix" (used only as a soft signal in the validator).
  String get keyPrefix => switch (this) {
    TongtaiAiProviderKind.xai => 'xai-',
    TongtaiAiProviderKind.gemini => 'AIza',
    TongtaiAiProviderKind.openRouter => 'sk-or-',
    TongtaiAiProviderKind.cerebras => 'csk-',
    TongtaiAiProviderKind.ollama => '',
    TongtaiAiProviderKind.openAI => 'sk-',
  };

  /// Console page where the user creates/copies their API key (BYOK onboarding).
  String get keyConsoleUrl => switch (this) {
    TongtaiAiProviderKind.xai => 'https://console.x.ai',
    TongtaiAiProviderKind.gemini => 'https://aistudio.google.com/apikey',
    TongtaiAiProviderKind.openRouter => 'https://openrouter.ai/keys',
    TongtaiAiProviderKind.cerebras => 'https://cloud.cerebras.ai',
    TongtaiAiProviderKind.ollama => 'https://ollama.com/download',
    TongtaiAiProviderKind.openAI => 'https://platform.openai.com/api-keys',
  };

  /// Secure-storage key holding this provider's API key. Namespaced per provider
  /// so multiple keys coexist. Stored via [FlutterSecureStorage] only — never in
  /// SharedPreferences, never logged.
  String get storageKey => 'tongtai.ai.$name.api_key';

  /// Whether the provider needs a real API key. Ollama runs locally and
  /// ignores auth — its key slot holds an opt-in marker (any non-empty value,
  /// e.g. "local") so enabling it stays an explicit per-provider choice.
  bool get requiresKey => this != TongtaiAiProviderKind.ollama;

  /// Providers with a working client today. Everything OpenAI-compatible is
  /// routable via the shared client since WTM-82; the settings UI still
  /// exposes xAI first (per-provider key UX lands with WTM-83).
  bool get isImplemented => true;
}
