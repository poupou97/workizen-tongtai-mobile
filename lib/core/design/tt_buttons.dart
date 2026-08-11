import 'package:flutter/material.dart';

import 'tt_tokens.dart';

/// Nút — Design System v1.0 (WTM-364).
///
/// Bốn loại, và **loại nào dùng khi nào là một quyết định nghĩa, không phải
/// thẩm mỹ**:
///
/// | Loại | Khi nào | Màu |
/// |---|---|---|
/// | [TtPrimaryButton] | một việc kinh doanh thật | cam |
/// | [TtSecondaryButton] | xem, lưu, so sánh | trắng + viền |
/// | [TtAiActionButton] | hỏi/xem thứ AI nói | tím **nhạt** |
/// | [TtTextAction] | "xem tất cả →" | không nền |
///
/// ⛔ **Không có nút tím đặc.** Tím là màu của *"Tổng Tài đang nói"*; một nút
/// tím đặc trông ngang hàng nút cam và sẽ dạy người bán rằng hai thứ đó cùng
/// loại. Nút AI cố ý nhạt hơn để nó **mời**, không **giục**.
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
          backgroundColor: TtColors.brand,
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
