import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../ai/predictive_ai.dart';
import '../../analytics/revenue_series.dart';
import '../../capability/capability_context.dart';
import '../../capability/revenue_capability.dart';
import '../../core/screen_state.dart';
import '../../core/tongtai_formatters.dart';
import '../../predictive/revenue_forecast_rule.dart';
import '../../predictive/rule_twin.dart';
import '../../providers/tongtai_capability_provider.dart';
import '../../providers/tongtai_predictive_provider.dart';
import '../widgets/tongtai_screen_data.dart';

/// **Revenue Forecast screen** (WTM-160 · ADR-TON-016) — "how much will I make
/// next month?", answered by the deterministic [RevenueForecastRule] twin.
///
/// **One data path** (ADR-TON-015): the headline, the band, the confidence and
/// the reasons are read verbatim from the single [revenueForecastProvider]
/// result, and the history/comparison from the single
/// [revenueCapabilityProvider] context the twin itself was computed over. The
/// screen re-computes nothing, rounds nothing beyond display formatting and
/// holds no clock — so the number the seller reads is byte-for-byte the number
/// the rule produced.
///
/// **No fabricated forecast** (ADR-TON-016, Testing Bible P-03): when the twin
/// refuses (`DataSufficiency.insufficient`, `result == null`) there is no
/// headline, no band and no chart of zeros — only the refusal, its reasons, and
/// the real months that do exist, if any. "We cannot tell yet" must never be
/// rendered as "you will earn 0 ₫".
///
/// **AI explains, never replaces** (ADR-TON-016): the number is arithmetic and
/// says so (`forecastRuleBased`). The `forecast-action-ai` button can only ever
/// add prose *about* the twin's output, and it is unavailable exactly when the
/// twin has nothing to explain.
class TongtaiForecastScreen extends ConsumerStatefulWidget {
  const TongtaiForecastScreen({super.key});

  @override
  ConsumerState<TongtaiForecastScreen> createState() =>
      _TongtaiForecastScreenState();
}

class _TongtaiForecastScreenState extends ConsumerState<TongtaiForecastScreen> {
  /// The on-demand Workizen AI explanation of the twin's output (WTM-158),
  /// or null until the seller asks for one. It never carries a number the
  /// screen renders — the headline stays the twin's (ADR-TON-016).
  PredictiveExplanation? _explanation;
  bool _aiRunning = false;

  /// Asks [PredictiveAiService] to explain the forecast **already on screen**.
  ///
  /// The context and the twin are passed in rather than reloaded, so the prose
  /// can only ever describe the numbers the seller is looking at. The service
  /// itself falls back to the deterministic twin explanation when no BYOK key
  /// is set or every provider fails — the button therefore always answers, and
  /// never silently spends the seller's quota on a refusal.
  Future<void> _explain(
    RevenueCapabilityContext revenue,
    RuleTwinResult<RevenueForecast> twin,
  ) async {
    if (_aiRunning) return;
    setState(() => _aiRunning = true);
    final explanation = await ref
        .read(predictiveAiServiceProvider)
        .explainForecast(context: revenue, forecast: twin);
    if (!mounted) return;
    setState(() {
      _explanation = explanation;
      _aiRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final forecast = ref.watch(revenueForecastProvider);
    final revenue = ref.watch(revenueCapabilityProvider);

    return Scaffold(
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        title: Text(l10n.titleForecast),
        elevation: 0,
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
      ),
      body: SafeArea(
        // Through the shared seam (WTM-148): loading, a failed load, a stale
        // read and the twin's own refusal each get their own state. A failed
        // load is NOT "you will earn nothing" — it is "could not compute", and
        // conflating the two is exactly what ADR-TON-016 forbids.
        child: TongtaiAsyncScreenData<RuleTwinResult<RevenueForecast>>(
          prefix: 'forecast',
          async: forecast,
          onRetry: () async => ref.invalidate(revenueForecastProvider),
          insufficiencyOf: (context, twin) => twin.result == null
              ? TongtaiInsufficiency(
                  title: context.l10n.forecastInsufficient,
                  body: context.l10n.forecastInsufficientBody,
                  reasons: [
                    for (final reason in twin.reasonCodes)
                      reason.label(context.l10n.languageCode),
                  ],
                )
              : null,
          // The months that really happened are still worth showing — a refusal
          // means "cannot forecast", not "nothing exists". A window that booked
          // no revenue at all shows no chart: zeros are not a history.
          insufficientExtra: (context, twin) {
            final context0 = revenue.value;
            if (context0 == null || !context0.hasData) return null;
            return _HistorySection(series: context0.series);
          },
          builder: (context, twin) => _body(twin, revenue.value),
        ),
      ),
    );
  }

  Widget _body(
    RuleTwinResult<RevenueForecast> twin,
    RevenueCapabilityContext? revenue,
  ) {
    // Non-null by construction: the seam routes a refusing twin to the shared
    // insufficient state above, so this path only ever renders a real forecast.
    final forecast = twin.result!;

    // The twin was computed over exactly this context, so the history the
    // seller sees is the history the forecast was made from. The fallback keeps
    // the screen truthful (not empty) if the context ever resolves later than
    // the twin: `basis` is the twin's own record of the months it used.
    final series = revenue?.series ?? RevenueSeries(points: forecast.basis);

    return SingleChildScrollView(
      // Not a ListView: the whole page is a fixed 12-month window, and building
      // every history row eagerly is what lets a contract test prove the rows
      // the window counted are the rows the seller can see.
      padding: const EdgeInsets.all(TtSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeadlineCard(twin: twin, forecast: forecast),
          const SizedBox(height: TtSpace.x4),
          _AiExplainAction(
            running: _aiRunning,
            explanation: _explanation,
            // Disabled until the context that backs the twin is in hand: an
            // explanation must be built from the SAME context, never reloaded.
            onExplain: revenue == null ? null : () => _explain(revenue, twin),
          ),
          const SizedBox(height: TtSpace.x6),
          _HistorySection(series: series),
          if (revenue != null) ...[
            const SizedBox(height: TtSpace.x6),
            _ComparisonCard(comparison: revenue.comparison),
          ],
          const SizedBox(height: TtSpace.x6),
          _WhySection(twin: twin, forecast: forecast),
        ],
      ),
    );
  }
}

// ── Direction presentation ──────────────────────────────────────────────────

/// Semantic colour of a trend [direction] — the same verdict the rule reached,
/// so the colour can never contradict the number beside it. `flat` is neutral
/// on purpose: a flat month is not a failure.
Color tongtaiForecastDirectionColor(RevenueTrendDirection direction) =>
    switch (direction) {
      RevenueTrendDirection.growing => TtColors.success,
      RevenueTrendDirection.declining => TtColors.danger,
      RevenueTrendDirection.flat => TtColors.unknown,
    };

IconData tongtaiForecastDirectionIcon(RevenueTrendDirection direction) =>
    switch (direction) {
      RevenueTrendDirection.growing => Icons.trending_up,
      RevenueTrendDirection.declining => Icons.trending_down,
      RevenueTrendDirection.flat => Icons.trending_flat,
    };

// ── Headline: the number, its band, its confidence, its provenance ──────────

class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard({required this.twin, required this.forecast});

  final RuleTwinResult<RevenueForecast> twin;
  final RevenueForecast forecast;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = tongtaiForecastDirectionColor(forecast.direction);
    final target = forecast.targetMonth;
    return Container(
      key: const Key('forecast-headline'),
      padding: const EdgeInsets.all(TtSpace.x4),
      decoration: BoxDecoration(
        color: TtColors.ai.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(TtRadius.md),
        border: Border.all(color: TtColors.ai.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: TtSpace.x2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                tongtaiForecastDirectionIcon(forecast.direction),
                size: 18,
                color: accent,
              ),
              Text(
                l10n.forecastNextMonth,
                style: TtType.body.copyWith(
                  color: TtColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (target != null)
                Text(
                  '${target.month}/${target.year}',
                  style: TtType.caption.copyWith(color: TtColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: TtSpace.x2),
          // The twin's number, formatted — never re-derived, never re-rounded
          // beyond what the money formatter does for display.
          Text(
            TongtaiFormatters.vnd(forecast.nextMonthRevenue),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TtType.h1.copyWith(
              color: TtColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TtSpace.x3),
          // The band travels with the number: a forecast without its range is
          // a promise, and this rule never makes one.
          Row(
            key: const Key('forecast-range'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.unfold_more, size: 16, color: TtColors.textSecondary),
              const SizedBox(width: TtSpace.x2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.forecastRange,
                      style: TtType.caption.copyWith(
                        color: TtColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${TongtaiFormatters.vnd(forecast.lowerBound)} – '
                      '${TongtaiFormatters.vnd(forecast.upperBound)}',
                      style: TtType.body.copyWith(
                        color: TtColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TtSpace.x3),
          Wrap(
            spacing: TtSpace.x2,
            runSpacing: TtSpace.x2,
            children: [
              // Confidence is a coarse, explainable band — shown next to the
              // number so the two are never read apart.
              _Chip(
                chipKey: const Key('forecast-confidence'),
                icon: Icons.speed_outlined,
                label:
                    '${l10n.forecastConfidence}: '
                    '${twin.confidence.label(l10n.languageCode)}',
                tone: TtStatus.neutral,
              ),
              // Provenance: this figure is arithmetic. No AI, no network, no
              // BYOK key was involved in producing it (ADR-TON-016).
              _Chip(
                chipKey: const Key('forecast-provenance'),
                icon: Icons.calculate_outlined,
                label: l10n.forecastRuleBased,
                tone: TtStatus.neutral,
              ),
            ],
          ),
          const SizedBox(height: TtSpace.x3),
          // WTM-280 — câu miễn trừ đi CÙNG con số, trong cùng một thẻ.
          // Đặt ở trang riêng thì người bán đọc nó lúc không nhìn số, tức là
          // không bao giờ đọc đúng lúc.
          Text(
            l10n.estimateDisclaimer,
            key: const Key('forecast-estimate-disclaimer'),
            style: TtType.caption.copyWith(
              color: TtColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ask Workizen AI to explain the twin's output in prose (WTM-158).
///
/// **Never rendered when the twin cannot answer** — the screen leaves this out
/// of the insufficient state entirely, because there would be nothing to
/// explain and the AI paragraph would end up being the only "forecast" on
/// screen (ADR-TON-016).
///
/// The answer is prose *about* the numbers above it. Its provenance chip says
/// which provider spoke — or that the deterministic twin explanation answered,
/// which is what happens with no BYOK key, offline, or on a provider failure.
class _AiExplainAction extends StatelessWidget {
  const _AiExplainAction({
    required this.running,
    required this.explanation,
    required this.onExplain,
  });

  final bool running;
  final PredictiveExplanation? explanation;

  /// `null` disables the button.
  final VoidCallback? onExplain;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (running) {
      return TongtaiInlineBusy(
        key: const Key('forecast-action-ai'),
        label: l10n.aiExplainRunning,
      );
    }
    final answer = explanation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (answer != null) ...[
          _AiExplanationCard(explanation: answer),
          const SizedBox(height: TtSpace.x3),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('forecast-action-ai'),
            onPressed: onExplain,
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: Text(l10n.aiExplain),
          ),
        ),
      ],
    );
  }
}

class _AiExplanationCard extends StatelessWidget {
  const _AiExplanationCard({required this.explanation});

  final PredictiveExplanation explanation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const accent = TtColors.ai;
    // Provenance, always: the seller must be able to tell a provider's prose
    // from the deterministic explanation of the same twin.
    final source = explanation.isAi
        ? (explanation.provider?.displayName ?? 'Workizen AI')
        : l10n.forecastRuleBased;
    return Container(
      key: const Key('forecast-ai-answer'),
      padding: const EdgeInsets.all(TtSpace.x4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(TtRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            source,
            key: const Key('forecast-ai-source'),
            style: TtType.caption.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TtSpace.x2),
          Text(
            explanation.text,
            key: const Key('forecast-ai-text'),
            style: TtType.body.copyWith(
              color: TtColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── History: every month in the window, empties included ────────────────────

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.series});

  final RevenueSeries series;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final points = series.points;
    final peak = points.fold<double>(
      0,
      (max, p) => p.revenue > max ? p.revenue : max,
    );
    return Container(
      key: const Key('forecast-history'),
      padding: const EdgeInsets.all(TtSpace.x4),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.forecastHistory,
            style: TtType.body.copyWith(
              color: TtColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TtSpace.x3),
          SizedBox(
            height: 120,
            child: CustomPaint(
              key: const Key('forecast-chart'),
              size: Size.infinite,
              painter: _MonthlyRevenueBarsPainter(points: points, peak: peak),
            ),
          ),
          const SizedBox(height: TtSpace.x3),
          // One row per month IN THE WINDOW — a month that booked nothing gets
          // its own visible zero row. Skipping it would let a chart close the
          // gap and hide a month the business lost.
          for (final point in points) _HistoryRow(point: point),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.point});

  final MonthlyRevenuePoint point;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // An empty month is shown, and shown as empty: dimmed, with its real zero.
    final color = point.isEmpty ? TtColors.textSecondary : TtColors.textPrimary;
    return Padding(
      key: Key('forecast-item-${point.year}-${point.month}'),
      padding: const EdgeInsets.symmetric(vertical: TtSpace.x1),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              '${point.month}/${point.year}',
              style: TtType.caption.copyWith(color: TtColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              TongtaiFormatters.vndShort(point.revenue),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TtType.caption.copyWith(
                color: color,
                fontWeight: point.isEmpty ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: TtSpace.x2),
          Text(
            l10n.reportsOrdersCount(point.orderCount),
            style: TtType.caption.copyWith(color: TtColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// One bar per month, scaled to the window's peak. Dependency-free by design —
/// Tổng Tài ships no charting package (the app is deliberately lean).
///
/// A zero month is drawn as a visible grey sliver rather than nothing at all:
/// an invisible bar and a missing bar look identical, and only one of them is
/// the truth.
class _MonthlyRevenueBarsPainter extends CustomPainter {
  _MonthlyRevenueBarsPainter({required this.points, required this.peak});

  final List<MonthlyRevenuePoint> points;
  final double peak;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const gap = 6.0;
    const minBarHeight = 3.0;
    final slot = size.width / points.length;
    final barWidth = (slot - gap).clamp(3.0, 32.0);

    final barPaint = Paint()..color = TtColors.ai;
    final zeroPaint = Paint()..color = TtColors.border;
    final baseline = size.height;

    for (var i = 0; i < points.length; i++) {
      final revenue = points[i].revenue;
      final fraction = peak <= 0 ? 0.0 : revenue / peak;
      final barHeight = revenue <= 0
          ? minBarHeight
          : (fraction * (size.height - 4)).clamp(minBarHeight, size.height);
      final left = i * slot + (slot - barWidth) / 2;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(left, baseline - barHeight, left + barWidth, baseline),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        revenue <= 0 ? zeroPaint : barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MonthlyRevenueBarsPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.peak != peak;
}

// ── Comparison: the recent window against the one before it ─────────────────

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.comparison});

  final RevenueWindowComparison comparison;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final code = l10n.languageCode;
    return Container(
      key: const Key('forecast-comparison'),
      padding: const EdgeInsets.all(TtSpace.x4),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.forecastVsPrevious,
            style: TtType.body.copyWith(
              color: TtColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TtSpace.x2),
          // Without both windows the comparison is not "flat" — it is unknown,
          // and it says so instead of printing a −100% collapse that never
          // happened (RevenueWindowComparison.insufficient).
          if (!comparison.hasBothWindows)
            Text(
              ReasonCode.notEnoughHistory.label(code),
              style: TtType.caption.copyWith(color: TtColors.textSecondary),
            )
          else ...[
            Text(
              '${TongtaiFormatters.vndShort(comparison.previousRevenue)} → '
              '${TongtaiFormatters.vndShort(comparison.recentRevenue)}',
              style: TtType.bodyLarge.copyWith(
                color: _deltaColor(comparison.revenueDelta),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: TtSpace.x1),
            Text(
              '${l10n.reportsOrdersCount(comparison.previousOrders)} → '
              '${l10n.reportsOrdersCount(comparison.recentOrders)}',
              style: TtType.caption.copyWith(color: TtColors.textSecondary),
            ),
            // A percentage only when it exists: growth out of a zero month has
            // no percentage, and `+∞%` would be a fabricated fact.
            if (comparison.revenueChange != null) ...[
              const SizedBox(height: TtSpace.x2),
              _Chip(
                chipKey: const Key('forecast-comparison-delta'),
                icon: comparison.revenueDelta >= 0
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                label: capabilityPercent(comparison.revenueChange),
                tone: _deltaTone(comparison.revenueDelta),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Color _deltaColor(double delta) => _deltaTone(delta).color;

  /// ⭐ `delta == 0` là **`neutral`**, không phải `unknown` (WTM-425): bằng
  /// phẳng là một kết quả đã biết, không phải thiếu dữ liệu.
  TtStatus _deltaTone(double delta) => delta > 0
      ? TtStatus.success
      : delta < 0
      ? TtStatus.danger
      : TtStatus.neutral;
}

// ── Why: the reason codes and the months the number came from ───────────────

class _WhySection extends StatelessWidget {
  const _WhySection({required this.twin, required this.forecast});

  final RuleTwinResult<RevenueForecast> twin;
  final RevenueForecast forecast;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      key: const Key('forecast-why'),
      padding: const EdgeInsets.all(TtSpace.x4),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.forecastWhy,
            style: TtType.body.copyWith(
              color: TtColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TtSpace.x2),
          _ReasonCodes(reasonCodes: twin.reasonCodes),
          const SizedBox(height: TtSpace.x3),
          Text(
            l10n.forecastBasis,
            style: TtType.caption.copyWith(
              color: TtColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TtSpace.x1),
          // Exactly the months the rule computed from — leading empty months
          // are absent here because the rule dropped them, and saying so is
          // more honest than implying a longer history than it used.
          Wrap(
            spacing: TtSpace.x2,
            runSpacing: TtSpace.x1,
            children: [
              for (final point in forecast.basis)
                Text(
                  '${point.month}/${point.year}',
                  style: TtType.caption.copyWith(color: TtColors.textSecondary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The twin's reason codes as localized text — the SAME codes the AI
/// explanation layer quotes, so screen and prose can never tell two stories.
class _ReasonCodes extends StatelessWidget {
  const _ReasonCodes({required this.reasonCodes});

  final List<ReasonCode> reasonCodes;

  @override
  Widget build(BuildContext context) {
    final code = context.l10n.languageCode;
    return Wrap(
      spacing: TtSpace.x2,
      runSpacing: TtSpace.x1,
      children: [
        for (final reason in reasonCodes)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: TtSpace.x2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: TtColors.surfaceTertiary,
              borderRadius: BorderRadius.circular(TtRadius.full),
            ),
            child: Text(
              reason.label(code),
              style: TtType.caption.copyWith(color: TtColors.textSecondary),
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.chipKey,
    required this.icon,
    required this.label,
    required this.tone,
  });

  final Key chipKey;
  final IconData icon;
  final String label;

  /// **Vai**, không phải màu (WTM-425). Ba lời gọi: hai nhãn *trung tính* (độ
  /// tin cậy · xuất xứ "số này do quy tắc tính") và một *có phán xét* (mức đổi
  /// tăng/giảm). Trước khi `TtStatus.neutral` tồn tại, hai cái đầu không có vai
  /// nào để nhận nên phải truyền `Color` thô.
  final TtStatus tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: chipKey,
      padding: const EdgeInsets.symmetric(
        horizontal: TtSpace.x3,
        vertical: TtSpace.x1,
      ),
      decoration: BoxDecoration(
        color: TtColors.surfaceTertiary,
        borderRadius: BorderRadius.circular(TtRadius.full),
        border: Border.all(color: TtColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tone.color),
          const SizedBox(width: TtSpace.x2),
          Flexible(
            child: Text(
              label,
              style: TtType.caption.copyWith(
                color: tone.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final BoxDecoration _cardDecoration = BoxDecoration(
  color: TtColors.surfaceSecondary,
  borderRadius: BorderRadius.circular(TtRadius.md),
  border: Border.all(color: TtColors.border),
);
