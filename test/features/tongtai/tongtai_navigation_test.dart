import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

      // Verify all tab labels are present
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Producer'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Consumer'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
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
      await tester.tap(find.text('Consumer'));
      expect(selectedTab, equals(3));

      // Tap More tab (index 4)
      await tester.tap(find.text('More'));
      expect(selectedTab, equals(4));
    });

    testWidgets('All 5 screens render without errors', (
      WidgetTester tester,
    ) async {
      // Test Home Screen
      await tester.pumpWidget(const MaterialApp(home: TongtaiHomeScreen()));
      expect(find.text('Home Dashboard'), findsOneWidget);

      // Test Producer Screen
      await tester.pumpWidget(const MaterialApp(home: TongtaiProducerScreen()));
      expect(find.text('Producer Hub'), findsOneWidget);

      // Test Inventory Screen (WTM-68: product list; AppBar title "Inventory").
      // Override the repository so the ConsumerStatefulWidget's hydrate() stays
      // off the real Drift database in this nav smoke test (WTM-121).
      await tester.pumpWidget(
        ProviderScope(
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

      // Test Consumer Screen
      await tester.pumpWidget(const MaterialApp(home: TongtaiConsumerScreen()));
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
      expect(getTabName(TongtaiTabs.more), equals('More'));

      // Verify tab colors
      final producerColor = getTabColor(TongtaiTabs.producer);
      expect(producerColor, equals(TongtaiDesignTokens.producerGreen));

      final inventoryColor = getTabColor(TongtaiTabs.inventory);
      expect(inventoryColor, equals(TongtaiDesignTokens.inventoryOrange));

      final consumerColor = getTabColor(TongtaiTabs.consumer);
      expect(consumerColor, equals(TongtaiDesignTokens.consumerBlue));
    });

    test('Tab indices are correctly defined', () {
      // Verify tab constants
      expect(TongtaiTabs.home, equals(0));
      expect(TongtaiTabs.producer, equals(1));
      expect(TongtaiTabs.inventory, equals(2));
      expect(TongtaiTabs.consumer, equals(3));
      expect(TongtaiTabs.more, equals(4));
    });
  });
}
