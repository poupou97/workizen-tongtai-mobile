import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/attribute_models.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/attribute_repository.dart';

/// WTM-334 — CRUD for the DYNAMIC attribute tier: create / read / delete of
/// definition · value · group through the repository (DoD checkbox 2).
void main() {
  late AppDatabase db;
  late AttributeRepository repo;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    repo = AttributeRepository(db);
  });
  tearDown(() => db.close());

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

  test('create → read → delete a definition', () async {
    await repo.createDefinition(
      def('d1', 'system.electronics.wattage', AttributeType.decimal, unit: 'W'),
    );

    var loaded = await repo.loadDefinitions();
    expect(loaded, hasLength(1));
    expect(loaded.single.code, 'system.electronics.wattage');
    expect(loaded.single.type, AttributeType.decimal);
    expect(loaded.single.unit, 'W');

    await repo.deleteDefinition('d1');
    loaded = await repo.loadDefinitions();
    expect(loaded, isEmpty);
  });

  test('an ENUM definition keeps its options through a round-trip', () async {
    await repo.createDefinition(
      def(
        'd1',
        'user.season',
        AttributeType.enumType,
        options: ['spring', 'summer', 'autumn', 'winter'],
      ),
    );
    final loaded = await repo.loadDefinitions();
    expect(loaded.single.enumOptions, ['spring', 'summer', 'autumn', 'winter']);
  });

  test('set a value, read it back on demand for one entity', () async {
    await repo.createDefinition(
      def('d1', 'system.electronics.wattage', AttributeType.integer, unit: 'W'),
    );
    await repo.setValue(
      AttributeValue(
        id: 'v1',
        definitionId: 'd1',
        entityType: 'product',
        entityId: 'p1',
        valueRaw: '1200',
      ),
    );

    final values = await repo.loadValuesForEntity('product', 'p1');
    expect(values, hasLength(1));
    expect(values.single.valueRaw, '1200');

    // A different product carries none — reads are entity-scoped.
    expect(await repo.loadValuesForEntity('product', 'p2'), isEmpty);
  });

  test('setting a value twice updates in place, never duplicates', () async {
    await repo.createDefinition(
      def('d1', 'user.warranty_months', AttributeType.integer),
    );
    await repo.setValue(
      AttributeValue(
        id: 'v1',
        definitionId: 'd1',
        entityType: 'product',
        entityId: 'p1',
        valueRaw: '12',
      ),
    );
    await repo.setValue(
      AttributeValue(
        id: 'v2', // different id — the (definition, entity) is what matters
        definitionId: 'd1',
        entityType: 'product',
        entityId: 'p1',
        valueRaw: '24',
      ),
    );

    final values = await repo.loadValuesForEntity('product', 'p1');
    expect(values, hasLength(1), reason: 'one value per (definition, entity)');
    expect(values.single.valueRaw, '24');
  });

  test(
    'MULTI_ENUM accepts a subset of its options, rejects a stranger',
    () async {
      await repo.createDefinition(
        def(
          'd1',
          'user.materials',
          AttributeType.multiEnum,
          options: ['cotton', 'wool', 'silk'],
        ),
      );

      await repo.setValue(
        AttributeValue(
          id: 'v1',
          definitionId: 'd1',
          entityType: 'product',
          entityId: 'p1',
          valueRaw: 'cotton,wool',
        ),
      );
      expect(
        (await repo.loadValuesForEntity('product', 'p1')).single.valueRaw,
        'cotton,wool',
      );

      expect(
        () => repo.setValue(
          AttributeValue(
            id: 'v2',
            definitionId: 'd1',
            entityType: 'product',
            entityId: 'p2',
            valueRaw: 'cotton,denim',
          ),
        ),
        throwsA(isA<InvalidAttributeValue>()),
      );
    },
  );

  test('create a group, add a definition to it, read the membership', () async {
    await repo.createDefinition(
      def('d1', 'system.electronics.wattage', AttributeType.decimal),
    );
    await repo.createGroup(
      AttributeGroup(id: 'g1', code: 'system.electronics', label: 'Điện tử'),
    );
    await repo.addToGroup(
      const AttributeGroupItem(id: 'gi1', groupId: 'g1', definitionId: 'd1'),
    );

    final groups = await repo.loadGroups();
    expect(groups.single.code, 'system.electronics');

    final items = await repo.loadGroupItems('g1');
    expect(items, hasLength(1));
    expect(items.single.definitionId, 'd1');

    await repo.deleteGroup('g1');
    expect(await repo.loadGroups(), isEmpty);
  });
}
