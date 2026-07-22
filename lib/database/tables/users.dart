import 'package:drift/drift.dart';

import 'businesses.dart';

/// User entity: Business owner profile and authentication.
class UsersTable extends Table {
  TextColumn get id => text()();
  TextColumn get email => text().unique()();
  // Nullable: a User is created at onboarding before their Business exists,
  // which also breaks the User<->Business required-FK insert cycle.
  TextColumn get businessId =>
      text().nullable().references(BusinessesTable, #id)();
  TextColumn get name => text()();
  TextColumn get language => text().nullable()(); // 'en', 'vi'
  TextColumn get timezone => text().nullable()(); // IANA timezone
  TextColumn get preferences => text().nullable()(); // JSON
  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
