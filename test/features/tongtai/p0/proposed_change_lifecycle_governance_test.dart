import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **Thay đổi do AI đề nghị phải đi qua vòng đời, không ghi thẳng** —
/// WTM-299 · D-2 · Founder Directive 2026-08-08 nguyên tắc 3.
///
/// ## Bằng chứng vì sao cần suite này
///
/// COMP AI có fact ledger nghiêm ngặt từ migration `20260801`: evidence bắt
/// buộc, bốn trạng thái, cổng human-owned. **Năm ngày sau**, `20260806` thêm
/// dynamic fields với `set_field_value` — **không evidence, không vòng đời,
/// ghi thẳng vào bản ghi**.
///
/// Không ai làm sai. Chỉ là **không có gì bắt kỷ luật lan sang bề mặt mới**:
/// 24 file test, 0 file kiểm ranh giới, `biome.jsonc` không có
/// `no-restricted-imports`.
///
/// ## Ba lớp
///
/// 1. Cổng là **hàm thuần** — không chạm DB, nên không có đường vòng
/// 2. **Đúng một** chỗ chuyển đề xuất khỏi `proposed`
/// 3. `superseded` **không xoá** dòng cũ
void main() {
  const gateFile = 'lib/features/tongtai/proposal/proposal_gate.dart';
  const repoFile =
      'lib/features/tongtai/proposal/proposed_change_repository.dart';
  const modelFile = 'lib/features/tongtai/proposal/proposed_change.dart';
  const seamFiles = [gateFile, repoFile, modelFile];

  String stripComments(String source) {
    final noBlock = source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    return noBlock
        .split('\n')
        .map((line) {
          final doc = line.indexOf('///');
          if (doc != -1) return line.substring(0, doc);
          final i = line.indexOf('//');
          return i == -1 ? line : line.substring(0, i);
        })
        .join('\n');
  }

  late final Map<String, String> code;

  setUpAll(() {
    code = {
      for (final f in seamFiles) f: stripComments(File(f).readAsStringSync()),
    };
  });

  /// Thân MỘT phương thức trong lớp cài đặt, dừng ở phương thức kế tiếp.
  ///
  /// Cần hai lớp cắt chứ không phải một, và bản đầu của suite này sai đúng chỗ
  /// đó: `indexOf('Future<int> supersedeOlder(')` tìm thấy **khai báo trong
  /// abstract class** trước, nên "thân phương thức" hoá ra là constructor của
  /// lớp Drift. Test đỏ vì lý do sai — và một luật cấm hay báo động giả sẽ bị
  /// người ta tắt đi.
  String methodBody(String source, String signature) {
    final impl = source.substring(
      source.indexOf('class DriftProposedChangeRepository'),
    );
    final start = impl.indexOf(signature);
    if (start == -1) return '';
    final rest = impl.substring(start + signature.length);
    final end = rest.indexOf('\n  @override');
    return signature + (end == -1 ? rest : rest.substring(0, end));
  }

  test('bộ quét thật sự đọc được code (chống PASS GIẢ)', () {
    for (final f in seamFiles) {
      expect(File(f).existsSync(), isTrue, reason: '$f phải tồn tại');
      expect(code[f], isNotEmpty);
    }
    expect(code[gateFile], contains('ProposalOutcome evaluate('));
    expect(code[repoFile], contains('class DriftProposedChangeRepository'));
  });

  test('lớp 1 · cổng KHÔNG có tay để ghi', () {
    // Cổng là luật nghiệp vụ. Nếu nó chạm được DB thì nó vừa quyết vừa ghi, và
    // "chỉ một chỗ quyết định" mất ý nghĩa.
    final gate = code[gateFile]!;
    for (final banned in [
      'package:drift/drift.dart',
      'database/database.dart',
      'local_workspace.dart',
      'await ',
    ]) {
      expect(
        gate.contains(banned),
        isFalse,
        reason:
            '$gateFile chạm `$banned` ⇒ cổng ghi được, và luật nghiệp vụ dính '
            'vào chi tiết lưu trữ',
      );
    }
  });

  test('lớp 1b · model KHÔNG chạm cơ sở dữ liệu', () {
    final model = code[modelFile]!;
    for (final banned in [
      'package:drift/drift.dart',
      'database/database.dart',
    ]) {
      expect(model.contains(banned), isFalse, reason: '$modelFile: `$banned`');
    }
  });

  test('lớp 2 · ĐÚNG MỘT chỗ chuyển đề xuất khỏi `proposed`', () {
    // Chỗ thứ hai gần như chắc chắn bỏ qua điều kiện chống đua
    // `where status = proposed`.
    final repo = code[repoFile]!;
    final writes = RegExp(
      r'\.write\(\s*ProposedChangesTableCompanion',
    ).allMatches(repo).length;
    expect(
      writes,
      2,
      reason:
          'chỉ được có `_decide` (apply/dismiss) và `supersedeOlder`. '
          'Thấy $writes — chỗ thứ ba là một đường đổi trạng thái song song',
    );

    // `_decide` phải có điều kiện chống đua.
    final decide = methodBody(repo, 'Future<bool> _decide(');
    expect(
      decide.indexOf('ProposalStatus.proposed.code'),
      lessThan(decide.indexOf('.write(')),
      reason:
          '`_decide` phải kiểm `status = proposed` TRƯỚC khi ghi — nếu không, '
          'lần bấm thứ hai ghi đè quyết định đầu',
    );
  });

  test('lớp 2b · `propose` luôn đi qua cổng trước khi ghi', () {
    final repo = code[repoFile]!;
    final body = methodBody(repo, 'Future<ProposalOutcome> propose(');

    expect(
      body.indexOf('_gate.evaluate('),
      lessThan(body.indexOf('.insertOnConflictUpdate(')),
      reason: 'phải gọi cổng TRƯỚC khi ghi',
    );
    expect(
      body,
      contains('if (outcome is ProposalRejected) return outcome;'),
      reason: 'bị từ chối thì phải dừng, không ghi',
    );
  });

  test('lớp 3 · `superseded` KHÔNG xoá dòng cũ', () {
    // Fact cũ giữ lại là thứ cho phát hiện thay đổi miễn phí — cùng cơ chế
    // `lastEmployerChange()` của COMP AI.
    final repo = code[repoFile]!;
    final body = methodBody(repo, 'Future<int> supersedeOlder(');

    expect(
      body.contains('delete('),
      isFalse,
      reason: 'thay thế phải là đổi trạng thái, không phải xoá',
    );
    expect(body, contains('ProposalStatus.superseded.code'));
  });

  test('lớp 3b · MỌI đường xoá đều có phạm vi khai rõ', () {
    // Luật gốc (WTM-299) là "chỉ `deleteAll` được xoá". WTM-307 thêm một
    // đường thứ hai — đặt lại dữ liệu mẫu — và đó là một nhu cầu thật: gieo
    // lại dữ liệu mẫu mà giữ quyết định cũ thì Founder không xem lại được
    // flow từ đầu.
    //
    // Nới luật thành "xoá thoải mái" sẽ mất đúng thứ nó bảo vệ. Nên luật đổi
    // thành: **mỗi đường xoá phải nói được nó xoá tới đâu**, và chỉ có hai
    // phạm vi hợp lệ.
    final repo = code[repoFile]!;
    final deletes = RegExp(r'_db\.delete\(').allMatches(repo).length;
    expect(
      deletes,
      2,
      reason:
          'hai đường: `deleteAll` (restore Replace) và '
          '`deleteForSampleSubjects` (đặt lại demo). Thấy $deletes — đường thứ '
          'ba phải khai phạm vi ở đây trước',
    );

    // Đường 1 — toàn bộ, và chỉ dùng cho restore Replace (WTM-164).
    expect(
      methodBody(repo, 'Future<void> deleteAll('),
      contains('_db.delete('),
    );

    // Đường 2 — CHẶN bằng tiền tố mẫu. Thiếu mệnh đề này thì "đặt lại demo"
    // sẽ cuốn theo mọi quyết định người bán đã ra cho khách thật của họ.
    final sampleOnly = methodBody(repo, 'Future<int> deleteForSampleSubjects(');
    expect(
      sampleOnly,
      contains('kSampleIdPrefix'),
      reason: 'xoá theo phạm vi mẫu phải dùng HẰNG SỐ tiền tố, không viết tay',
    );
    expect(
      sampleOnly,
      contains('subjectId.like('),
      reason: 'thiếu mệnh đề chặn ⇒ xoá sạch dưới cái tên "đặt lại demo"',
    );
  });

  test('bảng KHÔNG có cột điểm/confidence thô', () {
    // Lưu một con số khai sẵn ở đây là mở lại đúng cửa sau WTM-298 vừa đóng.
    final table = stripComments(
      File('lib/database/tables/proposed_changes.dart').readAsStringSync(),
    );
    expect(table, contains('TextColumn get evidence'));
    for (final banned in [
      'RealColumn get confidence',
      'RealColumn get score',
      'TextColumn get confidence',
    ]) {
      expect(table.contains(banned), isFalse, reason: banned);
    }
  });

  test('bộ quét bắt được vi phạm khi vi phạm thật sự có mặt', () {
    const offending = '''
      import 'package:drift/drift.dart';
      class ProposalGate {
        Future<void> evaluate() async { await db.delete(x); }
      }
    ''';
    expect(offending.contains('package:drift/drift.dart'), isTrue);
    expect(offending.contains('await '), isTrue);

    const badRepo = '''
      await (_db.update(t)).write(ProposedChangesTableCompanion(x: y));
      await (_db.update(t)).write(ProposedChangesTableCompanion(a: b));
      await (_db.update(t)).write(ProposedChangesTableCompanion(c: d));
    ''';
    expect(
      RegExp(
        r'\.write\(\s*ProposedChangesTableCompanion',
      ).allMatches(badRepo).length,
      greaterThan(2),
      reason: 'phải đếm được đường đổi trạng thái thứ ba',
    );
  });
}
