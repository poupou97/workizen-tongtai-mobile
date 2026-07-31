import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../ai/predictive_ai.dart';
import '../../analytics/revenue_series.dart';
import '../../capability/capability_context.dart';
import '../../capability/revenue_capability.dart';
import '../../core/tongtai_formatters.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../predictive/revenue_forecast_rule.dart';
import '../../predictive/rule_twin.dart';
import '../../providers/tongtai_capability_provider.dart';
import '../../providers/tongtai_predictive_provider.dart';

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
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(l10n.titleForecast),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
      ),
      body: SafeArea(
        child: forecast.when(
          loading: () => const Center(
            key: Key('forecast-loading'),
            child: CircularProgressIndicator(),
          ),
          // A failed load is NOT "you will earn nothing" — it is "could not
          // compute", and renders as the same honest refusal with no reasons
          // to quote and no history to show.
          error: (error, stack) =>
              const _ForecastInsufficient(reasonCodes: <ReasonCode>[]),
          data: (twin) => _body(twin, revenue.value),
        ),
      ),
    );
  }

  Widget _body(
    RuleTwinResult<RevenueForecast> twin,
    RevenueCapabilityContext? revenue,
  ) {
    final forecast = twin.result;
    if (forecast == null) {
      return _ForecastInsufficient(
        reasonCodes: twin.reasonCodes,
        // The months that really happened are still worth showing — a refusal
        // means "cannot forecast", not "nothing exists". A window that booked
        // no revenue at all shows no chart: zeros are not a history.
        series: revenue != null && revenue.hasData ? revenue.series : null,
      );
    }

    // The twin was computed over exactly this context, so the history the
    // seller sees is the history the forecast was made from. The fallback keeps
    // the screen truthful (not empty) if the context ever resolves later than
    // the twin: `basis` is the twin's own record of the months it used.
    final series = revenue?.series ?? RevenueSeries(points: forecast.basis);

    return SingleChildScrollView(
      // Not a ListView: the whole page is a fixed 12-month window, and building
      // every history row eagerly is what lets a contract test prove the rows
      // the window counted are the rows the seller can see.
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeadlineCard(twin: twin, forecast: forecast),
          const SizedBox(height: TongtaiDesignTokens.spacing4),
          _AiExplainAction(
            running: _aiRunning,
            explanation: _explanation,
            // Disabled until the context that backs the twin is in hand: an
            // explanation must be built from the SAME context, never reloaded.
            onExplain: revenue == null ? null : () => _explain(revenue, twin),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing6),
          _HistorySection(series: series),
          if (revenue != null) ...[
            const SizedBox(height: TongtaiDesignTokens.spacing6),
            _ComparisonCard(comparison: revenue.comparison),
          ],
          const SizedBox(height: TongtaiDesignTokens.spacing6),
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
      RevenueTrendDirection.growing => TongtaiDesignTokens.success,
      RevenueTrendDirection.declining => TongtaiDesignTokens.error,
      RevenueTrendDirection.flat => TongtaiDesignTokens.neutral,
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
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      decoration: BoxDecoration(
        color: TongtaiDesignTokens.financePurple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.cardBorderRadius,
        ),
        border: Border.all(
          color: TongtaiDesignTokens.financePurple.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: TongtaiDesignTokens.spacing2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                tongtaiForecastDirectionIcon(forecast.direction),
                size: 18,
                color: accent,
              ),
              Text(
                l10n.forecastNextMonth,
                style: TongtaiDesignTokens.smallStyle.copyWith(
                  color: TongtaiDesignTokens.lightTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (target != null)
                Text(
                  '${target.month}/${target.year}',
                  style: TongtaiDesignTokens.captionStyle.copyWith(
                    color: TongtaiDesignTokens.lightTextSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          // The twin's number, formatted — never re-derived, never re-rounded
          // beyond what the money formatter does for display.
          Text(
            TongtaiFormatters.vnd(forecast.nextMonthRevenue),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TongtaiDesignTokens.heading2Style.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          // The band travels with the number: a forecast without its range is
          // a promise, and this rule never makes one.
          Row(
            key: const Key('forecast-range'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.unfold_more,
                size: 16,
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
              const SizedBox(width: TongtaiDesignTokens.spacing2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.forecastRange,
                      style: TongtaiDesignTokens.captionStyle.copyWith(
                        color: TongtaiDesignTokens.lightTextSecondary,
                      ),
                    ),
                    Text(
                      '${TongtaiFormatters.vnd(forecast.lowerBound)} – '
                      '${TongtaiFormatters.vnd(forecast.upperBound)}',
                      style: TongtaiDesignTokens.smallStyle.copyWith(
                        color: TongtaiDesignTokens.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          Wrap(
            spacing: TongtaiDesignTokens.spacing2,
            runSpacing: TongtaiDesignTokens.spacing2,
            children: [
              // Confidence is a coarse, explainable band — shown next to the
              // number so the two are never read apart.
              _Chip(
                chipKey: const Key('forecast-confidence'),
                icon: Icons.speed_outlined,
                label:
                    '${l10n.forecastConfidence}: '
                    '${twin.confidence.label(l10n.languageCode)}',
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
              // Provenance: this figure is arithmetic. No AI, no network, no
              // BYOK key was involved in producing it (ADR-TON-016).
              _Chip(
                chipKey: const Key('forecast-provenance'),
                icon: Icons.calculate_outlined,
                label: l10n.forecastRuleBased,
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ],
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
      return Row(
        key: const Key('forecast-action-ai'),
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: TongtaiDesignTokens.spacing2),
          Expanded(
            child: Text(
              l10n.aiExplainRunning,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          ),
        ],
      );
    }
    final answer = explanation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (answer != null) ...[
          _AiExplanationCard(explanation: answer),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
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
    const accent = TongtaiDesignTokens.copilotViolet;
    // Provenance, always: the seller must be able to tell a provider's prose
    // from the deterministic explanation of the same twin.
    final source = explanation.isAi
        ? (explanation.provider?.displayName ?? 'Workizen AI')
        : l10n.forecastRuleBased;
    return Container(
      key: const Key('forecast-ai-answer'),
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.cardBorderRadius,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            source,
            key: const Key('forecast-ai-source'),
            style: TongtaiDesignTokens.captionStyle.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          Text(
            explanation.text,
            key: const Key('forecast-ai-text'),
            style: TongtaiDesignTokens.smallStyle.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
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
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.forecastHistory,
            style: TongtaiDesignTokens.smallStyle.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          SizedBox(
            height: 120,
            child: CustomPaint(
              key: const Key('forecast-chart'),
              size: Size.infinite,
              painter: _MonthlyRevenueBarsPainter(points: points, peak: peak),
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
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
    final color = point.isEmpty
        ? TongtaiDesignTokens.lightTextSecondary
        : TongtaiDesignTokens.lightTextPrimary;
    return Padding(
      key: Key('forecast-item-${point.year}-${point.month}'),
      padding: const EdgeInsets.symmetric(
        vertical: TongtaiDesignTokens.spacing1,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              '${point.month}/${point.year}',
              style: TongtaiDesignTokens.captionStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              TongtaiFormatters.vndShort(point.revenue),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TongtaiDesignTokens.captionStyle.copyWith(
                color: color,
                fontWeight: point.isEmpty ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: TongtaiDesignTokens.spacing2),
          Text(
            l10n.reportsOrdersCount(point.orderCount),
            style: TongtaiDesignTokens.captionStyle.copyWith(
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
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

    final barPaint = Paint()..color = TongtaiDesignTokens.financePurple;
    final zeroPaint = Paint()..color = TongtaiDesignTokens.lightBorder;
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
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.forecastVsPrevious,
            style: TongtaiDesignTokens.smallStyle.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          // Without both windows the comparison is not "flat" — it is unknown,
          // and it says so instead of printing a −100% collapse that never
          // happened (RevenueWindowComparison.insufficient).
          if (!comparison.hasBothWindows)
            Text(
              ReasonCode.notEnoughHistory.label(code),
              style: TongtaiDesignTokens.captionStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            )
          else ...[
            Text(
              '${TongtaiFormatters.vndShort(comparison.previousRevenue)} → '
              '${TongtaiFormatters.vndShort(comparison.recentRevenue)}',
              style: TongtaiDesignTokens.bodyStyle.copyWith(
                color: _deltaColor(comparison.revenueDelta),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing1),
            Text(
              '${l10n.reportsOrdersCount(comparison.previousOrders)} → '
              '${l10n.reportsOrdersCount(comparison.recentOrders)}',
              style: TongtaiDesignTokens.captionStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
            // A percentage only when it exists: growth out of a zero month has
            // no percentage, and `+∞%` would be a fabricated fact.
            if (comparison.revenueChange != null) ...[
              const SizedBox(height: TongtaiDesignTokens.spacing2),
              _Chip(
                chipKey: const Key('forecast-comparison-delta'),
                icon: comparison.revenueDelta >= 0
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                label: capabilityPercent(comparison.revenueChange),
                color: _deltaColor(comparison.revenueDelta),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Color _deltaColor(double delta) => delta > 0
      ? TongtaiDesignTokens.success
      : delta < 0
      ? TongtaiDesignTokens.error
      : TongtaiDesignTokens.neutral;
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
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.forecastWhy,
            style: TongtaiDesignTokens.smallStyle.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          _ReasonCodes(reasonCodes: twin.reasonCodes),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          Text(
            l10n.forecastBasis,
            style: TongtaiDesignTokens.captionStyle.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing1),
          // Exactly the months the rule computed from — leading empty months
          // are absent here because the rule dropped them, and saying so is
          // more honest than implying a longer history than it used.
          Wrap(
            spacing: TongtaiDesignTokens.spacing2,
            runSpacing: TongtaiDesignTokens.spacing1,
            children: [
              for (final point in forecast.basis)
                Text(
                  '${point.month}/${point.year}',
                  style: TongtaiDesignTokens.captionStyle.copyWith(
                    color: TongtaiDesignTokens.lightTextSecondary,
                  ),
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
      spacing: TongtaiDesignTokens.spacing2,
      runSpacing: TongtaiDesignTokens.spacing1,
      children: [
        for (final reason in reasonCodes)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: TongtaiDesignTokens.spacing2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: TongtaiDesignTokens.lightHover,
              borderRadius: BorderRadius.circular(
                TongtaiDesignTokens.radiusFull,
              ),
            ),
            child: Text(
              reason.label(code),
              style: TongtaiDesignTokens.captionStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
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
    required this.color,
  });

  final Key chipKey;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: chipKey,
      padding: const EdgeInsets.symmetric(
        horizontal: TongtaiDesignTokens.spacing3,
        vertical: TongtaiDesignTokens.spacing1,
      ),
      decoration: BoxDecoration(
        color: TongtaiDesignTokens.lightHover,
        borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusFull),
        border: Border.all(color: TongtaiDesignTokens.lightBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: TongtaiDesignTokens.spacing2),
          Flexible(
            child: Text(
              label,
              style: TongtaiDesignTokens.captionStyle.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── The honest non-answer ───────────────────────────────────────────────────

/// The twin refused to forecast: say so, say WHY, and show no number.
///
/// Rendering a zero headline or a chart of zeros here is the exact failure
/// ADR-TON-016 forbids — a fabricated forecast that reads as "you will earn
/// nothing" when the truth is "we cannot tell yet".
class _ForecastInsufficient extends StatelessWidget {
  const _ForecastInsufficient({required this.reasonCodes, this.series});

  final List<ReasonCode> reasonCodes;

  /// Real months to show under the refusal, or `null` when the window booked
  /// nothing at all — a chart of zeros is not a history.
  final RevenueSeries? series;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final history = series;
    return SingleChildScrollView(
      key: const Key('forecast-insufficient'),
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.help_outline,
            size: 48,
            color: TongtaiDesignTokens.warning,
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          Text(
            l10n.forecastInsufficient,
            textAlign: TextAlign.center,
            style: TongtaiDesignTokens.bodyStyle.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing1),
          Text(
            l10n.forecastInsufficientBody,
            textAlign: TextAlign.center,
            style: TongtaiDesignTokens.smallStyle.copyWith(
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
          if (reasonCodes.isNotEmpty) ...[
            const SizedBox(height: TongtaiDesignTokens.spacing3),
            _ReasonCodes(reasonCodes: reasonCodes),
          ],
          if (history != null) ...[
            const SizedBox(height: TongtaiDesignTokens.spacing6),
            _HistorySection(series: history),
          ],
        ],
      ),
    );
  }
}

final BoxDecoration _cardDecoration = BoxDecoration(
  color: TongtaiDesignTokens.lightBackground,
  borderRadius: BorderRadius.circular(TongtaiDesignTokens.cardBorderRadius),
  border: Border.all(color: TongtaiDesignTokens.lightBorder),
);
