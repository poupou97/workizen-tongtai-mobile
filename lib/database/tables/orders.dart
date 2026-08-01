import 'package:drift/drift.dart';

import 'businesses.dart';
import 'customers.dart';

/// Order entity: Sales transaction tracking.
@TableIndex(name: 'orders_business_id', columns: {#businessId})
@TableIndex(name: 'orders_customer_id', columns: {#customerId})
@TableIndex(name: 'orders_order_date', columns: {#orderDate})
class OrdersTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get customerId => text().references(CustomersTable, #id)();

  /// Canonical `SalesChannel` code (WTM-209) — **not** a foreign key.
  ///
  /// It was one, pointing at `channels_table`: a dead v1 table nothing ever
  /// wrote, so every real code failed the constraint (SqliteException 787 —
  /// found the moment the first test wrote 'shopee'). The channel is a code
  /// from a closed vocabulary, not a reference to a row, and an FK here would
  /// also make dataset write-order part of the restore contract — the same
  /// trap `sourceOpportunityId` (WTM-191) deliberately avoided. FK dropped in
  /// schema v12; `channels_table` dropped with it (the WTM-190 precedent:
  /// an empty table that lies about the design is worth more gone).
  TextColumn get channelId => text().nullable()();
  TextColumn get orderNumber => text().nullable()();
  DateTimeColumn get orderDate => dateTime()();
  IntColumn get totalQuantity => integer()();
  RealColumn get subtotal => real()();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get shippingCost => real().nullable()();
  RealColumn get totalAmount => real()();
  TextColumn get status => text()();
  TextColumn get paymentStatus => text().nullable()();
  TextColumn get items => text()(); // JSON array
  TextColumn get externalId => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
