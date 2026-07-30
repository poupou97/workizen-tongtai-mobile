import '../consumer/customer.dart';
import '../consumer/customer_directory_service.dart' show kSampleCustomers;
import '../consumer/customer_repository.dart';
import '../finance/finance_repository.dart';
import '../finance/finance_transaction.dart' show kSampleTransactions;
import '../inventory/product_inventory_service.dart' show kSampleProducts;
import '../inventory/product_repository.dart';
import '../journey/business_goal.dart' show kSampleBusinessGoals;
import '../journey/business_goal_repository.dart';
import '../orders/order.dart' show kSampleCustomerOrders;
import '../orders/order_repository.dart';

/// Every seeded sample record carries this id prefix (WTM-144/ADR-TON-014) —
/// user-created records use UUIDs, so the prefix can never collide and
/// [SampleDataSeeder.removeAll] can delete samples without touching user data.
const String kSampleIdPrefix = 'sample-';

/// Seeds the built-in sample fixtures INTO the production repositories
/// (WTM-144, P0 Regression Audit §1 → ADR-TON-014).
///
/// This replaces the old parallel demo state: after seeding, **every screen —
/// Home, Inventory, Consumer, Orders, Journey, Finance, Reports, Opportunity,
/// Timeline, AI — reads the exact same repositories and the same
/// BusinessContext.** Sample rows are ordinary rows: the user can open, edit
/// and delete them; [removeAll] wipes only the `sample-` prefixed ids.
///
/// [seed] is idempotent: it first removes existing sample rows, then inserts
/// the fixtures fresh (so re-seeding never duplicates, and finance — an
/// insert-only repository — stays clean).
class SampleDataSeeder {
  const SampleDataSeeder({
    required this.customers,
    required this.products,
    required this.orders,
    required this.goals,
    required this.finance,
  });

  final CustomerRepository customers;
  final ProductRepository products;
  final OrderRepository orders;
  final BusinessGoalRepository goals;
  final FinanceRepository finance;

  static String _sampleId(String originalId) => '$kSampleIdPrefix$originalId';

  /// Seeds all fixtures with `sample-` ids (idempotent — see class doc).
  Future<void> seed() async {
    await removeAll();

    final customerIds = <String>{for (final c in kSampleCustomers) c.id};
    for (final Customer c in kSampleCustomers) {
      await customers.upsert(c.withId(_sampleId(c.id)));
    }
    for (final p in kSampleProducts) {
      await products.upsert(p.withId(_sampleId(p.id)));
    }
    for (final o in kSampleCustomerOrders) {
      await orders.upsert(
        o.withIds(
          newId: _sampleId(o.id),
          // Rewire to the remapped sample customer when the order pointed at a
          // sample fixture; foreign links stay consistent inside the seed set.
          newCustomerId: customerIds.contains(o.customerId)
              ? _sampleId(o.customerId)
              : null,
        ),
      );
    }
    for (final g in kSampleBusinessGoals) {
      await goals.upsert(g.withId(_sampleId(g.id)));
    }
    for (final t in kSampleTransactions) {
      await finance.add(t.withId(_sampleId(t.id)));
    }
  }

  /// Removes every sample record across all repositories. User data (UUID ids)
  /// is untouched — including sample rows the user has edited (same id).
  ///
  /// Orders go FIRST: on the real SQLite database `orders_table.customer_id`
  /// enforces a foreign key into `customers_table` (PRAGMA foreign_keys=ON),
  /// so deleting customers while their sample orders still exist throws
  /// SqliteException 787. Found by `p0/drift_restart_test.dart` (WTM-146 §3) —
  /// the in-memory repositories used before never enforced the constraint.
  Future<void> removeAll() async {
    await orders.deleteByIdPrefix(kSampleIdPrefix);
    await customers.deleteByIdPrefix(kSampleIdPrefix);
    await products.deleteByIdPrefix(kSampleIdPrefix);
    await goals.deleteByIdPrefix(kSampleIdPrefix);
    await finance.deleteByIdPrefix(kSampleIdPrefix);
  }

  /// Whether any sample record is currently present (drives the Home banner
  /// and the More "remove samples" affordance).
  Future<bool> hasSamples() async {
    bool anySample(Iterable<dynamic> rows) =>
        rows.any((r) => (r.id as String).startsWith(kSampleIdPrefix));
    if (anySample(await customers.loadAll())) return true;
    if (anySample(await products.loadAll())) return true;
    if (anySample(await orders.loadAll())) return true;
    if (anySample(await goals.loadAll())) return true;
    return anySample(await finance.loadAll());
  }
}
