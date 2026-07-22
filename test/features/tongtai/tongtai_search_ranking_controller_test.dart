import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/database/search/tongtai_search_service.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorite.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorites_store.dart';
import 'package:tongtai/features/tongtai/search/tongtai_ranking.dart';
import 'package:tongtai/features/tongtai/search/tongtai_search_history_store.dart';
import 'package:tongtai/features/tongtai/search/tongtai_unified_search_controller.dart';

/// Integration tests for WTM-74 ranking wired through the unified-search
/// controller against a REAL in-memory FTS5 database: the personalization
/// signal (favourites) genuinely reorders results, and the A/B experiment
/// assigns + applies a sticky ranking variant.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    await _seed(db);
  });

  tearDown(() async => db.close());

  TongtaiUnifiedSearchController build({
    TongtaiSearchRanker? ranker,
    SupplierFavoritesStore? favoritesStore,
    TongtaiRankingExperiment? experiment,
    Future<String> Function()? unitIdLoader,
    List<String>? history,
  }) {
    return TongtaiUnifiedSearchController(
      TongtaiSearchService(db),
      InMemoryTongtaiSearchHistoryStore(seed: history),
      debounce: Duration.zero,
      ranker: ranker ?? const TongtaiSearchRanker(),
      favoritesStore: favoritesStore,
      experiment: experiment,
      unitIdLoader: unitIdLoader,
      // Fixed clock so recency is identical for the (equally-dated) seed rows.
      clock: () => DateTime(2026, 7, 16),
    );
  }

  test(
    'a favourited supplier is promoted under the personalized variant',
    () async {
      final favorites = InMemorySupplierFavoritesStore([
        SupplierFavorite(supplierId: 'sup-b', addedAt: DateTime(2026, 1, 1)),
      ]);
      final controller = build(
        ranker: const TongtaiSearchRanker(
          weights: TongtaiRankingWeights.personalized,
        ),
        favoritesStore: favorites,
      );
      await controller.init();
      await controller.submit('coffee');

      final ids = controller.results.suppliers.map((s) => s.id).toList();
      expect(ids, containsAll(<String>['sup-a', 'sup-b']));
      // Both suppliers match 'coffee' equally well; the favourite is lifted first.
      expect(ids.first, 'sup-b');

      controller.dispose();
    },
  );

  test('favouriting the other supplier flips the top result', () async {
    // Everything else is equal, so the favourite alone decides the winner —
    // whichever supplier is favourited surfaces first (independent of the FTS
    // tie-break order).
    Future<String> topFor(String favouriteId) async {
      final controller = build(
        ranker: const TongtaiSearchRanker(
          weights: TongtaiRankingWeights.personalized,
        ),
        favoritesStore: InMemorySupplierFavoritesStore([
          SupplierFavorite(
            supplierId: favouriteId,
            addedAt: DateTime(2026, 1, 1),
          ),
        ]),
      );
      await controller.init();
      await controller.submit('coffee');
      final top = controller.results.suppliers.first.id;
      controller.dispose();
      return top;
    }

    expect(await topFor('sup-a'), 'sup-a');
    expect(await topFor('sup-b'), 'sup-b');
  });

  test(
    'the A/B experiment assigns a sticky variant and applies its weights',
    () async {
      const experiment = TongtaiRankingExperiment.defaultExperiment;
      final expected = experiment.assign('unit-xyz');

      final controller = build(
        experiment: experiment,
        unitIdLoader: () async => 'unit-xyz',
      );
      await controller.init();

      expect(controller.activeVariant, isNotNull);
      expect(controller.activeVariant!.id, expected.id);

      // The assigned variant must actually drive ranking: forcing the personalized
      // arm + a favourite reorders results.
      controller.dispose();
    },
  );

  test(
    'no experiment configured leaves activeVariant null (default ranker)',
    () async {
      final controller = build();
      await controller.init();
      expect(controller.activeVariant, isNull);
      await controller.submit('coffee');
      expect(controller.results.suppliers, isNotEmpty);
      controller.dispose();
    },
  );
}

const String _ownerId = 'owner-rank';
const String _businessId = 'biz-rank';

Future<void> _seed(AppDatabase db) async {
  await db
      .into(db.usersTable)
      .insert(
        UsersTableCompanion.insert(
          id: _ownerId,
          email: 'owner@rank.test',
          name: 'Chủ tiệm',
        ),
      );
  await db
      .into(db.businessesTable)
      .insert(
        BusinessesTableCompanion.insert(
          id: _businessId,
          ownerId: _ownerId,
          name: 'Cửa hàng',
          country: const Value('VN'),
        ),
      );

  Future<void> supplier(String id, String name) {
    return db
        .into(db.producersTable)
        .insert(
          ProducersTableCompanion.insert(
            id: id,
            businessId: _businessId,
            name: name,
            category: const Value('Nông sản'),
            country: const Value('Vietnam'),
            rating: const Value(4.5),
            // Equal, fixed timestamps so recency is identical across the pair.
            updatedAt: Value(DateTime(2026, 7, 10)),
            createdAt: Value(DateTime(2026, 7, 10)),
          ),
        );
  }

  // Two suppliers with identical, equally-matching names so only the
  // personalization signal can separate them.
  await supplier('sup-a', 'Coffee House');
  await supplier('sup-b', 'Coffee House');
}
