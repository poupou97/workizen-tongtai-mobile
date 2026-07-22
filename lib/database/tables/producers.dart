import 'package:drift/drift.dart';

import 'businesses.dart';

/// Producer (Supplier) entity: Supplier and sourcing partner records.
@TableIndex(name: 'producers_business_id', columns: {#businessId})
class ProducersTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get category => text().nullable()();
  TextColumn get country => text().nullable()();
  RealColumn get rating => real().nullable()(); // 0-5
  RealColumn get reliabilityScore => real().nullable()(); // 0-100
  RealColumn get minOrderQty => real().nullable()();
  IntColumn get leadTimeDays => integer().nullable()();
  TextColumn get certifications => text().nullable()(); // JSON array
  TextColumn get contactEmail => text().nullable()();
  TextColumn get contactPhone => text().nullable()();
  TextColumn get externalId => text().nullable()();
  TextColumn get externalSource => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
