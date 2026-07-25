import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_create_order_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_inventory_picker_screen.dart';

/// WTM-126 — the Create Order flow: an order line must reference an inventory
/// product (via the picker), and the line snapshots the product identity + the
/// actual sold price at sale time.
void main() {
  final customer = Customer(
    id: 'c1',
    name: 'Phương Nguyễn',
    phone: '+84912345678',
    location: 'Hà Nội',
    orderCount: 0,
    totalSpent: 0,
    lastPurchaseDate: null,
  );

  final products = [
    Product(
      id: 'p1',
      sku: 'SKU-EL-001',
      name: 'Quạt mini',
      category: 'Electronics',
      quantity: 20,
      pricePerUnit: 89000,
      reorderLevel: 5,
      updatedAt: DateTime(2026, 7, 1),
    ),
    Product(
      id: 'p2',
      sku: 'SKU-FA-002',
      name: 'Áo thun',
      category: 'Fashion',
      quantity: 8,
      pricePerUnit: 120000,
      reorderLevel: 3,
      updatedAt: DateTime(2026, 7, 1),
    ),
  ];

  void useTallViewport(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(600, 1400);
  }

  /// Pumps the screen as the root so its body buttons are directly hit-testable;
  /// [captured] receives the order on save (via onSubmit).
  Future<List<CustomerOrder>> pumpForm(WidgetTester tester) async {
    final captured = <CustomerOrder>[];
    await tester.pumpWidget(
      MaterialApp(
        home: TongtaiCreateOrderScreen(
          customer: customer,
          products: products,
          clock: () => DateTime(2026, 7, 25, 9),
          idFactory: () => 'order-1',
          orderNumberFactory: (_) => 'DH-2026-9001',
          onSubmit: captured.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return captured;
  }

  Future<void> addLine(
    WidgetTester tester, {
    required String productId,
    required String quantity,
    String? price,
  }) async {
    await tester.tap(find.byKey(const Key('create-order-add-item')));
    await tester.pumpAndSettle();
    expect(find.byType(TongtaiInventoryPickerScreen), findsOneWidget);
    await tester.tap(find.byKey(Key('picker-product-$productId')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('order-item-quantity')),
      quantity,
    );
    if (price != null) {
      await tester.enterText(find.byKey(const Key('order-item-price')), price);
    }
    await tester.tap(find.byKey(const Key('order-item-add')));
    await tester.pumpAndSettle();
  }

  testWidgets('a line references an inventory product and snapshots it', (
    tester,
  ) async {
    useTallViewport(tester);
    final captured = await pumpForm(tester);

    expect(find.text('Customer: Phương Nguyễn'), findsOneWidget);
    await addLine(tester, productId: 'p1', quantity: '3');

    expect(find.text('Quạt mini'), findsOneWidget);
    await tester.tap(find.byKey(const Key('create-order-save')));
    await tester.pumpAndSettle();

    expect(captured, hasLength(1));
    final order = captured.single;
    expect(order.customerId, 'c1');
    expect(order.orderNumber, 'DH-2026-9001');
    expect(order.items, hasLength(1));
    final line = order.items.single;
    expect(line.productId, 'p1'); // references inventory
    expect(line.productName, 'Quạt mini');
    expect(line.sku, 'SKU-EL-001');
    expect(line.quantity, 3);
    expect(line.unitPrice, 89000); // inventory default sold price
    expect(order.totalAmount, 267000);
  });

  testWidgets('the sold price may override the inventory default', (
    tester,
  ) async {
    useTallViewport(tester);
    final captured = await pumpForm(tester);

    // Override 120,000 → 99,000 (a discount at sale time).
    await addLine(tester, productId: 'p2', quantity: '2', price: '99000');
    await tester.tap(find.byKey(const Key('create-order-save')));
    await tester.pumpAndSettle();

    final line = captured.single.items.single;
    expect(line.productId, 'p2');
    expect(line.unitPrice, 99000); // overridden sold price, not 120,000
    expect(captured.single.totalAmount, 198000);
  });

  testWidgets('save is refused with no line items', (tester) async {
    useTallViewport(tester);
    final captured = await pumpForm(tester);

    await tester.tap(find.byKey(const Key('create-order-save')));
    await tester.pumpAndSettle();

    expect(find.text('Add at least one product'), findsOneWidget);
    expect(captured, isEmpty);
  });

  testWidgets('a line can be removed before saving', (tester) async {
    useTallViewport(tester);
    final captured = await pumpForm(tester);

    await addLine(tester, productId: 'p1', quantity: '1');
    await addLine(tester, productId: 'p2', quantity: '1');
    expect(find.text('2 items'), findsOneWidget);

    await tester.tap(find.byKey(const Key('order-line-remove-0')));
    await tester.pumpAndSettle();
    expect(find.text('1 item'), findsOneWidget);

    await tester.tap(find.byKey(const Key('create-order-save')));
    await tester.pumpAndSettle();
    expect(captured.single.items, hasLength(1));
  });
}
