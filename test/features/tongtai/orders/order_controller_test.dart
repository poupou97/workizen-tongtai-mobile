import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_controller.dart';

/// WTM-125 — the Orders controller mirrors the repo-backed hydrate/upsert
/// pattern of the other capability controllers.
void main() {
  CustomerOrder order(String id, {String customerId = 'c1', DateTime? date}) =>
      CustomerOrder(
        id: id,
        customerId: customerId,
        orderNumber: 'DH-$id',
        date: date ?? DateTime(2026, 7, 1),
        status: OrderStatus.confirmed,
        items: const [
          OrderItem(
            productName: 'X',
            category: 'Home',
            quantity: 1,
            unitPrice: 1000,
          ),
        ],
      );

  test('hydrate loads the injected orders', () async {
    final c = OrderController.inMemory([order('o1'), order('o2')]);
    expect(c.isHydrated, isFalse);
    await c.hydrate();
    expect(c.isHydrated, isTrue);
    expect(c.count, 2);
  });

  test('orders getter sorts newest-first', () async {
    final c = OrderController.inMemory([
      order('old', date: DateTime(2026, 1, 1)),
      order('new', date: DateTime(2026, 9, 1)),
      order('mid', date: DateTime(2026, 5, 1)),
    ]);
    await c.hydrate();
    expect(c.orders.map((o) => o.id), ['new', 'mid', 'old']);
  });

  test('upsert appends then replaces, notifying', () async {
    final c = OrderController.inMemory();
    await c.hydrate();
    var notified = 0;
    c.addListener(() => notified++);

    expect(await c.upsert(order('o1')), isFalse); // append
    expect(await c.upsert(order('o1', customerId: 'c9')), isTrue); // replace
    expect(c.count, 1);
    expect(c.orders.single.customerId, 'c9');
    expect(notified, 2);
  });

  test('forCustomer filters to one customer', () async {
    final c = OrderController.inMemory([
      order('o1', customerId: 'c1'),
      order('o2', customerId: 'c2'),
      order('o3', customerId: 'c1'),
    ]);
    await c.hydrate();
    expect(c.forCustomer('c1').map((o) => o.id), ['o1', 'o3']);
  });
}
