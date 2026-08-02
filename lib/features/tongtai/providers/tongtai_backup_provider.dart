library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../export/backup_service.dart';
import 'tongtai_consumer_provider.dart';
import 'tongtai_finance_provider.dart';
import 'tongtai_inventory_provider.dart';
import 'tongtai_journey_provider.dart';
import 'tongtai_context_provider.dart';
import 'tongtai_orders_provider.dart';
import 'tongtai_profile_provider.dart';
import 'tongtai_search_provider.dart';

/// Every repository a backup covers, wired to the **production** sources
/// (WTM-164). Composed from the existing providers rather than re-created, so
/// a backup can never read from a different database than the app does — the
/// duplicate-`tongtaiDatabaseProvider` bug WTM-148 found is exactly what that
/// rule exists to prevent.
///
/// ⚠️ **Every optional slot must be filled here.** The slots are nullable so
/// that test call sites keep compiling, which means forgetting one is *not* a
/// compile error — it is a silent hole in real sellers' backups. WTM-190 found
/// exactly that: the profile (WTM-177) and the journey tree (WTM-185) were
/// declared as optional datasets but never wired here, so on a device they
/// were never written to a `.ttbk` — and worse, a Replace restore left the
/// PREVIOUS business's profile in place, because a `null` repository has
/// nothing to wipe. `backup_wiring_test.dart` now fails if a slot is empty.
final tongtaiBackupRepositoriesProvider = Provider<TongtaiBackupRepositories>(
  (ref) => TongtaiBackupRepositories(
    database: ref.watch(tongtaiDatabaseProvider),
    customers: ref.watch(customerRepositoryProvider),
    products: ref.watch(productRepositoryProvider),
    orders: ref.watch(orderRepositoryProvider),
    goals: ref.watch(businessGoalRepositoryProvider),
    finance: ref.watch(financeRepositoryProvider),
    favourites: ref.watch(tongtaiSearchFavoritesStoreProvider),
    businessProfile: ref.watch(businessProfileRepositoryProvider),
    journeys: ref.watch(journeyRepositoryProvider),
    opportunityReactions: ref.watch(opportunityReactionRepositoryProvider),
    businessInputs: ref.watch(businessInputRepositoryProvider),
  ),
);

/// Creates, validates and restores `.ttbk` v2 backups.
final tongtaiBackupServiceProvider = Provider<TongtaiBackupService>(
  (ref) => TongtaiBackupService(
    repositories: ref.watch(tongtaiBackupRepositoriesProvider),
  ),
);
