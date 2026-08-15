import 'dart:io';

import 'package:flutter/material.dart';

import 'tt_tokens.dart';

/// **Ô ảnh sản phẩm** — WTM-414.
///
/// Thứ tự dự phòng: **ảnh máy → ảnh mạng → ảnh mặc định**.
///
/// ## Vì sao có ảnh mặc định, và vì sao nó không phải một cái icon
///
/// Founder xem bản đầu (chỉ có biểu tượng danh mục) và nói *"trông như icon
/// ý :("* — đúng, vì nó **là** một cái icon. Ô ảnh mặc định nay có nền chuyển
/// sắc, một khung ảnh mờ phía sau và biểu tượng danh mục chồng lên: đủ chất
/// liệu để mắt đọc ra *"chỗ này là ảnh, chỉ chưa có ảnh"*.
///
/// Nó là **đường lui bắt buộc**, không phải tuỳ chọn: ảnh theo URL sẽ trắng khi
/// mất mạng, và Founder yêu cầu đúng điều này — *"tạo sẵn 1 cái ảnh default
/// phòng khi không có ảnh hoặc bị mất mạng"*.
///
/// ## Vẫn trung tính về màu
///
/// Luật màu của app đã có chủ (cam = hành động, tím = AI, xanh lá = tích cực…).
/// Một ô ảnh trống **không mang phán quyết nào**, nên nó không mượn màu nào cả —
/// nó phân biệt bằng biểu tượng.
class TtThumbnail extends StatelessWidget {
  const TtThumbnail({
    super.key,
    required this.icon,
    this.imagePath,
    this.assetPath,
    this.imageUrl,
    this.size = 56,
  });

  /// Biểu tượng danh mục — dùng cho ô mặc định.
  final IconData icon;

  /// Ảnh cục bộ người bán tự thêm — **thắng mọi thứ khác**.
  final String? imagePath;

  /// Ảnh đóng gói trong app — **không cần mạng**, bố cục không đổi khi offline.
  final String? assetPath;

  /// Ảnh theo URL do một nguồn ngoài cung cấp.
  final String? imageUrl;

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(TtRadius.md);
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: TtColors.border),
          ),
          child: _content(),
        ),
      ),
    );
  }

  Widget _content() {
    final fallback = _DefaultThumbnail(icon: icon, size: size);

    final path = imagePath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    final asset = assetPath;
    if (asset != null && asset.isNotEmpty) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: size,
        height: size,
        // Đang tải ⇒ giữ ô mặc định, KHÔNG nháy vòng xoay: danh sách 100 dòng
        // mà mỗi dòng một spinner thì trông như app đang hỏng.
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
        // ⛔ Mất mạng hoặc URL chết ⇒ ảnh mặc định, không để ô vỡ.
        errorBuilder: (_, _, _) => fallback,
      );
    }

    return fallback;
  }
}

class _DefaultThumbnail extends StatelessWidget {
  const _DefaultThumbnail({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [TtColors.surfaceSecondary, TtColors.surfaceTertiary],
      ),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.image_outlined, size: size * 0.62, color: TtColors.border),
        Icon(icon, size: size * 0.30, color: TtColors.textTertiary),
      ],
    ),
  );
}
