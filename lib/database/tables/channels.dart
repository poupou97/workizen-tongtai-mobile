import 'package:drift/drift.dart';

import 'businesses.dart';

/// Channel entity: Sales channel integration (Shopee, TikTok, Amazon, etc.).
class ChannelsTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get platformId => text().nullable()();
  TextColumn get status => text().nullable()();
  BoolColumn get isConnected =>
      boolean().withDefault(const Constant(false))();
  TextColumn get credentialsEncrypted => text().nullable()();
  TextColumn get metrics => text().nullable()(); // JSON
  DateTimeColumn get lastSyncDate => dateTime().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
