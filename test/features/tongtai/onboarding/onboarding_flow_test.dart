import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/onboarding/onboarding_conversation.dart';
import 'package:tongtai/features/tongtai/onboarding/onboarding_flow.dart';
import 'package:tongtai/features/tongtai/profile/business_profile.dart';

/// WTM-350 (S1) + WTM-351 (S2) — máy trạng thái onboarding V2.
///
/// Test chạy trên **giá trị**, không pump widget: nếu một luật về đường đi chỉ
/// đúng khi có widget thì nó không phải luật, nó là một chi tiết trình bày.
void main() {
  OnboardingFlow atDataStart({DataStartChoice? choice}) {
    var flow = const OnboardingFlow();
    while (flow.stage != OnboardingStage.dataStart) {
      flow = flow.next();
    }
    return choice == null ? flow : flow.chooseDataStart(choice);
  }

  group('đường đi suy ra từ MỘT lựa chọn', () {
    test('chưa chọn cửa nào ⇒ không đi tiếp được', () {
      final flow = atDataStart();

      expect(flow.stage, OnboardingStage.dataStart);
      expect(flow.path, isNull);
      // Không phải "UI không vẽ nút" — danh sách màn chưa có gì sau `dataStart`.
      expect(flow.next().stage, OnboardingStage.dataStart);
      expect(flow.next().next().stage, OnboardingStage.dataStart);
    });

    test('mỗi cửa cho đúng một đường', () {
      expect(DataStartChoice.csv.path, OnboardingPath.withData);
      expect(DataStartChoice.sample.path, OnboardingPath.sample);
      expect(DataStartChoice.none.path, OnboardingPath.noData);
    });

    test('chỉ đường B không phân tích', () {
      expect(OnboardingPath.withData.analysesData, isTrue);
      expect(OnboardingPath.sample.analysesData, isTrue);
      expect(OnboardingPath.noData.analysesData, isFalse);
    });
  });

  group('⛔ đường B KHÔNG THỂ vào bước phân tích', () {
    test('danh sách màn của đường B không chứa analysis/insight', () {
      final stages = stagesFor(OnboardingPath.noData);

      expect(stages, isNot(contains(OnboardingStage.analysis)));
      expect(stages, isNot(contains(OnboardingStage.insight)));
    });

    test('đi hết đường B chưa từng dừng ở analysis hay insight', () {
      var flow = atDataStart(choice: DataStartChoice.none);
      final visited = <OnboardingStage>[];

      // Chặn vòng lặp vô hạn bằng số bước tối đa, không bằng `isComplete` —
      // nếu `next()` hỏng thì test phải đỏ chứ không phải treo.
      for (var i = 0; i < 20 && !flow.isComplete; i++) {
        visited.add(flow.stage!);
        flow = flow.next();
      }

      expect(flow.isComplete, isTrue);
      expect(visited, isNot(contains(OnboardingStage.analysis)));
      expect(visited, isNot(contains(OnboardingStage.insight)));
      expect(visited.last, OnboardingStage.plan);
    });

    test('đường A và C đi qua cả hai bước đó', () {
      for (final choice in [DataStartChoice.csv, DataStartChoice.sample]) {
        var flow = atDataStart(choice: choice);
        final visited = <OnboardingStage>[];
        for (var i = 0; i < 20 && !flow.isComplete; i++) {
          visited.add(flow.stage!);
          flow = flow.next();
        }

        expect(visited, contains(OnboardingStage.analysis), reason: '$choice');
        expect(visited, contains(OnboardingStage.insight), reason: '$choice');
        // Phân tích phải đứng TRƯỚC kết luận — thứ tự này là cả ý nghĩa.
        expect(
          visited.indexOf(OnboardingStage.analysis),
          lessThan(visited.indexOf(OnboardingStage.insight)),
          reason: '$choice',
        );
      }
    });
  });

  group('quay lại là phép trừ, không mất câu đã trả lời', () {
    test('quay từ insight về dataStart giữ nguyên hồ sơ', () {
      var flow = const OnboardingFlow();
      // Trả lời câu đầu tiên (loại hình) rồi đi tiếp tới cửa dữ liệu.
      flow = flow.answerProfile('goods');
      final answered = flow.conversation.profile;
      flow = atDataStartFrom(flow).chooseDataStart(DataStartChoice.sample);

      while (flow.stage != OnboardingStage.insight) {
        flow = flow.next();
      }
      while (flow.stage != OnboardingStage.dataStart) {
        flow = flow.back();
      }

      expect(flow.conversation.profile.type, answered.type);
      expect(flow.dataStart, DataStartChoice.sample);
    });

    test('back ở màn đầu không đi ra ngoài', () {
      const flow = OnboardingFlow();
      expect(flow.back().stageIndex, 0);
    });

    test('đổi cửa sau khi đã chọn thì đổi luôn đường', () {
      final flow = atDataStart(choice: DataStartChoice.none);
      expect(flow.path, OnboardingPath.noData);

      final again = flow.chooseDataStart(DataStartChoice.csv);
      expect(again.path, OnboardingPath.withData);
      // Vẫn đứng ở cửa dữ liệu — đổi lựa chọn không tự đẩy người bán đi.
      expect(again.stage, OnboardingStage.dataStart);
    });
  });

  group('WTM-351 · hồ sơ V2', () {
    test('vẫn hỏi mùa vụ — SeasonalRule ăn tín hiệu này', () {
      expect(
        kOnboardingSteps.map((s) => s.id),
        containsAll(<String>[
          'business_type',
          'trade',
          'channels',
          'size',
          'seasonality',
        ]),
      );
    });

    test('loại hình hỏi đầu tiên', () {
      expect(kOnboardingSteps.first.id, 'business_type');
    });

    test('mỗi đáp án loại hình ánh xạ đúng về ADR-TON-023', () {
      expect(kBusinessTypeByAnswer['goods'], BusinessType.physical);
      expect(kBusinessTypeByAnswer['digital'], BusinessType.digital);
      expect(kBusinessTypeByAnswer['service'], BusinessType.service);
      expect(kBusinessTypeByAnswer['mixed'], BusinessType.hybrid);
      // ⭐ Hai mã này KHÔNG được đoán hộ một loại hình.
      expect(kBusinessTypeByAnswer['preparing'], isNull);
      expect(kBusinessTypeByAnswer['other'], isNull);
      // Mọi giá trị của enum đều có ít nhất một đáp án dẫn tới nó.
      expect(
        kBusinessTypeByAnswer.values.whereType<BusinessType>().toSet(),
        BusinessType.values.toSet(),
      );
    });

    test('"đang chuẩn bị" là tín hiệu riêng, không phải type null chung', () {
      final preparing = const OnboardingConversation().answer('preparing');
      final other = const OnboardingConversation().answer('other');

      expect(preparing.profile.type, isNull);
      expect(other.profile.type, isNull);
      // Cùng `type == null`, khác tín hiệu — đó là lý do giữ mã thô.
      expect(preparing.isPreparing, isTrue);
      expect(other.isPreparing, isFalse);
    });

    test('bấm lại đáp án đang chọn thì bỏ chọn', () {
      final once = const OnboardingConversation().answer('goods');
      expect(once.profile.type, BusinessType.physical);

      final twice = once.answer('goods');
      expect(twice.profile.type, isNull);
      expect(twice.businessTypeCode, isNull);
    });

    test('⭐ trả lời câu sau KHÔNG xoá loại hình đã trả lời', () {
      // Mỗi `_withX` dựng lại cả `BusinessProfile`; quên chép một trường là
      // xoá nó lặng lẽ. `type` là trường mới nhất nên dễ rơi nhất.
      var c = const OnboardingConversation().answer('goods');
      for (final answer in ['fashion', 'shopee', 'solo', 'tet']) {
        c = c.next().answer(answer);
      }

      expect(c.profile.type, BusinessType.physical, reason: 'type bị xoá');
      expect(c.profile.trade, BusinessTrade.fashion);
      expect(c.profile.channels, contains(SalesChannel.shopee));
      expect(c.profile.size, BusinessSize.solo);
      expect(c.profile.seasonality, BusinessSeasonality.tet);
    });

    test('luồng nhớ "đang chuẩn bị" mà KHÔNG tự ép sang đường B', () {
      final flow = const OnboardingFlow().answerProfile('preparing');

      expect(flow.preparing, isTrue);
      // Vẫn tự chọn cửa được: người đang chuẩn bị vẫn có thể có bảng tính.
      expect(flow.dataStart, isNull);
      expect(
        flow.chooseDataStart(DataStartChoice.csv).path,
        OnboardingPath.withData,
      );
    });
  });
}

/// Đưa [flow] tới cửa dữ liệu mà giữ nguyên những gì đã trả lời.
OnboardingFlow atDataStartFrom(OnboardingFlow flow) {
  var f = flow;
  while (f.stage != OnboardingStage.dataStart) {
    f = f.next();
  }
  return f;
}
