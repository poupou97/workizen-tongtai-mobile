import 'package:http/http.dart' as http;

import 'tongtai_ai_client.dart';
import 'tongtai_ai_errors.dart';
import 'tongtai_ai_key_store.dart';
import 'tongtai_ai_key_validator.dart';
import 'tongtai_ai_models.dart';
import 'tongtai_ai_provider_kind.dart';

/// Builds a [TongtaiAiClient] bound to a per-provider key loader. Injectable so
/// tests can hand the service a fake client without real HTTP.
typedef TongtaiAiClientFactory =
    TongtaiAiClient Function(
      TongtaiAiProviderKind provider,
      Future<String?> Function() apiKey,
    );

/// App-facing coordinator for BYOK AI (WTM-61): validate → store → retrieve →
/// test → chat, over any [TongtaiAiProviderKind]. The UI talks only to this
/// service, never directly to the store or client.
class TongtaiAiService {
  TongtaiAiService(this._store, {this._httpClient, this._clientFactory});

  final TongtaiAiKeyStore _store;
  final http.Client? _httpClient;
  final TongtaiAiClientFactory? _clientFactory;

  /// Validate [raw] for [provider] and, only if it is well-formed, persist the
  /// normalized (trimmed) key. Returns the validation either way — an invalid
  /// key is NOT stored, so the caller can surface [TongtaiAiKeyValidation.issue]
  /// to the user (WTM-61 AC: "validated … before storing").
  Future<TongtaiAiKeyValidation> saveKey(
    String raw, {
    TongtaiAiProviderKind provider = TongtaiAiProviderKind.xai,
  }) async {
    final validation = TongtaiAiKeyValidator.validate(raw, provider: provider);
    if (validation.ok) {
      await _store.write(provider, validation.normalizedKey!);
    }
    return validation;
  }

  /// The stored key for [provider], or null (WTM-61 AC: "retrieved on startup").
  Future<String?> loadKey({
    TongtaiAiProviderKind provider = TongtaiAiProviderKind.xai,
  }) => _store.read(provider);

  /// Whether a usable key is stored for [provider].
  Future<bool> hasKey({
    TongtaiAiProviderKind provider = TongtaiAiProviderKind.xai,
  }) => _store.hasKey(provider);

  /// Remove the stored key for [provider].
  Future<void> deleteKey({
    TongtaiAiProviderKind provider = TongtaiAiProviderKind.xai,
  }) => _store.delete(provider);

  /// Live connectivity + validity check against the provider using the stored
  /// key. Throws [TongtaiAiException.missingKey] when no key is set, otherwise a
  /// friendly [TongtaiAiException] on failure.
  Future<TongtaiAiResponse> testConnection({
    TongtaiAiProviderKind provider = TongtaiAiProviderKind.xai,
  }) async {
    if (!await hasKey(provider: provider)) {
      throw TongtaiAiException.missingKey;
    }
    return _clientFor(provider).testConnection();
  }

  /// Safely rotates the stored key for [provider] to [raw] (WTM-83,
  /// Founder-approved): validate the format → write the new key → live-test it
  /// against the provider → **roll back to the previous key when the test
  /// fails**, so a broken rotation never bricks a working setup.
  Future<TongtaiAiRotation> rotateKey(
    String raw, {
    TongtaiAiProviderKind provider = TongtaiAiProviderKind.xai,
  }) async {
    final validation = TongtaiAiKeyValidator.validate(raw, provider: provider);
    if (!validation.ok) {
      return TongtaiAiRotation.invalid(validation);
    }
    final previous = await _store.read(provider);
    await _store.write(provider, validation.normalizedKey!);
    try {
      final response = await _clientFor(provider).testConnection();
      return TongtaiAiRotation.success(response.model);
    } on TongtaiAiException catch (error) {
      // The new key failed live verification — restore what worked before.
      if (previous != null) {
        await _store.write(provider, previous);
      } else {
        await _store.delete(provider);
      }
      return TongtaiAiRotation.failed(error, rolledBack: previous != null);
    }
  }

  /// Send a chat exchange using the stored key. Throws
  /// [TongtaiAiException.missingKey] when no key is set.
  Future<TongtaiAiResponse> chat({
    required List<TongtaiAiMessage> messages,
    String? systemPrompt,
    String? model,
    double? temperature,
    int? maxTokens,
    TongtaiAiProviderKind provider = TongtaiAiProviderKind.xai,
  }) async {
    if (!await hasKey(provider: provider)) {
      throw TongtaiAiException.missingKey;
    }
    return _clientFor(provider).chat(
      messages: messages,
      systemPrompt: systemPrompt,
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  TongtaiAiClient _clientFor(TongtaiAiProviderKind provider) {
    Future<String?> loadKey() => _store.read(provider);
    if (_clientFactory != null) return _clientFactory(provider, loadKey);
    return TongtaiAiClient(
      provider: provider,
      apiKey: loadKey,
      client: _httpClient,
    );
  }
}

/// Outcome of a safe key rotation (WTM-83). Exactly one of the three shapes:
/// invalid format (nothing written), verified success, or live-test failure
/// (previous key restored when one existed).
class TongtaiAiRotation {
  const TongtaiAiRotation._({
    required this.ok,
    this.model,
    this.validation,
    this.error,
    this.rolledBack = false,
  });

  factory TongtaiAiRotation.success(String model) =>
      TongtaiAiRotation._(ok: true, model: model);

  factory TongtaiAiRotation.invalid(TongtaiAiKeyValidation validation) =>
      TongtaiAiRotation._(ok: false, validation: validation);

  factory TongtaiAiRotation.failed(
    TongtaiAiException error, {
    required bool rolledBack,
  }) => TongtaiAiRotation._(ok: false, error: error, rolledBack: rolledBack);

  /// True when the new key was verified live and is now the stored key.
  final bool ok;

  /// The model that answered the verification call (success only).
  final String? model;

  /// The format-validation result (invalid-format only).
  final TongtaiAiKeyValidation? validation;

  /// The live-test failure (failed only).
  final TongtaiAiException? error;

  /// Whether the previous working key was restored after the failure.
  final bool rolledBack;
}
