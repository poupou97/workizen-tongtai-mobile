import 'package:flutter/material.dart';

/// **Con cáo, và chỉ ở nơi nó đang làm gì đó** — Epic WTM-349 §17.
///
/// Bộ **Ai CRM** 24 tư thế do Founder giao (`assets/mascot/new-mascot.png`,
/// 2026-08-14), cắt bằng `tool/cut_mascot_set.py` — phân tích thành phần liên
/// thông, không cắt theo lưới, vì ô trong tờ art không đều và cắt lưới làm mỗi
/// ảnh dính một mẩu của tư thế bên cạnh.
///
/// Thay bộ origami cũ (WTM-111) **một lượt, không để lẫn**: hai con cáo vẽ khác
/// nhau trong cùng một app là cách chắc chắn để người dùng nghĩ họ đang nhìn
/// hai sản phẩm.
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
  explaining('analyzing'),

  /// Đưa ra danh sách việc cần làm.
  planning('pointing'),

  /// Có chuyện cần chú ý.
  warning('announcing'),

  /// Mừng một mốc thật.
  celebrating('celebrating'),

  /// Đã xem và không có gì gấp — bình thản, không phải vui mừng.
  /// Bộ mới: cáo khoanh tay, **không** cáo nhảy mừng.
  calm('confident'),

  /// Chưa có gì để xem.
  ///
  /// Bộ mới dùng cáo cầm kính lúp (*đang tìm*), KHÔNG dùng cáo cười. Màn "chưa
  /// đủ dữ liệu" mà có một con cáo hớn hở thì hình đã nói dối trước cả chữ —
  /// và bộ art mới có sẵn cả tư thế buồn lẫn tư thế mừng, nên chọn sai ở đây
  /// là chọn, không phải thiếu.
  idle('searching');

  const MascotPose(this._file);

  final String _file;

  String get asset => 'assets/mascot/brand/$_file.png';
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
