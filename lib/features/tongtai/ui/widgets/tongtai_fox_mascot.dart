import 'package:flutter/material.dart';

/// **Khuôn mặt của Workizen AI** — bộ linh vật Ai CRM (WTM-417).
///
/// Hai dạng, và khác nhau ở **vai**, không ở kích thước:
/// - [TongtaiFoxMascot.face] — đầu cáo trần, cho trạng thái rỗng / trang trí.
/// - [TongtaiFoxMascot.avatar] — đầu cáo trên đĩa tròn, là **người nói** trong
///   hội thoại và trên thẻ bản tin.
///
/// ## Vì sao đổi từ SVG origami sang ảnh
///
/// Bộ cũ (WTM-111) là cáo origami low-poly dựng bằng SVG. Founder chốt ngày
/// 2026-08-14 dùng bộ Ai CRM mới và giao nguyên tờ art 24 tư thế. Hai con cáo
/// vẽ khác nhau trong cùng một app là cách chắc chắn để người dùng nghĩ họ đang
/// nhìn hai sản phẩm — nên bộ cũ ra hết một lượt, không để lẫn.
///
/// Tờ art là ảnh raster nên không còn vector; đổi lại nó có **24 tư thế thật**
/// thay vì hai hình. Đầu cáo cắt sẵn ở `assets/mascot/brand/` bằng
/// `tool/cut_mascot_set.py`.
///
/// ## Vì sao đĩa tròn không mang màu ngữ nghĩa
///
/// Đĩa cũ màu navy — màu ấy nay là màu chữ trong logo. Đĩa mới dùng nền kem rất
/// nhạt của bảng màu nhận diện: nó **không mang phán quyết nào**, nên không cướp
/// nghĩa của tím (AI) hay cam (hành động).
class TongtaiFoxMascot extends StatelessWidget {
  const TongtaiFoxMascot._(
    this.size, {
    super.key,
    required this.onDisc,
    this.semanticsLabel,
  });

  /// Đầu cáo trần — trạng thái rỗng, trang trí.
  const TongtaiFoxMascot.face({
    Key? key,
    double size = 64,
    String? semanticsLabel,
  }) : this._(size, key: key, onDisc: false, semanticsLabel: semanticsLabel);

  /// Đầu cáo **không đĩa** — avatar của Workizen AI khi nó đang nói.
  ///
  /// ⚠️ WTM-436 — bản trước vẽ một đĩa `brandSoft` sau đầu cáo. Trên nền trang
  /// nó đọc ra như **một mảng trắng dán sau linh vật**, và Founder gọi đúng tên:
  /// *"rất thô"*. Ảnh nguồn vốn đã trong suốt (đo 24 tệp: 1,0–6,7% pixel trắng,
  /// và đó là lông má + áo hoodie của cáo) — cái đĩa là do widget thêm vào.
  ///
  /// `cp_home.png` vẽ linh vật nằm **thẳng trên nền**, không đĩa.
  ///
  /// Tín hiệu *"AI đang nói"* không mất: nó nằm ở **nền thẻ** (`TtStatus.ai.soft`)
  /// bao quanh cả khối, đúng như concept vẽ — không cần một vòng tròn quanh đầu.
  const TongtaiFoxMascot.avatar({
    Key? key,
    double size = 32,
    String? semanticsLabel,
  }) : this._(size, key: key, onDisc: true, semanticsLabel: semanticsLabel);

  /// Một tệp duy nhất cho cả hai dạng: cùng một khuôn mặt, khác cái nền.
  static const String headAsset = 'assets/mascot/brand/happy.png';

  final double size;
  final bool onDisc;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    // Ảnh chồm ra ngoài đĩa một chút cho tai cáo không bị đĩa cắt ngang.
    final head = Image.asset(
      headAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      // Ảnh thiếu ⇒ khoảng trống, KHÔNG phải ô báo lỗi đỏ giữa màn.
      errorBuilder: (_, _, _) => SizedBox(width: size, height: size),
    );

    return Semantics(
      label: semanticsLabel ?? 'Workizen AI',
      image: true,
      child: SizedBox(width: size, height: size, child: head),
    );
  }
}
