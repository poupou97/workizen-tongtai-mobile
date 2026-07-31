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
import 'package:tongtai/features/tongtai/producer/supplier_favorites_store.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_context_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_finance_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_search_provider.dart';
import 'package:tongtai/features/tongtai/sample/historical_data_generator.dart';
import 'package:tongtai/features/tongtai/sample/sample_data_seeder.dart';

/// Epic WTM-167 (ADR-TON-019 draft) — the fixed benchmark for Capability
/// Context hydration.
///
/// **The contract of this file is that the numbers it asserts are portable.**
/// Query counts are identical on a laptop and a phone, so they can be locked
/// in. Durations are printed as evidence for the Epic's comparison table but
/// never asserted as absolutes — a millisecond measured here is a desktop
/// benchmark, and desktop benchmarks must not become claims about a device
/// (Testing Bible P-16). Device milliseconds come from `StartupTrace` on a
/// release build; see `docs/04-DELIVERY/reports/WTM-166-cold-start.md`.
///
/// The volumes are the ones the Founder specified — 3 · 12 · 24 · 60 months —
/// because the whole point is what happens to a business that has been running
/// for five years, not to a fresh install.
void main() {
  /// The load a cold start performs today, per capability, with the count of
  /// repository reads each one causes. Locked in as the baseline every
  /// candidate direction in ADR-TON-019 has to beat.
  const baselineReads = {
    'customers': 4,
    'products': 3,
    'orders': 5,
    'goals': 4,
    'finance': 2,
  };

  for (final months in [3, 12, 24, 60]) {
    test('hydration baseline @ $months months of trading', () async {
      final tempDir = await Directory.systemTemp.createTemp('tongtai-bench-');
      final db = AppDatabase.forExecutor(
        NativeDatabase(File('${tempDir.path}/t.db')),
      );
      final counts = _Counts();
      final container = ProviderContainer(
        overrides: [
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
          tongtaiSearchFavoritesStoreProvider.overrideWithValue(
            DriftSupplierFavoritesStore(db),
          ),
        ],
      );

      addTearDown(() async {
        container.dispose();
        await db.close();
        if (tempDir.existsSync()) await tempDir.delete(recursive: true);
      });

      await HistoricalDataSeeder(
        sampleSeeder: SampleDataSeeder(
          customers: DriftCustomerRepository(db),
          products: DriftProductRepository(db),
          orders: DriftOrderRepository(db),
          goals: DriftBusinessGoalRepository(db),
          finance: DriftFinanceRepository(db),
        ),
      ).seed(HistoricalDataSpec(months: months));

      final rows = {
        'orders': (await DriftOrderRepository(db).loadAll()).length,
        'customers': (await DriftCustomerRepository(db).loadAll()).length,
        'finance': (await DriftFinanceRepository(db).loadAll()).length,
        'products': (await DriftProductRepository(db).loadAll()).length,
      };
      counts.reset();

      // The floor: read every table the hydration touches, exactly once.
      // Splitting this out matters — if hydration grows faster than reading
      // does, the expensive part is aggregation, and no amount of caching
      // reads will fix it. ADR-TON-019 picks a direction from this split.
      final readsOnly = Stopwatch()..start();
      await DriftCustomerRepository(db).loadAll();
      await DriftProductRepository(db).loadAll();
      await DriftOrderRepository(db).loadAll();
      await DriftBusinessGoalRepository(db).loadAll();
      await DriftFinanceRepository(db).loadAll();
      readsOnly.stop();

      // Exactly what the shell triggers on a cold start: the IndexedStack
      // builds all four data tabs, so all four hydrate together.
      final hydration = Stopwatch()..start();
      await Future.wait([
        Future(() async {
          await container.read(businessContextServiceProvider).load();
          await container.read(businessGoalRepositoryProvider).loadAll();
          await container.read(tongtaiSearchFavoritesStoreProvider).loadAll();
          await container.read(generatedOpportunitiesProvider.future);
        }),
        Future(() async {
          await container.read(tongtaiSearchFavoritesStoreProvider).loadAll();
          await container.read(generatedOpportunitiesProvider.future);
        }),
        container.read(productRepositoryProvider).loadAll(),
        container.read(customerRepositoryProvider).loadAll(),
      ]);
      hydration.stop();

      // ignore: avoid_print
      print(
        'TT-BENCH months=$months rows=${rows['orders']}o/${rows['customers']}c/'
        '${rows['finance']}f/${rows['products']}p '
        'reads=${counts.snapshot()} '
        'oneReadOfEach=${readsOnly.elapsedMilliseconds}ms(host) '
        'hydration=${hydration.elapsedMilliseconds}ms(host)',
      );

      expect(
        counts.snapshot(),
        baselineReads,
        reason:
            'Read counts must not depend on how much data a business has — '
            'they are a property of the wiring. If this differs at one volume '
            'and not another, something is reading conditionally and the Epic '
            'WTM-167 comparison table is measuring the wrong thing.',
      );
    }, timeout: const Timeout(Duration(minutes: 3)));
  }
}

class _Counts {
  final Map<String, int> _by = {};
  void hit(String table) => _by.update(table, (n) => n + 1, ifAbsent: () => 1);
  void reset() => _by.clear();
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
