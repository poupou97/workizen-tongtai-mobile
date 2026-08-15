import '../../../core/design/tt.dart';
import '../core/connection.dart';
import 'connection_catalog.dart';

/// **Trạng thái kết nối → sắc thái ngữ nghĩa** — WTM-414 (DS-2).
///
/// ## ⛔ Sửa một lỗi NGỮ NGHĨA, không chỉ dọn style
///
/// Bản cũ nằm trong `tongtai_connections_screen.dart` và dùng **màu Material
/// thô** — `Colors.green`, `Colors.orange` — tức bỏ qua **cả tầng token**.
///
/// Nặng nhất: `ConnectionStatus.error => Colors.orange`. Theo luật màu đã chốt,
/// **cam = Brand / Primary Action**. Một lỗi kết nối đang mặc màu của nút hành
/// động chính — người bán đọc ra "bấm vào đây" ở đúng chỗ đang hỏng.
///
/// Nay lỗi mang `danger`, và mọi màu đến từ DS.
TtStatus tongtaiConnectionStatusTone(ConnectionStatus status) =>
    switch (status) {
      ConnectionStatus.setupRequired => TtStatus.warning,
      ConnectionStatus.active => TtStatus.success,
      // **Biết rất rõ**: người dùng tự bấm dừng. Trước WTM-425 nó mượn
      // `unknown` vì enum chưa có vai trung tính — mà *tạm dừng* không mù mờ
      // chút nào.
      ConnectionStatus.paused => TtStatus.neutral,
      ConnectionStatus.error => TtStatus.danger,
    };

/// Mức sẵn sàng của một nền tảng trong danh mục kết nối.
///
/// `researched` / `partnerRequired` / `apiFuture` là **chưa có**, không phải
/// **hỏng** — nên chúng không mang `danger`. Tô đỏ một năng lực chưa tới là
/// doạ người dùng về một thứ không ai hứa.
///
/// ⭐ WTM-425 — cả bốn mức "chưa nối" chuyển từ `unknown` sang **`neutral`**.
///
/// Chúng mượn `unknown` chỉ vì enum chưa có vai trung tính. Nhưng không mức nào
/// ở đây *"chưa biết"* cả: đã tra và biết chắc nền tảng này **chưa có API**,
/// **cần hợp tác**, hoặc **đang phát dữ liệu mô phỏng**. Đó là **biết rõ mà
/// không phán xét** — đúng định nghĩa `neutral`.
///
/// `unknown` từ nay chỉ còn một nghĩa: *thiếu dữ liệu để kết luận*. Giữ hai
/// nghĩa trên một hằng là P-27 lộn ngược — sửa màu cho *"thiếu dữ liệu"* sẽ
/// lặng lẽ đổi màu của *"tạm dừng"*.
TtStatus tongtaiConnectionReadinessTone(ConnectionReadiness readiness) =>
    switch (readiness) {
      ConnectionReadiness.connected => TtStatus.success,
      ConnectionReadiness.demoConnected => TtStatus.success,
      ConnectionReadiness.fileBridge => TtStatus.info,
      ConnectionReadiness.demo => TtStatus.neutral,
      ConnectionReadiness.researched => TtStatus.neutral,
      ConnectionReadiness.partnerRequired => TtStatus.neutral,
      ConnectionReadiness.apiFuture => TtStatus.neutral,
    };
