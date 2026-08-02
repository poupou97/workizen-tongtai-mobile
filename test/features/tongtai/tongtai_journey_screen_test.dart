import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/journey.dart';
import 'package:tongtai/features/tongtai/journey/journey_controller.dart';
import 'package:tongtai/features/tongtai/journey/journey_node.dart';
import 'package:tongtai/features/tongtai/journey/journey_planner.dart';
import 'package:tongtai/features/tongtai/journey/journey_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/ui/screens/tongtai_journey_screen.dart';

import '../../support/tap_by_key.dart';

/// WTM-187 (J3) — the journey screen, against a real database.
void main() {
  late Directory dir;
  late AppDatabase db;
  late JourneyRepository repo;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('tongtai_journey_screen');
    db = AppDatabase.forExecutor(NativeDatabase(File('${dir.path}/t.sqlite')));
    repo = JourneyRepository(db);
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  Widget host(String locale) => ProviderScope(
    overrides: [tongtaiDatabaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('vi')],
      home: const TongtaiJourneyScreen(),
    ),
  );

  Future<Journey> seedRealJourney() async {
    // Built by the real planner, not by hand: a screen test that invents its
    // own tree can pass while the thing users actually get is broken.
    final controller = JourneyController(
      repo,
      clock: () => DateTime(2026, 8, 1),
    );
    return (await controller.startJourney(
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
        productCount: 10,
        customerCount: 5,
        orderCount: 3,
      ),
      journeyId: 'j1',
    ))!;
  }

  for (final locale in ['vi', 'en']) {
    testWidgets('[$locale] no journey yet shows empty, not an error', (
      tester,
    ) async {
      await tester.pumpWidget(host(locale));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('journey-empty-message')), findsOneWidget);
      expect(find.byKey(const Key('journey-error')), findsNothing);
    });

    testWidgets('[$locale] a real plan renders as a tiered list', (
      tester,
    ) async {
      // Khung hình cao: kế hoạch dài thêm một mốc (WTM-235 thêm mốc chi phí
      // đầu vào) là mốc cuối rơi khỏi vùng ListView dựng sẵn, và test đọc ra
      // "màn hỏng" trong khi màn vẫn đúng (P-26).
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 3600);
      final journey = await seedRealJourney();
      await tester.pumpWidget(host(locale));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('journey-list')), findsOneWidget);
      for (final milestone in journey.rootNodes) {
        expect(
          find.byKey(Key('journey-milestone-${milestone.id}')),
          findsOneWidget,
        );
      }
    });
  }

  testWidgets('a journey with no plan says insufficient, not empty', (
    tester,
  ) async {
    // "No journey" and "a journey that cannot be planned yet" are different
    // answers, and conflating them tells the seller nothing about what to do.
    await repo.save(
      Journey(
        id: 'j1',
        goalId: 'g1',
        state: JourneyState.active,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      ),
    );
    await tester.pumpWidget(host('vi'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('journey-insufficient-message')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('journey-empty-message')), findsNothing);
  });

  testWidgets('every rule-authored step says so', (tester) async {
    // ADR-TON-016 is invisible unless the seller can see which parts of the
    // plan they decided and which the app proposed.
    final journey = await seedRealJourney();
    await tester.pumpWidget(host('vi'));
    await tester.pumpAndSettle();

    final step = journey.nodes.firstWhere(
      (n) => n.kind == JourneyNodeKind.step,
    );
    await tester.scrollToKey(
      'journey-step-origin-${step.id}',
      under: 'journey-list',
    );
    expect(find.byKey(Key('journey-step-origin-${step.id}')), findsOneWidget);
  });

  testWidgets('a measured step is labelled as measured', (tester) async {
    final journey = await seedRealJourney();
    await tester.pumpWidget(host('vi'));
    await tester.pumpAndSettle();

    final measured = journey.nodes.firstWhere(
      (n) => n.completion == JourneyCompletion.derived,
    );
    await tester.scrollToKey(
      'journey-step-measured-${measured.id}',
      under: 'journey-list',
    );
    expect(
      find.byKey(Key('journey-step-measured-${measured.id}')),
      findsOneWidget,
    );
  });

  testWidgets('progress reflects the real completion, not a guess', (
    tester,
  ) async {
    var journey = await seedRealJourney();
    final controller = JourneyController(
      repo,
      clock: () => DateTime(2026, 8, 2),
    );
    final leaf = journey.nodes.firstWhere(
      (n) => n.kind == JourneyNodeKind.step,
    );
    journey = await controller.complete(journey, leaf.id);

    await tester.pumpWidget(host('vi'));
    await tester.pumpAndSettle();

    final label = tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(const Key('journey-progress')),
            matching: find.byType(Text),
          ),
        )
        .data!;
    final expected = (journey.completion! * 100).round();
    expect(label, contains('$expected%'));
  });

  testWidgets('WTM-191: a commitment from an opportunity says so', (
    tester,
  ) async {
    // Without the label it reads as one of the rules' own milestones, and the
    // seller loses the one thing that makes ADR-TON-016 visible: who decided.
    final journey = await seedRealJourney();
    final controller = JourneyController(
      repo,
      clock: () => DateTime(2026, 8, 2),
    );
    await controller.addFromOpportunity(
      journey,
      opportunityId: 'opp-1',
      title: 'Nhập lại quạt mini',
      nodeId: 'n-opp-1',
    );

    await tester.pumpWidget(host('vi'));
    await tester.pumpAndSettle();

    await tester.scrollToKey(
      'journey-milestone-source-n-opp-1',
      under: 'journey-list',
    );
    expect(
      find.byKey(const Key('journey-milestone-source-n-opp-1')),
      findsOneWidget,
    );
  });
}
