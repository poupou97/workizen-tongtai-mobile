import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/producer/supplier.dart';
import 'package:tongtai/features/tongtai/producer/supplier_profile.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_supplier_detail_screen.dart';

/// Real widget tests for the WTM-64 Supplier Detail View: every acceptance
/// criterion is exercised through the rendered UI — business profile, product
/// catalog, ratings + certifications, transaction summary, and contact with a
/// working messaging flow.
void main() {
  const supplier = Supplier(
    id: 's1',
    name: 'TechPro Wholesale',
    location: 'Shenzhen, China',
    rating: 4.8,
    reviewCount: 245,
    categories: ['Electronics', 'Accessories'],
    minOrderUnits: 100,
    leadTime: '7-14 days',
  );
  final profile = buildSupplierProfile(supplier);

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: TongtaiSupplierDetailScreen(profile: profile)),
    );
    await tester.pumpAndSettle();
  }

  group('supplierDetailContentWidth (responsive helper)', () {
    test('phone width is used as-is', () {
      expect(supplierDetailContentWidth(390), 390);
    });

    test('wide tablet width is capped', () {
      expect(supplierDetailContentWidth(1200), 680);
    });
  });

  testWidgets('renders the business profile header (AC1)', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Supplier'), findsOneWidget); // AppBar
    expect(find.text('TechPro Wholesale'), findsOneWidget); // name
    expect(find.text('Shenzhen, China'), findsOneWidget); // location
    expect(find.text(profile.initials), findsOneWidget); // logo monogram
  });

  testWidgets('renders the About description (AC1)', (tester) async {
    await pumpScreen(tester);

    expect(find.text('About'), findsOneWidget);
    expect(find.textContaining('trusted'), findsOneWidget);
    expect(find.textContaining('7-14 days'), findsOneWidget);
  });

  testWidgets('renders contact details and the message button (AC4)', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Contact'), findsOneWidget);
    expect(find.text(profile.contactEmail!), findsOneWidget);
    expect(find.text(profile.contactPhone!), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Message supplier'),
      findsOneWidget,
    );
  });

  testWidgets('messaging: compose and send shows a confirmation (AC4)', (
    tester,
  ) async {
    await pumpScreen(tester);

    // Open the composer (the button sits below the fold, so reveal it first).
    final messageButton = find.widgetWithText(FilledButton, 'Message supplier');
    await tester.ensureVisible(messageButton);
    await tester.pumpAndSettle();
    await tester.tap(messageButton);
    await tester.pumpAndSettle();

    expect(find.text('Message TechPro Wholesale'), findsOneWidget);
    final sendButton = find.widgetWithText(FilledButton, 'Send');
    expect(sendButton, findsOneWidget);

    // Send is disabled until a message is typed.
    expect(tester.widget<FilledButton>(sendButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'What is your MOQ?');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(sendButton).onPressed, isNotNull);

    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    // Sheet closes and a confirmation snackbar appears.
    expect(find.text('Message TechPro Wholesale'), findsNothing);
    expect(find.text('Message sent to TechPro Wholesale'), findsOneWidget);
  });

  testWidgets('forSupplier constructor builds the profile', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: TongtaiSupplierDetailScreen.forSupplier(supplier)),
    );
    await tester.pumpAndSettle();

    expect(find.text('TechPro Wholesale'), findsOneWidget);
  });

  // ── WTM-421 · Founder chốt 2026-08-15 ──────────────────────────────────
  //
  // Ba test AC cũ ở đây từng khẳng định màn PHẢI bày chứng chỉ, danh mục và
  // lịch sử giao dịch. Hợp đồng ấy đã bị thu hồi: cả ba khối hiện những giá
  // trị sinh bằng công thức trên `reviewCount`/`rating`, không đọc nguồn nào.
  //
  // Không xoá trắng (P-37: dựng lại một màn thì cửa đổi khoá, đừng bỏ guard) —
  // ba khẳng định dưới đây canh đúng **chiều ngược lại**, để không ai dựng lại
  // chúng mà không đọc WTM-421.
  testWidgets('⛔ KHÔNG bày chứng chỉ / danh mục / lịch sử giao dịch bịa', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: TongtaiSupplierDetailScreen.forSupplier(supplier)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('ISO 9001'),
      findsNothing,
      reason:
          'chứng chỉ gán cho MỌI nhà cung cấp — một tuyên bố pháp lý mà '
          'app không kiểm, và người bán có thể xuống tiền vì tin nó',
    );
    expect(find.byKey(const Key('supplier-detail-catalog')), findsNothing);
    expect(find.byKey(const Key('supplier-detail-transactions')), findsNothing);
  });

  testWidgets('§ đánh giá sao thì GIỮ — có nguồn, dù nguồn là bên thứ ba', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: TongtaiSupplierDetailScreen.forSupplier(supplier)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('supplier-detail-ratings')),
      findsOneWidget,
      reason:
          'gỡ luôn cả rating là phản ứng thái quá: nó đến từ hồ sơ NCC đã '
          'nhập, và màn nói rõ "từ N đánh giá"',
    );
  });
}
