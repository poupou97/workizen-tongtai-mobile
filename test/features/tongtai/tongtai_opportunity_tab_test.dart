import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/prefs.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/navigation/tongtai_design_tokens.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/ui/screens/tongtai_more_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_opportunity_feed_screen.dart';
import 'package:tongtai/features/tongtai/ui/tongtai_app_shell.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tongtai_more_action.dart';

import '../../support/tap_by_key.dart';

/// WTM-192 (O-5) — Opportunity Hub is a first-class capability in the bar.
///
/// Founder decision 2026-08-01 (option B): Opportunity took the fifth slot from
/// **More**, and More moved into every screen's AppBar. The trade is only
/// acceptable if More stays **one tap from every tab**, so that is the thing
/// these tests actually check — not that a widget exists somewhere.
void main() {
  late Directory dir;
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('tongtai_opp_tab');
    db = AppDatabase.forExecutor(NativeDatabase(File('${dir.path}/t.sqlite')));
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<Widget> host() async => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(
        await SharedPreferences.getInstance(),
      ),
      tongtaiDatabaseProvider.overrideWithValue(db),
    ],
    child: const MaterialApp(
      locale: Locale('vi'),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en'), Locale('vi')],
      home: TongtaiAppShell(),
    ),
  );

  testWidgets('the fifth tab opens the Opportunity Hub', (tester) async {
    await tester.pumpWidget(await host());
    await tester.pumpAndSettle();

    await tester.tapByKey('nav-tab-${TongtaiTabs.opportunity}');

    expect(find.byType(TongtaiOpportunityFeedScreen), findsOneWidget);
  });

  testWidgets('More is one tap away from every tab', (tester) async {
    // The whole justification for taking More out of the bar. If any tab
    // cannot reach it, the seller lost access to backup, privacy and the AI
    // key — and that is not a trade anyone agreed to.
    await tester.pumpWidget(await host());
    await tester.pumpAndSettle();

    for (final tab in [
      TongtaiTabs.home,
      TongtaiTabs.producer,
      TongtaiTabs.inventory,
      TongtaiTabs.consumer,
      TongtaiTabs.opportunity,
    ]) {
      await tester.tapByKey('nav-tab-$tab');

      expect(
        find.byKey(TongtaiMoreAction.actionKey),
        findsOneWidget,
        reason: 'tab $tab has no way to reach More',
      );
    }
  });

  testWidgets('tapping the More action opens the More screen', (tester) async {
    await tester.pumpWidget(await host());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(TongtaiMoreAction.actionKey));
    await tester.pumpAndSettle();

    expect(find.byType(TongtaiMoreScreen), findsOneWidget);
  });

  testWidgets('a persisted tab 4 lands on Opportunity, not out of range', (
    tester,
  ) async {
    // The index was **reused** rather than appended, so an existing install
    // whose last tab was More opens on a real screen instead of throwing.
    // The key `TongtaiSelectedTabNotifier` persists under.
    SharedPreferences.setMockInitialValues({'tongtai_selected_tab': 4});
    await tester.pumpWidget(await host());
    await tester.pumpAndSettle();

    expect(find.byType(TongtaiOpportunityFeedScreen), findsOneWidget);
  });
}
