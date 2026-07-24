import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_directory_controller.dart';
import 'package:tongtai/features/tongtai/consumer/customer_order.dart';
import 'package:tongtai/features/tongtai/consumer/customer_order_history_service.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/navigation/tongtai_design_tokens.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_history_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_list_screen.dart';

/// Widget tests for the WTM-77 Purchase History screen + its entry point on
/// the customer list.
void main() {
  void useTallViewport(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(500, 3400);
  }

  final customer = Customer(
    id: 'c1',
    name: 'Phương Nguyễn',
    phone: '+84912345678',
    location: 'Hà Nội',
    orderCount: 3,
    totalSpent: 5000000,
    lastPurchaseDate: DateTime(2026, 7, 10),
  );

  // Fixed "today" so the Last-30/90-days presets are deterministic.
  final now = DateTime(2026, 7, 22);

  final service = CustomerOrderHistoryService([
    CustomerOrder(
      id: 'o1',
      customerId: 'c1',
      orderNumber: 'DH-2026-0101',
      date: DateTime(2026, 7, 10), // within 30 days
      status: OrderStatus.delivered,
      items: const [
        OrderItem(
          productName: 'Quạt mini',
          category: 'Electronics',
          quantity: 2,
          unitPrice: 89000,
        ),
      ],
    ),
    CustomerOrder(
      id: 'o2',
      customerId: 'c1',
      orderNumber: 'DH-2026-0086',
      date: DateTime(2026, 5, 18), // within 90 days, outside 30
      status: OrderStatus.shipped,
      items: const [
        OrderItem(
          productName: 'Áo thun',
          category: 'Fashion',
          quantity: 3,
          unitPrice: 120000,
        ),
      ],
    ),
    CustomerOrder(
      id: 'o3',
      customerId: 'c1',
      orderNumber: 'DH-2026-0009',
      date: DateTime(2026, 1, 5), // outside both presets
      status: OrderStatus.cancelled,
      items: const [
        OrderItem(
          productName: 'Đèn LED',
          category: 'Home',
          quantity: 1,
          unitPrice: 145000,
        ),
      ],
    ),
  ]);

  Widget host() => MaterialApp(
    home: TongtaiCustomerHistoryScreen(
      customer: customer,
      service: service,
      clock: () => now,
    ),
  );

  Iterable<String> visibleOrderNumbers(WidgetTester tester) => tester
      .widgetList<Text>(find.textContaining('DH-2026-'))
      .map((t) => t.data!);

  testWidgets('AC1/AC2: orders render newest first with number, date, '
      'status and total', (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Newest first.
    expect(visibleOrderNumbers(tester).toList(), [
      'DH-2026-0101',
      'DH-2026-0086',
      'DH-2026-0009',
    ]);
    // Date + status + total of the newest order.
    expect(find.textContaining('2026-07-10'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
    expect(find.text('Shipped'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('178.000 ₫'), findsWidgets); // 2 × 89.000
  });

  testWidgets('AC3: item lines show product and quantity', (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.textContaining('2 × Quạt mini'), findsOneWidget);
    expect(find.textContaining('3 × Áo thun'), findsOneWidget);
  });

  testWidgets('AC4: category filter narrows the list', (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fashion'));
    await tester.pumpAndSettle();

    expect(visibleOrderNumbers(tester).toList(), ['DH-2026-0086']);

    // Back to all categories.
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(visibleOrderNumbers(tester), hasLength(3));
  });

  testWidgets('AC4: date-range presets filter with the injected clock', (
    tester,
  ) async {
    useTallViewport(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Last 30 days'));
    await tester.tap(find.text('Last 30 days'));
    await tester.pumpAndSettle();
    expect(visibleOrderNumbers(tester).toList(), ['DH-2026-0101']);

    await tester.ensureVisible(find.text('Last 90 days'));
    await tester.tap(find.text('Last 90 days'));
    await tester.pumpAndSettle();
    expect(visibleOrderNumbers(tester).toList(), [
      'DH-2026-0101',
      'DH-2026-0086',
    ]);

    await tester.ensureVisible(find.text('All time'));
    await tester.tap(find.text('All time'));
    await tester.pumpAndSettle();
    expect(visibleOrderNumbers(tester), hasLength(3));
  });

  testWidgets('AC5: metrics header shows AOV and repurchase rate '
      '(cancelled excluded)', (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Non-cancelled: o1 (178.000) + o2 (360.000) → 2 orders, AOV 269.000.
    expect(
      find.descendant(
        of: find.byKey(const Key('history-metric-orders')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('history-metric-aov')),
        matching: find.text('269.000 ₫'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('history-metric-repurchase')),
        matching: find.text('50%'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('empty state when filters match nothing', (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: TongtaiCustomerHistoryScreen(
          customer: customer.copyWith(name: 'Không Có Đơn'),
          service: CustomerOrderHistoryService(const []),
          clock: () => now,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No orders in this period'), findsOneWidget);
    expect(find.text('0 orders'), findsOneWidget);
  });

  testWidgets('status chip colors map by status (pure function)', (
    tester,
  ) async {
    expect(
      tongtaiOrderStatusColor(OrderStatus.pending),
      TongtaiDesignTokens.warning,
    );
    expect(
      tongtaiOrderStatusColor(OrderStatus.confirmed),
      TongtaiDesignTokens.info,
    );
    expect(
      tongtaiOrderStatusColor(OrderStatus.shipped),
      TongtaiDesignTokens.info,
    );
    expect(
      tongtaiOrderStatusColor(OrderStatus.delivered),
      TongtaiDesignTokens.success,
    );
    expect(
      tongtaiOrderStatusColor(OrderStatus.cancelled),
      TongtaiDesignTokens.error,
    );
  });

  testWidgets(
    'list screen: the row history button opens this customer\'s history',
    (tester) async {
      useTallViewport(tester);
      final directory = CustomerDirectoryController.inMemory([customer]);
      await directory.hydrate();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: TongtaiCustomerListScreen(
              directory: directory,
              orderHistory: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('customer-history-c1')));
      await tester.pumpAndSettle();

      expect(find.byType(TongtaiCustomerHistoryScreen), findsOneWidget);
      expect(find.text('Purchase History — Phương Nguyễn'), findsOneWidget);
      expect(find.textContaining('DH-2026-0101'), findsOneWidget);
    },
  );
}
