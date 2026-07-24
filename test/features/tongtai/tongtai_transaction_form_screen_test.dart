import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_transaction_form_screen.dart';

/// WTM-113 — the Add Transaction form validates and pops the built transaction.
void main() {
  DateTime fixedNow() => DateTime(2026, 7, 24);

  /// A viewport tall enough to show the whole form without scrolling, so both
  /// the amount error (top) and the save button (bottom) are on screen at once.
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('save with a blank form surfaces field errors, no pop', (
    tester,
  ) async {
    useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(home: TongtaiTransactionFormScreen(clock: fixedNow)),
    );

    await tester.tap(find.byKey(const Key('transaction-save')));
    await tester.pump();

    expect(find.text('Nhập số tiền hợp lệ (> 0)'), findsOneWidget);
    expect(find.text('Chọn hoặc nhập nhóm'), findsOneWidget);
    // Still on the form.
    expect(find.byType(TongtaiTransactionFormScreen), findsOneWidget);
  });

  testWidgets('fills income + category and saves, popping the transaction', (
    tester,
  ) async {
    useTallViewport(tester);
    FinanceTransaction? popped;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  popped = await Navigator.of(context).push<FinanceTransaction>(
                    MaterialPageRoute(
                      builder: (_) =>
                          TongtaiTransactionFormScreen(clock: fixedNow),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('transaction-type-income')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('transaction-amount')),
      '1500000',
    );
    await tester.tap(find.byKey(const Key('transaction-cat-Bán hàng')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('transaction-save')));
    await tester.pumpAndSettle();

    expect(popped, isNotNull);
    expect(popped!.type, TransactionType.income);
    expect(popped!.amount, 1500000);
    expect(popped!.category, 'Bán hàng');
    expect(popped!.date, DateTime(2026, 7, 24));
  });
}
