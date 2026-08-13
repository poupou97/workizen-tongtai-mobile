import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_search_provider.dart'
    hide tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/tongtai.dart';

void main() {
  group('Tổng Tài Navigation Tests', () {
    testWidgets('BottomNav renders all 5 tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: TongtaiBottomNav(
              selectedIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );

      // Every tab is present, found by **key**: the labels are localized, and
      // WTM-192 renamed the fifth one — a test reading labels checks the
      // translation, not the navigation.
      for (var tab = TongtaiTabs.home; tab < TongtaiTabs.count; tab++) {
        expect(
          find.byKey(Key('nav-tab-$tab')),
          findsOneWidget,
          reason: 'tab $tab',
        );
      }
    });

    testWidgets('BottomNav tab selection callback works', (
      WidgetTester tester,
    ) async {
      int selectedTab = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: TongtaiBottomNav(
              selectedIndex: selectedTab,
              onTabSelected: (index) {
                selectedTab = index;
              },
            ),
          ),
        ),
      );

      // Verify initial state
      expect(selectedTab, equals(0));

      // Tap Producer tab (index 1)
      await tester.tap(find.text('Producer'));
      expect(selectedTab, equals(1));

      // Tap Inventory tab (index 2)
      await tester.tap(find.text('Inventory'));
      expect(selectedTab, equals(2));

      // Tap Consumer tab (index 3)
      await tester.tap(find.byKey(const Key('nav-tab-3')));
      expect(selectedTab, equals(TongtaiTabs.consumer));

      // Slot 4 is Opportunity now (WTM-192).
      await tester.tap(find.byKey(const Key('nav-tab-4')));
      expect(selectedTab, equals(TongtaiTabs.opportunity));
    });

    testWidgets('All 5 screens render without errors', (
      WidgetTester tester,
    ) async {
      // Test Home Screen — a ConsumerStatefulWidget that loads its KPIs +
      // counts from the repositories (WTM-128); override the Drift database with
      // an in-memory one so this smoke test stays off the file-system.
      await tester.pumpWidget(
        ProviderScope(
          key: const Key('nav-home-scope'),
          overrides: [
            tongtaiDatabaseProvider.overrideWithValue(
              AppDatabase.forExecutor(NativeDatabase.memory()),
            ),
          ],
          child: const MaterialApp(home: TongtaiHomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      // WTM-404: cửa trước mang TÊN SẢN PHẨM, không phải chữ "Home Dashboard".
      // Tìm bằng **Key**, không bằng chuỗi hiển thị — chuỗi đổi theo locale và
      // theo thương hiệu, Key thì không (luật stable test IDs).
      expect(find.byKey(const Key('home-brand-title')), findsOneWidget);

      // Test Producer Screen — reads the favourites store + the
      // rule-generated opportunities (P0 correction: no more static shell).
      await tester.pumpWidget(
        ProviderScope(
          key: const Key('nav-producer-scope'),
          overrides: [
            customerRepositoryProvider.overrideWithValue(
              InMemoryCustomerRepository(),
            ),
            productRepositoryProvider.overrideWithValue(
              InMemoryProductRepository(),
            ),
            orderRepositoryProvider.overrideWithValue(
              InMemoryOrderRepository(),
            ),
            businessGoalRepositoryProvider.overrideWithValue(
              InMemoryBusinessGoalRepository(),
            ),
            tongtaiSearchFavoritesStoreProvider.overrideWithValue(
              InMemorySupplierFavoritesStore(),
            ),
          ],
          child: const MaterialApp(home: TongtaiProducerScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Producer Hub'), findsOneWidget);

      // Test Inventory Screen (WTM-68: product list; AppBar title "Inventory").
      // Override the repository so the ConsumerStatefulWidget's hydrate() stays
      // off the real Drift database in this nav smoke test (WTM-121).
      await tester.pumpWidget(
        ProviderScope(
          key: const Key('nav-inventory-scope'),
          overrides: [
            productRepositoryProvider.overrideWithValue(
              InMemoryProductRepository(),
            ),
          ],
          child: const MaterialApp(home: TongtaiInventoryScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Inventory'), findsOneWidget);

      // Test Consumer Screen — reads the customer repository
      // (P0 correction: no more static shell).
      await tester.pumpWidget(
        ProviderScope(
          key: const Key('nav-consumer-scope'),
          overrides: [
            customerRepositoryProvider.overrideWithValue(
              InMemoryCustomerRepository(),
            ),
          ],
          child: const MaterialApp(home: TongtaiConsumerScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Customer Intelligence'), findsOneWidget);

      // Test More Screen
      await tester.pumpWidget(const MaterialApp(home: TongtaiMoreScreen()));
      expect(find.text('More'), findsOneWidget);
    });

    test('Design tokens are correctly defined', () {
      // Verify all design token colors are non-null and valid
      expect(TongtaiDesignTokens.producerGreen, isNotNull);
      expect(TongtaiDesignTokens.inventoryOrange, isNotNull);
      expect(TongtaiDesignTokens.consumerBlue, isNotNull);
      expect(TongtaiDesignTokens.setupGray, isNotNull);

      // Verify tab names
      expect(getTabName(TongtaiTabs.home), equals('Home'));
      expect(getTabName(TongtaiTabs.producer), equals('Producer'));
      expect(getTabName(TongtaiTabs.inventory), equals('Inventory'));
      expect(getTabName(TongtaiTabs.consumer), equals('Consumer'));
      expect(getTabName(TongtaiTabs.opportunity), equals('Opportunity'));

      // Verify tab colors
      final producerColor = getTabColor(TongtaiTabs.producer);
      expect(producerColor, equals(TongtaiDesignTokens.producerGreen));

      final inventoryColor = getTabColor(TongtaiTabs.inventory);
      expect(inventoryColor, equals(TongtaiDesignTokens.inventoryOrange));

      final consumerColor = getTabColor(TongtaiTabs.consumer);
      expect(consumerColor, equals(TongtaiDesignTokens.consumerBlue));

      // WTM-192: Opportunity took the fifth slot and carries its own colour —
      // a tab with the neutral grey reads as a leftover, not a capability.
      expect(
        getTabColor(TongtaiTabs.opportunity),
        equals(TongtaiDesignTokens.copilotViolet),
      );
    });

    test('Tab indices are correctly defined', () {
      // Verify tab constants
      expect(TongtaiTabs.home, equals(0));
      expect(TongtaiTabs.producer, equals(1));
      expect(TongtaiTabs.inventory, equals(2));
      expect(TongtaiTabs.consumer, equals(3));
      // WTM-192: slot 4 is Opportunity now. The index is **reused**, so a
      // seller with tab 4 persisted lands on a real tab instead of an
      // out-of-range index.
      expect(TongtaiTabs.opportunity, equals(4));
    });
  });
}
