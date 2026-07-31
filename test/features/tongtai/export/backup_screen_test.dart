import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/export/backup_crypto.dart';
import 'package:tongtai/features/tongtai/export/backup_service.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorites_store.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_backup_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_backup_screen.dart';

import '../../../support/pump_until.dart';

/// WTM-164 — the restore **flow**, on the real screen over a real SQLite file.
///
/// The engine suite proves the rules; this one proves a seller cannot trip
/// over them: a bad file explains itself and offers no destructive button, and
/// a good one replaces nothing until an explicit confirmation.
///
/// **Every real read/write goes through `tester.runAsync`.** `testWidgets`
/// runs its body in a fake-async zone where SQLite and file futures never
/// complete — work that touches the disk has to be handed to the real clock.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppDatabase db;
  late TongtaiBackupRepositories repos;
  late _MemoryVault vault;
  late TongtaiBackupService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tongtai-backup-ui-');
    db = AppDatabase.forExecutor(NativeDatabase(File('${tempDir.path}/t.db')));
    repos = TongtaiBackupRepositories(
      database: db,
      customers: DriftCustomerRepository(db),
      products: DriftProductRepository(db),
      orders: DriftOrderRepository(db),
      goals: DriftBusinessGoalRepository(db),
      finance: DriftFinanceRepository(db),
      favourites: DriftSupplierFavoritesStore(db),
    );
    vault = _MemoryVault();
    service = TongtaiBackupService(
      repositories: repos,
      crypto: const BackupCrypto(iterations: 100),
      vault: vault,
      clock: () => DateTime(2026, 7, 31, 14),
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Customer customer(String id) => Customer(
    id: id,
    name: 'Khách $id',
    phone: '090$id',
    location: 'Hà Nội',
    orderCount: 0,
    totalSpent: 0,
    lastPurchaseDate: null,
  );

  Product product(String id) => Product(
    id: id,
    sku: 'SKU-$id',
    name: 'Sản phẩm $id',
    category: 'Chung',
    quantity: 5,
    pricePerUnit: 10000,
    reorderLevel: 1,
    updatedAt: DateTime(2026, 7, 20),
  );

  Future<T> real<T>(WidgetTester tester, Future<T> Function() body) async {
    late T value;
    await tester.runAsync(() async => value = await body());
    return value;
  }

  /// Writes a backup holding [customers] customers, then leaves the live
  /// database holding one product instead — so a successful restore shows up
  /// as a *change*, not a coincidence.
  Future<String> setUpFixture(WidgetTester tester, int customers) =>
      real(tester, () async {
        await repos.customers.upsertAll([
          for (var i = 0; i < customers; i++) customer('b$i'),
        ]);
        final armored = await service.createBackup();
        final path = '${tempDir.path}/backup.ttbk';
        await File(path).writeAsString(armored);
        await repos.customers.deleteAll();
        await repos.products.upsertAll([product('p1')]);
        return path;
      });

  /// Mirrors production (choose a file, then read it) while keeping dart:io
  /// out of the widget — see [TongtaiPickedBackup].
  Future<TongtaiPickedBackup?> Function() picker(String path) =>
      () async => TongtaiPickedBackup(
        path: path,
        content: await File(path).readAsString(),
      );

  Future<void> pumpScreen(
    WidgetTester tester,
    String path, {
    double textScale = 1.0,
    Size size = const Size(400, 900),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tongtaiBackupServiceProvider.overrideWithValue(service),
          tongtaiBackupRepositoriesProvider.overrideWithValue(repos),
        ],
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('vi')],
            home: TongtaiBackupScreen(pickFile: picker(path)),
          ),
        ),
      ),
    );
    await tester.pump();
    // At 320 px with a large text scale the button sits below the fold, and a
    // ListView does not build what it has not scrolled to.
    final pick = find.byKey(const Key('backup-action-pick'));
    if (pick.evaluate().isEmpty) {
      // `scrollUntilVisible` needs to be told WHICH scrollable once a dialog
      // or nested scroll view is also in the tree.
      await tester.scrollUntilVisible(
        pick,
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(pick);
    await tester.pump();
    await tester.tap(pick);
  }

  testWidgets('a valid file previews its contents and touches nothing', (
    tester,
  ) async {
    final path = await setUpFixture(tester, 3);

    await pumpScreen(tester, path);
    await pumpUntilFound(tester, find.byKey(const Key('backup-preview')));

    // Everything the preview is required to show.
    expect(find.byKey(const Key('backup-compatible')), findsOneWidget);
    expect(find.byKey(const Key('backup-count-customers')), findsOneWidget);
    expect(find.byKey(const Key('backup-count-orders')), findsOneWidget);
    expect(find.byKey(const Key('backup-count-favourites')), findsOneWidget);
    expect(find.byKey(const Key('backup-replace-warning')), findsOneWidget);
    expect(find.byKey(const Key('backup-action-replace')), findsOneWidget);

    expect(
      await real(tester, () => repos.customers.loadAll()),
      isEmpty,
      reason: 'a preview must not touch the database',
    );
    expect(await real(tester, () => repos.products.loadAll()), hasLength(1));
  });

  testWidgets('replacing needs an explicit yes, then reports the safety copy', (
    tester,
  ) async {
    final path = await setUpFixture(tester, 3);

    await pumpScreen(tester, path);
    await pumpUntilFound(tester, find.byKey(const Key('backup-preview')));

    // The destructive button sits at the bottom of the preview — scroll it
    // into view, exactly as a seller would have to.
    final replace = find.byKey(const Key('backup-action-replace'));
    await tester.ensureVisible(replace);
    await tester.pumpAndSettle();
    await tester.tap(replace);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('backup-confirm-replace')),
      findsOneWidget,
      reason: 'a destructive action needs a second, explicit yes',
    );
    expect(
      await real(tester, () => repos.customers.loadAll()),
      isEmpty,
      reason: 'nothing happens until that yes',
    );

    await tester.tap(find.byKey(const Key('backup-confirm-replace')));
    await pumpUntilFound(tester, find.byKey(const Key('backup-restore-done')));

    expect(await real(tester, () => repos.customers.loadAll()), hasLength(3));
    expect(
      await real(tester, () => repos.products.loadAll()),
      isEmpty,
      reason: 'Replace means the business becomes the snapshot, exactly',
    );
    expect(find.byKey(const Key('backup-safety-path')), findsOneWidget);
    expect(vault.files, hasLength(1));

    // The safety copy must hold what was there BEFORE (the product), or it is
    // a comforting file that restores nothing.
    final safety = await real(
      tester,
      () => service.validate(vault.files.values.single),
    );
    expect(safety.isRestorable, isTrue, reason: '${safety.issues}');
    expect(safety.contents!.counts['products'], 1);
  });

  testWidgets('the safety copy can be opened back up from inside the app', (
    tester,
  ) async {
    // WTM-173: the safety copy lands in the app's private documents directory,
    // where the system file picker cannot reach it. Without this path, the one
    // file that exists to undo a mistaken restore is the one file the seller
    // cannot open.
    final path = await setUpFixture(tester, 3);

    await pumpScreen(tester, path);
    await pumpUntilFound(tester, find.byKey(const Key('backup-preview')));
    final replace = find.byKey(const Key('backup-action-replace'));
    await tester.ensureVisible(replace);
    await tester.pumpAndSettle();
    await tester.tap(replace);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backup-confirm-replace')));
    await pumpUntilFound(tester, find.byKey(const Key('backup-restore-done')));

    // The business is now the snapshot: 3 customers, no products.
    expect(await real(tester, () => repos.products.loadAll()), isEmpty);

    final undo = find.byKey(const Key('backup-action-undo'));
    await tester.ensureVisible(undo);
    await tester.pumpAndSettle();
    await tester.tap(undo);
    await pumpUntilFound(tester, find.byKey(const Key('backup-preview')));

    expect(
      find.byKey(const Key('backup-action-replace')),
      findsOneWidget,
      reason:
          'the safety copy comes back as a PREVIEW — undoing a destructive '
          'action with one tap is the same mistake pointing the other way',
    );
    expect(
      await real(tester, () => repos.products.loadAll()),
      isEmpty,
      reason: 'opening the safety copy must not itself replace anything',
    );

    // Confirming does bring the product back.
    final replaceAgain = find.byKey(const Key('backup-action-replace'));
    await tester.ensureVisible(replaceAgain);
    await tester.pumpAndSettle();
    await tester.tap(replaceAgain);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backup-confirm-replace')));
    await pumpUntilFound(tester, find.byKey(const Key('backup-restore-done')));

    expect(
      await real(tester, () => repos.products.loadAll()),
      hasLength(1),
      reason: 'the safety copy held the business as it was before the restore',
    );
  });

  testWidgets('a rejected file explains itself and offers no destructive '
      'button', (tester) async {
    final path = '${tempDir.path}/not-a-backup.ttbk';
    await real(tester, () async {
      await repos.customers.upsertAll([customer('c1')]);
      await File(path).writeAsString('xin chào, đây không phải backup');
    });

    await pumpScreen(tester, path);
    await pumpUntilFound(tester, find.byKey(const Key('backup-rejected')));

    expect(find.byKey(const Key('backup-rejected-reason')), findsOneWidget);
    expect(
      find.byKey(const Key('backup-action-replace')),
      findsNothing,
      reason: 'there must be no path from a bad file to a destructive action',
    );
    expect(find.byKey(const Key('backup-replace-warning')), findsNothing);
    expect(await real(tester, () => repos.customers.loadAll()), hasLength(1));
  });

  testWidgets('an encrypted file asks for the passphrase instead of calling '
      'itself broken', (tester) async {
    final path = '${tempDir.path}/encrypted.ttbk';
    await real(tester, () async {
      await repos.customers.upsertAll([customer('c1')]);
      final armored = await service.createBackup(passphrase: 'mat-khau');
      await File(path).writeAsString(armored);
    });

    await pumpScreen(tester, path);
    await pumpUntilFound(tester, find.byKey(const Key('backup-rejected')));

    // Version and date are readable WITHOUT the passphrase, and the screen
    // names what is missing rather than declaring the file damaged.
    expect(find.byKey(const Key('backup-action-unlock')), findsOneWidget);
    expect(find.byKey(const Key('backup-action-replace')), findsNothing);
    expect(find.byKey(const Key('backup-replace-warning')), findsNothing);
    // Actually decrypting is covered end-to-end in backup_restore_test.dart:
    // AES-GCM via `cryptography` does not complete inside testWidgets'
    // fake-async zone, so driving it from here would hang rather than assert.
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
