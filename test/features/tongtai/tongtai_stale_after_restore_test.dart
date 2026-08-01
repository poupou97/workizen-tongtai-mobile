import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/prefs.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorites_store.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_data_invalidation.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_finance_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_search_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_consumer_screen.dart';

/// WTM-174 — a screen that is already built must not keep showing a business
/// that no longer exists.
///
/// Found on a Nokia 6.1: restore a backup of 7 customers over a business of 42,
/// and the success card says 7 while Home keeps showing **42** until the app is
/// killed. The database was right the whole time; only the screen lied — which
/// is worse than an error, because a seller reads it as "the restore failed".
///
/// Root cause: `invalidateBusinessDataProviders` drops the cached
/// `FutureProvider`s, but the four shell tabs hold their rows in a
/// `ScreenDataController` created in `initState`, and the shell keeps them alive
/// in an `IndexedStack`. `initState` runs once per launch, so the invalidation
/// never reached them. The comment on that list even said *"Home looked right
/// because it re-reads its repositories in initState"* — true when it was
/// written, made false by the WTM-148 seam migration.
void main() {
  testWidgets('a restore-style bulk change refreshes an already-built tab', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final customers = InMemoryCustomerRepository();

    Customer c(String id) => Customer(
      id: id,
      name: 'Khách $id',
      phone: '090$id',
      location: 'Hà Nội',
      orderCount: 0,
      totalSpent: 0,
      lastPurchaseDate: null,
    );

    // The business as it stands when the seller opens the tab.
    await customers.upsertAll([for (var i = 0; i < 5; i++) c('old$i')]);

    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          customerRepositoryProvider.overrideWithValue(customers),
          productRepositoryProvider.overrideWithValue(
            InMemoryProductRepository([]),
          ),
          orderRepositoryProvider.overrideWithValue(InMemoryOrderRepository()),
          businessGoalRepositoryProvider.overrideWithValue(
            InMemoryBusinessGoalRepository(),
          ),
          financeRepositoryProvider.overrideWithValue(
            InMemoryFinanceRepository(),
          ),
          tongtaiSearchFavoritesStoreProvider.overrideWithValue(
            InMemorySupplierFavoritesStore(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('vi')],
          home: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const TongtaiConsumerScreen();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('consumer-count-badge'))).data,
      '5',
      reason: 'the tab starts by showing the business it loaded',
    );

    // What a restore does: replace every row, then announce it.
    await customers.deleteAll();
    await customers.upsertAll([for (var i = 0; i < 2; i++) c('new$i')]);
    invalidateBusinessDataProviders(capturedRef);
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('consumer-count-badge'))).data,
      '2',
      reason:
          'the tab was alive in the shell the whole time — it has to re-read, '
          'or it keeps showing a business that was just replaced',
    );
  });
}
