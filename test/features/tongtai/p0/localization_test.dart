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

      test('no UI string literal concatenates two languages around " | "', () {
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
              if (!value.contains(' | ')) continue;
              final staticSegments = value
                  .substring(1, value.length - 1)
                  .split(' | ')
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
              'Label song ngữ "vi | en" bị cấm (P0 §2) — dùng '
              'context.l10n.<key>:\n${offenders.join('\n')}',
        );
      });

      test('no Vietnamese hard-coded literal remains under ui/ (P0 §2)', () {
        // After WTM-145 every user-facing string in lib/features/tongtai/ui/
        // comes from AppStrings — a Vietnamese literal in a widget can only
        // mean a new hard-coded label snuck in.
        final uiDir = Directory('lib/features/tongtai/ui');
        final offenders = <String>[];
        final literal = RegExp("'([^'\\\\]|\\\\.)*'");
        final viLetters = RegExp(
          '[àáảãạâầấẩẫậăằắẳẵặèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộ'
          'ơờớởỡợùúủũụưừứửữựỳýỷỹỵ]',
        );
        // Proper nouns that legitimately keep their Vietnamese spelling in
        // any locale (product name only — example hints live in AppStrings).
        const allowlist = ['Tổng Tài'];
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
              var value = m.group(0)!;
              for (final ok in allowlist) {
                value = value.replaceAll(ok, '');
              }
              if (viLetters.hasMatch(value)) {
                offenders.add('${f.path}:${i + 1}: ${m.group(0)!}');
              }
            }
          }
        }
        expect(
          offenders,
          isEmpty,
          reason:
              'Chuỗi tiếng Việt hard-code trong ui/ bị cấm (P0 §2) — dùng '
              'context.l10n.<key>:\n${offenders.join('\n')}',
        );
      });

      test('no English hard-coded literal remains under ui/ (WTM-194)', () {
        // The sibling test above looks for *Vietnamese* letters, because it was
        // written after WTM-145 to clean up Vietnamese literals. That makes it
        // blind to English ones — and this product is Vietnamese-first (D-8),
        // so an English literal is the version a real seller actually sees.
        //
        // WTM-194 found ~35 of them across 12 real screens: the goal form, the
        // customer form, the opportunity feed's empty state, Home's empty
        // states. Exactly the WTM-173 defect ("badge on Home shows English in
        // the Vietnamese build"), 35 times over, with nothing failing.
        final uiDir = Directory('lib/features/tongtai/ui');
        final offenders = <String>[];
        final literal = RegExp("'([^'\\\\]|\\\\.)*'");
        // Two or more words of plain Latin text — the shape of a sentence a
        // seller reads, not of a key, a path, or a format pattern.
        final prose = RegExp(r"^[A-Za-z][A-Za-z ,.'’!?%-]*$");

        // Allowed on purpose, each for a reason that survives review:
        // - `Workizen AI` is the **brand** users interact with (ADR-TON-006);
        //   translating it would break the one name the product promises.
        const allowedPhrases = ['Workizen AI'];
        // - the showcase is a developer screen, never shipped in a menu.
        const allowedFiles = ['tongtai_component_showcase_screen.dart'];

        for (final f
            in uiDir
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart'))) {
          if (allowedFiles.any(f.path.endsWith)) continue;
          // Blank out `assert(...)` bodies first: an assertion message is
          // developer text that never reaches a seller, and it is written in
          // English on purpose.
          final lines = _withoutAsserts(f.readAsStringSync()).split('\n');
          for (var i = 0; i < lines.length; i++) {
            final trimmed = lines[i].trimLeft();
            if (trimmed.startsWith('//')) continue;
            // An `expect(..., reason: '...')`-style string is developer text.
            if (trimmed.startsWith('reason:')) continue;
            for (final m in literal.allMatches(lines[i])) {
              var value = m.group(0)!;
              value = value.substring(1, value.length - 1);
              for (final ok in allowedPhrases) {
                value = value.replaceAll(ok, '');
              }
              if (value.trim().split(RegExp(r'\s+')).length < 2) continue;
              if (!prose.hasMatch(value)) continue;
              offenders.add('${f.path}:${i + 1}: ${m.group(0)!}');
            }
          }
        }
        expect(
          offenders,
          isEmpty,
          reason:
              'Chuỗi tiếng Anh hard-code trong ui/ bị cấm — sản phẩm lấy tiếng '
              'Việt làm chính (D-8), nên chuỗi này là thứ người bán thật nhìn '
              'thấy. Dùng context.l10n.<key>:\n${offenders.join('\n')}',
        );
      });

      test('ui/ never reads labelVi/labelEn directly — label(locale) only', () {
        // Domain enums keep labelVi/labelEn, but a widget picking one side
        // hard-wires a language and breaks runtime switching (P0 §2).
        final uiDir = Directory('lib/features/tongtai/ui');
        final offenders = <String>[];
        final direct = RegExp(r'\.label(Vi|En)\b');
        for (final f
            in uiDir
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart'))) {
          final lines = f.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i].trimLeft();
            if (line.startsWith('//') || line.startsWith('///')) continue;
            if (direct.hasMatch(lines[i])) {
              offenders.add('${f.path}:${i + 1}: ${lines[i].trim()}');
            }
          }
        }
        expect(
          offenders,
          isEmpty,
          reason:
              'UI phải gọi label(context.l10n.languageCode) thay vì '
              'labelVi/labelEn:\n${offenders.join('\n')}',
        );
      });

      test('NO string literal in any ui/ text position — keys only (§3)', () {
        // The complete ratchet (WTM-146): after the EN sweep, every string
        // rendered by a widget must come from AppStrings. A quoted literal in
        // a text position can only be a new hard-coded label.
        final uiDir = Directory('lib/features/tongtai/ui');
        final offenders = <String>[];
        // Text positions: Text('..'), label:/title:/tooltip:/hintText:/
        // labelText:/actionLabel:/message: '..' (optionally const Text(..)).
        final position = RegExp(
          r"(?:Text\(\s*|label:\s*(?:const\s+)?(?:Text\(\s*)?|"
          r"title:\s*(?:const\s+)?(?:Text\(\s*)?|tooltip:\s*|labelText:\s*|"
          r"hintText:\s*|actionLabel:\s*|message:\s*|"
          r"content:\s*(?:const\s+)?Text\(\s*)'((?:[^'\\]|\\.)+)'",
        );
        final letters = RegExp('[A-Za-zÀ-ỹ]{2,}');
        // Product names / brands render verbatim in every locale. The dev-only
        // component showcase is unreachable from production navigation.
        const allowValues = ['Workizen AI', 'Tổng Tài', 'SKU'];
        const allowFiles = ['tongtai_component_showcase_screen.dart'];
        for (final f
            in uiDir
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart'))) {
          if (allowFiles.any((ok) => f.path.endsWith(ok))) continue;
          final src = f.readAsStringSync();
          for (final m in position.allMatches(src)) {
            final value = m.group(1)!;
            if (value.contains(r'$')) continue; // interpolation = data-driven
            if (allowValues.contains(value)) continue;
            if (!letters.hasMatch(value)) continue; // symbols/numbers only
            final line = src.substring(0, m.start).split('\n').length;
            offenders.add('${f.path}:$line: \'$value\'');
          }
        }
        expect(
          offenders,
          isEmpty,
          reason:
              'Chuỗi hard-code trong vị trí text của ui/ bị cấm (P0 §3) — '
              'dùng context.l10n.<key>:\n${offenders.join('\n')}',
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

/// Replaces the contents of every `assert(...)` with spaces, preserving line
/// structure so reported line numbers stay correct.
///
/// Assertion messages are for whoever breaks the invariant, not for the seller,
/// so the English-literal scan must not read them as UI copy.
String _withoutAsserts(String source) {
  final out = source.split('');
  var i = 0;
  while (true) {
    final start = source.indexOf('assert(', i);
    if (start < 0) break;
    var depth = 0;
    var j = start + 'assert'.length;
    for (; j < source.length; j++) {
      final c = source[j];
      if (c == '(') depth++;
      if (c == ')') {
        depth--;
        if (depth == 0) break;
      }
    }
    for (var k = start; k <= j && k < source.length; k++) {
      if (out[k] != '\n') out[k] = ' ';
    }
    i = j + 1;
  }
  return out.join();
}
