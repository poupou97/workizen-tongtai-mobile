import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_score.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_reaction_repository.dart';

/// WTM-190 (O-3) — the seller's decisions about opportunities must outlive the
/// app.
///
/// Every test here uses a **real SQLite file** and reopens it, because the bug
/// being fixed was invisible in memory: the feed controller held the reaction
/// perfectly for as long as the process lived, and lost it the moment the
/// seller closed the app. An in-memory database would have passed the old code.
void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('tongtai_opp_reactions');
    file = File('${dir.path}/t.sqlite');
  });

  tearDown(() async => dir.delete(recursive: true));

  AppDatabase open() => AppDatabase.forExecutor(NativeDatabase(file));

  Opportunity opportunity(String id) => Opportunity(
    id: id,
    type: OpportunityType.trend,
    title: 'Cơ hội $id',
    description: 'mô tả',
    expectedImpact: 1000000,
    score: OpportunityScore.fixed(70),
    discoveredAt: DateTime(2026, 8, 1),
  );

  test('a save survives closing and reopening the app', () async {
    var db = open();
    await OpportunityReactionRepository(
      db,
    ).save('opp-1', OpportunityReaction.saved);
    await db.close();

    db = open();
    final stored = await OpportunityReactionRepository(db).loadAll();
    await db.close();

    expect(stored['opp-1'], OpportunityReaction.saved);
  });

  test('a dismissal survives closing and reopening the app', () async {
    var db = open();
    await OpportunityReactionRepository(
      db,
    ).save('opp-2', OpportunityReaction.dismissed);
    await db.close();

    db = open();
    final stored = await OpportunityReactionRepository(db).loadAll();
    await db.close();

    expect(stored['opp-2'], OpportunityReaction.dismissed);
  });

  test('undoing a dismissal removes it rather than storing "none"', () async {
    // Two ways to say "no opinion" would eventually disagree with each other.
    final db = open();
    final repo = OpportunityReactionRepository(db);
    await repo.save('opp-3', OpportunityReaction.dismissed);
    await repo.save('opp-3', OpportunityReaction.none);

    expect(await repo.loadAll(), isEmpty);
    await db.close();
  });

  test('the latest decision wins', () async {
    final db = open();
    final repo = OpportunityReactionRepository(db);
    await repo.save('opp-4', OpportunityReaction.saved);
    await repo.save('opp-4', OpportunityReaction.interested);

    expect((await repo.loadAll())['opp-4'], OpportunityReaction.interested);
    await db.close();
  });

  test('an unknown reaction code is dropped, not defaulted', () async {
    // ADR-TON-018's rule for unknown enums. Guessing would either resurrect
    // something the seller dismissed or hide something they saved, and they
    // would have no way to tell it happened.
    final db = open();
    await db.customStatement(
      "INSERT INTO opportunity_reactions_table "
      "(opportunity_id, reaction, updated_at) VALUES ('opp-5', 'from_the_future', 0)",
    );

    expect(await OpportunityReactionRepository(db).loadAll(), isEmpty);
    await db.close();
  });

  group('applyReactions', () {
    test('layers stored decisions onto a freshly generated feed', () {
      final applied = applyReactions(
        [opportunity('a'), opportunity('b')],
        {'a': OpportunityReaction.saved},
      );

      expect(applied.firstWhere((o) => o.id == 'a').isSaved, isTrue);
      expect(
        applied.firstWhere((o) => o.id == 'b').reaction,
        OpportunityReaction.none,
      );
    });

    test('a reaction whose opportunity is gone does not resurrect it', () {
      // The rule engine stops generating an opportunity when the underlying
      // business data changes. Its leftover row must not put a stale card back
      // on screen — nor error.
      final applied = applyReactions(
        [opportunity('a')],
        {'vanished': OpportunityReaction.saved},
      );

      expect(applied.map((o) => o.id), ['a']);
    });
  });

  test('replaceAll wipes what was there before (restore = Replace)', () async {
    final db = open();
    final repo = OpportunityReactionRepository(db);
    await repo.save('old', OpportunityReaction.saved);
    await repo.replaceAll({'new': OpportunityReaction.dismissed});

    expect(await repo.loadAll(), {'new': OpportunityReaction.dismissed});
    await db.close();
  });

  test('the dead opportunities table is gone from the schema', () async {
    // v10 dropped it (WTM-190): nothing ever wrote a row, and its presence made
    // the app look like it persisted opportunities — which is precisely the
    // confusion that hid this bug.
    final db = open();
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' "
          "AND name='opportunities_table'",
        )
        .get();

    expect(rows, isEmpty);
    await db.close();
  });
}
