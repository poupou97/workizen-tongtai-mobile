import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/journey.dart';
import 'package:tongtai/features/tongtai/journey/journey_controller.dart';
import 'package:tongtai/features/tongtai/journey/journey_node.dart';
import 'package:tongtai/features/tongtai/journey/journey_planner.dart';
import 'package:tongtai/features/tongtai/journey/journey_repository.dart';

/// WTM-191 (O-4) — an opportunity the seller decides to chase becomes work.
///
/// Audit WTM-189 found `interested` was a dead end: the feed recorded the
/// decision and nothing downstream ever used it. These tests are about the
/// edge that closes that loop, and about the one way it could quietly betray
/// the seller — a re-plan deleting what they chose.
void main() {
  late Directory dir;
  late File file;
  late AppDatabase db;
  late JourneyRepository repo;
  late JourneyController controller;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('tongtai_opp_journey');
    file = File('${dir.path}/t.sqlite');
    db = AppDatabase.forExecutor(NativeDatabase(file));
    repo = JourneyRepository(db);
    controller = JourneyController(repo, clock: () => DateTime(2026, 8, 1));
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  JourneyPlanInput input({int products = 10, int orders = 3}) =>
      JourneyPlanInput(
        goal: BusinessGoal(
          id: 'g1',
          name: 'Mục tiêu',
          type: GoalType.revenue,
          targetAmount: 50000000,
          achievedAmount: 0,
          growthTarget: 20,
          growthAchieved: 0,
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 12, 31),
          createdAt: DateTime(2026, 8, 1),
          updatedAt: DateTime(2026, 8, 1),
        ),
        productCount: products,
        customerCount: 5,
        orderCount: orders,
      );

  Future<Journey> start() async =>
      (await controller.startJourney(input(), journeyId: 'j1'))!;

  test(
    'an opportunity becomes a pending mission authored by the seller',
    () async {
      final journey = await controller.addFromOpportunity(
        await start(),
        opportunityId: 'opp-1',
        title: 'Nhập lại quạt mini',
        nodeId: 'n-opp-1',
      );

      final node = journey.nodes.firstWhere((n) => n.id == 'n-opp-1');
      expect(node.sourceOpportunityId, 'opp-1');
      expect(
        node.origin,
        JourneyNodeOrigin.user,
        reason: 'a model may describe an opportunity; only a person chases one',
      );
      expect(
        node.state,
        JourneyNodeState.pending,
        reason: 'committing to work is not doing it',
      );
      expect(node.isRoot, isTrue);
    },
  );

  test('the link survives closing and reopening the app', () async {
    await controller.addFromOpportunity(
      await start(),
      opportunityId: 'opp-1',
      title: 'Nhập lại quạt mini',
      nodeId: 'n-opp-1',
    );
    await db.close();

    final reopened = AppDatabase.forExecutor(NativeDatabase(file));
    addTearDown(reopened.close);
    final loaded = (await JourneyRepository(reopened).loadAll()).single;

    expect(
      loaded.nodes.firstWhere((n) => n.id == 'n-opp-1').sourceOpportunityId,
      'opp-1',
    );
  });

  test('adding the same opportunity twice does not duplicate it', () async {
    var journey = await controller.addFromOpportunity(
      await start(),
      opportunityId: 'opp-1',
      title: 'Nhập lại quạt mini',
      nodeId: 'n-opp-1',
    );
    journey = await controller.addFromOpportunity(
      journey,
      opportunityId: 'opp-1',
      title: 'Nhập lại quạt mini',
      nodeId: 'n-opp-2',
    );

    expect(
      journey.nodes.where((n) => n.sourceOpportunityId == 'opp-1'),
      hasLength(1),
    );
  });

  group('re-planning', () {
    test('does not delete what the seller committed to', () async {
      // The rules own the plan. A commitment is a decision, and re-planning is
      // not a licence to delete decisions.
      var journey = await controller.addFromOpportunity(
        await start(),
        opportunityId: 'opp-1',
        title: 'Nhập lại quạt mini',
        nodeId: 'n-opp-1',
      );

      journey = (await controller.replan(journey, input(products: 40)))!;

      final kept = journey.nodes.where((n) => n.id == 'n-opp-1');
      expect(kept, hasLength(1));
      expect(kept.single.sourceOpportunityId, 'opp-1');
    });

    test(
      'keeps the work underneath a commitment, not just the header',
      () async {
        var journey = await controller.addFromOpportunity(
          await start(),
          opportunityId: 'opp-1',
          title: 'Nhập lại quạt mini',
          nodeId: 'n-opp-1',
        );
        // A child the seller added under their own commitment.
        journey = journey.copyWith(
          nodes: [
            ...journey.nodes,
            JourneyNode(
              id: 'n-opp-1-a',
              journeyId: journey.id,
              parentId: 'n-opp-1',
              kind: JourneyNodeKind.step,
              title: 'Gọi nhà cung cấp',
              origin: JourneyNodeOrigin.user,
            ),
          ],
        );
        await repo.save(journey);

        journey = (await controller.replan(journey, input(products: 40)))!;

        expect(journey.nodes.map((n) => n.id), contains('n-opp-1-a'));
      },
    );

    test('still replaces the plan the rules own', () async {
      final before = await start();
      final planned = before.nodes.length;

      final after = (await controller.replan(before, input(products: 40)))!;

      expect(after.activePlanVersion, 2);
      expect(
        after.nodes.where((n) => n.origin == JourneyNodeOrigin.ruleTwin),
        isNotEmpty,
      );
      expect(planned, greaterThan(0));
    });

    test('a completed commitment stays completed', () async {
      var journey = await controller.addFromOpportunity(
        await start(),
        opportunityId: 'opp-1',
        title: 'Nhập lại quạt mini',
        nodeId: 'n-opp-1',
      );
      journey = await controller.complete(journey, 'n-opp-1');

      journey = (await controller.replan(journey, input(products: 40)))!;

      expect(journey.nodes.firstWhere((n) => n.id == 'n-opp-1').isDone, isTrue);
    });
  });

  test('a dangling opportunity id does not break loading', () async {
    // The rule engine stops generating an opportunity when the business data
    // changes. The work the seller committed to must survive that.
    await controller.addFromOpportunity(
      await start(),
      opportunityId: 'opp-that-vanishes',
      title: 'Việc vẫn còn',
      nodeId: 'n-opp-1',
    );

    final loaded = (await repo.loadAll()).single;

    expect(
      loaded.nodes.firstWhere((n) => n.id == 'n-opp-1').title,
      'Việc vẫn còn',
    );
  });
}
