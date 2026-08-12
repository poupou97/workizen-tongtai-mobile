import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../database/database.dart';
import '../../core/local_workspace.dart';
import 'attribute_models.dart';

/// Store + governance seam for the DYNAMIC attribute tier (WTM-334, ADDENDUM).
///
/// Every write goes through the governance checks in [createDefinition] and
/// [setValue]; there is no back door that skips them. The read path
/// ([loadValuesForEntity]) is deliberately entity-scoped — attributes are read
/// **only at the detail screen** (ADR-TON-019). Nothing here joins values into
/// a list, a summary, a Capability Context or the BusinessContext, and a
/// governance test scans `lib/` to keep it that way.
class AttributeRepository {
  AttributeRepository(this._db, {this.workspace = const LocalWorkspace()});

  final AppDatabase _db;
  final LocalWorkspace workspace;

  // ── definitions ────────────────────────────────────────────────────────────

  /// Creates a definition after every governance check passes.
  ///
  /// Refuses (with a typed [AttributeError]) a malformed code, a code that
  /// shadows a core field, a `user.*` code overriding a `system.*` field,
  /// malformed enum options, or a code that already exists in this business.
  Future<AttributeDefinition> createDefinition(
    AttributeDefinition definition,
  ) async {
    final businessId = await workspace.ensureBusinessId(_db);
    final namespace = _validateShape(definition);

    // Duplicate code in the same scope — the unique index is the backstop, but
    // refusing here gives a typed error instead of a raw SqliteException.
    final existing = await _findDefinitionRowByCode(
      businessId,
      definition.code,
    );
    if (existing != null) throw DuplicateAttributeCode(definition.code);

    // A user attribute may not override a system field of the same leaf.
    if (namespace.scope == AttributeScope.user) {
      if (await _systemLeafExists(businessId, namespace.leaf)) {
        throw UserAttributeOverridesSystem(namespace.leaf);
      }
    }

    await _db
        .into(_db.attributeDefinitionsTable)
        .insert(_definitionCompanion(definition, businessId, namespace));
    return definition;
  }

  /// Idempotent create-by-code: returns the existing definition when [code]
  /// already exists, otherwise creates it. This is what makes re-importing the
  /// same vendor file **not** mint a duplicate definition every run (spec §20).
  Future<AttributeDefinition> ensureDefinition(
    AttributeDefinition definition,
  ) async {
    final businessId = await workspace.ensureBusinessId(_db);
    final existing = await _findDefinitionRowByCode(
      businessId,
      definition.code,
    );
    if (existing != null) return _toDefinition(existing);
    return createDefinition(definition);
  }

  Future<List<AttributeDefinition>> loadDefinitions() async {
    final businessId = await workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.attributeDefinitionsTable)
              ..where((t) => t.businessId.equals(businessId))
              ..orderBy([(t) => OrderingTerm.asc(t.code)]))
            .get();
    return rows.map(_toDefinition).toList();
  }

  /// Removes a definition. Its values and group memberships go with it (the
  /// cascade foreign keys), so nothing is left orphaned.
  Future<void> deleteDefinition(String id) async {
    final businessId = await workspace.ensureBusinessId(_db);
    await (_db.delete(
      _db.attributeDefinitionsTable,
    )..where((t) => t.businessId.equals(businessId) & t.id.equals(id))).go();
  }

  // ── values ─────────────────────────────────────────────────────────────────

  /// Sets (inserts or replaces) one value on one entity after the value passes
  /// its definition's type check. There is at most one value per
  /// (definition, entity), so calling this twice updates rather than duplicates.
  Future<AttributeValue> setValue(AttributeValue value) async {
    final businessId = await workspace.ensureBusinessId(_db);
    final definitionRow = await _findDefinitionRowById(
      businessId,
      value.definitionId,
    );
    if (definitionRow == null) {
      throw InvalidAttributeValue(
        'no definition ${value.definitionId} for this business',
      );
    }
    final definition = _toDefinition(definitionRow);
    if (!definition.type.isValidValue(
      value.valueRaw,
      options: definition.enumOptions,
    )) {
      throw InvalidAttributeValue(
        'value "${value.valueRaw}" is not a valid ${definition.type.code}',
      );
    }

    final existing =
        await (_db.select(_db.attributeValuesTable)..where(
              (t) =>
                  t.businessId.equals(businessId) &
                  t.definitionId.equals(value.definitionId) &
                  t.entityType.equals(value.entityType) &
                  t.entityId.equals(value.entityId),
            ))
            .getSingleOrNull();

    if (existing != null) {
      await (_db.update(
        _db.attributeValuesTable,
      )..where((t) => t.id.equals(existing.id))).write(
        AttributeValuesTableCompanion(
          valueRaw: Value(value.valueRaw),
          updatedAt: Value(value.updatedAt),
        ),
      );
      return _toValue(existing.copyWith(valueRaw: value.valueRaw));
    }

    await _db
        .into(_db.attributeValuesTable)
        .insert(_valueCompanion(value, businessId));
    return value;
  }

  /// Loads every value for one entity — the **only** intended read path
  /// (detail screen, on demand).
  Future<List<AttributeValue>> loadValuesForEntity(
    String entityType,
    String entityId,
  ) async {
    final businessId = await workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.attributeValuesTable)..where(
              (t) =>
                  t.businessId.equals(businessId) &
                  t.entityType.equals(entityType) &
                  t.entityId.equals(entityId),
            ))
            .get();
    return rows.map(_toValue).toList();
  }

  Future<void> deleteValue(String id) async {
    final businessId = await workspace.ensureBusinessId(_db);
    await (_db.delete(
      _db.attributeValuesTable,
    )..where((t) => t.businessId.equals(businessId) & t.id.equals(id))).go();
  }

  // ── groups ─────────────────────────────────────────────────────────────────

  Future<AttributeGroup> createGroup(AttributeGroup group) async {
    final businessId = await workspace.ensureBusinessId(_db);
    final existing =
        await (_db.select(_db.attributeGroupsTable)..where(
              (t) =>
                  t.businessId.equals(businessId) & t.code.equals(group.code),
            ))
            .getSingleOrNull();
    if (existing != null) throw DuplicateAttributeCode(group.code);
    await _db
        .into(_db.attributeGroupsTable)
        .insert(_groupCompanion(group, businessId));
    return group;
  }

  Future<List<AttributeGroup>> loadGroups() async {
    final businessId = await workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.attributeGroupsTable)
              ..where((t) => t.businessId.equals(businessId))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
    return rows.map(_toGroup).toList();
  }

  Future<void> deleteGroup(String id) async {
    final businessId = await workspace.ensureBusinessId(_db);
    await (_db.delete(
      _db.attributeGroupsTable,
    )..where((t) => t.businessId.equals(businessId) & t.id.equals(id))).go();
  }

  /// Adds a definition to a group. The foreign keys guarantee both the group
  /// and the definition exist — a membership can never dangle.
  Future<AttributeGroupItem> addToGroup(AttributeGroupItem item) async {
    final businessId = await workspace.ensureBusinessId(_db);
    await _db
        .into(_db.attributeGroupItemsTable)
        .insert(_groupItemCompanion(item, businessId));
    return item;
  }

  Future<List<AttributeGroupItem>> loadGroupItems(String groupId) async {
    final businessId = await workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.attributeGroupItemsTable)
              ..where(
                (t) =>
                    t.businessId.equals(businessId) & t.groupId.equals(groupId),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
    return rows.map(_toGroupItem).toList();
  }

  Future<void> removeFromGroup(String id) async {
    final businessId = await workspace.ensureBusinessId(_db);
    await (_db.delete(
      _db.attributeGroupItemsTable,
    )..where((t) => t.businessId.equals(businessId) & t.id.equals(id))).go();
  }

  // ── backup / restore (WTM-164, ADR-TON-018) ─────────────────────────────────

  Future<List<AttributeDefinition>> loadAllDefinitions() => loadDefinitions();

  Future<List<AttributeValue>> loadAllValues() async {
    final businessId = await workspace.ensureBusinessId(_db);
    final rows = await (_db.select(
      _db.attributeValuesTable,
    )..where((t) => t.businessId.equals(businessId))).get();
    return rows.map(_toValue).toList();
  }

  Future<List<AttributeGroup>> loadAllGroups() => loadGroups();

  Future<List<AttributeGroupItem>> loadAllGroupItems() async {
    final businessId = await workspace.ensureBusinessId(_db);
    final rows = await (_db.select(
      _db.attributeGroupItemsTable,
    )..where((t) => t.businessId.equals(businessId))).get();
    return rows.map(_toGroupItem).toList();
  }

  /// Bulk restore, written parents-first so a value or membership never lands
  /// before the definition/group it points at. `insertOrReplace` mirrors the
  /// commerce repository's restore path.
  Future<void> restoreAll({
    required List<AttributeGroup> groups,
    required List<AttributeDefinition> definitions,
    required List<AttributeValue> values,
    required List<AttributeGroupItem> groupItems,
  }) async {
    final businessId = await workspace.ensureBusinessId(_db);
    await _db.transaction(() async {
      await _db.batch((batch) {
        for (final g in groups) {
          batch.insert(
            _db.attributeGroupsTable,
            _groupCompanion(g, businessId),
            mode: InsertMode.insertOrReplace,
          );
        }
        for (final d in definitions) {
          batch.insert(
            _db.attributeDefinitionsTable,
            _definitionCompanion(
              d,
              businessId,
              AttributeNamespace.tryParse(d.code),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
        for (final v in values) {
          batch.insert(
            _db.attributeValuesTable,
            _valueCompanion(v, businessId),
            mode: InsertMode.insertOrReplace,
          );
        }
        for (final item in groupItems) {
          batch.insert(
            _db.attributeGroupItemsTable,
            _groupItemCompanion(item, businessId),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    });
  }

  /// **Scope: every attribute table of this business.** Restore Replace only.
  /// Order is FK-safe: memberships and values before the definitions/groups
  /// they reference.
  Future<void> deleteAll() async {
    final businessId = await workspace.ensureBusinessId(_db);
    await _db.transaction(() async {
      await (_db.delete(
        _db.attributeGroupItemsTable,
      )..where((t) => t.businessId.equals(businessId))).go();
      await (_db.delete(
        _db.attributeValuesTable,
      )..where((t) => t.businessId.equals(businessId))).go();
      await (_db.delete(
        _db.attributeDefinitionsTable,
      )..where((t) => t.businessId.equals(businessId))).go();
      await (_db.delete(
        _db.attributeGroupsTable,
      )..where((t) => t.businessId.equals(businessId))).go();
    });
  }

  // ── validation ───────────────────────────────────────────────────────────

  /// Shape checks that do not need the database: namespace, core shadowing and
  /// enum-option well-formedness. Returns the parsed namespace for reuse.
  AttributeNamespace _validateShape(AttributeDefinition definition) {
    final namespace = AttributeNamespace.tryParse(definition.code);
    if (namespace == null) throw InvalidAttributeNamespace(definition.code);
    if (kCoreShadowedFields.contains(namespace.leaf)) {
      throw AttributeShadowsCoreField(namespace.leaf);
    }
    if (definition.type.usesOptions) {
      final options = definition.enumOptions;
      if (options.isEmpty) {
        throw const InvalidAttributeValue(
          'an ENUM / MULTI_ENUM needs at least one option',
        );
      }
      final seen = <String>{};
      for (final option in options) {
        if (option.isEmpty ||
            option.contains(AttributeType.multiEnumSeparator) ||
            !seen.add(option)) {
          throw InvalidAttributeValue('malformed enum option: "$option"');
        }
      }
    } else if (definition.enumOptions.isNotEmpty) {
      throw InvalidAttributeValue(
        '${definition.type.code} does not take enum options',
      );
    }
    return namespace;
  }

  Future<AttributeDefinitionsTableData?> _findDefinitionRowByCode(
    String businessId,
    String code,
  ) =>
      (_db.select(_db.attributeDefinitionsTable)..where(
            (t) => t.businessId.equals(businessId) & t.code.equals(code),
          ))
          .getSingleOrNull();

  Future<AttributeDefinitionsTableData?> _findDefinitionRowById(
    String businessId,
    String id,
  ) =>
      (_db.select(_db.attributeDefinitionsTable)
            ..where((t) => t.businessId.equals(businessId) & t.id.equals(id)))
          .getSingleOrNull();

  Future<bool> _systemLeafExists(String businessId, String leaf) async {
    final rows =
        await (_db.select(_db.attributeDefinitionsTable)..where(
              (t) =>
                  t.businessId.equals(businessId) &
                  t.scopeCode.equals(AttributeScope.system.code),
            ))
            .get();
    return rows.any(
      (row) => AttributeNamespace.tryParse(row.code)?.leaf == leaf,
    );
  }

  // ── mapping ────────────────────────────────────────────────────────────────

  AttributeDefinitionsTableCompanion _definitionCompanion(
    AttributeDefinition d,
    String businessId,
    AttributeNamespace? namespace,
  ) => AttributeDefinitionsTableCompanion.insert(
    id: d.id,
    businessId: businessId,
    code: d.code,
    scopeCode: (namespace?.scope ?? AttributeScope.user).code,
    vendorName: Value(namespace?.vendor),
    typeCode: d.type.code,
    label: d.label,
    unit: Value(d.unit),
    enumOptions: Value(
      d.enumOptions.isEmpty ? null : jsonEncode(d.enumOptions),
    ),
    createdAt: Value(d.createdAt),
    updatedAt: Value(d.updatedAt),
  );

  AttributeDefinition _toDefinition(AttributeDefinitionsTableData row) =>
      AttributeDefinition(
        id: row.id,
        code: row.code,
        type: AttributeType.fromCode(row.typeCode) ?? AttributeType.text,
        label: row.label,
        unit: row.unit,
        enumOptions: _decodeOptions(row.enumOptions),
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  AttributeValuesTableCompanion _valueCompanion(
    AttributeValue v,
    String businessId,
  ) => AttributeValuesTableCompanion.insert(
    id: v.id,
    businessId: businessId,
    definitionId: v.definitionId,
    entityType: v.entityType,
    entityId: v.entityId,
    valueRaw: v.valueRaw,
    createdAt: Value(v.createdAt),
    updatedAt: Value(v.updatedAt),
  );

  AttributeValue _toValue(AttributeValuesTableData row) => AttributeValue(
    id: row.id,
    definitionId: row.definitionId,
    entityType: row.entityType,
    entityId: row.entityId,
    valueRaw: row.valueRaw,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  AttributeGroupsTableCompanion _groupCompanion(
    AttributeGroup g,
    String businessId,
  ) => AttributeGroupsTableCompanion.insert(
    id: g.id,
    businessId: businessId,
    code: g.code,
    label: g.label,
    sortOrder: Value(g.sortOrder),
    createdAt: Value(g.createdAt),
    updatedAt: Value(g.updatedAt),
  );

  AttributeGroup _toGroup(AttributeGroupsTableData row) => AttributeGroup(
    id: row.id,
    code: row.code,
    label: row.label,
    sortOrder: row.sortOrder,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  AttributeGroupItemsTableCompanion _groupItemCompanion(
    AttributeGroupItem item,
    String businessId,
  ) => AttributeGroupItemsTableCompanion.insert(
    id: item.id,
    businessId: businessId,
    groupId: item.groupId,
    definitionId: item.definitionId,
    sortOrder: Value(item.sortOrder),
  );

  AttributeGroupItem _toGroupItem(AttributeGroupItemsTableData row) =>
      AttributeGroupItem(
        id: row.id,
        groupId: row.groupId,
        definitionId: row.definitionId,
        sortOrder: row.sortOrder,
      );

  static List<String> _decodeOptions(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded.whereType<String>().toList() : const [];
    } on FormatException {
      return const [];
    }
  }
}
