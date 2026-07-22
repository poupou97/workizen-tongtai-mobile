import 'package:drift/drift.dart';

import 'businesses.dart';

/// Document entity: Document storage (contracts, certificates, receipts, OCR).
class DocumentsTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get fileName => text().nullable()();
  TextColumn get fileType => text().nullable()();
  IntColumn get fileSize => integer().nullable()();
  TextColumn get localPath => text().nullable()();
  TextColumn get extractedText => text().nullable()();
  TextColumn get extractedData => text().nullable()(); // JSON
  TextColumn get relatedEntityType => text().nullable()();
  TextColumn get relatedEntityId => text().nullable()();
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
