import 'dart:io';

import 'package:flutter/material.dart';

import 'tt_tokens.dart';

/// **Ô ảnh sản phẩm** — WTM-414.
///
/// Thứ tự dự phòng: ảnh người bán tự thêm → ô placeholder trung tính.
///
/// ## ⛔ Vì sao placeholder KHÔNG tô màu theo danh mục
///
/// Cách hiển nhiên là cho mỗi danh mục một màu để nhìn phát biết. Nhưng luật
/// Founder 2026-08-14 nói thẳng: *"không dùng semantic color để trang trí;
/// không để mỗi domain tự có một palette riêng nếu màu không mang semantic
/// meaning"*.
///
/// Một ô hàng tạp hoá màu xanh lá không có nghĩa *"tốt"*, và một ô mỹ phẩm màu
/// đỏ không có nghĩa *"nguy hiểm"* — nhưng mắt đã học sáu màu ấy ở khắp app rồi,
/// nên nó sẽ đọc ra nghĩa không ai định nói. 13 danh mục cũng không có 13 màu
/// nào trong DS để mượn mà không đụng vào bảng ngữ nghĩa.
///
/// Nên: nền **trung tính**, phân biệt bằng **biểu tượng**. Biểu tượng mang thông
/// tin mà không mượn một kênh đã có chủ.
///
/// ## Vì sao là placeholder chứ không phải ảnh thật tải về
///
/// Ảnh chụp thật gắn vào một sản phẩm **không có thật** là một bản ghi tự xưng
/// là thứ nó không phải. Thêm nữa: Phase 2 local-first (D-5) — ảnh theo URL sẽ
/// trắng đúng lúc demo mất mạng.
class TtThumbnail extends StatelessWidget {
  const TtThumbnail({
    super.key,
    required this.icon,
    this.imagePath,
    this.size = 56,
  });

  /// Biểu tượng của danh mục — thứ **duy nhất** phân biệt các ô với nhau.
  final IconData icon;

  /// Ảnh cục bộ người bán đã thêm. Có thì nó thắng placeholder.
  final String? imagePath;

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(TtRadius.md);
    final path = imagePath;

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: TtColors.surfaceTertiary,
            borderRadius: radius,
            border: Border.all(color: TtColors.border),
          ),
          child: path != null && path.isNotEmpty && File(path).existsSync()
              ? Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  // Ảnh hỏng ⇒ quay về placeholder, không hiện ô vỡ.
                  errorBuilder: (_, _, _) => _Placeholder(icon: icon),
                )
              : _Placeholder(icon: icon),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) =>
      Center(child: Icon(icon, size: 22, color: TtColors.textTertiary));
}
