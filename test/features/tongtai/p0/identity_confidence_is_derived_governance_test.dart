import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **Confidence phải được TÍNH từ evidence, không do chỗ gọi khai** —
/// WTM-298 · D-1 · Founder Directive 2026-08-08 nguyên tắc 2.
///
/// ## Vì sao cần suite này
///
/// Bản trước của `IdentityCandidate` có trường `confidence` do chỗ gọi khai,
/// và ta đã phải thêm một lớp phòng thủ trong `resolve()` — hạ `exact` của ứng
/// viên về `strong` — **chính vì chỗ gọi có thể nói dối**. Lớp phòng thủ đó là
/// dấu hiệu API sai hình dạng, không phải giải pháp.
///
/// Nay chỗ gọi chỉ khai `IdentityEvidence`. Nhưng một nội quy *"đừng thêm
/// trường confidence lại"* sẽ bị vi phạm ngày ai đó thấy tiện — nhất là khi
/// viết connector và muốn đi tắt.
///
/// Bằng chứng điều đó xảy ra thật: COMP AI có fact ledger nghiêm ngặt từ
/// `20260801`, rồi **5 ngày sau** thêm `set_field_value` bỏ qua hoàn toàn.
/// Lý do là họ có **24 file test, 0 file kiểm ranh giới**.
///
/// ## Ba lớp, mạnh dần
///
/// 1. Không kiểu nào trong seam **nhận** confidence từ ngoài
/// 2. **Đúng một** hàm sinh ra `IdentityConfidence`
/// 3. Không bảng nào **lưu** confidence như giá trị khai
void main() {
  const evidenceFile = 'lib/features/tongtai/consumer/identity_evidence.dart';
  const resolverFile = 'lib/features/tongtai/consumer/identity_resolver.dart';
  const seamFiles = [evidenceFile, resolverFile];

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

  test('bộ quét thật sự đọc được code (chống PASS GIẢ)', () {
    // Bài học đã trả giá: một phép quét không tìm thấy gì vì nó **không đọc
    // được gì** trông y hệt một phép quét sạch. `\bdb\.` từng không khớp `_db`
    // và cho một lớp governance xanh oan.
    for (final f in seamFiles) {
      expect(File(f).existsSync(), isTrue, reason: '$f phải tồn tại');
      expect(code[f], isNotEmpty);
    }
    expect(code[evidenceFile], contains('ScoredIdentity scoreIdentity('));
    expect(code[resolverFile], contains('class IdentityCandidate'));
  });

  /// Cắt đúng thân MỘT lớp, dừng ở khai báo lớp kế tiếp.
  ///
  /// Cần thiết chứ không phải cầu kỳ: bản đầu của test này lấy substring tới
  /// hết file, nên nó "thấy" `AutoLink.confidence` — một trường hoàn toàn hợp
  /// lệ — và báo vi phạm. Một luật cấm hay báo động giả sẽ bị người ta tắt đi.
  String classBody(String source, String declaration) {
    final start = source.indexOf(declaration);
    if (start == -1) return '';
    final rest = source.substring(start + declaration.length);
    final end = rest.indexOf('\nclass ');
    return declaration + (end == -1 ? rest : rest.substring(0, end));
  }

  test('lớp 1 · không kiểu nào NHẬN confidence từ ngoài', () {
    final block = classBody(code[resolverFile]!, 'class IdentityCandidate');

    expect(
      RegExp(r'final\s+IdentityConfidence\s+confidence\s*;').hasMatch(block),
      isFalse,
      reason:
          'IdentityCandidate có trường `confidence` ⇒ chỗ gọi khai lại được',
    );
    expect(
      RegExp(r'this\.confidence').hasMatch(block),
      isFalse,
      reason: 'constructor nhận `confidence` ⇒ cửa sau đã mở',
    );
    // Và nó PHẢI tính ra, không phải nhận.
    expect(
      block,
      contains('scored = scoreIdentity(evidence)'),
      reason: 'mức tin cậy phải được tính trong constructor',
    );
  });

  test('lớp 1b · IdentityEvidence không mang trọng số hay điểm', () {
    final body = classBody(code[evidenceFile]!, 'class IdentityEvidence');

    for (final banned in ['double weight', 'double score', 'confidence']) {
      expect(
        body.contains(banned),
        isFalse,
        reason:
            'IdentityEvidence mang `$banned` ⇒ chỗ gọi định giá được quan sát '
            'của chính mình',
      );
    }
  });

  test('lớp 2 · ĐÚNG MỘT hàm sinh ra IdentityConfidence', () {
    // Hàm thứ hai gần như chắc chắn bỏ qua luật gộp nguồn/nhóm.
    var producers = 0;
    final signature = RegExp(
      r'(IdentityConfidence|ScoredIdentity)\s+_?[a-zA-Z]\w*\s*\(',
    );
    for (final entry in code.entries) {
      producers += signature.allMatches(entry.value).length;
    }
    expect(
      producers,
      2,
      reason:
          'chỉ được có `scoreIdentity` (public) và `_confidenceFor` (private). '
          'Thấy $producers — chỗ thứ ba là một đường định giá song song',
    );
    expect(code[evidenceFile], contains('ScoredIdentity scoreIdentity('));
    expect(code[evidenceFile], contains('IdentityConfidence _confidenceFor('));
  });

  test('lớp 2b · `exact` chỉ đến từ khoá nền tảng, không từ cộng dồn', () {
    final evidence = code[evidenceFile]!;
    final gate = evidence.substring(
      evidence.indexOf('IdentityConfidence _confidenceFor('),
    );
    expect(
      gate.indexOf('hasPlatformKey'),
      lessThan(gate.indexOf('IdentityConfidence.exact')),
      reason: 'cổng `exact` phải kiểm khoá nền tảng TRƯỚC khi trả exact',
    );
    // Và không có ngưỡng điểm nào dẫn tới `exact`.
    expect(
      RegExp(r'score\s*>=\s*\w*[Ee]xact').hasMatch(gate),
      isFalse,
      reason: '`exact` không được là một ngưỡng điểm',
    );
  });

  test('lớp 3 · không bảng nào lưu confidence như giá trị KHAI', () {
    final tables = Directory(
      'lib/database/tables',
    ).listSync().whereType<File>();
    var scanned = 0;
    for (final f in tables) {
      scanned++;
      final src = stripComments(f.readAsStringSync());
      // `external_identities_table` lưu `confidence` — nhưng đó là kết quả đã
      // tính, ghi lại để truy vết. Chỗ cấm là một cột nhận điểm thô.
      expect(
        src.contains('RealColumn get confidence') ||
            src.contains('RealColumn get score'),
        isFalse,
        reason: '${f.path}: cột điểm thô ⇒ chỗ gọi ghi được mức tin cậy tuỳ ý',
      );
    }
    // Chống PASS GIẢ: thư mục rỗng thì vòng lặp không chạy và test xanh oan.
    expect(scanned, greaterThan(10), reason: 'phải quét được các bảng thật');
  });

  test('bộ quét bắt được vi phạm khi vi phạm thật sự có mặt', () {
    // Một luật cấm chỉ đáng tin khi đã thấy nó bắt được thứ nó phải bắt.
    const offending = '''
      class IdentityCandidate {
        const IdentityCandidate({required this.confidence});
        final IdentityConfidence confidence;
      }
      IdentityConfidence guessIt(String signal) => IdentityConfidence.exact;
    ''';
    expect(
      RegExp(
        r'final\s+IdentityConfidence\s+confidence\s*;',
      ).hasMatch(offending),
      isTrue,
      reason: 'phải bắt được trường confidence',
    );
    expect(RegExp(r'this\.confidence').hasMatch(offending), isTrue);
    expect(
      RegExp(
        r'(IdentityConfidence|ScoredIdentity)\s+_?[a-zA-Z]\w*\s*\(',
      ).allMatches(offending).length,
      greaterThan(0),
      reason: 'phải bắt được hàm sinh confidence thứ hai',
    );
  });

  test('luật cũ của ADR-TON-024 vẫn còn nguyên', () {
    // WTM-298 chỉ đổi *ai tính ra mức*, không đổi *mức nào làm được gì*.
    final resolver = code[resolverFile]!;
    expect(resolver, contains('confidence == IdentityConfidence.exact'));
    expect(resolver, contains('canSuggest'));
    expect(
      resolver,
      isNot(contains('mergeCustomer')),
      reason: 'luật 4 không đổi',
    );
  });
}
