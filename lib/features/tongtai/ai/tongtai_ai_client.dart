import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'tongtai_ai_errors.dart';
import 'tongtai_ai_models.dart';
import 'tongtai_ai_provider_kind.dart';

/// BYOK client for an OpenAI-compatible AI provider — xAI (Grok) today
/// (WTM-61). Edge-First: the device calls the provider's `/chat/completions`
/// endpoint directly; the user's key is loaded from secure storage at call time
/// and travels only in the `Authorization` header, never cached in this object
/// and never logged.
///
/// All failure paths surface a friendly, bilingual [TongtaiAiException] — no
/// raw HTTP body or key material ever reaches the UI.
class TongtaiAiClient {
  TongtaiAiClient({
    required this.provider,
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// xAI (Grok) client — the WTM-61 provider.
  factory TongtaiAiClient.xai({
    required Future<String?> Function() apiKey,
    http.Client? client,
  }) => TongtaiAiClient(
    provider: TongtaiAiProviderKind.xai,
    apiKey: apiKey,
    client: client,
  );

  /// Which provider this client talks to (fixes base URL + default model).
  final TongtaiAiProviderKind provider;

  /// Loads the key from secure storage at call time — never held on this object.
  final Future<String?> Function() apiKey;

  final http.Client _client;

  /// How long to wait for a chat completion before giving up.
  static const Duration _chatTimeout = Duration(seconds: 60);

  /// Send [messages] to the provider and return the parsed reply.
  ///
  /// [systemPrompt] is prepended as a system turn when given. [model] overrides
  /// the provider default; [temperature] and [maxTokens] are forwarded only when
  /// set. Throws [TongtaiAiException] on any failure.
  Future<TongtaiAiResponse> chat({
    required List<TongtaiAiMessage> messages,
    String? systemPrompt,
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    final key = await _requireKey();
    final effectiveModel = (model != null && model.trim().isNotEmpty)
        ? model.trim()
        : provider.defaultModel;

    final body = jsonEncode({
      'model': effectiveModel,
      'temperature': ?temperature,
      'max_tokens': ?maxTokens,
      'messages': [
        if (systemPrompt != null && systemPrompt.trim().isNotEmpty)
          TongtaiAiMessage.system(systemPrompt).toJson(),
        for (final m in messages) m.toJson(),
      ],
    });

    http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('${provider.baseUrl}/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $key',
            },
            body: body,
          )
          .timeout(_chatTimeout);
    } on SocketException {
      throw TongtaiAiException.network;
    } on TimeoutException {
      throw TongtaiAiException.timeout;
    } on http.ClientException {
      throw TongtaiAiException.network;
    }

    _throwForStatus(res, effectiveModel);

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw TongtaiAiException.badResponse;
    }

    final choice =
        (json['choices'] as List?)?.firstOrNull as Map<String, dynamic>?;
    final message = choice?['message'] as Map<String, dynamic>?;
    final text = (message?['content'] as String?)?.trim() ?? '';
    if (text.isEmpty) throw TongtaiAiException.badResponse;

    final usage = json['usage'] as Map<String, dynamic>?;
    return TongtaiAiResponse(
      text: text,
      provider: provider,
      model: (json['model'] as String?) ?? effectiveModel,
      inputTokens: usage?['prompt_tokens'] as int?,
      outputTokens: usage?['completion_tokens'] as int?,
    );
  }

  /// Lightweight connectivity check (WTM-61 AC: "test API call to Grok endpoint
  /// succeeds and returns valid response"). Sends a tiny prompt capped at a few
  /// tokens so a valid key answers cheaply; any failure surfaces as a friendly
  /// [TongtaiAiException] the settings screen can display.
  Future<TongtaiAiResponse> testConnection() => chat(
    messages: const [TongtaiAiMessage.user('ping')],
    systemPrompt:
        'You are a connectivity probe. Reply with the single word: OK.',
    temperature: 0,
    maxTokens: 5,
  );

  Future<String> _requireKey() async {
    final key = await apiKey();
    final trimmed = key?.trim() ?? '';
    if (trimmed.isEmpty) throw TongtaiAiException.missingKey;
    return trimmed;
  }

  /// Map a non-200 HTTP status onto the right friendly error, returning normally
  /// for 200. xAI is quirky: it reports a bad key or unknown model as HTTP 400
  /// with a descriptive body (not 401/404), so 400 is classified from the body.
  void _throwForStatus(http.Response res, String effectiveModel) {
    switch (res.statusCode) {
      case 200:
        return;
      case 401:
      case 403:
        throw TongtaiAiException.invalidKey;
      case 429:
        throw TongtaiAiException.rateLimit;
      case 402:
        throw TongtaiAiException.quota;
      case 400:
        throw _classifyBadRequest(res) ?? TongtaiAiException.badResponse;
      case 500:
      case 502:
      case 503:
      case 529:
        throw TongtaiAiException.serverError;
      default:
        throw TongtaiAiException.unknown;
    }
  }

  /// Inspect (never echo) an HTTP-400 body to tell a bad key from another 400.
  /// Returns null when the body gives no useful signal.
  TongtaiAiException? _classifyBadRequest(http.Response res) {
    String detail;
    try {
      final json = jsonDecode(utf8.decode(res.bodyBytes));
      if (json is! Map<String, dynamic>) return null;
      final error = json['error'];
      detail = [
        json['code'],
        json['message'],
        if (error is String) error,
        if (error is Map) ...[error['code'], error['message'], error['type']],
      ].whereType<String>().join(' ').toLowerCase();
    } catch (_) {
      return null;
    }
    if (detail.contains('api key') ||
        detail.contains('api-key') ||
        detail.contains('apikey') ||
        detail.contains('authentication') ||
        detail.contains('unauthorized')) {
      return TongtaiAiException.invalidKey;
    }
    return null;
  }
}
