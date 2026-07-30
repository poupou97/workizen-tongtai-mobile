import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../core/domain_snapshot.dart';
import '../core/local_workspace.dart';
import 'customer.dart';
import 'customer_directory_service.dart' show kSampleCustomers;

/// Decides the source of CRM/customer data (WTM-123) — Drift (real, persistent),
/// Sample (demo) or in-memory (tests). The controller depends on this seam, not
/// on Drift; the UI never knows which source is behind it. Same pattern as
/// [FinanceRepository] (WTM-120) and `ProductRepository` (WTM-121).
abstract class CustomerRepository {
  Future<List<Customer>> loadAll();

  /// Insert a new customer or replace the one with the same id.
  Future<void> upsert(Customer customer);

  /// Deletes every row whose id starts with [prefix] — the sample-data
  /// lifecycle hook (WTM-144/ADR-TON-014): sample records carry the
  /// `sample-` id prefix so they can be removed without touching user data.
  ///
  /// Ids in [keep] are spared even when they match [prefix]. This exists for
  /// exactly one case, and it is a data-integrity one: `orders_table
  /// .customer_id` is a hard foreign key with **no** cascade, so a sample
  /// customer the user has since written their own order against cannot be
  /// deleted (SqliteException 787) — and must not be, because the order is
  /// user data (WTM-162).
  Future<void> deleteByIdPrefix(String prefix, {Set<String> keep});
}

/// Real, persistent customer directory for the local business (WTM-123).
///
/// **Structured columns + versioned domain snapshot** (ADR-TON-009, option B):
/// fields that get queried/reported/indexed live in structured columns — the
/// source of truth for those (promoted) fields: name/email/phone/city(location)/
/// orderCount/totalSpent/lastOrderDate, plus `segments` as its own JSON-array
/// column. Extended fields not yet promoted (tags, addresses, notes) ride in
/// `domain_snapshot` as versioned JSON. Edit history is not persisted (it is
/// regenerable session state).
///
/// **User Data First** (Founder, 2026-07-24): nothing is seeded — a new user
/// starts with an empty directory. Rows are scoped to [LocalWorkspace]'s
/// business, so one business never sees another's customers.
class DriftCustomerRepository implements CustomerRepository {
  DriftCustomerRepository(this._db, {this._workspace = const LocalWorkspace()});

  final AppDatabase _db;
  final LocalWorkspace _workspace;

  /// Current snapshot version — bump + migrate the reader when the JSON shape
  /// changes.
  static const int _snapshotVersion = 1;

  @override
  Future<List<Customer>> loadAll() async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.customersTable)
              ..where((t) => t.businessId.equals(businessId))
              ..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .get();
    return rows.map(_toCustomer).toList();
  }

  @override
  Future<void> upsert(Customer c) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await _db
        .into(_db.customersTable)
        .insertOnConflictUpdate(
          CustomersTableCompanion.insert(
            id: c.id,
            businessId: businessId,
            name: c.name,
            email: Value(c.email.isEmpty ? null : c.email),
            phone: Value(c.phone.isEmpty ? null : c.phone),
            city: Value(c.location.isEmpty ? null : c.location),
            segments: Value(encodeJsonStringList(c.segments)),
            orderCount: Value(c.orderCount),
            totalSpent: Value(c.totalSpent),
            lastOrderDate: Value(c.lastPurchaseDate),
            domainSnapshot: Value(
              encodeDomainSnapshot({
                'tags': c.tags,
                'addresses': c.addresses,
                'notes': c.notes,
              }, version: _snapshotVersion),
            ),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Customer _toCustomer(CustomersTableData row) {
    // Structured columns are the source of truth for promoted fields; the
    // snapshot only carries extended, not-yet-promoted fields.
    final snapshot = decodeDomainSnapshot(row.domainSnapshot);
    return Customer(
      id: row.id,
      name: row.name,
      phone: row.phone ?? '',
      location: row.city ?? '',
      orderCount: row.orderCount ?? 0,
      totalSpent: row.totalSpent ?? 0,
      lastPurchaseDate: row.lastOrderDate,
      email: row.email ?? '',
      segments: decodeJsonStringList(row.segments),
      addresses: snapshotStringList(snapshot, 'addresses'),
      tags: snapshotStringList(snapshot, 'tags'),
      notes: snapshotString(snapshot, 'notes'),
      // Audit history is not persisted (regenerable session state).
    );
  }

  @override
  Future<void> deleteByIdPrefix(
    String prefix, {
    Set<String> keep = const <String>{},
  }) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await (_db.delete(_db.customersTable)..where((t) {
          final match = t.businessId.equals(businessId) & t.id.like('$prefix%');
          return keep.isEmpty
              ? match
              : match & t.id.isNotIn(keep.toList(growable: false));
        }))
        .go();
  }
}

/// Demo / Preview source (WTM-123): the built-in sample directory, **read-only**
/// — used only in Demo Mode, never written to the user's database.
class SampleCustomerRepository implements CustomerRepository {
  const SampleCustomerRepository();

  @override
  Future<List<Customer>> loadAll() async => List.of(kSampleCustomers);

  @override
  Future<void> upsert(Customer customer) async {
    // Demo data is read-only — do not persist.
  }
  @override
  Future<void> deleteByIdPrefix(
    String prefix, {
    Set<String> keep = const <String>{},
  }) async {
    // Demo fixtures are read-only — nothing to delete.
  }
}

/// In-memory source for tests (mutable, no database).
class InMemoryCustomerRepository implements CustomerRepository {
  InMemoryCustomerRepository([Iterable<Customer> initial = const []])
    : _customers = [...initial];

  final List<Customer> _customers;

  @override
  Future<List<Customer>> loadAll() async => List.of(_customers);

  @override
  Future<void> upsert(Customer customer) async {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index >= 0) {
      _customers[index] = customer;
    } else {
      _customers.add(customer);
    }
  }

  @override
  Future<void> deleteByIdPrefix(
    String prefix, {
    Set<String> keep = const <String>{},
  }) async => _customers.removeWhere(
    (x) => x.id.startsWith(prefix) && !keep.contains(x.id),
  );
}
