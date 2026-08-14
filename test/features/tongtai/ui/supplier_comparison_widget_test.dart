// WTM-409 — bày so sánh nhà cung cấp, và **nói ra cái chưa biết**.
//
// Luật canh:
//
//   §1 `null` = CHƯA BIẾT ⇒ không in dòng so sánh, và phải hiện "chưa biết"
//   §2 nêu cả hai mặt của đánh đổi (rẻ hơn + chậm hơn), không chỉ mặt đẹp
//   §3 một báo giá duy nhất ⇒ không dựng khung rỗng
//   §4 không tự chọn hộ — có câu nhắc người bán mới là người quyết
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_models.dart';
import 'package:tongtai/features/tongtai/commerce/supplier_comparison.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tongtai_supplier_comparison.dart';

SupplierQuote quote({
  required String id,
  required String name,
  required double cost,
  int? leadTimeDays,
  double? moq,
}) => SupplierQuote(
  id: id,
  productId: 'p1',
  supplierName: name,
  unitCost: cost,
  currency: 'VND',
  leadTimeDays: leadTimeDays,
  minimumOrderQuantity: moq,
  quotedAt: DateTime(2026, 8, 14),
);

Future<void> pump(WidgetTester tester, SupplierComparison c) =>
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
            child: TongtaiSupplierComparison(comparison: c),
          ),
        ),
      ),
    );

void main() {
  testWidgets(
    '⭐ §1 thiếu thời gian giao ⇒ nói CHƯA BIẾT, không nói "nhanh ngang"',
    (tester) async {
      // Nguồn A biết giao 10 ngày; nguồn B rẻ hơn nhưng **chưa ai hỏi** giao bao
      // lâu. Coi `null` là 0 sẽ biến B thành "giao nhanh hơn 10 ngày" — đúng lời
      // cảnh báo nguyên văn trong `SupplierOption.slowerByDays`.
      final c = SupplierComparison.from(
        productId: 'p1',
        quotes: [
          quote(
            id: 'a',
            name: 'Nguồn A',
            cost: 100000,
            leadTimeDays: 10,
            moq: 10,
          ),
          quote(id: 'b', name: 'Nguồn B', cost: 88000),
        ],
        currentUnitCost: 100000,
      );
      await pump(tester, c);
      await tester.pumpAndSettle();

      expect(find.textContaining('Rẻ hơn 12%'), findsOneWidget);
      expect(find.textContaining('chưa biết thời gian giao'), findsOneWidget);
      expect(
        find.textContaining('chưa biết số lượng tối thiểu'),
        findsOneWidget,
      );
      // ⛔ Không được có bất kỳ dòng "giao nhanh/chậm hơn" nào cho nguồn B.
      expect(find.textContaining('Giao nhanh hơn'), findsNothing);
      expect(find.textContaining('Giao chậm hơn'), findsNothing);
    },
  );

  testWidgets('§2 rẻ hơn NHƯNG chậm hơn ⇒ hiện CẢ HAI mặt', (tester) async {
    final c = SupplierComparison.from(
      productId: 'p1',
      quotes: [
        quote(id: 'a', name: 'Nguồn A', cost: 100000, leadTimeDays: 5, moq: 10),
        quote(id: 'b', name: 'Nguồn B', cost: 88000, leadTimeDays: 11, moq: 60),
      ],
      currentUnitCost: 100000,
    );
    await pump(tester, c);
    await tester.pumpAndSettle();

    expect(find.textContaining('Rẻ hơn 12%'), findsOneWidget);
    expect(
      find.textContaining('Giao chậm hơn 6 ngày'),
      findsOneWidget,
      reason: 'chỉ khoe mặt rẻ mà giấu mặt chậm là bán một nửa sự thật',
    );
    expect(find.textContaining('Phải đặt thêm'), findsOneWidget);
  });

  testWidgets('§3 chỉ MỘT báo giá ⇒ không dựng khối nào', (tester) async {
    final c = SupplierComparison.from(
      productId: 'p1',
      quotes: [quote(id: 'a', name: 'Nguồn A', cost: 100000)],
      currentUnitCost: 100000,
    );
    expect(c.isComparable, isFalse);
    await pump(tester, c);
    await tester.pumpAndSettle();
    expect(find.byKey(TongtaiSupplierComparison.sectionKey), findsNothing);
  });

  testWidgets('§4 không chọn hộ — có câu nhắc người bán quyết', (tester) async {
    final c = SupplierComparison.from(
      productId: 'p1',
      quotes: [
        quote(id: 'a', name: 'Nguồn A', cost: 100000, leadTimeDays: 5, moq: 10),
        quote(id: 'b', name: 'Nguồn B', cost: 88000, leadTimeDays: 11, moq: 60),
      ],
      currentUnitCost: 100000,
    );
    await pump(tester, c);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('product-detail-suppliers-tradeoff')),
      findsOneWidget,
      reason: 'khối đang đưa phán quyết thay vì nêu đánh đổi',
    );
  });
}
