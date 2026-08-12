/// Turns an entity's loaded attribute values into a **grouped, display-ready**
/// structure (WTM-335 §15) and a **grouped AI context** (§14). Pure Dart — no
/// Flutter, no Drift — so both the detail screen and the AI builder read the
/// same shape, and both are unit-testable without a widget or a database.
///
/// Two hard rules from the spec, enforced here:
///
/// * **Only field · group · value leaves this layer.** The output carries a
///   group label, a field label, a formatted value and an optional unit —
///   never an `AttributeDefinition`, a code, a scope, a JSON blob or the EAV
///   shape (§15). The seller (and the model) see business language only.
/// * **No empty group renders.** A group with no resolved rows is dropped, so a
///   product with no attributes produces an empty list and the detail screen
///   shows no grouped block at all.
library;

import 'attribute_models.dart';
import 'product_attribute_catalog.dart';

/// One display row: a field label, its formatted value, and an optional unit.
/// This is what a detail row renders (`· Label: Value unit`) — no code, no id.
class AttributeDisplayRow {
  const AttributeDisplayRow({
    required this.label,
    required this.value,
    this.unit,
  });

  final String label;
  final String value;
  final String? unit;

  /// `Label: Value unit`, used by the AI context and by tests. The unit is
  /// appended only when present.
  String get line => unit == null ? '$label: $value' : '$label: $value $unit';
}

/// One display group: a heading plus its rows, already ordered.
class AttributeDisplayGroup {
  const AttributeDisplayGroup({required this.label, required this.rows});

  final String label;
  final List<AttributeDisplayRow> rows;
}

/// Groups [values] under their definitions' groups for display.
///
/// Resolution walks group → group-items → definition → value, so a value only
/// appears if the full chain resolves. Anything the chain cannot resolve (a
/// value whose definition is gone, a definition in no group) is simply not
/// shown — never rendered as raw EAV.
///
/// Returns an **empty list** when [values] is empty or nothing resolves; the
/// caller reads "empty ⇒ do not render the grouped block".
List<AttributeDisplayGroup> buildAttributeDisplayGroups({
  required List<AttributeValue> values,
  required List<AttributeDefinition> definitions,
  required List<AttributeGroup> groups,
  required List<AttributeGroupItem> groupItems,
}) {
  if (values.isEmpty) return const [];

  final definitionById = {for (final d in definitions) d.id: d};
  final valueByDefinitionId = {for (final v in values) v.definitionId: v};

  // group id → its ordered definition ids (from the memberships).
  final itemsByGroupId = <String, List<AttributeGroupItem>>{};
  for (final item in groupItems) {
    (itemsByGroupId[item.groupId] ??= []).add(item);
  }

  final orderedGroups = [...groups]
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  final result = <AttributeDisplayGroup>[];
  final placed = <String>{};

  for (final group in orderedGroups) {
    final members = [...(itemsByGroupId[group.id] ?? const [])]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final rows = <AttributeDisplayRow>[];
    for (final member in members) {
      final definition = definitionById[member.definitionId];
      if (definition == null) continue;
      final value = valueByDefinitionId[definition.id];
      if (value == null) continue;
      rows.add(_row(definition, value));
      placed.add(definition.id);
    }
    if (rows.isNotEmpty) {
      result.add(AttributeDisplayGroup(label: group.label, rows: rows));
    }
  }

  // A value whose definition is in no group still deserves a home rather than
  // vanishing (the "nothing is silently swallowed" discipline). Collect any
  // resolved-but-unplaced values under the Custom group's label.
  final leftovers = <AttributeDisplayRow>[];
  for (final value in values) {
    final definition = definitionById[value.definitionId];
    if (definition == null || placed.contains(definition.id)) continue;
    leftovers.add(_row(definition, value));
    placed.add(definition.id);
  }
  if (leftovers.isNotEmpty) {
    result.add(
      AttributeDisplayGroup(label: _customGroupLabel(groups), rows: leftovers),
    );
  }

  return result;
}

/// The §14 AI context block for a product's attributes: the same grouped shape,
/// flattened to text as `## <group>` headings with `- field: value unit` lines.
///
/// Returns an empty string when there are no attributes, so the caller appends
/// nothing (no empty "## Thông số" heading in the prompt). Internal metadata —
/// codes, ids, scope — is never emitted; only business labels and values, which
/// is the whole point of grouping the context rather than dumping key/value.
String buildAttributeAiContext({
  required List<AttributeValue> values,
  required List<AttributeDefinition> definitions,
  required List<AttributeGroup> groups,
  required List<AttributeGroupItem> groupItems,
}) {
  final grouped = buildAttributeDisplayGroups(
    values: values,
    definitions: definitions,
    groups: groups,
    groupItems: groupItems,
  );
  if (grouped.isEmpty) return '';
  final buffer = StringBuffer();
  for (final group in grouped) {
    buffer.writeln('## ${group.label}');
    for (final row in group.rows) {
      buffer.writeln('- ${row.line}');
    }
  }
  return buffer.toString().trimRight();
}

AttributeDisplayRow _row(
  AttributeDefinition definition,
  AttributeValue value,
) => AttributeDisplayRow(
  label: definition.label,
  value: _displayValue(definition, value.valueRaw),
  unit: definition.unit,
);

/// Formats a stored raw value into a human string. Enum codes become their
/// Vietnamese labels; booleans become Có/Không; everything else shows as
/// entered. Never exposes the code.
String _displayValue(AttributeDefinition definition, String raw) {
  switch (definition.type) {
    case AttributeType.enumType:
      return kAttributeOptionLabels[raw] ?? raw;
    case AttributeType.multiEnum:
      return raw
          .split(AttributeType.multiEnumSeparator)
          .map((code) => kAttributeOptionLabels[code] ?? code)
          .join(', ');
    case AttributeType.boolean:
      return raw == 'true' ? 'Có' : 'Không';
    case AttributeType.text:
    case AttributeType.integer:
    case AttributeType.decimal:
    case AttributeType.date:
    case AttributeType.datetime:
    case AttributeType.url:
      return raw;
  }
}

String _customGroupLabel(List<AttributeGroup> groups) {
  for (final g in groups) {
    if (g.code == 'system.group.custom') return g.label;
  }
  return 'Thông số khác';
}
