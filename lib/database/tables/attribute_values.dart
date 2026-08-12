import 'package:drift/drift.dart';

import 'attribute_definitions.dart';
import 'businesses.dart';

/// One dynamic attribute **value** attached to one entity (WTM-334, ADDENDUM).
///
/// A value points at its [definitionId] (which fixes the type, label and unit)
/// and at the entity carrying it (`entity_type` + `entity_id` — a product
/// today, kept generic so the same layer serves other entities later). The
/// value itself is stored as a **canonical string** in [valueRaw]: an INTEGER
/// as its decimal digits, a BOOLEAN as `true`/`false`, a DATE as `YYYY-MM-DD`,
/// a MULTI_ENUM as its option codes joined by `,`. The definition's type is
/// what interprets it; nothing here guesses.
///
/// ## Cascade, so nothing is orphaned
/// The foreign key to `attribute_definitions_table` cascades on delete:
/// removing a definition removes its values, so a value can never dangle
/// pointing at a definition that no longer exists (§20 "definition mồ côi").
///
/// ## One value per (definition, entity)
/// The `attribute_values_entity` unique index means a product has at most one
/// value for a given attribute. A MULTI_ENUM stays a single row (its options
/// joined), so "multi-select" never becomes "many rows the reader must dedupe".
///
/// ## Load on demand only (ADR-TON-019)
/// This table is read **only at the detail screen**. It must never be joined
/// into a list, a summary, a Capability Context or the BusinessContext — the
/// hydration cost the performance ADR measured is why. A governance test scans
/// for exactly that.
@TableIndex(name: 'attribute_values_business_id', columns: {#businessId})
@TableIndex(name: 'attribute_values_entity', columns: {#entityType, #entityId})
@TableIndex(
  name: 'attribute_values_unique',
  columns: {#businessId, #definitionId, #entityType, #entityId},
  unique: true,
)
class AttributeValuesTable extends Table {
  @override
  String get tableName => 'attribute_values_table';

  TextColumn get id => text()();
  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();

  /// The definition this value realizes. Cascades: delete the definition and
  /// its values go with it — no orphan.
  TextColumn get definitionId => text().references(
    AttributeDefinitionsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// The kind of entity this value hangs on (`product` for MVP). Kept generic.
  TextColumn get entityType => text()();

  /// The entity id (a `products_table.id` today).
  TextColumn get entityId => text()();

  /// Canonical string encoding of the value, interpreted by the definition's
  /// type. Never a display label, never localized.
  TextColumn get valueRaw => text()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
