import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../identity/tongtai_identity_service.dart';
import '../identity/tongtai_identity_store.dart';

/// Secure store holding the Tổng Tài local user id (WTM-58).
final tongtaiIdentityStoreProvider = Provider<TongtaiIdentityStore>(
  (ref) => SecureTongtaiIdentityStore(),
);

/// Service that resolves (and lazily creates) the local user id.
final tongtaiIdentityServiceProvider = Provider<TongtaiIdentityService>(
  (ref) => TongtaiIdentityService(ref.watch(tongtaiIdentityStoreProvider)),
);

/// The resolved local user id. Generates+persists a UUID on first read,
/// then returns the same value for the life of the install.
final tongtaiUserIdProvider = FutureProvider<String>(
  (ref) => ref.watch(tongtaiIdentityServiceProvider).getOrCreateUserId(),
);
