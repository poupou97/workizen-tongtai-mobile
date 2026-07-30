import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/l10n/app_strings.dart';
import 'package:tongtai/core/l10n/language_notifier.dart';
import 'package:tongtai/core/prefs.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_more_screen.dart';

/// P0 §2 (WTM-145) — single-locale localization:
///  - NO label may mix two languages ("Timeline · Dòng thời gian" is banned);
///  - switching updates the whole app instantly and persists across restart;
///  - every AppStrings key exists in both locales (compile-enforced) and is
///    actually referenced by the UI (unused-key check).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'hard-coded bilingual-label scan (regression: fails on the old code)',
    () {
      test('no UI string literal concatenates two languages around " · "', () {
        final uiDir = Directory('lib/features/tongtai/ui');
        final offenders = <String>[];
        final literal = RegExp("'([^'\\\\]|\\\\.)*'");
        final letters = RegExp('[A-Za-zÀ-ỹ]{2,}');
        for (final f
            in uiDir
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart'))) {
          final lines = f.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i].trimLeft();
            if (line.startsWith('//') || line.startsWith('///')) continue;
            for (final m in literal.allMatches(lines[i])) {
              final value = m.group(0)!;
              if (!value.contains(' · ')) continue;
              // Ban when TWO OR MORE segments carry static words — that is a
              // bilingual (or multi-phrase) concatenation. Data separators like
              // '$a · $b' have interpolations, not static words, per segment.
              final staticSegments = value
                  .substring(1, value.length - 1)
                  .split(' · ')
                  .where((seg) {
                    final withoutInterp = seg.replaceAll(
                      RegExp(r'\$\{[^}]*\}|\$[a-zA-Z_]\w*'),
                      '',
                    );
                    return letters.hasMatch(withoutInterp);
                  })
                  .length;
              if (staticSegments >= 2) {
                offenders.add('${f.path}:${i + 1}: $value');
              }
            }
          }
        }
        expect(
          offenders,
          isEmpty,
          reason:
              'Label song ngữ bị cấm (P0 §2) — dùng context.l10n.<key>:\n'
              '${offenders.join('\n')}',
        );
      });

      test(
        'every AppStrings key is referenced somewhere in lib/ (unused check)',
        () {
          final keys = RegExp(r'String get (\w+);')
              .allMatches(
                File('lib/core/l10n/app_strings.dart').readAsStringSync(),
              )
              .map((m) => m.group(1)!)
              .toList();
          expect(keys, isNotEmpty);

          final sources = Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))
              .map((f) => f.readAsStringSync())
              .join('\n');
          final unused = [
            for (final k in keys)
              if (!sources.contains('l10n.$k')) k,
          ];
          expect(
            unused,
            isEmpty,
            reason: 'Key khai báo nhưng không màn hình nào dùng: $unused',
          );
        },
      );

      test('vi and en implementations differ (no copy-paste locale)', () {
        const vi = AppStringsVi();
        const en = AppStringsEn();
        expect(vi.titleReports, isNot(en.titleReports));
        expect(vi.moreLoadSample, isNot(en.moreLoadSample));
        expect(vi.sectionGetStarted, isNot(en.sectionGetStarted));
      });
    },
  );

  group('runtime switching + persistence (production wiring)', () {
    Widget app(SharedPreferences prefs) => ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        customerRepositoryProvider.overrideWithValue(
          InMemoryCustomerRepository(),
        ),
        productRepositoryProvider.overrideWithValue(
          InMemoryProductRepository([]),
        ),
        orderRepositoryProvider.overrideWithValue(InMemoryOrderRepository()),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final code = ref.watch(languageProvider);
          return MaterialApp(
            locale: appLocale(code),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('vi')],
            home: const TongtaiMoreScreen(),
          );
        },
      ),
    );

    testWidgets(
      'switching locale re-renders the whole app in ONE language and persists',
      (tester) async {
        SharedPreferences.setMockInitialValues({'wz.locale': 'vi'});
        final prefs = await SharedPreferences.getInstance();
        await tester.pumpWidget(app(prefs));
        await tester.pumpAndSettle();

        // Vietnamese only — the English variant must NOT be on screen.
        expect(find.text('Nạp dữ liệu mẫu'), findsOneWidget);
        expect(find.text('Load sample data'), findsNothing);
        expect(find.text('Timeline · Dòng thời gian'), findsNothing);

        // Switch to English through the real notifier.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(TongtaiMoreScreen)),
        );
        await container.read(languageProvider.notifier).setLocale('en');
        await tester.pumpAndSettle();

        expect(find.text('Load sample data'), findsOneWidget);
        expect(find.text('Nạp dữ liệu mẫu'), findsNothing);

        // Persisted: a fresh app over the SAME prefs restarts in English.
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(app(prefs));
        await tester.pumpAndSettle();
        expect(find.text('Load sample data'), findsOneWidget);
        expect(find.text('Nạp dữ liệu mẫu'), findsNothing);
      },
    );
  });
}
