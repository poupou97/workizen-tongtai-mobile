/// Pure numeric helpers shared by every analytics series (Founder directive
/// "Capability-Driven Predictive Foundation", 2026-07-30).
///
/// Nothing here knows about orders, customers or money — it is the arithmetic
/// the series and the Rule Twins agree on, kept in one place so a mean is a
/// mean everywhere. Every function is total: short/empty input returns a
/// well-formed value (or `null` where the answer is genuinely undefined) and
/// **never** throws.
library;

import 'dart:math' as math;

/// Arithmetic mean; `0` for an empty input (a business with no months has no
/// average, and zero is the value every caller wants to render).
double mean(Iterable<double> values) {
  var sum = 0.0;
  var count = 0;
  for (final value in values) {
    sum += value;
    count += 1;
  }
  return count == 0 ? 0 : sum / count;
}

/// Population standard deviation (divides by N, not N−1).
///
/// The series *is* the population — we are describing the months that happened,
/// not inferring from a sample — so N keeps the value comparable between a
/// 6-month and a 12-month window. `0` for fewer than two values.
double populationStandardDeviation(Iterable<double> values) {
  final list = values.toList(growable: false);
  if (list.length < 2) return 0;
  final average = mean(list);
  var sumSquares = 0.0;
  for (final value in list) {
    final deviation = value - average;
    sumSquares += deviation * deviation;
  }
  return math.sqrt(sumSquares / list.length);
}

/// The [fraction]-quantile (0..1) using linear interpolation between order
/// statistics — the "type 7" definition used by NumPy/R, so a hand-computed
/// expectation in a test matches a spreadsheet.
///
/// Returns `null` for an empty input. [fraction] is clamped to `0..1`.
double? quantile(Iterable<num> values, double fraction) {
  final sorted = values.map((v) => v.toDouble()).toList()..sort();
  if (sorted.isEmpty) return null;
  if (sorted.length == 1) return sorted.first;
  final clamped = fraction.clamp(0.0, 1.0);
  final position = (sorted.length - 1) * clamped;
  final lower = position.floor();
  final upper = position.ceil();
  if (lower == upper) return sorted[lower];
  return sorted[lower] + (position - lower) * (sorted[upper] - sorted[lower]);
}

/// The median — [quantile] at 0.5. `null` for an empty input.
double? median(Iterable<num> values) => quantile(values, 0.5);

/// Least-squares slope of [values] against their index (`x = 0, 1, 2 …`), i.e.
/// the average change **per step** implied by the whole series rather than by
/// its last two points.
///
/// Returns `null` for fewer than two values — a single point has no trend, and
/// `null` lets a twin say "not enough history" instead of claiming "flat".
double? leastSquaresSlope(List<double> values) {
  if (values.length < 2) return null;
  final meanX = (values.length - 1) / 2;
  final meanY = mean(values);
  var covariance = 0.0;
  var varianceX = 0.0;
  for (var i = 0; i < values.length; i++) {
    final deltaX = i - meanX;
    covariance += deltaX * (values[i] - meanY);
    varianceX += deltaX * deltaX;
  }
  if (varianceX == 0) return null;
  return covariance / varianceX;
}

/// Linearly weighted average of [values] given **oldest → newest**: the newest
/// value carries weight `n`, the oldest weight `1`.
///
/// Recency matters more than history for a short-horizon forecast, but a plain
/// "last month" is noise; linear weights are the cheapest defensible middle.
/// `0` for an empty input.
double linearWeightedAverage(List<double> values) {
  if (values.isEmpty) return 0;
  var weightedSum = 0.0;
  var weightTotal = 0.0;
  for (var i = 0; i < values.length; i++) {
    final weight = (i + 1).toDouble();
    weightedSum += weight * values[i];
    weightTotal += weight;
  }
  return weightedSum / weightTotal;
}

/// The last [n] elements of [values] (fewer when the list is shorter), keeping
/// the original oldest → newest order. Empty when [n] is non-positive.
List<T> trailing<T>(List<T> values, int n) {
  if (n <= 0 || values.isEmpty) return const [];
  final take = n < values.length ? n : values.length;
  return values.sublist(values.length - take);
}

/// Fractional change from [previous] to [current], e.g. `0.25` for +25%.
///
/// `null` when [previous] is zero: growth *from nothing* has no percentage, and
/// a fabricated "+∞%" is exactly the kind of nonsense a Rule Twin must not emit.
double? fractionalChange(double previous, double current) {
  if (previous == 0) return null;
  return (current - previous) / previous;
}
