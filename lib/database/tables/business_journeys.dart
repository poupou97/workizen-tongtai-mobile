/// Business Journey persistence — three tables, one tree (WTM-185, ADR-TON-021).
///
/// The Concept describes six layers; the product had one. These tables add the
/// missing five **without touching a single existing table**: `BusinessGoal`
/// stays exactly as it is and a journey points at it by id, so a seller who
/// already has goals loses nothing and needs no backfill.
///
/// ## ⚠️ A name that is already taken
/// `journeys_table` (in `tables/journeys.dart`) does **not** store journeys —
/// it stores [BusinessGoal], and has since WTM-124. The name predates the
/// Concept vocabulary and is load-bearing in schema v1–v8, so renaming it would
/// be a breaking migration for zero user benefit.
///
/// Everything in this file is therefore prefixed **`business_journey`**. If you
/// are looking for the goal, it is in `journeys_table`; if you are looking for
/// the plan, it is here.
library;

import 'package:drift/drift.dart';

/// A journey: one goal plus the plan for reaching it.
class BusinessJourneysTable extends Table {
  TextColumn get id => text()();

  /// The `BusinessGoal` this journey pursues (`journeys_table.id`).
  ///
  /// **Deliberately not a foreign key.** Restore replaces goals and journeys as
  /// separate datasets, and a hard FK would make dataset write-order part of
  /// the restore contract — the same trap that produced SqliteException 787
  /// when orders were deleted before customers. The repository verifies the
  /// link after writing instead, exactly as `.ttbk` restore already verifies
  /// `order.customerId`.
  TextColumn get goalId => text()();

  /// `JourneyState.code` — `draft`/`active`/`paused`/`completed`/`archived`.
  /// Canonical code, never a display label (ADR-TON-018).
  TextColumn get state => text()();

  /// Which plan version is in force. `null` while the journey is a draft with
  /// no plan yet.
  IntColumn get activePlanVersion => integer().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One node of the journey tree — milestone, mission, step or task.
///
/// A single recursive table rather than four rigid ones (ADR-TON-021): adding
/// a node kind is an enum value rather than a migration, and depth is not
/// capped at the four levels the Concept happens to name today.
@TableIndex(name: 'business_journey_nodes_journey', columns: {#journeyId})
class BusinessJourneyNodesTable extends Table {
  TextColumn get id => text()();

  /// Owning journey. Deleting a journey deletes its whole tree.
  TextColumn get journeyId => text().references(
    BusinessJourneysTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// `null` = root. A plain column rather than a self-referencing FK: the
  /// repository validates the tree when it assembles it, and a self-FK would
  /// force parents to be written before children during restore.
  TextColumn get parentId => text().nullable()();

  /// `JourneyNodeKind.code`.
  TextColumn get kind => text()();

  TextColumn get title => text()();

  /// `JourneyNodeOrigin.code` — **who authored this node**.
  ///
  /// The column that makes ADR-TON-016 checkable rather than merely written
  /// down: without it nobody can tell, six months from now, which steps a rule
  /// produced and which a model suggested.
  TextColumn get origin => text()();

  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  /// `JourneyNodeState.code`.
  TextColumn get state => text()();

  /// `JourneyCompletion.code` — `manual` or `derived`.
  TextColumn get completion => text()();

  /// Which real number decides completion when [completion] is `derived`
  /// (`revenue`, `orders`, `customers`). Null for manual nodes.
  TextColumn get derivedMetric => text().nullable()();

  RealColumn get derivedTarget => real().nullable()();

  /// Fixed reason tokens joined by `,` — why a rule produced this node. A short
  /// closed vocabulary read as a whole, so it stays a joined column until a
  /// real query needs otherwise (ADR-TON-009).
  TextColumn get reasonCodes => text().nullable()();

  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A generated plan, kept by version.
///
/// Re-planning writes a **new version** and leaves the old one in place. The
/// Concept requires *"AI Adaptation — Journey can adjust if circumstances
/// change"*; overwriting would let the plan change under the seller with
/// nothing to compare against and no way to ask why it changed.
class BusinessJourneyPlansTable extends Table {
  TextColumn get journeyId => text().references(
    BusinessJourneysTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  IntColumn get version => integer()();

  /// `JourneyNodeOrigin.code` of whoever generated it. In Phase 2 always
  /// `rule_twin` — plan generation is a rule, not a model (ADR-TON-016).
  TextColumn get generatedBy => text()();

  DateTimeColumn get generatedAt => dateTime()();

  /// Fixed reason tokens joined by `,` explaining the shape of this plan.
  TextColumn get reasonCodes => text().nullable()();

  @override
  Set<Column> get primaryKey => {journeyId, version};
}
