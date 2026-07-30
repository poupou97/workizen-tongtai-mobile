import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer_order.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';
import 'package:tongtai/features/tongtai/timeline/business_event_sources.dart';
import 'package:tongtai/features/tongtai/timeline/timeline_service.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_more_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_timeline_screen.dart';

/// WTM-114 — the timeline screen renders grouped events, filters by type and
/// shows an empty state.
void main() {
  DateTime fixedNow() => DateTime(2026, 7, 24);

  /// A small, fully on-screen feed: one finance income + one delivered order.
  TimelineService smallService() => TimelineService([
    FinanceEventSource([
      FinanceTransaction(
        id: 'i',
        type: TransactionType.income,
        category: 'Bán hàng',
        amount: 3000000,
        date: DateTime(2026, 7, 20),
      ),
    ]),
    OrderEventSource([
      CustomerOrder(
        id: 'o',
        customerId: 'c',
        orderNumber: 'DH-1',
        date: DateTime(2026, 7, 18),
        status: OrderStatus.delivered,
        items: const [
          OrderItem(
            productName: 'Quạt',
            category: 'Electronics',
            quantity: 1,
            unitPrice: 500000,
          ),
        ],
      ),
    ]),
  ]);

  Widget host(TimelineService service) => MaterialApp(
    home: TongtaiTimelineScreen(service: service, clock: fixedNow),
  );

  testWidgets('renders events and type filter chips', (tester) async {
    await tester.pumpWidget(host(smallService()));

    expect(find.text('Thu: Bán hàng'), findsOneWidget);
    expect(find.text('Đơn hàng DH-1'), findsOneWidget);
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.byKey(const Key('timeline-filter-finance')), findsOneWidget);
    expect(find.byKey(const Key('timeline-filter-order')), findsOneWidget);
  });

  testWidgets('filtering by type narrows the feed', (tester) async {
    await tester.pumpWidget(host(smallService()));

    expect(find.text('Đơn hàng DH-1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('timeline-filter-finance')));
    await tester.pumpAndSettle();

    // Only finance remains.
    expect(find.text('Đơn hàng DH-1'), findsNothing);
    expect(find.text('Thu: Bán hàng'), findsOneWidget);
  });

  testWidgets('the sample timeline wires all four sources as filters', (
    tester,
  ) async {
    await tester.pumpWidget(host(TimelineService.sample()));

    expect(find.byKey(const Key('timeline-filter-finance')), findsOneWidget);
    expect(find.byKey(const Key('timeline-filter-order')), findsOneWidget);
    expect(
      find.byKey(const Key('timeline-filter-opportunity')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('timeline-filter-journey')), findsOneWidget);
  });

  testWidgets('empty timeline shows the fox empty state', (tester) async {
    await tester.pumpWidget(host(TimelineService(const [])));

    expect(find.byKey(const Key('timeline-empty')), findsOneWidget);
    expect(find.text('Chưa có hoạt động nào'), findsOneWidget);
  });

  testWidgets('the More menu opens the Timeline', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: TongtaiMoreScreen())),
    );

    final entry = find.text('Timeline');
    await tester.scrollUntilVisible(
      entry,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(find.byType(TongtaiTimelineScreen), findsOneWidget);
  });
}
