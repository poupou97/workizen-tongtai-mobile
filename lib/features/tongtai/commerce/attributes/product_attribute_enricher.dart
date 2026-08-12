/// Enriches the sample dataset with per-industry DYNAMIC attributes (WTM-335,
/// ADDENDUM). **Additive only** — it never creates, edits or deletes a product;
/// it mints `system.*` definitions + the eight display groups (§18) and writes
/// per-product attribute values through the [AttributeRepository]'s governed
/// write path (spec §17 "làm giàu, không thay thế").
///
/// Living under `commerce/attributes/` is deliberate: this is the only layer
/// besides the repository allowed to name the value store, so the WTM-334
/// performance-governance scan (ADR-TON-019) stays green. `SampleBusinessSeeder`
/// holds a [ProductAttributeEnricher] — a non-guarded type — and never touches
/// the attribute API itself.
library;

import '../../inventory/product.dart';
import 'attribute_models.dart';
import 'attribute_repository.dart';
import 'product_attribute_catalog.dart';

/// How many entities got attributes, and how many values were written — so a
/// caller (and a test) can prove the enrichment actually ran, not just "true".
class ProductAttributeEnrichmentReport {
  const ProductAttributeEnrichmentReport({
    required this.definitions,
    required this.groups,
    required this.enrichedProducts,
    required this.values,
  });

  final int definitions;
  final int groups;
  final int enrichedProducts;
  final int values;
}

/// The entity type every product attribute value is keyed on. One constant, so
/// the write path and the read path (detail screen) can never disagree about
/// the string.
const String kProductAttributeEntityType = 'product';

class ProductAttributeEnricher {
  ProductAttributeEnricher(this._attributes, {String Function()? newId})
    : _newId = newId ?? _defaultId;

  final AttributeRepository _attributes;
  final String Function() _newId;

  /// Seeds the catalog once, then writes each product's category-derived values.
  ///
  /// Idempotent: definitions and groups go through `ensureDefinition` /
  /// existence-checked `createGroup`, and `setValue` replaces rather than
  /// duplicates, so running it twice over the same products leaves the same
  /// rows. Safe to call after every sample re-seed.
  Future<ProductAttributeEnrichmentReport> enrich(
    List<Product> products,
  ) async {
    final definitionIdByCode = await _ensureDefinitions();
    final groupCount = await _ensureGroups(definitionIdByCode);

    var enriched = 0;
    var valueCount = 0;
    for (final product in products) {
      final specs = attributesForProduct(
        category: product.category,
        seed: product.id,
      );
      if (specs.isEmpty) continue;
      enriched++;
      for (final spec in specs) {
        final definitionId = definitionIdByCode[spec.code];
        // A value spec for a code we did not define is a programming error, not
        // a data condition — skip it rather than throw mid-seed.
        if (definitionId == null) continue;
        await _attributes.setValue(
          AttributeValue(
            id: _newId(),
            definitionId: definitionId,
            entityType: kProductAttributeEntityType,
            entityId: product.id,
            valueRaw: spec.valueRaw,
          ),
        );
        valueCount++;
      }
    }

    return ProductAttributeEnrichmentReport(
      definitions: definitionIdByCode.length,
      groups: groupCount,
      enrichedProducts: enriched,
      values: valueCount,
    );
  }

  /// Ensures every catalog definition exists; returns code → definition id
  /// (existing or freshly created), so values can be linked without a second
  /// query per product.
  Future<Map<String, String>> _ensureDefinitions() async {
    final existing = {
      for (final d in await _attributes.loadDefinitions()) d.code: d.id,
    };
    final idByCode = <String, String>{};
    for (final spec in kProductAttributeDefinitions) {
      final priorId = existing[spec.code];
      if (priorId != null) {
        idByCode[spec.code] = priorId;
        continue;
      }
      final id = _newId();
      final created = await _attributes.ensureDefinition(
        AttributeDefinition(
          id: id,
          code: spec.code,
          type: spec.type,
          label: spec.label,
          unit: spec.unit,
          enumOptions: spec.enumOptions,
        ),
      );
      idByCode[spec.code] = created.id;
    }
    return idByCode;
  }

  /// Ensures every display group exists and every definition sits in its group
  /// exactly once. Returns the number of catalog groups.
  Future<int> _ensureGroups(Map<String, String> definitionIdByCode) async {
    final existingGroups = {
      for (final g in await _attributes.loadGroups()) g.code: g.id,
    };
    final groupIdByCode = <String, String>{};
    for (final spec in kProductAttributeGroups) {
      final priorId = existingGroups[spec.code];
      if (priorId != null) {
        groupIdByCode[spec.code] = priorId;
        continue;
      }
      final group = await _attributes.createGroup(
        AttributeGroup(
          id: _newId(),
          code: spec.code,
          label: spec.label,
          sortOrder: spec.sortOrder,
        ),
      );
      groupIdByCode[spec.code] = group.id;
    }

    // Add memberships only for definitions not already in their group, so a
    // re-run does not stack duplicate group items.
    for (final spec in kProductAttributeDefinitions) {
      final groupId = groupIdByCode[spec.groupCode];
      final definitionId = definitionIdByCode[spec.code];
      if (groupId == null || definitionId == null) continue;
      final members = await _attributes.loadGroupItems(groupId);
      final alreadyIn = members.any((m) => m.definitionId == definitionId);
      if (alreadyIn) continue;
      await _attributes.addToGroup(
        AttributeGroupItem(
          id: _newId(),
          groupId: groupId,
          definitionId: definitionId,
        ),
      );
    }
    return groupIdByCode.length;
  }

  static int _counter = 0;
  static String _defaultId() => 'attr-seed-${_counter++}';
}
