import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/l10n/app_strings.dart';
import 'package:tongtai/core/prefs.dart';
import 'package:tongtai/core/telemetry/tongtai_telemetry.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/screen_data_controller.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_consumer_screen.dart';

import '../../../support/pump_until.dart';

/// WTM-148 / ADR-TON-017 — the shared seam **on a real screen**.
///
/// `screen_state_test.dart` proves the model. This file proves the thing the
/// Founder actually asked for: that a screen backed by real SQLite, real
/// Riverpod wiring and its real production widget tells the user the truth
/// when the data path breaks — instead of the empty state that started this
/// whole story ("Home Consumer = 1, tab trống").
///
/// The repository is a thin decorator over a **real `DriftCustomerRepository`**
/// so the rows, the queries and the failure are all genuine; only *when* it
/// fails is under the test's control. No screen-level mocks, no fixture-value
/// assertions.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppDatabase db;
  late _ControllableCustomerRepository repository;
  late _RecordingTelemetry telemetry;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('tongtai-seam-');
    db = AppDatabase.forExecutor(NativeDatabase(File('${tempDir.path}/t.db')));
    repository = _ControllableCustomerRepository(DriftCustomerRepository(db));
    telemetry = _RecordingTelemetry();
    // The default failure is a REAL SQLite error, captured from a genuine
    // foreign-key violation on this database — so the classification under
    // test (`storage`) is the one production would produce, not a label the
    // test chose for itself.
    repository.failure = await _realSqliteFailure(db);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Customer customer(String id, String name) => Customer(
    id: id,
    name: name,
    phone: '',
    location: 'Hà Nội',
    orderCount: 1,
    totalSpent: 1500000,
    lastPurchaseDate: DateTime(2026, 7, 20),
  );

  Future<Widget> host() async => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(
        await SharedPreferences.getInstance(),
      ),
      customerRepositoryProvider.overrideWithValue(repository),
      // The customer list (reached by "view all") reads these too; without the
      // overrides it would open a SECOND real database behind the test.
      productRepositoryProvider.overrideWithValue(DriftProductRepository(db)),
      orderRepositoryProvider.overrideWithValue(DriftOrderRepository(db)),
      tongtaiTelemetryProvider.overrideWithValue(telemetry),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en'), Locale('vi')],
      home: TongtaiConsumerScreen(),
    ),
  );

  Future<void> pump(WidgetTester tester, {Size size = const Size(400, 800)}) {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    return host().then(tester.pumpWidget);
  }

  group('a broken data path is visible, not empty', () {
    testWidgets('a failing read renders the error state — NOT the empty tab', (
      tester,
    ) async {
      await repository.inner.upsert(customer('c1', 'Chị Lan'));
      repository.failNext = 1;

      await pump(tester);
      await pumpUntilFound(tester, find.byKey(const Key('consumer-error')));

      // The regression this story exists for: "could not read" must never be
      // rendered as "there is nothing".
      expect(find.byKey(const Key('consumer-empty')), findsNothing);
      expect(
        find.byKey(const Key('consumer-count-badge')),
        findsNothing,
        reason: 'a count we could not read must not be printed as a number',
      );

      // And it must be diagnosable, not vague (WTM-148 §"no vague message").
      expect(find.byKey(const Key('consumer-error-code')), findsOneWidget);
      expect(find.byKey(const Key('consumer-error-retry')), findsOneWidget);
    });

    testWidgets('the technical detail is available on demand, verbatim', (
      tester,
    ) async {
      repository.failNext = 1;
      repository.failure = StateError('drift: table customers is locked');

      await pump(tester);
      await pumpUntilFound(tester, find.byKey(const Key('consumer-error')));
      expect(find.byKey(const Key('consumer-error-detail')), findsNothing);

      await tester.tap(find.byKey(const Key('consumer-error-detail-toggle')));
      await tester.pump();

      expect(
        find.textContaining('table customers is locked'),
        findsOneWidget,
        reason:
            'WTM-148 forbids trading a real cause for a friendly non-statement',
      );
    });

    testWidgets('retry re-reads and shows the real rows', (tester) async {
      await repository.inner.upsert(customer('c1', 'Chị Lan'));
      await repository.inner.upsert(customer('c2', 'Anh Dũng'));
      repository.failNext = 1;

      await pump(tester);
      await pumpUntilFound(tester, find.byKey(const Key('consumer-error')));

      await tester.tap(find.byKey(const Key('consumer-error-retry')));
      await pumpUntilFound(
        tester,
        find.byKey(const Key('consumer-count-badge')),
      );

      // Real rows from real SQLite — the count is the repository's, not the
      // test's idea of it.
      final badge = tester.widget<Text>(
        find.byKey(const Key('consumer-count-badge')),
      );
      expect(badge.data, '${(await repository.inner.loadAll()).length}');
    });

    testWidgets('a failed REFRESH keeps the data and says it is stale', (
      tester,
    ) async {
      await repository.inner.upsert(customer('c1', 'Chị Lan'));

      await pump(tester);
      await pumpUntilFound(
        tester,
        find.byKey(const Key('consumer-count-badge')),
      );

      // Break the path, then trigger a refresh the way the screen really does:
      // open the customer list and come back. Two reads fail — the list's own
      // load and the Consumer refresh behind it — which is exactly what a
      // seller with a broken database would hit.
      repository.failNext = 2;
      await tester.tap(find.byKey(const Key('consumer-view-all')));
      await pumpUntilFound(tester, find.byKey(const Key('customer-error')));
      await tester.pageBack();
      await pumpUntilFound(tester, find.byKey(const Key('consumer-stale')));

      expect(
        find.byKey(const Key('consumer-count-badge')),
        findsOneWidget,
        reason: 'a broken refresh must not blank a page that was working',
      );
      expect(find.byKey(const Key('consumer-stale-body')), findsOneWidget);
      expect(find.byKey(const Key('consumer-error')), findsNothing);
    });
  });

  group('the error surface is usable', () {
    testWidgets('renders at 320 px with a 1.3× text scale, no overflow', (
      tester,
    ) async {
      repository.failNext = 1;
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: await host(),
        ),
      );
      await pumpUntilFound(tester, find.byKey(const Key('consumer-error')));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('consumer-error-retry')), findsOneWidget);
    });

    testWidgets('announces itself and offers a real tap target', (
      tester,
    ) async {
      repository.failNext = 1;
      await pump(tester);
      await pumpUntilFound(tester, find.byKey(const Key('consumer-error')));

      final handle = tester.ensureSemantics();
      // A failure that appears after the page has settled has to be announced,
      // or a screen-reader user is left on a page that silently changed.
      final semantics = tester.getSemantics(
        find.byKey(const Key('consumer-error')),
      );
      expect(
        semantics.flagsCollection.isLiveRegion,
        isTrue,
        reason:
            'a failure that appears after the page settled must be announced',
      );

      final retry = tester.getSize(
        find.byKey(const Key('consumer-error-retry')),
      );
      expect(
        retry.height,
        greaterThanOrEqualTo(44),
        reason: 'the recovery affordance must be reachable, not a hairline',
      );
      handle.dispose();
    });

    testWidgets('the wording comes from AppStrings, in one locale', (
      tester,
    ) async {
      repository.failNext = 1;
      await pump(tester);
      await pumpUntilFound(tester, find.byKey(const Key('consumer-error')));

      // Storage failure ⇒ the storage wording, not a generic sentence.
      expect(find.text(const AppStringsEn().errorStorageTitle), findsOneWidget);
      expect(
        find.text(const AppStringsVi().errorStorageTitle),
        findsNothing,
        reason: 'single-locale UI (ADR-TON-007 / P0 §2)',
      );
    });
  });

  group('what the failure reports', () {
    testWidgets('telemetry gets kind + code + screen and no content', (
      tester,
    ) async {
      repository.failNext = 1;
      repository.failure = StateError('customer Chị Lan spent 1.500.000 ₫');

      await pump(tester);
      await pumpUntilFound(tester, find.byKey(const Key('consumer-error')));

      expect(telemetry.events, isNotEmpty);
      final (name, params) = telemetry.events.first;
      expect(name, kScreenErrorEvent);
      expect(params.keys.toSet(), {'kind', 'code', 'screen'});
      expect(params['screen'], 'consumer');
      expect(
        params.values.join(' '),
        isNot(contains('Chị Lan')),
        reason: 'negative control — business content must never be reported',
      );
      expect(
        telemetry.recorded.map((e) => e.toString()).join(' '),
        isNot(contains('1.500.000')),
      );
    });
  });
}

/// A **real** Drift repository with a switch on it.
///
/// Everything the screen touches is production code; only the moment of
/// failure is scripted. That is the difference between proving the screen
/// handles a broken database and proving a mock returns what the test wrote.
class _ControllableCustomerRepository implements CustomerRepository {
  _ControllableCustomerRepository(this.inner);

  final CustomerRepository inner;

  /// How many upcoming reads should fail.
  int failNext = 0;

  /// What they fail with (default: a storage-shaped error).
  Object failure = StateError('database is unavailable');

  @override
  Future<List<Customer>> loadAll() async {
    if (failNext > 0) {
      failNext--;
      throw failure;
    }
    return inner.loadAll();
  }

  @override
  Future<void> upsert(Customer customer) => inner.upsert(customer);

  @override
  Future<void> upsertAll(Iterable<Customer> customers) =>
      inner.upsertAll(customers);

  @override
  Future<void> deleteByIdPrefix(String prefix, {Set<String> keep = const {}}) =>
      inner.deleteByIdPrefix(prefix, keep: keep);
}

class _RecordingTelemetry implements TongtaiTelemetry {
  final List<(String, Map<String, Object>)> events = [];
  final List<Object> recorded = [];

  @override
  bool get enabled => true;

  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    events.add((name, params ?? const {}));
  }

  @override
  Future<void> recordError(Object error, StackTrace? stack) async {
    recorded.add(error);
  }
}

/// Provokes a genuine `SqliteException` on [db] and returns it.
///
/// A foreign-key violation is the failure this codebase has actually hit in
/// the field (the "Reset sample data" crash, WTM-162), so it is the honest
/// default for "the storage layer said no".
Future<Object> _realSqliteFailure(AppDatabase db) async {
  try {
    await DriftOrderRepository(db).upsert(
      CustomerOrder(
        id: 'o-orphan',
        customerId: 'nobody',
        orderNumber: 'DH-0000',
        date: DateTime(2026, 7, 31),
        status: OrderStatus.confirmed,
        items: const [],
      ),
    );
  } catch (error) {
    return error;
  }
  throw StateError('the foreign key did not fire — this helper is broken');
}
