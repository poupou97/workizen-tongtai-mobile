import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/attribute_models.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/attribute_repository.dart';

/// WTM-334 — the DYNAMIC attribute layer's governance rules (spec §20). Each
/// rule is one test, so a regression names exactly which invariant broke. No
/// placebo assertions: every test drives a real refusal or a real cascade.
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
    List<String> options = const [],
  }) => AttributeDefinition(
    id: id,
    code: code,
    type: type,
    label: 'Label',
    enumOptions: options,
  );

  test('duplicate code in the same scope is refused', () async {
    await repo.createDefinition(def('d1', 'user.season', AttributeType.text));
    expect(
      () => repo.createDefinition(def('d2', 'user.season', AttributeType.text)),
      throwsA(isA<DuplicateAttributeCode>()),
    );
    expect(await repo.loadDefinitions(), hasLength(1));
  });

  test('re-importing the same vendor field does not mint a duplicate', () async {
    final incoming = def('d1', 'vendor.shopify.fabric', AttributeType.text);
    // First import creates it; a second run of the same file must be idempotent.
    await repo.ensureDefinition(incoming);
    await repo.ensureDefinition(
      def('d2', 'vendor.shopify.fabric', AttributeType.text),
    );
    final loaded = await repo.loadDefinitions();
    expect(loaded, hasLength(1), reason: 'ensureDefinition is by code');
    expect(loaded.single.id, 'd1', reason: 'the first definition wins');
  });

  test('a dynamic attribute may not shadow a core field', () async {
    for (final leaf in [
      'price',
      'sku',
      'quantity',
      'cost_price',
      'status',
      'kind',
    ]) {
      expect(
        () => repo.createDefinition(
          def('d-$leaf', 'user.$leaf', AttributeType.text),
        ),
        throwsA(isA<AttributeShadowsCoreField>()),
        reason: 'user.$leaf collides with the core field $leaf',
      );
    }
    expect(await repo.loadDefinitions(), isEmpty);
  });

  test('a malformed namespace is refused', () async {
    expect(
      () => repo.createDefinition(def('d1', 'nope', AttributeType.text)),
      throwsA(isA<InvalidAttributeNamespace>()),
    );
    expect(
      () =>
          repo.createDefinition(def('d2', 'vendor.season', AttributeType.text)),
      throwsA(isA<InvalidAttributeNamespace>()),
      reason: 'a vendor code needs vendor.<name>.<leaf>',
    );
  });

  test('an invalid value for the definition type is refused', () async {
    await repo.createDefinition(
      def('d1', 'system.electronics.wattage', AttributeType.integer),
    );
    expect(
      () => repo.setValue(
        AttributeValue(
          id: 'v1',
          definitionId: 'd1',
          entityType: 'product',
          entityId: 'p1',
          valueRaw: 'not-a-number',
        ),
      ),
      throwsA(isA<InvalidAttributeValue>()),
    );
    expect(await repo.loadValuesForEntity('product', 'p1'), isEmpty);
  });

  test('an ENUM / MULTI_ENUM with no options is refused', () async {
    expect(
      () => repo.createDefinition(
        def('d1', 'user.season', AttributeType.enumType),
      ),
      throwsA(isA<InvalidAttributeValue>()),
    );
  });

  test(
    'deleting a definition cascades — no orphan value or membership',
    () async {
      await repo.createDefinition(
        def('d1', 'system.electronics.wattage', AttributeType.integer),
      );
      await repo.createGroup(
        AttributeGroup(id: 'g1', code: 'system.electronics', label: 'Điện tử'),
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
      await repo.addToGroup(
        const AttributeGroupItem(id: 'gi1', groupId: 'g1', definitionId: 'd1'),
      );

      await repo.deleteDefinition('d1');

      expect(
        await repo.loadValuesForEntity('product', 'p1'),
        isEmpty,
        reason: 'the value must go with its definition (cascade)',
      );
      expect(
        await repo.loadGroupItems('g1'),
        isEmpty,
        reason: 'the membership must go with its definition (cascade)',
      );
      expect(
        await repo.loadGroups(),
        hasLength(1),
        reason: 'the group itself survives — only the membership is removed',
      );
    },
  );

  test(
    'a membership pointing at a non-existent definition is rejected by the DB',
    () async {
      await repo.createGroup(
        AttributeGroup(id: 'g1', code: 'system.electronics', label: 'Điện tử'),
      );
      // No definition `ghost` exists — the foreign key must refuse it (787),
      // rather than let a dangling membership sit in the table.
      await expectLater(
        repo.addToGroup(
          const AttributeGroupItem(
            id: 'gi1',
            groupId: 'g1',
            definitionId: 'ghost',
          ),
        ),
        throwsA(anything),
      );
      expect(await repo.loadGroupItems('g1'), isEmpty);
    },
  );

  test(
    'a user attribute may not override a system field of the same leaf',
    () async {
      await repo.createDefinition(
        def('d1', 'system.color', AttributeType.text),
      );
      expect(
        () =>
            repo.createDefinition(def('d2', 'user.color', AttributeType.text)),
        throwsA(isA<UserAttributeOverridesSystem>()),
      );
      expect(await repo.loadDefinitions(), hasLength(1));
    },
  );

  test('every import field lands in exactly one bucket — none swallowed', () {
    final report = classifyAttributeImport(
      vendor: 'shopify',
      fields: ['Screen Size', 'Warranty', 'SKU', ''],
      knownCodes: {'vendor.shopify.screen_size'},
      ignoreFields: {''},
    );

    expect(report.mapped, ['Screen Size'], reason: 'a known code maps');
    expect(report.unmapped, [
      'Warranty',
    ], reason: 'an unknown field is surfaced, never dropped');
    expect(report.ignored, [''], reason: 'an explicitly ignored field');
    expect(report.invalid, [
      'SKU',
    ], reason: 'a field that would shadow a core column is invalid');
    expect(
      report.total,
      4,
      reason: 'mapped + unmapped + ignored + invalid == every field',
    );
  });
}
