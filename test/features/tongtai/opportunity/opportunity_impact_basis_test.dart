import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/ai/opportunity_ai.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_action_plan.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_score.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';

/// **Tác động: bằng chứng hay dự đoán** — WTM-384.
///
/// ⚠️ Lỗi tìm thấy trên **Nokia 6.1**: một thẻ cơ hội nói hai lần cùng một con
/// số, lần sau kèm dấu `+`:
///
/// > Nhóm Home dẫn đầu doanh thu 60 ngày qua **(15.270.000 đ)** …
/// > **Ước tính +15.270.000 đ**
///
/// Dấu `+` hứa *"làm việc này, bạn được thêm 15 triệu"* — nhưng đó là tiền
/// **đã kiếm**. §9 FLOW G cấm thẳng: *"Không bịa monetary impact."*
///
/// Suite này giữ ranh giới ấy ở cả ba nơi con số đi qua: **luật**, **màn
/// hình**, và **prompt AI**.
void main() {
  Opportunity opp(OpportunityImpactBasis basis, {double impact = 1000000}) =>
      Opportunity(
        id: 'o1',
        type: OpportunityType.trend,
        title: 'Đẩy thêm nhóm Home',
        description: 'Nhóm Home dẫn đầu doanh thu 60 ngày qua.',
        expectedImpact: impact,
        impactBasis: basis,
        score: OpportunityScore.fixed(61),
        discoveredAt: DateTime(2026, 8, 12),
      );

  String money(double v) => '${v.toStringAsFixed(0)}đ';

  String label(Opportunity o) => tongtaiImpactLabel(
    o,
    estimatePrefix: 'Ước tính',
    observedPrefix: 'Doanh thu 60 ngày',
    money: money,
  );

  group('⛔ dấu "+" chỉ dành cho tiền CHƯA kiếm', () {
    test('quan sát ⇒ KHÔNG có dấu +', () {
      final text = label(opp(OpportunityImpactBasis.observedRevenue));
      expect(text, isNot(contains('+')));
      expect(text, contains('Doanh thu 60 ngày'));
      expect(
        text,
        isNot(contains('Ước tính')),
        reason: 'doanh thu đã qua không phải một ước tính',
      );
    });

    test('ước tính ⇒ có dấu + và chữ "Ước tính"', () {
      final text = label(opp(OpportunityImpactBasis.estimatedGain));
      expect(text, contains('+'));
      expect(text, contains('Ước tính'));
    });

    test('con số KHÔNG bị đổi — chỉ nhãn đổi', () {
      // Cách sửa dễ mà sai là nhân doanh thu quá khứ với một hệ số rồi gọi nó
      // là ước tính. Một hệ số nghĩ ra cũng là bịa, chỉ khó phát hiện hơn.
      for (final b in OpportunityImpactBasis.values) {
        expect(label(opp(b, impact: 15270000)), contains('15270000đ'));
      }
    });
  });

  group('⛔ prompt AI nói THẬT con số là gì', () {
    test('quan sát ⇒ prompt cấm model hứa đây là tiền sẽ kiếm thêm', () {
      final block = opportunityPromptBlock(
        opp(OpportunityImpactBasis.observedRevenue),
      );
      expect(block, contains('ĐÃ ĐẠT'));
      expect(block, contains('KHÔNG phải khoản thêm vào'));
      expect(
        block,
        isNot(contains('Tác động ƯỚC TÍNH')),
        reason: 'gọi doanh thu quá khứ là ước tính chính là lỗi WTM-384',
      );
    });

    test('ước tính ⇒ prompt gọi đúng tên', () {
      final block = opportunityPromptBlock(
        opp(OpportunityImpactBasis.estimatedGain),
      );
      expect(block, contains('ƯỚC TÍNH'));
    });

    test('lời giải thích rule-based cũng phân biệt hai loại', () {
      expect(
        ruleBasedOpportunityInsight(
          opp(OpportunityImpactBasis.observedRevenue),
        ),
        contains('doanh thu 60 ngày qua'),
      );
      expect(
        ruleBasedOpportunityInsight(opp(OpportunityImpactBasis.estimatedGain)),
        contains('ước tính thêm'),
      );
    });
  });

  group('⛔ dư âm — kế hoạch hành động cũng không được hứa sai (WTM-390)', () {
    // ⚠️ WTM-384 sửa nhãn trên thẻ và trong prompt AI, nhưng **bỏ sót** bước
    // cuối của Kế hoạch hành động: nó gọi con số là *"mức kỳ vọng"*, trong khi
    // với luật tồn kho và luật nhóm nó là doanh thu **đã qua**.
    //
    // Cùng một lời hứa sai, chỉ nấp ở một cửa khác. Đây là lý do sau mỗi bản
    // vá phải hỏi *"còn cửa nào khác cùng lớp?"* — và lần này câu trả lời là
    // "có", tìm ra bằng mắt trên máy chứ không bằng suite.
    test('quan sát ⇒ gọi là MỐC 60 ngày, không phải kỳ vọng', () {
      final steps = opportunityActionPlan(
        opp(OpportunityImpactBasis.observedRevenue),
      );
      final last = steps.last.detailVi;
      expect(last, contains('60 ngày qua'));
      expect(
        last,
        isNot(contains('kỳ vọng')),
        reason: 'doanh thu đã qua không phải một kỳ vọng',
      );
    });

    test('ước tính ⇒ được phép gọi là kỳ vọng', () {
      final steps = opportunityActionPlan(
        opp(OpportunityImpactBasis.estimatedGain),
      );
      expect(steps.last.detailVi, contains('kỳ vọng'));
    });
  });

  group('⛔ luật khai đúng cơ sở của mình', () {
    test('⭐ hai luật dựa trên doanh thu quá khứ phải là observedRevenue', () {
      // Đây là hai dòng đã đẻ ra lỗi: `expectedImpact: recent` (luật tồn kho)
      // và `expectedImpact: top.value` (luật nhóm) — cả hai là doanh thu 60
      // ngày qua, và cả hai từng được hiện kèm dấu `+`.
      final code = File(
        'lib/features/tongtai/opportunity/opportunity_rule_engine.dart',
      ).readAsStringSync();
      for (final pair in const [
        ('expectedImpact: recent,', 'observedRevenue'),
        ('expectedImpact: top.value,', 'observedRevenue'),
        ('expectedImpact: aov,', 'estimatedGain'),
        ('expectedImpact: gap,', 'estimatedGain'),
      ]) {
        final at = code.indexOf(pair.$1);
        expect(at, greaterThan(-1), reason: 'không còn dòng ${pair.$1}');
        final after = code.substring(at, (at + 200).clamp(0, code.length));
        expect(
          after,
          contains('OpportunityImpactBasis.${pair.$2}'),
          reason: '${pair.$1} phải khai ${pair.$2}',
        );
      }
    });

    test('⛔ không màn nào tự gắn "+" vào expectedImpact', () {
      // Trước WTM-384 ba màn tự viết `'+${...expectedImpact}'`. Nhãn nay do
      // một chỗ duy nhất quyết, nên bốn màn không thể nói bốn kiểu.
      for (final f
          in Directory('lib/features/tongtai/ui')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final code = f.readAsStringSync();
        expect(
          RegExp(r"'\+\$\{[^}]*expectedImpact").hasMatch(code),
          isFalse,
          reason:
              '${f.uri.pathSegments.last} tự gắn "+" — dùng tongtaiImpactLabel',
        );
      }
    });
  });
}
