// Khối Tài chính của sản phẩm — WTM-420 (concept-1 `cp6`).
//
// Ba luật, và cả ba là chuyện **không được nói dối bằng con số**:
//
//   §1 thiếu giá vốn ⇒ hiện lời MỜI khai, KHÔNG hiện lãi bằng 0;
//   §2 "đo được" và "dự kiến" nằm ở hai khối tách rời, và khối dự kiến mang
//      nhãn dự kiến ngay trên con số — trộn hai thứ là lỗi WTM-384;
//   §3 chưa bán được cái nào ⇒ nói *chưa có*, không phải doanh thu 0.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_profit.dart';
import 'package:tongtai/features/tongtai/finance/true_profit.dart';
import 'package:tongtai/features/tongtai/inventory/product_unit_economics.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tongtai_product_finance.dart';

Widget _host({
  required ProductUnitEconomics economics,
  ProductProfit? sold,
  int windowDays = 30,
}) => MaterialApp(
  locale: const Locale('vi'),
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en'), Locale('vi')],
  home: Scaffold(
    body: SingleChildScrollView(
      child: TongtaiProductFinance(
        economics: economics,
        sold: sold,
        windowDays: windowDays,
      ),
    ),
  ),
);

ProductProfit _sold({
  int units = 12,
  double revenue = 1200000,
  TrueProfit profit = const ProfitKnown(
    revenue: 1200000,
    cogs: 700000,
    settlementImpact: -50000,
  ),
}) => ProductProfit(
  productId: 'p',
  name: 'Sản phẩm',
  revenue: revenue,
  units: units,
  profit: profit,
  orderCount: 5,
);

void main() {
  testWidgets('§1 thiếu giá vốn ⇒ MỜI khai, không hiện lãi bằng 0', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        economics: const ProductUnitEconomics(
          sellingPrice: 100000,
          costPrice: null,
          stockOnHand: 20,
        ),
      ),
    );

    expect(
      find.byKey(const Key('product-finance-cost-missing')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('product-finance-profit-per-unit')),
      findsNothing,
      reason: 'không có giá vốn thì không có lãi — in một con số ở đây là bịa',
    );
    expect(find.byKey(const Key('product-finance-margin')), findsNothing);
    expect(
      find.byKey(const Key('product-finance-projected')),
      findsNothing,
      reason: 'dự phóng cũng dựng trên giá vốn, nên nó cũng phải im',
    );
  });

  testWidgets('§2 đo được và dự kiến là HAI khối, dự kiến có nhãn riêng', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        economics: const ProductUnitEconomics(
          sellingPrice: 100000,
          costPrice: 60000,
          stockOnHand: 34,
        ),
        sold: _sold(),
      ),
    );

    // Đo được
    expect(
      find.byKey(const Key('product-finance-real-profit')),
      findsOneWidget,
    );
    // Dự kiến — có nhãn nói rõ là dự kiến, kèm số lượng tồn thật
    expect(find.byKey(const Key('product-finance-projected')), findsOneWidget);
    expect(find.textContaining('Dự kiến'), findsOneWidget);
    expect(find.textContaining('34'), findsWidgets);
  });

  testWidgets('§3 chưa bán được cái nào ⇒ nói CHƯA CÓ, không phải 0', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        economics: const ProductUnitEconomics(
          sellingPrice: 100000,
          costPrice: 60000,
          stockOnHand: 5,
        ),
        sold: null,
      ),
    );

    expect(find.byKey(const Key('product-finance-no-sales')), findsOneWidget);
    expect(
      find.byKey(const Key('product-finance-real-profit')),
      findsNothing,
      reason:
          'chưa bán mà in "lợi nhuận thật 0 đ" thì con số ấy tự xưng là '
          'một phép đo',
    );
  });

  testWidgets('§4 lợi nhuận thật CHƯA TÍNH ĐƯỢC ⇒ dấu —, không phải 0', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        economics: const ProductUnitEconomics(
          sellingPrice: 100000,
          costPrice: 60000,
          stockOnHand: 5,
        ),
        sold: _sold(
          profit: ProfitInsufficient(const [ProfitBlocker.missingCost]),
        ),
      ),
    );

    final row = find.byKey(const Key('product-finance-real-profit'));
    expect(row, findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.text('—')),
      findsOneWidget,
      reason: '`TrueProfit` có nhánh "chưa tính được"; màn phải tôn trọng nó',
    );
  });
}
