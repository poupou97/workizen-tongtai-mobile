import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_controller.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_form.dart';

/// Unit tests for the WTM-87 Business Goal domain:
///  - AC1: form validation (name, at-least-one-target, numeric, timeline)
///  - AC2: templates seed the form per business type
///  - AC3: edit round-trip preserves identity + createdAt
///  - AC4: progress / timeline / pace math
///  - AC5: rule-based recommendations per pace, bilingual
void main() {
  BusinessGoal goal({
    double target = 100000000,
    double achieved = 0,
    int growthTarget = 0,
    int growthAchieved = 0,
    DateTime? start,
    DateTime? end,
  }) => BusinessGoal(
    id: 'g1',
    name: 'Đạt 100 triệu',
    type: GoalType.revenue,
    targetAmount: target,
    achievedAmount: achieved,
    growthTarget: growthTarget,
    growthAchieved: growthAchieved,
    startDate: start ?? DateTime(2026, 7, 1),
    endDate: end ?? DateTime(2026, 7, 31),
    createdAt: DateTime(2026, 7, 1),
    updatedAt: DateTime(2026, 7, 1),
  );

  group('progress + pace (AC4)', () {
    test('revenue-based progress, clamped at 1', () {
      expect(goal(achieved: 50000000).progress, 0.5);
      expect(goal(achieved: 150000000).progress, 1.0);
    });

    test('falls back to the growth metric when no revenue target', () {
      final g = goal(target: 0, growthTarget: 100, growthAchieved: 30);
      expect(g.progress, 0.3);
    });

    test(
      'timelineElapsed is 0 before start, 1 after end, fractional inside',
      () {
        final g = goal(start: DateTime(2026, 7, 1), end: DateTime(2026, 7, 31));
        expect(g.timelineElapsed(DateTime(2026, 6, 30)), 0);
        expect(g.timelineElapsed(DateTime(2026, 8, 1)), 1);
        expect(g.timelineElapsed(DateTime(2026, 7, 16)), closeTo(0.5, 0.01));
      },
    );

    test('daysRemaining never goes negative', () {
      final g = goal(end: DateTime(2026, 7, 31));
      expect(g.daysRemaining(DateTime(2026, 7, 21)), 10);
      expect(g.daysRemaining(DateTime(2026, 9, 1)), 0);
    });

    test('pace: completed / notStarted / ahead / onTrack / behind', () {
      final mid = DateTime(2026, 7, 16); // ~50% elapsed
      expect(goal(achieved: 100000000).pace(mid), GoalPace.completed);
      expect(goal().pace(DateTime(2026, 6, 15)), GoalPace.notStarted);
      expect(goal(achieved: 70000000).pace(mid), GoalPace.ahead); // 70% > 60%
      expect(goal(achieved: 50000000).pace(mid), GoalPace.onTrack);
      expect(goal(achieved: 30000000).pace(mid), GoalPace.behind); // 30% < 40%
    });
  });

  group('recommendations (AC5)', () {
    final mid = DateTime(2026, 7, 16);

    test('every pace produces non-empty bilingual advice', () {
      final cases = {
        GoalPace.completed: goal(achieved: 100000000),
        GoalPace.ahead: goal(achieved: 70000000),
        GoalPace.onTrack: goal(achieved: 50000000),
        GoalPace.behind: goal(achieved: 30000000),
      };
      cases.forEach((pace, g) {
        expect(g.pace(mid), pace);
        expect(g.recommendation(mid), isNotEmpty);
        expect(g.recommendation(mid, languageCode: 'en'), isNotEmpty);
        expect(
          g.recommendation(mid),
          isNot(g.recommendation(mid, languageCode: 'en')),
          reason: 'VI and EN advice must be real translations',
        );
      });
    });

    test('behind-schedule advice cites the actual numbers', () {
      final g = goal(achieved: 30000000);
      expect(g.recommendation(mid), contains('30%'));
      expect(g.recommendation(mid), contains('50%'));
    });
  });

  group('templates (AC2)', () {
    test('one template per goal type, all fields plausible', () {
      final types = kTongtaiGoalTemplates.map((t) => t.type).toSet();
      expect(types, GoalType.values.toSet());
      for (final t in kTongtaiGoalTemplates) {
        expect(t.nameVi, isNotEmpty);
        expect(t.nameEn, isNotEmpty);
        expect(t.suggestedDays, greaterThan(0));
        expect(t.suggestedGrowthTarget, greaterThan(0));
      }
    });

    test(
      'fromTemplate seeds name, type, targets and a day-aligned timeline',
      () {
        final template = kTongtaiGoalTemplates.first; // revenue
        final data = GoalFormData.fromTemplate(
          template,
          DateTime(2026, 7, 22, 15, 30),
        );
        expect(data.name, template.nameVi);
        expect(data.type, GoalType.revenue);
        expect(data.targetAmountText, '100000000');
        expect(data.growthTargetText, '200');
        expect(data.startDate, DateTime(2026, 7, 22)); // midnight-aligned
        expect(
          data.endDate,
          DateTime(2026, 7, 22).add(const Duration(days: 90)),
        );
        expect(data.isValid, isTrue);
      },
    );

    test('a no-revenue template leaves the amount blank and stays valid', () {
      final template = kTongtaiGoalTemplates.firstWhere(
        (t) => t.type == GoalType.customerGrowth,
      );
      final data = GoalFormData.fromTemplate(template, DateTime(2026, 7, 22));
      expect(data.targetAmountText, isEmpty);
      expect(data.isValid, isTrue); // growth target carries the goal
    });
  });

  group('GoalFormData.validate (AC1)', () {
    GoalFormData valid() => GoalFormData(
      name: 'Mục tiêu',
      targetAmountText: '100000000',
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 31),
    );

    test('a fully-filled form passes', () {
      expect(valid().validate(), isEmpty);
    });

    test('name is required', () {
      final errors = valid().copyWith(name: '  ').validate();
      expect(errors[GoalField.name], isNotNull);
    });

    test('at least one target (revenue or metric) is required', () {
      final errors = valid().copyWith(targetAmountText: '').validate();
      expect(errors[GoalField.targetAmount], isNotNull);

      final withGrowth = valid().copyWith(
        targetAmountText: '',
        growthTargetText: '100',
      );
      expect(withGrowth.validate(), isEmpty);
    });

    test('numeric fields reject junk and negatives', () {
      expect(
        valid()
            .copyWith(targetAmountText: 'abc')
            .validate()[GoalField.targetAmount],
        isNotNull,
      );
      expect(
        valid()
            .copyWith(growthTargetText: '-5')
            .validate()[GoalField.growthTarget],
        isNotNull,
      );
    });

    test('timeline requires both dates and end after start', () {
      final missing = GoalFormData(
        name: 'X',
        targetAmountText: '1000',
        startDate: DateTime(2026, 7, 1),
      );
      expect(missing.validate()[GoalField.timeline], isNotNull);

      final inverted = valid().copyWith(
        startDate: DateTime(2026, 7, 31),
        endDate: DateTime(2026, 7, 1),
      );
      expect(inverted.validate()[GoalField.timeline], isNotNull);
    });
  });

  group('edit round-trip (AC3)', () {
    test('fromGoal → toGoal preserves id, createdAt and every field', () {
      final original = goal(achieved: 62000000);
      final data = GoalFormData.fromGoal(original);
      final edited = data
          .copyWith(achievedAmountText: '75000000')
          .toGoal(
            id: original.id,
            now: DateTime(2026, 7, 23),
            createdAt: original.createdAt,
          );

      expect(edited.id, original.id);
      expect(edited.createdAt, original.createdAt);
      expect(edited.updatedAt, DateTime(2026, 7, 23));
      expect(edited.achievedAmount, 75000000);
      expect(edited.name, original.name);
      expect(edited.startDate, original.startDate);
      expect(edited.endDate, original.endDate);
    });
  });

  group('BusinessGoalController', () {
    test('upsert appends new goals and replaces edits, notifying', () {
      final controller = BusinessGoalController([goal()]);
      var notified = 0;
      controller.addListener(() => notified++);

      final added = controller.upsert(
        goal().copyWith(name: 'Khác', updatedAt: DateTime(2026, 7, 23)),
      );
      // Same id 'g1' → replace.
      expect(added, isTrue);
      expect(controller.count, 1);
      expect(notified, 1);
      expect(controller.goals.single.name, 'Khác');
    });

    test('goals sort newest-updated first', () {
      final a = BusinessGoal(
        id: 'a',
        name: 'A',
        type: GoalType.revenue,
        targetAmount: 1000,
        achievedAmount: 0,
        growthTarget: 0,
        growthAchieved: 0,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
        createdAt: DateTime(2026, 7, 1),
        updatedAt: DateTime(2026, 7, 10),
      );
      final b = BusinessGoal(
        id: 'b',
        name: 'B',
        type: GoalType.revenue,
        targetAmount: 1000,
        achievedAmount: 0,
        growthTarget: 0,
        growthAchieved: 0,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
        createdAt: DateTime(2026, 7, 1),
        updatedAt: DateTime(2026, 7, 20),
      );
      final controller = BusinessGoalController([a, b]);
      expect(controller.goals.map((g) => g.id), ['b', 'a']);
    });

    test('sample goals are well-formed', () {
      for (final g in kSampleBusinessGoals) {
        expect(g.name, isNotEmpty);
        expect(g.endDate.isAfter(g.startDate), isTrue);
        expect(g.progress, inInclusiveRange(0, 1));
      }
    });
  });
}
