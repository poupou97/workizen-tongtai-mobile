import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/producer/business_input.dart';
import 'package:tongtai/features/tongtai/producer/business_input_repository.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorites_store.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_context_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_finance_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_search_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_business_inputs_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_home_screen.dart';

/// WTM-461 — **ô "Nguồn hàng" trên Home đếm cùng repo với màn đích**.
///
/// Bug đường dữ liệu (ADR-TON-015): ô `home-tile-producer` từng đếm
/// `favorites.length` (search-favourites store, di sản Phase-1) trong khi cú
/// chạm của chính nó mở [TongtaiBusinessInputsScreen] — màn đếm
/// `businessInputRepository.loadAll()`. Hai nguồn cho một khái niệm ⇒ ô nói "0
/// đầu vào" cạnh một màn có N nguồn.
///
/// Gate này khoá cả hai vế cùng lúc:
/// 1. con số trên ô == số nguồn đầu vào (KHÔNG phải số favourites), và
/// 2. đúng những bản ghi ấy hiện ra khi mở màn đích.
void main() {
  DateTime fixedNow() => DateTime(2026, 8, 25);

  late InMemoryCustomerRepository customerRepo;
  late InMemoryProductRepository productRepo;
  late InMemoryOrderRepository orderRepo;
  late InMemoryBusinessGoalRepository goalRepo;
  late InMemoryFinanceRepository financeRepo;
  late InMemoryBusinessInputRepository inputRepo;
  late InMemorySupplierFavoritesStore favorites;

  setUp(() {
    customerRepo = InMemoryCustomerRepository();
    productRepo = InMemoryProductRepository([]);
    orderRepo = InMemoryOrderRepository();
    goalRepo = InMemoryBusinessGoalRepository();
    financeRepo = InMemoryFinanceRepository();
    inputRepo = InMemoryBusinessInputRepository();
    favorites = InMemorySupplierFavoritesStore();
  });

  AppDatabase? sharedDb;
  AppDatabase memoryDb() =>
      sharedDb ??= AppDatabase.forExecutor(NativeDatabase.memory());
  tearDown(() async {
    await sharedDb?.close();
    sharedDb = null;
  });

  Widget host() => ProviderScope(
    overrides: [
      tongtaiDatabaseProvider.overrideWithValue(memoryDb()),
      customerRepositoryProvider.overrideWithValue(customerRepo),
      productRepositoryProvider.overrideWithValue(productRepo),
      orderRepositoryProvider.overrideWithValue(orderRepo),
      businessGoalRepositoryProvider.overrideWithValue(goalRepo),
      financeRepositoryProvider.overrideWithValue(financeRepo),
      businessInputRepositoryProvider.overrideWithValue(inputRepo),
      tongtaiSearchFavoritesStoreProvider.overrideWithValue(favorites),
    ],
    child: MaterialApp(home: TongtaiHomeScreen(clock: fixedNow)),
  );

  /// The single numeric Text rendered inside the keyed tile.
  int tileCount(WidgetTester tester, String tileKey) {
    final numeric = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(Key(tileKey)),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data)
        .whereType<String>()
        .where((t) => int.tryParse(t) != null)
        .toList();
    expect(
      numeric,
      hasLength(1),
      reason: '$tileKey must render exactly one count, got $numeric',
    );
    return int.parse(numeric.single);
  }

  testWidgets('producer tile counts Business Inputs, NOT favourites, and its '
      'destination screen shows exactly those records', (tester) async {
    // Four business inputs is the number the tile must show...
    await inputRepo.upsertAll(const [
      BusinessInput(
        id: 'i1',
        name: 'Máy chủ VPS',
        kind: BusinessInputKind.infrastructure,
        cadence: InputCadence.monthly,
        expectedAmount: 250000,
      ),
      BusinessInput(
        id: 'i2',
        name: 'Google Workspace',
        kind: BusinessInputKind.tooling,
        cadence: InputCadence.monthly,
        expectedAmount: 150000,
      ),
      BusinessInput(
        id: 'i3',
        name: 'Workizen AI',
        kind: BusinessInputKind.provider,
        cadence: InputCadence.usageBased,
      ),
      BusinessInput(
        id: 'i4',
        name: 'Xưởng may Thành Phát',
        kind: BusinessInputKind.supplier,
        cadence: InputCadence.usageBased,
      ),
    ]);
    // ...while the favourites store holds a DIFFERENT number. If the tile still
    // read favourites (the bug), it would show 2, not 4.
    await favorites.add('fav-a');
    await favorites.add('fav-b');

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final inputCount = (await inputRepo.loadAll()).length;
    expect(inputCount, 4);
    expect(
      tileCount(tester, 'home-tile-producer'),
      inputCount,
      reason: 'tile must equal the business-input repository, not favourites',
    );

    // The tile's destination is the same source it counts: open it and every
    // counted record is visible (Summary Count == Domain Visible Records).
    await tester.ensureVisible(find.byKey(const Key('home-tile-producer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-tile-producer')));
    await tester.pumpAndSettle();

    expect(find.byType(TongtaiBusinessInputsScreen), findsOneWidget);
    // One row Card per input, keyed `inputs-item-<id>`. Exclude the row's own
    // `-monthly`/`-delete` child keys so we count rows, not widgets.
    final visibleRows = tester.allWidgets
        .map((w) => w.key)
        .whereType<ValueKey<String>>()
        .where(
          (k) =>
              k.value.startsWith('inputs-item-') &&
              !k.value.endsWith('-monthly') &&
              !k.value.endsWith('-delete'),
        )
        .toSet()
        .length;
    expect(
      visibleRows,
      inputCount,
      reason:
          'destination screen must show exactly the records the tile counted',
    );
  });

  testWidgets('a business with zero inputs shows 0 — and adding one moves the '
      'tile, favourites never touching it', (tester) async {
    await favorites.add('fav-only'); // favourites present, inputs empty

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(
      tileCount(tester, 'home-tile-producer'),
      0,
      reason: '2 favourites must NOT leak into the producer tile',
    );

    // Add one real input and the tile follows the input repository.
    await inputRepo.upsert(
      const BusinessInput(
        id: 'i9',
        name: 'Tên miền .vn',
        kind: BusinessInputKind.infrastructure,
        cadence: InputCadence.yearly,
        expectedAmount: 850000,
      ),
    );
    // Tear the screen down first so a fresh Home State re-runs its load — the
    // tile reads the repository on load, so this proves the source, not a
    // cache (a bare re-pump would reuse the same State and its old value).
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(tileCount(tester, 'home-tile-producer'), 1);
  });
}
