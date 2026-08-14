import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/orders/order_tone.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_directory_controller.dart';
import 'package:tongtai/features/tongtai/consumer/customer_order.dart';
import 'package:tongtai/features/tongtai/consumer/customer_order_history_service.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/orders/order_controller.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_create_order_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_history_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_list_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_inventory_picker_screen.dart';
import 'package:tongtai/core/design/tt.dart';

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

  // WTM-224: the screen raises the one "business data changed" signal at the
  // point of the WRITE (an order is the biggest business event in the app), so
  // it is a Consumer now and needs a scope.
  Widget host() => ProviderScope(
    child: MaterialApp(
      home: TongtaiCustomerHistoryScreen(
        customer: customer,
        service: service,
        clock: () => now,
      ),
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

    // WTM-393: category chips show localized labels now; the row scrolls
    // horizontally, so the Fashion chip can sit off-screen — reveal it first.
    await tester.ensureVisible(find.text('Fashion'));
    await tester.tap(find.text('Fashion'));
    await tester.pumpAndSettle();

    expect(visibleOrderNumbers(tester).toList(), ['DH-2026-0086']);

    // Back to all categories (the All chip may have scrolled off-screen left).
    await tester.ensureVisible(find.text('All'));
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
      ProviderScope(
        child: MaterialApp(
          home: TongtaiCustomerHistoryScreen(
            customer: customer.copyWith(name: 'Không Có Đơn'),
            service: CustomerOrderHistoryService(const []),
            clock: () => now,
          ),
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
    expect(tongtaiOrderStatusTone(OrderStatus.pending).color, TtColors.warning);
    expect(tongtaiOrderStatusTone(OrderStatus.confirmed).color, TtColors.info);
    expect(tongtaiOrderStatusTone(OrderStatus.shipped).color, TtColors.info);
    expect(
      tongtaiOrderStatusTone(OrderStatus.delivered).color,
      TtColors.success,
    );
    expect(
      tongtaiOrderStatusTone(OrderStatus.cancelled).color,
      TtColors.danger,
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
      expect(find.text('Purchase history — Phương Nguyễn'), findsOneWidget);
      expect(find.textContaining('DH-2026-0101'), findsOneWidget);
    },
  );

  group('Create Order from history (WTM-126)', () {
    final products = [
      Product(
        id: 'p1',
        sku: 'SKU-EL-001',
        name: 'Quạt tích điện',
        category: 'Electronics',
        quantity: 20,
        pricePerUnit: 350000,
        reorderLevel: 5,
        updatedAt: DateTime(2026, 7, 1),
      ),
    ];

    testWidgets('no Create Order action in read-only (sample) mode', (
      tester,
    ) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: TongtaiCustomerHistoryScreen(
              customer: customer,
              service: service,
              clock: () => now,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-create-order')), findsNothing);
    });

    testWidgets('creates an inventory-referenced order and shows it', (
      tester,
    ) async {
      useTallViewport(tester);
      final orders = OrderController.inMemory();
      await orders.hydrate();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: TongtaiCustomerHistoryScreen(
              customer: customer,
              orderController: orders,
              products: products,
              clock: () => now,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Starts empty (User Data First) with the Create Order action available.
      expect(find.text('No orders in this period'), findsOneWidget);
      await tester.tap(find.byKey(const Key('history-create-order')));
      await tester.pumpAndSettle();

      // Create Order form → add a line via the inventory picker.
      expect(find.byType(TongtaiCreateOrderScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('create-order-add-item')));
      await tester.pumpAndSettle();
      expect(find.byType(TongtaiInventoryPickerScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('picker-product-p1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('order-item-quantity')), '2');
      await tester.tap(find.byKey(const Key('order-item-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create-order-save')));
      await tester.pumpAndSettle();

      // Back on history — the new order is persisted to the controller + shown.
      expect(orders.count, 1);
      expect(orders.orders.single.items.single.productId, 'p1');
      expect(find.byType(TongtaiCustomerHistoryScreen), findsOneWidget);
      expect(find.textContaining('Quạt tích điện'), findsOneWidget);
      expect(find.text('1 order'), findsOneWidget);
    });
  });
}
