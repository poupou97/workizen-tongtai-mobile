import 'package:drift/drift.dart';

import 'businesses.dart';
import 'users.dart';

/// AIChat entity: Conversation history with AI Copilot.
class AIChatTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId => text().references(UsersTable, #id)();
  TextColumn get messages => text()(); // JSON array
  TextColumn get context => text().nullable()(); // JSON
  TextColumn get summary => text().nullable()();
  IntColumn get tokensUsed => integer().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
