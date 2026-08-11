import 'package:flutter/material.dart';

import 'tt_tokens.dart';

/// **Theme Material của Tổng Tài** — WTM-379 (Epic WTM-362).
///
/// ## Vì sao nó ở đây chứ không nằm trong `main.dart`
///
/// Nó **là** một phần của Design System: mọi widget Material không được tạo
/// kiểu riêng — hộp thoại, công tắc, ô đánh dấu, tay kéo chọn chữ, snackbar,
/// nút mặc định — lấy màu từ đây. Để nó là một biểu thức vô danh nằm giữa
/// `build()` của `TongtaiApp` nghĩa là thứ **ảnh hưởng rộng nhất** trong sản
/// phẩm lại là thứ **không ai sở hữu**.
///
/// ## ⭐ Hạt giống là CAM thương hiệu, không phải xanh lá
///
/// Trước WTM-375 nó gieo bằng `producerGreen`. Tức là **cả app ngầm nói "tốt /
/// thành công"** ở mọi chỗ chưa ai sơn tay, trong khi luật Design System nói
/// XANH LÁ = KẾT QUẢ TÍCH CỰC và CAM = HÀNH ĐỘNG.
///
/// Đây chính là lý do nút `Lưu` của màn Nguồn đầu vào từng trông khác bốn nút
/// `Lưu` còn lại: nó là nút *mặc định*, nên nó mang màu của hạt giống.
///
/// `test/core/design/theme_seed_test.dart` khoá điều đó lại — vì đây là thứ chỉ
/// **mắt người trên máy thật** nhìn ra, và một suite xanh không biết hạt giống
/// màu gì.
final ThemeData tongtaiTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: TtColors.brand),
);
