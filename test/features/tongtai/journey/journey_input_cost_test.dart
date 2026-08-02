import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/journey/journey_metric.dart';
import 'package:tongtai/features/tongtai/journey/journey_node.dart';
import 'package:tongtai/features/tongtai/journey/journey_planner.dart';

/// WTM-235 — hai nhịp cuối của Business Loop Producer.
///
/// WTM-234 mở được ba nhịp đầu (thấy · làm · kết quả) nhưng hành trình kinh
/// doanh **không đổi một chữ nào** khi người bán khai thêm một khoản cam kết,
/// và khai xong thì họ không được nói gì về việc tiếp theo. Đây là việc **nối**,
/// không phải việc thêm màn.
void main() {
  BusinessGoal goal({double target = 10000000}) => BusinessGoal(
    id: 'g1',
    name: 'Tăng doanh thu',
    type: GoalType.revenue,
    targetAmount: target,
    achievedAmount: 0,
    growthTarget: 20,
    growthAchieved: 0,
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2026, 9, 30),
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );

  JourneyPlanResult planWith({
    int inputCount = 0,
    int countedInputs = 0,
    double monthlyCommitment = 0,
    double target = 10000000,
  }) => planJourney(
    JourneyPlanInput(
      goal: goal(target: target),
      // Đủ dữ liệu để planner không từ chối vì lý do khác.
      productCount: 8,
      customerCount: 12,
      orderCount: 30,
      expenseCount: 6,
      inputCount: inputCount,
      countedInputs: countedInputs,
      monthlyCommitment: monthlyCommitment,
    ),
    journeyId: 'j1',
  );

  List<JourneyNode> stepsFor(JourneyPlanResult plan, String metricCode) => [
    for (final n in plan.nodes)
      if (n.derivedMetric == metricCode) n,
  ];

  group('hành trình ĐỔI khi biết thêm về chi phí đầu vào', () {
    test('chưa khai nguồn nào ⇒ bước "khai 3 khoản trả đều đặn"', () {
      final plan = planWith();

      final steps = stepsFor(plan, JourneyMetric.inputs.code);
      expect(steps, hasLength(1));
      expect(steps.single.derivedTarget, 3);
      expect(steps.single.reasonCodes, contains(JourneyReason.dataEmptyInputs));
    });

    test('khai dở dang ⇒ bước ĐIỀN NỐT, không phải bước phán xét con số', () {
      // Chỗ dễ nói dối nhất: tổng cam kết đang THIẾU, mà một kế hoạch dựng trên
      // con số thiếu tưởng là đủ sẽ khuyên sai (bảo "chi phí nhẹ" trong khi
      // hai nguồn chưa ai điền tiền).
      final plan = planWith(
        inputCount: 3,
        countedInputs: 1,
        monthlyCommitment: 200000,
      );

      final steps = stepsFor(plan, JourneyMetric.inputs.code);
      expect(steps, hasLength(1));
      expect(
        steps.single.derivedTarget,
        3,
        reason: 'xong khi MỌI nguồn hiện có đã đủ dữ liệu',
      );
      expect(
        steps.single.reasonCodes,
        contains(JourneyReason.dataInputsIncomplete),
      );
      expect(
        stepsFor(plan, JourneyMetric.inputCommitment.code),
        isEmpty,
        reason: 'chưa đủ dữ liệu thì không được kết luận về tổng',
      );
    });

    test('đủ dữ liệu và cam kết NẶNG ⇒ bước xem lại chi phí', () {
      final plan = planWith(
        inputCount: 2,
        countedInputs: 2,
        monthlyCommitment: 3000000,
        target: 10000000,
      );

      final steps = stepsFor(plan, JourneyMetric.inputCommitment.code);
      expect(steps, hasLength(1));
      expect(
        steps.single.derivedTarget,
        1500000,
        reason: 'xong khi cam kết giảm còn một nửa',
      );
      expect(
        steps.single.reasonCodes,
        contains(JourneyReason.dataInputCommitment),
      );
    });

    test('đủ dữ liệu và cam kết NHẸ ⇒ không có bước nào về chi phí', () {
      // Một tiệm trả 100k/tháng cho tên miền không cần bị nhắc cắt giảm.
      final plan = planWith(
        inputCount: 1,
        countedInputs: 1,
        monthlyCommitment: 100000,
        target: 10000000,
      );

      expect(stepsFor(plan, JourneyMetric.inputCommitment.code), isEmpty);
      expect(stepsFor(plan, JourneyMetric.inputs.code), isEmpty);
    });
  });

  group('bước tiếp phải MỞ ĐƯỢC chỗ làm việc', () {
    test('cả hai loại bước về đầu vào đều dẫn tới màn nguồn đầu vào', () {
      // Không có đích đến thì "bước tiếp theo" chỉ là một dòng chữ (WTM-169:
      // một nút không đi đâu còn tệ hơn không có nút).
      for (final metric in [
        JourneyMetric.inputs,
        JourneyMetric.inputCommitment,
      ]) {
        final node = JourneyNode(
          id: 'n-${metric.code}',
          journeyId: 'j1',
          title: 'x',
          kind: JourneyNodeKind.step,
          origin: JourneyNodeOrigin.ruleTwin,
          derivedMetric: metric.code,
        );
        expect(journeyNodeDestination(node), JourneyDestination.inputs);
      }
    });
  });

  group('đo bằng nguồn ĐÃ ĐỦ THÔNG TIN, không phải số dòng', () {
    test('journeyMetrics nhận countedInputs', () {
      // Đếm dòng thì một nguồn khai mỗi cái tên rồi bỏ đó cũng tính là xong —
      // trong khi nó chính là thứ làm tổng cam kết thiếu.
      final metrics = journeyMetrics(
        productCount: 3,
        customerCount: 2,
        expenseCount: 5,
        revenue: 1000,
        countedInputs: 2,
      );

      expect(metrics[JourneyMetric.inputs.code], 2);
    });

    test(
      'inputCommitment KHÔNG nằm trong bảng đo — nó xong bằng cách GIẢM',
      () {
        // Cùng lý do receivables vắng mặt (WTM-211): `refreshDerived` chỉ đẩy
        // bước tiến lên, nên đưa một con số giảm vào đây sẽ đánh dấu "xem lại
        // chi phí" là xong ngay lúc chi phí TĂNG.
        final metrics = journeyMetrics(
          productCount: 3,
          customerCount: 2,
          expenseCount: 5,
          revenue: 1000,
          countedInputs: 2,
        );

        expect(
          metrics.containsKey(JourneyMetric.inputCommitment.code),
          isFalse,
        );
        expect(metrics.containsKey(JourneyMetric.receivables.code), isFalse);
      },
    );
  });

  group('vựng từ canonical', () {
    test('mã lạ vẫn đọc ra null, mã mới đọc đúng', () {
      expect(JourneyMetric.fromCode('inputs'), JourneyMetric.inputs);
      expect(
        JourneyMetric.fromCode('input_commitment'),
        JourneyMetric.inputCommitment,
      );
      expect(JourneyMetric.fromCode('input_cost'), isNull);
    });
  });
}
