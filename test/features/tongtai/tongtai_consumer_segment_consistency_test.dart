// ⭐ Màn Khách hàng KHÔNG được nói hai chuyện về cùng một phân khúc — WTM-419.
//
// ## Vì sao test này tồn tại
//
// Dogfood Nokia 2026-08-15 (build +17). Trên **một màn hình**, cách nhau khoảng
// 600px:
//
//     ô tóm tắt:  VIP  0        Mới  4
//     chip:       Khách VIP (8) Khách mới (14)
//
// Người bán nhìn thấy cả bốn con số cùng lúc. **2863 test xanh.**
//
// Không test nào bắt được, vì mọi test đều kiểm *một* con số có đúng không —
// còn lỗi này nằm ở **quan hệ giữa hai con số**. Ba nguồn khác nhau đội chung
// một nhãn: một trường xếp hạng không đường ghi nào set · một phép đếm
// `orderCount == 0` gắn nhãn "Mới" (thật ra là *chưa mua*) · và nhãn lưu sẵn
// từ file nhập.
//
// Nên test này dựng màn với dữ liệu thật rồi **đọc lại chính hai chỗ ấy trên
// cây widget** và bắt chúng khớp nhau. Nó là bản sao cơ học của việc Founder
// nhìn xuống màn hình.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/l10n/app_strings.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_consumer_screen.dart';

final _now = DateTime(2026, 8, 15);

Customer _customer(String id) => Customer(
  id: id,
  name: 'Khách $id',
  phone: '',
  location: '',
  orderCount: 0,
  totalSpent: 0,
  lastPurchaseDate: null,
  // ⚠️ Nhãn lưu sẵn CỐ Ý sai sự thật: đây là nguồn cũ, và test phải chứng minh
  // màn KHÔNG còn đọc nó nữa. Nếu ai nối lại nguồn này, chip sẽ nói "VIP" cho
  // một khách mới mua một lần và test đỏ.
  segments: const ['vip', 'loyal'],
);

CustomerOrder _order(String id, String customerId, DateTime at, double total) =>
    CustomerOrder(
      id: id,
      customerId: customerId,
      orderNumber: 'DH-$id',
      date: at,
      status: OrderStatus.delivered,
      items: [
        OrderItem(
          productName: 'X',
          category: 'Home',
          quantity: 1,
          unitPrice: total,
        ),
      ],
    );

/// Con số trong ô tóm tắt, đọc theo nhãn ngay dưới nó.
int _statUnder(WidgetTester tester, String label) {
  final column = find.ancestor(
    of: find.text(label),
    matching: find.byType(Column),
  );
  final value = find.descendant(of: column.first, matching: find.byType(Text));
  final texts = tester.widgetList<Text>(value).map((t) => t.data).toList();
  return int.parse(texts.firstWhere((t) => int.tryParse(t ?? '') != null)!);
}

/// Con số trong chip `Nhãn (N)`.
int? _chipCount(WidgetTester tester, String label) {
  for (final t in tester.widgetList<Text>(find.byType(Text))) {
    final data = t.data;
    if (data != null && data.startsWith('$label (')) {
      return int.parse(RegExp(r'\((\d+)\)').firstMatch(data)!.group(1)!);
    }
  }
  return null;
}

void main() {
  testWidgets('ô tóm tắt và chip phân khúc phải nói CÙNG một con số', (
    tester,
  ) async {
    // Ba khách mua đều đặn (nhịp ~20 ngày, còn trong nhịp) + một khách chưa mua.
    final customers = [
      for (final id in ['a', 'b', 'c', 'd']) _customer(id),
    ];
    final orders = <CustomerOrder>[
      for (final id in ['a', 'b', 'c'])
        for (var k = 1; k <= 4; k++)
          _order(
            '$id-$k',
            id,
            _now.subtract(Duration(days: 5 + (4 - k) * 20)),
            1000000,
          ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerRepositoryProvider.overrideWithValue(
            InMemoryCustomerRepository(customers),
          ),
          orderRepositoryProvider.overrideWithValue(
            InMemoryOrderRepository(orders),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('vi')],
          home: const TongtaiConsumerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const l10n = AppStringsVi();

    for (final (statLabel, chipLabel) in [
      (l10n.segVip, 'Khách VIP'),
      (l10n.segNew, 'Khách mới'),
    ]) {
      final stat = _statUnder(tester, statLabel);
      final chip = _chipCount(tester, chipLabel) ?? 0;
      expect(
        stat,
        chip,
        reason:
            'ô tóm tắt "$statLabel" = $stat nhưng chip "$chipLabel" = $chip. '
            'Hai con số cho cùng một phân khúc, hiện cùng lúc trên một màn — '
            'đúng lỗi đã thấy trên Nokia 2026-08-15.',
      );
    }
  });
}
