import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/journey/journey.dart';
import 'package:tongtai/features/tongtai/journey/journey_node.dart';
import 'package:tongtai/features/tongtai/export/backup_codec.dart';
import 'package:tongtai/features/tongtai/export/backup_format.dart';
import 'package:tongtai/features/tongtai/journey/journey_repository.dart';

/// WTM-185 (J1) — the journey tree against a real SQLite file.
void main() {
  late Directory dir;
  late AppDatabase db;
  late JourneyRepository repo;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('tongtai_journey');
    db = AppDatabase.forExecutor(NativeDatabase(File('${dir.path}/t.sqlite')));
    repo = JourneyRepository(db);
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  JourneyNode node(
    String id, {
    String? parentId,
    JourneyNodeKind kind = JourneyNodeKind.step,
    JourneyNodeOrigin origin = JourneyNodeOrigin.ruleTwin,
    JourneyNodeState state = JourneyNodeState.pending,
    int order = 0,
    JourneyCompletion completion = JourneyCompletion.manual,
    String? metric,
    double? target,
    List<String> reasons = const [],
  }) => JourneyNode(
    id: id,
    journeyId: 'j1',
    parentId: parentId,
    kind: kind,
    title: 'node $id',
    origin: origin,
    orderIndex: order,
    state: state,
    completion: completion,
    derivedMetric: metric,
    derivedTarget: target,
    reasonCodes: reasons,
  );

  Journey journey({
    JourneyState state = JourneyState.active,
    List<JourneyNode> nodes = const [],
    List<JourneyPlan> plans = const [],
    int? activePlanVersion,
  }) => Journey(
    id: 'j1',
    goalId: 'g1',
    state: state,
    activePlanVersion: activePlanVersion,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
    nodes: nodes,
    plans: plans,
  );

  group('empty database', () {
    test('reads as no journeys, not as an error', () async {
      expect(await repo.loadAll(), isEmpty);
      expect(await repo.loadActive(), isNull);
    });
  });

  group('round-trip through a real file', () {
    test('a three-level tree survives save and load', () async {
      await repo.save(
        journey(
          nodes: [
            node('m1', kind: JourneyNodeKind.milestone),
            node('mi1', parentId: 'm1', kind: JourneyNodeKind.mission),
            node('s1', parentId: 'mi1'),
            node('t1', parentId: 's1', kind: JourneyNodeKind.task),
          ],
        ),
      );

      final loaded = (await repo.loadAll()).single;
      expect(loaded.nodes, hasLength(4));
      expect(loaded.rootNodes.map((n) => n.id), ['m1']);
      expect(loaded.childrenOf('m1').map((n) => n.id), ['mi1']);
      expect(loaded.childrenOf('mi1').map((n) => n.id), ['s1']);
      expect(loaded.childrenOf('s1').map((n) => n.id), ['t1']);
      expect(loaded.orphanNodes, isEmpty);
    });

    test('carries derived completion and reason codes', () async {
      await repo.save(
        journey(
          nodes: [
            node(
              's1',
              completion: JourneyCompletion.derived,
              metric: 'orders',
              target: 50,
              reasons: const ['goal.behind_pace', 'profile.channel_shopee'],
            ),
          ],
        ),
      );

      final n = (await repo.loadAll()).single.nodes.single;
      expect(n.completion, JourneyCompletion.derived);
      expect(n.derivedMetric, 'orders');
      expect(n.derivedTarget, 50);
      expect(n.reasonCodes, ['goal.behind_pace', 'profile.channel_shopee']);
    });

    test('keeps every plan version, newest does not erase older', () async {
      await repo.save(
        journey(
          activePlanVersion: 2,
          plans: [
            JourneyPlan(
              version: 1,
              generatedBy: JourneyNodeOrigin.ruleTwin,
              generatedAt: DateTime(2026, 7, 1),
              reasonCodes: const ['goal.new'],
            ),
            JourneyPlan(
              version: 2,
              generatedBy: JourneyNodeOrigin.ruleTwin,
              generatedAt: DateTime(2026, 8, 1),
              reasonCodes: const ['goal.behind_pace'],
            ),
          ],
        ),
      );

      final loaded = (await repo.loadAll()).single;
      expect(loaded.plans.map((p) => p.version), containsAll([1, 2]));
      expect(loaded.activePlanVersion, 2);
    });

    test('saving again replaces the tree instead of duplicating it', () async {
      await repo.save(journey(nodes: [node('a'), node('b')]));
      await repo.save(journey(nodes: [node('c')]));

      final loaded = (await repo.loadAll()).single;
      expect(loaded.nodes.map((n) => n.id), ['c']);
    });
  });

  group('ordering', () {
    test('nodes come back in orderIndex order', () async {
      await repo.save(
        journey(
          nodes: [
            node('third', order: 3),
            node('first', order: 1),
            node('second', order: 2),
          ],
        ),
      );
      expect((await repo.loadAll()).single.rootNodes.map((n) => n.id), [
        'first',
        'second',
        'third',
      ]);
    });

    test('a tie on orderIndex is broken by id, stably', () async {
      // Without a tiebreak the plan would appear to shuffle itself between
      // reads — which reads as the app changing the plan behind the seller.
      await repo.save(
        journey(nodes: [node('b', order: 1), node('a', order: 1)]),
      );
      final first = (await repo.loadAll()).single.rootNodes.map((n) => n.id);
      final second = (await repo.loadAll()).single.rootNodes.map((n) => n.id);
      expect(first, ['a', 'b']);
      expect(second, first);
    });
  });

  group('the ADR-TON-016 invariants survive the database', () {
    test('an AI node marked done is dropped on read', () async {
      // Constructor asserts are compiled out in release, so the guard has to
      // exist at the read boundary too — a hand-edited or corrupted database
      // must not be able to present an AI-authored completed step as fact.
      await repo.save(
        journey(
          nodes: [
            node('root'),
            node('s1', parentId: 'root'),
          ],
        ),
      );
      await db.customStatement(
        "UPDATE business_journey_nodes_table "
        "SET origin = 'ai', state = 'done' WHERE id = 's1'",
      );
      expect((await repo.loadAll()).single.nodes.map((n) => n.id), ['root']);
    });

    test('an orphan AI node is dropped on read', () async {
      await repo.save(journey(nodes: [node('s1')]));
      await db.customStatement(
        "UPDATE business_journey_nodes_table SET origin = 'ai' WHERE id = 's1'",
      );
      expect((await repo.loadAll()).single.nodes, isEmpty);
    });

    test('an AI node under a parent is kept', () async {
      await repo.save(
        journey(
          nodes: [
            node('root'),
            node('ai1', parentId: 'root', origin: JourneyNodeOrigin.ai),
          ],
        ),
      );
      final ids = (await repo.loadAll()).single.nodes.map((n) => n.id);
      expect(ids, containsAll(['root', 'ai1']));
    });
  });

  group('unknown codes', () {
    test('an unknown node kind drops the node, keeps the rest', () async {
      await repo.save(journey(nodes: [node('a'), node('b')]));
      await db.customStatement(
        "UPDATE business_journey_nodes_table "
        "SET kind = 'quantum_widget' WHERE id = 'a'",
      );
      expect((await repo.loadAll()).single.nodes.map((n) => n.id), ['b']);
    });

    test('an unknown journey state drops the journey', () async {
      await repo.save(journey());
      await db.customStatement(
        "UPDATE business_journeys_table SET state = 'schrodinger'",
      );
      expect(await repo.loadAll(), isEmpty);
    });
  });

  group('one active journey', () {
    test('loadActive finds the active one among paused ones', () async {
      await repo.save(journey(state: JourneyState.active));
      await repo.save(
        Journey(
          id: 'j2',
          goalId: 'g2',
          state: JourneyState.paused,
          createdAt: DateTime(2026, 7, 1),
          updatedAt: DateTime(2026, 7, 1),
        ),
      );
      expect((await repo.loadActive())!.id, 'j1');
      expect(
        await repo.loadAll(),
        hasLength(2),
        reason: 'pausing goal A to run goal B must not delete anything',
      );
    });
  });

  group('completion', () {
    test('is null when there is no plan — not zero', () async {
      // "No plan yet" and "no progress yet" are different answers, and a
      // seller deserves to know which one they are looking at.
      await repo.save(journey());
      expect((await repo.loadAll()).single.completion, isNull);
    });

    test(
      'counts leaves only, so a done parent does not double-count',
      () async {
        await repo.save(
          journey(
            nodes: [
              node('m1', kind: JourneyNodeKind.milestone),
              node('s1', parentId: 'm1', state: JourneyNodeState.done),
              node('s2', parentId: 'm1'),
            ],
          ),
        );
        expect((await repo.loadAll()).single.completion, 0.5);
      },
    );
  });

  group('deleteAll', () {
    test('removes journeys, nodes and plans', () async {
      await repo.save(
        journey(
          nodes: [node('a')],
          plans: [
            JourneyPlan(
              version: 1,
              generatedBy: JourneyNodeOrigin.ruleTwin,
              generatedAt: DateTime(2026, 8, 1),
            ),
          ],
        ),
      );
      await repo.deleteAll();
      expect(await repo.loadAll(), isEmpty);
      expect(
        await db.select(db.businessJourneyNodesTable).get(),
        isEmpty,
        reason: 'a restore must not leave the old business\'s steps behind',
      );
    });
  });

  group('backup compatibility (protects every .ttbk that already exists)', () {
    test('journeys is NOT a required dataset', () {
      // BackupService rejects a package missing any required dataset. Putting
      // journeys in `all` would make every backup written before schema v9
      // unrestorable — an additive feature causing a data-loss-shaped bug.
      // Exactly the trap WTM-177 found.
      expect(BackupDatasets.all, isNot(contains(BackupDatasets.journeys)));
      expect(BackupDatasets.optional, contains(BackupDatasets.journeys));
    });

    test('the required list is still exactly the original six', () {
      expect(BackupDatasets.all, hasLength(6));
    });

    test('a journey round-trips through the codec whole', () {
      final original = Journey(
        id: 'j1',
        goalId: 'g1',
        state: JourneyState.active,
        activePlanVersion: 2,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 2),
        nodes: [
          node('m1', kind: JourneyNodeKind.milestone),
          node('s1', parentId: 'm1'),
        ],
        plans: [
          JourneyPlan(
            version: 1,
            generatedBy: JourneyNodeOrigin.ruleTwin,
            generatedAt: DateTime(2026, 7, 1),
            reasonCodes: const ['goal.new'],
          ),
        ],
      );
      final back = BackupCodec.decodeJourney(
        BackupCodec.encodeJourney(original),
      )!;
      expect(back.id, 'j1');
      expect(back.state, JourneyState.active);
      expect(back.activePlanVersion, 2);
      expect(back.nodes, hasLength(2));
      expect(back.plans.single.reasonCodes, ['goal.new']);
    });

    test('a journey with an unreadable state is dropped whole', () {
      final json = BackupCodec.encodeJourney(
        Journey(
          id: 'j1',
          goalId: 'g1',
          state: JourneyState.active,
          createdAt: DateTime(2026, 8, 1),
          updatedAt: DateTime(2026, 8, 1),
        ),
      )..['state'] = 'schrodinger';
      expect(BackupCodec.decodeJourney(json), isNull);
    });

    test('a tree is one record, so it cannot arrive half-restored', () {
      // Split across three datasets, a partial restore could leave a plan with
      // no steps — worse than no plan, because it looks complete.
      final json = BackupCodec.encodeJourney(
        Journey(
          id: 'j1',
          goalId: 'g1',
          state: JourneyState.active,
          createdAt: DateTime(2026, 8, 1),
          updatedAt: DateTime(2026, 8, 1),
          nodes: [
            node('a'),
            node('b', parentId: 'a'),
          ],
        ),
      );
      expect(json['nodes'], hasLength(2));
    });
  });
}
