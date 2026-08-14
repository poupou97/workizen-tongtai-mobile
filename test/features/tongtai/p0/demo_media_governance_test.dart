// P0 — **cổng cho ảnh demo bundle trong app** (WTM-414).
//
// ## Vì sao ba luật này, không phải một lời nhắc trong tài liệu
//
// Cả ba đều là lỗi đã xảy ra thật trong chính đợt làm này:
//
//   §1 **Giấy phép**: tôi lọc Openverse bằng `license_type=commercial` và bốn
//      ảnh **by-nd** lọt vào bundle. ND *cho phép* dùng thương mại nhưng **cấm
//      tác phẩm phái sinh** — mà công cụ cắt vuông + resize *mọi* tấm, nên tấm
//      nào cũng là phái sinh. Bộ lọc đúng nghĩa "được dùng" nhưng sai nghĩa
//      "được sửa"; không ai đọc ra khác biệt đó khi nhìn ảnh.
//
//   §2 **Manifest lệch thư mục**: `kDemoProductImageSkus` là thứ app dùng để
//      hỏi asset. Lệch một tên ⇒ Flutter hỏi một tệp không có ⇒ **ô ảnh vỡ**,
//      tệ hơn ô ảnh trống.
//
//   §3 **Ghi công**: CC-BY buộc ghi tác giả. Không có bản ghi thì không ghi
//      công được, và một ảnh không rõ nguồn thì **không được phép** ở trong một
//      app phát hành.
//
// Ba luật này là *dữ liệu kiểm dữ liệu* — chạy được vì cả ảnh lẫn manifest đều
// nằm trong repo. Sinh lại bằng `tool/fetch_demo_product_images.py dart`.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/inventory/demo_media_manifest.dart';

/// Giấy phép **cấm tác phẩm phái sinh**. Ảnh nào cũng bị cắt vuông ⇒ cấm tiệt.
const _forbiddenLicensePrefix = 'by-nd';

void main() {
  final dir = Directory('assets/demo/products');
  final manifestFile = File('assets/demo/products/ATTRIBUTION.json');

  group('ảnh demo bundle — giấy phép · manifest · ghi công', () {
    test('§1 KHÔNG ảnh nào mang giấy phép cấm phái sinh', () {
      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      final offenders = <String>[];
      for (final e in manifest.entries) {
        final license = (e.value as Map)['license'] as String? ?? '';
        if (license.startsWith(_forbiddenLicensePrefix)) offenders.add(e.key);
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'ảnh ND (cấm phái sinh) trong bundle. Công cụ cắt vuông mọi tấm ⇒ '
            'mọi tấm là phái sinh. Lấy lại bằng `license=cc0,pdm,by,by-sa`.',
      );
    });

    test('§2 manifest Dart == đúng tập tệp trong thư mục', () {
      final onDisk = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jpg'))
          .map((f) => f.uri.pathSegments.last.replaceAll('.jpg', ''))
          .toSet();

      expect(
        kDemoProductImageSkus.difference(onDisk),
        isEmpty,
        reason: 'manifest kê một SKU không có tệp ⇒ app hỏi asset không tồn '
            'tại ⇒ ô ảnh vỡ. Chạy `tool/fetch_demo_product_images.py dart`.',
      );
      expect(
        onDisk.difference(kDemoProductImageSkus),
        isEmpty,
        reason: 'có tệp ảnh nhưng manifest không kê ⇒ ảnh nằm không trong '
            'bundle mà không ai dùng, và app vẫn hiện ô mặc định.',
      );
    });

    test('§3 mọi ảnh đều có bản ghi nguồn + giấy phép + tác giả', () {
      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      for (final sku in kDemoProductImageSkus) {
        final row = manifest[sku] as Map<String, dynamic>?;
        expect(row, isNotNull, reason: '$sku không có bản ghi ghi công');
        for (final field in ['license', 'source', 'page']) {
          expect(
            (row![field] as String?)?.isNotEmpty,
            isTrue,
            reason: '$sku thiếu "$field" — không truy được nguồn thì không '
                'chứng minh được quyền dùng',
          );
        }
      }
    });

    test('§4 thư mục ảnh được khai trong pubspec', () {
      // Thiếu dòng này thì ảnh **không vào bundle**: máy dev vẫn thấy tệp trên
      // đĩa, còn bản cài trên máy thật thì không — đúng loại lỗi chỉ hiện ở
      // thiết bị.
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('assets/demo/products/'),
      );
    });
  });
}
