import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_summary.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';
import 'package:tongtai/features/tongtai/metrics/business_metrics.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_context_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_finance_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';

/// WTM-196 (F-1) — Finance and Home must not disagree about the money.
///
/// The defect: `BusinessMetrics` counted **orders**, `FinanceSummary` counted
/// hand-entered **transactions**, and nothing bridged them. A seller with ten
/// recorded orders opened Finance and read ₫0 income and a negative profit,
/// while Home showed real revenue — two authoritative-looking answers to the
/// same question.
void main() {
  CustomerOrder order(
    String id, {
    required double amount,
    required DateTime date,
    OrderStatus status = OrderStatus.delivered,
  }) => CustomerOrder(
    id: id,
    customerId: 'c1',
    orderNumber: 'DH-$id',
    date: date,
    status: status,
    items: [
      OrderItem(
        productName: 'SP',
        category: 'Home',
        quantity: 1,
        unitPrice: amount,
      ),
    ],
  );

  FinanceTransaction txn(
    String id, {
    required double amount,
    required TransactionType type,
    required DateTime date,
    String category = 'Nhập hàng',
  }) => FinanceTransaction(
    id: id,
    type: type,
    category: category,
    amount: amount,
    date: date,
  );

  final now = DateTime(2026, 8, 1);

  test('sales revenue reaches Finance income', () {
    final summary = FinanceService(
      const [],
      orders: [
        order('o1', amount: 3000000, date: DateTime(2026, 8, 1)),
        order('o2', amount: 2000000, date: DateTime(2026, 8, 2)),
      ],
    ).summaryAsOf(now);

    expect(summary.incomeMtd, 5000000);
    expect(summary.salesIncomeMtd, 5000000);
  });

  test('Finance agrees with Home on the same orders', () {
    // The cross-check. Testing each side alone is what let them drift: both
    // were internally consistent and told the seller different things.
    final orders = [
      order('o1', amount: 3000000, date: DateTime(2026, 3, 4)),
      order('o2', amount: 2500000, date: DateTime(2026, 7, 9)),
      order('o3', amount: 1500000, date: DateTime(2026, 8, 1)),
    ];

    final home = BusinessMetrics.from(orders: orders, customersCount: 1);
    final finance = FinanceService(const [], orders: orders).summaryAsOf(now);

    expect(
      finance.salesIncomeYtd,
      home.revenue,
      reason: 'Finance and Home must answer "how much did I make" identically',
    );
  });

  test('a cancelled order counts in neither', () {
    final orders = [
      order('o1', amount: 3000000, date: DateTime(2026, 8, 1)),
      order(
        'x',
        amount: 9000000,
        date: DateTime(2026, 8, 1),
        status: OrderStatus.cancelled,
      ),
    ];

    final home = BusinessMetrics.from(orders: orders, customersCount: 1);
    final finance = FinanceService(const [], orders: orders).summaryAsOf(now);

    expect(finance.salesIncomeYtd, 3000000);
    expect(finance.salesIncomeYtd, home.revenue);
  });

  test('hand-entered income stays distinguishable from sales', () {
    // AC2: the seller should see which part the app worked out and which part
    // they typed in — folding them together silently would hide the split.
    final summary = FinanceService(
      [
        txn(
          't1',
          amount: 500000,
          type: TransactionType.income,
          date: DateTime(2026, 8, 1),
          category: 'Thu khác',
        ),
      ],
      orders: [order('o1', amount: 3000000, date: DateTime(2026, 8, 1))],
    ).summaryAsOf(now);

    expect(summary.incomeMtd, 3500000);
    expect(summary.salesIncomeMtd, 3000000);
    expect(summary.manualIncomeMtd, 500000);
  });

  test('sales revenue lands in the right month of the cashflow chart', () {
    final summary = FinanceService(
      const [],
      orders: [
        order('o1', amount: 1000000, date: DateTime(2026, 7, 15)),
        order('o2', amount: 2000000, date: DateTime(2026, 8, 15)),
      ],
    ).summaryAsOf(now);

    final july = summary.monthly.firstWhere((m) => m.month == 7);
    final august = summary.monthly.firstWhere((m) => m.month == 8);

    expect(july.income, 1000000);
    expect(august.income, 2000000);
  });

  test('profit is revenue minus expenses, not minus everything', () {
    final summary = FinanceService(
      [
        txn(
          't1',
          amount: 1000000,
          type: TransactionType.expense,
          date: DateTime(2026, 8, 1),
        ),
      ],
      orders: [order('o1', amount: 3000000, date: DateTime(2026, 8, 1))],
    ).summaryAsOf(now);

    expect(summary.profitMtd, 2000000);
    expect(
      summary.profitMtd,
      greaterThan(0),
      reason: 'a shop that sold ₫3m and spent ₫1m is not losing money',
    );
  });

  test('a business with no orders and no rows is still empty', () {
    final summary = FinanceService(const [], orders: const []).summaryAsOf(now);

    expect(summary.hasActivity, isFalse);
    expect(summary.incomeYtd, 0);
  });

  group('production wiring', () {
    test('the Finance context is given the order repository', () async {
      // Same shape as `backup_wiring_test`: the slot is nullable so existing
      // call sites compile, which means forgetting it is **not** a compile
      // error — and a Finance screen reading ₫0 looks plausible.
      final container = ProviderContainer(
        overrides: [
          financeRepositoryProvider.overrideWithValue(
            InMemoryFinanceRepository(const []),
          ),
          orderRepositoryProvider.overrideWithValue(
            InMemoryOrderRepository([
              order('o1', amount: 4000000, date: DateTime(2026, 8, 1)),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final summary = await container.read(financeContextProvider).load();

      expect(
        summary.salesIncomeYtd,
        4000000,
        reason: 'the production provider never passed orders before WTM-196',
      );
    });
  });
}
