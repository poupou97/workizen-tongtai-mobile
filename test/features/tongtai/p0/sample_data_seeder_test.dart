import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/consumer/customer_directory_service.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';
import 'package:tongtai/features/tongtai/inventory/product_inventory_service.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/sample/sample_data_seeder.dart';

/// P0 §1 (WTM-144/ADR-TON-014) — the sample-data lifecycle over the
/// repositories: seed is idempotent, links stay consistent, removal deletes
/// ONLY sample rows.
void main() {
  late InMemoryCustomerRepository customers;
  late InMemoryProductRepository products;
  late InMemoryOrderRepository orders;
  late InMemoryBusinessGoalRepository goals;
  late InMemoryFinanceRepository finance;
  late SampleDataSeeder seeder;

  setUp(() {
    customers = InMemoryCustomerRepository();
    products = InMemoryProductRepository([]);
    orders = InMemoryOrderRepository();
    goals = InMemoryBusinessGoalRepository();
    finance = InMemoryFinanceRepository();
    seeder = SampleDataSeeder(
      customers: customers,
      products: products,
      orders: orders,
      goals: goals,
      finance: finance,
    );
  });

  test('seed populates every repository with sample- prefixed rows', () async {
    await seeder.seed();

    expect(await customers.loadAll(), hasLength(kSampleCustomers.length));
    expect(await products.loadAll(), hasLength(kSampleProducts.length));
    expect(await orders.loadAll(), hasLength(kSampleCustomerOrders.length));
    expect(await goals.loadAll(), hasLength(kSampleBusinessGoals.length));
    expect(await finance.loadAll(), hasLength(kSampleTransactions.length));

    for (final c in await customers.loadAll()) {
      expect(c.id, startsWith(kSampleIdPrefix));
    }
    expect(await seeder.hasSamples(), isTrue);
  });

  test('order → customer links are remapped consistently', () async {
    await seeder.seed();
    final seededCustomers = await customers.loadAll();
    final ids = {for (final c in seededCustomers) c.id};
    for (final o in await orders.loadAll()) {
      expect(o.customerId, startsWith(kSampleIdPrefix));
      expect(
        ids,
        contains(o.customerId),
        reason: 'mỗi đơn mẫu phải trỏ tới một khách mẫu tồn tại',
      );
    }
  });

  test(
    're-seeding never duplicates (idempotent, incl. insert-only finance)',
    () async {
      await seeder.seed();
      await seeder.seed();
      await seeder.seed();

      expect(await customers.loadAll(), hasLength(kSampleCustomers.length));
      expect(await finance.loadAll(), hasLength(kSampleTransactions.length));
    },
  );

  test('removeAll deletes ONLY sample rows — user data survives', () async {
    await seeder.seed();
    // User records (UUID-style ids) in two repositories.
    await customers.upsert(
      const Customer(
        id: 'a1b2c3d4-user',
        name: 'Khách Thật',
        phone: '09',
        location: 'HN',
        orderCount: 0,
        totalSpent: 0,
        lastPurchaseDate: null,
      ),
    );
    await orders.upsert(
      CustomerOrder(
        id: 'e5f6-user-order',
        customerId: 'a1b2c3d4-user',
        orderNumber: 'DH-USER',
        date: DateTime(2026, 7, 20),
        status: OrderStatus.delivered,
        items: const [
          OrderItem(
            productName: 'Hàng thật',
            category: 'Home',
            quantity: 1,
            unitPrice: 100000,
          ),
        ],
      ),
    );

    await seeder.removeAll();

    expect((await customers.loadAll()).single.name, 'Khách Thật');
    expect((await orders.loadAll()).single.orderNumber, 'DH-USER');
    expect(await products.loadAll(), isEmpty);
    expect(await goals.loadAll(), isEmpty);
    expect(await finance.loadAll(), isEmpty);
    expect(await seeder.hasSamples(), isFalse);
  });

  test(
    'users may edit a sample row — the edit persists and stays removable',
    () async {
      await seeder.seed();
      final first = (await customers.loadAll()).first;
      await customers.upsert(first.copyWith(name: 'Đã Sửa Tên'));

      final edited = (await customers.loadAll()).firstWhere(
        (c) => c.id == first.id,
      );
      expect(edited.name, 'Đã Sửa Tên');

      await seeder
          .removeAll(); // the edited sample row still carries the prefix
      expect(await customers.loadAll(), isEmpty);
    },
  );
}
