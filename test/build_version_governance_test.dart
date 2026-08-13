import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **Số build phải TĂNG, và mỗi số chỉ được dùng MỘT lần** — WTM-401.
///
/// ## Vì sao cần một cổng ở đây
///
/// `versionCode` là thứ Android dùng để quyết định *"bản này mới hơn bản đang
/// cài không"*. Hạ nó xuống, hay dùng lại một số đã phát hành, thì:
///
/// * người dùng **không cập nhật được** (Play từ chối, cài đè thất bại);
/// * hai artefact khác nhau mang **cùng một số**, và không ai phân biệt được
///   nữa — kể cả khi đi điều tra một sự cố.
///
/// Cùng họ với mọi thứ repo này dọn: **một con số tự xưng là thứ nó không phải.**
///
/// Đây là cổng **cơ học**. Một dòng trong tài liệu nói "nhớ tăng versionCode"
/// không làm gì đỏ cả — và luật của repo là *bảng đứng im thì không có gì thất
/// bại*.
void main() {
  final pubspec = File('pubspec.yaml');
  final log = File('docs/04-DELIVERY/BUILD-LOG.md');
  final tool = File('tool/build_version.sh');

  int buildNumber() {
    final line = pubspec.readAsLinesSync().firstWhere(
      (l) => l.startsWith('version:'),
      orElse: () => '',
    );
    final plus = line.indexOf('+');
    expect(plus, greaterThan(-1), reason: 'pubspec version thiếu phần +build');
    return int.parse(line.substring(plus + 1).trim());
  }

  List<int> loggedBuilds() => log.existsSync()
      ? RegExp(r'^## build \+(\d+)', multiLine: true)
            .allMatches(log.readAsStringSync())
            .map((m) => int.parse(m.group(1)!))
            .toList()
      : <int>[];

  test('⭐ đọc được file thật (chống PASS giả)', () {
    // Không có cửa này thì mọi khẳng định dưới PASS trên một repo không có
    // pubspec — đúng loại xanh-rỗng suite này sinh ra để chặn.
    expect(pubspec.existsSync(), isTrue, reason: 'không thấy pubspec.yaml');
    expect(
      tool.existsSync(),
      isTrue,
      reason: 'không thấy tool/build_version.sh',
    );
    expect(buildNumber(), greaterThan(0));
  });

  test('⛔ pubspec KHÔNG được thấp hơn số build đã ghi trong log', () {
    // Thấp hơn nghĩa là ai đó đã hạ số build, và bản dựng kế tiếp sẽ mang một
    // số đã dùng rồi.
    final logged = loggedBuilds();
    // chưa có bản dựng nào được ghi — không có gì để so
    if (logged.isEmpty) return;
    expect(
      buildNumber(),
      greaterThanOrEqualTo(logged.reduce((a, b) => a > b ? a : b)),
      reason:
          'pubspec (+${buildNumber()}) thấp hơn log (+${logged.reduce((a, b) => a > b ? a : b)}) '
          '— bản dựng sau sẽ trùng số đã dùng',
    );
  });

  test('⛔ không số build nào xuất hiện HAI lần trong log', () {
    final logged = loggedBuilds();
    final seen = <int>{};
    final dup = <int>[];
    for (final b in logged) {
      if (!seen.add(b)) dup.add(b);
    }
    expect(
      dup,
      isEmpty,
      reason:
          'số build trùng: $dup — hai artefact khác nhau mang cùng một số thì '
          'không ai phân biệt được nữa',
    );
  });

  test('⛔ log xếp giảm dần — mục mới nhất ở trên', () {
    final logged = loggedBuilds();
    final sorted = [...logged]..sort((a, b) => b.compareTo(a));
    expect(
      logged,
      sorted,
      reason: 'BUILD-LOG không giảm dần: $logged — mục mới phải nằm trên',
    );
  });

  test('⭐ mọi bản dựng đã ghi đều được ĐÓNG bằng OK hoặc FAILED', () {
    // Một mục treo ở "ĐANG DỰNG" nghĩa là có một số build đã đốt mà không ai
    // biết nó thành hay bại. Đó là chỗ một artefact vô danh lọt ra ngoài.
    if (!log.existsSync()) return;
    final body = log.readAsStringSync();
    final pending = RegExp(
      r'^## build \+(\d+).*?\n- Trạng thái: ⏳',
      multiLine: true,
      dotAll: true,
    ).allMatches(body).map((m) => m.group(1)).toList();
    expect(
      pending,
      isEmpty,
      reason:
          'build $pending còn treo ở "ĐANG DỰNG" — chạy '
          '`tool/build_version.sh record OK|FAILED`',
    );
  });

  test('⛔ script KHÔNG được hoàn lại số build khi dựng hỏng', () {
    // Cách "dễ" là revert số build để dãy số không thủng. Cửa này chặn đúng
    // đường tắt ấy: số đã đốt là một sự kiện đã xảy ra.
    final src =
        tool.readAsStringSync() +
        File('tool/build_release.sh').readAsStringSync();
    expect(
      RegExp(
        r'(revert|hoàn lại|rollback).*(build|version)',
        caseSensitive: false,
      ).hasMatch(src.replaceAll(RegExp(r'^#.*$', multiLine: true), '')),
      isFalse,
      reason:
          'có mã hoàn lại số build — thủng dãy số vô hại, dùng lại số thì không',
    );
    expect(
      src.contains('FAILED'),
      isTrue,
      reason:
          'không có đường ghi FAILED ⇒ một bản dựng hỏng sẽ biến mất khỏi lịch sử',
    );
  });
}
