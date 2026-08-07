import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **Catalog và Matrix là DỮ LIỆU, không phải kiến thức của AI** —
/// ADR-TON-024 luật 3 (WTM-293 · N1/N2).
///
/// ## Hai điều suite này canh
///
/// **1. `recommended` không được lưu.** Một cờ gán tay là ý kiến đội lốt dữ
/// liệu: AI nói *"nên dùng X"* mà không ai truy được vì sao. Và nó là đúng họ
/// lỗi P-27/P-28 đã lặp bốn lần trong repo này — một trường được **lưu** trong
/// khi lẽ ra nó phải được **tính**.
///
/// **2. Hai cột đầu của ma trận không ra khỏi module.** `platformSupports` và
/// `connectorCovers` là thông tin nội bộ; chỉ `verifiedOnDogfood` nói được với
/// người bán. Nếu AI đọc nhầm cột đầu thành cột ba, nó sẽ nói *"đồng bộ tồn kho
/// Shopee được"* trong khi **chưa ai viết dòng code nào**.
///
/// ## Vì sao là suite quét mã nguồn
///
/// Cả hai đều cấm một **khả năng** tồn tại. Test hành vi chỉ chứng minh những
/// đường đã nghĩ ra; ngày ai đó thêm `bool recommended` vào bảng hoặc viết
/// `if (cell.platformSupports) return 'làm được'`, mọi test hành vi vẫn xanh.
///
/// Cùng họ với `identity_no_auto_merge_governance_test` (WTM-291) và
/// `settlement_no_derived_write_governance_test` (WTM-292).
void main() {
  const catalogFile = 'lib/features/tongtai/platform/vendor_catalog.dart';
  const matrixFile = 'lib/features/tongtai/platform/capability_matrix.dart';

  String stripComments(String source) {
    final noBlock = source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    return noBlock
        .split('\n')
        .map((line) {
          final i = line.indexOf('//');
          final j = line.indexOf('///');
          if (j != -1) return line.substring(0, j);
          return i == -1 ? line : line.substring(0, i);
        })
        .join('\n');
  }

  late final String catalog;
  late final String matrix;

  setUpAll(() {
    catalog = File(catalogFile).readAsStringSync();
    matrix = File(matrixFile).readAsStringSync();
  });

  test('bộ quét thật sự đọc được code (chống PASS GIẢ)', () {
    // Bài học WTM-291: một phép quét không tìm thấy gì vì nó **không đọc được
    // gì** trông y hệt một phép quét sạch. Chứng minh trước khi tin kết luận.
    expect(stripComments(catalog), contains('bool get recommended'));
    expect(stripComments(matrix), contains('class CapabilityClaim'));
  });

  test('luật 1 · `recommended` là getter, KHÔNG phải trường lưu được', () {
    final code = stripComments(catalog);
    expect(
      code,
      contains('bool get recommended'),
      reason: 'phải là hàm thuần tính lại mỗi lần đọc',
    );
    expect(
      RegExp(r'final\s+bool\s+recommended\b').hasMatch(code),
      isFalse,
      reason: 'một trường `recommended` là ý kiến đội lốt dữ liệu (P-27/P-28)',
    );
    expect(
      RegExp(r'this\.recommended\b').hasMatch(code),
      isFalse,
      reason: 'không constructor nào được nhận `recommended` từ ngoài',
    );
  });

  test('luật 1 · không bảng nào trong schema lưu `recommended`', () {
    // Đường ghi xuống đĩa là chỗ một giá trị dẫn xuất trở thành nguồn sự thật
    // thứ hai. Quét cả thư mục bảng thay vì chỉ file này.
    final tables = Directory(
      'lib/database/tables',
    ).listSync().whereType<File>();
    var scanned = 0;
    for (final f in tables) {
      scanned++;
      expect(
        f.readAsStringSync(),
        isNot(contains('recommended')),
        reason: '${f.path} lưu `recommended` ⇒ nó thành nguồn sự thật thứ hai',
      );
    }
    // Chống PASS GIẢ: thư mục rỗng thì vòng lặp không chạy và test xanh oan.
    expect(scanned, greaterThan(10), reason: 'phải quét được các bảng thật');
  });

  test('luật 1 · catalog không chạm cơ sở dữ liệu', () {
    final code = stripComments(catalog);
    for (final banned in [
      'package:drift/drift.dart',
      'database/database.dart',
      'local_workspace.dart',
    ]) {
      expect(
        code,
        isNot(contains(banned)),
        reason:
            'catalog là KIẾN THỨC CỦA APP, không phải dữ liệu người bán. Lưu '
            'nó vào SQLite sinh ra một bản sao cũ trên máy mỗi người, và mỗi '
            'lần sửa catalog lại thành một migration',
      );
    }
  });

  test('luật 2 · CapabilityClaim không mang hai cột đầu', () {
    final code = stripComments(matrix);
    final claim = code.substring(code.indexOf('class CapabilityClaim'));
    for (final column in ['platformSupports', 'connectorCovers']) {
      expect(
        claim.contains('final bool $column'),
        isFalse,
        reason:
            'CapabilityClaim mang `$column` ⇒ tầng AI cầm được nó ⇒ đọc nhầm '
            'được. AI chỉ được hứa ở `verifiedOnDogfood` (ADR-TON-024 luật 3)',
      );
    }
    // Và nó phải mang bằng chứng — một lời hứa không kèm bằng chứng thì không
    // phải lời hứa này.
    expect(claim, contains('final String evidence'));
  });

  test('luật 2 · constructor của CapabilityClaim là private', () {
    // Đây là chỗ luật thành cấu trúc: cách DUY NHẤT tạo ra một lời hứa là qua
    // `CapabilityCell.toClaim()`, và cổng đó chỉ mở khi cột D bật. Constructor
    // công khai thì bất kỳ ai cũng dựng được một lời hứa từ hư không.
    final code = stripComments(matrix);
    expect(
      code,
      contains('const CapabilityClaim._('),
      reason: 'constructor phải private',
    );
    expect(
      RegExp(r'const CapabilityClaim\(\{').hasMatch(code),
      isFalse,
      reason: 'có constructor công khai ⇒ cổng bị vòng qua',
    );
  });

  test('luật 2 · chỉ MỘT chỗ trong module dựng được CapabilityClaim', () {
    final code = stripComments(matrix);
    // `(?!\{)` loại khai báo `CapabilityClaim._({…})` ra khỏi phép đếm — chỉ
    // đếm **lời gọi**. Không có nó thì con số luôn thừa đúng một, và một luật
    // đếm sai là luật sẽ bị sửa cho khớp thay vì được tin.
    final built = RegExp(r'CapabilityClaim\._\((?!\{)').allMatches(code).length;
    expect(
      built,
      1,
      reason:
          'thấy $built chỗ dựng lời hứa. Chỗ thứ hai gần như chắc chắn bỏ qua '
          'phép kiểm `verifiedOnDogfood`',
    );
    // …và chỗ đó phải nằm sau một phép kiểm cột D.
    final gate = code.substring(code.indexOf('toClaim()'));
    expect(
      gate.indexOf('verifiedOnDogfood'),
      lessThan(gate.indexOf('CapabilityClaim._(')),
      reason: 'cổng phải kiểm cột D TRƯỚC khi dựng lời hứa',
    );
  });

  test('bộ quét bắt được vi phạm khi vi phạm thật sự có mặt', () {
    // Một luật cấm chỉ đáng tin khi đã thấy nó bắt được thứ nó phải bắt.
    const offending = '''
      class Vendor { final bool recommended; }
      class CapabilityClaim {
        const CapabilityClaim({required this.platformSupports});
        final bool platformSupports;
      }
    ''';
    expect(RegExp(r'final\s+bool\s+recommended\b').hasMatch(offending), isTrue);
    expect(offending.contains('final bool platformSupports'), isTrue);
    expect(RegExp(r'const CapabilityClaim\(\{').hasMatch(offending), isTrue);
  });
}
