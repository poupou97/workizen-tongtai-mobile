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
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_context_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_finance_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_metrics_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/sample/historical_data_generator.dart';
import 'package:tongtai/features/tongtai/sample/sample_data_seeder.dart';

/// Epic WTM-167 (ADR-TON-019 · ADR-TON-025 draft) — the **aggregation** half of
/// the Capability Context performance baseline.
///
/// `capability_hydration_benchmark_test` locks *how many times a whole cold
/// start reads each table*. This file locks the complementary fact the Epic
/// actually turns on: **for one hydration, how many times does each individual
/// Capability Context re-read each table** — the fan-out. Summing the `orders`
/// column across the capabilities that read it is exactly ADR-TON-019's "who
/// reads `orders`" table, now a locked number instead of prose. That is the
/// evidence every candidate direction in ADR-TON-025 is scored against.
///
/// Like every number here it is a **count, not a millisecond** (Testing Bible
/// P-16): a fan-out is identical on a laptop and a phone, so it can be locked
/// in; a duration cannot. The volumes are the Founder's — 3 · 12 · 24 · 60
/// months — and the whole point is that the fan-out is **the same at all four**.
/// A fan-out that grew with data would mean the count is an artifact of the
/// dataset, not a fact about the wiring, and the Epic's comparison would be
/// measuring the wrong thing.
void main() {
  /// One hydration's read fan-out, per capability. **Recorded current state,
  /// not desired state** — a ratchet: it turns red the day a capability starts
  /// reading a table it did not before, which is the regression ADR-TON-019
  /// exists to make visible. Because it is one constant asserted at every
  /// volume, locking it *also* proves the fan-out does not depend on how much
  /// data a business has.
  const expectedFanOut = <String, Map<String, int>>{
    'metrics': {'customers': 1, 'orders': 1},
    'customer': {'customers': 1},
    'order': {'orders': 1},
    'inventory': {'products': 1},
    'opportunity': {'customers': 1, 'goals': 1, 'orders': 1, 'products': 1},
    'journey': {'goals': 1, 'orders': 1},
    'finance': {'finance': 1, 'orders': 1},
    'timeline': {'finance': 1, 'goals': 1, 'orders': 1},
  };

  for (final months in [3, 12, 24, 60]) {
    test('aggregation fan-out is a wiring fact @ $months months of trading', () async {
      final tempDir = await Directory.systemTemp.createTemp('tongtai-agg-');
      final db = AppDatabase.forExecutor(
        NativeDatabase(File('${tempDir.path}/t.db')),
      );
      addTearDown(() async {
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

      // Measure each capability in isolation — a fresh container per capability
      // so no FutureProvider caching leaks one capability's reads into another.
      final fanOut = <String, Map<String, int>>{};
      for (final entry in _capabilities.entries) {
        fanOut[entry.key] = await _measure(db, entry.value);
      }

      // The whole BusinessContext hydration must read **exactly the union** of
      // what the parts read on their own. If it differs, hydration performs a
      // read no per-capability baseline can see — and the fan-out table below
      // would be lying by omission.
      final hydrationTotal = await _measure(db, (c) async {
        await c.read(businessContextServiceProvider).load();
      });
      final summedParts = <String, int>{};
      for (final f in fanOut.values) {
        f.forEach((k, v) => summedParts[k] = (summedParts[k] ?? 0) + v);
      }
      final summedSorted = _sorted(summedParts);

      // ignore: avoid_print
      print(
        'TT-AGG months=$months '
        'fanOut=$fanOut '
        'hydrationTotal=$hydrationTotal summedParts=$summedSorted',
      );

      expect(
        hydrationTotal,
        summedSorted,
        reason:
            'One BusinessContext hydration must read exactly the union of what '
            'each capability reads alone. A difference means a hidden read the '
            'per-capability baseline cannot account for.',
      );

      expect(
        fanOut,
        expectedFanOut,
        reason:
            'Per-capability aggregation fan-out is a property of the wiring, '
            'not of the data — so it is identical at 3 and 60 months. If it '
            'changed, a capability started reading a table it did not before; '
            'that is precisely the read amplification Epic WTM-167 / ADR-TON-019 '
            'exists to keep visible before a seller with a big business pays '
            'for it.',
      );
    }, timeout: const Timeout(Duration(minutes: 3)));
  }
}

/// The capabilities `BusinessContextService.load()` composes, each exercised in
/// isolation. `metrics` is the KPI source of truth; the other seven are the
/// Capability Context providers (WTM-131).
final _capabilities = <String, Future<void> Function(ProviderContainer)>{
  'metrics': (c) async {
    await c.read(businessMetricsServiceProvider).load();
  },
  'customer': (c) async {
    await c.read(customerContextProvider).load();
  },
  'order': (c) async {
    await c.read(orderContextProvider).load();
  },
  'inventory': (c) async {
    await c.read(inventoryContextProvider).load();
  },
  'opportunity': (c) async {
    await c.read(opportunityContextProvider).load();
  },
  'journey': (c) async {
    await c.read(journeyContextProvider).load();
  },
  'finance': (c) async {
    await c.read(financeContextProvider).load();
  },
  'timeline': (c) async {
    await c.read(timelineContextProvider).load();
  },
};

/// Runs [exercise] against a container whose five repositories are counting
/// wrappers over the real Drift repositories, and returns the read fan-out.
/// A fresh container per call keeps FutureProvider caching from bleeding one
/// measurement into the next.
Future<Map<String, int>> _measure(
  AppDatabase db,
  Future<void> Function(ProviderContainer) exercise,
) async {
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
    ],
  );
  try {
    await exercise(container);
  } finally {
    container.dispose();
  }
  return counts.snapshot();
}

Map<String, int> _sorted(Map<String, int> m) =>
    Map.fromEntries(m.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));

class _Counts {
  final Map<String, int> _by = {};
  void hit(String table) => _by.update(table, (n) => n + 1, ifAbsent: () => 1);
  Map<String, int> snapshot() => _sorted(_by);
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
