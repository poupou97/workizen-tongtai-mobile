import 'package:drift/drift.dart';

import 'businesses.dart';

/// A **definition** of one dynamic attribute (WTM-334, ADDENDUM).
///
/// This is the DYNAMIC tier of the Commerce Attribute Model
/// (`docs/05-DATA/COMMERCE-ATTRIBUTE-MODEL.md` §6.3): per-industry
/// classification / spec / metadata that is too sparse to earn a typed column
/// (electronics wattage, fashion season, food shelf-life…). A definition
/// carries the *shape* — label, one of nine types, optional unit, and the
/// allowed options for an ENUM — while `attribute_values_table` carries the
/// per-product value.
///
/// ## Namespace, not a free-for-all
/// `code` is fully namespaced: `system.*` (shipped by the app), `user.*`
/// (created by the seller), or `vendor.<name>.*` (mapped from an import). A
/// vendor import can never mint a `system.*` code, and two definitions may not
/// share a `code` within a business — the `attribute_definitions_code` unique
/// index makes "duplicate code in the same scope" a database constraint, not a
/// convention nobody enforces (§20).
///
/// ## Why no arbitrary-JSON type
/// The nine types are a closed set. Raw vendor payload that does not fit one of
/// them stays in import provenance and is *reported* as unmapped — it never
/// becomes a business attribute (§21). Storing arbitrary JSON here would
/// re-open the "third home for the same field" the model exists to close.
@TableIndex(name: 'attribute_definitions_business_id', columns: {#businessId})
@TableIndex(
  name: 'attribute_definitions_code',
  columns: {#businessId, #code},
  unique: true,
)
class AttributeDefinitionsTable extends Table {
  @override
  String get tableName => 'attribute_definitions_table';

  TextColumn get id => text()();
  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();

  /// Fully-namespaced canonical code — `system.*` / `user.*` /
  /// `vendor.<name>.*`. Unique per business.
  TextColumn get code => text()();

  /// The namespace root — canonical `AttributeScope` code (`system` / `user` /
  /// `vendor`). Stored so scans and the "user may not override system"
  /// governance rule do not have to re-parse `code` on every row.
  TextColumn get scopeCode => text()();

  /// Vendor slug when [scopeCode] is `vendor`; `null` otherwise.
  TextColumn get vendorName => text().nullable()();

  /// One of nine canonical `AttributeType` codes (TEXT · INTEGER · DECIMAL ·
  /// BOOLEAN · DATE · DATETIME · ENUM · MULTI_ENUM · URL).
  TextColumn get typeCode => text()();

  /// Human label shown on the detail screen. Display only.
  TextColumn get label => text()();

  /// Unit of measure for a numeric attribute (`W`, `V`, `months`…); `null`
  /// when the type has no unit. `null` ≠ empty string.
  TextColumn get unit => text().nullable()();

  /// Allowed option codes for `ENUM` / `MULTI_ENUM`, as a JSON string array.
  /// `null` for every other type. This is bounded metadata of the definition,
  /// not an arbitrary-JSON *value*.
  TextColumn get enumOptions => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
