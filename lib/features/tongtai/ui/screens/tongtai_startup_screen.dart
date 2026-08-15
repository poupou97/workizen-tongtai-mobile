import 'package:flutter/material.dart';

import '../../../../core/design/tt.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../startup/startup_pipeline.dart';

/// **Màn khởi động** — WTM-367 (Epic WTM-362).
///
/// Tham chiếu thị giác: `docs/01-PRODUCT/concept-1/screen-startup.png`.
///
/// ## Hai chỗ concept vẽ sai, và màn này không chép
///
/// **"68%".** Concept vẽ một thanh tiến trình đứng ở 68%. Con số duy nhất hợp
/// lệ ở đây là *số bước THẬT đã xong / tổng số bước THẬT* — và danh sách bước
/// là `StartupStep`, một enum, nên nó không co giãn theo ý màn hình. Không có
/// `Duration` nào trong màn này.
///
/// **"Đang kiểm tra dữ liệu và các mô hình AI".** App **không tải mô hình AI
/// nào** lúc khởi động: BYOK gọi thẳng nhà cung cấp vào lúc người bán hỏi, và
/// bản demo không gọi gì cả. Nói thế là quảng cáo cho một năng lực không chạy,
/// nên câu chữ ở đây nói đúng việc đang làm: mở cơ sở dữ liệu, đọc hồ sơ, đọc
/// danh mục, đọc đơn hàng.
///
/// ## Nhanh quá thì không hiện
///
/// Màn này chỉ được dựng khi khởi động lâu hơn ngưỡng của
/// `StartupRun.visibleThreshold`. Một màn loading chớp qua làm app trông giật —
/// tức là thứ để trấn an lại thành thứ gây lo.
///
/// ## Nhận diện mới (WTM-416) — chép bố cục, KHÔNG chép câu chữ
///
/// Founder giao `assets/new-icon/loading-screen.png`. Màn này lấy đúng bố cục
/// ấy: logo trên cùng · chủ sở hữu · tên sản phẩm · đường kẻ "AI Platform" ·
/// linh vật · dòng trạng thái.
///
/// ⚠️ Một chỗ **cố ý lệch bản vẽ**: bản vẽ ghi *"Customer Relationship
/// Management"*. Tổng Tài không phải một CRM — nó có tám năng lực, trong đó
/// quan hệ khách hàng chỉ là một. In dòng ấy lên màn đầu tiên là **hứa sai sản
/// phẩm** với chính người sắp dùng nó, nên chỗ đó dùng câu mô tả đã có sẵn của
/// app. Tên hiển thị, logo, và nhãn nền tảng thì giữ nguyên bản vẽ.
///
/// ⚠️ Linh vật ở đây là **ảnh cắt thẳng từ bản vẽ**, không phải một tư thế
/// trong `MascotPose`: hai bộ cáo vẽ khác nhau, và trộn chúng trên cùng một màn
/// làm người xem thấy hai sản phẩm. Bộ 25 tư thế vẫn dùng cho trong app.
class TongtaiStartupScreen extends StatelessWidget {
  const TongtaiStartupScreen({super.key, required this.progress});

  /// Các chặng **đã xong**. Danh sách này chỉ dài ra khi có việc thật xong,
  /// nên không có cách nào vẽ một tiến trình chạy trước công việc.
  final List<StartupProgress> progress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final done = progress.isEmpty ? 0 : progress.last.done;
    final total = progress.isEmpty
        ? StartupStep.values.length
        : progress.last.total;

    return Scaffold(
      // Nền trắng theo bản vẽ. Dải linh vật mang sẵn nền chuyển sắc của chính
      // nó, mép đo được 250–254 nên ghép vào đây không lộ đường.
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TtSpace.screenH),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo co được, không cố định chiều cao: ở 320px với chữ 1,3×
              // phần chữ nở ra và bản cố định 132px làm tràn 32px — test §3
              // bắt đúng chỗ này. Trần 132 giữ cho máy lớn không phóng to logo.
              Flexible(
                flex: 3,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 132),
                  child: Image.asset(
                    'assets/startup/logo_lockup.png',
                    fit: BoxFit.contain,
                    // Logo đã mang sẵn tên thương hiệu; đọc lại tên ấy bằng
                    // giọng nói là thừa, nên nhãn trợ năng nói việc đang diễn ra.
                    semanticLabel: l10n.startupWorking,
                  ),
                ),
              ),
              const SizedBox(height: TtSpace.x4),
              Text(
                l10n.startupBrandOwner,
                style: TtType.label.copyWith(color: TtColors.ai),
              ),
              const SizedBox(height: TtSpace.x1),
              Text(
                l10n.startupBrand,
                textAlign: TextAlign.center,
                style: TtType.display,
              ),
              const SizedBox(height: TtSpace.x2),
              _PlatformDivider(label: l10n.startupPlatform),
              const SizedBox(height: TtSpace.x3),
              Text(
                l10n.startupTagline,
                textAlign: TextAlign.center,
                style: TtType.body.copyWith(color: TtColors.textSecondary),
              ),
              const Spacer(),
              Flexible(
                flex: 8,
                child: Image.asset(
                  'assets/startup/startup_mascot.png',
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
              const Spacer(),
              _ProgressCard(progress: progress, done: done, total: total),
              const SizedBox(height: TtSpace.x4),
              Padding(
                padding: const EdgeInsets.only(bottom: TtSpace.x4),
                child: Text(
                  // Câu này ĐÚNG, nên nó ở lại: local-first, không tài khoản,
                  // không đồng bộ. Nó không phải một lời trấn an trang trí.
                  l10n.startupPrivacy,
                  style: TtType.caption.copyWith(color: TtColors.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Đường kẻ hai bên một nhãn ngắn — đúng khoá nhận diện Founder giao.
class _PlatformDivider extends StatelessWidget {
  const _PlatformDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Expanded(child: Divider(color: TtColors.border, endIndent: 12)),
      Text(label, style: TtType.label.copyWith(color: TtColors.brand)),
      const Expanded(child: Divider(color: TtColors.border, indent: 12)),
    ],
  );
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.progress,
    required this.done,
    required this.total,
  });

  final List<StartupProgress> progress;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TtCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 20, color: TtColors.ai),
              const SizedBox(width: TtSpace.x2),
              Expanded(child: Text(l10n.startupWorking, style: TtType.title)),
              Text(
                // Tỉ lệ **bước thật**, không phải một đường cong thời gian.
                '$done/$total',
                key: const Key('startup-fraction'),
                style: TtType.label.copyWith(color: TtColors.ai),
              ),
            ],
          ),
          const SizedBox(height: TtSpace.x3),
          ClipRRect(
            borderRadius: BorderRadius.circular(TtRadius.full),
            child: LinearProgressIndicator(
              key: const Key('startup-bar'),
              value: total == 0 ? null : done / total,
              minHeight: 6,
              backgroundColor: TtColors.surfaceTertiary,
              valueColor: const AlwaysStoppedAnimation(TtColors.ai),
            ),
          ),
          // Mỗi dòng chỉ tồn tại vì chặng của nó ĐÃ CHẠY XONG. Danh sách không
          // có phần "sẽ chạy" — không có chỗ cho một con số xuất hiện trước
          // việc sinh ra nó (cùng khuôn với `AnalysisPipeline`, WTM-353).
          for (final p in progress) ...[
            const SizedBox(height: TtSpace.x2),
            Row(
              key: Key('startup-step-${p.step.code}'),
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: TtColors.success,
                ),
                const SizedBox(width: TtSpace.x2),
                Expanded(
                  child: Text(
                    l10n.startupStep(p.step.code, p.count),
                    style: TtType.caption,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
