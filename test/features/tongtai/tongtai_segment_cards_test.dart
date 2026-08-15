// Dải thẻ phân khúc — WTM-419 bước 2 (concept-1 `cp4`).
//
// Hai luật dễ sai nhất, và cả hai đều là chuyện **nói dối bằng hình**:
//
//   §1 KHÔNG có mốc so ⇒ KHÔNG mũi tên. Người bán mới dùng app hai tuần thì mốc
//      "30 ngày trước" là một tệp rỗng; mọi phần trăm dựng trên nó là bịa. Cùng
//      kỷ luật `HomeTrend.changePercent` (WTM-404).
//   §2 "Tăng" KHÔNG đồng nghĩa với "tốt", nhưng mũi tên vẫn phải đi theo DẤU
//      của con số. Bản đầu gộp hai câu này làm một và thẻ "Nguy cơ rời bỏ 13"
//      hiện `↓ +7` — mũi tên xuống cạnh con số tăng, đọc ra thành "giảm 7".
//      Nay: hướng = dấu delta · màu = tăng-là-tốt-hay-xấu.
//
// Kèm §3: thẻ cảnh báo hiện **cả khi bằng 0**, vì sự vắng mặt của một cảnh báo
// chỉ trấn an được người ta khi nhìn thấy được.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/analytics/customer_segment_view.dart';
import 'package:tongtai/features/tongtai/consumer/customer_segment.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tongtai_segment_cards.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tt_metric_card.dart';

CustomerSegmentView _view({
  required Map<CustomerSegment, int> now,
  Map<CustomerSegment, int>? before,
}) => CustomerSegmentView(
  tally: now,
  customLabels: const {},
  notPurchased: 0,
  total: now.values.fold(0, (a, b) => a + b),
  previous: before,
);

Widget _host(CustomerSegmentView view) => MaterialApp(
  locale: const Locale('vi'),
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en'), Locale('vi')],
  home: Scaffold(body: TongtaiSegmentCards(view: view)),
);

TtMetricCard _card(WidgetTester tester, CustomerSegment s) =>
    tester.widget<TtMetricCard>(find.byKey(Key('segment-card-${s.code}')));

void main() {
  testWidgets('§1 không có mốc so ⇒ KHÔNG mũi tên, KHÔNG dòng delta', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(_view(now: const {CustomerSegment.loyal: 24})),
    );

    final card = _card(tester, CustomerSegment.loyal);
    expect(card.trend, TtTrend.unknown);
    expect(
      card.deltaLabel,
      isNull,
      reason: 'chưa đủ lịch sử mà vẫn vẽ xu hướng thì con số ấy là bịa',
    );
  });

  testWidgets('§1b mốc cũ RỖNG cũng là không có mốc', (tester) async {
    // Tệp 30 ngày trước chưa có ai — "tăng từ 0" không phải một phát biểu.
    await tester.pumpWidget(
      _host(
        _view(
          now: const {CustomerSegment.loyal: 24},
          before: const {CustomerSegment.loyal: 0},
        ),
      ),
    );
    expect(_card(tester, CustomerSegment.loyal).trend, TtTrend.unknown);
  });

  testWidgets(
    '⭐ §2 thêm khách RỜI BỎ là mũi tên XẤU, không phải mũi tên tăng',
    (tester) async {
      await tester.pumpWidget(
        _host(
          _view(
            now: const {CustomerSegment.churned: 16, CustomerSegment.loyal: 24},
            before: const {
              CustomerSegment.churned: 10,
              CustomerSegment.loyal: 20,
            },
          ),
        ),
      );

      final churned = _card(tester, CustomerSegment.churned);
      expect(
        churned.trend,
        TtTrend.up,
        reason:
            'rời bỏ tăng 10 → 16 thì MŨI TÊN phải lên, vì nó nói con số đi '
            'hướng nào. Cho nó xuống là mâu thuẫn với chính dòng "+6".',
      );
      expect(
        churned.upIsGood,
        isFalse,
        reason:
            'thêm khách rời bỏ là tin XẤU — màu phải nói điều đó, và đây '
            'là chỗ duy nhất được nói',
      );

      final loyal = _card(tester, CustomerSegment.loyal);
      expect(loyal.trend, TtTrend.up);
      expect(loyal.upIsGood, isTrue);
    },
  );

  testWidgets('§2b nguy cơ rời bỏ GIẢM là tin TỐT', (tester) async {
    await tester.pumpWidget(
      _host(
        _view(
          now: const {CustomerSegment.atRisk: 4},
          before: const {CustomerSegment.atRisk: 13},
        ),
      ),
    );
    final atRisk = _card(tester, CustomerSegment.atRisk);
    expect(
      atRisk.trend,
      TtTrend.down,
      reason: 'nguy cơ giảm 13 → 4: mũi tên XUỐNG theo con số',
    );
    expect(
      atRisk.upIsGood,
      isFalse,
      reason:
          'ít khách nguy cơ hơn là tin tốt ⇒ mũi tên xuống phải mang màu '
          'TỐT, không phải màu báo động',
    );
  });

  testWidgets('§3 thẻ cảnh báo hiện cả khi bằng 0', (tester) async {
    await tester.pumpWidget(
      _host(_view(now: const {CustomerSegment.loyal: 5})),
    );

    expect(find.byKey(const Key('segment-card-at_risk')), findsOneWidget);
    expect(find.byKey(const Key('segment-card-churned')), findsOneWidget);
    expect(
      find.byKey(const Key('segment-card-one_time')),
      findsNothing,
      reason: 'phân khúc bình thường bằng 0 thì không cần chiếm chỗ',
    );
  });

  testWidgets('§4 thứ tự là VÒNG ĐỜI, không phải số lượng', (tester) async {
    await tester.pumpWidget(
      _host(
        _view(
          now: const {
            CustomerSegment.churned: 99,
            CustomerSegment.newcomer: 1,
            CustomerSegment.loyal: 50,
          },
        ),
      ),
    );

    final keys = tester
        .widgetList<TtMetricCard>(find.byType(TtMetricCard))
        .map((c) => (c.key as ValueKey<String>?)?.value ?? '')
        .toList();
    expect(
      keys.indexOf('segment-card-new'),
      lessThan(keys.indexOf('segment-card-loyal')),
    );
    expect(
      keys.indexOf('segment-card-loyal'),
      lessThan(keys.indexOf('segment-card-churned')),
      reason:
          'sắp theo số lượng thì thứ tự nhảy loạn mỗi lần dữ liệu đổi, và '
          'dải thẻ mất thứ duy nhất nó kể được: một dòng chảy',
    );
  });
}
