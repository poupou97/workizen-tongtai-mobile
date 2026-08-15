import 'package:flutter/material.dart';

import '../../../../core/design/tt.dart';
import '../../../../core/l10n/app_strings.dart';

/// **Màn chào lúc mở app** — dựng theo `assets/new-icon/loading-screen.png`
/// (WTM-433, Epic WTM-435).
///
/// ## Vì sao phải là màn Flutter, không phải một ảnh splash
///
/// Native splash của Android chỉ vẽ được **một drawable tĩnh**: không chữ,
/// không chuyển động. Trước WTM-433, thứ người dùng thấy lúc mở app đúng là
/// như vậy — **logo `Ai CRM` giữa nền trắng trơn**, trong khi concept có tám
/// thành phần. Founder nói thẳng: *"thiếu text, chưa có thanh loading"*.
///
/// Nhét cả concept vào một PNG cũng không được: chữ sẽ vỡ theo tỉ lệ màn, và
/// bảy chấm thì không chạy.
///
/// ⇒ Native splash **giữ nguyên** (nó hiện *trước khi* Flutter engine sống,
/// không bỏ được), rồi màn này tiếp quản ngay khi engine sẵn sàng.
///
/// ## Nó KHÔNG phải màn chờ nhân tạo
///
/// [minimumHold] là **sàn**, không phải thời lượng cố định: nếu app sẵn sàng
/// muộn hơn thì màn chào tự nhường chỗ ngay. Kéo dài thời gian mở app để khoe
/// một màn chào là đánh đổi sai — người bán mở app để làm việc.
class TongtaiSplashScreen extends StatefulWidget {
  const TongtaiSplashScreen({
    super.key,
    required this.onDone,
    this.minimumHold = const Duration(milliseconds: 1600),
  });

  /// Gọi khi màn chào xong phần của nó.
  final VoidCallback onDone;

  /// Thời gian **tối thiểu** giữ màn — đủ để đọc, không đủ để sốt ruột.
  ///
  /// Tiêm được để test không phải chờ thật, và để dựng bản cho Founder xem
  /// bằng một giá trị lớn hơn mà không đụng vào mã sản phẩm.
  final Duration minimumHold;

  @override
  State<TongtaiSplashScreen> createState() => _TongtaiSplashScreenState();
}

class _TongtaiSplashScreenState extends State<TongtaiSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.minimumHold, () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: TtColors.surface,
      body: Stack(
        children: [
          const Positioned.fill(child: _SoftWaves()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                // Cuộn được, KHÔNG cố định: ở 320px với cỡ chữ 1,3× thì khối
                // chữ cao hơn màn, và một `Column` cứng sẽ tràn (cổng
                // `overflow_test` bắt đúng điều này).
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TtSpace.x6,
                        vertical: TtSpace.x6,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Wordmark(l10n: l10n),
                          const _MascotBlock(),
                          _Footer(l10n: l10n, dots: _dots),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo + ba dòng chữ thương hiệu.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.l10n});

  final AppStrings l10n;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      // `Flexible` + trần chiều cao: ở màn 320px cỡ chữ 1,3× logo từng đẩy cả
      // khối tràn 32px (WTM-416 đã trả giá một lần).
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 132),
        child: Image.asset(
          // ⚠️ `loading-screen.png` là CẢ TẤM concept, không phải riêng logo.
          // Bản đầu tôi trỏ vào nó và `BoxFit.contain` co cả tấm xuống 148px
          // ⇒ logo nhỏ tới mức vô hình, để lại một khoảng trống giữa màn. Chỉ
          // nhìn trên máy mới thấy — suite không có mắt (WTM-433).
          'assets/new-icon/wordmark.png',
          fit: BoxFit.contain,
          // Ảnh thiếu ⇒ khoảng trống, KHÔNG phải ô báo lỗi đỏ giữa màn chào.
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
          // Trang trí: ba dòng chữ ngay dưới đã mang trọn nghĩa, nên gán nhãn
          // cho ảnh chỉ khiến trình đọc màn hình đọc thương hiệu hai lần.
          excludeFromSemantics: true,
        ),
      ),
      const SizedBox(height: TtSpace.x4),
      Text(
        l10n.splashOwner,
        key: const Key('splash-owner'),
        style: TtType.title.copyWith(color: TtColors.ai),
      ),
      const SizedBox(height: TtSpace.x1),
      Text(
        l10n.splashProduct,
        key: const Key('splash-product'),
        textAlign: TextAlign.center,
        style: TtType.h2.copyWith(color: TtColors.textPrimary),
      ),
      const SizedBox(height: TtSpace.x2),
      _PlatformLine(label: l10n.splashPlatform),
    ],
  );
}

/// *"Nền tảng AI"* giữa hai gạch mảnh — đúng như concept vẽ.
class _PlatformLine extends StatelessWidget {
  const _PlatformLine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Expanded(child: Divider(color: TtColors.border, endIndent: 12)),
      Text(
        label,
        key: const Key('splash-platform'),
        style: TtType.title.copyWith(color: TtColors.brand),
      ),
      const Expanded(child: Divider(color: TtColors.border, indent: 12)),
    ],
  );
}

/// Linh vật vẫy tay. Concept có thêm bốn thẻ nổi quanh nó; chúng nằm sẵn
/// trong chính ảnh nên không dựng lại bằng widget.
class _MascotBlock extends StatelessWidget {
  const _MascotBlock();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TtSpace.x4),
    child: Image.asset(
      'assets/mascot/brand/waving.png',
      key: const Key('splash-mascot'),
      height: 220,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
      excludeFromSemantics: true,
    ),
  );
}

class _Footer extends StatelessWidget {
  const _Footer({required this.l10n, required this.dots});

  final AppStrings l10n;
  final Animation<double> dots;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _LoadingDots(animation: dots),
      const SizedBox(height: TtSpace.x3),
      Text(
        l10n.splashLoading,
        key: const Key('splash-loading'),
        style: TtType.title.copyWith(color: TtColors.textPrimary),
      ),
      const SizedBox(height: TtSpace.x1),
      Text(
        l10n.splashTagline,
        key: const Key('splash-tagline'),
        textAlign: TextAlign.center,
        style: TtType.caption.copyWith(color: TtColors.textSecondary),
      ),
    ],
  );
}

/// **Bảy chấm** chuyển sắc cam → tím, chạy thành sóng.
///
/// ⚠️ KHÔNG dùng `LinearProgressIndicator`: một thanh tiến độ **hứa một tỉ lệ
/// phần trăm có thật**, mà lúc này chẳng ai đo được đã xong bao nhiêu. Bảy chấm
/// nói đúng thứ đang xảy ra — *"đang làm việc"* — mà không bịa một con số.
class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.animation});

  static const int count = 7;

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, _) => Row(
      key: const Key('splash-dots'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: TtSpace.x2),
          _Dot(
            // Sắc đi từ cam (thương hiệu) sang tím (AI) — hai đầu của ngôn ngữ
            // màu sản phẩm, đúng dải concept vẽ.
            color: Color.lerp(TtColors.brand, TtColors.ai, i / (count - 1))!,
            // Sóng chạy: chấm nào tới lượt thì đậm và to hơn một chút.
            phase: ((animation.value * count) - i) % count,
          ),
        ],
      ],
    ),
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.phase});

  final Color color;
  final double phase;

  @override
  Widget build(BuildContext context) {
    final near = (1 - (phase.clamp(0, 2) / 2)).clamp(0.0, 1.0);
    final size = 8.0 + 3.0 * near;
    return SizedBox(
      width: 11,
      height: 11,
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.45 + 0.55 * near),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Nền sóng tím-đào mềm ở hai góc dưới, như concept.
class _SoftWaves extends StatelessWidget {
  const _SoftWaves();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          TtColors.surface,
          TtColors.surface,
          TtColors.ai.withValues(alpha: 0.07),
        ],
        stops: const [0, 0.55, 1],
      ),
    ),
  );
}
