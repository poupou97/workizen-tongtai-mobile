import 'package:flutter/material.dart';

import '../../../../core/design/tt.dart';
import 'tt_sparkline.dart';

/// Hướng của một thay đổi — quyết định **màu và mũi tên**, không phải phía gọi.
///
/// ⚠️ Tồn tại vì Founder A2: *"màu định vị/thương hiệu tuyệt đối không dùng để
/// biểu diễn trạng thái hay giá trị"*. Nếu mỗi thẻ tự chọn màu delta, sớm muộn
/// sẽ có thẻ tô cam (màu HÀNH ĐỘNG) cho một con số giảm — và người bán đọc ra
/// một nghĩa không ai định nói.
enum TtTrend {
  /// Tăng, và tăng là tốt cho chỉ số này.
  up,

  /// Giảm, và giảm là xấu cho chỉ số này.
  down,

  /// Không có mốc để so — **khác hẳn** "không đổi".
  unknown,
}

/// Sắc thái của **con số chính** trên thẻ.
///
/// Concept vẽ *"**5** cần nhập sớm"* bằng màu đỏ trong khi *"**82** tổng
/// khách"* màu mực — nên con số ĐƯỢC phép mang màu. Nhưng nó chỉ được mang màu
/// **ngữ nghĩa**, và đó là lý do chỗ này là một enum hai giá trị chứ không phải
/// một tham số `Color`.
///
/// Một tham số `Color` sẽ cho phép — và sớm muộn sẽ nhận — màu định vị của
/// module. Đó đúng là lỗi WTM-389: ô *"Nguồn hàng **0**"* hiện màu **xanh lá**
/// vì xanh lá là màu của Nguồn hàng, và người bán đọc ra "tin tốt" từ một con
/// số không.
enum TtValueTone {
  /// Mặc định — con số là một sự thật, không phải một phán quyết.
  neutral,

  /// Con số NÀY là một cảnh báo (sắp hết hàng, quá hạn). Đỏ theo luật màu.
  critical,
}

/// **Thẻ chỉ số của concept** — WTM-404 (`cp_home.png`).
///
/// Một thẻ = ô biểu tượng · nhãn · con số lớn · đơn vị · mức đổi so mốc ·
/// đường xu hướng · lối đi tiếp. Chính bố cục này lặp 8 lần trên Home concept
/// (4 thẻ năng lực + 4 thẻ sức khoẻ), nên nó là **một widget**, không phải tám
/// đoạn chép tay.
///
/// ## Màu ở đây nói gì
///
/// * `iconColor` / `tint` — **định vị**: giúp mắt tìm đúng module. Chỉ dùng cho
///   ô biểu tượng, nền thẻ và nhãn hành động.
/// * `valueTone` · delta · đường — **ngữ nghĩa**: xanh tích cực · đỏ tiêu cực ·
///   **xám khi không biết**.
///
/// Trộn hai vai ấy là lỗi WTM-375 đã dọn một lần (gieo theme bằng xanh lá khiến
/// cả app ngầm nói "thành công" ở mọi chỗ chưa ai sơn tay).
///
/// ## ⛔ Thiếu dữ liệu thì NÓI THIẾU
///
/// `trend = unknown` ⇒ không mũi tên, không phần trăm, không chữ xám giả vờ.
/// Và [TtSparkline] tự từ chối vẽ khi dưới 3 điểm. Một thẻ "0%" màu xanh khi
/// chưa có mốc so là một lời khẳng định không ai đo được.
class TtMetricCard extends StatelessWidget {
  const TtMetricCard({
    required this.label,
    required this.value,
    required this.iconData,
    required this.iconColor,
    this.unitLabel,
    this.valueTone = TtValueTone.neutral,
    this.tint,
    this.deltaLabel,
    this.trend = TtTrend.unknown,
    this.series = const [],
    this.actionLabel,
    this.onTap,
    super.key,
  });

  final String label;

  /// Con số đã định dạng sẵn — thẻ **không** tự tính và **không** tự làm tròn.
  final String value;

  /// Dòng dưới con số: *"cơ hội mới"*, *"tổng khách"*. `null` ⇒ bỏ dòng.
  final String? unitLabel;

  final TtValueTone valueTone;

  final IconData iconData;

  /// Màu ĐỊNH VỊ của module. Không dùng cho con số, delta hay đường.
  final Color iconColor;

  /// Nền nhạt của thẻ — cũng là định vị. `null` ⇒ nền trắng.
  final Color? tint;

  /// Ví dụ *"+20% so với tháng trước"*. `null` ⇒ không có mốc để so.
  final String? deltaLabel;

  final TtTrend trend;

  /// Chuỗi giá trị cũ → mới. Dưới 3 điểm ⇒ không vẽ đường.
  final List<double> series;

  final String? actionLabel;
  final VoidCallback? onTap;

  /// Màu của delta và của đường — **ngữ nghĩa**, không phải định vị.
  Color get _semanticColor => switch (trend) {
    TtTrend.up => TtColors.success,
    TtTrend.down => TtColors.danger,
    TtTrend.unknown => TtColors.textTertiary,
  };

  Color get _valueColor => switch (valueTone) {
    TtValueTone.neutral => TtColors.textPrimary,
    TtValueTone.critical => TtColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final showDelta = deltaLabel != null && trend != TtTrend.unknown;
    return Material(
      color: tint ?? TtColors.surface,
      borderRadius: BorderRadius.circular(TtRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TtRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TtRadius.lg),
            border: Border.all(color: TtColors.border),
          ),
          padding: const EdgeInsets.all(TtSpace.x3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(TtSpace.x2),
                    decoration: BoxDecoration(
                      color: TtColors.surface,
                      borderRadius: BorderRadius.circular(TtRadius.sm),
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(iconData, size: 16, color: iconColor),
                  ),
                  const SizedBox(width: TtSpace.x2),
                  Expanded(
                    child: Text(
                      label,
                      style: TtType.caption.copyWith(
                        color: TtColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TtSpace.x3),
              Text(
                value,
                style: TtType.h1.copyWith(
                  color: _valueColor,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (unitLabel != null)
                Text(
                  unitLabel!,
                  style: TtType.caption.copyWith(color: TtColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (showDelta) ...[
                const SizedBox(height: TtSpace.x2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        trend == TtTrend.up
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 12,
                        color: _semanticColor,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        deltaLabel!,
                        style: TtType.caption.copyWith(color: _semanticColor),
                        // ⭐ HAI dòng, không phải một.
                        //
                        // Trên Nokia 6.1 một dòng cắt thành *"+17% so với tháng
                        // tr…"*. Phần bị nuốt chính là **cái mốc** — và một mức
                        // đổi không có mốc là con số vô nghĩa nhất trên thẻ:
                        // người bán không biết 17% ấy so với hôm qua, tháng
                        // trước, hay năm ngoái.
                        //
                        // Thà thẻ cao thêm một dòng còn hơn giữ lại đúng nửa
                        // câu không dùng được.
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (TtSparkline.hasShape(series)) ...[
                const SizedBox(height: TtSpace.x2),
                TtSparkline(values: series, color: _semanticColor, height: 34),
              ],
              if (actionLabel != null) ...[
                const SizedBox(height: TtSpace.x2),
                Row(
                  children: [
                    Text(
                      actionLabel!,
                      style: TtType.label.copyWith(
                        color: iconColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_forward, size: 13, color: iconColor),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
