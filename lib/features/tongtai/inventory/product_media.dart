import 'product.dart';

/// **Ảnh của một sản phẩm, đã phân giải** — WTM-414.
///
/// UI **không biết** ảnh đến từ đâu: máy người bán, asset demo, hay một
/// connector thật (Shopify/Shopee/eBay/Alibaba). Khi connector thật thay nguồn,
/// UI không phải sửa một dòng.
sealed class ProductMedia {
  const ProductMedia();
}

/// Ảnh người bán tự chụp/thêm — nằm trên máy họ.
class ProductMediaFile extends ProductMedia {
  const ProductMediaFile(this.path);
  final String path;
}

/// Ảnh đóng gói trong app (bộ demo).
class ProductMediaAsset extends ProductMedia {
  const ProductMediaAsset(this.assetPath);
  final String assetPath;
}

/// Ảnh do một nguồn ngoài cung cấp qua URL.
class ProductMediaUrl extends ProductMedia {
  const ProductMediaUrl(this.url);
  final String url;
}

/// **Nguồn ảnh** cho sản phẩm — một tầng, nhiều bản cài đặt.
///
/// ## Vì sao tồn tại
///
/// Bản đầu của WTM-414 ghi thẳng URL ảnh demo vào `Product.imageUrl`. Đó là
/// biến **media của bộ demo** thành **Business Truth của sản phẩm**: một ngày
/// nào đó người bán xuất `.ttbk` ra và thấy hàng của mình mang một URL họ chưa
/// từng nhập, hoặc một connector thật ghi đè lên nó và không ai biết cái nào
/// đúng.
///
/// Media là **thuộc tính của nguồn**, không phải sự thật của sản phẩm. Nên nó
/// đi qua đây.
abstract interface class ProductMediaProvider {
  /// `null` = nguồn này không có ảnh cho sản phẩm ấy; hỏi nguồn tiếp theo.
  ProductMedia? mediaFor(Product product);
}

/// Ảnh **người bán tự thêm** — luôn thắng mọi nguồn khác.
///
/// Người bán chụp hàng của chính mình; không nguồn nào được đè lên.
class SellerProductMediaProvider implements ProductMediaProvider {
  const SellerProductMediaProvider();

  @override
  ProductMedia? mediaFor(Product product) => product.imagePaths.isEmpty
      ? null
      : ProductMediaFile(product.imagePaths.first);
}

/// Ảnh từ **nguồn ngoài đã nhập** (`Product.imageUrl`).
///
/// Đây là chỗ Shopify/Shopee/eBay/Alibaba sẽ cắm vào: connector ghi `imageUrl`
/// khi đồng bộ, và tầng này đọc nó. Không cần một provider mới cho mỗi sàn nếu
/// tất cả đều ghi vào cùng một trường.
class ConnectorProductMediaProvider implements ProductMediaProvider {
  const ConnectorProductMediaProvider();

  @override
  ProductMedia? mediaFor(Product product) {
    final url = product.imageUrl;
    return url == null || url.isEmpty ? null : ProductMediaUrl(url);
  }
}

/// Ảnh **bộ demo**, đóng gói trong app.
///
/// ## ⛔ Chỉ khớp theo SKU của bộ demo
///
/// Một sản phẩm thật của người bán trùng SKU với bộ demo sẽ **không** nhận ảnh
/// demo, vì bộ demo dùng tiền tố riêng (`DT-`, `GD-`…) do chính file mẫu sinh
/// ra. Nếu ngày nào đó tiền tố ấy trùng dữ liệu thật, luật này phải chặt hơn —
/// nhưng nó không được lỏng hơn.
///
/// Ảnh nằm trong bundle ⇒ **offline chạy được**, cùng sản phẩm luôn ra cùng
/// ảnh, và bố cục không phụ thuộc mạng.
class DemoAssetMediaProvider implements ProductMediaProvider {
  const DemoAssetMediaProvider(this.availableSkus);

  /// Tập SKU **thật sự có ảnh trong bundle**.
  ///
  /// Truyền vào thay vì đoán: hỏi một asset không tồn tại chỉ báo lỗi lúc chạy,
  /// và một ô ảnh vỡ tệ hơn một ô ảnh trống.
  final Set<String> availableSkus;

  @override
  ProductMedia? mediaFor(Product product) => availableSkus.contains(product.sku)
      ? ProductMediaAsset('assets/demo/products/${product.sku}.jpg')
      : null;
}

/// Hỏi lần lượt các nguồn, **nguồn nào trả trước thì thắng**.
///
/// Thứ tự có ý nghĩa: người bán → connector → demo. Ảnh người bán tự thêm không
/// bao giờ bị một tấm ảnh mẫu che mất.
class ProductMediaResolver {
  const ProductMediaResolver(this.providers);

  final List<ProductMediaProvider> providers;

  ProductMedia? resolve(Product product) {
    for (final p in providers) {
      final media = p.mediaFor(product);
      if (media != null) return media;
    }
    return null;
  }
}
