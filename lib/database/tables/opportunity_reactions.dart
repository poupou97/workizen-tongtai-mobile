/// What the seller decided about an opportunity (WTM-190).
///
/// ## Why only the reaction is stored, not the opportunity
/// Opportunities are **derived data**: the rule engine regenerates them from
/// products, customers, orders and goals on every read, deterministically. So
/// storing the opportunity itself would create a parallel copy of something the
/// app can already compute — exactly what One Data Path (ADR-TON-015) forbids,
/// and the copy would drift the moment the underlying data changed.
///
/// What is **not** derivable is the seller's judgement: *"I saved this one"*,
/// *"I never want to see this again"*. That is the only thing worth persisting,
/// and until now it was not persisted at all — every save and every dismissal
/// was lost the moment the app closed.
library;

import 'package:drift/drift.dart';

/// One row per opportunity the seller has reacted to.
///
/// Opportunities the seller has not touched have no row: absence means
/// [OpportunityReaction.none], so a brand-new business writes nothing.
class OpportunityReactionsTable extends Table {
  /// The opportunity's stable id, as produced by the rule engine.
  ///
  /// The engine is deterministic, so the same business data yields the same
  /// ids — which is what makes keying by id safe. If an opportunity stops
  /// being generated (the underlying data changed), its row simply stops
  /// matching anything and is ignored on read.
  TextColumn get opportunityId => text()();

  /// `OpportunityReaction.name` — canonical code, never a display label
  /// (ADR-TON-018).
  TextColumn get reaction => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {opportunityId};
}
