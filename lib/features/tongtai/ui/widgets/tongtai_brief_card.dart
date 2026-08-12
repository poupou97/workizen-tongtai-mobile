import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../agent/business_brief.dart';
import '../../providers/tongtai_agentic_provider.dart';
import '../screens/tongtai_agent_screen.dart';
import 'tongtai_brief_widgets.dart';
import 'tongtai_fox_mascot.dart';

/// **Trải nghiệm #1 · AI Morning Brief** — WTM-304 (Epic WTM-302).
///
/// Cảm giác phải đạt, nguyên văn Founder Task Order §6:
///
/// > *"Tổng Tài đã nhìn doanh nghiệp **trước khi tôi mở app**."*
///
/// Nên thẻ này nằm ngay dưới hero, **trên** mọi ô số: thứ tự trên một màn hình
/// là một lời khẳng định về thứ gì quan trọng.
///
/// ## Ba trạng thái, và vì sao "đang tải" không hiện gì
///
/// | | Hiện gì |
/// |---|---|
/// | đang tính | **không gì cả** |
/// | hỏng | một dòng ngắn + nút thử lại |
/// | xong | lời chào + tối đa ba việc |
///
/// Brief tính từ Rule Twin trên toàn bộ sổ sách, nên nó về sau phần còn lại
/// của Home một nhịp. Nhét một khung xương xám vào đó chỉ làm màn hình nhấp
/// nháy mỗi lần mở app.
///
/// Nhưng **hỏng thì phải nói** — im lặng ở đây sẽ đọc thành *"hôm nay không có
/// gì đáng chú ý"*, và đó là câu dối nguy hiểm nhất màn hình này có thể nói.
class TongtaiBriefCard extends ConsumerWidget {
  const TongtaiBriefCard({
    super.key,
    this.clock,
    this.maxItems = 3,
    this.showCount = true,
  });

  /// Đồng hồ tiêm được — lời chào theo buổi phải test được lúc 3 giờ sáng.
  final DateTime Function()? clock;

  final int maxItems;

  /// Có công bố con số của riêng thẻ này không.
  ///
  /// `false` trên **Trang chủ** (WTM-388): ở đó thẻ là **nguồn**, và Home chỉ
  /// được nói một con số. `true` ở mọi nơi khác, nơi nó là chủ của câu chuyện.
  final bool showCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brief = ref.watch(businessBriefProvider);

    if (brief.hasError) {
      return _BriefFailed(onRetry: () => ref.invalidate(businessBriefProvider));
    }
    final items = brief.hasValue ? brief.value : null;
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return _BriefCardBody(
      items: items.take(maxItems).toList(),
      total: items.length,
      showCount: showCount,
      clock: clock,
    );
  }
}

class _BriefCardBody extends StatelessWidget {
  const _BriefCardBody({
    required this.items,
    required this.total,
    required this.showCount,
    this.clock,
  });

  final List<BriefItem> items;
  final int total;

  /// `false` trên Trang chủ — xem WTM-388.
  final bool showCount;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = (clock ?? DateTime.now)();

    return Container(
      key: const Key('home-brief'),
      width: double.infinity,
      padding: const EdgeInsets.all(TtSpace.x4),
      decoration: BoxDecoration(
        color: TtColors.ai.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TtRadius.lg),
        border: Border.all(color: TtColors.ai.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TongtaiFoxMascot.avatar(size: 36),
              const SizedBox(width: TtSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tongtaiBriefGreeting(l10n, now),
                      key: const Key('home-brief-greeting'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TtColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      // ⭐ WTM-388: trên Trang chủ thẻ này là **nguồn**, không
                      // phải một bảng đếm cạnh tranh. Nó từng nói "Có 17 việc
                      // đáng chú ý" ngay dưới câu "43 cơ hội" — hai con số,
                      // một màn, và người bán không biết tin cái nào.
                      //
                      // Con số vẫn còn ở màn Brief đầy đủ; ở đây nó nhường.
                      showCount
                          ? l10n.briefHeadline(total)
                          : l10n.briefHeadlineNoCount,
                      key: const Key('home-brief-headline'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: TtColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TtSpace.x3),
          for (final item in items) _BriefLine(item: item),
          const SizedBox(height: TtSpace.x2),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('home-brief-open'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TongtaiAgentScreen(),
                ),
              ),
              // Vùng bấm ≥48dp — luật của `accessibility_test`, và nó bắt
              // được ngay bản đầu của thẻ này. Người bán cầm điện thoại một
              // tay giữa lúc bán hàng; một nút cao 32dp là một nút họ bấm
              // trượt.
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(48, 48),
                foregroundColor: TtColors.aiOnLight,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.briefSeeAll,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward, size: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Một dòng trong thẻ — **chỉ tiêu đề**, không kèm lý do.
///
/// Lý do sống ở màn Tổng Tài. Nhét chúng vào đây thì thẻ dài bằng cả màn hình
/// và không còn là một lời chào nữa.
class _BriefLine extends StatelessWidget {
  const _BriefLine({required this.item});

  final BriefItem item;

  @override
  Widget build(BuildContext context) {
    final color = tongtaiBriefColor(item.severity);
    return Padding(
      key: Key('home-brief-item-${item.id}'),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 8),
            child: Icon(tongtaiBriefIcon(item.kind), size: 16, color: color),
          ),
          Expanded(
            child: Text(
              item.headline,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.35,
                color: TtColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hỏng thì nói — im lặng ở đây đọc thành "hôm nay không có gì đáng chú ý".
class _BriefFailed extends StatelessWidget {
  const _BriefFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('home-brief-failed'),
    width: double.infinity,
    padding: const EdgeInsets.all(TtSpace.x3),
    decoration: BoxDecoration(
      color: TtColors.danger.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(TtRadius.md),
      border: Border.all(color: TtColors.danger.withValues(alpha: 0.35)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.error_outline,
          size: 18,
          color: TtColors.dangerOnLight,
        ),
        const SizedBox(width: TtSpace.x2),
        Expanded(
          child: Text(
            // WTM-342 — **hỏng** và **thiếu dữ liệu** là hai trạng thái khác
            // nhau của ADR-TON-017, và câu chữ phải khác nhau. Dùng câu
            // "chưa đủ dữ liệu" cho một lần đọc HỎNG là đổ lỗi cho người bán
            // về một lỗi của máy — và giấu mất thứ duy nhất đáng sửa.
            context.l10n.briefFailedTitle,
            style: const TextStyle(fontSize: 13, color: TtColors.textPrimary),
          ),
        ),
        TextButton(
          key: const Key('home-brief-retry'),
          onPressed: onRetry,
          child: Text(context.l10n.stateRetry),
        ),
      ],
    ),
  );
}
