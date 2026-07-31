/// Riverpod wiring for Tổng Tài Unified Search (WTM-73).
///
/// Exposes the on-device Tổng Tài database, the FTS5-backed search service, the
/// SharedPreferences-backed recent-search history store and the demo-catalogue
/// seeder, so the search route can assemble a controller without knowing how any
/// of them are built.
///
/// Note: Tổng Tài has its **own** SQLite database ([AppDatabase] in
/// `lib/database/database.dart`, file `tongtai.db`) — separate from the Hub's
/// `databaseProvider`. This is the first provider that opens it in the running
/// app; later Tổng Tài features can reuse [tongtaiDatabaseProvider].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database.dart';
import '../../../database/search/tongtai_search_service.dart';
import 'package:tongtai/core/prefs.dart' show sharedPreferencesProvider;
import 'tongtai_chat_provider.dart' show tongtaiDatabaseProvider;
import '../producer/supplier_favorites_store.dart';
// ONE database provider for the whole app (WTM-148). This file used to declare
// its own `tongtaiDatabaseProvider`, so search + favourites ran on a SECOND
// `AppDatabase` over the same file: two connections in production, and a test
// that overrode "the" database silently only overrode half the app. Re-exported
// so every existing importer of this file keeps resolving the same symbol —
// now the canonical one (ADR-TON-015 One Data Path).
export 'tongtai_chat_provider.dart' show tongtaiDatabaseProvider;
import '../search/tongtai_catalog_seeder.dart';
import '../search/tongtai_ranking.dart';
import '../search/tongtai_search_history_store.dart';

/// FTS5 full-text search over the on-device catalogue (WTM-72).
final tongtaiSearchServiceProvider = Provider<TongtaiSearchService>(
  (ref) => TongtaiSearchService(ref.watch(tongtaiDatabaseProvider)),
);

/// Durable recent-search history (WTM-73 AC3).
final tongtaiSearchHistoryStoreProvider = Provider<TongtaiSearchHistoryStore>(
  (ref) => SharedPrefsTongtaiSearchHistoryStore(
    ref.watch(sharedPreferencesProvider),
  ),
);

/// One-shot demo-catalogue seeder so search has data on a fresh install.
final tongtaiCatalogSeederProvider = Provider<TongtaiCatalogSeeder>(
  (ref) => const TongtaiCatalogSeeder(),
);

/// The user's favourite suppliers — the personalization signal for search
/// ranking (WTM-74 AC4). Reuses the WTM-65 SQLite-backed store on the Tổng Tài
/// database.
final tongtaiSearchFavoritesStoreProvider = Provider<SupplierFavoritesStore>(
  (ref) => DriftSupplierFavoritesStore(ref.watch(tongtaiDatabaseProvider)),
);

/// The A/B experiment that assigns a sticky ranking variant per install
/// (WTM-74 AC5). Defaults to the FTS-baseline vs balanced-ranker split.
final tongtaiRankingExperimentProvider = Provider<TongtaiRankingExperiment>(
  (ref) => TongtaiRankingExperiment.defaultExperiment,
);
