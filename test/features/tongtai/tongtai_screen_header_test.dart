import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/l10n/app_strings.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/ui/screens/tongtai_consumer_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_inventory_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_opportunity_feed_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_producer_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_reports_screen.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tongtai_fox_mascot.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tongtai_more_action.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tongtai_screen_header.dart';

import '../../support/pump_until.dart';

/// WTM-216 (concept-1 nhóm C) — every main screen wears the same header:
/// mascot · title · subtitle.
///
/// The test that matters is the LAST one: the header is built by one function,
/// so a screen cannot quietly grow its own. Five hand-written headers is the
/// chrome version of the defect ADR-TON-015 forbids in the data layer, and it
/// is invisible until two tabs are screenshotted side by side.
void main() {
  // The real screens hydrate from repositories; without a database the read
  // fails and every header sits behind the failure state (the harness failing,
  // not the screen — WTM-210's lesson).
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forExecutor(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Widget host(Widget screen, {String locale = 'vi'}) => ProviderScope(
    overrides: [tongtaiDatabaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('vi')],
      home: screen,
    ),
  );

  void tallViewport(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(500, 3200);
  }

  final screens = <String, Widget Function()>{
    'producer': () => const TongtaiProducerScreen(),
    'inventory': () => const TongtaiInventoryScreen(),
    'consumer': () => const TongtaiConsumerScreen(),
    'opportunity': () => const TongtaiOpportunityFeedScreen(),
    'reports': () => const TongtaiReportsScreen(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} header carries the mascot and its subtitle', (
      tester,
    ) async {
      tallViewport(tester);
      await tester.pumpWidget(host(entry.value()));
      await pumpUntilFound(tester, find.byKey(Key('${entry.key}-header')));

      expect(
        find.descendant(
          of: find.byKey(Key('${entry.key}-header')),
          matching: find.byType(TongtaiFoxMascot),
        ),
        findsOneWidget,
      );
      final subtitle = tester.widget<Text>(
        find.byKey(Key('${entry.key}-header-subtitle')),
      );
      expect(subtitle.data, isNotEmpty);
    });
  }

  testWidgets('each screen gets ITS subtitle — no shared placeholder', (
    tester,
  ) async {
    // A single "Quản lý doanh nghiệp" reused on every tab would pass the test
    // above while telling the seller nothing. Collect and compare.
    final seen = <String>{};
    for (final entry in screens.entries) {
      tallViewport(tester);
      await tester.pumpWidget(host(entry.value()));
      await pumpUntilFound(tester, find.byKey(Key('${entry.key}-header')));
      seen.add(
        tester
            .widget<Text>(find.byKey(Key('${entry.key}-header-subtitle')))
            .data!,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }

    expect(seen, hasLength(screens.length));
  });

  testWidgets('the tab screens keep their one-tap More action (WTM-192)', (
    tester,
  ) async {
    // The header supplies `actions` now, so the reachability guarantee moved
    // into shared code — this pins that the move did not drop it.
    for (final screen in ['producer', 'inventory', 'consumer']) {
      tallViewport(tester);
      await tester.pumpWidget(host(screens[screen]!()));
      await pumpUntilFound(tester, find.byKey(Key('$screen-header')));

      expect(
        find.byKey(TongtaiMoreAction.actionKey),
        findsOneWidget,
        reason: '$screen lost the More entry point',
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('the bar grows with the system font instead of clipping', (
    tester,
  ) async {
    // A two-line title in a fixed kToolbarHeight is the WTM-169 overflow class
    // waiting to happen: at 2.0x the subtitle is the line that disappears.
    tallViewport(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(host(const TongtaiInventoryScreen()));
    await pumpUntilFound(tester, find.byKey(const Key('inventory-header')));

    final bar = tester.widget<AppBar>(find.byType(AppBar));
    expect(bar.toolbarHeight, greaterThan(kToolbarHeight));
  });

  group('the subtitle mapping itself', () {
    test('every header screen has a real line in both locales', () {
      for (final l10n in [AppStringsVi(), AppStringsEn()]) {
        final lines = {
          for (final screen in screens.keys)
            screen: tongtaiScreenSubtitle(l10n, screen),
          'finance': tongtaiScreenSubtitle(l10n, 'finance'),
        };
        expect(lines.values.every((s) => s.trim().isNotEmpty), isTrue);
        expect(
          lines.values.toSet(),
          hasLength(lines.length),
          reason: '${l10n.languageCode}: two screens share one subtitle',
        );
      }
    });

    test('an unknown screen throws instead of inventing a line', () {
      // Better a loud error at build time than a header that silently says
      // nothing — the same reason an unknown enum code is never defaulted
      // to a plausible value (ADR-TON-018).
      expect(
        () => tongtaiScreenSubtitle(AppStringsVi(), 'not-a-screen'),
        throwsArgumentError,
      );
    });
  });
}
