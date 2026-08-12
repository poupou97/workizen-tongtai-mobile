import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/attribute_models.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/attribute_repository.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/export/backup_crypto.dart';
import 'package:tongtai/features/tongtai/export/backup_service.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/journey/journey_repository.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_reaction_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/producer/business_input_repository.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorites_store.dart';
import 'package:tongtai/features/tongtai/profile/business_profile_repository.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_repository.dart';

/// WTM-334 — the DYNAMIC attribute layer through `.ttbk` v2 (ADR-TON-018):
///
/// 1. backup/restore must **not lose** attributes (governance §20), and
/// 2. a `.ttbk` written before v27 (no attribute datasets) must **still
///    restore** — the four datasets are OPTIONAL, not part of `all` (the
///    WTM-177/ADR-TON-021 lesson).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppDatabase db;
  late AttributeRepository attributes;
  late TongtaiBackupService service;

  const fastCrypto = BackupCrypto(iterations: 100);

  TongtaiBackupRepositories reposFor(AppDatabase database) =>
      TongtaiBackupRepositories(
        database: database,
        customers: DriftCustomerRepository(database),
        products: DriftProductRepository(database),
        orders: DriftOrderRepository(database),
        goals: DriftBusinessGoalRepository(database),
        finance: DriftFinanceRepository(database),
        favourites: DriftSupplierFavoritesStore(database),
        businessProfile: BusinessProfileRepository(database),
        journeys: JourneyRepository(database),
        opportunityReactions: OpportunityReactionRepository(database),
        businessInputs: DriftBusinessInputRepository(database),
        commerce: CommerceRepository(database),
        attributes: AttributeRepository(database),
      );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tongtai-attr-backup-');
    db = AppDatabase.forExecutor(NativeDatabase(File('${tempDir.path}/t.db')));
    attributes = AttributeRepository(db);
    service = TongtaiBackupService(
      repositories: reposFor(db),
      crypto: fastCrypto,
      vault: _MemoryVault(),
      clock: () => DateTime(2026, 8, 12, 20, 0),
      randomId: () => 'attr-backup-id',
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Future<void> seedAttributes() async {
    await attributes.createGroup(
      AttributeGroup(id: 'g1', code: 'system.electronics', label: 'Điện tử'),
    );
    await attributes.createDefinition(
      AttributeDefinition(
        id: 'd1',
        code: 'system.electronics.wattage',
        type: AttributeType.integer,
        label: 'Công suất',
        unit: 'W',
      ),
    );
    await attributes.createDefinition(
      AttributeDefinition(
        id: 'd2',
        code: 'user.materials',
        type: AttributeType.multiEnum,
        label: 'Chất liệu',
        enumOptions: const ['cotton', 'wool'],
      ),
    );
    await attributes.setValue(
      AttributeValue(
        id: 'v1',
        definitionId: 'd1',
        entityType: 'product',
        entityId: 'p1',
        valueRaw: '1200',
      ),
    );
    await attributes.addToGroup(
      const AttributeGroupItem(id: 'gi1', groupId: 'g1', definitionId: 'd1'),
    );
  }

  test(
    'backup then restore keeps every attribute definition/value/group',
    () async {
      await seedAttributes();

      final armored = await service.createBackup();

      // Wipe the attribute layer, then restore — Replace must bring it back.
      await attributes.deleteAll();
      expect(await attributes.loadDefinitions(), isEmpty);

      final validation = await service.validate(armored);
      expect(validation.isRestorable, isTrue, reason: validation.issues.join());
      await service.restore(validation);

      final definitions = await attributes.loadDefinitions();
      expect(
        definitions.map((d) => d.code),
        containsAll(['system.electronics.wattage', 'user.materials']),
      );
      final wattage = definitions.firstWhere((d) => d.id == 'd1');
      expect(wattage.unit, 'W', reason: 'unit survives the round-trip');
      final materials = definitions.firstWhere((d) => d.id == 'd2');
      expect(materials.enumOptions, ['cotton', 'wool']);

      final values = await attributes.loadValuesForEntity('product', 'p1');
      expect(values.single.valueRaw, '1200');
      expect(await attributes.loadGroupItems('g1'), hasLength(1));
    },
  );

  test('a pre-v27 backup with no attribute datasets still restores', () async {
    // A backup taken when no attributes exist omits all four datasets — the
    // shape of every `.ttbk` written before this feature. It must validate and
    // restore, and (Replace) must leave the attribute layer empty rather than
    // rejecting the file for a "missing dataset".
    final legacyArmored = await service.createBackup();

    // Now the live database has attributes; restoring the older file must wipe
    // them (Replace means replace) and must not fail.
    await seedAttributes();
    expect(await attributes.loadDefinitions(), isNotEmpty);

    final validation = await service.validate(legacyArmored);
    expect(
      validation.isRestorable,
      isTrue,
      reason:
          'four optional attribute datasets absent must not make an old file '
          'unrestorable: ${validation.issues.join()}',
    );
    await service.restore(validation);

    expect(await attributes.loadDefinitions(), isEmpty);
    expect(await attributes.loadValuesForEntity('product', 'p1'), isEmpty);
    expect(await attributes.loadGroups(), isEmpty);
  });
}

class _MemoryVault implements BackupVault {
  final Map<String, String> files = {};

  @override
  Future<String> write(String label, String armored) async {
    files['/vault/$label'] = armored;
    return '/vault/$label';
  }

  @override
  Future<String> read(String path) async => files[path]!;
}
