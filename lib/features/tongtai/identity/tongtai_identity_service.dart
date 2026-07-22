import 'package:uuid/uuid.dart';

import 'tongtai_identity_store.dart';

/// Resolves the Tổng Tài local user identity (WTM-58).
///
/// On first call it generates a random v4 UUID, persists it via
/// [TongtaiIdentityStore], and returns it. Every subsequent call returns the
/// same value — the id is stable for the life of the install.
class TongtaiIdentityService {
  TongtaiIdentityService(this._store, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final TongtaiIdentityStore _store;
  final Uuid _uuid;

  /// Returns the existing local user id, generating and persisting one on the
  /// first ever call. Idempotent: the same id is returned across app restarts.
  Future<String> getOrCreateUserId() async {
    final existing = await _store.read();
    if (existing != null && isValid(existing)) {
      return existing;
    }
    final generated = _uuid.v4();
    await _store.write(generated);
    return generated;
  }

  /// Whether [id] is a well-formed UUID (36 chars, canonical form).
  static bool isValid(String id) =>
      id.length == 36 && Uuid.isValidUUID(fromString: id);
}
