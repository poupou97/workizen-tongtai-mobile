import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_create_order_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_inventory_picker_screen.dart';

/// WTM-126 — the Create Order flow: an order line must reference an inventory
/// product (via the picker), and the line snapshots the product identity + the
/// actual sold price at sale time.
void main() {
  final customer = Customer(
    id: 'c1',
    name: 'Phương Nguyễn',
    phone: '+84912345678',
    location: 'Hà Nội',
    orderCount: 0,
    totalSpent: 0,
    lastPurchaseDate: null,
  );

  final products = [
    Product(
      id: 'p1',
      sku: 'SKU-EL-001',
      name: 'Quạt mini',
      category: 'Electronics',
      quantity: 20,
      pricePerUnit: 89000,
      reorderLevel: 5,
      updatedAt: DateTime(2026, 7, 1),
    ),
    Product(
      id: 'p2',
      sku: 'SKU-FA-002',
      name: 'Áo thun',
      category: 'Fashion',
      quantity: 8,
      pricePerUnit: 120000,
      reorderLevel: 3,
      updatedAt: DateTime(2026, 7, 1),
    ),
  ];

  void useTallViewport(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(600, 1400);
  }

  /// Pumps the screen as the root so its body buttons are directly hit-testable;
  /// [captured] receives the order on save (via onSubmit).
  Future<List<CustomerOrder>> pumpForm(WidgetTester tester) async {
    final captured = <CustomerOrder>[];
    await tester.pumpWidget(
      MaterialApp(
        home: TongtaiCreateOrderScreen(
          customer: customer,
          products: products,
          clock: () => DateTime(2026, 7, 25, 9),
          idFactory: () => 'order-1',
          orderNumberFactory: (_) => 'DH-2026-9001',
          onSubmit: captured.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return captured;
  }

  Future<void> addLine(
    WidgetTester tester, {
    required String productId,
    required String quantity,
    String? price,
  }) async {
    await tester.tap(find.byKey(const Key('create-order-add-item')));
    await tester.pumpAndSettle();
    expect(find.byType(TongtaiInventoryPickerScreen), findsOneWidget);
    await tester.tap(find.byKey(Key('picker-product-$productId')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('order-item-quantity')),
      quantity,
    );
    if (price != null) {
      await tester.enterText(find.byKey(const Key('order-item-price')), price);
    }
    await tester.tap(find.byKey(const Key('order-item-add')));
    await tester.pumpAndSettle();
  }

  testWidgets('a line references an inventory product and snapshots it', (
    tester,
  ) async {
    useTallViewport(tester);
    final captured = await pumpForm(tester);

    expect(find.text('Customer: Phương Nguyễn'), findsOneWidget);
    await addLine(tester, productId: 'p1', quantity: '3');

    expect(find.text('Quạt mini'), findsOneWidget);
    await tester.tap(find.byKey(const Key('create-order-save')));
    await tester.pumpAndSettle();

    expect(captured, hasLength(1));
    final order = captured.single;
    expect(order.customerId, 'c1');
    expect(order.orderNumber, 'DH-2026-9001');
    expect(order.items, hasLength(1));
    final line = order.items.single;
    expect(line.productId, 'p1'); // references inventory
    expect(line.productName, 'Quạt mini');
    expect(line.sku, 'SKU-EL-001');
    expect(line.quantity, 3);
    expect(line.unitPrice, 89000); // inventory default sold price
    expect(order.totalAmount, 267000);
  });

  testWidgets('the sold price may override the inventory default', (
    tester,
  ) async {
    useTallViewport(tester);
    final captured = await pumpForm(tester);

    // Override 120,000 → 99,000 (a discount at sale time).
    await addLine(tester, productId: 'p2', quantity: '2', price: '99000');
    await tester.tap(find.byKey(const Key('create-order-save')));
    await tester.pumpAndSettle();

    final line = captured.single.items.single;
    expect(line.productId, 'p2');
    expect(line.unitPrice, 99000); // overridden sold price, not 120,000
    expect(captured.single.totalAmount, 198000);
  });

  testWidgets('save is refused with no line items', (tester) async {
    useTallViewport(tester);
    final captured = await pumpForm(tester);

    await tester.tap(find.byKey(const Key('create-order-save')));
    await tester.pumpAndSettle();

    expect(find.text('Add at least one product'), findsOneWidget);
    expect(captured, isEmpty);
  });

  testWidgets('a line can be removed before saving', (tester) async {
    useTallViewport(tester);
    final captured = await pumpForm(tester);

    await addLine(tester, productId: 'p1', quantity: '1');
    await addLine(tester, productId: 'p2', quantity: '1');
    expect(find.text('2 items'), findsOneWidget);

    await tester.tap(find.byKey(const Key('order-line-remove-0')));
    await tester.pumpAndSettle();
    expect(find.text('1 item'), findsOneWidget);

    await tester.tap(find.byKey(const Key('create-order-save')));
    await tester.pumpAndSettle();
    expect(captured.single.items, hasLength(1));
  });

  testWidgets('⭐ nút xoá dòng phải NÓI RA nó xoá gì (WTM-432)', (tester) async {
    // ## Vì sao suite accessibility không bắt được lỗi này
    //
    // `accessibility_test.dart` chạy `labeledTapTargetGuideline` — *"mọi thứ
    // bấm được đều có tên"* — trên **28 màn**, cả hai locale, và màn này CÓ
    // trong danh sách. Nó vẫn bỏ lọt, vì nó quét màn ở **trạng thái KHỞI ĐẦU**:
    // `_items` rỗng ⇒ `itemBuilder` không dựng dòng nào ⇒ **nút xoá không tồn
    // tại** ⇒ guideline không có gì để kiểm.
    //
    // Cổng không mù về *màn*, nó mù về **trạng thái**. Mọi widget chỉ sinh ra
    // sau tương tác — dòng đơn, kết quả tìm kiếm, thẻ lỗi — đều nằm ngoài tầm
    // nó, dù màn "đã được phủ". Nên khẳng định phải sống ở ĐÂY, nơi test đã
    // lái màn vào đúng trạng thái ấy.
    //
    // ## Vì sao nhãn phải kèm TÊN SẢN PHẨM
    //
    // Đây là hành động **phá huỷ**, và có nhiều nút `×` giống hệt nhau xếp
    // chồng. Một nhãn *"Xoá"* trần khiến người dùng khiếm thị nghe ba nút y
    // như nhau và không biết cái nào xoá cái gì.
    useTallViewport(tester);
    await pumpForm(tester);
    await addLine(tester, productId: 'p1', quantity: '1');

    // Tên sản phẩm lấy từ chính dòng vừa thêm, không viết tay: một chuỗi ghim
    // sẽ đỏ vì đổi dữ liệu mẫu chứ không vì mất nhãn.
    final line = tester.widget<ListTile>(
      find.ancestor(
        of: find.byKey(const Key('order-line-remove-0')),
        matching: find.byType(ListTile),
      ),
    );
    final productName = (line.title! as Text).data!;

    final button = tester.widget<IconButton>(
      find.byKey(const Key('order-line-remove-0')),
    );
    expect(
      button.tooltip,
      isNotNull,
      reason:
          'nút xoá dòng không có tên — trình đọc màn hình chỉ đọc ra một biểu '
          'tượng, không nói nó xoá cái gì',
    );
    expect(
      button.tooltip,
      contains(productName),
      reason:
          'nhãn phải chứa TÊN sản phẩm: nhiều nút xoá giống hệt nhau xếp '
          'chồng, "Xoá" trần không phân biệt được cái nào',
    );
  });
}
