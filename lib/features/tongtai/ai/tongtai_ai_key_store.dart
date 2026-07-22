import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'tongtai_ai_provider_kind.dart';

/// Persistent store for BYOK AI API keys (WTM-61).
///
/// Keys live in the platform secure store (Keychain / Keystore), one entry per
/// [TongtaiAiProviderKind] so several providers' keys can coexist. The value is
/// the raw user-supplied API key; it is written only after passing validation,
/// read back on demand (e.g. app startup / before a request), and never logged.
abstract interface class TongtaiAiKeyStore {
  /// The stored key for [provider], or null when none is set.
  Future<String?> read(TongtaiAiProviderKind provider);

  /// Persist [key] for [provider], overwriting any previous value.
  Future<void> write(TongtaiAiProviderKind provider, String key);

  /// Remove the stored key for [provider] (no-op if absent).
  Future<void> delete(TongtaiAiProviderKind provider);

  /// Whether a non-empty key is stored for [provider].
  Future<bool> hasKey(TongtaiAiProviderKind provider);
}

/// Production store backed by [FlutterSecureStorage].
class SecureTongtaiAiKeyStore implements TongtaiAiKeyStore {
  SecureTongtaiAiKeyStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(TongtaiAiProviderKind provider) =>
      _storage.read(key: provider.storageKey);

  @override
  Future<void> write(TongtaiAiProviderKind provider, String key) =>
      _storage.write(key: provider.storageKey, value: key);

  @override
  Future<void> delete(TongtaiAiProviderKind provider) =>
      _storage.delete(key: provider.storageKey);

  @override
  Future<bool> hasKey(TongtaiAiProviderKind provider) async {
    final value = await read(provider);
    return value != null && value.trim().isNotEmpty;
  }
}

/// In-memory store for tests (no platform channels required).
class InMemoryTongtaiAiKeyStore implements TongtaiAiKeyStore {
  final Map<TongtaiAiProviderKind, String> _values = {};

  @override
  Future<String?> read(TongtaiAiProviderKind provider) async =>
      _values[provider];

  @override
  Future<void> write(TongtaiAiProviderKind provider, String key) async =>
      _values[provider] = key;

  @override
  Future<void> delete(TongtaiAiProviderKind provider) async =>
      _values.remove(provider);

  @override
  Future<bool> hasKey(TongtaiAiProviderKind provider) async {
    final value = _values[provider];
    return value != null && value.trim().isNotEmpty;
  }
}
