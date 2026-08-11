import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tongtai_onboarding_provider.dart';
import '../providers/tongtai_startup_provider.dart';
import '../startup/startup_pipeline.dart';
import 'screens/tongtai_onboarding_v2_screen.dart';
import 'screens/tongtai_startup_screen.dart';
import 'tongtai_app_shell.dart';

/// Root entry point for Tổng Tài — khởi động → onboarding hoặc shell.
///
/// WTM-59 (sáu slide) → WTM-178 (hội thoại) → Epic WTM-349 (Onboarding V2) →
/// **WTM-367 (màn khởi động)**.
///
/// ## Bàn giao ngữ cảnh — WTM-357
///
/// Onboarding **không** trao cho Trang chủ một bản sao kết luận của nó. Nó ghi
/// hồ sơ + mục tiêu + hành trình xuống repository rồi làm mới cây provider.
/// Trang chủ dựng brief bằng **đúng những luật** `FirstInsightEngine` vừa
/// chạy, trên **đúng dữ liệu** vừa nhập — nên kết luận giống nhau là **hệ quả
/// cấu trúc**, không phải một sự trùng khớp cần giữ gìn. Truyền bản sao sang
/// sẽ tạo hai nguồn cho cùng một kết luận, và chúng lệch nhau vào đúng ngày
/// một luật đổi (ADR-TON-015).
///
/// ## Màn khởi động chỉ hiện khi đáng hiện — WTM-367
///
/// Pipeline chạy các bước **thật** (mở CSDL + migration, đọc cờ onboarding,
/// đếm danh mục, đếm đơn). Xong nhanh hơn `StartupRun.visibleThreshold` thì
/// màn này **không bao giờ được dựng**: một màn loading chớp qua làm app trông
/// giật, tức là thứ để trấn an lại thành thứ gây lo.
class TongtaiRootGate extends ConsumerStatefulWidget {
  const TongtaiRootGate({super.key});

  @override
  ConsumerState<TongtaiRootGate> createState() => _TongtaiRootGateState();
}

class _TongtaiRootGateState extends ConsumerState<TongtaiRootGate> {
  final List<StartupProgress> _progress = [];

  /// Máy còn đang hâm nóng. Tắt khi xong **hoặc khi lỗi**.
  bool _booting = true;

  /// Đã trôi qua đủ lâu để việc hiện màn khởi động là hợp lý.
  bool _slowEnough = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final started = DateTime.now();
    // Không `try/catch` ở đây: `ui/` không được tự bắt lỗi (ADR-TON-017), và
    // `StartupPipeline` đã tự nuốt lỗi từng bước — một bước hỏng vẫn phát tín
    // hiệu, chỉ là không mang con số nào.
    await for (final p
        in ref.read(startupPipelineProvider).run(onDone: (_) {})) {
      if (!mounted) return;
      setState(() {
        _progress.add(p);
        // Quyết định hiện màn dựa trên thời gian ĐÃ TRÔI QUA thật, không dựa
        // trên số bước: một máy nhanh chạy hết bốn bước trong 80ms và không
        // đáng phải nhìn thấy gì.
        if (!_slowEnough &&
            DateTime.now().difference(started) >= StartupRun.visibleThreshold) {
          _slowEnough = true;
        }
      });
    }
    if (mounted) setState(() => _booting = false);
  }

  @override
  Widget build(BuildContext context) {
    // ⭐ Màn đích quyết định **ngay**, từ cờ onboarding đọc đồng bộ được.
    //
    // Bản đầu chặn màn đích cho tới khi khởi động xong. Sai ở hai chỗ: một
    // pipeline treo sẽ nhốt người dùng ở màn trắng vĩnh viễn, và onboarding
    // vốn không cần kết quả khởi động nào cả. Khởi động là **hâm nóng**, không
    // phải một cửa.
    //
    // Màn khởi động chỉ chen lên khi việc hâm nóng thật sự lâu — nên máy nhanh
    // không bao giờ thấy nó nháy, và máy chậm thì thấy tiến trình thật.
    final hasCompletedOnboarding = ref.watch(tongtaiOnboardingProvider);

    if (_booting && _slowEnough) {
      return TongtaiStartupScreen(progress: _progress);
    }

    if (!hasCompletedOnboarding) {
      return TongtaiOnboardingV2Screen(
        onDone: (_) => ref.read(tongtaiOnboardingProvider.notifier).complete(),
      );
    }

    return const TongtaiAppShell();
  }
}
