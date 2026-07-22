import 'package:drift/drift.dart';

import 'businesses.dart';
import 'customers.dart';
import 'channels.dart';

/// Order entity: Sales transaction tracking.
@TableIndex(name: 'orders_business_id', columns: {#businessId})
@TableIndex(name: 'orders_customer_id', columns: {#customerId})
@TableIndex(name: 'orders_order_date', columns: {#orderDate})
class OrdersTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get customerId => text().references(CustomersTable, #id)();
  TextColumn get channelId =>
      text().nullable().references(ChannelsTable, #id)();
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
