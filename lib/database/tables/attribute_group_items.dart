import 'package:drift/drift.dart';

import 'attribute_definitions.dart';
import 'attribute_groups.dart';
import 'businesses.dart';

/// Membership of a definition in a display group (WTM-334, ADDENDUM).
///
/// A join row: it says *"definition X shows under group Y, at position N"*. It
/// is deliberately its own table rather than a `group_id` column on the
/// definition, because a definition's home group is presentation and may move,
/// while the definition (type, unit, options) is data that does not.
///
/// ## Both foreign keys cascade
/// Delete the group **or** the definition and the membership row goes with it.
/// A membership can therefore never point at a group or a definition that no
/// longer exists — "group membership treo" (§20) is a database constraint, and
/// with `PRAGMA foreign_keys = ON` inserting a row for a non-existent
/// definition fails outright (SqliteException 787) instead of dangling.
///
/// The `attribute_group_items_unique` index keeps a definition from being added
/// to the same group twice.
@TableIndex(name: 'attribute_group_items_business_id', columns: {#businessId})
@TableIndex(name: 'attribute_group_items_group', columns: {#groupId})
@TableIndex(
  name: 'attribute_group_items_unique',
  columns: {#businessId, #groupId, #definitionId},
  unique: true,
)
class AttributeGroupItemsTable extends Table {
  @override
  String get tableName => 'attribute_group_items_table';

  TextColumn get id => text()();
  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get groupId => text().references(
    AttributeGroupsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get definitionId => text().references(
    AttributeDefinitionsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Position within the group. Display only.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
