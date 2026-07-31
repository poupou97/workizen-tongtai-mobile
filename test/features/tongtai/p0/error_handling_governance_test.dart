import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// WTM-148 / ADR-TON-017 — **architecture governance for error handling.**
///
/// ADR-TON-015 established that business data flows one way. WTM-148 adds the
/// other half: **failure** flows one way too. A screen that invents its own
/// "something went wrong" card, its own spinner, or its own silent `catch` is
/// how the product ends up unable to tell a user whether their data is missing
/// or merely unreadable — the bug this whole story removes.
///
/// These are static scans on purpose. A behaviour test proves one screen does
/// the right thing today; a scan proves the twenty-sixth screen cannot do the
/// wrong thing tomorrow.
void main() {
  final uiFiles = Directory('lib/features/tongtai/ui')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  /// The seam itself is allowed to do what it forbids everyone else.
  const seamFile = 'lib/features/tongtai/ui/widgets/tongtai_screen_data.dart';

  List<String> codeLines(File file) {
    return file.readAsLinesSync().where((line) {
      final trimmed = line.trimLeft();
      return !trimmed.startsWith('//') && !trimmed.startsWith('///');
    }).toList();
  }

  test('every screen with a data path goes through the shared seam', () {
    // Screens that read or write through an IO boundary — a repository, a
    // controller's `hydrate`, a provider future, a file. Each must reference
    // the seam; a screen added here without one fails this test in the PR that
    // adds it, not in the field.
    const seamSymbols = [
      'ScreenDataController',
      'TongtaiScreenData',
      'TongtaiAsyncScreenData',
      'runTongtaiAction',
      'TongtaiLoadingView',
    ];
    final ioPattern = RegExp(
      r'ref\.read\([a-zA-Z]+(Repository|Store|Service|Seeder)Provider\)'
      r'|\.hydrate\(\)'
      r'|Provider\.future\)',
    );

    final offenders = <String>[];
    for (final file in uiFiles) {
      if (file.path.endsWith('tongtai_screen_data.dart')) continue;
      final source = file.readAsStringSync();
      if (!ioPattern.hasMatch(source)) continue;
      if (seamSymbols.any(source.contains)) continue;
      offenders.add(file.path);
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Màn có đọc/ghi IO phải đi qua seam dùng chung '
          '(ScreenDataController / TongtaiScreenData / runTongtaiAction) — '
          'xem docs/03-DECISIONS/ADR-TON-017-error-handling-seam.md:\n'
          '${offenders.join('\n')}',
    );
  });

  test('no screen hand-rolls an indeterminate progress indicator', () {
    // Determinate bars (`value:`) are data — a goal's progress, a margin.
    // Indeterminate ones are a *state*, and states belong to the seam:
    // `TongtaiLoadingView` for a load, `TongtaiInlineBusy` for an action the
    // user started. Without this rule the non-animating loading contract
    // (which is what lets every widget test settle) erodes one screen at a
    // time.
    final offenders = <String>[];
    for (final file in uiFiles) {
      if (file.path == seamFile) continue;
      final lines = codeLines(file);
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!line.contains('CircularProgressIndicator') &&
            !line.contains('LinearProgressIndicator')) {
          continue;
        }
        // A determinate indicator states its value on the same line or the
        // next few (formatter-wrapped constructor).
        final window = lines.skip(i).take(4).join(' ');
        if (window.contains('value:')) continue;
        offenders.add('${file.path}:${i + 1}: ${line.trim()}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Spinner vô hạn phải dùng TongtaiLoadingView / TongtaiInlineBusy — '
          'màn tự chế sẽ làm pumpAndSettle treo và phá hợp đồng "loading '
          'không animation" (ADR-TON-017 §4):\n'
          '${offenders.join('\n')}',
    );
  });

  test('no screen catches an error by hand', () {
    // Every catch in `ui/` is a chance to swallow one. There is exactly one
    // approved way to run fallible work from a screen — `runTongtaiAction` for
    // writes, `ScreenDataController` for reads — and both classify, surface
    // and report. The seam file itself is exempt.
    final offenders = <String>[];
    final catchPattern = RegExp(r'\bcatch\s*\(|\bon\s+\w+\s+catch\b');
    for (final file in uiFiles) {
      if (file.path == seamFile) continue;
      final lines = codeLines(file);
      for (var i = 0; i < lines.length; i++) {
        if (catchPattern.hasMatch(lines[i])) {
          offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Không bắt lỗi thủ công trong ui/ — dùng runTongtaiAction hoặc '
          'ScreenDataController để lỗi được phân loại, hiển thị và báo cáo '
          'đúng một kiểu (ADR-TON-017):\n'
          '${offenders.join('\n')}',
    );
  });

  test('no screen renders an AsyncValue or a Future directly', () {
    // `FutureBuilder` and `AsyncValue.when` both collapse to three cases and
    // have no vocabulary for *stale* — so a failed refresh under either one
    // silently blanks a page that was working. `TongtaiAsyncScreenData` is the
    // adapter that keeps provider-backed screens in the same six states.
    final offenders = <String>[];
    for (final file in uiFiles) {
      if (file.path == seamFile) continue;
      final lines = codeLines(file);
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('FutureBuilder') ||
            RegExp(r'\.when\(\s*$|\.when\(loading').hasMatch(lines[i])) {
          offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Dùng TongtaiAsyncScreenData thay cho FutureBuilder/.when — hai thứ '
          'này không có trạng thái "dữ liệu cũ", nên refresh lỗi sẽ xoá trắng '
          'màn đang chạy (ADR-TON-017):\n'
          '${offenders.join('\n')}',
    );
  });

  test('the database provider is declared exactly once', () {
    // Regression lock, WTM-148. `tongtai_search_provider.dart` used to declare
    // a SECOND `tongtaiDatabaseProvider`: production opened two connections to
    // the same file, and a test that overrode "the" database only overrode the
    // half of the app that imported the other one — which is how Home could
    // fail to read while every assertion passed. One provider, one database
    // (ADR-TON-015 One Data Path).
    final declarations = <String>[];
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('final tongtaiDatabaseProvider')) {
          declarations.add('${file.path}:${i + 1}');
        }
      }
    }

    expect(
      declarations,
      hasLength(1),
      reason:
          'Chỉ được có MỘT tongtaiDatabaseProvider — nhiều khai báo nghĩa là '
          'app mở nhiều kết nối vào cùng một file .db và test override chỉ '
          'trúng một nửa:\n${declarations.join('\n')}',
    );
  });

  test('failure telemetry can only carry kind, code and screen', () {
    // The privacy red-line, enforced where it is written rather than only
    // where it is called: `TongtaiFailure.telemetryParams` is the single
    // source of what leaves the device, and the reporter adds nothing but the
    // screen name. A message, a customer, a revenue figure must not be
    // reachable from either.
    final controller = File(
      'lib/features/tongtai/core/screen_data_controller.dart',
    ).readAsStringSync();

    expect(
      controller.contains('failure.telemetryParams'),
      isTrue,
      reason: 'telemetry phải đi qua telemetryParams, không tự dựng map',
    );
    expect(
      RegExp(
        r"logEvent\([^)]*'(detail|message|name|phone|email)'",
      ).hasMatch(controller),
      isFalse,
      reason: 'không được gửi nội dung nghiệp vụ lên telemetry',
    );
    expect(
      controller.contains('failure.detail'),
      isFalse,
      reason:
          'detail chỉ hiển thị trên máy người dùng — không được chạm vào '
          'đường báo cáo (ADR-TON-005 / ADR-TON-017 §5)',
    );

    final state = File(
      'lib/features/tongtai/core/screen_state.dart',
    ).readAsStringSync();
    final toString = state.substring(state.indexOf('String toString() =>'));
    expect(
      toString.split(';').first.contains('detail'),
      isFalse,
      reason:
          'TongtaiFailure.toString() được crash reporter ghi lại — nó phải '
          'chỉ mang kind/code',
    );
  });

  test('the screen_error event is declared in the telemetry catalogue', () {
    final catalogue = File(
      'docs/05-OPERATIONS/TELEMETRY-EVENTS.md',
    ).readAsStringSync();
    expect(
      catalogue.contains('screen_error'),
      isTrue,
      reason:
          'Mọi event mới phải được khai báo trong TELEMETRY-EVENTS.md '
          '(D-7 / ADR-TON-005)',
    );
  });

  test('production code never defaults to an in-memory store', () {
    // WTM-164 found `tongtai_export_screen` doing exactly this: it defaulted
    // to `InMemoryTongtaiExportHistoryStore` in production, so the export
    // history WTM-99 promised was wiped on every launch while the persistent
    // implementation sat unused. In-memory implementations are for tests and
    // for explicitly-named `.inMemory()` factories — never a silent fallback.
    final offenders = <String>[];
    final fallback = RegExp(r'\?\?\s*(const\s+)?InMemory');
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (fallback.hasMatch(line)) {
          offenders.add('${file.path}:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Production KHÔNG được rơi về InMemory store — dữ liệu sẽ mất lặng '
          'lẽ sau mỗi lần khởi động lại (WTM-164). Dùng implementation bền và '
          'inject InMemory ở test:\n${offenders.join('\n')}',
    );
  });

  test('the app version stamped into backups matches pubspec', () {
    // `kTongtaiAppVersion` is written into every `.ttbk` manifest and shown in
    // the restore preview. A stale constant would make a backup claim it came
    // from a version that never existed.
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final versionLine = pubspec.firstWhere((l) => l.startsWith('version:'));
    final pubspecVersion = versionLine.split(':')[1].trim().split('+').first;
    final format = File(
      'lib/features/tongtai/export/backup_format.dart',
    ).readAsStringSync();

    expect(
      format,
      contains("kTongtaiAppVersion = '$pubspecVersion'"),
      reason:
          'kTongtaiAppVersion phải bằng version trong pubspec.yaml '
          '($pubspecVersion)',
    );
  });

  test('backup telemetry carries no file path, name or business counts', () {
    // The restore flow handles a user-chosen file. Its path and name are the
    // user's, and its contents are their business — none of it may be
    // reported (Founder rule, WTM-164).
    final screen = File(
      'lib/features/tongtai/ui/screens/tongtai_backup_screen.dart',
    ).readAsStringSync();
    final calls = RegExp(
      r'runTongtaiAction\([\s\S]*?screen: .backup.,',
    ).allMatches(screen);
    expect(calls, isNotEmpty, reason: 'the screen must guard its actions');

    for (final call in calls) {
      final text = call.group(0)!;
      for (final leak in ['path', 'fileName', 'counts', 'armored']) {
        expect(
          RegExp("'\$leak':").hasMatch(text),
          isFalse,
          reason: 'telemetry may not carry $leak',
        );
      }
    }
  });
}
