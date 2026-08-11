import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/agent/business_brief.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/onboarding/first_insight.dart';
import 'package:tongtai/features/tongtai/onboarding/first_plan.dart';

/// WTM-355 (S6) + WTM-356 (S7).
///
/// Ba thứ được khoá ở đây:
///
/// 1. **Không CTA chết** — mọi việc trỏ tới một đích trong danh sách đóng.
/// 2. **Không lời hứa lợi nhuận** — không trường nào mang tác động dự kiến.
/// 3. **Không mục tiêu nào là ngõ cụt** — mỗi lựa chọn sinh được ít nhất một
///    việc, trừ *"chỉ khám phá"* vốn cố ý không sinh gì.
void main() {
  const builder = FirstPlanBuilder();

  FirstFinding finding(
    BriefKind kind, {
    String id = 'p1',
    BriefSeverity severity = BriefSeverity.warning,
  }) => FirstFinding(
    kind: kind,
    severity: severity,
    headline: 'Chuyện gì đó về $id',
    reason: 'Vì một lý do đo được',
    ruleCode: 'rule:stock-alert',
    subjectKind: 'product',
    subjectId: id,
  );

  FirstInsight ready(List<FirstFinding> findings) =>
      FirstInsight.ready(findings: findings, snapshot: BusinessSnapshot.none);

  group('mục tiêu ánh xạ 1:1, không méo', () {
    test('bảy mục tiêu tạo goal, một thì không', () {
      final creating = OnboardingGoal.values.where((g) => g.createsGoal);

      expect(creating, hasLength(7));
      expect(OnboardingGoal.justExplore.createsGoal, isFalse);
      expect(OnboardingGoal.justExplore.archetype, isNull);
    });

    test('không hai mục tiêu nào dùng chung một nguyên mẫu', () {
      // Dùng chung nghĩa là một trong hai đang bị ép vào archetype sai, và
      // người bán sẽ nhận kế hoạch nói về chuyện khác.
      final archetypes = [for (final g in OnboardingGoal.values) ?g.archetype];

      expect(archetypes.toSet(), hasLength(archetypes.length));
    });

    test('mọi nguyên mẫu GoalType đều tới được từ onboarding', () {
      final reachable = {for (final g in OnboardingGoal.values) ?g.archetype};

      expect(reachable, GoalType.values.toSet());
    });

    test('nhiều nhất hai mục tiêu', () {
      expect(kMaxOnboardingGoals, 2);
    });
  });

  group('⛔ không CTA chết', () {
    test('mọi việc sinh từ phát hiện đều có đích', () {
      for (final kind in BriefKind.values) {
        final plan = builder.build(
          goals: const [],
          insight: ready([finding(kind)]),
        );

        expect(plan.actions, hasLength(1), reason: '$kind');
        expect(
          PlanDestination.values,
          contains(plan.actions.single.destination),
          reason: '$kind',
        );
      }
    });

    test('mọi mục tiêu tạo-goal sinh được ít nhất một việc', () {
      for (final goal in OnboardingGoal.values) {
        final plan = builder.build(goals: [goal], insight: ready(const []));

        if (goal == OnboardingGoal.justExplore) {
          // Người chọn "chỉ khám phá" không muốn ai giao việc — giao một việc
          // ở đây là không nghe họ nói.
          expect(plan.actions, isEmpty, reason: goal.code);
        } else {
          expect(plan.actions, isNotEmpty, reason: goal.code);
          expect(plan.actions.first.action, isNotEmpty, reason: goal.code);
          expect(plan.actions.first.evidence, isNotEmpty, reason: goal.code);
        }
      }
    });

    test('mỗi việc đủ bốn phần VẤN ĐỀ · BẰNG CHỨNG · HÀNH ĐỘNG · ƯU TIÊN', () {
      final plan = builder.build(
        goals: const [OnboardingGoal.growProfit],
        insight: ready([finding(BriefKind.stockRunningOut)]),
      );

      for (final a in plan.actions) {
        expect(a.problem, isNotEmpty);
        expect(a.evidence, isNotEmpty);
        expect(a.action, isNotEmpty);
        expect(a.priority, greaterThan(0));
      }
      // Ưu tiên tăng dần, không trùng — một danh sách hai việc cùng "ưu tiên 1"
      // không nói được nên làm gì trước.
      final priorities = plan.actions.map((a) => a.priority).toList();
      expect(priorities, priorities.toSet().toList());
      expect(priorities, List.generate(priorities.length, (i) => i + 1));
    });
  });

  group('phát hiện thật đứng trước việc chung', () {
    test('có phát hiện ⇒ việc đầu tiên mang mã luật', () {
      final plan = builder.build(
        goals: const [OnboardingGoal.growProfit],
        insight: ready([finding(BriefKind.stockRunningOut)]),
      );

      expect(plan.actions.first.ruleCode, isNotNull);
      expect(isDeclaredRuleSource(plan.actions.first.ruleCode!), isTrue);
    });

    test('việc sinh từ mục tiêu KHÔNG giả vờ có luật', () {
      final plan = builder.build(
        goals: const [OnboardingGoal.growProfit],
        insight: ready(const []),
      );

      // `null` là câu trả lời đúng: việc này đến từ điều người bán vừa chọn,
      // không từ một quan sát nào.
      expect(plan.actions.single.ruleCode, isNull);
    });

    test('nhiều nhất ba việc', () {
      final plan = builder.build(
        goals: OnboardingGoal.values.take(3).toList(),
        insight: ready([
          finding(BriefKind.stockRunningOut, id: 'p1'),
          finding(BriefKind.marginTooThin, id: 'p2'),
          finding(BriefKind.customerAtRisk, id: 'c1'),
          finding(BriefKind.businessSignal, id: 'b1'),
        ]),
      );

      expect(plan.actions, hasLength(3));
    });
  });

  group('⛔ governance · không lời hứa lợi nhuận', () {
    late String code;

    setUpAll(() {
      code = File('lib/features/tongtai/onboarding/first_plan.dart')
          .readAsLinesSync()
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
    });

    test('đọc được mã nguồn (chống PASS giả)', () {
      expect(code, contains('class PlanAction'));
      expect(code, contains('final int priority'));
    });

    test('PlanAction không có trường tác động/lợi nhuận dự kiến', () {
      // Trường đó vắng mặt để không ai điền nó "tạm". Nếu ngày mai có luật dự
      // báo thật thì thêm nó cùng luật, không thêm trước.
      for (final banned in const [
        'expectedImpact',
        'estimatedImpact',
        'expectedProfit',
        'projectedRevenue',
        'impactAmount',
      ]) {
        expect(
          code.contains(banned),
          isFalse,
          reason:
              '"$banned" xuất hiện trong kế hoạch — đó là lời hứa lợi nhuận '
              'cho một việc chưa ai làm',
        );
      }
    });

    test('không việc nào chứa dấu + trước một số tiền', () {
      // "+8,4 triệu" là hình dạng cụ thể mà concept vẽ và directive cấm.
      final plan = builder.build(
        goals: OnboardingGoal.values.toList(),
        insight: ready([finding(BriefKind.stockRunningOut)]),
      );
      final promise = RegExp(r'\+\s*[\d.,]+\s*(triệu|tr|nghìn|k|đ)');

      for (final a in plan.actions) {
        for (final text in [a.problem, a.evidence, a.action]) {
          expect(promise.hasMatch(text), isFalse, reason: text);
        }
      }
    });
  });
}
