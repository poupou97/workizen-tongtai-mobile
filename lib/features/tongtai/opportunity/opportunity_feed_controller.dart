import 'package:flutter/foundation.dart';

import '../core/tongtai_enums.dart';
import 'opportunity.dart';

/// How the opportunity feed is ordered (WTM-91 AC3).
enum OpportunitySort {
  relevance, // aiScore
  recency, // discoveredAt
  roi; // estimatedRoi

  String get labelEn => switch (this) {
    OpportunitySort.relevance => 'Relevance',
    OpportunitySort.recency => 'Newest',
    OpportunitySort.roi => 'ROI',
  };

  String get labelVi => switch (this) {
    OpportunitySort.relevance => 'Liên quan',
    OpportunitySort.recency => 'Mới nhất',
    OpportunitySort.roi => 'ROI',
  };

  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// The active feed view: an optional type facet, sort order, and whether the
/// view shows the main feed or the saved list. Immutable, screen holds one.
@immutable
class OpportunityQuery {
  const OpportunityQuery({
    this.type,
    this.sort = OpportunitySort.relevance,
    this.savedOnly = false,
  });

  /// Type facet (AC2); null = all types.
  final OpportunityType? type;

  /// Sort key (AC3); always descending — best/newest first.
  final OpportunitySort sort;

  /// When true, only bookmarked opportunities are shown (AC4).
  final bool savedOnly;

  OpportunityQuery copyWith({
    OpportunityType? type,
    bool clearType = false,
    OpportunitySort? sort,
    bool? savedOnly,
  }) {
    return OpportunityQuery(
      type: clearType ? null : (type ?? this.type),
      sort: sort ?? this.sort,
      savedOnly: savedOnly ?? this.savedOnly,
    );
  }
}

/// Mutable, in-memory opportunity feed (WTM-91) — same ChangeNotifier
/// pattern as the other module controllers. Local-first; a Drift-backed
/// source over the rule engine can replace the in-memory list without
/// touching callers. Reactions (save/interested/dismiss) live here so every
/// view reflects them immediately.
class OpportunityFeedController extends ChangeNotifier {
  OpportunityFeedController(Iterable<Opportunity> initial)
    : _items = [...initial];

  /// Convenience: seeded with the built-in sample opportunities.
  factory OpportunityFeedController.sample() =>
      OpportunityFeedController(kSampleOpportunities);

  final List<Opportunity> _items;

  /// Every opportunity regardless of reaction (unsorted snapshot).
  List<Opportunity> get all => List.unmodifiable(_items);

  /// Bookmarked count — badge material for the Saved toggle.
  int get savedCount => _items.where((o) => o.isSaved).length;

  /// The feed for [query]: dismissed items are hidden from the main feed but
  /// remain in the saved view if they were saved first (AC4/AC5), sorted
  /// descending by the query's key with a stable id tiebreak.
  List<Opportunity> feed(OpportunityQuery query) {
    final results = <Opportunity>[
      for (final o in _items)
        // WTM-182: a type the rule engine cannot produce is filtered out of
        // the feed, not deleted from the store. A seller who restores a backup
        // holding one keeps the record; they simply do not see it until the
        // data source that justifies it exists.
        if (o.type.isVisible &&
            (query.savedOnly ? o.isSaved : !o.isDismissed) &&
            (query.type == null || o.type == query.type))
          o,
    ];
    int compare(Opportunity a, Opportunity b) {
      final int c = switch (query.sort) {
        OpportunitySort.relevance => b.aiScore.compareTo(a.aiScore),
        OpportunitySort.recency => b.discoveredAt.compareTo(a.discoveredAt),
        OpportunitySort.roi => b.estimatedRoi.compareTo(a.estimatedRoi),
      };
      return c != 0 ? c : a.id.compareTo(b.id);
    }

    results.sort(compare);
    return results;
  }

  /// Distinct types present in the (non-dismissed) feed — the AC2 facet row.
  ///
  /// Types the rule engine cannot produce yet are filtered out here rather than
  /// removed from the domain (WTM-182): a facet that always returns nothing is
  /// a promise the product cannot keep.
  List<OpportunityType> get availableTypes {
    final set = <OpportunityType>{
      for (final o in _items)
        if (!o.isDismissed && o.type.isVisible) o.type,
    };
    final list = set.toList()..sort((a, b) => a.index.compareTo(b.index));
    return list;
  }

  /// The seller's current reaction to [id], or [OpportunityReaction.none] if
  /// they have not reacted (or the opportunity is no longer in the feed).
  ///
  /// Callers persist what this returns rather than re-deriving it, so the
  /// stored reaction cannot disagree with the one on screen (WTM-190).
  OpportunityReaction reactionOf(String id) {
    final index = _items.indexWhere((o) => o.id == id);
    return index < 0 ? OpportunityReaction.none : _items[index].reaction;
  }

  void _react(String id, OpportunityReaction reaction) {
    final index = _items.indexWhere((o) => o.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(reaction: reaction);
    notifyListeners();
  }

  /// Bookmark for later review (AC4). Toggles off back to none.
  void toggleSaved(String id) {
    final index = _items.indexWhere((o) => o.id == id);
    if (index < 0) return;
    _react(
      id,
      _items[index].isSaved
          ? OpportunityReaction.none
          : OpportunityReaction.saved,
    );
  }

  /// Swipe right — mark as actively pursued (AC5).
  void markInterested(String id) => _react(id, OpportunityReaction.interested);

  /// Swipe left — hide from the main feed (AC5). Reversible via [restore].
  void dismiss(String id) => _react(id, OpportunityReaction.dismissed);

  /// Undo a dismissal (snackbar action).
  void restore(String id) => _react(id, OpportunityReaction.none);
}
