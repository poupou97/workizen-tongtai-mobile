import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_context_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_finance_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_search_provider.dart';

/// WTM-166 — how many times one cold start reads each table.
///
/// This test deliberately measures **counts, not milliseconds.** A count is the
/// same on a laptop and on a phone, so it is a fact we are allowed to act on;
/// a millisecond here would be a desktop benchmark dressed up as a device
/// claim, and the device numbers live in the report instead.
///
/// Why it matters: on the measured device the whole hydration finished in ~5ms
/// because that database was nearly empty. Read amplification is invisible at
/// six rows and decisive at six thousand — so the guard has to be the shape of
/// the work, not the clock.
void main() {
  late Directory tempDir;
  late AppDatabase db;
  late _Counts counts;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tongtai-coldstart-');
    db = AppDatabase.forExecutor(NativeDatabase(File('${tempDir.path}/t.db')));
    counts = _Counts();
    container = ProviderContainer(
      overrides: [
        tongtaiDatabaseProvider.overrideWithValue(db),
        customerRepositoryProvider.overrideWithValue(
          _CountingCustomers(DriftCustomerRepository(db), counts),
        ),
        productRepositoryProvider.overrideWithValue(
          _CountingProducts(DriftProductRepository(db), counts),
        ),
        orderRepositoryProvider.overrideWithValue(
          _CountingOrders(DriftOrderRepository(db), counts),
        ),
        businessGoalRepositoryProvider.overrideWithValue(
          _CountingGoals(DriftBusinessGoalRepository(db), counts),
        ),
        financeRepositoryProvider.overrideWithValue(
          _CountingFinance(DriftFinanceRepository(db), counts),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  /// Exactly what the app does when it cold-starts on Home: the shell builds
  /// all four data tabs into an IndexedStack, so all four hydrate at once.
  Future<void> coldStart() async {
    await Future.wait([
      // Home
      Future(() async {
        await container.read(businessContextServiceProvider).load();
        await container.read(businessGoalRepositoryProvider).loadAll();
        await container.read(tongtaiSearchFavoritesStoreProvider).loadAll();
        await container.read(generatedOpportunitiesProvider.future);
      }),
      // Producer
      Future(() async {
        await container.read(tongtaiSearchFavoritesStoreProvider).loadAll();
        await container.read(generatedOpportunitiesProvider.future);
      }),
      // Inventory
      container.read(productRepositoryProvider).loadAll(),
      // Consumer
      container.read(customerRepositoryProvider).loadAll(),
    ]);
  }

  test(
    'one cold start does not re-read the same table many times over',
    () async {
      await container.read(customerRepositoryProvider).upsertAll([
        for (var i = 0; i < 20; i++)
          Customer(
            id: 'c$i',
            name: 'Khách $i',
            phone: '090$i',
            location: 'Hà Nội',
            orderCount: 0,
            totalSpent: 0,
            lastPurchaseDate: null,
          ),
      ]);
      await container.read(productRepositoryProvider).upsertAll([
        for (var i = 0; i < 20; i++)
          Product(
            id: 'p$i',
            sku: 'SKU-$i',
            name: 'Sản phẩm $i',
            category: 'Chung',
            quantity: 10,
            pricePerUnit: 10000,
            reorderLevel: 2,
            updatedAt: DateTime(2026, 7, 20),
          ),
      ]);

      await coldStart();

      // The numbers this locks in are the ones the WTM-166 report is based on.
      // If a future change makes any of them grow, the cost lands on the seller
      // with the biggest business — the one least able to notice why.
      expect(
        counts.snapshot(),
        {'customers': 4, 'finance': 2, 'goals': 4, 'orders': 5, 'products': 3},
        reason:
            'These are the numbers WTM-166 measured, not the numbers it wants. '
            'They are locked in so the shape of a cold start cannot get worse '
            'unnoticed — a regression here is invisible on a test device with '
            'twenty rows and expensive for the seller with ten thousand orders.',
      );
    },
  );
}

class _Counts {
  final Map<String, int> _by = {};
  void hit(String table) => _by.update(table, (n) => n + 1, ifAbsent: () => 1);
  Map<String, int> snapshot() => Map.fromEntries(
    _by.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
}

class _CountingCustomers implements CustomerRepository {
  _CountingCustomers(this._inner, this._counts);
  final CustomerRepository _inner;
  final _Counts _counts;

  @override
  Future<List<Customer>> loadAll() {
    _counts.hit('customers');
    return _inner.loadAll();
  }

  @override
  Future<void> upsert(Customer customer) => _inner.upsert(customer);
  @override
  Future<void> upsertAll(Iterable<Customer> customers) =>
      _inner.upsertAll(customers);
  @override
  Future<void> deleteByIdPrefix(String prefix, {Set<String> keep = const {}}) =>
      _inner.deleteByIdPrefix(prefix, keep: keep);
  @override
  Future<void> deleteAll() => _inner.deleteAll();
}

class _CountingProducts implements ProductRepository {
  _CountingProducts(this._inner, this._counts);
  final ProductRepository _inner;
  final _Counts _counts;

  @override
  Future<List<Product>> loadAll() {
    _counts.hit('products');
    return _inner.loadAll();
  }

  @override
  Future<void> upsert(Product product) => _inner.upsert(product);
  @override
  Future<void> upsertAll(Iterable<Product> products) =>
      _inner.upsertAll(products);
  @override
  Future<void> deleteByIdPrefix(String prefix) =>
      _inner.deleteByIdPrefix(prefix);
  @override
  Future<void> deleteAll() => _inner.deleteAll();
}

class _CountingOrders implements OrderRepository {
  _CountingOrders(this._inner, this._counts);
  final OrderRepository _inner;
  final _Counts _counts;

  @override
  Future<List<CustomerOrder>> loadAll() {
    _counts.hit('orders');
    return _inner.loadAll();
  }

  @override
  Future<List<CustomerOrder>> loadForCustomer(String customerId) =>
      _inner.loadForCustomer(customerId);
  @override
  Future<void> upsert(CustomerOrder order) => _inner.upsert(order);
  @override
  Future<void> upsertAll(Iterable<CustomerOrder> orders) =>
      _inner.upsertAll(orders);
  @override
  Future<void> deleteByIdPrefix(String prefix) =>
      _inner.deleteByIdPrefix(prefix);
  @override
  Future<void> deleteAll() => _inner.deleteAll();
}

class _CountingGoals implements BusinessGoalRepository {
  _CountingGoals(this._inner, this._counts);
  final BusinessGoalRepository _inner;
  final _Counts _counts;

  @override
  Future<List<BusinessGoal>> loadAll() {
    _counts.hit('goals');
    return _inner.loadAll();
  }

  @override
  Future<void> upsert(BusinessGoal goal) => _inner.upsert(goal);
  @override
  Future<void> upsertAll(Iterable<BusinessGoal> goals) =>
      _inner.upsertAll(goals);
  @override
  Future<void> deleteByIdPrefix(String prefix) =>
      _inner.deleteByIdPrefix(prefix);
  @override
  Future<void> deleteAll() => _inner.deleteAll();
}

class _CountingFinance implements FinanceRepository {
  _CountingFinance(this._inner, this._counts);
  final FinanceRepository _inner;
  final _Counts _counts;

  @override
  Future<List<FinanceTransaction>> loadAll() {
    _counts.hit('finance');
    return _inner.loadAll();
  }

  @override
  Future<void> add(FinanceTransaction transaction) => _inner.add(transaction);
  @override
  Future<void> addAll(Iterable<FinanceTransaction> transactions) =>
      _inner.addAll(transactions);
  @override
  Future<void> deleteByIdPrefix(String prefix) =>
      _inner.deleteByIdPrefix(prefix);
  @override
  Future<void> deleteAll() => _inner.deleteAll();
}
