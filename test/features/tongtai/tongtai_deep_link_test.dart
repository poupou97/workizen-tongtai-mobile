import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/prefs.dart' show sharedPreferencesProvider;
import 'package:tongtai/features/tongtai/tongtai.dart';

/// Real tests for Deep Linking Support (WTM-57).
///
/// Coverage maps 1:1 to the acceptance criteria:
///  AC1  supplier detail links (tongtai://suppliers/ID) resolve + carry data
///  AC2  customer profile + journey links work without errors
///  AC3  URL parameters are validated and sanitized before navigation
///  AC4  bad links fail gracefully with a friendly, bilingual message
///  AC5  cold-start (app killed) launch links restore the right screen
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const parser = TongtaiDeepLinkParser.instance;

  // ── Parser: happy-path route matching ────────────────────────────────────
  group('Parser — route matching (AC1/AC2)', () {
    test('AC1: supplier detail resolves and carries the id', () {
      final r = parser.parse('tongtai://suppliers/42');
      expect(r, isA<TongtaiDeepLinkSuccess>());
      final route = r.routeOrNull!;
      expect(route.kind, TongtaiRouteKind.supplierDetail);
      expect(route.entityId, '42');
      // Supplier detail lives inside the Producer tab.
      expect(route.tabIndex, TongtaiTabs.producer);
    });

    test('AC1: canonical producer/supplier/ID form is an alias', () {
      final a = parser.parse('tongtai://suppliers/abc-123').routeOrNull;
      final b = parser.parse('tongtai://producer/supplier/abc-123').routeOrNull;
      expect(a, isNotNull);
      expect(a, equals(b));
      expect(b!.kind, TongtaiRouteKind.supplierDetail);
      expect(b.entityId, 'abc-123');
    });

    test('AC2: customer profile resolves (both URL forms)', () {
      final short = parser.parse('tongtai://customers/C_9').routeOrNull;
      final long = parser.parse('tongtai://consumer/customer/C_9').routeOrNull;
      expect(short, isNotNull);
      expect(short!.kind, TongtaiRouteKind.customerDetail);
      expect(short.entityId, 'C_9');
      expect(short.tabIndex, TongtaiTabs.consumer);
      expect(long, equals(short));
    });

    test('AC2: active journey resolves without an id', () {
      for (final link in ['tongtai://journey', 'tongtai://journey/active']) {
        final route = parser.parse(link).routeOrNull;
        expect(route, isNotNull, reason: link);
        expect(route!.kind, TongtaiRouteKind.journey);
        expect(route.entityId, isNull);
        expect(route.tabIndex, TongtaiTabs.home);
      }
    });

    test('AC2: a specific journey resolves with an id', () {
      final route = parser.parse('tongtai://journey/j-2026').routeOrNull;
      expect(route, isNotNull);
      expect(route!.kind, TongtaiRouteKind.journey);
      expect(route.entityId, 'j-2026');
    });

    test('list + dashboard routes resolve to the right tab', () {
      final cases = <String, ({TongtaiRouteKind kind, int tab})>{
        'tongtai://home': (kind: TongtaiRouteKind.home, tab: TongtaiTabs.home),
        'tongtai://producer': (
          kind: TongtaiRouteKind.producer,
          tab: TongtaiTabs.producer,
        ),
        'tongtai://producer/suppliers': (
          kind: TongtaiRouteKind.supplierList,
          tab: TongtaiTabs.producer,
        ),
        'tongtai://suppliers': (
          kind: TongtaiRouteKind.supplierList,
          tab: TongtaiTabs.producer,
        ),
        'tongtai://inventory/products': (
          kind: TongtaiRouteKind.inventoryProducts,
          tab: TongtaiTabs.inventory,
        ),
        'tongtai://consumer/customers': (
          kind: TongtaiRouteKind.customerList,
          tab: TongtaiTabs.consumer,
        ),
        // WTM-192: these three used to land on the More tab, which no longer
        // exists in the bar. They land on Home and push their own screen —
        // Home is the only tab that hosts none of them, so it never leaves the
        // seller on a tab that contradicts what they opened.
        'tongtai://reports': (
          kind: TongtaiRouteKind.reports,
          tab: TongtaiTabs.home,
        ),
        'tongtai://finance/accounts': (
          kind: TongtaiRouteKind.financeAccounts,
          tab: TongtaiTabs.home,
        ),
        'tongtai://chat': (kind: TongtaiRouteKind.chat, tab: TongtaiTabs.home),
      };
      cases.forEach((link, expected) {
        final route = parser.parse(link).routeOrNull;
        expect(route, isNotNull, reason: link);
        expect(route!.kind, expected.kind, reason: link);
        expect(route.tabIndex, expected.tab, reason: link);
        expect(route.entityId, isNull, reason: link);
      });
    });

    test('product + opportunity detail carry ids on the right tab', () {
      final p = parser.parse('tongtai://inventory/product/SKU-1').routeOrNull;
      expect(p!.kind, TongtaiRouteKind.productDetail);
      expect(p.entityId, 'SKU-1');
      expect(p.tabIndex, TongtaiTabs.inventory);

      final o = parser.parse('tongtai://opportunity/op9').routeOrNull;
      expect(o!.kind, TongtaiRouteKind.opportunityDetail);
      expect(o.entityId, 'op9');
      expect(o.tabIndex, TongtaiTabs.producer);
    });

    test('scheme and host are case-insensitive', () {
      final route = parser.parse('TONGTAI://SUPPLIERS/77').routeOrNull;
      expect(route, isNotNull);
      expect(route!.kind, TongtaiRouteKind.supplierDetail);
      expect(route.entityId, '77');
    });

    test('canonicalUri round-trips back to the same route', () {
      for (final link in [
        'tongtai://suppliers/42',
        'tongtai://consumer/customer/C_9',
        'tongtai://journey/active',
        'tongtai://inventory/product/SKU-1',
        'tongtai://home',
      ]) {
        final route = parser.parse(link).routeOrNull!;
        final reparsed = parser.parse(route.canonicalUri).routeOrNull;
        expect(reparsed, equals(route), reason: link);
      }
    });
  });

  // ── Parser: validation & sanitization ────────────────────────────────────
  group('Parser — validation & sanitization (AC3)', () {
    test('a valid 64-char id is accepted; 65 chars is rejected', () {
      final ok = 'a' * 64;
      final tooLong = 'a' * 65;
      expect(parser.parse('tongtai://suppliers/$ok').isSuccess, isTrue);

      final bad = parser.parse('tongtai://suppliers/$tooLong');
      expect(bad, isA<TongtaiDeepLinkFailure>());
      expect(
        (bad as TongtaiDeepLinkFailure).error,
        TongtaiDeepLinkError.invalidParameter,
      );
    });

    test('path-traversal ids are rejected', () {
      // Traversal payloads that survive URI parsing as a single non-empty
      // segment (a bare `..` is normalized away by Uri, which is also safe —
      // it degrades to the list route, never a detail id). Each of these keeps
      // a '.' or '/' after decoding, so id validation rejects it.
      for (final id in ['a..b', '..b', 'a%2Fb', 'a%2e%2eb']) {
        final r = parser.parse('tongtai://suppliers/$id');
        expect(r, isA<TongtaiDeepLinkFailure>(), reason: id);
        expect(
          (r as TongtaiDeepLinkFailure).error,
          TongtaiDeepLinkError.invalidParameter,
          reason: id,
        );
      }
    });

    test('a bare `..` traversal never resolves to a detail id', () {
      // Defense in depth: even the Uri-normalized `..` case must not produce a
      // supplier *detail* route carrying a traversal string.
      final route = parser.parse('tongtai://suppliers/..').routeOrNull;
      expect(route?.kind, isNot(TongtaiRouteKind.supplierDetail));
    });

    test('ids with illegal characters are rejected', () {
      // %20 = space, %2F = slash, plus symbols outside [A-Za-z0-9_-].
      for (final id in ['a%20b', 'a%2Fb', r'a$b', 'a~b', 'a.b']) {
        final r = parser.parse('tongtai://suppliers/$id');
        expect(r, isA<TongtaiDeepLinkFailure>(), reason: id);
        expect(
          (r as TongtaiDeepLinkFailure).error,
          TongtaiDeepLinkError.invalidParameter,
          reason: id,
        );
      }
    });

    test('search query is trimmed, control-stripped and length-capped', () {
      // Leading/trailing space + an embedded control char, all cleaned up.
      final r = parser
          .parse('tongtai://search?q=%20rice%09price%20')
          .routeOrNull;
      expect(r, isNotNull);
      expect(r!.kind, TongtaiRouteKind.search);
      expect(r.queryParams['q'], 'riceprice');

      final long = 'x' * 500;
      final capped = parser
          .parse('tongtai://search?q=$long')
          .routeOrNull!
          .queryParams['q']!;
      expect(capped.length, 200);
    });

    test('an all-whitespace search query yields no param', () {
      final r = parser.parse('tongtai://search?q=%20%20').routeOrNull;
      expect(r, isNotNull);
      expect(r!.kind, TongtaiRouteKind.search);
      expect(r.queryParams, isEmpty);
    });
  });

  // ── Parser: graceful failures ────────────────────────────────────────────
  group('Parser — graceful failure (AC4)', () {
    test('empty / whitespace input reports the empty error', () {
      for (final s in ['', '   ', '\n']) {
        final r = parser.parse(s);
        expect(r, isA<TongtaiDeepLinkFailure>(), reason: '"$s"');
        expect((r as TongtaiDeepLinkFailure).error, TongtaiDeepLinkError.empty);
      }
    });

    test('a non-tongtai scheme is rejected as unsupported', () {
      final r = parser.parse('https://example.com/suppliers/42');
      expect(
        (r as TongtaiDeepLinkFailure).error,
        TongtaiDeepLinkError.unsupportedScheme,
      );
    });

    test('a malformed URI is caught, not thrown', () {
      // Non-numeric port makes Uri.parse throw FormatException internally.
      final r = parser.parse('tongtai://suppliers:notaport/42');
      expect(r, isA<TongtaiDeepLinkFailure>());
      expect(
        (r as TongtaiDeepLinkFailure).error,
        TongtaiDeepLinkError.malformed,
      );
    });

    test('an unknown route reports unknownRoute', () {
      for (final link in [
        'tongtai://',
        'tongtai://nope',
        'tongtai://producer/unknown/thing',
        'tongtai://home/extra',
      ]) {
        final r = parser.parse(link);
        expect(r, isA<TongtaiDeepLinkFailure>(), reason: link);
        expect(
          (r as TongtaiDeepLinkFailure).error,
          TongtaiDeepLinkError.unknownRoute,
          reason: link,
        );
      }
    });

    test('every failure has a non-empty EN and VI message that differ', () {
      for (final e in TongtaiDeepLinkError.values) {
        final f = TongtaiDeepLinkFailure(e);
        final en = f.messageFor('en');
        final vi = f.messageFor('vi');
        expect(en, isNotEmpty, reason: e.name);
        expect(vi, isNotEmpty, reason: e.name);
        expect(en, isNot(vi), reason: e.name);
      }
    });
  });

  // ── Route value object ───────────────────────────────────────────────────
  group('TongtaiRoute value semantics', () {
    test('equality and hashCode are value-based', () {
      const a = TongtaiRoute(TongtaiRouteKind.supplierDetail, entityId: '1');
      const b = TongtaiRoute(TongtaiRouteKind.supplierDetail, entityId: '1');
      const c = TongtaiRoute(TongtaiRouteKind.supplierDetail, entityId: '2');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('requiresId is true only for detail kinds', () {
      expect(TongtaiRouteKind.supplierDetail.requiresId, isTrue);
      expect(TongtaiRouteKind.customerDetail.requiresId, isTrue);
      expect(TongtaiRouteKind.productDetail.requiresId, isTrue);
      expect(TongtaiRouteKind.opportunityDetail.requiresId, isTrue);
      expect(TongtaiRouteKind.home.requiresId, isFalse);
      expect(TongtaiRouteKind.supplierList.requiresId, isFalse);
      expect(TongtaiRouteKind.journey.requiresId, isFalse);
    });

    test('every kind maps to a valid bottom-nav tab index', () {
      for (final kind in TongtaiRouteKind.values) {
        expect(
          kind.tabIndex,
          inInclusiveRange(TongtaiTabs.home, TongtaiTabs.opportunity),
          reason: kind.name,
        );
      }
    });
  });

  // ── Controller: navigation + cold-start ──────────────────────────────────
  group('TongtaiDeepLinkController', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    ProviderContainer makeContainer() {
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('AC1: a valid supplier link selects the Producer tab', () {
      final c = makeContainer();
      final result = c
          .read(tongtaiDeepLinkControllerProvider.notifier)
          .handle('tongtai://suppliers/42');

      expect(result.isSuccess, isTrue);
      expect(c.read(tongtaiSelectedTabProvider), TongtaiTabs.producer);

      final state = c.read(tongtaiDeepLinkControllerProvider);
      expect(state.activeRoute?.kind, TongtaiRouteKind.supplierDetail);
      expect(state.activeRoute?.entityId, '42');
      expect(state.lastFailure, isNull);
    });

    test('AC2: customer + journey links land on the right tabs', () {
      final c = makeContainer();
      final ctrl = c.read(tongtaiDeepLinkControllerProvider.notifier);

      ctrl.handle('tongtai://customers/C1');
      expect(c.read(tongtaiSelectedTabProvider), TongtaiTabs.consumer);

      ctrl.handle('tongtai://journey/active');
      expect(c.read(tongtaiSelectedTabProvider), TongtaiTabs.home);
      expect(
        c.read(tongtaiDeepLinkControllerProvider).activeRoute?.kind,
        TongtaiRouteKind.journey,
      );
    });

    test('AC4: a bad link records a failure and does NOT navigate', () {
      final c = makeContainer();
      final ctrl = c.read(tongtaiDeepLinkControllerProvider.notifier);

      // Start on a known tab so we can prove it is unchanged.
      ctrl.handle('tongtai://producer');
      expect(c.read(tongtaiSelectedTabProvider), TongtaiTabs.producer);

      final result = ctrl.handle('tongtai://suppliers/bad%20id');
      expect(result.isFailure, isTrue);

      final state = c.read(tongtaiDeepLinkControllerProvider);
      expect(state.lastFailure?.error, TongtaiDeepLinkError.invalidParameter);
      // Tab stayed put — no navigation to a broken screen.
      expect(c.read(tongtaiSelectedTabProvider), TongtaiTabs.producer);
    });

    test('sequence increments on every handled link', () {
      final c = makeContainer();
      final ctrl = c.read(tongtaiDeepLinkControllerProvider.notifier);
      final s0 = c.read(tongtaiDeepLinkControllerProvider).sequence;
      ctrl.handle('tongtai://home');
      ctrl.handle('tongtai://nonsense');
      expect(c.read(tongtaiDeepLinkControllerProvider).sequence, s0 + 2);
    });

    test('AC5: cold-start launch link restores the target screen', () {
      // Simulate app-killed launch: feed the link BEFORE anything reads the
      // shell/tab. The first thing to read the tab already sees Producer.
      final c = makeContainer();
      final result = c
          .read(tongtaiDeepLinkControllerProvider.notifier)
          .handleInitialLink('tongtai://suppliers/999');

      expect(result, isNotNull);
      expect(result!.isSuccess, isTrue);
      expect(c.read(tongtaiSelectedTabProvider), TongtaiTabs.producer);
      expect(
        c.read(tongtaiDeepLinkControllerProvider).activeRoute?.entityId,
        '999',
      );
    });

    test('AC5: a normal launch (no link) leaves state untouched', () {
      final c = makeContainer();
      final result = c
          .read(tongtaiDeepLinkControllerProvider.notifier)
          .handleInitialLink(null);

      expect(result, isNull);
      final state = c.read(tongtaiDeepLinkControllerProvider);
      expect(state.activeRoute, isNull);
      expect(state.lastFailure, isNull);
      expect(state.sequence, 0);
      // Default tab is still Home.
      expect(c.read(tongtaiSelectedTabProvider), TongtaiTabs.home);
    });

    test('consumeActiveRoute clears the pending route only once', () {
      final c = makeContainer();
      final ctrl = c.read(tongtaiDeepLinkControllerProvider.notifier);
      ctrl.handle('tongtai://suppliers/42');
      expect(c.read(tongtaiDeepLinkControllerProvider).activeRoute, isNotNull);

      ctrl.consumeActiveRoute();
      expect(c.read(tongtaiDeepLinkControllerProvider).activeRoute, isNull);

      final seq = c.read(tongtaiDeepLinkControllerProvider).sequence;
      ctrl.consumeActiveRoute(); // no-op when already null
      expect(c.read(tongtaiDeepLinkControllerProvider).sequence, seq);
    });
  });

  // ── Shell integration: graceful error UI ─────────────────────────────────
  group('TongtaiAppShell deep-link UI (AC4)', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    ProviderContainer makeContainer() {
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      return c;
    }

    testWidgets('a bad link shows a friendly SnackBar and does not navigate', (
      tester,
    ) async {
      final c = makeContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: TongtaiAppShell()),
        ),
      );

      c
          .read(tongtaiDeepLinkControllerProvider.notifier)
          .handle('tongtai://totally/unknown');
      await tester.pump(); // run the ref.listen callback
      await tester.pump(
        const Duration(milliseconds: 400),
      ); // animate SnackBar in

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text("We couldn't find the screen this link points to."),
        findsOneWidget,
      );
      // Still on the default Home tab — no navigation happened.
      expect(c.read(tongtaiSelectedTabProvider), TongtaiTabs.home);
    });

    testWidgets('a valid link navigates and shows no error SnackBar', (
      tester,
    ) async {
      final c = makeContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: TongtaiAppShell()),
        ),
      );

      c
          .read(tongtaiDeepLinkControllerProvider.notifier)
          .handle('tongtai://customers/C1');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SnackBar), findsNothing);
      expect(c.read(tongtaiSelectedTabProvider), TongtaiTabs.consumer);
    });
  });
}
