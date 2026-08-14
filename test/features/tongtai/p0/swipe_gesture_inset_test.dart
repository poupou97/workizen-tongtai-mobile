// P0 — **hàng vuốt được phải nằm TRÊN vùng cử chỉ hệ thống** (WTM-403).
//
// ## Rủi ro đo được
//
// S24 Ultra có **hai** vùng inset ở đáy, và chúng chỉ trùng nhau ở một chế độ:
//
// | chế độ điều hướng | `navigationBars` (= `viewPadding`) | `mandatorySystemGestures` | hở |
// |---|---|---|---|
// | ba nút — đo 2026-08-14 | 135px | 135px | 0 |
// | cử chỉ — đo 2026-08-13 | 42px | 135px | **93px** |
//
// `SafeArea` trừ `viewPadding`. Ở chế độ cử chỉ nó chỉ trừ 42px, nên 93px cuối
// vẫn nhận hàng — mà trong dải ấy hệ điều hành **cướp thao tác vuốt** trước khi
// app thấy. Màn Cơ hội dùng vuốt làm thao tác chính (`Dismissible`: phải =
// quan tâm, trái = bỏ qua).
//
// ## Vì sao không chốt nào cũ bắt được
//
// - `accessibility_test` kiểm **tap target ≥48dp** — **chạm vẫn tới app**, nên
//   nó xanh. Thứ hỏng là *vuốt*, không phải *chạm*.
// - Mọi thứ dựa `SafeArea`/`viewPadding` đều xanh: 42px là câu trả lời **đúng**
//   cho *"thanh nav cao bao nhiêu"*, chỉ không phải cho *"vuốt ở đâu thì tới"*.
// - Widget test **mặc định** có `systemGestureInsets = 0` ⇒ không màn nào từng
//   được dựng ở cấu hình lộ lỗi.
//
// Cùng họ P-35 (`gfxinfo` trả 0 khung cho Flutter) và P-36 (cây semantics rỗng
// giả): một API đứng cạnh thứ mình cần, trả về dữ liệu **trông giống** thứ mình
// cần, và sai **im lặng**.
//
// ## Phép kiểm này thay cho việc gì
//
// Vuốt thật ở chế độ cử chỉ cần đổi `navigation_mode` trên máy Founder — đúng
// thao tác đã làm hỏng đợt đo trước (vé WTM-403 ghi rõ cửa sổ không tin được).
// Ở đây dựng thẳng cấu hình ấy trong tiến trình: đặt `systemGestureInsets` lớn
// hơn `viewPadding`, rồi đo **toạ độ thật** của hàng cuối.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_score.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_feed_controller.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_opportunity_feed_screen.dart';

void main() {
  /// S24 Ultra ở **chế độ cử chỉ** — cấu hình duy nhất lộ khoảng hở.
  const gestureBand = 135.0;
  const navBar = 42.0;

  /// 1080×2340 px @ 3.0 ⇒ 360×780 dp.
  const size = Size(360, 780);

  List<Opportunity> feed(int n) => [
    for (var i = 0; i < n; i++)
      Opportunity(
        id: 'o$i',
        type: OpportunityType.trend,
        title: 'Cơ hội $i',
        description: 'mô tả $i',
        expectedImpact: 1000000,
        impactBasis: OpportunityImpactBasis.estimatedGain,
        score: OpportunityScore.fixed(50 + i.toDouble()),
        discoveredAt: DateTime(2026, 8, 14),
      ),
  ];

  testWidgets('⭐ hàng vuốt cuối cùng nằm TRÊN dải cử chỉ 135px', (
    tester,
  ) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3.0;
    // ⚠️ Đây là chỗ mọi phép kiểm cũ bỏ sót: mặc định cả hai đều 0, nên khoảng
    // hở không tồn tại và không màn nào từng bị hỏi câu này.
    tester.view.viewPadding = FakeViewPadding(bottom: navBar * 3);
    tester.view.padding = FakeViewPadding(bottom: navBar * 3);
    tester.view.systemGestureInsets = FakeViewPadding(bottom: gestureBand * 3);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewPadding();
      tester.view.resetPadding();
      tester.view.resetSystemGestureInsets();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('vi'), Locale('en')],
          home: TongtaiOpportunityFeedScreen(
            controller: OpportunityFeedController(feed(12)),
            clock: () => DateTime(2026, 8, 14),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Cuộn tới đáy — đúng chỗ rủi ro sống.
    for (var i = 0; i < 10; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    final swipeables = find.byType(Dismissible);
    expect(swipeables, findsWidgets, reason: 'không có hàng vuốt nào để đo');

    // Biên dưới của vùng an toàn: đáy màn trừ dải cử chỉ.
    final safeBottom = size.height - gestureBand;

    // ⚠️ Đo **MÉP DƯỚI**, không phải mép trên.
    //
    // Bản đầu của phép kiểm này so `top < safeBottom` và **xanh cả trên mã
    // chưa sửa** — vì một hàng cao ~100dp có mép trên nằm ngoài dải trong khi
    // nửa dưới của nó đã nằm trong. Ngón tay đặt vào nửa dưới ấy là cú vuốt
    // bị nuốt. Một phép kiểm không bao giờ đỏ được thì tệ hơn là không có, nên
    // ghi lại đây thay vì lặng lẽ sửa.
    var checked = 0;
    for (final element in swipeables.evaluate()) {
      final box = element.renderObject! as RenderBox;
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      // Chỉ xét hàng đang hiện trong khung nhìn.
      if (top > size.height || bottom < 0) continue;
      checked++;
      expect(
        bottom,
        lessThanOrEqualTo(safeBottom),
        reason:
            'một hàng vuốt kéo xuống tới y=$bottom, tức chồng vào dải cử chỉ '
            '(bắt đầu ở $safeBottom dp) — ngón tay đặt vào phần chồng ấy thì '
            'hệ thống nuốt cú vuốt trước khi app thấy. Chạm vẫn tới, nên không '
            'phép kiểm tap-target nào đỏ.',
      );
    }
    expect(checked, greaterThan(0), reason: 'không hàng nào trong khung nhìn');
  });
}
