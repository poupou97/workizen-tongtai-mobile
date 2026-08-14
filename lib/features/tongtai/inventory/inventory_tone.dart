import '../../../core/design/tt.dart';
import 'product.dart';
import 'stock_alert.dart';

/// **Trạng thái kho → sắc thái ngữ nghĩa** — WTM-414 (DS-2).
///
/// ## Vì sao trả `TtStatus` chứ không trả `Color`
///
/// Trả `Color` là **nhảy qua tầng semantic**: màn nhận về một giá trị token thô
/// và từ giây đó nó đặt màu ấy vào đâu cũng được — một con số, một cái nền, một
/// nhãn không mang phán quyết. Đó chính là cách `_Chip(label, color)` và
/// `_CustomerStat(color:)` (WTM-407) ra đời: **không phải vì ai cẩu thả, mà vì
/// chữ ký hàm cho phép.**
///
/// `TtStatus` là tầng vai ngữ nghĩa của Design System và **tự** giữ ánh xạ sang
/// token (`status.color`, `status.soft`). Miền chỉ nói *"cái này nghĩa là gì"*;
/// nói *"cái đó màu gì"* là việc của DS.
///
/// ## Vì sao nằm ở đây, không nằm trong tệp màn
///
/// Trước DS-2, hai hàm này sống trong `tongtai_inventory_screen.dart` và
/// `tongtai_stock_alerts_screen.dart` — tức **màn đang giữ một khái niệm của
/// tầng trên**. Hai màn cùng hỏi *"hết hàng nghĩa là gì"* thì phải nhận cùng
/// một câu trả lời, và câu ấy không thể thuộc về một trong hai.
///
/// Theo đúng khuôn `goal_theme.dart` / `opportunity_theme.dart` đã có: ánh xạ
/// của một miền sống **cạnh miền ấy**.

/// Còn hàng · sắp hết · hết hàng.
TtStatus tongtaiStockStatusTone(StockStatus status) => switch (status) {
  StockStatus.inStock => TtStatus.success,
  StockStatus.lowStock => TtStatus.warning,
  StockStatus.outOfStock => TtStatus.danger,
};

/// Mức cảnh báo tồn kho.
TtStatus tongtaiStockAlertTone(StockAlertLevel level) => switch (level) {
  StockAlertLevel.outOfStock => TtStatus.danger,
  StockAlertLevel.lowStock => TtStatus.warning,
};
