// WTM-408 — bung điểm cơ hội, và **nói ra phần không chấm được**.
//
// Luật canh ở đây, theo thứ tự quan trọng:
//
//   §1 yếu tố vắng hiện `—` + LÝ DO, tuyệt đối không hiện `0`
//   §2 trọng số hiện cả khi yếu tố vắng — đó là thứ cho thấy bao nhiêu % đang thiếu
//   §3 độ phủ hiện khi điểm chưa đủ (`isPartial`)
//   §4 nhãn "nhu cầu" nói **khách của bạn**, không nói "thị trường"
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_score.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tongtai_score_breakdown.dart';

Future<void> pump(WidgetTester tester, OpportunityScore score) =>
    tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('vi'), Locale('en')],
        home: Scaffold(
          body: SingleChildScrollView(
            child: TongtaiScoreBreakdown(score: score),
          ),
        ),
      ),
    );

void main() {
  testWidgets('⭐ §1 yếu tố KHÔNG chấm được hiện "—" + lý do, KHÔNG hiện 0', (
    tester,
  ) async {
    // `fixed()` dựng đúng bộ bốn yếu tố thật: lợi nhuận chấm được, nhu cầu
    // không có lịch sử đơn, NCC và cạnh tranh vắng vĩnh viễn ở Phase 2.
    await pump(tester, OpportunityScore.fixed(72));
    await tester.pumpAndSettle();

    // Bốn yếu tố đều có mặt kèm trọng số — §2.
    for (final weight in ['40%', '30%', '20%', '10%']) {
      expect(
        find.text(weight),
        findsOneWidget,
        reason: 'thiếu trọng số $weight',
      );
    }

    // Yếu tố chấm được hiện con số thật.
    expect(find.text('72'), findsOneWidget);

    // ⛔ Ba yếu tố vắng hiện `—`. Nếu có ngày ai đó "dọn cho gọn" bằng cách
    // thay `null` thành 0, ca này đỏ — và đó chính là việc của nó.
    expect(find.text('—'), findsNWidgets(3));
    expect(
      find.text('0'),
      findsNothing,
      reason:
          'một yếu tố vắng đang hiện 0 — 0 nói "vô giá trị", '
          'null nói "không ai biết"',
    );

    // Lý do phải hiện, không chỉ dấu gạch.
    expect(find.textContaining('dữ liệu mẫu'), findsOneWidget);
    expect(find.textContaining('dữ liệu thị trường'), findsOneWidget);
    expect(find.textContaining('lịch sử đơn hàng'), findsOneWidget);
  });

  testWidgets('§3 độ phủ hiện ra khi điểm chưa dựa đủ trọng số', (
    tester,
  ) async {
    // ⚠️ Fixture này cho `coverage = 0.40`, KHÔNG phải 0.70.
    //
    // Con số 70% trong tài liệu là trường hợp *nhu cầu chấm được* (0.40 lợi
    // nhuận + 0.30 nhu cầu). `OpportunityScore.fixed()` dựng nhu cầu bằng
    // `demandVolumeFactor(orders: 0)` ⇒ **không có lịch sử đơn** ⇒ yếu tố ấy
    // cũng vắng ⇒ chỉ còn 0.40.
    //
    // Ghi rõ ở đây vì suýt nữa tôi đặt tên ca này là "đúng 70%" trong khi nó
    // khẳng định 0.40 — một cái tên nói sai về chính thứ nó đo.
    final score = OpportunityScore.fixed(72);
    expect(score.isPartial, isTrue);
    expect(score.coverage, closeTo(0.40, 1e-9));

    await pump(tester, score);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('opportunity-score-coverage')),
      findsOneWidget,
      reason: 'điểm chỉ dựa trên một phần trọng số mà không nói ra',
    );
  });

  testWidgets('§4 nhãn nhu cầu nói KHÁCH CỦA BẠN, không nói thị trường', (
    tester,
  ) async {
    // `OpportunityFactorKind.demandVolume` ghi rõ: trên máy này nó đọc từ lịch
    // sử đơn của chính người bán. Rút gọn nhãn thành "nhu cầu thị trường" là
    // đổi một phép đo thành một lời hứa cần backend mới giữ được.
    await pump(tester, OpportunityScore.fixed(50));
    await tester.pumpAndSettle();
    expect(find.textContaining('khách của bạn'), findsOneWidget);
    expect(find.textContaining('thị trường'), findsOneWidget); // chỉ ở LÝ DO
    expect(
      find.text('Nhu cầu thị trường'),
      findsNothing,
      reason: 'nhãn hứa dữ liệu thị trường mà máy này không có',
    );
  });

  testWidgets('điểm rỗng ⇒ không dựng gì, không dựng khung trống', (
    tester,
  ) async {
    await pump(tester, const OpportunityScore([]));
    await tester.pumpAndSettle();
    expect(find.byKey(TongtaiScoreBreakdown.sectionKey), findsNothing);
  });
}
