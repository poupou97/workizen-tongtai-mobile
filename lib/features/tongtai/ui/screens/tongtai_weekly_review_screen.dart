import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../core/screen_state.dart';
import '../../core/tongtai_formatters.dart';
import '../../predictive/rule_twin.dart';
import '../../predictive/weekly_review_rule.dart';
import '../../providers/tongtai_predictive_provider.dart';
import '../widgets/tongtai_screen_data.dart';

/// **Màn Tổng kết tuần** — WTM-377 (Epic WTM-179 · ADR-TON-016/017).
///
/// ## Ba trạng thái, và không có trạng thái thứ tư
///
/// | Twin trả về | Màn hiện |
/// |---|---|
/// | `insufficient` | [TtInsufficientData] — **xám**, nói rõ thiếu gì |
/// | tuần rồi **trống** | số thật `0` + xu hướng giảm |
/// | tuần rồi có bán | số + so sánh + hàng bán chạy |
///
/// Hàng giữa là hàng dễ làm sai nhất. *"Tuần rồi không bán được gì"* là một
/// **câu trả lời**, và trộn nó vào ô xám *"chưa xét được"* sẽ giấu đúng tin
/// người bán cần nghe nhất (Testing Bible P-03).
///
/// ## Màn không tính lại gì
///
/// Doanh thu · số đơn · số khách · trung bình mỗi đơn · phần trăm so tuần trước
/// · hàng bán chạy — **tất cả** đọc thẳng từ một [WeeklyReview] duy nhất. Màn
/// không cộng lại một con số nào, không giữ đồng hồ, không làm tròn ngoài việc
/// định dạng (ADR-TON-015 One Data Path).
///
/// ## Không có tuần trước thì KHÔNG vẽ 0 %
///
/// `revenueChange == null` nghĩa là *không so được*, khác hẳn *không đổi*. Vẽ
/// 0 % ở đó là bịa ra một phép so sánh không tồn tại — nên chỗ ấy hiện đúng câu
/// "chưa có tuần trước để so", và `deltaStatus` để `null` nên chênh lệch hiện
/// **xám** chứ không xanh (UNKNOWN ≠ SUCCESS).
class TongtaiWeeklyReviewScreen extends ConsumerWidget {
  const TongtaiWeeklyReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        title: Text(l10n.titleWeeklyReview),
        elevation: 0,
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
      ),
      body: SafeArea(
        // Qua seam dùng chung (ADR-TON-017): loading · lỗi đọc · dữ liệu cũ ·
        // twin từ chối — bốn thứ khác nhau, bốn trạng thái khác nhau. Lỗi đọc
        // KHÔNG phải "tuần rồi bán được 0".
        child: TongtaiAsyncScreenData<RuleTwinResult<WeeklyReview>>(
          prefix: 'weekly-review',
          async: ref.watch(weeklyReviewProvider),
          onRetry: () async => ref.invalidate(weeklyReviewProvider),
          insufficiencyOf: (context, twin) => twin.result == null
              ? TongtaiInsufficiency(
                  title: context.l10n.weeklyReviewInsufficient,
                  body: context.l10n.weeklyReviewInsufficientBody,
                  reasons: [
                    for (final reason in twin.reasonCodes)
                      reason.label(context.l10n.languageCode),
                  ],
                )
              : null,
          builder: (context, twin) => _Body(review: twin.result!, twin: twin),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.review, required this.twin});

  final WeeklyReview review;
  final RuleTwinResult<WeeklyReview> twin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      key: const Key('weekly-review-list'),
      padding: const EdgeInsets.all(TtSpace.screenH),
      children: [
        Text(
          l10n.weeklyReviewSubtitle,
          style: TtType.body.copyWith(color: TtColors.textSecondary),
        ),
        const SizedBox(height: TtSpace.x2),
        Text(
          '${l10n.weeklyReviewRange} '
          '${TongtaiFormatters.isoDate(review.week.week.monday)} → '
          '${TongtaiFormatters.isoDate(review.week.week.sunday)}',
          key: const Key('weekly-review-range'),
          style: TtType.label.copyWith(color: TtColors.textTertiary),
        ),
        const SizedBox(height: TtSpace.x4),

        // ⭐ Tuần trống vẫn là một CÂU TRẢ LỜI, không phải ô xám "chưa xét
        // được". Nó nói thẳng con số 0 là thật.
        if (review.week.isEmpty) ...[
          TtStatusCard(
            key: const Key('weekly-review-nothing-sold'),
            status: TtStatus.warning,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.weeklyReviewNothingSold, style: TtType.title),
                const SizedBox(height: TtSpace.x1),
                Text(
                  l10n.weeklyReviewNothingSoldBody,
                  style: TtType.body.copyWith(color: TtColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: TtSpace.x4),
        ],

        _Numbers(review: review),
        const SizedBox(height: TtSpace.x4),

        if (review.week.topProduct case final top?) ...[
          TtCard(
            key: const Key('weekly-review-top-product'),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  size: 20,
                  color: TtColors.brandOnDark,
                ),
                const SizedBox(width: TtSpace.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.weeklyReviewTopProduct, style: TtType.caption),
                      Text(top.name, style: TtType.title),
                    ],
                  ),
                ),
                Text(
                  TongtaiFormatters.vndShort(top.revenue),
                  style: TtType.title,
                ),
              ],
            ),
          ),
          const SizedBox(height: TtSpace.x4),
        ],

        TtSectionHeader(title: l10n.weeklyReviewHistory),
        const SizedBox(height: TtSpace.x2),
        _History(review: review),
        const SizedBox(height: TtSpace.x4),

        _Why(twin: twin),
        const SizedBox(height: TtSpace.x3),
        Text(
          l10n.estimateDisclaimer,
          style: TtType.caption.copyWith(color: TtColors.textTertiary),
        ),
      ],
    );
  }
}

class _Numbers extends StatelessWidget {
  const _Numbers({required this.review});

  final WeeklyReview review;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final week = review.week;
    return TtMetricRow(
      key: const Key('weekly-review-metrics'),
      metrics: [
        TtMetric(
          label: l10n.weeklyReviewRevenue,
          value: TongtaiFormatters.vndShort(week.revenue),
          delta: _deltaLabel(context, review.revenueChange),
          deltaStatus: _deltaStatus(review.revenueChange),
          large: true,
        ),
        TtMetric(
          label: l10n.weeklyReviewOrders,
          value: '${week.orderCount}',
          delta: _deltaLabel(context, review.ordersChange),
          deltaStatus: _deltaStatus(review.ordersChange),
        ),
        TtMetric(
          label: l10n.weeklyReviewCustomers,
          value: '${week.customerCount}',
        ),
        TtMetric(
          label: l10n.weeklyReviewAov,
          value: TongtaiFormatters.vndShort(week.averageOrderValue),
        ),
      ],
    );
  }

  /// `null` ⇒ câu *"chưa có tuần trước để so"*, **không** phải "0 %".
  static String? _deltaLabel(BuildContext context, double? change) {
    if (change == null) return context.l10n.weeklyReviewNoPrevious;
    final percent = (change * 100).round();
    final sign = percent > 0 ? '+' : '';
    return '$sign$percent% ${context.l10n.weeklyReviewVsPrevious}';
  }

  /// Chưa biết chiều ⇒ `null` ⇒ [TtMetric] hiện **xám**. Một con số không so
  /// được không phải một tin tốt (UNKNOWN ≠ SUCCESS).
  static TtStatus? _deltaStatus(double? change) => switch (change) {
    null => null,
    > 0 => TtStatus.success,
    < 0 => TtStatus.danger,
    _ => TtStatus.unknown,
  };
}

/// Bốn tuần gần nhất — tuần trống là một **thanh rỗng nhìn thấy được**, không
/// phải một dòng biến mất.
class _History extends StatelessWidget {
  const _History({required this.review});

  final WeeklyReview review;

  @override
  Widget build(BuildContext context) {
    final peak = review.history
        .map((p) => p.revenue)
        .fold<double>(0, (a, b) => a > b ? a : b);
    return TtCard(
      key: const Key('weekly-review-history'),
      child: Column(
        children: [
          for (final point in review.history) ...[
            Row(
              key: Key('weekly-review-week-${point.week}'),
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    TongtaiFormatters.isoDate(point.week.monday).substring(5),
                    style: TtType.caption,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(TtRadius.full),
                    child: LinearProgressIndicator(
                      value: peak == 0 ? 0 : point.revenue / peak,
                      minHeight: 8,
                      backgroundColor: TtColors.surfaceTertiary,
                      valueColor: AlwaysStoppedAnimation(
                        point.week == review.week.week
                            ? TtColors.brandOnDark
                            : TtColors.borderStrong,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: TtSpace.x3),
                Text(
                  TongtaiFormatters.vndShort(point.revenue),
                  style: TtType.caption,
                ),
              ],
            ),
            const SizedBox(height: TtSpace.x3),
          ],
        ],
      ),
    );
  }
}

/// Lý do, nguyên văn từ twin. Màn không diễn giải lại — chữ hiện ở đây là chữ
/// AI sẽ trích khi lớp giải thích được bật (ADR-TON-016).
class _Why extends StatelessWidget {
  const _Why({required this.twin});

  final RuleTwinResult<WeeklyReview> twin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TtCard(
      key: const Key('weekly-review-why'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(l10n.weeklyReviewWhy, style: TtType.title)),
              TtStatusBadge(
                label: l10n.forecastRuleBased,
                status: TtStatus.unknown,
              ),
            ],
          ),
          const SizedBox(height: TtSpace.x2),
          for (final reason in twin.reasonCodes)
            Padding(
              padding: const EdgeInsets.only(bottom: TtSpace.x1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.circle,
                    size: 6,
                    color: TtColors.textTertiary,
                  ),
                  const SizedBox(width: TtSpace.x2),
                  Expanded(
                    child: Text(
                      reason.label(l10n.languageCode),
                      style: TtType.body.copyWith(
                        color: TtColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
