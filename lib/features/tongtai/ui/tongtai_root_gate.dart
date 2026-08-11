import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tongtai_onboarding_provider.dart';
import 'screens/tongtai_onboarding_v2_screen.dart';
import 'tongtai_app_shell.dart';

/// Root entry point for Tổng Tài — onboarding on first launch, then the shell.
///
/// WTM-59 (sáu slide) → WTM-178 (hội thoại) → **Epic WTM-349 (Onboarding V2)**.
///
/// ## Bàn giao ngữ cảnh — WTM-357
///
/// Onboarding **không** trao cho Trang chủ một bản sao kết luận của nó. Nó chỉ
/// làm hai việc rồi mở cửa: ghi hồ sơ + mục tiêu xuống repository, và làm mới
/// cây provider dữ liệu nghiệp vụ.
///
/// Vì sao không truyền `FirstPlan` sang: Trang chủ dựng brief bằng **đúng
/// những luật** mà `FirstInsightEngine` vừa chạy, trên **đúng dữ liệu** vừa
/// nhập. Truyền một bản sao sang sẽ tạo ra hai nguồn cho cùng một kết luận, và
/// chúng lệch nhau vào đúng ngày một luật đổi — đúng họ khuyết tật ADR-TON-015
/// cấm. Kết luận giống nhau ở đây là **hệ quả cấu trúc**, không phải một sự
/// trùng khớp cần giữ gìn; có test khoá nó.
///
/// Hệ quả phụ đáng giá: mở app lần thứ hai vẫn ra đúng kế hoạch ấy, vì nó được
/// suy lại chứ không được nhớ.
class TongtaiRootGate extends ConsumerWidget {
  const TongtaiRootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCompletedOnboarding = ref.watch(tongtaiOnboardingProvider);

    if (!hasCompletedOnboarding) {
      return TongtaiOnboardingV2Screen(
        onDone: (_) => ref.read(tongtaiOnboardingProvider.notifier).complete(),
      );
    }

    return const TongtaiAppShell();
  }
}
