import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/analytics/month_bucket.dart';
import 'package:tongtai/features/tongtai/analytics/revenue_series.dart';
import 'package:tongtai/features/tongtai/capability/revenue_capability.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_context.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/predictive/revenue_forecast_rule.dart';
import 'package:tongtai/features/tongtai/predictive/rule_twin.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_predictive_provider.dart';

/// WTM-155 — the **Revenue Forecast Rule Twin**, the authoritative
/// deterministic prediction (ADR-TON-016).
///
/// Every expectation below is hand-computed from the fixture and written out in
/// a comment, so a reviewer can defend the number without running the code.
/// The formula under test (`revenue-forecast/1`):
///
/// ```
/// level  = weightedTrailingAverage(3)  over the basis   (weights 1 : 2 : 3)
/// slope  = leastSquaresSlope(basis)                     (đồng per month)
/// base   = level + 0.7 × slope × 5/3                    (5/3 = weight centroid → target)
/// value  = max(0, base × relativeSeasonalFactor?)
/// band   = ± clamp(0.10 + 0.5·volatility + historyPenalty, 0.10, 0.75)
///            × max(value, mean(basis))                  lower floored at 0
/// ```
void main() {
  // A fixed clock. July 2026 is the running month, so a 12-month window is the
  // completed months Jul 2025 … Jun 2026 and the forecast target is Jul 2026.
  final now = DateTime(2026, 7, 15, 9, 30);

  const rule = RevenueForecastRule();

  /// Builds a context straight from monthly revenues (oldest → newest).
  ///
  /// The twin's contract is over the **context**, not over orders — the
  /// orders → context step is already proven by `revenue_capability_test.dart`.
  /// Building the series directly is what lets every fixture below be an
  /// explicit, hand-checkable list of months. (An end-to-end run through the
  /// real repository + provider is asserted separately at the bottom.)
  RevenueCapabilityContext contextOf(
    List<double> revenues, {
    MonthKey start = const MonthKey(2025, 7),
    bool currentMonthExcluded = true,
  }) {
    final points = <MonthlyRevenuePoint>[];
    for (var i = 0; i < revenues.length; i++) {
      final key = start.addMonths(i);
      points.add(
        MonthlyRevenuePoint(
          year: key.year,
          month: key.month,
          revenue: revenues[i],
          orderCount: revenues[i] > 0 ? 1 : 0,
          customerCount: revenues[i] > 0 ? 1 : 0,
        ),
      );
    }
    return RevenueCapabilityContext(
      generatedAt: now,
      series: RevenueSeries(
        points: List.unmodifiable(points),
        currentMonthExcluded: currentMonthExcluded,
      ),
      orderHistory: OrderSummary(
        total: points.where((p) => p.orderCount > 0).length,
        byStatus: {
          OrderStatus.delivered: points.where((p) => p.orderCount > 0).length,
        },
      ),
      windowMonths: revenues.length,
      comparisonMonths: 3,
    );
  }

  // ── 1 · no data at all ────────────────────────────────────────────────────
  group('refuses to answer without history', () {
    test('an empty window: insufficient, null result, confidence none', () {
      final result = rule.forecast(contextOf(const []));

      expect(result.sufficiency, DataSufficiency.insufficient);
      expect(result.result, isNull);
      expect(result.hasAnswer, isFalse);
      expect(result.confidence, ForecastConfidence.none);
      expect(result.reasonCodes, contains(ReasonCode.notEnoughHistory));
      // An empty window observed no months, so it cannot claim they were zero.
      expect(result.reasonCodes, isNot(contains(ReasonCode.noRevenueYet)));
      expect(result.version, 'revenue-forecast/1');
      expect(result.generatedAt, now);
    });

    test('six months that all booked zero: noRevenueYet leads the reasons', () {
      final result = rule.forecast(contextOf(List.filled(6, 0)));

      expect(result.sufficiency, DataSufficiency.insufficient);
      expect(result.result, isNull);
      expect(result.confidence, ForecastConfidence.none);
      // Most significant first: "every month booked nothing" is the specific,
      // actionable diagnosis; "too few months" is the gate that fired.
      expect(result.reasonCodes, [
        ReasonCode.noRevenueYet,
        ReasonCode.notEnoughHistory,
        ReasonCode.partialMonthExcluded,
      ]);
    });

    test(
      'cancelled-only / out-of-window history reads as no revenue',
      () async {
        // Straight through the production seam: the only billable-looking order
        // is cancelled, so the series is all zeros.
        final context = await RevenueCapabilityProvider(
          InMemoryOrderRepository([
            CustomerOrder(
              id: 'o1',
              customerId: 'c1',
              orderNumber: 'DH-1',
              date: DateTime(2026, 6, 10),
              status: OrderStatus.cancelled,
              items: const [
                OrderItem(
                  productName: 'Áo',
                  category: 'Fashion',
                  quantity: 1,
                  unitPrice: 9000000,
                ),
              ],
            ),
          ]),
          clock: () => now,
        ).load();

        final result = rule.forecast(context);
        expect(result.result, isNull);
        expect(result.reasonCodes.first, ReasonCode.noRevenueYet);
      },
    );
  });

  // ── 2 · the boundary ──────────────────────────────────────────────────────
  group('the three-month minimum is a hard boundary', () {
    test('exactly 2 earning months is still a refusal', () {
      final result = rule.forecast(contextOf([5000000, 6000000]));

      expect(result.sufficiency, DataSufficiency.insufficient);
      expect(result.result, isNull);
      expect(result.confidence, ForecastConfidence.none);
      expect(result.reasonCodes, contains(ReasonCode.notEnoughHistory));
      expect(result.reasonCodes, isNot(contains(ReasonCode.noRevenueYet)));
    });

    test('2 earning months inside a longer window is still a refusal — the '
        'signal is months that BOOKED, not months on the calendar', () {
      final result = rule.forecast(contextOf([0, 0, 0, 0, 5000000, 6000000]));

      expect(result.sufficiency, DataSufficiency.insufficient);
      expect(result.result, isNull);
    });

    test('the third earning month unlocks the answer', () {
      final result = rule.forecast(contextOf([5000000, 6000000, 7000000]));

      expect(result.sufficiency, DataSufficiency.partial);
      expect(result.result, isNotNull);
    });
  });

  // ── 3 · three flat months ─────────────────────────────────────────────────
  group('3 flat months of 10M → partial, low, flat, forecast 10M', () {
    late RuleTwinResult<RevenueForecast> result;

    setUp(() => result = rule.forecast(contextOf([10e6, 10e6, 10e6])));

    test('sufficiency partial, confidence low', () {
      expect(result.sufficiency, DataSufficiency.partial);
      expect(result.confidence, ForecastConfidence.low);
      // 3–5 months meets the rule's stated minimum, so `notEnoughHistory` —
      // "fewer months than the minimum" — would be a false statement.
      expect(result.reasonCodes, isNot(contains(ReasonCode.notEnoughHistory)));
    });

    test('forecast is exactly 10M', () {
      // level = (1·10M + 2·10M + 3·10M) / 6 = 10,000,000
      // slope = 0  ⇒  base = 10,000,000 + 0.7 × 0 × 5/3
      expect(result.result!.nextMonthRevenue, closeTo(10e6, 1e-6));
      expect(result.result!.trendPerMonth, closeTo(0, 1e-9));
      expect(result.result!.direction, RevenueTrendDirection.flat);
      expect(result.reasonCodes.first, ReasonCode.revenueFlat);
    });

    test('band = ±25 % — 10 % floor plus the 15 % thin-history penalty, with '
        'volatility measured at exactly 0', () {
      // relativeBand = clamp(0.10 + 0.5×0 + 0.15) = 0.25 · scale = 10M
      expect(result.result!.lowerBound, closeTo(7.5e6, 1e-6));
      expect(result.result!.upperBound, closeTo(12.5e6, 1e-6));
    });

    test('no season is claimed from three months', () {
      expect(result.result!.seasonalMultiplierApplied, isNull);
      expect(
        result.reasonCodes,
        isNot(contains(ReasonCode.seasonalPatternDetected)),
      );
    });

    test('basis is the three months it was computed from', () {
      final basis = result.result!.basis;
      expect(basis.length, 3);
      expect(basis.first.key, const MonthKey(2025, 7));
      expect(basis.last.key, const MonthKey(2025, 9));
      expect(result.result!.targetMonth, const MonthKey(2025, 10));
    });
  });

  // ── 4 · six growing months ────────────────────────────────────────────────
  group('6 growing months 100k…600k → sufficient, medium, growing', () {
    late RuleTwinResult<RevenueForecast> result;

    setUp(
      () => result = rule.forecast(
        contextOf([100e3, 200e3, 300e3, 400e3, 500e3, 600e3]),
      ),
    );

    test('sufficient + medium', () {
      expect(result.sufficiency, DataSufficiency.sufficient);
      expect(result.confidence, ForecastConfidence.medium);
    });

    test('forecast 650,000 — above the last month, and a documented 30 % '
        'haircut on the undamped 700,000', () {
      // level = (1·400k + 2·500k + 3·600k)/6 = 3,200,000/6 = 533,333.333…
      // slope = +100,000/month (a perfect ramp)
      // base  = 533,333.333… + 0.7 × 100,000 × 5/3 = 533,333.333… + 116,666.667
      //       = 650,000
      // (with trendWeight 1.0 this is exactly 700,000 — the true next value —
      //  which is precisely the over-confidence the 0.7 damping removes)
      expect(result.result!.nextMonthRevenue, closeTo(650000, 1e-6));
      expect(result.result!.nextMonthRevenue, greaterThan(600000));
      expect(result.result!.trendPerMonth, closeTo(100000, 1e-6));
      expect(result.result!.trendPerMonth, greaterThan(0));
      expect(result.result!.direction, RevenueTrendDirection.growing);
      expect(result.reasonCodes.first, ReasonCode.revenueGrowing);
    });

    test('the trend is not flattened away', () {
      // A trend-free rule would answer with the bare level, 533,333.33 — below
      // the last month the seller actually booked. The damped blend adds
      // 116,666.67 on top, clearing both the level and the last month.
      expect(result.result!.nextMonthRevenue, greaterThan(533333.34));
      expect(result.result!.nextMonthRevenue, greaterThan(600000));
      expect(
        result.result!.nextMonthRevenue - 533333.333333,
        closeTo(0.7 * 100000 * 5 / 3, 1e-3),
      );
    });

    test('band is symmetric and strictly positive here', () {
      // volatility = 0.6353300772… (dispersion of +100 %, +50 %, +33.3 %, +25 %,
      //   +20 % relative to their 45.67 % mean size)
      // relativeBand = 0.10 + 0.5×0.63533008 + 0.05 (6–11 months) = 0.46766504
      // scale = max(650,000 · mean(basis)=350,000) = 650,000
      // half  = 303,982.2751…
      final forecast = result.result!;
      expect(forecast.lowerBound, closeTo(346017.724883, 1e-3));
      expect(forecast.upperBound, closeTo(953982.275117, 1e-3));
      expect(
        forecast.upperBound - forecast.nextMonthRevenue,
        closeTo(forecast.nextMonthRevenue - forecast.lowerBound, 1e-6),
      );
      expect(forecast.lowerBound, greaterThan(0));
    });

    test('a steady ramp is not called volatile', () {
      expect(result.reasonCodes, isNot(contains(ReasonCode.highVolatility)));
    });
  });

  // ── 5 · six declining months ──────────────────────────────────────────────
  group('6 declining months 600k…100k → declining, floored lower bound', () {
    late RuleTwinResult<RevenueForecast> result;

    setUp(
      () => result = rule.forecast(
        contextOf([600e3, 500e3, 400e3, 300e3, 200e3, 100e3]),
      ),
    );

    test('forecast 50,000 — below the last month', () {
      // level = (1·300k + 2·200k + 3·100k)/6 = 1,000,000/6 = 166,666.667
      // slope = −100,000/month
      // base  = 166,666.667 + 0.7 × (−100,000) × 5/3 = 166,666.667 − 116,666.667
      //       = 50,000
      expect(result.result!.nextMonthRevenue, closeTo(50000, 1e-6));
      expect(result.result!.nextMonthRevenue, lessThan(100000));
      expect(result.result!.trendPerMonth, closeTo(-100000, 1e-6));
      expect(result.result!.direction, RevenueTrendDirection.declining);
      expect(result.reasonCodes.first, ReasonCode.revenueDeclining);
      expect(result.confidence, ForecastConfidence.medium);
    });

    test('lower bound is floored at zero, never negative', () {
      // volatility = 0.41058784…
      // relativeBand = 0.10 + 0.5×0.41058784 + 0.05 = 0.35529392
      // scale = max(50,000 · mean(basis)=350,000) = 350,000  — the band of an
      //   extrapolation is set by the size of the business, not by the
      //   extrapolated point
      // half  = 124,352.872…  ⇒  50,000 − 124,352.872 = −74,352.872 → 0
      expect(result.result!.lowerBound, 0);
      expect(result.result!.upperBound, closeTo(174352.872239, 1e-3));
      expect(result.result!.upperBound, greaterThan(50000));
    });

    test('a cliff never forecasts negative revenue', () {
      // 600k, 500k, 400k, 100k, 50k, 10k — the undamped blend runs to −115,000.
      final cliff = rule.forecast(
        contextOf([600e3, 500e3, 400e3, 100e3, 50e3, 10e3]),
      );
      expect(cliff.result!.nextMonthRevenue, 0);
      expect(cliff.result!.lowerBound, 0);
      expect(cliff.result!.direction, RevenueTrendDirection.declining);
    });

    test('a business that simply stopped selling is not flattered', () {
      // Three good months, then nine months of nothing: the trailing months are
      // real zeros, so the level is 0 and the forecast is 0 — the rule refuses
      // to keep quoting a level the business abandoned.
      final stopped = rule.forecast(
        contextOf([10e6, 10e6, 10e6, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
      );

      expect(stopped.result!.nextMonthRevenue, 0);
      expect(stopped.result!.direction, RevenueTrendDirection.declining);
      // Only 3 months ever booked, so the answer stays partial/low despite the
      // 12-month window.
      expect(stopped.sufficiency, DataSufficiency.partial);
      expect(stopped.confidence, ForecastConfidence.low);
      // Leading zeros would have been trimmed; trailing zeros are kept.
      expect(stopped.result!.basis.length, 12);
      // The band is still scaled by the size the business actually had.
      expect(stopped.result!.upperBound, closeTo(1875000, 1e-6));
    });

    test('leading empty months are trimmed from the basis', () {
      // The business did not trade before its first sale — those months are not
      // bad months, and must not drag the fitted trend.
      final late = rule.forecast(contextOf([0, 0, 0, 100e3, 200e3, 300e3]));
      final direct = rule.forecast(contextOf([100e3, 200e3, 300e3]));

      expect(late.result!.basis.length, 3);
      expect(
        late.result!.nextMonthRevenue,
        closeTo(direct.result!.nextMonthRevenue, 1e-9),
      );
      expect(late.result!.trendPerMonth, closeTo(100000, 1e-6));
    });
  });

  // ── 6 · seasonality ───────────────────────────────────────────────────────
  group('12 months with a strong seasonal shape', () {
    // Window Jul 2025 … Jun 2026, so every calendar month appears once and the
    // forecast target is July 2026.
    //   Jul 2025 = 1.9M (peak) · Aug 2025 = 0.1M (trough) · the other ten = 1.0M
    //   window mean = 12.0M / 12 = 1,000,000
    //   ⇒ index[7] = 1.9 · index[8] = 0.1 · every other month = 1.0
    final peakInJuly = <double>[1.9e6, 0.1e6, ...List.filled(10, 1.0e6)];

    late RuleTwinResult<RevenueForecast> result;

    setUp(() => result = rule.forecast(contextOf(peakInJuly)));

    test('the pattern is detected and reported', () {
      expect(result.reasonCodes, contains(ReasonCode.seasonalPatternDetected));
      expect(result.sufficiency, DataSufficiency.sufficient);
    });

    test('the multiplier applied is the RELATIVE one, 1.9 / 1.0', () {
      // The level came from Apr, May, Jun 2026 — all index 1.0 — so the target
      // month's raw 1.9× is applied undiluted here. Had the level come from
      // peak months, the factor would have been divided down.
      expect(result.result!.seasonalMultiplierApplied, closeTo(1.9, 1e-9));
    });

    test('the multiplier really moves the number, upward for a peak month', () {
      // level = 1,000,000 (Apr/May/Jun 2026 all 1.0M)
      // slope = −900,000/143 = −6,293.7063/month
      // base  = 1,000,000 + 0.7 × (−6,293.7063) × 5/3 = 992,657.3427
      // value = 992,657.3427 × 1.9 = 1,886,048.9510
      const seasonlessBase = 992657.342657342;
      expect(result.result!.nextMonthRevenue, closeTo(1886048.951048, 1e-3));
      expect(result.result!.nextMonthRevenue, greaterThan(seasonlessBase));
      expect(
        result.result!.nextMonthRevenue,
        closeTo(seasonlessBase * 1.9, 1e-3),
      );
      // A peak-month forecast must clear a typical month by a wide margin.
      expect(result.result!.nextMonthRevenue, greaterThan(1.8e6));
    });

    test('a trough target month pulls the forecast DOWN by the same rule', () {
      // Same shape shifted one month: window Aug 2025 … Jul 2026, target
      // Aug 2026, whose index is the 0.1M trough → relative factor 0.1.
      final troughInAugust = rule.forecast(
        contextOf(<double>[
          0.1e6,
          1.9e6,
          ...List.filled(10, 1.0e6),
        ], start: const MonthKey(2025, 8)),
      );

      expect(
        troughInAugust.reasonCodes,
        contains(ReasonCode.seasonalPatternDetected),
      );
      expect(
        troughInAugust.result!.seasonalMultiplierApplied,
        closeTo(0.1, 1e-9),
      );
      // base = 1,000,000 + 0.7 × (+6,293.7063) × 5/3 = 1,007,342.6573
      // value = 1,007,342.6573 × 0.1 = 100,734.2657
      expect(
        troughInAugust.result!.nextMonthRevenue,
        closeTo(100734.265734, 1e-3),
      );
      expect(troughInAugust.result!.nextMonthRevenue, lessThan(1007342.66));
    });

    test('a flat year is not a season', () {
      final flatYear = rule.forecast(contextOf(List.filled(12, 1.0e6)));

      expect(flatYear.result!.seasonalMultiplierApplied, isNull);
      expect(
        flatYear.reasonCodes,
        isNot(contains(ReasonCode.seasonalPatternDetected)),
      );
    });

    test('a TREND is not a season — the guard that stops a growing business '
        'being forecast at a ninth of its recent level', () {
      // 100k…1.2M over twelve months. Because each calendar month appears once,
      // seasonalIndex() reports index[Jul 2025] = 100k/650k = 0.154× — applying
      // that would forecast next July at 9 % of the recent level. The
      // whole-window drift (100,000 × 11 / 650,000 = 1.69) exceeds the 0.5
      // limit, so the seasonal step is refused.
      final ramp = rule.forecast(
        contextOf([for (var i = 1; i <= 12; i++) 100e3 * i]),
      );

      expect(ramp.result!.seasonalMultiplierApplied, isNull);
      expect(
        ramp.reasonCodes,
        isNot(contains(ReasonCode.seasonalPatternDetected)),
      );
      // level = (1·1.0M + 2·1.1M + 3·1.2M)/6 = 1,133,333.333
      // base  = 1,133,333.333 + 0.7 × 100,000 × 5/3 = 1,250,000
      expect(ramp.result!.nextMonthRevenue, closeTo(1250000, 1e-6));
      expect(ramp.result!.direction, RevenueTrendDirection.growing);
      // A full, steady year earns the strongest claim a rule twin makes.
      expect(ramp.confidence, ForecastConfidence.high);
      expect(ramp.sufficiency, DataSufficiency.sufficient);
    });

    test('a zero month makes the multiplicative model undefined, so the '
        'seasonal step is skipped rather than dividing by zero', () {
      final withGap = rule.forecast(
        contextOf([1.9e6, 0, ...List.filled(10, 1.0e6)]),
      );

      expect(withGap.result, isNotNull);
      expect(withGap.result!.seasonalMultiplierApplied, isNull);
      expect(withGap.result!.nextMonthRevenue.isFinite, isTrue);
    });
  });

  // ── 7 · volatility ────────────────────────────────────────────────────────
  group('a wildly volatile history is downgraded and says so', () {
    late RuleTwinResult<RevenueForecast> result;

    // 1M · 100k · 3M · 200k · 2M · 150k — a business with no rhythm at all.
    setUp(
      () => result = rule.forecast(
        contextOf([1e6, 100e3, 3e6, 200e3, 2e6, 150e3]),
      ),
    );

    test('highVolatility is reported and confidence drops medium → low', () {
      // volatility = 1.4266 ≥ the 1.0 threshold RevenueSeries itself documents
      // as "wild swings".
      expect(result.reasonCodes, contains(ReasonCode.highVolatility));
      expect(result.sufficiency, DataSufficiency.sufficient); // 6 months
      expect(result.confidence, ForecastConfidence.low); // not medium
    });

    test('a full year of the same chaos is downgraded high → medium', () {
      final year = rule.forecast(
        contextOf([
          1e6, 100e3, 3e6, 200e3, 2e6, 150e3, //
          1e6, 100e3, 3e6, 200e3, 2e6, 150e3,
        ]),
      );

      expect(year.reasonCodes, contains(ReasonCode.highVolatility));
      expect(year.confidence, ForecastConfidence.medium); // not high
    });

    test('the noise band refuses to call a direction on a whipsawing '
        'business', () {
      // slope = −38,571.43/month over a 1,075,000 average month = −3.6 %,
      // inside the volatility-widened noise band of 0.02 + 0.05×1.4266 = 9.1 %.
      expect(result.result!.direction, RevenueTrendDirection.flat);
      expect(result.reasonCodes.first, ReasonCode.revenueFlat);
    });

    test('the band widens to its 75 % cap and floors the lower bound', () {
      // level = (1·200k + 2·2M + 3·150k)/6 = 775,000
      // base  = 775,000 + 0.7 × (−38,571.43) × 5/3 = 730,000
      // relativeBand = 0.10 + 0.5×1.4266 + 0.05 = 0.863 → clamped to 0.75
      // scale = max(730,000 · mean(basis)=1,075,000) = 1,075,000
      // half  = 806,250  ⇒  730,000 − 806,250 < 0 → 0
      expect(result.result!.nextMonthRevenue, closeTo(730000, 1e-6));
      expect(result.result!.lowerBound, 0);
      expect(result.result!.upperBound, closeTo(1536250, 1e-6));
    });

    test('an alternating 100k/200k business is NOT called volatile — the '
        'threshold matches the metric\'s own documented scale', () {
      // The analytics-proven 100·200·100·200 shape scores 0.9186 here, under
      // the 1.0 line. Firing highVolatility below that would also fire it on a
      // business that merely wobbles ±5 %, which is not volatile at all.
      final alternating = rule.forecast(
        contextOf([100e3, 200e3, 100e3, 200e3, 100e3, 200e3]),
      );

      expect(
        alternating.reasonCodes,
        isNot(contains(ReasonCode.highVolatility)),
      );
      expect(alternating.confidence, ForecastConfidence.medium);
      expect(alternating.result!.direction, RevenueTrendDirection.flat);
    });
  });

  // ── 8 · the partial-month caveat ──────────────────────────────────────────
  group('partialMonthExcluded mirrors the context', () {
    test('present, and last, when the running month was excluded', () {
      final result = rule.forecast(contextOf([10e6, 10e6, 10e6]));

      expect(result.reasonCodes, contains(ReasonCode.partialMonthExcluded));
      // Least significant caveat → last.
      expect(result.reasonCodes.last, ReasonCode.partialMonthExcluded);
    });

    test('absent when the running month was included', () {
      final result = rule.forecast(
        contextOf([10e6, 10e6, 10e6], currentMonthExcluded: false),
      );

      expect(
        result.reasonCodes,
        isNot(contains(ReasonCode.partialMonthExcluded)),
      );
    });

    test('stated even on a refusal — the caveat is about the input', () {
      final result = rule.forecast(contextOf(const [0, 0, 0]));

      expect(result.result, isNull);
      expect(result.reasonCodes, contains(ReasonCode.partialMonthExcluded));
    });

    test('the real provider excludes the running month, so the code fires '
        'end to end', () async {
      var id = 0;
      CustomerOrder order(DateTime date, double total) => CustomerOrder(
        id: 'o${id++}',
        customerId: 'c1',
        orderNumber: 'DH-$id',
        date: date,
        status: OrderStatus.delivered,
        items: [
          OrderItem(
            productName: 'Áo',
            category: 'Fashion',
            quantity: 1,
            unitPrice: total,
          ),
        ],
      );

      final context = await RevenueCapabilityProvider(
        InMemoryOrderRepository([
          order(DateTime(2026, 4, 10), 100000),
          order(DateTime(2026, 5, 10), 200000),
          order(DateTime(2026, 6, 10), 300000),
          order(DateTime(2026, 7, 2), 9000000), // running month — must be out
        ]),
        clock: () => now,
        windowMonths: 6,
      ).load();

      final result = rule.forecast(context);
      expect(result.reasonCodes, contains(ReasonCode.partialMonthExcluded));
      // level = (1·100k + 2·200k + 3·300k)/6 = 233,333.333
      // slope = +100,000  ⇒  233,333.333 + 116,666.667 = 350,000
      expect(result.result!.nextMonthRevenue, closeTo(350000, 1e-6));
      expect(result.result!.basis.last.key, const MonthKey(2026, 6));
      expect(result.result!.targetMonth, const MonthKey(2026, 7));
    });
  });

  // ── 9 · determinism ───────────────────────────────────────────────────────
  group('determinism — no clock, no randomness', () {
    test('the same context yields an identical result twice', () {
      final context = contextOf([100e3, 250e3, 180e3, 400e3, 320e3, 610e3]);
      final first = rule.forecast(context);
      final second = rule.forecast(context);

      expect(first.result, second.result); // value equality
      expect(first.result!.nextMonthRevenue, second.result!.nextMonthRevenue);
      expect(first.result!.lowerBound, second.result!.lowerBound);
      expect(first.result!.upperBound, second.result!.upperBound);
      expect(first.confidence, second.confidence);
      expect(first.sufficiency, second.sufficiency);
      expect(first.reasonCodes, second.reasonCodes);
      expect(first.generatedAt, second.generatedAt);
      expect(first.provenance, second.provenance);
      expect(first.result.hashCode, second.result.hashCode);
    });

    test('two equal contexts built independently agree', () {
      final a = rule.forecast(contextOf([100e3, 250e3, 180e3]));
      final b = rule.forecast(contextOf([100e3, 250e3, 180e3]));

      expect(a.result, b.result);
    });

    test('generatedAt is the context clock, never DateTime.now()', () {
      final result = rule.forecast(contextOf([10e6, 10e6, 10e6]));
      expect(result.generatedAt, now);
    });

    test('a different last month moves the target month', () {
      final result = rule.forecast(
        contextOf([10e6, 10e6, 10e6], start: const MonthKey(2026, 10)),
      );
      // Oct, Nov, Dec 2026 → the target rolls over the year.
      expect(result.result!.targetMonth, const MonthKey(2027, 1));
    });
  });

  // ── 10 · the envelope contract ────────────────────────────────────────────
  group('the RuleTwinResult contract holds for every shape', () {
    final fixtures = <String, List<double>>{
      'empty': const [],
      'all zero': const [0, 0, 0, 0],
      'one month': const [1e6],
      'two months': const [1e6, 2e6],
      'three flat': const [10e6, 10e6, 10e6],
      'gap then revenue': const [0, 0, 5e6, 6e6, 7e6],
      'six growing': const [100e3, 200e3, 300e3, 400e3, 500e3, 600e3],
      'six declining': const [600e3, 500e3, 400e3, 300e3, 200e3, 100e3],
      'wild': const [1e6, 100e3, 3e6, 200e3, 2e6, 150e3],
      'seasonal': const [
        1.9e6, 0.1e6, 1e6, 1e6, 1e6, 1e6, //
        1e6, 1e6, 1e6, 1e6, 1e6, 1e6,
      ],
      'stopped': const [10e6, 10e6, 10e6, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'single spike': const [0, 0, 0, 0, 0, 50e6],
    };

    for (final entry in fixtures.entries) {
      test('${entry.key}: null result ⟺ insufficient, and never empty '
          'reasons', () {
        final result = rule.forecast(contextOf(entry.value));

        expect(
          result.result == null,
          result.sufficiency == DataSufficiency.insufficient,
          reason: 'insufficient MUST carry a null result, and vice versa',
        );
        if (result.sufficiency == DataSufficiency.insufficient) {
          expect(result.confidence, ForecastConfidence.none);
        } else {
          expect(result.confidence, isNot(ForecastConfidence.none));
        }
        expect(result.reasonCodes, isNotEmpty);
        expect(result.version, 'revenue-forecast/1');
        expect(result.generatedAt, now);
      });

      test('${entry.key}: an answer is always finite, non-negative and '
          'inside its own band', () {
        final forecast = rule.forecast(contextOf(entry.value)).result;
        if (forecast == null) return;

        expect(forecast.nextMonthRevenue.isFinite, isTrue);
        expect(forecast.nextMonthRevenue, greaterThanOrEqualTo(0));
        expect(forecast.lowerBound, greaterThanOrEqualTo(0));
        expect(forecast.lowerBound, lessThanOrEqualTo(forecast.upperBound));
        expect(
          forecast.nextMonthRevenue,
          inInclusiveRange(forecast.lowerBound, forecast.upperBound),
        );
        expect(forecast.basis, isNotEmpty);
        expect(forecast.basis.first.revenue, greaterThan(0));
      });

      test('${entry.key}: the verdict always leads the reason codes', () {
        final result = rule.forecast(contextOf(entry.value));
        const verdicts = {
          ReasonCode.revenueGrowing,
          ReasonCode.revenueDeclining,
          ReasonCode.revenueFlat,
        };

        if (result.hasAnswer) {
          expect(result.reasonCodes.first, result.result!.direction.reasonCode);
          expect(
            result.reasonCodes.where(verdicts.contains).length,
            1,
            reason: 'exactly one direction may be claimed',
          );
        } else {
          expect(result.reasonCodes.any(verdicts.contains), isFalse);
          expect(result.reasonCodes, contains(ReasonCode.notEnoughHistory));
        }
      });

      test('${entry.key}: provenance leaks no money and no identity', () {
        final result = rule.forecast(contextOf(entry.value));
        // Only codes and bands travel to the AI prompt / telemetry.
        expect(result.provenance, contains('revenue-forecast/1'));
        expect(result.provenance, isNot(contains('₫')));
        expect(result.provenance, isNot(contains('000')));
      });
    }

    test('the envelope assert is live, not vacuous: a hand-built inconsistent '
        'result throws', () {
      expect(
        () => RuleTwinResult<RevenueForecast>(
          result: null,
          confidence: ForecastConfidence.high,
          sufficiency: DataSufficiency.sufficient,
          reasonCodes: const [ReasonCode.revenueGrowing],
          version: RevenueForecastRule.version,
          generatedAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => RuleTwinResult<RevenueForecast>(
          result: null,
          confidence: ForecastConfidence.low,
          sufficiency: DataSufficiency.insufficient,
          reasonCodes: const [ReasonCode.notEnoughHistory],
          version: RevenueForecastRule.version,
          generatedAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  // ── production wiring ─────────────────────────────────────────────────────
  group('revenueForecastProvider (production wiring, no AI/network/key)', () {
    ProviderContainer containerWith(List<CustomerOrder> orders) {
      final container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(
            InMemoryOrderRepository(orders),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    CustomerOrder order(String id, DateTime date, double total) =>
        CustomerOrder(
          id: id,
          customerId: 'c1',
          orderNumber: 'DH-$id',
          date: date,
          status: OrderStatus.delivered,
          items: [
            OrderItem(
              productName: 'Áo',
              category: 'Fashion',
              quantity: 1,
              unitPrice: total,
            ),
          ],
        );

    test('an empty repository resolves to an honest refusal', () async {
      final container = containerWith(const []);
      final result = await container.read(revenueForecastProvider.future);

      expect(result.result, isNull);
      expect(result.sufficiency, DataSufficiency.insufficient);
      expect(result.confidence, ForecastConfidence.none);
      expect(result.reasonCodes, contains(ReasonCode.notEnoughHistory));
    });

    test('real orders resolve to a real forecast', () async {
      // The provider uses the wall clock, so the fixture is anchored to
      // *completed* months relative to now — three ascending months ending with
      // last month.
      final today = DateTime.now();
      final lastMonth = MonthKey.of(today).addMonths(-1);
      final container = containerWith([
        for (var back = 2; back >= 0; back--)
          order(
            'o$back',
            DateTime(
              lastMonth.addMonths(-back).year,
              lastMonth.addMonths(-back).month,
              15,
            ),
            100000 * (3 - back).toDouble(),
          ),
      ]);

      final result = await container.read(revenueForecastProvider.future);

      expect(result.hasAnswer, isTrue);
      expect(result.result!.basis.length, greaterThanOrEqualTo(3));
      // 100k · 200k · 300k ⇒ level 233,333.33 + 0.7×100,000×5/3 = 350,000
      expect(result.result!.nextMonthRevenue, closeTo(350000, 1e-6));
      expect(result.result!.direction, RevenueTrendDirection.growing);
      expect(result.result!.targetMonth, MonthKey.of(today));
      expect(result.version, RevenueForecastRule.version);
    });
  });
}
