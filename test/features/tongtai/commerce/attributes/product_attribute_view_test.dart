import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/attribute_models.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/product_attribute_view.dart';

/// WTM-335 — the grouped display view model (§15) and the grouped AI context
/// (§14). Pure Dart. Each test drives the real grouping, never a placebo.
void main() {
  AttributeDefinition def(
    String id,
    String code,
    AttributeType type, {
    String label = 'Label',
    String? unit,
    List<String> options = const [],
  }) => AttributeDefinition(
    id: id,
    code: code,
    type: type,
    label: label,
    unit: unit,
    enumOptions: options,
  );

  AttributeValue val(String defId, String raw, {String entity = 'p1'}) =>
      AttributeValue(
        id: 'v-$defId',
        definitionId: defId,
        entityType: 'product',
        entityId: entity,
        valueRaw: raw,
      );

  AttributeGroup grp(String id, String code, String label, int sort) =>
      AttributeGroup(id: id, code: code, label: label, sortOrder: sort);

  test('empty values ⇒ empty groups (no block to render)', () {
    final groups = buildAttributeDisplayGroups(
      values: const [],
      definitions: [def('d1', 'system.material', AttributeType.text)],
      groups: [grp('g1', 'system.group.custom', 'Khác', 0)],
      groupItems: const [
        AttributeGroupItem(id: 'gi1', groupId: 'g1', definitionId: 'd1'),
      ],
    );
    expect(groups, isEmpty);
  });

  test('a group with no resolved rows is dropped — never an empty heading', () {
    // The group exists and has a member, but there is no VALUE for that member,
    // so the group must not appear.
    final groups = buildAttributeDisplayGroups(
      values: [val('d2', '350')], // value for d2, which is in g2
      definitions: [
        def('d1', 'system.form', AttributeType.text, label: 'Kiểu dáng'),
        def(
          'd2',
          'system.wattage',
          AttributeType.decimal,
          label: 'Công suất',
          unit: 'W',
        ),
      ],
      groups: [
        grp('g1', 'system.group.fashion', 'Thời trang', 0),
        grp('g2', 'system.group.electronics', 'Điện tử', 1),
      ],
      groupItems: const [
        AttributeGroupItem(id: 'gi1', groupId: 'g1', definitionId: 'd1'),
        AttributeGroupItem(id: 'gi2', groupId: 'g2', definitionId: 'd2'),
      ],
    );
    expect(groups.map((g) => g.label), ['Điện tử']);
    expect(groups.single.rows.single.label, 'Công suất');
    expect(groups.single.rows.single.unit, 'W');
  });

  test('groups render in sortOrder, rows carry label · value · unit only', () {
    final groups = buildAttributeDisplayGroups(
      values: [val('d1', 'cotton'), val('d2', '350')],
      definitions: [
        def(
          'd1',
          'system.material',
          AttributeType.enumType,
          label: 'Chất liệu',
          options: const ['cotton'],
        ),
        def(
          'd2',
          'system.wattage',
          AttributeType.decimal,
          label: 'Công suất',
          unit: 'W',
        ),
      ],
      groups: [
        grp('g2', 'system.group.electronics', 'Điện tử', 5),
        grp('g1', 'system.group.fashion', 'Thời trang', 1),
      ],
      groupItems: const [
        AttributeGroupItem(id: 'gi1', groupId: 'g1', definitionId: 'd1'),
        AttributeGroupItem(id: 'gi2', groupId: 'g2', definitionId: 'd2'),
      ],
    );
    // fashion (sort 1) before electronics (sort 5).
    expect(groups.map((g) => g.label), ['Thời trang', 'Điện tử']);
    // Enum code is shown as a Vietnamese label, never the raw code.
    expect(groups.first.rows.single.value, 'Cotton');
    expect(groups.first.rows.single.line, 'Chất liệu: Cotton');
    expect(groups.last.rows.single.line, 'Công suất: 350 W');
  });

  test('NO EAV / code / id / scope leaks into the display rows', () {
    final groups = buildAttributeDisplayGroups(
      values: [val('def-electron', '220')],
      definitions: [
        def(
          'def-electron',
          'system.voltage',
          AttributeType.integer,
          label: 'Điện áp',
          unit: 'V',
        ),
      ],
      groups: [grp('g1', 'system.group.electronics', 'Điện tử', 0)],
      groupItems: const [
        AttributeGroupItem(
          id: 'gi1',
          groupId: 'g1',
          definitionId: 'def-electron',
        ),
      ],
    );
    final row = groups.single.rows.single;
    for (final field in [row.label, row.value, row.line, groups.single.label]) {
      expect(field, isNot(contains('system.voltage')), reason: 'no code');
      expect(
        field,
        isNot(contains('def-electron')),
        reason: 'no definition id',
      );
      expect(field.toLowerCase(), isNot(contains('scope')));
    }
    expect(row.label, 'Điện áp');
    expect(row.value, '220');
  });

  test('a value whose definition is gone is dropped, not shown as raw', () {
    final groups = buildAttributeDisplayGroups(
      values: [val('ghost', 'orphan-value')],
      definitions: const [],
      groups: [grp('g1', 'system.group.custom', 'Khác', 0)],
      groupItems: const [],
    );
    expect(groups, isEmpty);
  });

  group('AI context (§14)', () {
    test('empty attributes ⇒ empty string (no dangling heading)', () {
      expect(
        buildAttributeAiContext(
          values: const [],
          definitions: const [],
          groups: const [],
          groupItems: const [],
        ),
        '',
      );
    });

    test(
      'context is grouped — ## group headings + labelled lines, no codes',
      () {
        final ctx = buildAttributeAiContext(
          values: [val('d1', 'cotton'), val('d2', '350')],
          definitions: [
            def(
              'd1',
              'system.material',
              AttributeType.enumType,
              label: 'Chất liệu',
              options: const ['cotton'],
            ),
            def(
              'd2',
              'system.wattage',
              AttributeType.decimal,
              label: 'Công suất',
              unit: 'W',
            ),
          ],
          groups: [
            grp('g1', 'system.group.fashion', 'Thời trang', 1),
            grp('g2', 'system.group.electronics', 'Điện tử', 5),
          ],
          groupItems: const [
            AttributeGroupItem(id: 'gi1', groupId: 'g1', definitionId: 'd1'),
            AttributeGroupItem(id: 'gi2', groupId: 'g2', definitionId: 'd2'),
          ],
        );
        expect(ctx, contains('## Thời trang'));
        expect(ctx, contains('- Chất liệu: Cotton'));
        expect(ctx, contains('## Điện tử'));
        expect(ctx, contains('- Công suất: 350 W'));
        // Not a raw key/value dump and no internal metadata.
        expect(ctx, isNot(contains('system.material')));
        expect(ctx, isNot(contains('definitionId')));
      },
    );
  });
}
