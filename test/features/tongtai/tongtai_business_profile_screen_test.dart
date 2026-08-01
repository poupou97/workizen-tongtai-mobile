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
import 'package:tongtai/features/tongtai/ui/screens/tongtai_business_profile_screen.dart';

import '../../support/tap_by_key.dart';

/// WTM-177 — the profile editor, against a real SQLite file.
void main() {
  late Directory dir;
  late AppDatabase db;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('tongtai_profile_screen');
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
      home: const TongtaiBusinessProfileScreen(),
    ),
  );

  Future<void> tapProfile(WidgetTester tester, String key) =>
      tester.tapByKey(key, scrollableUnder: 'profile-list');

  for (final locale in ['vi', 'en']) {
    testWidgets('[$locale] a seller with no profile sees empty chips', (
      tester,
    ) async {
      await tester.pumpWidget(host(locale));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile-list')), findsOneWidget);
      final chip = tester.widget<ChoiceChip>(
        find.byKey(const Key('profile-trade-0')),
      );
      expect(chip.selected, isFalse);
    });

    testWidgets('[$locale] picking answers saves them to the database', (
      tester,
    ) async {
      await tester.pumpWidget(host(locale));
      await tester.pumpAndSettle();

      await tapProfile(tester, 'profile-trade-0');
      await tapProfile(tester, 'profile-size-0');
      await tapProfile(tester, 'profile-channel-2');
      await tapProfile(tester, 'profile-save');

      final saved = await BusinessProfileRepository(db).load();
      expect(saved.trade, BusinessTrade.fashion);
      expect(saved.size, BusinessSize.solo);
      expect(saved.channels, contains(SalesChannel.shopee));
      expect(find.byKey(const Key('profile-saved')), findsOneWidget);
    });
  }

  testWidgets('an existing profile loads with its chips already selected', (
    tester,
  ) async {
    await BusinessProfileRepository(db).save(
      const BusinessProfile(
        trade: BusinessTrade.food,
        channels: [SalesChannel.zalo],
      ),
      now: DateTime(2026, 8, 1),
    );

    await tester.pumpWidget(host('vi'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('profile-trade-1')))
          .selected,
      isTrue,
    );
    await tester.scrollToKey('profile-channel-5', under: 'profile-list');
    expect(
      tester
          .widget<FilterChip>(find.byKey(const Key('profile-channel-5')))
          .selected,
      isTrue,
    );
  });

  testWidgets('tapping a selected chip clears it', (tester) async {
    // A wrong answer must be removable, not only replaceable — otherwise a
    // mis-tap is permanent and the seller has to live with the AI believing it.
    await tester.pumpWidget(host('vi'));
    await tester.pumpAndSettle();

    await tapProfile(tester, 'profile-trade-0');
    await tapProfile(tester, 'profile-trade-0');
    await tapProfile(tester, 'profile-save');

    expect((await BusinessProfileRepository(db).load()).trade, isNull);
  });

  testWidgets('saving nothing at all is allowed and stays empty', (
    tester,
  ) async {
    // Every question is skippable, so "save" with no answers must not be an
    // error path — it is the state most sellers will leave the screen in.
    await tester.pumpWidget(host('vi'));
    await tester.pumpAndSettle();

    await tapProfile(tester, 'profile-save');

    expect((await BusinessProfileRepository(db).load()).isEmpty, isTrue);
  });

  testWidgets('the screen tells the seller what will be sent', (tester) async {
    await tester.pumpWidget(host('vi'));
    await tester.pumpAndSettle();
    await tester.scrollToKey('profile-privacy-note', under: 'profile-list');
  });

  testWidgets('there is no text field anywhere on the screen', (tester) async {
    // The structural half of the privacy promise. A TextField here is the one
    // affordance that could carry "chị Lan 0909…" into every AI prompt.
    await tester.pumpWidget(host('vi'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
  });
}
