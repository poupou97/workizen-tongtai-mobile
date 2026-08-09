import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/connection/connection_capability.dart';
import 'package:tongtai/features/tongtai/connection/connection_catalog.dart';

/// **Governance — catalog nói thật** · WTM-331 (§24).
///
/// Founder: *"Không gọi Demo XLSX là Shopify/Shopee data."*
///
/// Suite này là chỗ duy nhất chặn được điều đó bằng máy. Một dòng catalog sai
/// không làm gì đỏ: nó chỉ khiến người bán tin app đang đồng bộ với sàn trong
/// khi thứ họ có là một file Excel.
void main() {
  group('không tự khai đã nối', () {
    test('CONNECTED chỉ được khai khi có connector THẬT trong app', () {
      for (final source in ConnectionCatalog.all) {
        if (source.readiness != ConnectionReadiness.connected) continue;

        // Hai đường hợp lệ để nói "đã nối": có connector đã dựng, hoặc là
        // đường tự nhập (không cần vendor nào). Không có đường thứ ba.
        final hasConnector =
            source.connectorId != null &&
            ConnectorDescriptor.byId(source.connectorId!) != null;
        final isManual = source.entryPattern == 'manual';

        expect(
          hasConnector || isManual,
          isTrue,
          reason:
              '"${source.name}" khai CONNECTED nhưng không có connector nào '
              'trong app — đó là nói app làm được một việc nó chưa làm được',
        );
      }
    });

    test('nguồn chưa dựng KHÔNG được khai connected hay file_bridge', () {
      const notBuiltYet = {
        'shopee',
        'tiktok_shop',
        'shopify',
        'woocommerce',
        'ebay',
        'amazon',
        'alibaba',
        '1688',
        'aliexpress',
        'url_import',
      };

      for (final id in notBuiltYet) {
        final source = ConnectionCatalog.byId(id)!;
        expect(
          source.readiness,
          isNot(ConnectionReadiness.connected),
          reason: '$id chưa dựng mà khai đã nối',
        );
        expect(
          source.readiness,
          isNot(ConnectionReadiness.fileBridge),
          reason:
              '$id khai FILE_BRIDGE nghĩa là dữ liệu của CHÍNH NÓ vào được '
              'qua file — nhưng file mẫu là file của ta, không phải của nó',
        );
      }
    });

    test('chỉ Google Drive/Excel đang thật sự là FILE_BRIDGE', () {
      final fileBridge = ConnectionCatalog.withReadiness(
        ConnectionReadiness.fileBridge,
      );

      expect(fileBridge.map((s) => s.id), ['google_drive_xlsx']);
    });
  });

  group('ba tầng tách nhau (§21)', () {
    test('mỗi nguồn nói được CẢ BA: bằng chứng · vendor nói · ta quyết', () {
      for (final source in ConnectionCatalog.all) {
        expect(source.evidence, isNotEmpty, reason: source.id);
        expect(source.vendorClaim, isNotEmpty, reason: source.id);
      }
    });

    test('⭐ "0 implementation" KHÔNG được viết thành "không có API"', () {
      // Đây là chỉnh sửa Founder đưa ra ở §21 của Task Order trước. Nó không
      // phải chuyện chữ nghĩa: "vendor không có API" đóng lại một hướng đi,
      // còn "ta chưa tìm thấy trong bộ mã đã đọc" thì không.
      for (final source in ConnectionCatalog.all) {
        final text = '${source.evidence} ${source.vendorClaim}'.toLowerCase();
        if (!text.contains('không tìm thấy implementation')) continue;

        expect(
          source.vendorClaim.toLowerCase(),
          isNot(contains('không có api')),
          reason:
              '${source.name}: "không tìm thấy trong bộ mã đã đọc" khác hẳn '
              '"vendor không có API" — trộn hai câu là đóng nhầm một hướng đi',
        );
      }
    });

    test('nguồn PARTNER_REQUIRED nói rõ rào cản là THƯƠNG MẠI', () {
      final blocked = ConnectionCatalog.withReadiness(
        ConnectionReadiness.partnerRequired,
      );

      expect(blocked, isNotEmpty);
      for (final source in blocked) {
        // Phân biệt rào cản thương mại với rào cản kỹ thuật quyết định việc
        // nên làm gì tiếp: một cái chờ người duyệt, cái kia chờ ta viết code.
        expect(
          source.vendorClaim.toLowerCase(),
          anyOf(contains('partner'), contains('duyệt'), contains('đăng ký')),
          reason: '${source.name} khai cần đối tác mà không nói vì sao',
        );
      }
    });
  });

  group('catalog là DỮ LIỆU, không phải switch trong UI', () {
    test('không màn hình nào hardcode tên nguồn', () {
      final offenders = <String>[];
      final names = {
        for (final s in ConnectionCatalog.all)
          if (s.name.split(' ').length == 1) s.name,
      };

      for (final file
          in Directory('lib/features/tongtai/ui')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final source = file.readAsStringSync();
        for (final name in names) {
          // Tên trong một chuỗi hiển thị ⇒ ai đó đang dựng danh sách bằng tay.
          if (source.contains("'$name'") || source.contains('"$name"')) {
            offenders.add('${file.path}: $name');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Tên nguồn phải đọc từ catalog. Hardcode nghĩa là thêm một nguồn '
            'phải sửa hai chỗ, và chỗ thứ hai sẽ bị quên:\n'
            '${offenders.join('\n')}',
      );
    });

    test('mã trạng thái là canonical, mã lạ ⇒ null', () {
      expect(ConnectionReadiness.values.map((r) => r.code).toList(), [
        'connected',
        'file_bridge',
        'demo',
        'researched',
        'partner_required',
        'api_future',
      ]);
      expect(ConnectionReadiness.fromCode('shopee_connected'), isNull);
      expect(ConnectionReadiness.fromCode(null), isNull);
    });

    test('đủ cả bảy nguồn thương mại và năm nguồn nhập hàng (§24)', () {
      expect(
        ConnectionCatalog.commerce.map((s) => s.id),
        containsAll(const [
          'google_drive_xlsx',
          'shopify',
          'shopee',
          'tiktok_shop',
          'ebay',
          'amazon',
          'woocommerce',
        ]),
      );
      expect(
        ConnectionCatalog.sourcing.map((s) => s.id),
        containsAll(const [
          'alibaba',
          '1688',
          'aliexpress',
          'manual_supplier',
          'url_import',
        ]),
      );
    });

    test('mã nguồn duy nhất — không hai dòng cùng một id', () {
      final ids = ConnectionCatalog.all.map((s) => s.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });
  });

  group('§D-6 · connector ≠ chỉ API', () {
    test('đường vào không phải API vẫn được khai', () {
      final patterns = {
        for (final s in ConnectionCatalog.all)
          if (s.entryPattern != null) s.entryPattern!,
      };

      // App-to-app · share · deep link · URL import · file import đều hợp lệ.
      expect(patterns, contains('file_import'));
      expect(patterns, contains('url_import'));
      expect(patterns, contains('manual'));
    });
  });
}
