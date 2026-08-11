import 'package:flutter/material.dart';

/// **Con cáo, và chỉ ở nơi nó đang làm gì đó** — Epic WTM-349 §17.
///
/// Bộ 25 tư thế do Founder cung cấp (`docs/01-PRODUCT/concept-1/icon
/// mascot.png`), cắt bằng phân tích thành phần liên thông trên kênh alpha —
/// không cắt theo lưới 5×5 đều, vì lưới đó không đều và cách ấy làm mỗi ảnh
/// dính một mẩu của tư thế bên cạnh.
///
/// ## Luật dùng
///
/// Linh vật xuất hiện khi AI **tự giới thiệu · đang phân tích · đang tóm tắt ·
/// đang đề xuất · đang cảnh báo · đang mừng một mốc**. Nó **không** phải hoạ
/// tiết rải khắp nơi: một con cáo ở mọi màn thì không màn nào còn nghĩa là
/// *"chỗ này AI đang nói"*.
///
/// Đó là lý do enum này liệt kê **việc**, không liệt kê **hình**. Tên ảnh có
/// thể đổi; câu hỏi *"lúc này AI đang làm gì"* thì không.
enum MascotPose {
  /// Tự giới thiệu — màn đầu tiên của sản phẩm.
  greeting('waving'),

  /// Đang đọc dữ liệu của người bán.
  working('at_laptop'),

  /// Vừa hiểu ra điều gì đó, đang trình bày con số.
  explaining('chart_tablet'),

  /// Đưa ra danh sách việc cần làm.
  planning('checklist'),

  /// Có chuyện cần chú ý.
  warning('megaphone'),

  /// Mừng một mốc thật.
  celebrating('celebrate'),

  /// Đã xem và không có gì gấp — bình thản, không phải vui mừng.
  calm('meditating'),

  /// Chưa có gì để xem.
  idle('thinking');

  const MascotPose(this._file);

  final String _file;

  String get asset => 'assets/mascot/poses/$_file.png';
}

/// Một tư thế linh vật, đã có nhãn trợ năng.
class TongtaiMascotPose extends StatelessWidget {
  const TongtaiMascotPose(
    this.pose, {
    super.key,
    this.height = 140,
    required this.semanticsLabel,
  });

  final MascotPose pose;
  final double height;

  /// Bắt buộc: một hình không lời là một hình người dùng TalkBack không thấy.
  /// Nhãn nói **AI đang làm gì**, không mô tả con cáo — người nghe cần biết
  /// trạng thái, không cần biết có một con cáo.
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel,
    image: true,
    child: Image.asset(
      pose.asset,
      key: Key('mascot-${pose.name}'),
      height: height,
      fit: BoxFit.contain,
      // Ảnh thiếu ⇒ khoảng trống, KHÔNG phải ô báo lỗi đỏ giữa màn onboarding.
      // Linh vật là trang trí có ý nghĩa; nó không đáng làm hỏng màn đầu tiên
      // người bán nhìn thấy.
      errorBuilder: (_, _, _) => SizedBox(height: height),
    ),
  );
}
