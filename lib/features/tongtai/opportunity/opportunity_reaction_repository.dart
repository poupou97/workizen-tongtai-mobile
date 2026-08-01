import '../../../database/database.dart';
import 'opportunity.dart';

/// Persists what the seller decided about each opportunity (WTM-190).
///
/// Opportunities themselves are regenerated from business data on every read,
/// so only the judgement is stored. See `tables/opportunity_reactions.dart`
/// for why storing the opportunity too would violate One Data Path.
class OpportunityReactionRepository {
  OpportunityReactionRepository(this._db);

  final AppDatabase _db;

  /// Every stored reaction, keyed by opportunity id.
  ///
  /// An unknown code is **dropped**, not defaulted — the same rule
  /// ADR-TON-018 sets for restoring an unknown enum. Defaulting to `saved`
  /// would resurrect something the seller dismissed; defaulting to `dismissed`
  /// would hide something they saved. Both are worse than forgetting.
  Future<Map<String, OpportunityReaction>> loadAll() async {
    final rows = await _db.select(_db.opportunityReactionsTable).get();
    return Map.fromEntries([
      for (final r in rows) ?_entry(r.opportunityId, r.reaction),
    ]);
  }

  /// Records a reaction. [OpportunityReaction.none] deletes the row rather
  /// than storing "no opinion" — absence already means that, and keeping both
  /// representations would make two states that read the same.
  Future<void> save(
    String opportunityId,
    OpportunityReaction reaction, {
    DateTime? now,
  }) async {
    if (reaction == OpportunityReaction.none) {
      await (_db.delete(
        _db.opportunityReactionsTable,
      )..where((t) => t.opportunityId.equals(opportunityId))).go();
      return;
    }
    await _db
        .into(_db.opportunityReactionsTable)
        .insertOnConflictUpdate(
          OpportunityReactionsTableCompanion.insert(
            opportunityId: opportunityId,
            reaction: reaction.name,
            updatedAt: now ?? DateTime.now(),
          ),
        );
  }

  /// Replaces every reaction in one transaction. Used by restore
  /// (Replace semantics, ADR-TON-018).
  Future<void> replaceAll(
    Map<String, OpportunityReaction> reactions, {
    DateTime? now,
  }) async {
    final stamp = now ?? DateTime.now();
    await _db.transaction(() async {
      await _db.delete(_db.opportunityReactionsTable).go();
      for (final entry in reactions.entries) {
        if (entry.value == OpportunityReaction.none) continue;
        await _db
            .into(_db.opportunityReactionsTable)
            .insert(
              OpportunityReactionsTableCompanion.insert(
                opportunityId: entry.key,
                reaction: entry.value.name,
                updatedAt: stamp,
              ),
            );
      }
    });
  }

  Future<void> deleteAll() async {
    await _db.delete(_db.opportunityReactionsTable).go();
  }

  static MapEntry<String, OpportunityReaction>? _entry(String id, String code) {
    final reaction = _reactionFromCode(code);
    return reaction == null ? null : MapEntry(id, reaction);
  }

  static OpportunityReaction? _reactionFromCode(String code) {
    for (final value in OpportunityReaction.values) {
      if (value.name == code) return value;
    }
    return null;
  }
}

/// Applies stored reactions to a freshly generated feed.
///
/// The opportunities come from the rule engine (no reaction), the reactions
/// come from the database. This is the one place they meet, so it is also the
/// one place a mismatch can be handled: a reaction whose opportunity is no
/// longer generated is simply not applied — it does not error, and it does not
/// resurrect a stale card.
List<Opportunity> applyReactions(
  List<Opportunity> generated,
  Map<String, OpportunityReaction> reactions,
) => [
  for (final o in generated)
    if (reactions[o.id] case final reaction?)
      o.copyWith(reaction: reaction)
    else
      o,
];
