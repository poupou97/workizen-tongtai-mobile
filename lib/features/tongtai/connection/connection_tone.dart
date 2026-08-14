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
      ConnectionStatus.paused => TtStatus.unknown,
      ConnectionStatus.error => TtStatus.danger,
    };

/// Mức sẵn sàng của một nền tảng trong danh mục kết nối.
///
/// `researched` / `partnerRequired` / `apiFuture` là **chưa có**, không phải
/// **hỏng** — nên chúng mang `unknown` (xám), không mang `danger`. Tô đỏ một
/// năng lực chưa tới là doạ người dùng về một thứ không ai hứa.
TtStatus tongtaiConnectionReadinessTone(ConnectionReadiness readiness) =>
    switch (readiness) {
      ConnectionReadiness.connected => TtStatus.success,
      ConnectionReadiness.demoConnected => TtStatus.success,
      ConnectionReadiness.fileBridge => TtStatus.info,
      ConnectionReadiness.demo => TtStatus.unknown,
      ConnectionReadiness.researched => TtStatus.unknown,
      ConnectionReadiness.partnerRequired => TtStatus.unknown,
      ConnectionReadiness.apiFuture => TtStatus.unknown,
    };
