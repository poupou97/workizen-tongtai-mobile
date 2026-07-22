import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistent store for the Tổng Tài local user identity (WTM-58).
///
/// The identity is a random UUID generated once on first launch. It identifies
/// the install locally — there is no email/password auth in the MVP
/// (local-first, privacy by default). The value is kept in secure storage,
/// never in SharedPreferences and never logged.
abstract interface class TongtaiIdentityStore {
  Future<String?> read();
  Future<void> write(String userId);
  Future<void> delete();

  /// Secure-storage key for the local user id.
  static const String storageKey = 'tongtai.local_user_id';
}

/// Production store backed by [FlutterSecureStorage] (Keychain / Keystore).
class SecureTongtaiIdentityStore implements TongtaiIdentityStore {
  SecureTongtaiIdentityStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() =>
      _storage.read(key: TongtaiIdentityStore.storageKey);

  @override
  Future<void> write(String userId) =>
      _storage.write(key: TongtaiIdentityStore.storageKey, value: userId);

  @override
  Future<void> delete() =>
      _storage.delete(key: TongtaiIdentityStore.storageKey);
}

/// In-memory store for tests (no platform channels required).
class InMemoryTongtaiIdentityStore implements TongtaiIdentityStore {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String userId) async => _value = userId;

  @override
  Future<void> delete() async => _value = null;
}
