import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/l10n/app_strings.dart';
import 'package:tongtai/core/l10n/language_notifier.dart';

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
        // WTM-217 removed the last file-level exception (the unreachable
        // component showcase). An allowlisted FILE is a hole in the net, and
        // this net has been blind before (WTM-194) — keep it at zero.

        for (final f
            in uiDir
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart'))) {
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
        // Product names / brands render verbatim in every locale. No FILE is
        // exempt any more (WTM-217).
        const allowValues = ['Workizen AI', 'Tổng Tài', 'SKU'];
        for (final f
            in uiDir
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart'))) {
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

      test('⭐ chuỗi CÓ NỘI SUY cũng bị soi — chữ tiếng Anh cứng không lọt '
          '(WTM-344)', () {
        // ## Vì sao bài test cũ để lọt
        //
        // Bản trước bỏ qua **mọi** chuỗi chứa `$` với lý do
        // *"interpolation = data-driven"*. Điều đó đúng với `'$count đ'` và
        // **sai** với `'$count customers'`: phần chữ nằm NGOÀI chỗ nội suy vẫn
        // là nhãn người dùng đọc.
        //
        // Founder cầm máy ngày 10/8 và thấy **"42 opportunities"** trên một
        // màn tiếng Việt — trong khi 2494 test đang xanh. Governance chỉ bắt
        // được thứ nó được viết để tìm.
        //
        // ## Cách tránh báo nhầm
        //
        // Chỉ soi **vị trí text** trong `lib/features/tongtai/ui/` — nên mã
        // enum, log/debug, fixture test và dữ liệu doanh nghiệp demo (nằm ở
        // `simulation/`) đều không lọt vào tầm quét. Phần còn lại sau khi bóc
        // nội suy phải có một **từ ASCII ≥3 ký tự** không nằm trong danh sách
        // tên riêng — nên `'$count đ'`, `'$d/$m'`, `'$a · $b'` đều im lặng.
        final uiDir = Directory('lib/features/tongtai/ui');
        final position = RegExp(
          r"(?:Text\(\s*|label:\s*(?:const\s+)?(?:Text\(\s*)?|"
          r"title:\s*(?:const\s+)?(?:Text\(\s*)?|tooltip:\s*|labelText:\s*|"
          r"hintText:\s*|actionLabel:\s*|message:\s*|"
          r"content:\s*(?:const\s+)?Text\(\s*)'((?:[^'\\]|\\.)+)'",
        );
        // Nội suy: `${...}` và `$tên`.
        final interpolation = RegExp(r'\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_]*');
        final asciiWord = RegExp(r'[A-Za-z]{3,}');
        // Hiện nguyên văn ở mọi ngôn ngữ: tên riêng, đơn vị, viết tắt.
        const verbatim = {
          'workizen',
          'tongtai',
          'shopee',
          'tiktok',
          'shop',
          'facebook',
          'instagram',
          'telegram',
          'google',
          'drive',
          'excel',
          'alibaba',
          'aliexpress',
          'amazon',
          'ebay',
          'shopify',
          'woocommerce',
          'ghn',
          'ghtk',
          'viettel',
          'post',
          'jira',
          'confluence',
          'ollama',
          'grok',
          'sku',
          'roi',
          'aov',
          'csv',
          'qr',
          'api',
          'vnd',
          'xlsx',
          'ttbk',
        };

        final offenders = <String>[];
        for (final f
            in uiDir
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart'))) {
          final src = f.readAsStringSync();
          for (final m in position.allMatches(src)) {
            final value = m.group(1)!;
            if (!value.contains(r'$')) continue; // bài test trên lo phần này
            final residue = value.replaceAll(interpolation, ' ');
            final words = [
              for (final w in asciiWord.allMatches(residue))
                if (!verbatim.contains(w.group(0)!.toLowerCase())) w.group(0)!,
            ];
            if (words.isEmpty) continue;
            final line = src.substring(0, m.start).split('\n').length;
            offenders.add("${f.path}:$line: '$value' → $words");
          }
        }

        expect(
          offenders,
          isEmpty,
          reason:
              'Chuỗi nội suy trong vị trí text vẫn chứa chữ cứng — dùng một '
              "khoá nhận tham số (vd `l10n.countOrders(n)`):\n"
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

  group('⛔ MỘT locale — WTM-308', () {
    // Trước đây có bộ chọn ngôn ngữ và mặc định lấy ngôn ngữ MÁY, nên máy đặt
    // tiếng Anh thì nhãn ra tiếng Anh trong khi câu brief vẫn là dữ liệu tiếng
    // Việt đã lưu cùng bản ghi. Đó không phải lỗi dịch thiếu: câu brief chứa
    // tên khách và con số của chính doanh nghiệp này, và WTM-299 buộc nó phải
    // đi cùng bản ghi — dựng lại theo locale lúc hiển thị sẽ khiến mở một
    // quyết định cũ đọc ra câu khác câu lúc bấm.
    test('locale của app là hằng số, không hỏi máy', () {
      expect(kAppLocaleCode, 'vi');
    });

    test('màn Thêm KHÔNG còn mục chọn ngôn ngữ', () {
      // Một bộ chọn còn đó nghĩa là còn đường quay lại trạng thái nửa Việt nửa
      // Anh — thứ vừa bỏ.
      final source = File(
        'lib/features/tongtai/ui/screens/tongtai_more_screen.dart',
      ).readAsStringSync();
      expect(source.contains("more-language"), isFalse);
    });
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
