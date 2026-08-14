// Thẻ "vốn đang nằm trong hàng chậm bán" — WTM-411 (concept-1 `cp3`).
//
// Ba luật, và cả ba đều nói về **sự thật của con số**, không phải hình dáng:
//
//   §1 tổng thiếu phải TỰ NÓI là nó thiếu. `tiedUpAmount` chỉ cộng mặt hàng có
//      giá vốn, nên khi còn mặt hàng chưa khai, con số đang **thấp hơn sự
//      thật** — và một tổng thiếu trông như tổng đủ khiến người bán yên tâm
//      nhầm. Đây là hướng nói dối nguy hiểm hơn hẳn hướng ngược lại.
//   §2 không có hàng chậm ⇒ KHÔNG dựng thẻ rỗng.
//   §3 thẻ phải LÀM ĐƯỢC việc gì đó: bấm vào là lọc danh sách về đúng tập ấy.
//      *"cp3, cp7, cp8 không thẻ nào chỉ để đọc"* — một con số tiền đang nằm
//      mà không dẫn tới danh sách thì chỉ là một nỗi lo mới.
//
// ⚠️ Thêm §4 cho đường nạp: thẻ là phần PHỤ đứng trên danh sách chính, nên khi
// nguồn dữ liệu riêng của nó (đơn hàng) hỏng, nó phải tự biến mất — không được
// kéo cả danh mục chết theo.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/inventory/slow_moving_capital.dart';
import 'package:tongtai/features/tongtai/inventory/slow_moving_capital_loader.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tongtai_tied_up_capital_card.dart';

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('vi'),
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en'), Locale('vi')],
  home: Scaffold(body: child),
);

void main() {
  testWidgets('§1 tổng còn thiếu ⇒ thẻ NÓI RA phần chưa tính được', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TongtaiTiedUpCapitalCard(
          capital: const SlowMovingCapital(
            tiedUpAmount: 4200000,
            slowMovingCount: 12,
            unknownCostCount: 3,
            windowDays: 30,
            productIds: {'a', 'b'},
          ),
          onViewList: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('inventory-tied-up-amount')), findsOneWidget);
    expect(
      find.byKey(const Key('inventory-tied-up-unknown-cost')),
      findsOneWidget,
      reason: 'còn 3 mặt hàng chưa khai giá vốn mà thẻ im lặng ⇒ con số thấp '
          'hơn sự thật lại trông như con số đủ',
    );
  });

  testWidgets('§1b không thiếu gì ⇒ KHÔNG có dòng thú nhận thừa', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TongtaiTiedUpCapitalCard(
          capital: const SlowMovingCapital(
            tiedUpAmount: 4200000,
            slowMovingCount: 12,
            unknownCostCount: 0,
            windowDays: 30,
            productIds: {'a'},
          ),
          onViewList: () {},
        ),
      ),
    );
    expect(find.byKey(const Key('inventory-tied-up-unknown-cost')), findsNothing);
  });

  testWidgets('§2 không có hàng chậm ⇒ không dựng thẻ rỗng', (tester) async {
    await tester.pumpWidget(
      _host(
        TongtaiTiedUpCapitalCard(
          capital: SlowMovingCapital.none,
          onViewList: () {},
        ),
      ),
    );
    expect(find.byKey(TongtaiTiedUpCapitalCard.cardKey), findsNothing);
  });

  testWidgets('§3 bấm thẻ ⇒ gọi hành động (thẻ không chỉ để đọc)', (
    tester,
  ) async {
    var tapped = 0;
    await tester.pumpWidget(
      _host(
        TongtaiTiedUpCapitalCard(
          capital: const SlowMovingCapital(
            tiedUpAmount: 1000,
            slowMovingCount: 2,
            unknownCostCount: 0,
            windowDays: 30,
            productIds: {'a', 'b'},
          ),
          onViewList: () => tapped++,
        ),
      ),
    );

    await tester.tap(find.byKey(TongtaiTiedUpCapitalCard.cardKey));
    expect(tapped, 1);
  });

  group('§4 đường nạp — thẻ phụ không được kéo danh sách chính chết theo', () {
    test('đọc đơn hàng hỏng ⇒ thẻ tự ẩn, KHÔNG ném lỗi lên màn', () async {
      final capital = await loadSlowMovingCapital(
        profit: Future.error(StateError('không đọc được đơn hàng')),
        products: const [],
      );

      expect(
        capital.hasSlowMoving,
        isFalse,
        reason: 'lỗi ở nguồn dữ liệu PHỤ mà xoá sạch danh mục thì người bán mở '
            'Kho ra không thấy hàng của mình',
      );
      expect(
        capital.tiedUpAmount,
        0,
        reason: 'không biết món nào đã bán thì KHÔNG được đoán một con số',
      );
    });
  });
}
