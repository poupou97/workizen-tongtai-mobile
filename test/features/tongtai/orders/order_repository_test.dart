import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/core/local_workspace.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';

/// WTM-125 — Orders (sales) persistence over Drift. Orders is an independent
/// capability that OWNS revenue + line items (Founder G-2 / ADR-TON-010). Covers
/// the Founder test set: round-trip, backward compatibility, corrupt-JSON
/// fallback, denormalized revenue columns, business isolation, items round-trip.
void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forExecutor(NativeDatabase.memory()));
  tearDown(() => db.close());

  CustomerOrder order(
    String id, {
    String customerId = 'c1',
    String orderNumber = 'DH-2026-0001',
    DateTime? date,
    OrderStatus status = OrderStatus.confirmed,
    List<OrderItem> items = const [
      OrderItem(
        productName: 'Quạt mini',
        category: 'Electronics',
        quantity: 2,
        unitPrice: 89000,
      ),
    ],
  }) => CustomerOrder(
    id: id,
    customerId: customerId,
    orderNumber: orderNumber,
    date: date ?? DateTime(2026, 7, 10),
    status: status,
    items: items,
  );

  /// Orders FK-reference a customer; seed one under [businessId] (defaults to the
  /// local business) so inserts hold.
  Future<void> seedCustomer(String id, {String? businessId}) async {
    final biz = businessId ?? await const LocalWorkspace().ensureBusinessId(db);
    await db
        .into(db.customersTable)
        .insert(
          CustomersTableCompanion.insert(id: id, businessId: biz, name: id),
        );
  }

  Future<void> insertRawOrder({
    required String id,
    required String customerId,
    String? businessId,
    DateTime? orderDate,
    int totalQuantity = 1,
    double subtotal = 1000,
    double totalAmount = 1000,
    String status = 'confirmed',
    required String items,
  }) async {
    final biz = businessId ?? await const LocalWorkspace().ensureBusinessId(db);
    await db
        .into(db.ordersTable)
        .insert(
          OrdersTableCompanion.insert(
            id: id,
            businessId: biz,
            customerId: customerId,
            orderDate: orderDate ?? DateTime(2026, 7, 1),
            totalQuantity: totalQuantity,
            subtotal: subtotal,
            totalAmount: totalAmount,
            status: status,
            items: items,
          ),
        );
  }

  test('a new order list starts EMPTY (no sample seeded)', () async {
    expect(await DriftOrderRepository(db).loadAll(), isEmpty);
  });

  test('round-trip: fields + line items survive; revenue is derived', () async {
    await seedCustomer('c1');
    final repo = DriftOrderRepository(db);
    await repo.upsert(
      order(
        'o1',
        orderNumber: 'DH-2026-0142',
        status: OrderStatus.delivered,
        items: const [
          OrderItem(
            productName: 'Tai nghe',
            category: 'Electronics',
            quantity: 1,
            unitPrice: 420000,
          ),
          OrderItem(
            productName: 'Áo thun',
            category: 'Fashion',
            quantity: 3,
            unitPrice: 120000,
          ),
        ],
      ),
    );

    final o = (await DriftOrderRepository(db).loadAll()).single;
    expect(o.id, 'o1');
    expect(o.customerId, 'c1');
    expect(o.orderNumber, 'DH-2026-0142');
    expect(o.status, OrderStatus.delivered);
    expect(o.items, hasLength(2));
    expect(o.items.first.productName, 'Tai nghe');
    expect(o.items[1].quantity, 3);
    // Revenue derived from the lines: 420000 + 3×120000.
    expect(o.totalAmount, 780000);
    expect(o.totalQuantity, 4);
    expect(o.categories, {'Electronics', 'Fashion'});
  });

  test('the structured revenue columns are denormalised for query', () async {
    await seedCustomer('c1');
    await DriftOrderRepository(db).upsert(
      order(
        'o1',
        items: const [
          OrderItem(
            productName: 'X',
            category: 'Home',
            quantity: 2,
            unitPrice: 50000,
          ),
        ],
      ),
    );
    // Reports can SUM totalAmount without decoding JSON — the column mirrors the
    // line total written at upsert time.
    final row = await (db.select(
      db.ordersTable,
    )..where((t) => t.id.equals('o1'))).getSingle();
    expect(row.totalAmount, 100000);
    expect(row.totalQuantity, 2);
    expect(row.subtotal, 100000);
  });

  test('loadForCustomer filters to one customer, newest first', () async {
    await seedCustomer('c1');
    await seedCustomer('c2');
    final repo = DriftOrderRepository(db);
    await repo.upsert(
      order('o1', customerId: 'c1', date: DateTime(2026, 5, 1)),
    );
    await repo.upsert(
      order('o2', customerId: 'c1', date: DateTime(2026, 7, 1)),
    );
    await repo.upsert(
      order('o3', customerId: 'c2', date: DateTime(2026, 6, 1)),
    );

    final c1 = await repo.loadForCustomer('c1');
    expect(c1.map((o) => o.id), ['o2', 'o1']); // newest first
    expect((await repo.loadForCustomer('c2')).single.id, 'o3');
  });

  test('upsert replaces the order with the same id (edit)', () async {
    await seedCustomer('c1');
    final repo = DriftOrderRepository(db);
    await repo.upsert(order('o1', status: OrderStatus.pending));
    await repo.upsert(order('o1', status: OrderStatus.delivered));
    final all = await repo.loadAll();
    expect(all, hasLength(1));
    expect(all.single.status, OrderStatus.delivered);
  });

  test('loadAll returns newest orderDate first', () async {
    await seedCustomer('c1');
    final repo = DriftOrderRepository(db);
    await repo.upsert(order('o1', date: DateTime(2026, 1, 1)));
    await repo.upsert(order('o2', date: DateTime(2026, 7, 1)));
    await repo.upsert(order('o3', date: DateTime(2026, 4, 1)));
    expect((await repo.loadAll()).map((o) => o.id), ['o2', 'o3', 'o1']);
  });

  test('corrupt / empty items JSON never breaks a load', () async {
    await seedCustomer('c1');
    await insertRawOrder(id: 'bad', customerId: 'c1', items: '}{ not json');
    await insertRawOrder(id: 'empty', customerId: 'c1', items: '');
    await insertRawOrder(id: 'notarray', customerId: 'c1', items: '{"a":1}');

    final all = await DriftOrderRepository(db).loadAll();
    expect(all, hasLength(3));
    // Every order loads; corrupt/empty/non-array items degrade to [].
    for (final o in all) {
      expect(o.items, isEmpty);
      expect(o.totalAmount, 0);
    }
  });

  test('items decode drops malformed elements, keeps valid ones', () async {
    await seedCustomer('c1');
    await insertRawOrder(
      id: 'mixed',
      customerId: 'c1',
      items:
          '[{"productName":"OK","category":"Home","quantity":2,"unitPrice":5000},'
          '42,null,{"productName":"NoPrice","category":"Home","quantity":1}]',
    );
    final o = (await DriftOrderRepository(db).loadAll()).single;
    // The scalar/null are dropped; the price-less line reads unitPrice 0.
    expect(o.items.map((i) => i.productName), ['OK', 'NoPrice']);
    expect(o.items.first.lineTotal, 10000);
    expect(o.items[1].unitPrice, 0);
  });

  test(
    'business isolation: loadAll only returns the local business rows',
    () async {
      final localBusiness = await const LocalWorkspace().ensureBusinessId(db);
      await db
          .into(db.usersTable)
          .insert(
            UsersTableCompanion.insert(
              id: 'other-owner',
              email: 'o@x.app',
              name: 'Khác',
            ),
          );
      await db
          .into(db.businessesTable)
          .insert(
            BusinessesTableCompanion.insert(
              id: 'other-business',
              ownerId: 'other-owner',
              name: 'Khác',
            ),
          );
      await seedCustomer('mine-c', businessId: localBusiness);
      await seedCustomer('their-c', businessId: 'other-business');

      await insertRawOrder(
        id: 'mine',
        customerId: 'mine-c',
        businessId: localBusiness,
        items: '[]',
      );
      await insertRawOrder(
        id: 'theirs',
        customerId: 'their-c',
        businessId: 'other-business',
        items: '[]',
      );

      final mine = await DriftOrderRepository(db).loadAll();
      expect(mine.map((o) => o.id), ['mine']);
    },
  );

  group('SampleOrderRepository (demo, read-only)', () {
    test('returns the sample orders and never persists', () async {
      const repo = SampleOrderRepository();
      final before = (await repo.loadAll()).length;
      expect(before, greaterThan(0));
      await repo.upsert(order('o1'));
      expect((await repo.loadAll()).length, before);
    });

    test('loadForCustomer filters the sample orders', () async {
      const repo = SampleOrderRepository();
      final c01 = await repo.loadForCustomer('c01');
      expect(c01, isNotEmpty);
      expect(c01.every((o) => o.customerId == 'c01'), isTrue);
    });

    test('the Drift list is NOT seeded with the sample orders', () async {
      expect(await DriftOrderRepository(db).loadAll(), isEmpty);
      expect(
        (await const SampleOrderRepository().loadAll()).length,
        greaterThan(0),
      );
    });
  });

  group('InMemoryOrderRepository (tests)', () {
    test('upserts, replaces and filters by customer', () async {
      final repo = InMemoryOrderRepository([order('o1', customerId: 'c1')]);
      await repo.upsert(order('o2', customerId: 'c2'));
      await repo.upsert(order('o1', customerId: 'c1', orderNumber: 'edited'));
      expect((await repo.loadAll()), hasLength(2));
      expect((await repo.loadForCustomer('c1')).single.orderNumber, 'edited');
    });
  });

  test(
    'line snapshot (productId/sku/unit + sold price) round-trips via Drift',
    () async {
      await seedCustomer('c1');
      final repo = DriftOrderRepository(db);
      await repo.upsert(
        order(
          'o1',
          items: const [
            OrderItem(
              productId: 'p1',
              productName: 'Quạt mini',
              sku: 'SKU-EL-001',
              category: 'Electronics',
              unit: 'cái',
              quantity: 2,
              unitPrice: 79000, // sold price, below the inventory default
            ),
          ],
        ),
      );

      final line = (await DriftOrderRepository(
        db,
      ).loadAll()).single.items.single;
      expect(line.productId, 'p1');
      expect(line.sku, 'SKU-EL-001');
      expect(line.unit, 'cái');
      expect(line.unitPrice, 79000); // immutable sold-price snapshot
    },
  );

  test('legacy items blob without snapshot fields still loads', () async {
    await seedCustomer('c1');
    // A pre-WTM-126 line: no productId/sku/unit keys.
    await insertRawOrder(
      id: 'legacy',
      customerId: 'c1',
      items:
          '[{"productName":"Old","category":"Home","quantity":1,"unitPrice":5000}]',
    );
    final line = (await DriftOrderRepository(db).loadAll()).single.items.single;
    expect(line.productName, 'Old');
    expect(line.unitPrice, 5000);
    // New snapshot fields default to empty — no crash.
    expect(line.productId, '');
    expect(line.sku, '');
    expect(line.unit, '');
  });

  group('order items JSON codec', () {
    test('round-trips the full snapshot through encode/decode', () {
      const items = [
        OrderItem(
          productId: 'p9',
          productName: 'A',
          sku: 'SKU-A',
          category: 'Home',
          unit: 'hộp',
          quantity: 2,
          unitPrice: 1500,
        ),
      ];
      final decoded = decodeOrderItems(encodeOrderItems(items));
      expect(decoded, items);
    });

    test('OrderItem.fromProduct snapshots the product + sold price', () {
      final product = Product(
        id: 'p1',
        sku: 'SKU-EL-001',
        name: 'Quạt mini',
        category: 'Electronics',
        quantity: 10,
        pricePerUnit: 89000,
        reorderLevel: 2,
        updatedAt: DateTime(2026, 7, 1),
      );
      final line = OrderItem.fromProduct(
        product,
        quantity: 3,
        soldPrice: 80000,
      );
      expect(line.productId, 'p1');
      expect(line.productName, 'Quạt mini');
      expect(line.sku, 'SKU-EL-001');
      expect(line.category, 'Electronics');
      expect(line.quantity, 3);
      expect(line.unitPrice, 80000); // sold price overrides the default
      // Default sold price falls back to the inventory price.
      expect(OrderItem.fromProduct(product, quantity: 1).unitPrice, 89000);
    });

    test('decode is tolerant of null', () {
      expect(decodeOrderItems(null), isEmpty);
    });
  });
}
