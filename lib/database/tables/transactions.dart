import 'package:drift/drift.dart';

import 'businesses.dart';
import 'orders.dart';

/// Transaction entity: Financial transaction tracking (revenue, expenses).
@TableIndex(name: 'transactions_business_id', columns: {#businessId})
@TableIndex(name: 'transactions_date', columns: {#date})
class TransactionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  TextColumn get category => text().nullable()();
  RealColumn get amount => real()();
  TextColumn get currency => text().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get account => text().nullable()();
  TextColumn get orderId => text().nullable().references(OrdersTable, #id)();
  TextColumn get description => text().nullable()();
  TextColumn get paymentMethod => text().nullable()();
  BoolColumn get isReconciled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
