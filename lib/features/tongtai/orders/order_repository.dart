import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../core/local_workspace.dart';
import '../core/tongtai_enums.dart';
import 'order.dart';

/// Decides the source of Orders (sales) data (WTM-125) — Drift (real,
/// persistent), Sample (demo) or in-memory (tests). Orders is an **independent
/// capability** (Founder G-2 / ADR-TON-010): it owns the order lifecycle,
/// revenue, order items and (later) payment/invoice/shipment/returns. The UI
/// depends on this seam, never on Drift. Same pattern as `FinanceRepository`
/// (WTM-120) and the other capability repositories.
abstract class OrderRepository {
  Future<List<CustomerOrder>> loadAll();

  /// Orders for one customer, newest first (Consumer purchase history reads
  /// through here rather than a sample service).
  Future<List<CustomerOrder>> loadForCustomer(String customerId);

  /// Insert a new order or replace the one with the same id.
  Future<void> upsert(CustomerOrder order);
}

/// Real, persistent sales orders for the local business (WTM-125).
///
/// Maps `CustomerOrder` onto the existing `orders_table`. Structured columns are
/// the source of truth for the fields Reports/Home aggregate without decoding
/// JSON — `orderDate`, `status`, `totalQuantity`, `subtotal`, `totalAmount` —
/// while the full line detail rides the tolerant `items` JSON array. Revenue is
/// owned here, not recomputed by downstream consumers.
///
/// **User Data First** (Founder): nothing is seeded — a new user has no orders.
/// Rows are scoped to [LocalWorkspace]'s business.
class DriftOrderRepository implements OrderRepository {
  DriftOrderRepository(this._db, {this._workspace = const LocalWorkspace()});

  final AppDatabase _db;
  final LocalWorkspace _workspace;

  @override
  Future<List<CustomerOrder>> loadAll() async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.ordersTable)
              ..where((t) => t.businessId.equals(businessId))
              ..orderBy([(t) => OrderingTerm.desc(t.orderDate)]))
            .get();
    return rows.map(_toOrder).toList();
  }

  @override
  Future<List<CustomerOrder>> loadForCustomer(String customerId) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.ordersTable)
              ..where(
                (t) =>
                    t.businessId.equals(businessId) &
                    t.customerId.equals(customerId),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.orderDate)]))
            .get();
    return rows.map(_toOrder).toList();
  }

  @override
  Future<void> upsert(CustomerOrder o) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await _db
        .into(_db.ordersTable)
        .insertOnConflictUpdate(
          OrdersTableCompanion.insert(
            id: o.id,
            businessId: businessId,
            customerId: o.customerId,
            orderNumber: Value(o.orderNumber),
            orderDate: o.date,
            // Structured revenue columns (SoT for query/report aggregation).
            totalQuantity: o.totalQuantity,
            subtotal: o.totalAmount,
            totalAmount: o.totalAmount,
            status: o.status.name,
            // Full line detail as a tolerant JSON array.
            items: encodeOrderItems(o.items),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  CustomerOrder _toOrder(OrdersTableData row) => CustomerOrder(
    id: row.id,
    customerId: row.customerId,
    orderNumber: row.orderNumber ?? '',
    date: row.orderDate,
    status: OrderStatus.fromStorage(row.status),
    items: decodeOrderItems(row.items),
  );
}

/// Demo / Preview source (WTM-125): the built-in sample orders, **read-only** —
/// used only in Demo Mode, never written to the user's database.
class SampleOrderRepository implements OrderRepository {
  const SampleOrderRepository();

  @override
  Future<List<CustomerOrder>> loadAll() async => List.of(kSampleCustomerOrders);

  @override
  Future<List<CustomerOrder>> loadForCustomer(String customerId) async =>
      kSampleCustomerOrders.where((o) => o.customerId == customerId).toList();

  @override
  Future<void> upsert(CustomerOrder order) async {
    // Demo data is read-only — do not persist.
  }
}

/// In-memory source for tests (mutable, no database).
class InMemoryOrderRepository implements OrderRepository {
  InMemoryOrderRepository([Iterable<CustomerOrder> initial = const []])
    : _orders = [...initial];

  final List<CustomerOrder> _orders;

  @override
  Future<List<CustomerOrder>> loadAll() async => List.of(_orders);

  @override
  Future<List<CustomerOrder>> loadForCustomer(String customerId) async =>
      _orders.where((o) => o.customerId == customerId).toList();

  @override
  Future<void> upsert(CustomerOrder order) async {
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index >= 0) {
      _orders[index] = order;
    } else {
      _orders.add(order);
    }
  }
}

/// Encodes order lines into the `orders_table.items` JSON array.
String encodeOrderItems(List<OrderItem> items) => jsonEncode([
  for (final i in items)
    {
      'productName': i.productName,
      'category': i.category,
      'quantity': i.quantity,
      'unitPrice': i.unitPrice,
    },
]);

/// Decodes the `items` JSON array, tolerant of null/empty/corrupt/non-array
/// blobs and wrong element types — a bad blob yields `[]`, never a throw.
List<OrderItem> decodeOrderItems(String? json) {
  if (json == null || json.isEmpty) return const [];
  try {
    final decoded = jsonDecode(json);
    if (decoded is! List) return const [];
    return [
      for (final e in decoded)
        if (e is Map)
          OrderItem(
            productName: e['productName'] is String
                ? e['productName'] as String
                : '',
            category: e['category'] is String ? e['category'] as String : '',
            quantity: e['quantity'] is num ? (e['quantity'] as num).toInt() : 0,
            unitPrice: e['unitPrice'] is num
                ? (e['unitPrice'] as num).toDouble()
                : 0,
          ),
    ];
  } catch (_) {
    return const [];
  }
}
