import 'package:drift/drift.dart';

import 'businesses.dart';

/// A display grouping for dynamic attributes (WTM-334, ADDENDUM).
///
/// A group is **presentation only** — it names a bucket the detail screen can
/// render attributes under (General · Inventory · Fashion · Electronics …). It
/// owns no value: which definitions belong to it lives in
/// `attribute_group_items_table`, so a definition can move between groups
/// without rewriting the definition itself.
///
/// `code` is unique per business (the `attribute_groups_code` index): a screen
/// refers to a group by a stable code, not by its localized label.
@TableIndex(name: 'attribute_groups_business_id', columns: {#businessId})
@TableIndex(
  name: 'attribute_groups_code',
  columns: {#businessId, #code},
  unique: true,
)
class AttributeGroupsTable extends Table {
  @override
  String get tableName => 'attribute_groups_table';

  TextColumn get id => text()();
  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();

  /// Stable code (e.g. `system.inventory`, `user.custom`). Unique per business.
  TextColumn get code => text()();

  /// Human label shown on the detail screen. Display only — never a key.
  TextColumn get label => text()();

  /// Ordering hint so groups render in a deliberate order, not insertion order.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
