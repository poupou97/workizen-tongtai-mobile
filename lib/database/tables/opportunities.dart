import 'package:drift/drift.dart';

import 'businesses.dart';

/// Opportunity entity: AI-discovered business opportunities.
@TableIndex(name: 'opportunities_business_id', columns: {#businessId})
class OpportunitiesTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get market => text().nullable()();
  RealColumn get estimatedRoi => real().nullable()();
  RealColumn get estimatedInvestment => real().nullable()();
  RealColumn get riskScore => real().nullable()(); // 0-100
  RealColumn get feasibilityScore => real().nullable()(); // 0-100
  RealColumn get aiScore => real().nullable()(); // 0-100
  TextColumn get status => text().nullable()();
  TextColumn get relatedProducts => text().nullable()(); // JSON array
  TextColumn get relatedSuppliers => text().nullable()(); // JSON array
  DateTimeColumn get discoveredAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
