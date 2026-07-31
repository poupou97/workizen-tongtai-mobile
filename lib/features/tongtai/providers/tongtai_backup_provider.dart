library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../export/backup_service.dart';
import 'tongtai_consumer_provider.dart';
import 'tongtai_finance_provider.dart';
import 'tongtai_inventory_provider.dart';
import 'tongtai_journey_provider.dart';
import 'tongtai_orders_provider.dart';
import 'tongtai_search_provider.dart';

/// The six repositories a backup covers, wired to the **production** sources
/// (WTM-164). Composed from the existing providers rather than re-created, so
/// a backup can never read from a different database than the app does — the
/// duplicate-`tongtaiDatabaseProvider` bug WTM-148 found is exactly what that
/// rule exists to prevent.
final tongtaiBackupRepositoriesProvider = Provider<TongtaiBackupRepositories>(
  (ref) => TongtaiBackupRepositories(
    database: ref.watch(tongtaiDatabaseProvider),
    customers: ref.watch(customerRepositoryProvider),
    products: ref.watch(productRepositoryProvider),
    orders: ref.watch(orderRepositoryProvider),
    goals: ref.watch(businessGoalRepositoryProvider),
    finance: ref.watch(financeRepositoryProvider),
    favourites: ref.watch(tongtaiSearchFavoritesStoreProvider),
  ),
);

/// Creates, validates and restores `.ttbk` v2 backups.
final tongtaiBackupServiceProvider = Provider<TongtaiBackupService>(
  (ref) => TongtaiBackupService(
    repositories: ref.watch(tongtaiBackupRepositoriesProvider),
  ),
);
