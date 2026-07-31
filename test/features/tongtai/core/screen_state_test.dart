import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/telemetry/tongtai_telemetry.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/screen_data_controller.dart';
import 'package:tongtai/features/tongtai/core/screen_state.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';

/// WTM-148 / ADR-TON-017 — the shared screen-state seam, at the model level.
///
/// The widget half lives in `screen_data_seam_test.dart`; this file proves the
/// rules a widget cannot: classification of a REAL SQLite failure, the
/// constructor invariants, the stale-on-failed-refresh guarantee, the
/// out-of-order race, and the privacy split between what is shown and what is
/// reported.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TongtaiFailure.from — classification', () {
    test(
      'a REAL SQLite constraint failure classifies as storage + code',
      () async {
        // Production path, not a stub: a foreign-key violation on a real file
        // database — the exact failure "Reset sample data" used to crash on.
        final tempDir = await Directory.systemTemp.createTemp(
          'tongtai-failure-',
        );
        addTearDown(() async {
          if (tempDir.existsSync()) await tempDir.delete(recursive: true);
        });
        final db = AppDatabase.forExecutor(
          NativeDatabase(File('${tempDir.path}/tongtai.db')),
        );
        addTearDown(db.close);
        final orders = DriftOrderRepository(db);

        Object? thrown;
        try {
          // No such customer ⇒ orders_table.customer_id FK fails.
          await orders.upsert(
            CustomerOrder(
              id: 'o-orphan',
              customerId: 'nobody',
              orderNumber: 'DH-2026-0001',
              date: DateTime(2026, 7, 31),
              status: OrderStatus.confirmed,
              items: const [],
            ),
          );
        } catch (error) {
          thrown = error;
        }

        expect(
          thrown,
          isNotNull,
          reason: 'the FK must actually fire, or this test proves nothing',
        );
        final failure = TongtaiFailure.from(thrown!, StackTrace.current);
        expect(failure.kind, TongtaiFailureKind.storage);
        expect(failure.code, 'storage.sqlite_787');
        expect(failure.isRetryable, isTrue);
        expect(failure.detail, isNotNull);
      },
    );

    test('a timeout is a network failure', () {
      final failure = TongtaiFailure.from(TimeoutException('too slow'));
      expect(failure.kind, TongtaiFailureKind.network);
      expect(failure.code, 'network.timeout');
    });

    test('an unclassified error keeps its type name, visibly', () {
      final failure = TongtaiFailure.from(const FormatException('bad json'));
      expect(failure.kind, TongtaiFailureKind.unexpected);
      expect(failure.code, 'unexpected.FormatException');
      expect(
        failure.detail,
        contains('bad json'),
        reason: 'WTM-148: never trade a real cause for a vague message',
      );
    });

    test('an error that classifies itself is trusted', () {
      final failure = TongtaiFailure.from(const _SelfClassifying());
      expect(failure.kind, TongtaiFailureKind.configuration);
      expect(failure.code, 'configuration.demo');
      expect(
        failure.isRetryable,
        isFalse,
        reason: 'a setup problem must not offer a button that changes nothing',
      );
    });

    test('re-classifying a failure is idempotent', () {
      final first = TongtaiFailure.from(const FormatException('x'));
      expect(TongtaiFailure.from(first).code, first.code);
    });

    test('a runaway message is capped so the retry button stays reachable', () {
      final failure = TongtaiFailure.from(StateError('y' * 5000));
      expect(failure.detail!.length, lessThanOrEqualTo(301));
    });
  });

  group('privacy — what may leave the device (negative control)', () {
    test('toString and telemetryParams carry no message, ever', () {
      const secret = 'Nguyễn Văn A 0901234567 — 12.500.000 ₫';
      final failure = TongtaiFailure.from(StateError(secret));

      // Positive: the user CAN see it on their own screen.
      expect(failure.detail, contains(secret));

      // Negative control: nothing that leaves the device may contain it.
      expect(failure.toString(), isNot(contains(secret)));
      expect(failure.toString(), isNot(contains('Nguyễn')));
      expect(failure.telemetryParams.values.join(' '), isNot(contains(secret)));
      expect(failure.telemetryParams.keys, containsAll(['kind', 'code']));
      expect(failure.telemetryParams, hasLength(2));
    });

    test('the controller reports kind+code+screen and nothing else', () async {
      final telemetry = _RecordingTelemetry();
      final controller = ScreenDataController<int>(
        () async => throw StateError('customer Trần Thị B spent 9.000.000 ₫'),
        telemetry: () => telemetry,
        screen: 'consumer',
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(telemetry.events, hasLength(1));
      final (name, params) = telemetry.events.single;
      expect(name, kScreenErrorEvent);
      expect(params, {
        'kind': 'unexpected',
        'code': 'unexpected.StateError',
        'screen': 'consumer',
      });
      expect(params.values.join(' '), isNot(contains('Trần')));

      // Crashlytics records `toString()` — which is why it omits `detail`.
      expect(telemetry.recorded.single.toString(), isNot(contains('Trần')));
    });
  });

  group('ScreenState — invariants the type enforces', () {
    test('failed ⟺ failure present', () {
      expect(
        () => ScreenState<int>.failed(
          const TongtaiFailure(
            kind: TongtaiFailureKind.storage,
            code: 'storage.x',
          ),
        ),
        returnsNormally,
      );
      const loading = ScreenState<int>.loading();
      expect(loading.hasFailed, isFalse);
      expect(loading.failure, isNull);
    });

    test('a ready value always records when it was read', () {
      final at = DateTime(2026, 7, 31, 9, 41);
      final state = ScreenState<int>.ready(7, loadedAt: at);
      expect(state.loadedAt, at);
      expect(state.hasValue, isTrue);
      expect(state.isStale, isFalse);
    });

    test('a failed refresh keeps the value — that is what stale means', () {
      final at = DateTime(2026, 7, 31, 9, 41);
      final ready = ScreenState<int>.ready(7, loadedAt: at);
      final stale = ready.toRefreshing().toFailed(
        const TongtaiFailure(
          kind: TongtaiFailureKind.storage,
          code: 'storage.x',
        ),
      );
      expect(stale.isStale, isTrue);
      expect(
        stale.value,
        7,
        reason: 'the page must not blank on a bad refresh',
      );
      expect(stale.loadedAt, at, reason: 'stale must name the ORIGINAL read');
    });

    test('refreshing with nothing known is still plain loading', () {
      expect(const ScreenState<int>.loading().toRefreshing().isLoading, isTrue);
    });
  });

  group('ScreenDataController', () {
    test('load: loading → ready', () async {
      final seen = <ScreenPhase>[];
      final controller = ScreenDataController<int>(() async => 42);
      addTearDown(controller.dispose);
      controller.addListener(() => seen.add(controller.state.phase));

      await controller.load();

      expect(seen, [ScreenPhase.loading, ScreenPhase.ready]);
      expect(controller.state.value, 42);
    });

    test('load failure: failed, with nothing invented', () async {
      final controller = ScreenDataController<List<int>>(
        () async => throw const FormatException('nope'),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.hasFailed, isTrue);
      expect(controller.state.hasValue, isFalse);
      expect(controller.state.failure!.code, 'unexpected.FormatException');
    });

    test('failed refresh degrades to stale, then a retry recovers', () async {
      var attempt = 0;
      final controller = ScreenDataController<int>(() async {
        attempt++;
        if (attempt == 2) throw const FormatException('flaky');
        return attempt;
      });
      addTearDown(controller.dispose);

      await controller.load();
      expect(controller.state.value, 1);

      await controller.refresh();
      expect(controller.state.isStale, isTrue);
      expect(controller.state.value, 1, reason: 'old data stays readable');

      await controller.retry();
      expect(controller.state.hasFailed, isFalse);
      expect(controller.state.value, 3);
    });

    test('a slow first read cannot overwrite a newer one', () async {
      final gates = [Completer<int>(), Completer<int>()];
      var call = 0;
      final controller = ScreenDataController<int>(() {
        final index = call.clamp(0, gates.length - 1);
        call++;
        return gates[index].future;
      });
      addTearDown(controller.dispose);

      final first = controller.load();
      final second = controller.load();
      // The NEWER read answers first, the older one lands late.
      gates[1].complete(2);
      await second;
      gates[0].complete(1);
      await first;

      expect(
        controller.state.value,
        2,
        reason: 'the stale generation must be dropped, not applied',
      );
    });

    test('a response after dispose is dropped, not thrown', () async {
      final gate = Completer<int>();
      final controller = ScreenDataController<int>(() => gate.future);
      final pending = controller.load();
      controller.dispose();
      gate.complete(1);
      await expectLater(pending, completes);
    });
  });

  group('runTongtaiAction — writes cannot fail silently', () {
    test('returns null on success', () async {
      expect(await runTongtaiAction(() async {}), isNull);
    });

    test('returns a classified failure and reports it', () async {
      final telemetry = _RecordingTelemetry();
      final failure = await runTongtaiAction(
        () async => throw const FormatException('write failed'),
        telemetry: () => telemetry,
        screen: 'export',
      );
      expect(failure, isNotNull);
      expect(failure!.kind, TongtaiFailureKind.unexpected);
      expect(telemetry.events.single.$2['screen'], 'export');
    });

    test('a real repository failure reaches the caller', () async {
      // Production wiring: a Drift repository over a CLOSED database.
      final tempDir = await Directory.systemTemp.createTemp('tongtai-action-');
      addTearDown(() async {
        if (tempDir.existsSync()) await tempDir.delete(recursive: true);
      });
      final db = AppDatabase.forExecutor(
        NativeDatabase(File('${tempDir.path}/tongtai.db')),
      );
      final customers = DriftCustomerRepository(db);
      await customers.loadAll();
      await db.close();

      final failure = await runTongtaiAction(
        () => customers.upsert(
          Customer(
            id: 'c1',
            name: 'A',
            phone: '',
            location: '',
            orderCount: 0,
            totalSpent: 0,
            lastPurchaseDate: null,
          ),
        ),
      );

      expect(
        failure,
        isNotNull,
        reason: 'a write against a closed database must surface, not vanish',
      );
    });
  });
}

/// An error that declares its own classification (the [TongtaiClassifiedError]
/// seam a feature module uses instead of teaching the core about its types).
class _SelfClassifying implements Exception, TongtaiClassifiedError {
  const _SelfClassifying();

  @override
  TongtaiFailure get failure => const TongtaiFailure(
    kind: TongtaiFailureKind.configuration,
    code: 'configuration.demo',
  );
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
