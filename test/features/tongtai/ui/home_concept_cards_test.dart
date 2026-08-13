// WTM-404 — luật đứng sau các thẻ chỉ số của concept-1.
//
// Mỗi ca dưới đây canh một **quyết định**, không canh một pixel. Bố cục còn đổi
// nhiều lần trước bản demo; ba luật này thì không được đổi lặng lẽ:
//
//   §1 thiếu mốc ⇒ KHÔNG có phần trăm (kể cả khi mốc bằng 0)
//   §2 dưới 3 điểm ⇒ KHÔNG vẽ đường
//   §3 màu định vị KHÔNG được chạm vào con số hay đường
//   §4 mức ưu tiên là THỨ HẠNG, không phải ngưỡng điểm
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/design/tt.dart';
import 'package:tongtai/features/tongtai/analytics/revenue_series.dart';
import 'package:tongtai/features/tongtai/metrics/home_trend.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_priority.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_score.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tt_metric_card.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tt_sparkline.dart';

Opportunity _opp({required String id, required double? score}) => Opportunity(
  id: id,
  type: OpportunityType.trend,
  title: 'Nhập thêm quạt mini',
  description: 'Dự kiến hết hàng sau 3 ngày',
  expectedImpact: 1200000,
  impactBasis: OpportunityImpactBasis.estimatedGain,
  // ⚠️ Điểm rỗng dựng bằng danh sách yếu tố TRỐNG, không phải `fixed(0)`:
  // `coverage == 0 ⇒ value == null`, tức *"không chấm được"* — khác hẳn
  // *"chấm được và bằng 0"*.
  score: score == null
      ? const OpportunityScore([])
      : OpportunityScore.fixed(score),
  discoveredAt: DateTime(2026, 8, 13),
);

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: SizedBox(width: 200, child: child)),
  ),
);

void main() {
  group('§1 HomeTrend — thiếu mốc thì nói thiếu', () {
    test('dưới hai điểm ⇒ null, không phải 0', () {
      expect(HomeTrend.changePercent(const []), isNull);
      expect(HomeTrend.changePercent(const [5]), isNull);
    });

    test('⭐ mốc bằng 0 ⇒ null — KHÔNG làm tròn thành +100%', () {
      // Tăng từ 0 lên bất cứ đâu là tăng **vô hạn**. Mọi con số hiển thị ở đây
      // đều là một con số bịa. Đây là ca dễ mất nhất khi ai đó "sửa cho gọn".
      expect(HomeTrend.changePercent(const [0, 900]), isNull);
      expect(HomeTrend.changePercent(const [3, 0, 900]), isNull);
    });

    test('có mốc ⇒ tính đúng dấu và độ lớn', () {
      expect(HomeTrend.changePercent(const [100, 120]), closeTo(20, 1e-9));
      expect(HomeTrend.changePercent(const [100, 49]), closeTo(-51, 1e-9));
      // Chỉ so hai điểm CUỐI: các tháng trước đó vẽ nên đường, không nên mốc.
      expect(
        HomeTrend.changePercent(const [1, 2, 100, 120]),
        closeTo(20, 1e-9),
      );
    });

    test('rút từ RevenueSeries chứ không cộng lại từ đơn hàng', () {
      const series = RevenueSeries(
        points: [
          MonthlyRevenuePoint(year: 2026, month: 5, revenue: 10, orderCount: 2),
          MonthlyRevenuePoint(year: 2026, month: 6, revenue: 20, orderCount: 4),
        ],
      );
      final trend = HomeTrend.from(series, profitByMonth: const [5, 4]);
      expect(trend.revenue, const [10, 20]);
      expect(trend.orders, const [2, 4]);
      expect(trend.revenueChangePercent, closeTo(100, 1e-9));
      expect(trend.ordersChangePercent, closeTo(100, 1e-9));
      expect(trend.profitChangePercent, closeTo(-20, 1e-9));
    });

    test('tháng rỗng vào chuỗi bằng 0 thật, không bị bỏ qua', () {
      // Một tháng không bán được gì là **thông tin**. Bỏ điểm ấy đi thì đường
      // tự khép lại và cái hố biến mất khỏi màn hình.
      const series = RevenueSeries(
        points: [
          MonthlyRevenuePoint(year: 2026, month: 5, revenue: 10, orderCount: 1),
          MonthlyRevenuePoint(year: 2026, month: 6),
          MonthlyRevenuePoint(year: 2026, month: 7, revenue: 30, orderCount: 3),
        ],
      );
      expect(HomeTrend.from(series).revenue, const [10, 0, 30]);
    });
  });

  group('§2 TtSparkline — dưới ba điểm thì không vẽ', () {
    test('ngưỡng là ba', () {
      expect(TtSparkline.hasShape(const []), isFalse);
      expect(TtSparkline.hasShape(const [1]), isFalse);
      // Hai điểm chỉ vẽ được một đoạn thẳng, và một đoạn thẳng trông y hệt một
      // xu hướng trong khi nó không nói gì về hình dạng.
      expect(TtSparkline.hasShape(const [1, 2]), isFalse);
      expect(TtSparkline.hasShape(const [1, 2, 3]), isTrue);
    });

    testWidgets('dưới ngưỡng ⇒ không có CustomPaint nào được dựng', (
      tester,
    ) async {
      // ⚠️ Phải giới hạn TRONG `TtSparkline`: `Scaffold` tự dựng `CustomPaint`
      // của riêng nó, nên `find.byType(CustomPaint)` trần sẽ xanh/đỏ vì lý do
      // chẳng liên quan gì tới widget đang kiểm.
      final painterInside = find.descendant(
        of: find.byType(TtSparkline),
        matching: find.byType(CustomPaint),
      );

      await _pump(
        tester,
        const TtSparkline(values: [1, 2], color: TtColors.success),
      );
      expect(painterInside, findsNothing);

      await _pump(
        tester,
        const TtSparkline(values: [1, 2, 3], color: TtColors.success),
      );
      expect(painterInside, findsOneWidget);
    });
  });

  group('§3 TtMetricCard — màu định vị không chạm vào giá trị', () {
    testWidgets('⭐ con số KHÔNG bao giờ mang màu của ô biểu tượng', (
      tester,
    ) async {
      // Đây là lỗi WTM-389 viết thành phép kiểm: ô *"Nguồn hàng **0**"* từng
      // hiện màu **xanh lá** vì xanh lá là màu của Nguồn hàng — và người bán
      // đọc ra "tin tốt" từ một con số không.
      const wayfinding = Color(0xFF00A3FF); // màu chỉ có ở đây, dễ truy
      await _pump(
        tester,
        const TtMetricCard(
          label: 'Kho hàng',
          value: '114',
          iconData: Icons.warehouse_outlined,
          iconColor: wayfinding,
          tint: Color(0xFFEFF6FF),
        ),
      );
      final value = tester.widget<Text>(find.text('114'));
      expect(value.style!.color, TtColors.textPrimary);
      expect(value.style!.color, isNot(wayfinding));
    });

    testWidgets('sắc thái cảnh báo mới được tô đỏ, và chỉ đỏ', (tester) async {
      await _pump(
        tester,
        const TtMetricCard(
          label: 'Kho hàng',
          value: '5',
          iconData: Icons.warehouse_outlined,
          iconColor: Color(0xFF00A3FF),
          valueTone: TtValueTone.critical,
        ),
      );
      expect(tester.widget<Text>(find.text('5')).style!.color, TtColors.danger);
    });

    testWidgets('⭐ trend unknown ⇒ KHÔNG mũi tên, KHÔNG phần trăm', (
      tester,
    ) async {
      // Phía gọi vẫn có thể lỡ truyền `deltaLabel`; thẻ phải tự từ chối. Một
      // nhãn "0%" cạnh mũi tên xám vẫn là một lời khẳng định không ai đo được.
      await _pump(
        tester,
        const TtMetricCard(
          label: 'Doanh thu',
          value: '0 ₫',
          iconData: Icons.trending_up,
          iconColor: TtColors.brandOnDark,
          deltaLabel: '+17% so với tháng trước',
        ),
      );
      expect(find.text('+17% so với tháng trước'), findsNothing);
      expect(find.byIcon(Icons.arrow_upward), findsNothing);
      expect(find.byIcon(Icons.arrow_downward), findsNothing);
    });

    testWidgets('có mốc ⇒ mũi tên đúng hướng, màu ngữ nghĩa', (tester) async {
      await _pump(
        tester,
        const TtMetricCard(
          label: 'Lợi nhuận',
          value: '5tr ₫',
          iconData: Icons.savings_outlined,
          iconColor: TtColors.aiOnLight, // tím — KHÔNG được lan sang mũi tên
          deltaLabel: '−49% so với tháng trước',
          trend: TtTrend.down,
        ),
      );
      final arrow = tester.widget<Icon>(find.byIcon(Icons.arrow_downward));
      expect(arrow.color, TtColors.danger);
      expect(arrow.color, isNot(TtColors.aiOnLight));
    });
  });

  group('§4 OpportunityPriority — thứ hạng, không phải ngưỡng điểm', () {
    test('vị trí quyết định mức, KHÔNG phải độ lớn của điểm', () {
      // ⭐ Hai cơ hội điểm **thấp như nhau** vẫn có mức khác nhau vì đứng khác
      // chỗ; một cơ hội điểm cao đứng thứ ba vẫn là "Thấp". Đó chính là điều
      // một ngưỡng tuyệt đối KHÔNG làm được — và ngưỡng ấy sẽ sai, vì 30%
      // trọng số của thang điểm không tính được trên máy này (`coverage`).
      final weak = _opp(id: 'a', score: 12);
      final strong = _opp(id: 'b', score: 98);
      expect(OpportunityPriority.at(weak, 0), OpportunityPriority.high);
      expect(OpportunityPriority.at(weak, 1), OpportunityPriority.medium);
      expect(OpportunityPriority.at(strong, 2), OpportunityPriority.low);
      expect(OpportunityPriority.at(strong, 7), OpportunityPriority.low);
    });

    test('⭐ không chấm được điểm ⇒ unknown, kể cả khi đứng đầu', () {
      // Cùng luật WTM-193 hiện dấu `—` thay vì số 0: *không biết* ≠ *vô giá
      // trị*. Vị trí đầu bảng không biến một cơ hội không đo được thành ưu
      // tiên cao.
      final unscored = _opp(id: 'c', score: null);
      expect(unscored.score.value, isNull);
      expect(OpportunityPriority.at(unscored, 0), OpportunityPriority.unknown);
    });
  });
}
