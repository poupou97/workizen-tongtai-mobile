import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../analytics/month_bucket.dart';
import '../analytics/revenue_series.dart';
import '../analytics/series_math.dart';
import '../capability/revenue_capability.dart';
import 'rule_twin.dart';

/// Which way the business is moving, once month-to-month noise is discounted.
///
/// "Flat" is a real, useful verdict — most SME months are flat, and calling a
/// random wobble a trend is exactly the fabrication a Rule Twin must not commit.
enum RevenueTrendDirection {
  growing,
  declining,
  flat;

  /// The [ReasonCode] this direction is reported as, so the UI and the AI both
  /// quote the same code the rule decided on.
  ReasonCode get reasonCode => switch (this) {
    RevenueTrendDirection.growing => ReasonCode.revenueGrowing,
    RevenueTrendDirection.declining => ReasonCode.revenueDeclining,
    RevenueTrendDirection.flat => ReasonCode.revenueFlat,
  };
}

/// The deterministic revenue forecast for the **next** calendar month, i.e. the
/// month after [basis]'s last point.
///
/// Carried inside a [RuleTwinResult], never on its own: the number is only
/// meaningful next to the confidence, sufficiency and reason codes that qualify
/// it.
@immutable
class RevenueForecast {
  const RevenueForecast({
    required this.nextMonthRevenue,
    required this.lowerBound,
    required this.upperBound,
    required this.trendPerMonth,
    required this.direction,
    required this.seasonalMultiplierApplied,
    required this.basis,
  });

  /// The headline number, in đồng. Never negative — a month cannot book
  /// negative revenue, so a trend line that runs below zero is reported as
  /// zero, not as a nonsense figure.
  final double nextMonthRevenue;

  /// Honest band around [nextMonthRevenue], in đồng, widened by volatility and
  /// by how little history the rule had. [lowerBound] is floored at zero.
  final double lowerBound;
  final double upperBound;

  /// Least-squares slope over [basis], in **đồng per month**. Positive =
  /// growing. This is the raw slope, *before* the damping applied to the
  /// forecast, so a reader can see the trend the rule actually measured.
  final double trendPerMonth;

  /// The slope's verdict once compared against a volatility-derived noise band.
  final RevenueTrendDirection direction;

  /// The seasonal factor actually multiplied into the forecast, or `null` when
  /// no usable yearly shape existed.
  ///
  /// This is the **relative** factor — the target month's seasonal index
  /// divided by the average index of the months the base was computed from —
  /// not the raw index entry. The base already carries the seasonality of its
  /// own months; multiplying by the raw entry would count the season twice.
  final double? seasonalMultiplierApplied;

  /// The months the forecast was computed from, oldest → newest.
  ///
  /// This is the analysis window trimmed of its **leading** empty months: a
  /// month before the first sale is not a bad month, it is a month in which
  /// this business did not yet trade. Interior and trailing zeros are kept —
  /// a business that stopped selling must not be flattered.
  final List<MonthlyRevenuePoint> basis;

  /// The last completed month the forecast was built on, or `null` if [basis]
  /// were somehow empty (the rule never produces that).
  MonthlyRevenuePoint? get lastObservedMonth =>
      basis.isEmpty ? null : basis.last;

  /// The calendar month being forecast — the month after [lastObservedMonth].
  MonthKey? get targetMonth =>
      basis.isEmpty ? null : basis.last.key.addMonths(1);

  /// Half the width of the band, in đồng, as computed before the zero floor.
  double get bandWidth => upperBound - lowerBound;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RevenueForecast &&
          other.nextMonthRevenue == nextMonthRevenue &&
          other.lowerBound == lowerBound &&
          other.upperBound == upperBound &&
          other.trendPerMonth == trendPerMonth &&
          other.direction == direction &&
          other.seasonalMultiplierApplied == seasonalMultiplierApplied &&
          listEquals(other.basis, basis));

  @override
  int get hashCode => Object.hash(
    nextMonthRevenue,
    lowerBound,
    upperBound,
    trendPerMonth,
    direction,
    seasonalMultiplierApplied,
    Object.hashAll(basis),
  );

  @override
  String toString() =>
      'RevenueForecast(${targetMonth ?? '?'}: $nextMonthRevenue '
      '[$lowerBound … $upperBound], ${direction.name}, '
      'slope: $trendPerMonth/mo, seasonal: $seasonalMultiplierApplied, '
      'basis: ${basis.length} months)';
}

/// **Revenue Forecast Rule Twin** (WTM-155, ADR-TON-016) — the *authoritative*
/// deterministic answer to "how much will I make next month?".
///
/// No AI, no network, no BYOK key: it is a pure function of
/// [RevenueCapabilityContext], and the context already carries the clock
/// ([RevenueCapabilityContext.generatedAt]), so this class never reads one.
/// Same context in → byte-identical result out, forever.
///
/// All arithmetic is delegated to `analytics/` (`series_math.dart`,
/// [RevenueSeries]); nothing statistical is re-implemented here (One Data Path,
/// ADR-TON-015). What lives here is *judgement*: how the pieces are combined,
/// when the rule refuses to answer, and how much it trusts itself.
///
/// ## The formula (`revenue-forecast/1`)
///
/// Let `basis` be the analysis window trimmed of leading empty months, `n` its
/// length and `T` the month after its last point.
///
/// 1. **Level** — `level = weightedTrailingAverage(3)` over `basis`: the last
///    three completed months weighted `1 : 2 : 3`, newest heaviest. Three
///    months because one month is noise and six is stale; linear weights
///    because recency matters more than history but not infinitely more.
/// 2. **Trend** — `slope = leastSquaresSlope(basis)`, đồng per month, fitted
///    over the whole basis rather than the last two points so a single freak
///    month cannot become "the trend".
/// 3. **Blend (damped trend)** — the weighted average of step 1 sits at the
///    centroid of its own weights, i.e. `2/3` of a month *before* the last
///    observed month. The target month is one month *after* it, so the trend
///    must be carried `1 + 2/3 = 5/3` months:
///
///    ```
///    base = level + 0.7 × slope × 5/3
///    ```
///
///    The `0.7` is the blend: **70 % trend, 30 % recent level**. With a full
///    `1.0` this expression reproduces a perfect linear ramp exactly (100k…600k
///    ⇒ 700k), which is precisely the over-confidence to avoid — a slope fitted
///    to a handful of SME months carries real estimation error. Dropping to
///    `0.7` costs a clear ramp only a 30 % haircut (100k…600k ⇒ 650k, still far
///    above the last month), so a real trend is *not* flattened away, while a
///    steep slope is pulled back toward where the business actually is.
/// 4. **Season** — when a usable yearly shape exists (see
///    [RevenueSeries.seasonalIndex] and the four guards on
///    `_relativeSeasonalMultiplier`) the base is multiplied by
///    `index[T] / mean(index[m] for the three months of step 1)`. The base
///    already carries the seasonality of the months it came from, so the
///    *relative* factor is applied, never the raw index entry. The guards
///    refuse the step for a flat year, for an undefined (zero) factor, and —
///    critically — for a year the linear trend explains, because a 12-point
///    index cannot separate a season from a trend.
/// 5. **Floor** — `nextMonthRevenue = max(0, …)`. Revenue cannot be negative.
/// 6. **Band** — `± relativeBand × max(nextMonthRevenue, mean(basis))` where
///
///    ```
///    relativeBand = clamp(0.10 + 0.5 × volatility + historyPenalty, 0.10, 0.75)
///    historyPenalty = 0.15 (3–5 months) · 0.05 (6–11) · 0 (≥ 12)
///    ```
///
///    Both reasons a forecast can be wrong are priced in: the business swings
///    (volatility) and we have seen too little of it (history). The scale is
///    the *larger* of the forecast and the average month of the basis — a
///    forecast that has run far below where the business has actually been is
///    an extrapolation, and its uncertainty is set by the size of the business,
///    not by the extrapolated point. `lowerBound` is then floored at zero.
/// 7. **Direction** — the slope becomes a verdict only outside a noise band:
///
///    ```
///    relativeSlope = slope / mean(basis)
///    noise = clamp(0.02 + 0.05 × volatility, 0.02, 0.10)
///    ```
///
///    i.e. a movement of at least 2 % of an average month per month, more when
///    the business is erratic, capped at 10 % so a wild business can still be
///    called growing when it genuinely doubles.
///
/// ## Sufficiency & confidence
///
/// The single signal is [RevenueCapabilityContext.monthsWithRevenue] — months
/// that actually **booked** something, not months on the calendar.
///
/// | months with revenue | sufficiency | confidence |
/// |---|---|---|
/// | `< 3` | `insufficient` (result `null`) | `none` |
/// | `3–5` | `partial` | `low` |
/// | `6–11` | `sufficient` | `medium`, `low` if volatile |
/// | `≥ 12` | `sufficient` | `high`, `medium` if volatile |
///
/// Three months is the minimum because the level itself averages three months;
/// with two, the "trend" is a single line through two points and the band would
/// be a guess dressed as a range.
class RevenueForecastRule {
  const RevenueForecastRule();

  /// Formula version — bump on **any** change to the maths above, because
  /// consumers cache and compare forecasts across app versions.
  static const String version = 'revenue-forecast/1';

  /// Months averaged into the level (step 1).
  static const int trailingMonths = 3;

  /// Minimum months **with revenue** before the rule will answer at all.
  static const int minMonthsOfRevenue = 3;

  /// From here the answer is `sufficient` rather than `partial`.
  static const int mediumConfidenceMonths = 6;

  /// From here the rule will claim `high` confidence (a full year).
  static const int highConfidenceMonths = 12;

  /// Weight of the trend in the blend (step 3); `1 − trendWeight` is the weight
  /// of the flat recent level.
  static const double trendWeight = 0.7;

  /// Measured [RevenueSeries.volatility] at or above this is "wild".
  ///
  /// Taken straight from that metric's **own** documented scale — "`0` = a
  /// perfectly steady rhythm … `≈ 1` and above = wild swings — the input for
  /// `highVolatility`" — rather than invented here. It is deliberately not
  /// lower: the metric is the dispersion of month-over-month *changes* relative
  /// to their own average size, so a rock-steady business that merely wobbles
  /// ± 5 % up and down already scores `≈ 1.0`. Anything below this threshold
  /// would fire the code on businesses that are not volatile at all.
  static const double highVolatilityThreshold = 1.0;

  /// Band floor: even a perfectly steady business gets ± 10 %. A forecast is
  /// not a promise.
  static const double baseBandFraction = 0.10;

  /// How hard measured volatility widens the band.
  static const double volatilityBandWeight = 0.5;

  /// Extra band for a `partial` (3–5 month) history.
  static const double thinHistoryBandFraction = 0.15;

  /// Extra band for a 6–11 month history.
  static const double shortHistoryBandFraction = 0.05;

  /// Beyond ± 75 % the band stops informing anyone, so it is clamped there.
  static const double maxBandFraction = 0.75;

  /// Slope smaller than this share of an average month per month is noise.
  static const double flatNoiseFraction = 0.02;

  /// How hard volatility widens the flat/noise band.
  static const double noiseVolatilityWeight = 0.05;

  /// The noise band never eats more than 10 % of an average month per month —
  /// otherwise a volatile business could never be called growing.
  static const double maxFlatNoiseFraction = 0.10;

  /// Peak-to-trough spread the seasonal index must show before the rule will
  /// call it a season. Twelve near-identical months are not a yearly rhythm,
  /// and relabelling noise as seasonality is a fabricated conclusion.
  static const double minSeasonalAmplitude = 0.25;

  /// How far the linear trend may have carried the business across the whole
  /// basis — as a share of an average month — before the seasonal index is
  /// refused as untrustworthy.
  ///
  /// **This guard is load-bearing.** With exactly 12 points every calendar
  /// month appears once, so [RevenueSeries.seasonalIndex] is the normalised
  /// series itself and cannot tell a *season* from a *trend*. A business that
  /// simply grew 100k → 1.2M over the year produces an "index" of `0.15×` for
  /// its first month; applying that to next month would forecast a thriving
  /// business at a ninth of its recent level. Requiring the whole-window drift
  /// to stay under half an average month keeps the seasonal step to the case it
  /// is actually valid for: a business that returns to roughly where it began.
  static const double maxSeasonalTrendDrift = 0.5;

  /// Computes the forecast, or an honest refusal, from [ctx].
  ///
  /// Pure and total: never throws, never reads a clock, never touches a
  /// repository. `generatedAt` is copied from [ctx] so the whole chain shares
  /// one instant.
  RuleTwinResult<RevenueForecast> forecast(RevenueCapabilityContext ctx) {
    final generatedAt = ctx.generatedAt;
    final monthsWithRevenue = ctx.monthsWithRevenue;

    // ── Refusal gate ────────────────────────────────────────────────────────
    // Below the minimum the rule produces nothing at all: `insufficient` with a
    // null result, so "we do not know" can never be rendered as a number.
    if (monthsWithRevenue < minMonthsOfRevenue) {
      return RuleTwinResult<RevenueForecast>.insufficient(
        reasonCodes: <ReasonCode>[
          // Most specific first: "months happened and every one booked zero"
          // is a different, more actionable fact than "too few months".
          // An *empty* window has observed no months at all, so it cannot
          // claim that.
          if (ctx.series.isNotEmpty && monthsWithRevenue == 0)
            ReasonCode.noRevenueYet,
          ReasonCode.notEnoughHistory,
          if (ctx.currentMonthExcluded) ReasonCode.partialMonthExcluded,
        ],
        version: version,
        generatedAt: generatedAt,
      );
    }

    // ── Basis ───────────────────────────────────────────────────────────────
    // Drop the leading months in which nothing was ever sold; keep every month
    // from the first sale onward, zeros included. `indexWhere` cannot return
    // -1 here — monthsWithRevenue >= 3 guarantees an earning month exists.
    final points = ctx.series.points;
    final firstEarningMonth = points.indexWhere((point) => point.revenue > 0);
    final basis = List<MonthlyRevenuePoint>.unmodifiable(
      points.sublist(firstEarningMonth),
    );
    final basisRevenues = [for (final point in basis) point.revenue];
    final basisMean = mean(basisRevenues);

    // The last `trailingMonths` months of the basis. Because `basis` is a
    // suffix of the series and is at least `minMonthsOfRevenue` long, this is
    // the same slice `RevenueSeries.weightedTrailingAverage` averages — the
    // level below therefore reuses the series' own helper rather than
    // re-deriving it.
    final trailingPoints = trailing(basis, trailingMonths);
    final level = ctx.series.weightedTrailingAverage(trailingMonths);

    // ── Trend, damped and carried to the target month ───────────────────────
    final slope = leastSquaresSlope(basisRevenues) ?? 0;
    final horizon = 1 - _weightedCentreOffset(trailingPoints.length);
    final trendedBase = level + trendWeight * slope * horizon;

    // ── Season ──────────────────────────────────────────────────────────────
    final seasonalMultiplier = _relativeSeasonalMultiplier(
      ctx,
      trailingPoints: trailingPoints,
      basisLength: basis.length,
      basisMean: basisMean,
      slope: slope,
    );
    final seasonalBase = seasonalMultiplier == null
        ? trendedBase
        : trendedBase * seasonalMultiplier;

    // Revenue cannot be negative; a trend line that runs below zero means
    // "we expect nothing", not "we expect minus two million".
    final nextMonthRevenue = math.max(0.0, seasonalBase);

    // ── Volatility ──────────────────────────────────────────────────────────
    // A *measured* volatility at or above the threshold is evidence of an
    // unstable business. An **unmeasurable** one (fewer than two usable
    // month-over-month changes) is not evidence of anything, so it neither
    // raises `highVolatility` nor downgrades confidence — but it must not be
    // read as calm either, so the band and the noise band both price it as if
    // it were at the threshold.
    final measuredVolatility = ctx.volatility;
    final isHighlyVolatile =
        measuredVolatility != null &&
        measuredVolatility >= highVolatilityThreshold;
    final effectiveVolatility = measuredVolatility ?? highVolatilityThreshold;

    // ── Band ────────────────────────────────────────────────────────────────
    final historyPenalty = monthsWithRevenue >= highConfidenceMonths
        ? 0.0
        : monthsWithRevenue >= mediumConfidenceMonths
        ? shortHistoryBandFraction
        : thinHistoryBandFraction;
    final relativeBand =
        (baseBandFraction +
                volatilityBandWeight * effectiveVolatility +
                historyPenalty)
            .clamp(baseBandFraction, maxBandFraction);
    final bandScale = math.max(nextMonthRevenue, basisMean);
    final halfWidth = bandScale * relativeBand;

    // ── Direction ───────────────────────────────────────────────────────────
    final noiseBand =
        (flatNoiseFraction + noiseVolatilityWeight * effectiveVolatility).clamp(
          flatNoiseFraction,
          maxFlatNoiseFraction,
        );
    final relativeSlope = basisMean <= 0 ? 0.0 : slope / basisMean;
    final direction = relativeSlope > noiseBand
        ? RevenueTrendDirection.growing
        : relativeSlope < -noiseBand
        ? RevenueTrendDirection.declining
        : RevenueTrendDirection.flat;

    // ── Sufficiency + confidence ────────────────────────────────────────────
    final DataSufficiency sufficiency;
    final ForecastConfidence confidence;
    if (monthsWithRevenue >= highConfidenceMonths) {
      sufficiency = DataSufficiency.sufficient;
      confidence = isHighlyVolatile
          ? ForecastConfidence.medium
          : ForecastConfidence.high;
    } else if (monthsWithRevenue >= mediumConfidenceMonths) {
      sufficiency = DataSufficiency.sufficient;
      confidence = isHighlyVolatile
          ? ForecastConfidence.low
          : ForecastConfidence.medium;
    } else {
      // 3–5 months: answerable, but the caller must surface the caveat.
      // `notEnoughHistory` is deliberately NOT reported here — the rule's
      // stated minimum *is* met; the caveat is `partial` + `low`.
      sufficiency = DataSufficiency.partial;
      confidence = ForecastConfidence.low;
    }

    // Ordered most-significant first: the verdict, then the caveat that most
    // weakens it, then how the number was shaped, then the input caveat.
    final reasonCodes = <ReasonCode>[
      direction.reasonCode,
      if (isHighlyVolatile) ReasonCode.highVolatility,
      if (seasonalMultiplier != null) ReasonCode.seasonalPatternDetected,
      if (ctx.currentMonthExcluded) ReasonCode.partialMonthExcluded,
    ];

    return RuleTwinResult<RevenueForecast>(
      result: RevenueForecast(
        nextMonthRevenue: nextMonthRevenue,
        lowerBound: math.max(0.0, nextMonthRevenue - halfWidth),
        upperBound: nextMonthRevenue + halfWidth,
        trendPerMonth: slope,
        direction: direction,
        seasonalMultiplierApplied: seasonalMultiplier,
        basis: basis,
      ),
      confidence: confidence,
      sufficiency: sufficiency,
      reasonCodes: reasonCodes,
      version: version,
      generatedAt: generatedAt,
    );
  }

  /// Where the linear weights `1 … n` sit, in months relative to the **newest**
  /// month of the trailing slice (which is offset `0`, the oldest `−(n−1)`).
  ///
  /// For `n = 3` this is `(1·(−2) + 2·(−1) + 3·0) / 6 = −2/3`: the weighted
  /// average describes the business two thirds of a month before the last
  /// observed month, which is why the trend has to be carried `5/3` months to
  /// reach the target. Getting this exactly right is what makes the undamped
  /// blend reproduce a perfect linear ramp.
  static double _weightedCentreOffset(int n) {
    if (n <= 0) return 0;
    var weighted = 0.0;
    var total = 0.0;
    for (var i = 0; i < n; i++) {
      final weight = (i + 1).toDouble();
      weighted += weight * (i - (n - 1));
      total += weight;
    }
    return weighted / total;
  }

  /// The seasonal factor to apply, or `null` when no yearly shape may honestly
  /// be claimed.
  ///
  /// Every guard exists to stop a fabricated season:
  ///
  /// - the index itself is `null` below 12 months (RevenueSeries' own rule);
  /// - a **non-positive** factor makes the multiplicative model undefined — a
  ///   calendar month that booked nothing means the business had no sales, not
  ///   that the season is worth zero — so the whole step is skipped;
  /// - a peak-to-trough spread below [minSeasonalAmplitude] is a flat year, and
  ///   calling it seasonal would dress noise up as a rhythm;
  /// - a whole-window drift beyond [maxSeasonalTrendDrift] means the shape is a
  ///   **trend**, not a season, and a 12-point index cannot tell them apart;
  /// - the target month must actually appear in the index.
  ///
  /// The returned factor is **relative**: `index[target]` divided by the mean
  /// index of the months the level came from, so the seasonality already baked
  /// into the level is divided back out before the target month's is applied.
  ///
  /// Known limitation, stated plainly: with exactly 12 points every calendar
  /// month appears once, so the index is a *same-month-last-year* shape rather
  /// than a fitted seasonal component. It is therefore used only as this light
  /// multiplier on a trend-blended base — never to de-seasonalise the series,
  /// which at 12 points would flatten it to a constant and destroy the trend.
  static double? _relativeSeasonalMultiplier(
    RevenueCapabilityContext ctx, {
    required List<MonthlyRevenuePoint> trailingPoints,
    required int basisLength,
    required double basisMean,
    required double slope,
  }) {
    final index = ctx.seasonalIndex;
    if (index == null || index.length < 12) return null;
    if (index.values.any((factor) => factor <= 0)) return null;

    final spread =
        index.values.reduce(math.max) - index.values.reduce(math.min);
    if (spread < minSeasonalAmplitude) return null;

    // Trend, not season: how far the fitted line carried the business from one
    // end of the basis to the other, as a share of an average month.
    if (basisMean <= 0) return null;
    final drift = (slope.abs() * (basisLength - 1)) / basisMean;
    if (drift >= maxSeasonalTrendDrift) return null;

    final latest = ctx.latestMonth;
    if (latest == null || trailingPoints.isEmpty) return null;
    final targetFactor = index[latest.key.addMonths(1).month];
    if (targetFactor == null) return null;

    final baseFactors = <double>[];
    for (final point in trailingPoints) {
      final factor = index[point.month];
      if (factor == null) return null;
      baseFactors.add(factor);
    }
    final baseFactor = mean(baseFactors);
    if (baseFactor <= 0) return null;

    return targetFactor / baseFactor;
  }
}
