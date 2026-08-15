// P0 — **cổng Business Truth**: giao diện không được bày một tuyên bố kinh
// doanh mà không truy được nguồn (WTM-421, Founder chốt 2026-08-15).
//
// ## Chuyện đã xảy ra
//
// `supplier_detail_screen` bày bốn thứ, không thứ nào là sự thật:
//
//   * **chứng chỉ** — `ISO 9001` gán cho MỌI nhà cung cấp, phần còn lại suy từ
//     danh mục sản phẩm;
//   * **số sản phẩm mỗi danh mục** — `4 + ((reviewCount + len(category) + i*7) % 24)`;
//   * **tổng đơn đã hoàn thành** — `reviewCount + 20`;
//   * **tỉ lệ mua lại** — `0,5 + (rating − 4,0) × 0,3`.
//
// Mã gọi chúng là *"deterministic sample"* — tác giả biết. Giao diện thì không
// nói gì, nên người bán đọc chúng y hệt giá bán hay tồn kho. Chứng chỉ nặng
// nhất: đó là tuyên bố pháp lý/chất lượng mà app không kiểm, và người bán có
// thể xuống tiền nhập hàng dựa vào nó.
//
// ## Vì sao cổng nằm ở tầng SOURCE chứ không ở tầng widget
//
// Một test widget chỉ chứng minh *màn hôm nay* không bày chúng. Cổng này chặn
// **đường gọi**: chừng nào `ui/` không gọi tới ba hàm sinh số ấy thì không màn
// nào — kể cả màn viết sau này — bày lại được. Cùng khuôn với
// `error_handling_governance_test` và `design_system_ratchet_test`.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Hàm sinh giá trị bằng công thức, KHÔNG đọc nguồn nào.
const _fabricators = <String, String>{
  'supplierCertifications':
      'gán ISO 9001 cho mọi NCC + suy chứng chỉ từ danh mục sản phẩm',
  'supplierCatalog':
      'số sản phẩm = 4 + ((reviewCount + len(category) + i*7) % 24)',
  'supplierTransactions':
      'tổng đơn = reviewCount + 20 · tỉ lệ mua lại suy từ số sao',
};

List<File> _dartFilesUnder(String dir) => [
  for (final e in Directory(dir).listSync(recursive: true))
    if (e is File && e.path.endsWith('.dart')) e,
];

void main() {
  test('⛔ `ui/` KHÔNG gọi hàm sinh dữ liệu giả về nhà cung cấp', () {
    final offenders = <String>[];
    for (final file in _dartFilesUnder('lib/features/tongtai/ui')) {
      final src = file.readAsStringSync();
      for (final entry in _fabricators.entries) {
        if (src.contains('${entry.key}(')) {
          offenders.add('${file.path} → ${entry.key}() (${entry.value})');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Một tuyên bố kinh doanh (chứng chỉ · số đơn · tỉ lệ mua lại · quy mô '
          'danh mục) chỉ được lên màn khi truy được nguồn. Không có nguồn thì '
          'bỏ trống — KHÔNG bịa công thức để lấp giao diện, và cũng không thay '
          'bằng 0/N-A giả.\n${offenders.join('\n')}',
    );
  });

  test(
    '⛔ màn nhà cung cấp không còn khối "danh mục" và "lịch sử giao dịch"',
    () {
      // Hai khối này tồn tại CHỈ để bày số bịa. Khoá bằng chính test id của
      // chúng: nếu ai dựng lại, id quay về và cổng đỏ.
      final src = File(
        'lib/features/tongtai/ui/screens/tongtai_supplier_detail_screen.dart',
      ).readAsStringSync();

      for (final id in [
        'supplier-detail-catalog',
        'supplier-detail-transactions',
      ]) {
        expect(
          src.contains(id),
          isFalse,
          reason:
              '`$id` quay lại — khối ấy chỉ có nội dung sinh bằng công thức',
        );
      }
    },
  );

  test('§ đánh giá sao thì GIỮ — nó có nguồn, dù nguồn là bên thứ ba', () {
    // Cổng này chặn thứ **bịa**, không chặn thứ **nhập từ ngoài**. Gỡ luôn cả
    // rating là phản ứng thái quá: nó đến từ hồ sơ nhà cung cấp đã nhập, và
    // màn nói rõ "từ N đánh giá".
    final src = File(
      'lib/features/tongtai/ui/screens/tongtai_supplier_detail_screen.dart',
    ).readAsStringSync();
    expect(src, contains('supplier-detail-ratings'));
    expect(src, contains('profile.rating'));
  });
}
