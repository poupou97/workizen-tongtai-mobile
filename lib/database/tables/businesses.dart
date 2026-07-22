import 'package:drift/drift.dart';

import 'users.dart';

/// Business entity: Root entity representing a business, owned by one user.
class BusinessesTable extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text().references(UsersTable, #id)();
  TextColumn get name => text()();
  TextColumn get industry =>
      text().nullable()(); // 'retail', 'ecommerce', 'manufacturing', 'service'
  TextColumn get country => text().nullable()(); // Country code
  TextColumn get currency => text().withDefault(const Constant('VND'))();
  RealColumn get annualRevenue => real().nullable()();
  IntColumn get employeeCount => integer().nullable()();
  TextColumn get stage =>
      text().nullable()(); // 'startup', 'growth', 'established'
  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
