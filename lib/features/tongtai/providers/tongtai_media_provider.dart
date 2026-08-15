import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../inventory/demo_media_manifest.dart';
import '../inventory/product_media.dart';

/// Chuỗi nguồn ảnh sản phẩm — WTM-414.
///
/// Thứ tự **có ý nghĩa**: ảnh người bán tự thêm → ảnh connector đồng bộ → ảnh
/// bộ demo. Ảnh của chính người bán không bao giờ bị một tấm ảnh mẫu che mất.
///
/// Thêm một sàn mới (Shopee, eBay, Alibaba) **không** cần provider mới nếu
/// connector ấy ghi vào `Product.imageUrl` như mọi nguồn ngoài khác.
final productMediaResolverProvider = Provider<ProductMediaResolver>(
  (ref) => const ProductMediaResolver([
    SellerProductMediaProvider(),
    ConnectorProductMediaProvider(),
    DemoAssetMediaProvider(kDemoProductImageSkus),
  ]),
);
