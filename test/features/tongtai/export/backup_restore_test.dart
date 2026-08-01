import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/finance/finance_category.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_history.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/export/backup_crypto.dart';
import 'package:tongtai/features/tongtai/export/backup_format.dart';
import 'package:tongtai/features/tongtai/export/backup_service.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_history.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/journey/journey_repository.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_reaction_repository.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorites_store.dart';
import 'package:tongtai/features/tongtai/profile/business_profile_repository.dart';

/// WTM-164 / ADR-TON-018 — `.ttbk` v2 backup and **Replace** restore, on a
/// real SQLite file.
///
/// The v1 format could not do this: it was one encrypted CSV of one dataset,
/// it dropped `order.id` and `OrderItem.productId` entirely, and it stored
/// enums as Vietnamese display labels. Every test here exists because a
/// restore built on that would have destroyed a business quietly.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File dbFile;
  late AppDatabase db;
  late TongtaiBackupRepositories repos;
  late _MemoryVault vault;
  late TongtaiBackupService service;

  /// A fast crypto — 150k PBKDF2 rounds would make the suite crawl. The
  /// iteration count travels inside the container, so this changes nothing
  /// about what is being tested.
  const fastCrypto = BackupCrypto(iterations: 100);

  /// Mirrors [tongtaiBackupRepositoriesProvider] — **every** slot filled.
  ///
  /// It did not, once. The optional slots were left null here, so the whole
  /// restore suite exercised the "no profile / no journey" path and stayed
  /// green while production shipped backups that carried neither (WTM-190).
  /// A test bundle that is smaller than the real one tests a product nobody
  /// runs.
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
      );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tongtai-backup-');
    dbFile = File('${tempDir.path}/tongtai.db');
    db = AppDatabase.forExecutor(NativeDatabase(dbFile));
    repos = reposFor(db);
    vault = _MemoryVault();
    service = TongtaiBackupService(
      repositories: repos,
      crypto: fastCrypto,
      vault: vault,
      clock: () => DateTime(2026, 7, 31, 13, 45),
      randomId: () => 'test-backup-id',
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  // ── fixtures: every field populated, so "lossless" means something ────────

  Customer customer(String id, String name) => Customer(
    id: id,
    name: name,
    phone: '0901234567',
    location: 'Hà Nội',
    orderCount: 2,
    totalSpent: 1500000.5,
    lastPurchaseDate: DateTime(2026, 7, 20),
    email: '$id@example.com',
    addresses: const ['12 Hàng Bông', '3 Lê Lợi'],
    segments: const ['khách quen'],
    tags: const ['vip', 'giao nhanh'],
    notes: 'Thích giao buổi sáng',
    history: [
      CustomerRevision(
        timestamp: DateTime(2026, 7, 1, 8, 30),
        changes: const [
          CustomerFieldChange(
            field: CustomerField.phone,
            before: '0900000000',
            after: '0901234567',
          ),
        ],
      ),
    ],
  );

  Product product(String id) => Product(
    id: id,
    sku: 'SKU-$id',
    name: 'Cà phê $id',
    category: 'Đồ uống',
    quantity: 12,
    pricePerUnit: 85000.5,
    reorderLevel: 5,
    updatedAt: DateTime(2026, 7, 25, 10),
    description: 'Rang mộc',
    imagePaths: ['/images/$id.jpg'],
    history: [
      ProductRevision(
        timestamp: DateTime(2026, 7, 2, 9),
        changes: const [
          ProductFieldChange(
            field: ProductField.quantity,
            before: '10',
            after: '12',
          ),
        ],
      ),
    ],
  );

  CustomerOrder order(String id, String customerId, String productId) =>
      CustomerOrder(
        id: id,
        customerId: customerId,
        orderNumber: 'DH-2026-$id',
        date: DateTime(2026, 7, 22, 14, 5),
        status: OrderStatus.delivered,
        items: [
          OrderItem(
            productId: productId,
            productName: 'Cà phê $productId',
            sku: 'SKU-$productId',
            category: 'Đồ uống',
            unit: 'gói',
            quantity: 3,
            unitPrice: 85000.5,
          ),
        ],
      );

  BusinessGoal goal(String id) => BusinessGoal(
    id: id,
    name: 'Doanh thu tháng 8',
    type: GoalType.revenue,
    targetAmount: 50000000,
    achievedAmount: 12000000,
    growthTarget: 20,
    growthAchieved: 5,
    startDate: DateTime(2026, 8),
    endDate: DateTime(2026, 8, 31),
    notes: 'Đẩy mạnh kênh online',
    createdAt: DateTime(2026, 7, 28),
    updatedAt: DateTime(2026, 7, 30),
  );

  FinanceTransaction txn(String id) => FinanceTransaction(
    id: id,
    type: TransactionType.expense,
    category: FinanceCategory.productCost,
    amount: 2500000.75,
    date: DateTime(2026, 7, 26),
    description: 'Nhập 20kg cà phê',
    paymentMethod: 'Chuyển khoản',
  );

  Future<void> seedBusiness() async {
    await repos.customers.upsertAll([
      customer('c1', 'Chị Lan'),
      customer('c2', 'Anh Dũng'),
    ]);
    await repos.products.upsertAll([product('p1'), product('p2')]);
    await repos.orders.upsertAll([
      order('o1', 'c1', 'p1'),
      order('o2', 'c2', 'p2'),
    ]);
    await repos.goals.upsertAll([goal('g1')]);
    await repos.finance.addAll([txn('t1'), txn('t2')]);
    await repos.favourites.add('sup-1', addedAt: DateTime(2026, 7, 10));
  }

  Future<Map<String, int>> liveCounts(TongtaiBackupRepositories r) async => {
    'customers': (await r.customers.loadAll()).length,
    'products': (await r.products.loadAll()).length,
    'orders': (await r.orders.loadAll()).length,
    'goals': (await r.goals.loadAll()).length,
    'transactions': (await r.finance.loadAll()).length,
    'favourites': (await r.favourites.loadAll()).length,
  };

  // ── round trip ───────────────────────────────────────────────────────────

  group('round trip over a real SQLite file', () {
    test('all six datasets come back exactly — every field', () async {
      await seedBusiness();
      final armored = await service.createBackup();
      final before = await service.validate(armored);
      expect(before.isRestorable, isTrue, reason: '${before.issues}');

      // Wipe the business the hard way, then restore.
      await repos.orders.deleteAll();
      await repos.customers.deleteAll();
      await repos.products.deleteAll();
      await repos.goals.deleteAll();
      await repos.finance.deleteAll();
      await repos.favourites.deleteAll();
      expect(await liveCounts(repos), {
        'customers': 0,
        'products': 0,
        'orders': 0,
        'goals': 0,
        'transactions': 0,
        'favourites': 0,
      });

      await service.restore(await service.validate(armored));

      final customers = await repos.customers.loadAll();
      final products = await repos.products.loadAll();
      final orders = await repos.orders.loadAll();
      final goals = await repos.goals.loadAll();
      final transactions = await repos.finance.loadAll();
      final favourites = await repos.favourites.loadAll();

      expect(customers, hasLength(2));
      final lan = customers.firstWhere((c) => c.id == 'c1');
      expect(lan.name, 'Chị Lan');
      expect(lan.phone, '0901234567');
      expect(lan.email, 'c1@example.com');
      expect(lan.addresses, ['12 Hàng Bông', '3 Lê Lợi']);
      expect(lan.segments, ['khách quen']);
      expect(lan.tags, ['vip', 'giao nhanh']);
      expect(lan.notes, 'Thích giao buổi sáng');
      expect(lan.totalSpent, 1500000.5, reason: 'money must not be rounded');
      expect(lan.lastPurchaseDate, DateTime(2026, 7, 20));
      expect(
        lan.history,
        isEmpty,
        reason:
            'edit history is documented as NOT persisted (regenerable session '
            'state — see DriftCustomerRepository). The backup faithfully '
            'reproduces what the app stores; it does not invent history the '
            'database never kept. The codec itself round-trips history — see '
            'the codec test below.',
      );

      final coffee = products.firstWhere((p) => p.id == 'p1');
      expect(coffee.description, 'Rang mộc');
      expect(coffee.imagePaths, ['/images/p1.jpg']);
      expect(coffee.pricePerUnit, 85000.5);
      expect(coffee.history, isEmpty, reason: 'as above — not persisted');

      final first = orders.firstWhere((o) => o.id == 'o1');
      expect(
        first.id,
        'o1',
        reason: 'v1 CSV dropped order.id entirely — v2 must not',
      );
      expect(first.status, OrderStatus.delivered);
      expect(
        first.items.single.productId,
        'p1',
        reason: 'the Inventory↔Orders link ADR-TON-010 requires',
      );
      expect(first.items.single.sku, 'SKU-p1');
      expect(first.items.single.unit, 'gói');
      expect(first.items.single.unitPrice, 85000.5);

      expect(goals.single.type, GoalType.revenue);
      expect(goals.single.notes, 'Đẩy mạnh kênh online');
      expect(transactions, hasLength(2));
      expect(transactions.first.type, TransactionType.expense);
      expect(transactions.first.amount, 2500000.75);
      expect(favourites.single.supplierId, 'sup-1');
    });

    test('enums travel as canonical codes, never display labels', () async {
      await seedBusiness();
      final armored = await service.createBackup();
      final body = armored.substring(kBackupV2Header.length);
      final payload = utf8.decode(
        base64Decode(jsonDecode(body)['payload'] as String),
      );

      expect(payload, contains('"status":"delivered"'));
      expect(payload, contains('"type":"expense"'));
      expect(
        payload,
        isNot(contains('Đã giao')),
        reason: 'a Vietnamese label in a backup breaks an English build',
      );
      expect(payload, isNot(contains('Chi tiêu')));
    });

    test('an encrypted backup round-trips with its passphrase', () async {
      await seedBusiness();
      final armored = await service.createBackup(passphrase: 'mat-khau-manh');
      expect(
        armored,
        isNot(contains('Chị Lan')),
        reason: 'business content must not be readable in the file',
      );

      final needsPass = await service.validate(armored);
      expect(needsPass.firstProblem, BackupProblem.passphraseRequired);
      expect(
        needsPass.manifest,
        isNotNull,
        reason: 'version + date must be readable without the passphrase',
      );

      final wrong = await service.validate(armored, passphrase: 'sai-mat-khau');
      expect(wrong.firstProblem, BackupProblem.wrongPassphrase);

      final ok = await service.validate(armored, passphrase: 'mat-khau-manh');
      expect(ok.isRestorable, isTrue, reason: '${ok.issues}');
      expect(ok.contents!.counts['orders'], 2);
    });

    test('restored data survives closing and reopening the database', () async {
      await seedBusiness();
      final armored = await service.createBackup();
      await repos.orders.deleteAll();
      await repos.customers.deleteAll();
      await service.restore(await service.validate(armored));
      await db.close();

      // A brand-new AppDatabase over the SAME file — the app "restarting".
      final reopened = AppDatabase.forExecutor(NativeDatabase(dbFile));
      addTearDown(reopened.close);
      final after = reposFor(reopened);
      expect(await liveCounts(after), {
        'customers': 2,
        'products': 2,
        'orders': 2,
        'goals': 1,
        'transactions': 2,
        'favourites': 1,
      });
      db = reopened; // let tearDown close it exactly once
    });
  });

  // ── validation refuses, without touching the database ────────────────────

  group('a file that does not validate never reaches the database', () {
    /// Seeds once, then proves a bad file changes nothing. Callers seed
    /// themselves when they need a backup of the seeded state first — finance
    /// is insert-only (`addAll`), so seeding twice is a UNIQUE violation, not
    /// a no-op.
    Future<void> expectUntouched(
      Future<BackupValidation> Function() run, {
      bool seed = true,
    }) async {
      if (seed) await seedBusiness();
      final before = await liveCounts(repos);
      final validation = await run();
      expect(validation.isRestorable, isFalse);
      expect(
        await liveCounts(repos),
        before,
        reason: 'validation must be read-only',
      );
      await expectLater(
        service.restore(validation),
        throwsA(isA<BackupRestoreException>()),
      );
      expect(
        await liveCounts(repos),
        before,
        reason: 'restore must refuse a file that did not validate',
      );
    }

    test('a v1 .ttbk is not a v2 backup', () async {
      final v1 = await fastCrypto.encryptArmored('id,ten\r\nc1,Lan\r\n', 'x');
      await expectUntouched(() => service.validate(v1));
    });

    test('random text is not a backup', () async {
      await expectUntouched(() => service.validate('xin chào'));
    });

    test('a newer format version is blocked, not guessed at', () async {
      await seedBusiness();
      final armored = await service.createBackup();
      final tampered = _withManifest(armored, (m) => m..['formatVersion'] = 99);
      final validation = await service.validate(tampered);
      expect(validation.firstProblem, BackupProblem.tooNew);
      expect(validation.compatibility, BackupCompatibility.tooNew);
      expect(
        validation.manifest,
        isNotNull,
        reason: 'the preview still has to explain WHY it is blocked',
      );
    });

    test('a newer content schema is blocked', () async {
      await seedBusiness();
      final armored = await service.createBackup();
      final tampered = _withManifest(
        armored,
        (m) => m..['contentSchemaVersion'] = 99,
      );
      expect(
        (await service.validate(tampered)).firstProblem,
        BackupProblem.tooNew,
      );
    });

    test('a corrupt checksum is caught', () async {
      await seedBusiness();
      final armored = await service.createBackup();
      final tampered = _withManifest(
        armored,
        (m) => m..['payloadSha256'] = 'deadbeef',
      );
      await expectUntouched(() => service.validate(tampered), seed: false);
      expect(
        (await service.validate(tampered)).firstProblem,
        BackupProblem.checksumMismatch,
      );
    });

    test('a truncated payload is caught before hashing', () async {
      await seedBusiness();
      final armored = await service.createBackup();
      final body = jsonDecode(armored.substring(kBackupV2Header.length)) as Map;
      final bytes = base64Decode(body['payload'] as String);
      body['payload'] = base64Encode(bytes.sublist(0, bytes.length ~/ 2));
      final truncated = '$kBackupV2Header${jsonEncode(body)}';
      expect(
        (await service.validate(truncated)).firstProblem,
        BackupProblem.truncated,
      );
    });

    test(
      'a missing dataset is not a partial import — it is a refusal',
      () async {
        final armored = await _payloadEdited(service, (payload) {
          (payload['datasets'] as Map).remove('goals');
          (payload['counts'] as Map).remove('goals');
        }, seed: seedBusiness);
        final validation = await service.validate(armored);
        expect(validation.firstProblem, BackupProblem.missingDataset);
        expect(validation.issues.single.dataset, 'goals');
      },
    );

    test('a duplicate id is caught', () async {
      final armored = await _payloadEdited(service, (payload) {
        final customers = (payload['datasets'] as Map)['customers'] as List;
        customers.add(Map<String, Object?>.from(customers.first as Map));
        (payload['counts'] as Map)['customers'] = customers.length;
      }, seed: seedBusiness);
      expect(
        (await service.validate(armored)).firstProblem,
        BackupProblem.duplicateId,
      );
    });

    test('an order pointing at a missing customer is caught up front', () async {
      // This is the one that would otherwise blow up mid-transaction: the real
      // database enforces orders.customer_id, so the wipe would already have
      // happened by the time SQLite objected.
      final armored = await _payloadEdited(service, (payload) {
        final customers = (payload['datasets'] as Map)['customers'] as List;
        customers.removeWhere((c) => (c as Map)['id'] == 'c1');
        (payload['counts'] as Map)['customers'] = customers.length;
      }, seed: seedBusiness);
      expect(
        (await service.validate(armored)).firstProblem,
        BackupProblem.brokenForeignKey,
      );
    });

    test('an unknown enum code is an invalid record, not a default', () async {
      final armored = await _payloadEdited(service, (payload) {
        final orders = (payload['datasets'] as Map)['orders'] as List;
        (orders.first as Map)['status'] = 'teleported';
      }, seed: seedBusiness);
      final validation = await service.validate(armored);
      expect(validation.firstProblem, BackupProblem.invalidRecord);
      expect(validation.issues.single.dataset, 'orders');
    });

    test('declared counts must match the rows actually present', () async {
      final armored = await _payloadEdited(service, (payload) {
        (payload['counts'] as Map)['products'] = 99;
      }, seed: seedBusiness);
      expect(
        (await service.validate(armored)).firstProblem,
        BackupProblem.countMismatch,
      );
    });
  });

  // ── Business Snapshot Package: room reserved, not opened ─────────────────

  group('the package declares what it is and what it holds (WTM-165)', () {
    test('a backup this app writes says so explicitly', () async {
      await seedBusiness();
      final armored = await service.createBackup();
      final manifest = decodeBackupDocument(armored)!.manifest;

      expect(manifest.packageKind, PackageKind.backup);
      expect(manifest.redaction, BackupRedaction.none);
      expect(
        manifest.datasets,
        BackupDatasets.all,
        reason: 'a restorable package carries the whole business',
      );
    });

    test(
      'a package written BEFORE these fields existed still restores',
      () async {
        // The two real backups the Founder already holds were written without
        // packageKind/datasets/redaction. Dropping them on the floor would make
        // this change a data-loss event of its own.
        await seedBusiness();
        final armored = await service.createBackup();
        final legacy = _withManifest(armored, (m) {
          return m
            ..remove('packageKind')
            ..remove('datasets')
            ..remove('redaction');
        });

        final validation = await service.validate(legacy);
        expect(validation.isRestorable, isTrue, reason: '${validation.issues}');
        expect(
          validation.manifest!.packageKind,
          PackageKind.backup,
          reason:
              'that is all the format could produce at the time — a fact, '
              'not a guess',
        );
        expect(validation.manifest!.datasets, BackupDatasets.all);
      },
    );

    test(
      'a reserved kind is identified and refused, never guessed at',
      () async {
        await seedBusiness();
        final armored = await service.createBackup();
        for (final kind in [
          PackageKind.clone,
          PackageKind.demoDataset,
          PackageKind.supportBundle,
          PackageKind.analyticsExchange,
        ]) {
          final tagged = _withManifest(
            armored,
            (m) => m..['packageKind'] = kind.code,
          );
          final validation = await service.validate(tagged);
          expect(
            validation.firstProblem,
            BackupProblem.notRestorableKind,
            reason: '${kind.code} has no restore rules yet',
          );
          expect(
            validation.manifest!.packageKind,
            kind,
            reason: 'the preview must still be able to say WHAT it is',
          );
        }
      },
    );

    test(
      'a kind from a newer app parses as unknown, not as a backup',
      () async {
        await seedBusiness();
        final armored = await service.createBackup();
        final future = _withManifest(
          armored,
          (m) => m..['packageKind'] = 'time-machine',
        );
        final validation = await service.validate(future);
        expect(validation.manifest!.packageKind, PackageKind.unknown);
        expect(validation.firstProblem, BackupProblem.notRestorableKind);
      },
    );

    test('a redacted package is readable but never restorable', () async {
      await seedBusiness();
      final armored = await service.createBackup();
      final redacted = _withManifest(
        armored,
        (m) => m..['redaction'] = 'personal-data',
      );
      final validation = await service.validate(redacted);
      expect(validation.firstProblem, BackupProblem.redactedPackage);
      expect(
        validation.manifest!.redaction,
        BackupRedaction.personalData,
        reason: 'restoring blanks over real customers is the failure mode',
      );
    });

    test('an unknown manifest key is ignored, not fatal', () async {
      // A newer writer adding a field must not turn its packages into
      // "corrupt" for this reader — the version fields gate compatibility.
      await seedBusiness();
      final armored = await service.createBackup();
      final extended = _withManifest(
        armored,
        (m) => m..['somethingFromTheFuture'] = {'a': 1},
      );
      expect((await service.validate(extended)).isRestorable, isTrue);
    });

    test('a partial package is a valid package, just not restorable', () async {
      // Analytics Exchange / Demo Dataset will legitimately carry a subset.
      // The refusal must come from the RESTORE contract, and the manifest must
      // still parse so a reader can see what is inside.
      final armored = await _payloadEdited(service, (payload) {
        (payload['datasets'] as Map).remove('favourites');
        (payload['counts'] as Map).remove('favourites');
      }, seed: seedBusiness);
      final validation = await service.validate(armored);

      expect(validation.manifest, isNotNull);
      expect(validation.firstProblem, BackupProblem.missingDataset);
      expect(validation.issues.single.dataset, 'favourites');
    });
  });

  // ── safety backup + rollback ─────────────────────────────────────────────

  group('nothing is destroyed without a verified safety copy', () {
    test(
      'a verified safety backup is written before anything is deleted',
      () async {
        await seedBusiness();
        final armored = await service.createBackup();
        await repos.finance.deleteAll(); // make "before" differ from the file

        final report = await service.restore(await service.validate(armored));

        expect(vault.files, hasLength(1));
        expect(report.safetyBackupPath, vault.files.keys.single);
        expect(
          report.replacedCounts['transactions'],
          0,
          reason:
              'the safety copy describes what was replaced, not what arrived',
        );
        // The safety copy must itself be restorable — otherwise it is decoration.
        final safety = await service.validate(vault.files.values.single);
        expect(safety.isRestorable, isTrue, reason: '${safety.issues}');
        expect(safety.contents!.counts['transactions'], 0);
      },
    );

    test('an unwritable vault stops the restore before the wipe', () async {
      await seedBusiness();
      final armored = await service.createBackup();
      final before = await liveCounts(repos);

      final failing = TongtaiBackupService(
        repositories: repos,
        crypto: fastCrypto,
        vault: _FailingVault(),
        clock: () => DateTime(2026, 7, 31),
      );
      await expectLater(
        failing.restore(await failing.validate(armored)),
        throwsA(isA<BackupRestoreException>()),
      );
      expect(
        await liveCounts(repos),
        before,
        reason: 'no safety backup ⇒ nothing may be deleted (Founder rule)',
      );
    });

    test('a safety copy that reads back broken stops the restore', () async {
      await seedBusiness();
      final armored = await service.createBackup();
      final before = await liveCounts(repos);

      final corrupting = TongtaiBackupService(
        repositories: repos,
        crypto: fastCrypto,
        vault: _CorruptingVault(),
        clock: () => DateTime(2026, 7, 31),
      );
      await expectLater(
        corrupting.restore(await corrupting.validate(armored)),
        throwsA(isA<BackupRestoreException>()),
      );
      expect(await liveCounts(repos), before);
    });

    test('a failure during apply rolls the whole business back', () async {
      await seedBusiness();
      final armored = await service.createBackup();
      final before = await liveCounts(repos);
      final beforeCustomers = await repos.customers.loadAll();

      // A repository that dies part-way through the write — after the wipe,
      // which is precisely the window a non-atomic restore would lose data in.
      final exploding = TongtaiBackupService(
        repositories: TongtaiBackupRepositories(
          database: db,
          customers: repos.customers,
          products: repos.products,
          orders: _ExplodingOrderRepository(DriftOrderRepository(db)),
          goals: repos.goals,
          finance: repos.finance,
          favourites: repos.favourites,
        ),
        crypto: fastCrypto,
        vault: vault,
        clock: () => DateTime(2026, 7, 31),
      );

      await expectLater(
        exploding.restore(await exploding.validate(armored)),
        throwsA(anything),
      );

      expect(
        await liveCounts(repos),
        before,
        reason: 'the transaction must roll back completely',
      );
      final after = await repos.customers.loadAll();
      expect(
        after.map((c) => c.id).toSet(),
        beforeCustomers.map((c) => c.id).toSet(),
      );
    });
  });

  // ── privacy ──────────────────────────────────────────────────────────────

  group('opportunity reactions (WTM-190)', () {
    test('a save and a dismissal survive a full backup → restore', () async {
      final reactions = OpportunityReactionRepository(db);
      await reactions.save('opp-keep', OpportunityReaction.saved);
      await reactions.save('opp-hide', OpportunityReaction.dismissed);

      final document = await service.createBackup();
      await reactions.deleteAll();

      await service.restore(await service.validate(document));

      expect(await reactions.loadAll(), {
        'opp-keep': OpportunityReaction.saved,
        'opp-hide': OpportunityReaction.dismissed,
      });
    });

    test('Replace drops the previous business decisions', () async {
      // ADR-TON-018: the incoming business wins. Keeping the old seller's
      // dismissals would silently hide opportunities from the new one.
      final reactions = OpportunityReactionRepository(db);
      final document = await service.createBackup();
      await reactions.save('someone-elses', OpportunityReaction.dismissed);

      await service.restore(await service.validate(document));

      expect(await reactions.loadAll(), isEmpty);
    });

    test('a .ttbk written before reactions existed still restores', () async {
      // The dataset is optional on purpose. If it were required, every file a
      // seller made yesterday would stop restoring today.
      final document = await service.createBackup();
      expect(document.contains(BackupDatasets.opportunityReactions), isFalse);

      final report = await service.restore(await service.validate(document));

      expect(report.restored, isNotEmpty);
    });
  });

  group('privacy (negative control)', () {
    test(
      'issues carry codes and row numbers, never business content',
      () async {
        final armored = await _payloadEdited(service, (payload) {
          final customers = (payload['datasets'] as Map)['customers'] as List;
          (customers.first as Map)['orderCount'] = 'không phải số';
        }, seed: seedBusiness);
        final validation = await service.validate(armored);

        final rendered = validation.issues.map((i) => i.toString()).join(' ');
        expect(rendered, contains('invalidRecord'));
        expect(rendered, isNot(contains('Chị Lan')));
        expect(rendered, isNot(contains('0901234567')));
        expect(rendered, isNot(contains('1500000')));
      },
    );

    test('a restore exception names the problem, not the data', () async {
      await seedBusiness();
      final validation = await service.validate('không phải backup');
      try {
        await service.restore(validation);
        fail('expected a refusal');
      } on BackupRestoreException catch (e) {
        expect(e.toString(), contains('notABackup'));
        expect(e.toString(), isNot(contains('Chị Lan')));
      }
    });

    test('the plaintext manifest leaks no counts and no content', () async {
      await seedBusiness();
      final armored = await service.createBackup(passphrase: 'mat-khau');
      final manifestJson = jsonEncode(
        (jsonDecode(armored.substring(kBackupV2Header.length))
            as Map)['manifest'],
      );
      expect(manifestJson, contains('formatVersion'));
      expect(
        manifestJson,
        isNot(contains('counts')),
        reason: 'record counts belong inside the encrypted payload',
      );
      expect(manifestJson, isNot(contains('Chị Lan')));
    });
  });
}

/// Rewrites the manifest of an armored document, keeping the payload intact.
String _withManifest(
  String armored,
  Map<String, Object?> Function(Map<String, Object?>) edit,
) {
  final body = jsonDecode(armored.substring(kBackupV2Header.length)) as Map;
  body['manifest'] = edit(Map<String, Object?>.from(body['manifest'] as Map));
  return '$kBackupV2Header${jsonEncode(body)}';
}

/// Builds a backup, edits the decoded payload, and re-seals it with a correct
/// checksum — so the test exercises the *content* check, not the hash check.
Future<String> _payloadEdited(
  TongtaiBackupService service,
  void Function(Map<String, Object?> payload) edit, {
  required Future<void> Function() seed,
}) async {
  await seed();
  final armored = await service.createBackup();
  final body = jsonDecode(armored.substring(kBackupV2Header.length)) as Map;
  final payload =
      jsonDecode(utf8.decode(base64Decode(body['payload'] as String)))
          as Map<String, Object?>;
  edit(payload);
  final stored = utf8.encode(jsonEncode(payload));
  final manifest = Map<String, Object?>.from(body['manifest'] as Map)
    ..['payloadSha256'] = backupSha256Hex(stored)
    ..['payloadBytes'] = stored.length;
  return '$kBackupV2Header'
      '${jsonEncode({'manifest': manifest, 'payload': base64Encode(stored)})}';
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

class _FailingVault implements BackupVault {
  @override
  Future<String> write(String label, String armored) async =>
      throw const FileSystemException('no space left on device');

  @override
  Future<String> read(String path) async => throw StateError('never written');
}

/// Writes something that is NOT a restorable backup — the "verify" half of
/// "create and verify a safety backup" is what this proves.
class _CorruptingVault implements BackupVault {
  @override
  Future<String> write(String label, String armored) async => '/vault/$label';

  @override
  Future<String> read(String path) async => 'not a backup at all';
}

/// Fails on the bulk write, after the wipe has already happened.
class _ExplodingOrderRepository implements OrderRepository {
  _ExplodingOrderRepository(this.inner);

  final OrderRepository inner;

  @override
  Future<void> upsertAll(Iterable<CustomerOrder> orders) async =>
      throw StateError('disk gave up mid-restore');

  @override
  Future<List<CustomerOrder>> loadAll() => inner.loadAll();

  @override
  Future<List<CustomerOrder>> loadForCustomer(String customerId) =>
      inner.loadForCustomer(customerId);

  @override
  Future<void> upsert(CustomerOrder order) => inner.upsert(order);

  @override
  Future<void> deleteByIdPrefix(String prefix) =>
      inner.deleteByIdPrefix(prefix);

  @override
  Future<void> deleteAll() => inner.deleteAll();
}
