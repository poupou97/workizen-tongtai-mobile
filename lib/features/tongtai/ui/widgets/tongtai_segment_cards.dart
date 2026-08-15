import 'package:flutter/material.dart';

import '../../../../core/design/tt.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../analytics/customer_segment_view.dart';
import '../../consumer/customer_segment.dart';
import 'tt_metric_card.dart';

/// **Dải thẻ phân khúc khách** — WTM-419 bước 2 (concept-1 `cp4`).
///
/// ## Vì sao là 8 thẻ chứ không phải "6 thẻ + thẻ Khác"
///
/// Concept vẽ đúng 6 thẻ; app suy ra 8 phân khúc. Tôi đã đề xuất *"6 thẻ + một
/// thẻ Khác gộp"* để không mất thông tin, và Founder trao quyền quyết.
///
/// Khi vào việc thì phần gộp không đáng: nó **thêm một cú bấm để giấu đúng hai
/// phân khúc** (`Khách VIP`, `Đang giảm nhịp`) — mà cả hai đều là thứ người bán
/// cần thấy ngay, một cái là tiền, một cái là dấu hiệu sớm nhất của rời bỏ.
/// Một nhóm "Khác" chỉ đáng tồn tại khi cái đuôi dài; ở đây đuôi có hai phần
/// tử. Nên: giữ **nhịp thị giác** của concept (dải thẻ cuộn ngang, icon + số),
/// bỏ phần gộp.
///
/// ## Thứ tự là VÒNG ĐỜI, không phải số lượng
///
/// Mới → mua một lần → quay lại → trung thành → VIP → giảm nhịp → nguy cơ → rời
/// bỏ. Sắp theo số lượng thì thứ tự nhảy loạn mỗi lần dữ liệu đổi, và người bán
/// mất luôn thứ duy nhất dải này kể được: **một dòng chảy**.
///
/// ## ⛔ Không vẽ mũi tên khi không có mốc
///
/// Xu hướng tính bằng cách chấm lại phân khúc ở mốc 30 ngày trước **từ đơn hàng
/// thật**. Người bán mới dùng app hai tuần thì mốc ấy rỗng, và mọi phần trăm
/// dựng trên nó là bịa. `TtTrend.unknown` + `deltaLabel: null` là câu trả lời
/// đúng, không phải `0%`.
class TongtaiSegmentCards extends StatelessWidget {
  const TongtaiSegmentCards({required this.view, this.onTap, super.key});

  final CustomerSegmentView view;

  /// Bấm một thẻ ⇒ mở danh sách khách của phân khúc ấy. `null` ⇒ thẻ chỉ đọc.
  final void Function(CustomerSegment segment)? onTap;

  /// Thứ tự vòng đời — xem ghi chú lớp.
  static const List<CustomerSegment> order = [
    CustomerSegment.newcomer,
    CustomerSegment.oneTime,
    CustomerSegment.returning,
    CustomerSegment.loyal,
    CustomerSegment.vip,
    CustomerSegment.slowing,
    CustomerSegment.atRisk,
    CustomerSegment.churned,
  ];

  static IconData _icon(CustomerSegment s) => switch (s) {
    CustomerSegment.newcomer => Icons.person_add_outlined,
    CustomerSegment.oneTime => Icons.looks_one_outlined,
    CustomerSegment.returning => Icons.autorenew,
    CustomerSegment.loyal => Icons.workspace_premium_outlined,
    CustomerSegment.vip => Icons.diamond_outlined,
    CustomerSegment.slowing => Icons.trending_down,
    CustomerSegment.atRisk => Icons.warning_amber_outlined,
    CustomerSegment.churned => Icons.person_off_outlined,
    CustomerSegment.dormant => Icons.hourglass_empty,
  };

  /// Sắc thái NGỮ NGHĨA của từng phân khúc — đi qua `TtStatus`, không qua màu
  /// thô (DS-2 · WTM-415).
  static TtStatus _tone(CustomerSegment s) => switch (s) {
    CustomerSegment.newcomer ||
    CustomerSegment.returning ||
    CustomerSegment.loyal ||
    CustomerSegment.vip => TtStatus.success,
    CustomerSegment.oneTime => TtStatus.info,
    CustomerSegment.slowing => TtStatus.warning,
    CustomerSegment.atRisk => TtStatus.danger,
    CustomerSegment.churned || CustomerSegment.dormant => TtStatus.unknown,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Phân khúc rỗng vẫn hiện: "0 khách nguy cơ rời bỏ" là một tin tốt có thật,
    // còn thẻ biến mất thì người bán không biết app có đang nhìn hay không.
    final visible = order.where((s) => view.of(s) > 0 || _alwaysShow(s));

    // ⛔ KHÔNG đóng cứng chiều cao. Thẻ có delta thì cao hơn thẻ không có, và
    // bản đầu của tôi đoán 132px rồi tràn đúng 22px ở ca có delta.
    // `TtCardRail` để thẻ tự khai chiều cao (DS · dùng chung với Home).
    return TtCardRail(
      key: const Key('consumer-segment-cards'),
      cardWidth: 150,
      children: [
        for (final segment in visible)
          TtMetricCard(
            key: Key('segment-card-${segment.code}'),
            label: segment.label(l10n.languageCode),
            value: '${view.of(segment)}',
            unitLabel: l10n.segCardUnit,
            iconData: _icon(segment),
            iconColor: _tone(segment).color,
            deltaLabel: _deltaLabel(l10n, segment),
            trend: _trend(segment),
            onTap: onTap == null ? null : () => onTap!(segment),
          ),
      ],
    );
  }

  /// Hai phân khúc luôn hiện dù bằng 0: chúng là **cảnh báo**, và sự vắng mặt
  /// của một cảnh báo phải nhìn thấy được thì mới trấn an được ai.
  static bool _alwaysShow(CustomerSegment s) =>
      s == CustomerSegment.atRisk || s == CustomerSegment.churned;

  String? _deltaLabel(AppStrings l10n, CustomerSegment segment) {
    final delta = view.deltaOf(segment);
    if (delta == null || delta == 0) return null;
    return l10n.segCardDelta(delta);
  }

  TtTrend _trend(CustomerSegment segment) {
    final delta = view.deltaOf(segment);
    if (delta == null || delta == 0) return TtTrend.unknown;
    // ⚠️ "Tăng" KHÔNG đồng nghĩa với "tốt". Thêm khách rời bỏ là tin xấu, và
    // một mũi tên xanh trên thẻ ấy là hình nói dối trước cả chữ.
    final more = delta > 0;
    final goodWhenMore =
        _tone(segment) != TtStatus.danger &&
        _tone(segment) != TtStatus.warning &&
        segment != CustomerSegment.churned;
    return (more == goodWhenMore) ? TtTrend.up : TtTrend.down;
  }
}
