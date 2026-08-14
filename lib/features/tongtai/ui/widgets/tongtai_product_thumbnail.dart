import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';
import '../../inventory/category_icon.dart';
import '../../inventory/product.dart';
import '../../inventory/product_media.dart';
import '../../providers/tongtai_media_provider.dart';

/// **Ô ảnh của một sản phẩm** — WTM-414.
///
/// ## Vì sao có lớp này giữa màn và `TtThumbnail`
///
/// `TtThumbnail` thuộc Design System nên nó **không được biết** `Product` là gì.
/// Màn thì không được biết ảnh đến **từ đâu** — người bán tự chụp, connector
/// Shopify/Shopee đồng bộ về, hay asset của bộ demo.
///
/// Lớp này đứng giữa: hỏi [ProductMediaResolver], rồi đưa cho DS đúng một
/// nguồn. Khi connector thật thay nguồn media, **không màn nào phải sửa**.
///
/// Đó cũng là lý do màn chỉ gọi `TongtaiProductThumbnail(product: p)` và không
/// bao giờ chạm tới `product.imageUrl`.
class TongtaiProductThumbnail extends ConsumerWidget {
  const TongtaiProductThumbnail({
    required this.product,
    this.size = 56,
    super.key,
  });

  final Product product;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(productMediaResolverProvider).resolve(product);
    return TtThumbnail(
      icon: tongtaiCategoryIcon(product.category),
      size: size,
      imagePath: media is ProductMediaFile ? media.path : null,
      assetPath: media is ProductMediaAsset ? media.assetPath : null,
      imageUrl: media is ProductMediaUrl ? media.url : null,
    );
  }
}
