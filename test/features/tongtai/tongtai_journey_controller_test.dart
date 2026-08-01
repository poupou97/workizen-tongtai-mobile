import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/journey_controller.dart';
import 'package:tongtai/features/tongtai/journey/journey_node.dart';
import 'package:tongtai/features/tongtai/journey/journey_planner.dart';
import 'package:tongtai/features/tongtai/journey/journey_repository.dart';
import 'package:tongtai/features/tongtai/profile/business_profile.dart';

/// WTM-186 (J2) — planner wired to a real database.
void main() {
  late Directory dir;
  late AppDatabase db;
  late JourneyRepository repo;
  late JourneyController controller;

  final now = DateTime(2026, 8, 1, 12);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('tongtai_journey_ctl');
    db = AppDatabase.forExecutor(NativeDatabase(File('${dir.path}/t.sqlite')));
    repo = JourneyRepository(db);
    controller = JourneyController(repo, clock: () => now);
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  BusinessGoal goal({GoalType type = GoalType.revenue}) => BusinessGoal(
    id: 'g1',
    name: 'Mục tiêu',
    type: type,
    targetAmount: 50000000,
    achievedAmount: 0,
    growthTarget: 20,
    growthAchieved: 0,
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2026, 12, 31),
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );

  JourneyPlanInput input({
    GoalType type = GoalType.revenue,
    BusinessProfile profile = BusinessProfile.empty,
    int products = 10,
    int customers = 5,
  }) => JourneyPlanInput(
    goal: goal(type: type),
    profile: profile,
    productCount: products,
    customerCount: customers,
    orderCount: 3,
  );

  group('starting a journey', () {
    test('plans, saves, and reads back whole', () async {
      final journey = await controller.startJourney(input(), journeyId: 'j1');
      expect(journey, isNotNull);

      final loaded = (await repo.loadAll()).single;
      expect(loaded.id, 'j1');
      expect(loaded.goalId, 'g1');
      expect(loaded.state, JourneyState.active);
      expect(loaded.activePlanVersion, 1);
      expect(loaded.nodes, isNotEmpty);
      expect(loaded.plans.single.version, 1);
      expect(loaded.plans.single.generatedBy, JourneyNodeOrigin.ruleTwin);
      expect(loaded.orphanNodes, isEmpty);
    });

    test('refuses for a business with nothing in it — and saves nothing', () {
      // An empty journey on screen is worse than an honest empty state: it
      // looks like the app tried and had nothing to say.
      return expectLater(
        controller
            .startJourney(input(products: 0, customers: 0), journeyId: 'j1')
            .then((j) async {
              expect(j, isNull);
              expect(await repo.loadAll(), isEmpty);
            }),
        completes,
      );
    });

    test('the plan carries the reasons that shaped it', () async {
      final journey = await controller.startJourney(
        input(profile: const BusinessProfile(trade: BusinessTrade.food)),
        journeyId: 'j1',
      );
      expect(
        journey!.plans.single.reasonCodes,
        contains(JourneyReason.profileKnown),
      );
    });
  });

  group('re-planning', () {
    test('adds a version instead of overwriting the old one', () async {
      final first = await controller.startJourney(input(), journeyId: 'j1');
      final second = await controller.replan(first!, input());

      expect(second!.activePlanVersion, 2);
      final loaded = (await repo.loadAll()).single;
      expect(
        loaded.plans.map((p) => p.version),
        containsAll([1, 2]),
        reason: 'the old plan is the only evidence that the plan changed',
      );
    });

    test('a finished step stays finished across a re-plan', () async {
      // Regenerating the plan must not quietly undo work the seller did.
      var journey = (await controller.startJourney(input(), journeyId: 'j1'))!;
      final target = journey.nodes.firstWhere(
        (n) => n.kind == JourneyNodeKind.step,
      );
      journey = await controller.complete(journey, target.id);

      final replanned = await controller.replan(journey, input());
      final same = replanned!.nodes.where((n) => n.title == target.title);
      expect(same, isNotEmpty);
      expect(same.every((n) => n.isDone), isTrue);
    });

    test('node ids do not collide across versions', () async {
      final first = await controller.startJourney(input(), journeyId: 'j1');
      final second = await controller.replan(first!, input());
      expect(
        second!.nodes.map((n) => n.id).toSet(),
        hasLength(second.nodes.length),
      );
    });
  });

  group('completing by hand', () {
    test('marks the node done and stamps the time', () async {
      var journey = (await controller.startJourney(input(), journeyId: 'j1'))!;
      final node = journey.nodes.first;
      journey = await controller.complete(journey, node.id);

      final loaded = (await repo.loadAll()).single;
      final updated = loaded.nodes.firstWhere((n) => n.id == node.id);
      expect(updated.isDone, isTrue);
      expect(updated.completedAt, now);
    });

    test('refuses to complete an AI-authored node', () async {
      // ADR-TON-016 at the write path: a model proposes, a person completes.
      var journey = (await controller.startJourney(input(), journeyId: 'j1'))!;
      final root = journey.nodes.firstWhere((n) => n.parentId == null);
      final suggestion = JourneyNode(
        id: 'ai-1',
        journeyId: journey.id,
        parentId: root.id,
        kind: JourneyNodeKind.task,
        title: 'AI đề xuất',
        origin: JourneyNodeOrigin.ai,
      );
      journey = journey.copyWith(nodes: [...journey.nodes, suggestion]);
      await repo.save(journey);

      journey = await controller.complete(journey, 'ai-1');
      expect(journey.nodes.firstWhere((n) => n.id == 'ai-1').isDone, isFalse);
    });
  });

  group('derived steps answer "am I on track", not "what did I tick"', () {
    test('a measured step completes itself from the real number', () async {
      var journey = (await controller.startJourney(input(), journeyId: 'j1'))!;
      final measured = journey.nodes.firstWhere(
        (n) => n.completion == JourneyCompletion.derived,
      );

      journey = await controller.refreshDerived(journey, {
        measured.derivedMetric!: measured.derivedTarget! + 1,
      });

      expect(
        journey.nodes.firstWhere((n) => n.id == measured.id).isDone,
        isTrue,
      );
    });

    test('below target it stays open', () async {
      var journey = (await controller.startJourney(input(), journeyId: 'j1'))!;
      final measured = journey.nodes.firstWhere(
        (n) => n.completion == JourneyCompletion.derived,
      );

      journey = await controller.refreshDerived(journey, {
        measured.derivedMetric!: measured.derivedTarget! - 1,
      });

      expect(
        journey.nodes.firstWhere((n) => n.id == measured.id).isDone,
        isFalse,
      );
    });

    test('a metric that dips does not un-finish completed work', () async {
      // A refund or a corrected entry must not take a milestone back off the
      // seller — that would read as the app forgetting what they achieved.
      var journey = (await controller.startJourney(input(), journeyId: 'j1'))!;
      final measured = journey.nodes.firstWhere(
        (n) => n.completion == JourneyCompletion.derived,
      );

      journey = await controller.refreshDerived(journey, {
        measured.derivedMetric!: measured.derivedTarget! + 10,
      });
      journey = await controller.refreshDerived(journey, {
        measured.derivedMetric!: 0,
      });

      expect(
        journey.nodes.firstWhere((n) => n.id == measured.id).isDone,
        isTrue,
      );
    });

    test('nothing to change means no write', () async {
      final journey = (await controller.startJourney(
        input(),
        journeyId: 'j1',
      ))!;
      final again = await controller.refreshDerived(journey, const {});
      expect(identical(again, journey), isTrue);
    });

    test('manual steps are never completed by a metric', () async {
      var journey = (await controller.startJourney(input(), journeyId: 'j1'))!;
      final manual = journey.nodes.firstWhere(
        (n) => n.completion == JourneyCompletion.manual,
      );
      journey = await controller.refreshDerived(journey, {
        'revenue': 999999999,
        'customers': 999999,
        'products': 999999,
      });
      expect(
        journey.nodes.firstWhere((n) => n.id == manual.id).isDone,
        isFalse,
      );
    });
  });
}
