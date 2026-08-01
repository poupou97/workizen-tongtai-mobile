import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/business_profile.dart';
import '../profile/business_profile_repository.dart';
import 'tongtai_chat_provider.dart' show tongtaiDatabaseProvider;

/// Riverpod wiring for the AI Business Profile (WTM-177).
///
/// Reuses the single [tongtaiDatabaseProvider] rather than declaring another
/// one — the duplicate-database bug WTM-148 found is exactly what a second
/// declaration causes, and it is invisible until two screens disagree about
/// what is stored.

final businessProfileRepositoryProvider = Provider<BusinessProfileRepository>(
  (ref) => BusinessProfileRepository(ref.watch(tongtaiDatabaseProvider)),
);

/// The stored profile. Invalidated after a save so the AI prompt stops sending
/// the previous answers.
final businessProfileProvider = FutureProvider<BusinessProfile>(
  (ref) => ref.watch(businessProfileRepositoryProvider).load(),
);
