import 'package:drift/drift.dart';

import 'businesses.dart';

/// Journey entity: Business goal tracking and orchestration.
@TableIndex(name: 'journeys_business_id', columns: {#businessId})
class JourneysTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get goal => text()();
  TextColumn get status => text()();
  IntColumn get progressPercent => integer().nullable()();
  IntColumn get totalSteps => integer().nullable()();
  IntColumn get completedSteps =>
      integer().withDefault(const Constant(0))();
  RealColumn get budget => real().nullable()();
  RealColumn get spent => real().withDefault(const Constant(0))();
  IntColumn get timelineDays => integer().nullable()();
  RealColumn get revenueImpact => real().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
