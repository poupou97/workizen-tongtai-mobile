import 'package:flutter/material.dart';

import '../../../../core/design/tt.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../startup/startup_pipeline.dart';
import '../widgets/tongtai_mascot_pose.dart';

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
      backgroundColor: TtColors.surfaceSecondary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TtSpace.screenH),
          child: Column(
            children: [
              const Spacer(),
              TongtaiMascotPose(
                MascotPose.working,
                height: 170,
                semanticsLabel: l10n.startupWorking,
              ),
              const SizedBox(height: TtSpace.x5),
              Text(l10n.startupBrand, style: TtType.display),
              const SizedBox(height: TtSpace.x2),
              Text(
                l10n.startupTagline,
                textAlign: TextAlign.center,
                style: TtType.body.copyWith(color: TtColors.textSecondary),
              ),
              const SizedBox(height: TtSpace.x8),
              _ProgressCard(progress: progress, done: done, total: total),
              const SizedBox(height: TtSpace.x8),
              const _ValueRow(),
              const Spacer(),
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

class _ValueRow extends StatelessWidget {
  const _ValueRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Value(
          icon: Icons.psychology_outlined,
          color: TtColors.ai,
          title: l10n.startupValueUnderstandTitle,
          body: l10n.startupValueUnderstandBody,
        ),
        _Value(
          icon: Icons.track_changes,
          color: TtColors.brand,
          title: l10n.startupValueActTitle,
          body: l10n.startupValueActBody,
        ),
        _Value(
          icon: Icons.insights_outlined,
          color: TtColors.success,
          title: l10n.startupValueMeasureTitle,
          body: l10n.startupValueMeasureBody,
        ),
      ],
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: TtSpace.x2),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TtType.label.copyWith(color: TtColors.textPrimary),
        ),
        const SizedBox(height: TtSpace.x1),
        Text(body, textAlign: TextAlign.center, style: TtType.caption),
      ],
    ),
  );
}
