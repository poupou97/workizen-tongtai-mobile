import 'package:drift/drift.dart';

import 'businesses.dart';

/// Customer entity: CRM records and customer segmentation.
@TableIndex(name: 'customers_business_id', columns: {#businessId})
class CustomersTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get externalId => text().nullable()();
  TextColumn get externalSource => text().nullable()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get segments => text().nullable()(); // JSON array
  RealColumn get lifetimeValue => real().nullable()();
  IntColumn get orderCount => integer().nullable()();
  RealColumn get totalSpent => real().nullable()();
  RealColumn get avgOrderValue => real().nullable()();
  DateTimeColumn get lastOrderDate => dateTime().nullable()();
  RealColumn get churnRisk => real().nullable()(); // 0-100

  /// Versioned full-domain snapshot (JSON) — WTM-123, ADR-TON-009 (option B).
  /// Structured columns stay the source of truth for promoted fields; this
  /// carries extended fields not yet promoted (tags, addresses, notes).
  TextColumn get domainSnapshot => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
