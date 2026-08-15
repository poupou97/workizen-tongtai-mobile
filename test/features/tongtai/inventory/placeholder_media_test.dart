// Ảnh giữ chỗ không được tự xưng là ảnh sản phẩm — WTM-418.
//
// ## Lỗi này đã sống sót qua một lần sửa
//
// WTM-414 gỡ đường **GHI** (bỏ tệp sinh URL demo, bỏ đoạn seeder ghi vào
// `Product.imageUrl`) và tôi coi thế là xong. Nhưng bộ dữ liệu mẫu XLSX vẫn có
// cột `image_url` điền `picsum.photos/seed/…`, máy Founder đã nạp từ
// 2026-08-09, và giá trị ấy đi vào qua đường **ĐỌC**. 2845 test xanh; danh sách
// Kho trên máy thật hiện ảnh phong cảnh cho từng món hàng.
//
// Đó là P-39 nguyên vẹn: *guard đặt ở đường ghi, giá trị hỏng vào bằng đường
// đọc*. Nên test này canh **cả hai đầu**, và có một ca hồi quy đúng bằng dữ
// liệu thật trong workbook.
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/provenance.dart';
import 'package:tongtai/features/tongtai/inventory/placeholder_media.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_media.dart';

Product _product({String? imageUrl}) => Product(
  id: 'p1',
  name: 'Bình nước thể thao 1L',
  sku: 'TH-069',
  category: 'sports',
  pricePerUnit: 330000,
  quantity: 18,
  updatedAt: DateTime(2026, 8, 9),
  imageUrl: imageUrl,
  provenance: ProvenanceSource.fileBridge,
);

void main() {
  group('§1 nhận diện host ảnh giữ chỗ', () {
    test('đúng những host chuyên trả ảnh ngẫu nhiên', () {
      // Ca đầu là URL THẬT trong `TongTai-Commerce-Demo-100-Products.xlsx`.
      expect(
        isPlaceholderMediaUrl('https://picsum.photos/seed/tongtai1/400/400'),
        isTrue,
      );
      expect(
        isPlaceholderMediaUrl('https://loremflickr.com/400/400/fox'),
        isTrue,
      );
      expect(isPlaceholderMediaUrl('https://via.placeholder.com/400'), isTrue);
      expect(isPlaceholderMediaUrl('https://dummyimage.com/400x400'), isTrue);
    });

    test('KHÔNG bắt nhầm URL thật', () {
      // So theo **host**. Một ảnh thật hoàn toàn có thể có chữ "placeholder"
      // trong tên tệp — bắt bằng `contains` là xoá ảnh thật của người bán.
      expect(
        isPlaceholderMediaUrl(
          'https://cdn.shopify.com/s/files/placeholder.jpg',
        ),
        isFalse,
      );
      expect(
        isPlaceholderMediaUrl('https://cf.shopee.vn/file/abc123'),
        isFalse,
      );
      expect(isPlaceholderMediaUrl(null), isFalse);
      expect(isPlaceholderMediaUrl(''), isFalse);
      expect(isPlaceholderMediaUrl('không-phải-url'), isFalse);
    });
  });

  group('§2 đường ĐỌC — chữa cho máy đã nạp dữ liệu hỏng', () {
    const connector = ConnectorProductMediaProvider();

    test('URL giữ chỗ đã nằm trong DB ⇒ coi như KHÔNG có ảnh', () {
      expect(
        connector.mediaFor(
          _product(imageUrl: 'https://picsum.photos/seed/tongtai7/400/400'),
        ),
        isNull,
        reason:
            'ảnh ngẫu nhiên vẫn hiện ⇒ mỗi món hàng mang một tấm ảnh không '
            'liên quan, và người xem kết luận dữ liệu là giả',
      );
    });

    test('URL thật của connector vẫn đi qua', () {
      // Không được sửa quá tay: đây chính là chỗ Shopify/Shopee sẽ cắm vào.
      final media = connector.mediaFor(
        _product(imageUrl: 'https://cf.shopee.vn/file/real-photo'),
      );
      expect(media, isA<ProductMediaUrl>());
    });
  });

  group('§3 chuỗi phân giải — ảnh đã duyệt không bị URL rác đè', () {
    test(
      'sản phẩm có ảnh demo duyệt ⇒ dùng ảnh ấy, KHÔNG dùng URL giữ chỗ',
      () {
        const resolver = ProductMediaResolver([
          SellerProductMediaProvider(),
          ConnectorProductMediaProvider(),
          DemoAssetMediaProvider({'TH-069'}),
        ]);

        final media = resolver.resolve(
          _product(imageUrl: 'https://picsum.photos/seed/tongtai7/400/400'),
        );

        expect(
          media,
          isA<ProductMediaAsset>(),
          reason:
              'connector đứng TRƯỚC demo asset trong chuỗi, nên một URL rác '
              'còn sống sẽ đè lên đúng những ảnh đã ngồi duyệt bằng mắt',
        );
      },
    );
  });
}
