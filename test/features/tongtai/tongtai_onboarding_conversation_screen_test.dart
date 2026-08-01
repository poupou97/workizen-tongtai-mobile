import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/profile/business_profile.dart';
import 'package:tongtai/features/tongtai/profile/business_profile_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/ui/screens/tongtai_onboarding_conversation_screen.dart';

import '../../support/tap_by_key.dart';

/// WTM-178 — the onboarding conversation, end to end, against a real database.
///
/// The property under test throughout: **it works with no AI**. There is no
/// provider to stub in this file because the screen never calls one.
void main() {
  late Directory dir;
  late AppDatabase db;
  var doneCalls = 0;

  setUp(() async {
    doneCalls = 0;
    dir = await Directory.systemTemp.createTemp('tongtai_ob_screen');
    db = AppDatabase.forExecutor(NativeDatabase(File('${dir.path}/t.sqlite')));
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  Widget host(String locale) => ProviderScope(
    overrides: [tongtaiDatabaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('vi')],
      home: TongtaiOnboardingConversationScreen(onDone: () => doneCalls++),
    ),
  );

  /// Onboarding is a full-screen portrait flow. The 800×600 default test
  /// surface is landscape-shaped and squeezes the column enough that chips
  /// stop being hit-testable — a test artefact, not a real layout bug. Sizing
  /// to a phone keeps the test honest about the shape sellers actually see.
  Future<void> usePhoneSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Future<void> start(WidgetTester tester, String locale) async {
    await usePhoneSurface(tester);
    await tester.pumpWidget(host(locale));
    await tester.pumpAndSettle();
    await tester.tapByKey('onboarding-start');
    tester.expectScreen(
      'onboarding-question',
      reason: 'the start button did not take us into the conversation',
    );
  }

  Future<void> tapOption(WidgetTester tester, int index) => tester.tapByKey(
    'onboarding-option-$index',
    scrollableUnder: 'onboarding-question',
  );

  Future<void> tapNext(WidgetTester tester) => tester.tapByKey(
    'onboarding-next',
    scrollableUnder: 'onboarding-question',
  );

  for (final locale in ['vi', 'en']) {
    testWidgets('[$locale] opens on the greeting, not on a question', (
      tester,
    ) async {
      await tester.pumpWidget(host(locale));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('onboarding-greeting')), findsOneWidget);
      expect(find.byKey(const Key('onboarding-question')), findsNothing);
    });

    testWidgets('[$locale] answers all four and saves the profile', (
      tester,
    ) async {
      await start(tester, locale);

      for (var step = 0; step < 4; step++) {
        expect(find.byKey(const Key('onboarding-prompt')), findsOneWidget);
        await tapOption(tester, 0);
        await tapNext(tester);
      }

      expect(find.byKey(const Key('onboarding-closing')), findsOneWidget);
      await tester.tapByKey('onboarding-done');

      final saved = await BusinessProfileRepository(db).load();
      expect(saved.trade, BusinessTrade.fashion);
      expect(saved.channels, contains(SalesChannel.shop));
      expect(saved.size, BusinessSize.solo);
      expect(saved.seasonality, BusinessSeasonality.none);
      expect(doneCalls, 1);
    });
  }

  testWidgets('skipping every question still finishes and opens the app', (
    tester,
  ) async {
    // The path a hurried seller takes. It must be a normal outcome, not a
    // dead end and not an error.
    await start(tester, 'vi');
    for (var step = 0; step < 4; step++) {
      await tester.tapByKey('onboarding-skip');
    }
    await tester.tapByKey('onboarding-done');

    expect(doneCalls, 1);
    expect((await BusinessProfileRepository(db).load()).isEmpty, isTrue);
  });

  testWidgets('a seller who answered nothing is not thanked for answers', (
    tester,
  ) async {
    // Thanking someone for information they declined to give reads as the app
    // not listening — the exact impression onboarding must not leave.
    await start(tester, 'vi');
    for (var step = 0; step < 4; step++) {
      await tester.tapByKey('onboarding-skip');
    }
    final closing = tester
        .widget<Text>(find.byKey(const Key('onboarding-closing-text')))
        .data!;
    expect(closing, contains('Không sao'));
  });

  testWidgets('going back shows the previous answer still selected', (
    tester,
  ) async {
    await start(tester, 'vi');
    await tapOption(tester, 1);
    await tapNext(tester);
    await tester.tapByKey(
      'onboarding-back',
      scrollableUnder: 'onboarding-question',
    );

    final chip = tester.widget<ChoiceChip>(
      find.byKey(const Key('onboarding-option-1')),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('there is no back button on the first question', (tester) async {
    await start(tester, 'vi');
    expect(find.byKey(const Key('onboarding-back')), findsNothing);
  });

  testWidgets('progress says which question this is', (tester) async {
    await start(tester, 'vi');
    expect(
      tester.widget<Text>(find.byKey(const Key('onboarding-progress'))).data,
      contains('1/4'),
    );
  });

  testWidgets('no text input anywhere in the flow', (tester) async {
    // Same boundary as the profile editor: nothing a seller types can reach an
    // AI prompt, because there is nowhere to type.
    await start(tester, 'vi');
    for (var step = 0; step < 4; step++) {
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      await tapNext(tester);
    }
    expect(find.byType(TextField), findsNothing);
  });
}
