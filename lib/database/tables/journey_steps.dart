import 'package:drift/drift.dart';

import 'journeys.dart';

/// JourneyStep entity: Individual steps within a journey.
class JourneyStepsTable extends Table {
  TextColumn get id => text()();
  TextColumn get journeyId =>
      text().references(JourneysTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get stepNumber => integer()();
  TextColumn get title => text()();
  TextColumn get status => text()();
  BoolColumn get milestone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  IntColumn get forecastDays => integer().nullable()();
  TextColumn get dependsOn => text().nullable()(); // JSON array
  TextColumn get guidance => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
