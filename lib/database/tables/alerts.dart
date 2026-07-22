import 'package:drift/drift.dart';

import 'businesses.dart';

/// Alert entity: Notifications and AI recommendations.
class AlertsTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  TextColumn get severity => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get aiRecommendation => text().nullable()();
  TextColumn get status => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
