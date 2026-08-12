import 'package:flutter/material.dart';

import 'tt_tokens.dart';

/// Nút — Design System v1.0 (WTM-364).
///
/// Năm loại, và **loại nào dùng khi nào là một quyết định nghĩa, không phải
/// thẩm mỹ**:
///
/// | Loại | Khi nào | Màu |
/// |---|---|---|
/// | [TtPrimaryButton] | một việc kinh doanh thật | cam |
/// | [TtSecondaryButton] | xem, lưu, so sánh | trắng + viền |
/// | [TtDangerButton] | việc **phá huỷ, không lùi được** | đỏ |
/// | [TtAiActionButton] | hỏi/xem thứ AI nói | tím **nhạt** |
/// | [TtTextAction] | "xem tất cả →" | không nền |
///
/// ⛔ **Không có nút tím đặc.** Tím là màu của *"Tổng Tài đang nói"*; một nút
/// tím đặc trông ngang hàng nút cam và sẽ dạy người bán rằng hai thứ đó cùng
/// loại. Nút AI cố ý nhạt hơn để nó **mời**, không **giục**.
///
/// ## ⭐ Vì sao [TtDangerButton] KHÔNG phá luật "cam = hành động"
///
/// Luật thật không phải *"nút chính luôn cam"* — mà là **một nút không mượn
/// nghĩa nó không có**. Chín nút phải sửa ở WTM-374 mượn nghĩa: `Lưu` màu tím
/// nói *AI đang làm*, `Quan tâm` màu xanh lá nói *đã thành công*.
///
/// *"Khôi phục = Thay thế"* thì **đúng là** đỏ: nó xoá cả sáu repository và
/// không lùi được (ADR-TON-018). Sơn nó cam sẽ làm *"xoá sạch dữ liệu"* trông y
/// hệt *"lưu sản phẩm"* — mất đúng thứ người bán cần nhìn thấy nhất.
///
/// Nên nó là một **loại riêng**, không phải một `FilledButton` ai đó tự sơn.
///
/// Chiều cao 48 và vùng chạm tối thiểu 44×44 nằm ở đây, không rải trong màn.
abstract final class TtButtonMetrics {
  static const double height = 48;
  static const double minTouch = 44;
  static const double hPadding = TtSpace.x5;
  static const double radius = TtRadius.md;
}

/// Việc kinh doanh thật: *"Tạo đơn nhập"* · *"Bắt đầu điều hành"*.
class TtPrimaryButton extends StatelessWidget {
  const TtPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;

  /// `null` = không bấm được. Cố ý bắt buộc truyền: một nút không biết mình có
  /// bấm được không là nút sẽ được nối vào hư không (bài học WTM-360).
  final VoidCallback? onPressed;

  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: TtButtonMetrics.height,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          // `brandOnDark`, không phải `brand`: chữ trắng trên `brand` chỉ đạt
          // 2,80:1 — xem chú thích ở token.
          backgroundColor: TtColors.brandOnDark,
          foregroundColor: TtColors.textOnBrand,
          disabledBackgroundColor: TtColors.borderStrong,
          padding: const EdgeInsets.symmetric(
            horizontal: TtButtonMetrics.hPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TtButtonMetrics.radius),
          ),
          textStyle: TtType.title,
        ),
        child: _Label(label: label, icon: icon),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Nút **nổi** để thêm một bản ghi: *"Thêm sản phẩm"* · *"Thêm giao dịch"*.
///
/// ## ⚠️ Vì sao nó phải nằm ở đây
///
/// Lỗi tìm thấy trên Nokia 6.1 (WTM-382): **bảy màn có FAB, và nó mang bốn màu
/// khác nhau** — xanh dương ở Tạo đơn/Khách, **tím** ở Tài chính và Mục tiêu,
/// hổ phách ở Kho.
///
/// *"Thêm giao dịch"* màu tím nói **AI đang ghi giao dịch**, trong khi người
/// bán mới là người ghi. Đúng lỗi WTM-374 đã dọn cho nút `Lưu`, chỉ khác chỗ
/// nấp: nút nổi.
///
/// Thêm một bản ghi là **HÀNH ĐỘNG** ⇒ cam. Một chỗ khai, bảy màn theo.
///
/// [scrollPadding] là chiều cao cần chừa dưới đáy danh sách để mục cuối cuộn
/// ra khỏi vùng FAB che. Trên máy cao không ai thấy vấn đề; trên Nokia vùng
/// danh sách chỉ còn một hai dòng và FAB che đúng vào đó.
abstract final class TtFab {
  static const Color background = TtColors.brandOnDark;
  static const Color foreground = TtColors.textOnBrand;

  /// 56 (chiều cao FAB) + 16×2 (lề nổi) — chừa đủ cho mục cuối thoát ra.
  static const double scrollPadding = 88;
}

/// Việc **phá huỷ, không lùi được**: *"Thay thế toàn bộ dữ liệu"*.
///
/// Đây là loại duy nhất được mang màu ngữ nghĩa, vì ở đây màu **chính là** điều
/// cần nói — xem chú thích đầu file.
class TtDangerButton extends StatelessWidget {
  const TtDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: TtButtonMetrics.height,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          // `dangerOnLight`, không phải `danger`: chữ trắng trên `danger` chỉ
          // đạt 3,72:1 — cùng lý do với nút cam.
          backgroundColor: TtColors.dangerOnLight,
          foregroundColor: TtColors.textOnBrand,
          disabledBackgroundColor: TtColors.borderStrong,
          padding: const EdgeInsets.symmetric(
            horizontal: TtButtonMetrics.hPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TtButtonMetrics.radius),
          ),
          textStyle: TtType.title,
        ),
        child: _Label(label: label, icon: icon),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Việc phụ trợ: *"Xem phân tích"* · *"Lưu"* · *"So sánh"*.
class TtSecondaryButton extends StatelessWidget {
  const TtSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: TtButtonMetrics.height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: TtColors.surface,
          foregroundColor: TtColors.textPrimary,
          side: const BorderSide(color: TtColors.borderStrong),
          padding: const EdgeInsets.symmetric(
            horizontal: TtButtonMetrics.hPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TtButtonMetrics.radius),
          ),
          textStyle: TtType.title,
        ),
        child: _Label(label: label, icon: icon),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Hỏi hoặc xem thứ **AI** nói: *"Hỏi Tổng Tài"* · *"Xem AI Insight"*.
class TtAiActionButton extends StatelessWidget {
  const TtAiActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.auto_awesome,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: TtButtonMetrics.height,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          // Nền tím **nhạt**, chữ tím. Không phải nút tím đặc — xem chú thích
          // đầu file.
          backgroundColor: TtColors.aiSoft,
          foregroundColor: TtColors.ai,
          disabledBackgroundColor: TtColors.surfaceTertiary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: TtButtonMetrics.hPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TtButtonMetrics.radius),
          ),
          textStyle: TtType.title,
        ),
        child: _Label(label: label, icon: icon),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// *"Xem tất cả →"*. Không nền, nhưng vẫn phải đủ 44px để bấm trúng.
class TtTextAction extends StatelessWidget {
  const TtTextAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = TtColors.brand,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: TtButtonMetrics.minTouch),
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: TtSpace.x2),
        textStyle: TtType.bodyMedium,
        minimumSize: const Size(
          TtButtonMetrics.minTouch,
          TtButtonMetrics.minTouch,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: TtSpace.x1),
          const Icon(Icons.arrow_forward, size: 18),
        ],
      ),
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: TtSpace.x2),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
