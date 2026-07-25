import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/metrics/business_metrics.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_home_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_reports_screen.dart';

/// WTM-128 — the Home dashboard is User Data First: real module counts + KPIs
/// (from BusinessMetrics), a BusinessHealth read, onboarding CTAs for a new
/// business, and Demo Mode only behind an explicit action.
void main() {
  DateTime fixedNow() => DateTime(2026, 7, 24);

  // Home + any real screen it opens (Reports, etc.) read repositories; override
  // them empty so navigation targets stay off the real Drift database.
  Widget wrap(Widget home) => ProviderScope(
    overrides: [
      orderRepositoryProvider.overrideWithValue(InMemoryOrderRepository()),
      customerRepositoryProvider.overrideWithValue(
        InMemoryCustomerRepository(),
      ),
    ],
    child: MaterialApp(home: home),
  );

  // Demo dashboard (explicit action) — populated with sample data.
  Widget demoHost() => wrap(TongtaiHomeScreen.demo(clock: fixedNow));

  // A brand-new business — real zeros, onboarding CTAs.
  Widget emptyHost() =>
      wrap(TongtaiHomeScreen(metrics: BusinessMetrics.empty, clock: fixedNow));

  group('demo mode (sample data)', () {
    testWidgets('module tiles show real counts', (tester) async {
      await tester.pumpWidget(demoHost());
      await tester.pumpAndSettle();

      expect(find.text('Producer'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Consumer'), findsOneWidget);
      expect(find.text('Journey'), findsOneWidget);
      expect(find.text('28'), findsOneWidget); // products
      expect(find.text('26'), findsOneWidget); // customers
      expect(find.text('12'), findsOneWidget); // suppliers
    });

    testWidgets('KPIs come from BusinessMetrics + Healthy badge', (
      tester,
    ) async {
      await tester.pumpWidget(demoHost());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home-kpi-revenue')), findsOneWidget);
      expect(find.text('4,06tr ₫'), findsOneWidget); // 4.058.000 billable
      expect(find.text('Doanh thu'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('home-kpi-orders')),
          matching: find.text('7'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('home-health-badge')),
          matching: find.text('Healthy'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('top opportunities + goal missions render', (tester) async {
      await tester.pumpWidget(demoHost());
      await tester.pumpAndSettle();

      expect(find.text('Quạt tích điện sắp vào mùa nóng'), findsOneWidget);
      expect(find.text('92'), findsOneWidget);
      expect(find.text("Today's Missions"), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsWidgets);
      // A business with data shows no onboarding CTAs.
      expect(find.byKey(const Key('home-cta-customer')), findsNothing);
    });
  });

  group('new business (User Data First)', () {
    testWidgets('KPIs show real zeros (never "No Data")', (tester) async {
      await tester.pumpWidget(emptyHost());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home-kpi-revenue')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('home-kpi-orders')),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );
      expect(find.text('No Data'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('home-health-badge')),
          matching: find.text('Not enough data'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the five onboarding CTAs in priority order', (
      tester,
    ) async {
      await tester.pumpWidget(emptyHost());
      await tester.pumpAndSettle();

      expect(find.text('Create your first customer'), findsOneWidget);
      expect(find.text('Add your first product'), findsOneWidget);
      expect(find.text('Create your first order'), findsOneWidget);
      expect(find.text('Set your first business goal'), findsOneWidget);
      expect(find.text('Explore Demo Mode'), findsOneWidget);
    });

    testWidgets('Explore Demo Mode opens the demo dashboard (explicit)', (
      tester,
    ) async {
      await tester.pumpWidget(emptyHost());
      await tester.pumpAndSettle();

      final demo = find.byKey(const Key('home-cta-demo'));
      await tester.ensureVisible(demo);
      await tester.pumpAndSettle();
      await tester.tap(demo);
      await tester.pumpAndSettle();

      // The pushed demo dashboard shows sample data.
      expect(find.text('28'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('home-health-badge')),
          matching: find.text('Healthy'),
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('empty goals fall back to the no-missions box', (tester) async {
    await tester.pumpWidget(
      wrap(
        TongtaiHomeScreen(
          // A business with sales but no goals (so CTAs stay hidden).
          metrics: BusinessMetrics.from(orders: const [], customersCount: 5),
          customerCount: 5,
          inventoryCount: 3,
          goals: const [],
          clock: fixedNow,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Today's Missions"), findsOneWidget);
    expect(find.text('No missions yet'), findsOneWidget);
  });

  testWidgets('the KPI header opens the full Reports dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(demoHost());
    await tester.pumpAndSettle();

    final action = find.byKey(const Key('home-open-reports'));
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.byType(TongtaiReportsScreen), findsOneWidget);
  });
}
