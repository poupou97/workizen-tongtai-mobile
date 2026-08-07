import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **Phân bổ là luật dẫn xuất, và luật dẫn xuất không được ghi xuống đĩa** —
/// ADR-TON-024 luật 2 (WTM-292 · N0.4).
///
/// ## Vì sao luật này cần một suite riêng
///
/// Phí vận chuyển gắn ở đơn; hoa hồng gắn ở món. Người bán vẫn muốn thấy *"món
/// này thật ra lãi bao nhiêu"*, nên phải chia phí đơn xuống món. Cám dỗ tự
/// nhiên là chia sẵn lúc ghi cho nhanh.
///
/// Làm vậy thì cùng một con số vừa được **lưu** (dòng cấp đơn) vừa được **tính
/// lại** (các dòng cấp món). Đó là P-27/P-28 — đã lặp **bốn lần** trong repo
/// này, mỗi lần đều xanh hết test cho tới khi hai bên lệch nhau.
///
/// Test hành vi bắt được *"lần ghi này có sinh thêm dòng không"*. Nó **không**
/// bắt được *"ngày mai có ai thêm một đường ghi mới không"*. Suite này bắt
/// điều thứ hai.
///
/// ## Ba lớp
///
/// 1. Module phân bổ **không import** repository/database — nó không có tay để
///    ghi.
/// 2. Hàm phân bổ **không trả về `SettlementLine`** — trả về `SettlementLine`
///    thì bước tiếp theo tự nhiên nhất của người đọc code là `upsertAll`.
/// 3. Repository **không có hàm nào sinh nhiều dòng từ một dòng**.
///
/// Cùng họ với `identity_no_auto_merge_governance_test` (WTM-291) và
/// `derived_data_governance_test` (WTM-212): một luật kiến trúc mà **không có
/// gì thất bại** khi nó bị vi phạm, nên phải dựng cái để thất bại.
void main() {
  const allocationFile =
      'lib/features/tongtai/finance/settlement_allocation.dart';
  const repositoryFile =
      'lib/features/tongtai/finance/settlement_repository.dart';

  /// Thứ một module thuần **không được** chạm.
  const writeImports = <String>[
    'settlement_repository.dart',
    'database/database.dart',
    'package:drift/drift.dart',
    'local_workspace.dart',
  ];

  String stripComments(String source) {
    final noBlock = source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    return noBlock
        .split('\n')
        .map((line) {
          final i = line.indexOf('//');
          return i == -1 ? line : line.substring(0, i);
        })
        .join('\n');
  }

  late final String allocation;
  late final String repository;

  setUpAll(() {
    allocation = File(allocationFile).readAsStringSync();
    repository = File(repositoryFile).readAsStringSync();
  });

  test('bộ quét thật sự đọc được file (chống PASS GIẢ)', () {
    // Bài học đã trả giá trong WTM-291: một phép quét không tìm thấy gì vì nó
    // **không đọc được gì** trông y hệt một phép quét sạch. Chứng minh trước.
    expect(allocation, contains('allocateByRevenue'));
    expect(repository, contains('class DriftSettlementRepository'));
  });

  test('lớp 1 · module phân bổ không có tay để ghi', () {
    final code = stripComments(allocation);
    for (final banned in writeImports) {
      expect(
        code,
        isNot(contains(banned)),
        reason:
            '$allocationFile import `$banned` ⇒ nó ghi được, và một luật dẫn '
            'xuất ghi được là một nguồn sự thật thứ hai (P-27/P-28)',
      );
    }
    // Và không có `await` nào: một hàm thuần thì không chờ ai cả.
    expect(
      code,
      isNot(contains('await ')),
      reason: 'phân bổ phải là hàm thuần, đồng bộ',
    );
  });

  test('lớp 2 · phân bổ không trả về SettlementLine', () {
    final code = stripComments(allocation);
    // Trả về `SettlementLine` thì bước tiếp theo tự nhiên nhất của bất kỳ ai
    // đọc code là đem chúng đi `upsertAll`. Kiểu trả về khác — không có `id`,
    // không có `provenance` — làm việc đó không viết ra được.
    expect(
      RegExp(r'(List<)?SettlementLine>?\s+\w+\s*\(').hasMatch(code),
      isFalse,
      reason: 'kết quả phân bổ phải là khung nhìn, không phải bản ghi lưu được',
    );
    expect(code, contains('AllocatedSettlement'));
    // Khung nhìn không được có `id` — không có khoá thì không ghi vào bảng
    // được, kể cả khi ai đó cố.
    final viewClass = code.substring(code.indexOf('class AllocatedSettlement'));
    expect(
      RegExp(r'final String id;').hasMatch(viewClass),
      isFalse,
      reason: 'AllocatedSettlement có `id` ⇒ nó lưu được ⇒ luật hỏng',
    );
  });

  test('lớp 3 · repository không sinh nhiều dòng từ một dòng', () {
    final code = stripComments(repository);

    // `insertAll*` chỉ được phép trong `upsertAll`, tức nơi caller đã đưa vào
    // một tập. Ngoài đó, một lần ghi nhiều dòng từ một đầu vào chính là phân
    // bổ ngầm.
    final bulkWrites = RegExp(r'insertAll\w*').allMatches(code).length;
    expect(
      bulkWrites,
      1,
      reason:
          'chỉ `upsertAll` được ghi hàng loạt. Thấy $bulkWrites chỗ — chỗ thứ '
          'hai gần như chắc chắn là phân bổ ngầm',
    );

    // Không hàm nào nhận MỘT dòng rồi lặp qua các món.
    expect(
      RegExp(r'for\s*\(.*orderItem').hasMatch(code),
      isFalse,
      reason: 'repository lặp qua món ⇒ nó đang chia khoản cấp đơn xuống món',
    );
    // Và nó không biết doanh thu từng món, nên không có gì để chia theo.
    expect(
      code,
      isNot(contains('ItemRevenues')),
      reason: 'repository chạm trọng số phân bổ ⇒ phân bổ đã lọt vào đường ghi',
    );
  });

  test('bộ quét bắt được vi phạm khi vi phạm thật sự có mặt', () {
    // Một luật cấm chỉ đáng tin khi đã thấy nó bắt được thứ nó phải bắt.
    const offending = '''
      List<SettlementLine> spread(SettlementLine line, ItemRevenues r) => [];
      class AllocatedSettlement { final String id; }
    ''';
    expect(
      RegExp(r'(List<)?SettlementLine>?\s+\w+\s*\(').hasMatch(offending),
      isTrue,
      reason: 'phải bắt được hàm trả về SettlementLine',
    );
    expect(
      RegExp(
        r'final String id;',
      ).hasMatch(offending.substring(offending.indexOf('class Allocated'))),
      isTrue,
      reason: 'phải bắt được khung nhìn có id',
    );
  });
}
