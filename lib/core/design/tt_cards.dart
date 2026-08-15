/// Thẻ, số liệu, trạng thái — Design System v1.0 (WTM-364).
///
/// ## ⛔ Không phải thông tin nào cũng cần một thẻ
///
/// Chỉ dựng thẻ khi nội dung là **một đối tượng nghiệp vụ rõ ràng**: một mặt
/// hàng, một khách, một phát hiện. Bọc mỗi đoạn chữ vào một hộp có viền sẽ làm
/// màn hình trông như một bảng điều khiển và không còn thứ tự đọc.
///
/// Ưu tiên **viền nhẹ hơn đổ bóng**: trên nền sáng, viền đọc rõ hơn, và một màn
/// mà mọi thẻ đều nổi lên thì không thẻ nào còn nổi.
library;

import 'package:flutter/material.dart';

import 'tt_tokens.dart';

/// Thẻ tiêu chuẩn — trắng, viền nhạt, bo 16.
class TtCard extends StatelessWidget {
  const TtCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(TtSpace.cardPadding),
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;

  /// Có `onTap` ⇒ cả thẻ là vùng chạm. Một dòng chữ trông bấm được mà chỉ bấm
  /// trúng khi nhắm đúng vài chục pixel vẫn là một lời hứa hỏng (WTM-360).
  final VoidCallback? onTap;

  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: padding, child: child);
    return Container(
      decoration: BoxDecoration(
        color: TtColors.surface,
        borderRadius: BorderRadius.circular(TtRadius.lg),
        border: Border.all(color: borderColor ?? TtColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}

/// Thẻ **Tổng Tài đang nói** — nền tím nhạt, viền tím, bo 20.
///
/// Dùng cho *"Tổng Tài phát hiện"* · *"Tổng Tài khuyến nghị"* · AI Insight ·
/// AI Brief. Không dùng cho dữ liệu thô: nếu nội dung là một bản ghi người bán
/// tự nhập thì nó không phải thứ AI nói, và tô tím sẽ nhận công cho AI.
class TtAiCard extends StatelessWidget {
  const TtAiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(TtSpace.heroPadding),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: padding, child: child);
    return Container(
      decoration: BoxDecoration(
        color: TtColors.aiSoft,
        borderRadius: BorderRadius.circular(TtRadius.xl),
        border: Border.all(color: TtColors.aiBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}

/// Thẻ mang một mức nghiêm trọng — vạch **đặc** bên trái.
///
/// Vạch chứ không phải sắc độ viền: dogfood WTM-360 cho thấy bốn thẻ chỉ khác
/// nhau ở độ đậm viền thì mắt không tách được ở khoảng cách đọc. Màu được đọc
/// **trước** chữ.
class TtStatusCard extends StatelessWidget {
  const TtStatusCard({
    super.key,
    required this.status,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(TtSpace.cardPadding),
  });

  final TtStatus status;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final body = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 4, color: status.color),
          Expanded(
            child: Padding(padding: padding, child: child),
          ),
        ],
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: TtColors.surface,
        borderRadius: BorderRadius.circular(TtRadius.lg),
        border: Border.all(color: TtColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}

/// Nhãn trạng thái nhỏ, hình viên thuốc.
class TtStatusBadge extends StatelessWidget {
  const TtStatusBadge({
    super.key,
    required this.status,
    required this.label,
    this.icon,
  });

  final TtStatus status;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: TtSpace.x3,
      vertical: TtSpace.x1,
    ),
    decoration: BoxDecoration(
      color: status.soft,
      borderRadius: BorderRadius.circular(TtRadius.full),
      border: Border.all(color: status.color.withValues(alpha: 0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: status.color),
          const SizedBox(width: TtSpace.x1),
        ],
        // ⭐ WTM-414 (DS-2) — nhãn PHẢI co được.
        //
        // Một component dùng chung mà có thể làm **tràn bất kỳ hàng nào** đặt
        // nó vào là khuyết tật của Design System, không phải của màn. Khi 5 màn
        // bỏ chip tự chế để dùng huy hiệu này, hàng sản phẩm của Kho tràn 8px —
        // vì huy hiệu chung rộng hơn bản tự chế (đệm x3 + viền) và nhãn không
        // chịu co.
        //
        // Sửa ở đây thay vì bọc `Flexible` ở từng chỗ gọi: chỗ gọi thứ sáu sẽ
        // không nhớ phải bọc.
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TtType.label.copyWith(color: status.color),
          ),
        ),
      ],
    ),
  );
}

/// Một con số nghiệp vụ: giá trị lớn, chênh lệch có màu, chú thích nhạt.
class TtMetric extends StatelessWidget {
  const TtMetric({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.deltaStatus,
    this.context_,
    this.large = false,
  });

  final String label;

  /// Đã định dạng sẵn. Widget không tự định dạng tiền: định dạng là việc của
  /// miền, và hai chỗ định dạng sẽ ra hai kết quả (`TongtaiFormatters`).
  final String value;

  final String? delta;

  /// `null` khi chưa biết chiều — và khi đó [delta] hiện màu **xám**, không
  /// phải xanh. Chưa biết không phải một kết quả tốt.
  final TtStatus? deltaStatus;

  final String? context_;
  final bool large;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: TtType.caption),
      const SizedBox(height: TtSpace.x1),
      Text(value, style: large ? TtType.metricLarge : TtType.metric),
      if (delta case final d?) ...[
        const SizedBox(height: TtSpace.x1),
        Text(
          d,
          style: TtType.label.copyWith(
            // ⚠️ `unknown` ở đây là ĐÚNG — tôi đã đổi nhầm sang `neutral` ở
            // WTM-425 và `tt_components_test` bắt lại.
            //
            // `deltaStatus == null` KHÔNG phải "biết mà không phán xét"; nó là
            // **chưa có kỳ trước để so** (xem `weekly_review_screen`). Thiếu
            // dữ liệu thì mang màu thiếu dữ liệu. Ranh giới hẹp và dễ trượt:
            // *không có gì để so* ≠ *so rồi, bằng phẳng* — cái sau mới là
            // `neutral`, và nó nằm ở `_deltaStatus` của màn tổng kết tuần.
            color: (deltaStatus ?? TtStatus.unknown).color,
          ),
        ),
      ],
      if (context_ case final c?)
        Text(c, style: TtType.caption.copyWith(color: TtColors.textTertiary)),
    ],
  );
}

/// Ba–bốn KPI trên **cùng một mặt**.
///
/// Không phải mỗi KPI một thẻ: bốn hộp cạnh nhau làm mắt phải nhảy bốn lần cho
/// một câu chuyện duy nhất, và nó cũng ngốn hết chiều cao màn hình.
class TtMetricRow extends StatelessWidget {
  const TtMetricRow({super.key, required this.metrics});

  final List<TtMetric> metrics;

  @override
  Widget build(BuildContext context) => TtCard(
    child: Wrap(spacing: TtSpace.x6, runSpacing: TtSpace.x4, children: metrics),
  );
}

/// Chưa có gì — nhưng **đã nhìn**.
class TtEmptyState extends StatelessWidget {
  const TtEmptyState({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String body;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 40, color: TtColors.textTertiary),
      const SizedBox(height: TtSpace.x3),
      Text(title, style: TtType.h3),
      const SizedBox(height: TtSpace.x1),
      Text(body, style: TtType.body.copyWith(color: TtColors.textSecondary)),
      if (action case final a?) ...[const SizedBox(height: TtSpace.x4), a],
    ],
  );
}

/// ⭐ **Chưa đủ dữ liệu để kết luận** — khác hẳn [TtEmptyState].
///
/// Rỗng nghĩa *"đã xét và không có gì"*; cái này nghĩa *"chưa xét được"*. Gộp
/// hai câu đó là cách một màn im lặng biến thành lời trấn an sai — luật đã lặp
/// lại ở `SeasonalVerdict`, `FirstInsight` và ADR-TON-017, nên nó có widget
/// riêng chứ không phải một biến thể màu.
///
/// Luôn **xám**. Không bao giờ xanh.
class TtInsufficientData extends StatelessWidget {
  const TtInsufficientData({
    super.key,
    required this.title,
    required this.reason,
    this.action,
  });

  final String title;

  /// Thiếu **cái gì** — để người bán biết bổ sung gì, thay vì chỉ biết là
  /// thiếu.
  final String reason;

  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(TtSpace.cardPadding),
    decoration: BoxDecoration(
      color: TtStatus.unknown.soft,
      borderRadius: BorderRadius.circular(TtRadius.lg),
      border: Border.all(color: TtColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.help_outline, size: 20, color: TtStatus.unknown.color),
            const SizedBox(width: TtSpace.x2),
            Expanded(child: Text(title, style: TtType.title)),
          ],
        ),
        const SizedBox(height: TtSpace.x1),
        Text(
          reason,
          style: TtType.body.copyWith(color: TtColors.textSecondary),
        ),
        if (action case final a?) ...[const SizedBox(height: TtSpace.x3), a],
      ],
    ),
  );
}

/// Tiêu đề một khối + lối "xem tất cả".
class TtSectionHeader extends StatelessWidget {
  const TtSectionHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: TtType.h3)),
      ?action,
    ],
  );
}

/// **Dải thẻ cuộn ngang** — bố cục dùng chung của mọi hàng thẻ số liệu.
///
/// ## Vì sao KHÔNG đóng cứng chiều cao
///
/// Thẻ có thể có hoặc không có dòng delta, đường xu hướng, nhãn đơn vị. Đặt một
/// `SizedBox(height: …)` quanh chúng là đoán trước tổ hợp nào sẽ xuất hiện —
/// và WTM-419 đã đoán trượt đúng 22px ngay lần đầu, ở đúng ca có delta.
///
/// `IntrinsicHeight` để **thẻ tự khai chiều cao**, còn dải chỉ lo bề ngang và
/// việc cuộn. Mọi thẻ trong hàng cao bằng nhau vì `stretch`, không vì ai đó
/// nhớ đúng con số.
///
/// ## Vì sao không thêm đệm ngang
///
/// Trang đã có đệm riêng. Trên Nokia 6.1 (411dp) phần còn lại là 379dp — hai
/// thẻ đủ và thẻ thứ ba ló ra ~31dp, đúng tín hiệu *"còn nữa, cuộn đi"* mà
/// concept vẽ bằng cách cắt ngang thẻ cuối.
class TtCardRail extends StatelessWidget {
  const TtCardRail({
    required this.children,
    this.cardWidth = defaultCardWidth,
    super.key,
  });

  /// Đủ cho `24,56tr đ` ở cỡ `h1` mà không phải thu nhỏ.
  static const double defaultCardWidth = 168;

  final List<Widget> children;
  final double cardWidth;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: TtSpace.x3),
            SizedBox(width: cardWidth, child: children[i]),
          ],
        ],
      ),
    ),
  );
}
