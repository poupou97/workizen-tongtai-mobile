import 'package:drift/drift.dart';

import 'businesses.dart';

/// Integration entity: External provider integrations and encrypted credentials.
class IntegrationsTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get provider => text()();
  TextColumn get status => text().nullable()();
  TextColumn get apiKeyEncrypted => text().nullable()();
  TextColumn get apiSecretEncrypted => text().nullable()();
  TextColumn get accessTokenEncrypted => text().nullable()();
  TextColumn get refreshTokenEncrypted => text().nullable()();
  TextColumn get config => text().nullable()(); // JSON
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
