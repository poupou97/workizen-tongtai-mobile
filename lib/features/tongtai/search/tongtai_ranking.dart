/// Search-result ranking & relevance engine for Tổng Tài search (WTM-74).
///
/// The FTS5 service (WTM-72) hands back rows in `bm25` relevance order — a good
/// baseline, but it only knows *text*. This engine re-scores that baseline with
/// the extra signals a sourcing catalogue cares about, so the best supplier /
/// product surfaces first:
///
/// * **Text match quality** (WTM-74 AC1) — an exact-name hit outranks a prefix
///   hit, which outranks a mid-word "contains", which outranks a loose fuzzy
///   token match. Diacritic-/đ-folded so it lines up with the FTS index.
/// * **Ratings & reviews** (AC2) — a higher supplier rating lifts a result, and
///   (when review volume is known) a rating backed by more reviews is trusted
///   more than a lone 5★ with no reviews.
/// * **Recency** (AC3) — newly added or updated items get a half-life decay
///   boost, so fresh catalogue entries are not buried under stale ones.
/// * **Personalization** (AC4) — a favourited supplier, or an item that matches
///   the user's own past searches, is nudged up. Purely on-device (no profile
///   ever leaves the phone — Privacy by Default).
/// * **A/B framework** (AC5) — the weight of each signal above is a named
///   [TongtaiRankingVariant]; [TongtaiRankingExperiment] assigns a *sticky*
///   variant per user by a deterministic hash, so a given install always sees
///   the same algorithm and variants can be compared locally.
///
/// Everything here is pure Dart (no Flutter, no Drift) so every signal and the
/// end-to-end ordering are directly unit-testable.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'tongtai_search_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Text folding (shared by every text-based signal)
// ─────────────────────────────────────────────────────────────────────────────

/// The Vietnamese diacritic letters grouped by the base letter they fold to.
///
/// `unicode61 remove_diacritics 2` (the FTS tokenizer, see `tongtai_fts_schema`)
/// folds these at index/query time, so the ranker folds them the same way to
/// keep text-match classification consistent with what actually matched. đ/Đ is
/// a stroked letter unicode61 does *not* fold, so it is listed explicitly.
const Map<String, String> _viDiacriticGroups = {
  'a': 'àáảãạăằắẳẵặâầấẩẫậ',
  'e': 'èéẻẽẹêềếểễệ',
  'i': 'ìíỉĩị',
  'o': 'òóỏõọôồốổỗộơờớởỡợ',
  'u': 'ùúủũụưừứửữự',
  'y': 'ỳýỷỹỵ',
  'd': 'đ',
};

/// Char→base-letter lookup, built once from [_viDiacriticGroups].
final Map<int, String> _viFold = _buildViFold();

Map<int, String> _buildViFold() {
  final map = <int, String>{};
  _viDiacriticGroups.forEach((base, accented) {
    for (final rune in accented.runes) {
      map[rune] = base;
    }
  });
  return map;
}

/// Lower-cases, folds Vietnamese diacritics (incl. đ→d) and collapses runs of
/// whitespace to a single space, so two strings can be compared the same way the
/// FTS index compared them. `'  Cà  Phê Đắk '` → `'ca phe dak'`.
String foldTongtaiRankText(String input) {
  final lower = input.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    buffer.write(_viFold[rune] ?? String.fromCharCode(rune));
  }
  return buffer.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

// ─────────────────────────────────────────────────────────────────────────────
// AC1 — text match quality
// ─────────────────────────────────────────────────────────────────────────────

/// How well a query matches a candidate's text, best → worst (WTM-74 AC1).
///
/// The [score] each class maps to is the AC1 signal fed into the weighted rank.
enum TongtaiMatchQuality {
  /// The whole text equals the query (diacritic-folded).
  exact,

  /// The text starts with the query.
  prefix,

  /// A word within the text starts with the query.
  wordPrefix,

  /// The query appears somewhere inside the text.
  contains,

  /// Every query token prefixes some word (multi-word AND, FTS-style), or the
  /// query is a subsequence of the text — a loose "fuzzy" match.
  fuzzy,

  /// No relationship between query and text.
  none;

  /// The [0,1] relevance weight of this match class.
  double get score => switch (this) {
        TongtaiMatchQuality.exact => 1.0,
        TongtaiMatchQuality.prefix => 0.85,
        TongtaiMatchQuality.wordPrefix => 0.7,
        TongtaiMatchQuality.contains => 0.55,
        TongtaiMatchQuality.fuzzy => 0.35,
        TongtaiMatchQuality.none => 0.0,
      };
}

/// Classifies how [query] matches [text] (both diacritic-folded first).
///
/// A blank query or blank text is [TongtaiMatchQuality.none]. The checks run
/// strongest-first and return on the first hit, so the result is the *best*
/// applicable class.
TongtaiMatchQuality classifyTongtaiMatch(String query, String text) {
  final q = foldTongtaiRankText(query);
  final t = foldTongtaiRankText(text);
  if (q.isEmpty || t.isEmpty) return TongtaiMatchQuality.none;

  if (t == q) return TongtaiMatchQuality.exact;
  if (t.startsWith(q)) return TongtaiMatchQuality.prefix;

  final words = t.split(' ');
  if (words.any((w) => w.startsWith(q))) return TongtaiMatchQuality.wordPrefix;
  if (t.contains(q)) return TongtaiMatchQuality.contains;

  // Fuzzy 1: every query token prefixes some text word (order-independent AND).
  final qTokens = q.split(' ').where((s) => s.isNotEmpty).toList();
  if (qTokens.length > 1 &&
      qTokens.every((qt) => words.any((w) => w.startsWith(qt)))) {
    return TongtaiMatchQuality.fuzzy;
  }
  // Fuzzy 2: the query's letters appear in order within the text.
  if (_isSubsequence(q.replaceAll(' ', ''), t.replaceAll(' ', ''))) {
    return TongtaiMatchQuality.fuzzy;
  }
  return TongtaiMatchQuality.none;
}

/// The AC1 signal in [0,1] — a convenience wrapper over [classifyTongtaiMatch].
double tongtaiTextMatchScore(String query, String text) =>
    classifyTongtaiMatch(query, text).score;

/// Whether every char of [needle] appears in [haystack] in order (not
/// necessarily contiguous).
bool _isSubsequence(String needle, String haystack) {
  if (needle.isEmpty) return false;
  var i = 0;
  for (var j = 0; j < haystack.length && i < needle.length; j++) {
    if (needle[i] == haystack[j]) i++;
  }
  return i == needle.length;
}

// ─────────────────────────────────────────────────────────────────────────────
// AC2 — ratings & reviews
// ─────────────────────────────────────────────────────────────────────────────

/// The neutral midpoint used by the two-sided signals (rating, recency): an
/// unknown value neither helps nor hurts.
const double kTongtaiNeutralScore = 0.5;

/// Folds a 0–5 [rating] into a [0,1] signal, weighted by review confidence
/// (WTM-74 AC2).
///
/// * A `null` rating is unknown → [kTongtaiNeutralScore] (products carry no
///   rating today, so they must not be pushed to the bottom).
/// * With no review-volume information ([reviewCount] `null`) the rating is
///   trusted as-is — this is the catalogue's situation today.
/// * When review volume *is* known, the rating is shrunk toward the neutral
///   midpoint by a confidence factor `reviews / (reviews + smoothing)`, so a
///   5★ with a single review counts for less than a 5★ with hundreds. A rating
///   with zero reviews carries no confidence and lands on neutral.
double tongtaiRatingScore(
  double? rating, {
  int? reviewCount,
  double neutral = kTongtaiNeutralScore,
  double reviewSmoothing = 8,
}) {
  if (rating == null) return neutral;
  final normalized = (rating / 5).clamp(0.0, 1.0);
  if (reviewCount == null) return normalized;
  if (reviewCount <= 0) return neutral;
  final confidence = reviewCount / (reviewCount + reviewSmoothing);
  return neutral + confidence * (normalized - neutral);
}

// ─────────────────────────────────────────────────────────────────────────────
// AC3 — recency
// ─────────────────────────────────────────────────────────────────────────────

/// A [0,1] freshness signal for an item last touched at [timestamp] (WTM-74
/// AC3), using half-life decay: brand-new → 1.0, one [halfLifeDays] old →
/// [kTongtaiNeutralScore]-ish (0.5), then decaying toward 0.
///
/// A `null` timestamp is unknown → [kTongtaiNeutralScore]. Future-dated / just-
/// created items clamp to 1.0. `updatedAt` is the right input: it advances on
/// both add *and* edit, so this covers "newly added or updated".
double tongtaiRecencyScore(
  DateTime? timestamp,
  DateTime now, {
  double halfLifeDays = 30,
  double neutral = kTongtaiNeutralScore,
}) {
  if (timestamp == null) return neutral;
  final ageDays = now.difference(timestamp).inSeconds / Duration.secondsPerDay;
  if (ageDays <= 0) return 1.0;
  final decay = math.pow(0.5, ageDays / halfLifeDays).toDouble();
  return decay.clamp(0.0, 1.0);
}

// ─────────────────────────────────────────────────────────────────────────────
// AC4 — personalization
// ─────────────────────────────────────────────────────────────────────────────

/// A one-sided [0,1] personalization boost (WTM-74 AC4). 0 means "no affinity";
/// items the user has no relationship with are simply not lifted.
///
/// Two on-device signals, combined by taking the stronger:
/// * **Favorites** — a supplier the user favourited (WTM-65) gets [favoriteBoost].
/// * **History** — the fraction of the user's past searches ([historyTerms])
///   whose folded text is contained in the item's folded [text]. Pass history
///   *without* the current query so the active search does not trivially boost
///   everything it matched.
double tongtaiPersonalizationScore({
  required String id,
  required String text,
  required bool isSupplier,
  Set<String> favoriteSupplierIds = const {},
  List<String> historyTerms = const [],
  double favoriteBoost = 1.0,
}) {
  var score = 0.0;
  if (isSupplier && favoriteSupplierIds.contains(id)) {
    score = favoriteBoost;
  }
  if (historyTerms.isNotEmpty) {
    final foldedText = foldTongtaiRankText(text);
    var hits = 0;
    var considered = 0;
    for (final term in historyTerms) {
      final foldedTerm = foldTongtaiRankText(term);
      if (foldedTerm.isEmpty) continue;
      considered++;
      if (foldedText.contains(foldedTerm)) hits++;
    }
    if (considered > 0) {
      score = math.max(score, hits / considered);
    }
  }
  return score.clamp(0.0, 1.0);
}

/// The FTS baseline signal from a row's position in the bm25-ordered list: the
/// top row scores 1.0, the last 0.0. Preserves FTS relevance as one input to the
/// blended rank rather than discarding it.
double tongtaiBaseRelevanceScore(int position, int total) {
  if (total <= 1) return 1.0;
  return 1.0 - position / (total - 1);
}

// ─────────────────────────────────────────────────────────────────────────────
// AC5 — weights, variants & the A/B experiment framework
// ─────────────────────────────────────────────────────────────────────────────

/// The tunable weight of each ranking signal. One instance is one "ranking
/// algorithm"; the A/B framework swaps these to compare algorithms.
@immutable
class TongtaiRankingWeights {
  const TongtaiRankingWeights({
    this.textMatch = 0.35,
    this.baseRelevance = 0.25,
    this.rating = 0.15,
    this.recency = 0.10,
    this.personalization = 0.15,
  });

  /// AC1 — weight of text match quality.
  final double textMatch;

  /// Weight of the preserved FTS bm25 order.
  final double baseRelevance;

  /// AC2 — weight of rating/reviews.
  final double rating;

  /// AC3 — weight of recency.
  final double recency;

  /// AC4 — weight of personalization.
  final double personalization;

  /// The default, well-rounded mix (used by [TongtaiRankingVariant.balanced]).
  static const TongtaiRankingWeights balanced = TongtaiRankingWeights();

  /// FTS-dominant baseline — the "do (almost) what search always did" control
  /// arm to measure the other variants against.
  static const TongtaiRankingWeights control = TongtaiRankingWeights(
    textMatch: 0.25,
    baseRelevance: 0.75,
    rating: 0.0,
    recency: 0.0,
    personalization: 0.0,
  );

  /// Leans hard on personalization + ratings.
  static const TongtaiRankingWeights personalized = TongtaiRankingWeights(
    textMatch: 0.25,
    baseRelevance: 0.15,
    rating: 0.15,
    recency: 0.10,
    personalization: 0.35,
  );

  /// Leans on freshness — good for a fast-moving catalogue.
  static const TongtaiRankingWeights fresh = TongtaiRankingWeights(
    textMatch: 0.25,
    baseRelevance: 0.20,
    rating: 0.10,
    recency: 0.35,
    personalization: 0.10,
  );
}

/// A named ranking algorithm plus its A/B traffic [allocation].
@immutable
class TongtaiRankingVariant {
  const TongtaiRankingVariant({
    required this.id,
    required this.label,
    required this.weights,
    this.allocation = 1.0,
  }) : assert(allocation > 0, 'allocation must be positive');

  final String id;
  final String label;
  final TongtaiRankingWeights weights;

  /// Relative share of traffic assigned to this variant by
  /// [TongtaiRankingExperiment] (need not sum to 1 across variants — the
  /// experiment normalises).
  final double allocation;

  static const TongtaiRankingVariant control = TongtaiRankingVariant(
    id: 'control',
    label: 'FTS baseline',
    weights: TongtaiRankingWeights.control,
  );

  static const TongtaiRankingVariant balanced = TongtaiRankingVariant(
    id: 'balanced',
    label: 'Balanced',
    weights: TongtaiRankingWeights.balanced,
  );

  static const TongtaiRankingVariant personalized = TongtaiRankingVariant(
    id: 'personalized',
    label: 'Personalized',
    weights: TongtaiRankingWeights.personalized,
  );

  static const TongtaiRankingVariant fresh = TongtaiRankingVariant(
    id: 'fresh',
    label: 'Freshness',
    weights: TongtaiRankingWeights.fresh,
  );
}

/// A local, deterministic A/B experiment over ranking [variants] (WTM-74 AC5).
///
/// [assign] buckets a user into exactly one variant by hashing their id with the
/// experiment [salt], so assignment is **sticky** (the same install always gets
/// the same variant across sessions) and **offline** — no server, no coordinator,
/// nothing about the user leaves the device. That is enough to evaluate ranking
/// algorithms: ship two variants, keep them stable per user, compare locally.
@immutable
class TongtaiRankingExperiment {
  const TongtaiRankingExperiment({
    required this.variants,
    this.salt = 'wtm-74-ranking',
  });

  final List<TongtaiRankingVariant> variants;

  /// Mixed into the hash so two experiments bucket the same user independently.
  final String salt;

  /// The default two-arm experiment: FTS baseline vs the balanced multi-signal
  /// ranker, split 50/50.
  static const TongtaiRankingExperiment defaultExperiment =
      TongtaiRankingExperiment(
    variants: [
      TongtaiRankingVariant.control,
      TongtaiRankingVariant.balanced,
    ],
  );

  /// Deterministically assigns [unitId] (e.g. the local user id) to a variant by
  /// allocation. Same id + same experiment → same variant, always.
  TongtaiRankingVariant assign(String unitId) {
    if (variants.length == 1) return variants.first;
    final total =
        variants.fold<double>(0, (sum, v) => sum + v.allocation);
    final point = _hashUnitInterval('$salt:$unitId') * total;
    var cumulative = 0.0;
    for (final variant in variants) {
      cumulative += variant.allocation;
      if (point < cumulative) return variant;
    }
    return variants.last;
  }

  /// [assign], unless [overrideId] names a known variant (a QA / settings escape
  /// hatch to force a specific algorithm). An unknown [overrideId] falls back to
  /// the normal sticky assignment.
  TongtaiRankingVariant resolve(String unitId, {String? overrideId}) {
    if (overrideId != null) {
      for (final variant in variants) {
        if (variant.id == overrideId) return variant;
      }
    }
    return assign(unitId);
  }
}

/// Hashes [input] to a stable double in [0,1) via 32-bit FNV-1a. Deterministic
/// across platforms and runs (no `Random`), which is what makes bucketing sticky
/// and testable.
double _hashUnitInterval(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash / 0x100000000;
}

// ─────────────────────────────────────────────────────────────────────────────
// The ranker
// ─────────────────────────────────────────────────────────────────────────────

/// Re-ranks a [TongtaiSearchResults] set with the WTM-74 signals under a chosen
/// set of [weights].
///
/// Suppliers and products are ranked independently (each tab keeps its own best-
/// first order). Ranking only *reorders* — it never adds or drops rows — so the
/// filter/facet layer downstream keeps working unchanged.
@immutable
class TongtaiSearchRanker {
  const TongtaiSearchRanker({
    this.weights = TongtaiRankingWeights.balanced,
    this.recencyHalfLifeDays = 30,
    this.reviewSmoothing = 8,
  });

  final TongtaiRankingWeights weights;
  final double recencyHalfLifeDays;
  final double reviewSmoothing;

  /// Returns [results] re-ordered best-first under [weights].
  ///
  /// [query] drives the text-match signal; [now] the recency decay;
  /// [favoriteSupplierIds] and [historyTerms] the personalization. Pass
  /// [historyTerms] without the current [query].
  TongtaiSearchResults rank(
    TongtaiSearchResults results, {
    required String query,
    required DateTime now,
    Set<String> favoriteSupplierIds = const {},
    List<String> historyTerms = const [],
  }) {
    final suppliers = _rankList<TongtaiSupplierResult>(
      results.suppliers,
      query: query,
      now: now,
      favoriteSupplierIds: favoriteSupplierIds,
      historyTerms: historyTerms,
      isSupplier: true,
      idOf: (s) => s.id,
      textOf: (s) => s.name,
      ratingOf: (s) => s.rating,
      reviewCountOf: (s) => s.reviewCount,
      updatedAtOf: (s) => s.updatedAt,
    );
    final products = _rankList<TongtaiProductResult>(
      results.products,
      query: query,
      now: now,
      favoriteSupplierIds: favoriteSupplierIds,
      historyTerms: historyTerms,
      isSupplier: false,
      idOf: (p) => p.id,
      textOf: (p) => p.name,
      ratingOf: (p) => p.rating,
      reviewCountOf: (p) => p.reviewCount,
      updatedAtOf: (p) => p.updatedAt,
    );
    return TongtaiSearchResults(suppliers: suppliers, products: products);
  }

  /// The blended [0,1]-ish score for one item (exposed for tuning/testing).
  double scoreItem({
    required String id,
    required String text,
    required bool isSupplier,
    required int position,
    required int total,
    double? rating,
    int? reviewCount,
    DateTime? updatedAt,
    required String query,
    required DateTime now,
    Set<String> favoriteSupplierIds = const {},
    List<String> historyTerms = const [],
  }) {
    final textScore = tongtaiTextMatchScore(query, text);
    final baseScore = tongtaiBaseRelevanceScore(position, total);
    final ratingScore = tongtaiRatingScore(
      rating,
      reviewCount: reviewCount,
      reviewSmoothing: reviewSmoothing,
    );
    final recencyScore = tongtaiRecencyScore(
      updatedAt,
      now,
      halfLifeDays: recencyHalfLifeDays,
    );
    final personalizationScore = tongtaiPersonalizationScore(
      id: id,
      text: text,
      isSupplier: isSupplier,
      favoriteSupplierIds: favoriteSupplierIds,
      historyTerms: historyTerms,
    );
    return weights.textMatch * textScore +
        weights.baseRelevance * baseScore +
        weights.rating * ratingScore +
        weights.recency * recencyScore +
        weights.personalization * personalizationScore;
  }

  List<T> _rankList<T>(
    List<T> items, {
    required String query,
    required DateTime now,
    required Set<String> favoriteSupplierIds,
    required List<String> historyTerms,
    required bool isSupplier,
    required String Function(T) idOf,
    required String Function(T) textOf,
    required double? Function(T) ratingOf,
    required int? Function(T) reviewCountOf,
    required DateTime? Function(T) updatedAtOf,
  }) {
    if (items.length <= 1) return List<T>.of(items);
    final total = items.length;

    final scored = <_Scored<T>>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final score = scoreItem(
        id: idOf(item),
        text: textOf(item),
        isSupplier: isSupplier,
        position: i,
        total: total,
        rating: ratingOf(item),
        reviewCount: reviewCountOf(item),
        updatedAt: updatedAtOf(item),
        query: query,
        now: now,
        favoriteSupplierIds: favoriteSupplierIds,
        historyTerms: historyTerms,
      );
      scored.add(_Scored<T>(item, score, i));
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      // Stable tie-break: keep the original FTS order for equal scores.
      return byScore != 0 ? byScore : a.index.compareTo(b.index);
    });

    return [for (final s in scored) s.item];
  }
}

/// An item paired with its computed score and original position, for sorting.
class _Scored<T> {
  const _Scored(this.item, this.score, this.index);
  final T item;
  final double score;
  final int index;
}
