import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/search/tongtai_ranking.dart';
import 'package:tongtai/features/tongtai/search/tongtai_search_models.dart';

/// Pure unit tests for the WTM-74 ranking & relevance engine: each signal
/// (text match quality, ratings+reviews, recency, personalization, FTS base)
/// in isolation, the deterministic A/B experiment, and the end-to-end reorder.
void main() {
  TongtaiSupplierResult supplier(
    String id,
    String name, {
    double? rating,
    int? reviewCount,
    DateTime? updatedAt,
  }) => TongtaiSupplierResult(
    id: id,
    name: name,
    rating: rating,
    reviewCount: reviewCount,
    updatedAt: updatedAt,
  );

  TongtaiProductResult product(String id, String name, {DateTime? updatedAt}) =>
      TongtaiProductResult(
        id: id,
        name: name,
        price: 1000,
        stock: 10,
        updatedAt: updatedAt,
      );

  group('foldTongtaiRankText', () {
    test(
      'lower-cases, folds Vietnamese diacritics incl. đ, collapses spaces',
      () {
        expect(foldTongtaiRankText('  Cà  Phê Đắk Lắk '), 'ca phe dak lak');
        expect(foldTongtaiRankText('ĐƠN Hàng'), 'don hang');
        expect(foldTongtaiRankText('Nước Mắm'), 'nuoc mam');
      },
    );

    test('folds the query and target to the same form (FTS parity)', () {
      expect(foldTongtaiRankText('ca phe'), foldTongtaiRankText('Cà phê'));
    });
  });

  group('classifyTongtaiMatch (AC1: exact/prefix/fuzzy)', () {
    test('exact (diacritic-insensitive)', () {
      expect(
        classifyTongtaiMatch('ca phe', 'Cà Phê'),
        TongtaiMatchQuality.exact,
      );
    });

    test('prefix — text starts with the query', () {
      expect(
        classifyTongtaiMatch('ca phe', 'Cà phê Đắk Lắk'),
        TongtaiMatchQuality.prefix,
      );
    });

    test('wordPrefix — an inner word starts with the query', () {
      expect(
        classifyTongtaiMatch('dak', 'Cà phê Đắk Lắk'),
        TongtaiMatchQuality.wordPrefix,
      );
    });

    test('contains — query sits mid-word', () {
      expect(
        classifyTongtaiMatch('hun', 'Robusta thunder'),
        TongtaiMatchQuality.contains,
      );
    });

    test('fuzzy — all tokens are word-prefixes, any order', () {
      expect(
        classifyTongtaiMatch('phe ca', 'Cà phê rang xay'),
        TongtaiMatchQuality.fuzzy,
      );
    });

    test('fuzzy — subsequence of letters', () {
      // c-p-h appear in order across "cà phê".
      expect(classifyTongtaiMatch('cph', 'Cà phê'), TongtaiMatchQuality.fuzzy);
    });

    test('none — unrelated, and blank query/text', () {
      expect(classifyTongtaiMatch('xyz', 'Cà phê'), TongtaiMatchQuality.none);
      expect(classifyTongtaiMatch('   ', 'Cà phê'), TongtaiMatchQuality.none);
      expect(classifyTongtaiMatch('ca', '   '), TongtaiMatchQuality.none);
    });

    test('scores strictly decrease exact > prefix > wordPrefix > contains > '
        'fuzzy > none', () {
      final scores = [
        TongtaiMatchQuality.exact,
        TongtaiMatchQuality.prefix,
        TongtaiMatchQuality.wordPrefix,
        TongtaiMatchQuality.contains,
        TongtaiMatchQuality.fuzzy,
        TongtaiMatchQuality.none,
      ].map((q) => q.score).toList();
      for (var i = 0; i < scores.length - 1; i++) {
        expect(
          scores[i],
          greaterThan(scores[i + 1]),
          reason: 'index $i should outrank ${i + 1}',
        );
      }
    });
  });

  group('tongtaiRatingScore (AC2: ratings & reviews)', () {
    test('null rating is neutral (unrated must not sink)', () {
      expect(tongtaiRatingScore(null), kTongtaiNeutralScore);
    });

    test('higher rating scores higher when review volume is unknown', () {
      expect(tongtaiRatingScore(5.0), 1.0);
      expect(tongtaiRatingScore(2.5), closeTo(0.5, 1e-9));
      expect(tongtaiRatingScore(4.0), greaterThan(tongtaiRatingScore(3.0)));
    });

    test('reviews add confidence: a lone 5★ is shrunk toward neutral', () {
      final fewReviews = tongtaiRatingScore(5.0, reviewCount: 1);
      final manyReviews = tongtaiRatingScore(5.0, reviewCount: 500);
      expect(fewReviews, lessThan(manyReviews));
      expect(fewReviews, greaterThan(kTongtaiNeutralScore));
      expect(manyReviews, greaterThan(0.9));
    });

    test('a rating with zero reviews carries no confidence → neutral', () {
      expect(tongtaiRatingScore(5.0, reviewCount: 0), kTongtaiNeutralScore);
    });
  });

  group('tongtaiRecencyScore (AC3: recency boost)', () {
    final now = DateTime(2026, 7, 16, 12);

    test('brand-new / future-dated items score 1.0', () {
      expect(tongtaiRecencyScore(now, now), 1.0);
      expect(tongtaiRecencyScore(now.add(const Duration(days: 3)), now), 1.0);
    });

    test('one half-life old sits at ~0.5', () {
      final oneHalfLifeAgo = now.subtract(const Duration(days: 30));
      expect(
        tongtaiRecencyScore(oneHalfLifeAgo, now, halfLifeDays: 30),
        closeTo(0.5, 1e-6),
      );
    });

    test('newer beats older; null is neutral', () {
      final newer = now.subtract(const Duration(days: 2));
      final older = now.subtract(const Duration(days: 120));
      expect(
        tongtaiRecencyScore(newer, now),
        greaterThan(tongtaiRecencyScore(older, now)),
      );
      expect(tongtaiRecencyScore(null, now), kTongtaiNeutralScore);
    });
  });

  group('tongtaiPersonalizationScore (AC4: favorites + history)', () {
    test('a favourited supplier is boosted; a non-favourite is not', () {
      expect(
        tongtaiPersonalizationScore(
          id: 's1',
          text: 'Anything',
          isSupplier: true,
          favoriteSupplierIds: {'s1'},
        ),
        1.0,
      );
      expect(
        tongtaiPersonalizationScore(
          id: 's2',
          text: 'Anything',
          isSupplier: true,
          favoriteSupplierIds: {'s1'},
        ),
        0.0,
      );
    });

    test('favorites are supplier-only (a product id never matches)', () {
      expect(
        tongtaiPersonalizationScore(
          id: 's1',
          text: 'Anything',
          isSupplier: false,
          favoriteSupplierIds: {'s1'},
        ),
        0.0,
      );
    });

    test('history affinity = fraction of past searches the item matches', () {
      final score = tongtaiPersonalizationScore(
        id: 'p1',
        text: 'Cà phê Robusta',
        isSupplier: false,
        historyTerms: const ['ca phe', 'balo'],
      );
      expect(score, closeTo(0.5, 1e-9)); // 1 of 2 terms matches
    });

    test('favourite dominates a weaker history signal', () {
      final score = tongtaiPersonalizationScore(
        id: 's1',
        text: 'Trà sữa',
        isSupplier: true,
        favoriteSupplierIds: {'s1'},
        historyTerms: const ['ca phe', 'balo', 'quat'], // 0 hits
      );
      expect(score, 1.0);
    });
  });

  group('tongtaiBaseRelevanceScore', () {
    test('top row scores 1.0, last 0.0, single row 1.0', () {
      expect(tongtaiBaseRelevanceScore(0, 5), 1.0);
      expect(tongtaiBaseRelevanceScore(4, 5), 0.0);
      expect(tongtaiBaseRelevanceScore(0, 1), 1.0);
    });
  });

  group('TongtaiRankingExperiment (AC5: A/B framework)', () {
    const experiment = TongtaiRankingExperiment.defaultExperiment;

    test('assignment is deterministic and sticky per user', () {
      final a = experiment.assign('user-123');
      final b = experiment.assign('user-123');
      expect(a.id, b.id); // same user → same variant, always
    });

    test(
      'different users can land on different variants (both arms reachable)',
      () {
        final assigned = <String>{};
        for (var i = 0; i < 200; i++) {
          assigned.add(experiment.assign('user-$i').id);
        }
        // With a 50/50 split over 200 users, both arms must appear.
        expect(assigned, containsAll(<String>{'control', 'balanced'}));
      },
    );

    test('allocation skews the split toward the heavier arm', () {
      const skewed = TongtaiRankingExperiment(
        variants: [
          TongtaiRankingVariant(
            id: 'control',
            label: 'c',
            weights: TongtaiRankingWeights.control,
            allocation: 9,
          ),
          TongtaiRankingVariant.balanced,
        ],
      );
      var control = 0;
      for (var i = 0; i < 400; i++) {
        if (skewed.assign('u$i').id == 'control') control++;
      }
      // ~90% expected; assert a comfortable majority to avoid flakiness.
      expect(control, greaterThan(280));
    });

    test(
      'resolve() honours a QA override, else falls back to sticky assign',
      () {
        expect(
          experiment.resolve('user-1', overrideId: 'control').id,
          'control',
        );
        expect(
          experiment.resolve('user-1', overrideId: 'balanced').id,
          'balanced',
        );
        // Unknown override → normal assignment.
        expect(
          experiment.resolve('user-1', overrideId: 'nope').id,
          experiment.assign('user-1').id,
        );
      },
    );

    test('single-variant experiment always returns that variant', () {
      const solo = TongtaiRankingExperiment(
        variants: [TongtaiRankingVariant.personalized],
      );
      expect(solo.assign('whoever').id, 'personalized');
    });
  });

  group('TongtaiSearchranker.rank (end-to-end reorder)', () {
    final now = DateTime(2026, 7, 16, 12);

    test('ranking only reorders — never adds or drops rows', () {
      final results = TongtaiSearchResults(
        suppliers: [supplier('s1', 'Alpha'), supplier('s2', 'Beta')],
        products: [product('p1', 'Gamma')],
      );
      final ranked = const TongtaiSearchRanker().rank(
        results,
        query: 'a',
        now: now,
      );
      expect(ranked.suppliers.map((s) => s.id).toSet(), {'s1', 's2'});
      expect(ranked.products.map((p) => p.id).toSet(), {'p1'});
    });

    test(
      'text-match quality dominates the score at equal FTS position (AC1)',
      () {
        // Same position (base signal equal) isolates the text-match signal: an
        // exact hit must score above a prefix hit, a prefix above a contains.
        const ranker = TongtaiSearchRanker();
        double score(String name) => ranker.scoreItem(
          id: 'x',
          text: name,
          isSupplier: true,
          position: 0,
          total: 3,
          query: 'ca phe',
          now: now,
        );
        expect(score('Cà phê'), greaterThan(score('Cà phê Đắk Lắk')));
        expect(score('Cà phê Đắk Lắk'), greaterThan(score('Đặc sản cà phê')));
      },
    );

    test('a text-weighted algorithm promotes the exact hit over FTS order '
        '(AC1)', () {
      // FTS hands them back prefix-first; a text-heavy variant reorders so the
      // exact match wins despite its worse FTS position.
      final results = TongtaiSearchResults(
        suppliers: [
          supplier('prefix', 'Cà phê Đắk Lắk'),
          supplier('exact', 'Cà phê'),
        ],
      );
      const textHeavy = TongtaiSearchRanker(
        weights: TongtaiRankingWeights(
          textMatch: 0.8,
          baseRelevance: 0.05,
          rating: 0.05,
          recency: 0.05,
          personalization: 0.05,
        ),
      );
      final ranked = textHeavy.rank(results, query: 'ca phe', now: now);
      expect(ranked.suppliers.first.id, 'exact');
    });

    test(
      'a rating-weighted algorithm surfaces the higher-rated supplier (AC2)',
      () {
        final results = TongtaiSearchResults(
          suppliers: [
            supplier('low', 'Vietnam Coffee', rating: 3.0),
            supplier('high', 'Vietnam Coffee', rating: 5.0),
          ],
        );
        const ratingHeavy = TongtaiSearchRanker(
          weights: TongtaiRankingWeights(
            textMatch: 0.2,
            baseRelevance: 0.05,
            rating: 0.6,
            recency: 0.05,
            personalization: 0.1,
          ),
        );
        final ranked = ratingHeavy.rank(
          results,
          query: 'vietnam coffee',
          now: now,
        );
        expect(ranked.suppliers.first.id, 'high');
      },
    );

    test('recency breaks ties among otherwise-equal items (AC3)', () {
      final results = TongtaiSearchResults(
        products: [
          product(
            'old',
            'Gao ST25',
            updatedAt: now.subtract(const Duration(days: 200)),
          ),
          product('new', 'Gao ST25', updatedAt: now),
        ],
      );
      final ranked = const TongtaiSearchRanker(
        weights: TongtaiRankingWeights.fresh,
      ).rank(results, query: 'gao', now: now);
      expect(ranked.products.first.id, 'new');
    });

    test('a favourited supplier is promoted under the personalized variant '
        '(AC4)', () {
      final results = TongtaiSearchResults(
        suppliers: [
          supplier('plain', 'Saigon Textile', rating: 4.9),
          supplier('fav', 'Saigon Textile', rating: 4.0),
        ],
      );
      final ranked = const TongtaiSearchRanker(
        weights: TongtaiRankingWeights.personalized,
      ).rank(results, query: 'saigon', now: now, favoriteSupplierIds: {'fav'});
      // The favourite outranks the (slightly) higher-rated non-favourite.
      expect(ranked.suppliers.first.id, 'fav');
    });

    test('equal scores keep the original FTS order (stable sort)', () {
      final results = TongtaiSearchResults(
        suppliers: [
          supplier('first', 'Neutral Co'),
          supplier('second', 'Neutral Co'),
          supplier('third', 'Neutral Co'),
        ],
      );
      // No query match, no rating/recency/fav differences → all-equal signal
      // except base relevance, which preserves the incoming order.
      final ranked = const TongtaiSearchRanker().rank(
        results,
        query: 'zzz',
        now: now,
      );
      expect(ranked.suppliers.map((s) => s.id), ['first', 'second', 'third']);
    });

    test('control variant preserves FTS order (baseline arm)', () {
      final results = TongtaiSearchResults(
        suppliers: [
          supplier(
            'a',
            'Coffee A',
            rating: 3.0,
            updatedAt: now.subtract(const Duration(days: 300)),
          ),
          supplier('b', 'Coffee B', rating: 5.0, updatedAt: now),
        ],
      );
      final ranked = const TongtaiSearchRanker(
        weights: TongtaiRankingWeights.control,
      ).rank(results, query: 'coffee', now: now);
      // Control ignores rating/recency/personalization, so FTS order stands.
      expect(ranked.suppliers.map((s) => s.id), ['a', 'b']);
    });
  });
}
