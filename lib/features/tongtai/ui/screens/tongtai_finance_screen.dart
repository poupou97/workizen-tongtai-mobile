import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tongtai_formatters.dart';
import '../../finance/finance_controller.dart';
import '../../finance/finance_summary.dart';
import '../../finance/finance_transaction.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../providers/tongtai_finance_provider.dart';
import '../widgets/tongtai_fox_mascot.dart';
import 'tongtai_transaction_form_screen.dart';

/// Finance dashboard (WTM-27, WTM-113, WTM-120) — income, expenses, profit and
/// margin over the transaction ledger, an income-vs-expense cashflow chart, the
/// expense breakdown by category, and a recent-activity feed. The FAB adds a
/// transaction that flows straight into the figures.
///
/// Reads/writes through a [FinanceController] over a [FinanceRepository]
/// (WTM-120): the real app persists to Drift (User Data First — starts empty);
/// tests inject an in-memory controller. Both `controller` and `clock` are
/// injectable so every figure is deterministic under test.
class TongtaiFinanceScreen extends ConsumerStatefulWidget {
  const TongtaiFinanceScreen({super.key, this.controller, this.clock});

  /// Injectable ledger. When provided it is *not* disposed here.
  final FinanceController? controller;
  final DateTime Function()? clock;

  static const Color _income = TongtaiDesignTokens.producerGreen;
  static const Color _expense = TongtaiDesignTokens.error;

  @override
  ConsumerState<TongtaiFinanceScreen> createState() =>
      _TongtaiFinanceScreenState();
}

class _TongtaiFinanceScreenState extends ConsumerState<TongtaiFinanceScreen> {
  late final FinanceController _controller;
  late final bool _ownsController;
  late final DateTime Function() _clock;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      // Real app: persistent Drift ledger (WTM-120), starts empty for new users.
      _controller = FinanceController(ref.read(financeRepositoryProvider));
      _ownsController = true;
    }
    _clock = widget.clock ?? DateTime.now;
    // Load the ledger from its source (Drift / sample / in-memory).
    _controller.hydrate();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _addTransaction() async {
    final result = await Navigator.of(context).push<FinanceTransaction>(
      MaterialPageRoute(
        builder: (_) => TongtaiTransactionFormScreen(clock: widget.clock),
      ),
    );
    if (result != null) await _controller.add(result);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final summary = _controller.summaryAsOf(_clock());
        return Scaffold(
          backgroundColor: TongtaiDesignTokens.lightBackground,
          appBar: AppBar(
            title: const Text('Finance · Tài chính'),
            backgroundColor: TongtaiDesignTokens.lightBackground,
            foregroundColor: TongtaiDesignTokens.lightTextPrimary,
            elevation: 0,
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('finance-add'),
            onPressed: _addTransaction,
            backgroundColor: TongtaiDesignTokens.financePurple,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Ghi giao dịch'),
          ),
          body: summary.hasActivity
              ? _FinanceBody(summary: summary, recent: _controller.recent())
              : const _FinanceEmptyState(),
        );
      },
    );
  }
}

class _FinanceBody extends StatelessWidget {
  const _FinanceBody({required this.summary, required this.recent});

  final FinanceSummary summary;
  final List<FinanceTransaction> recent;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      children: [
        // ── KPIs (YTD) ──────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                cardKey: const Key('finance-kpi-income'),
                label: 'Doanh thu · Income',
                value: TongtaiFormatters.vnd(summary.incomeYtd),
                accent: TongtaiFinanceScreen._income,
                icon: Icons.south_west,
              ),
            ),
            const SizedBox(width: TongtaiDesignTokens.spacing3),
            Expanded(
              child: _KpiCard(
                cardKey: const Key('finance-kpi-expense'),
                label: 'Chi phí · Expense',
                value: TongtaiFormatters.vnd(summary.expenseYtd),
                accent: TongtaiFinanceScreen._expense,
                icon: Icons.north_east,
              ),
            ),
          ],
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                cardKey: const Key('finance-kpi-profit'),
                label: 'Lợi nhuận · Profit',
                value: TongtaiFormatters.vnd(summary.profitYtd),
                accent: TongtaiDesignTokens.financePurple,
                icon: Icons.savings_outlined,
              ),
            ),
            const SizedBox(width: TongtaiDesignTokens.spacing3),
            Expanded(
              child: _KpiCard(
                cardKey: const Key('finance-kpi-margin'),
                label: 'Biên LN · Margin',
                value: '${(summary.marginYtd * 100).round()}%',
                accent: TongtaiDesignTokens.consumerBlue,
                icon: Icons.percent,
              ),
            ),
          ],
        ),

        const SizedBox(height: TongtaiDesignTokens.spacing6),

        // ── Cashflow: income vs expense per month ───────────────────────
        const _SectionTitle('Dòng tiền · Thu vs Chi'),
        const SizedBox(height: TongtaiDesignTokens.spacing2),
        const _CashflowLegend(),
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        _CashflowCard(summary: summary),

        const SizedBox(height: TongtaiDesignTokens.spacing6),

        // ── Expense breakdown ───────────────────────────────────────────
        const _SectionTitle('Chi phí theo nhóm · Expenses'),
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        _ExpenseBreakdownCard(
          categories: summary.expenseByCategory,
          total: summary.expenseYtd,
        ),

        const SizedBox(height: TongtaiDesignTokens.spacing6),

        // ── Recent activity ─────────────────────────────────────────────
        const _SectionTitle('Gần đây · Recent'),
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        _RecentCard(transactions: recent),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.cardKey,
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final Key cardKey;
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: cardKey,
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.cardBorderRadius,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TongtaiDesignTokens.heading3Style.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TongtaiDesignTokens.captionStyle.copyWith(
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TongtaiDesignTokens.heading3Style.copyWith(
        color: TongtaiDesignTokens.lightTextPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _CashflowLegend extends StatelessWidget {
  const _CashflowLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dot(TongtaiFinanceScreen._income, 'Thu'),
        const SizedBox(width: TongtaiDesignTokens.spacing4),
        _dot(TongtaiFinanceScreen._expense, 'Chi'),
      ],
    );
  }

  Widget _dot(Color color, String label) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: TongtaiDesignTokens.captionStyle.copyWith(
          color: TongtaiDesignTokens.lightTextSecondary,
        ),
      ),
    ],
  );
}

class _CashflowCard extends StatelessWidget {
  const _CashflowCard({required this.summary});

  final FinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final months = summary.monthly;
    return Container(
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            child: CustomPaint(
              key: const Key('finance-cashflow-chart'),
              size: Size.infinite,
              painter: _CashflowPainter(
                months: months,
                peak: summary.peakMonthlyFlow,
              ),
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final m in months)
                Expanded(
                  child: Text(
                    m.shortLabelVi,
                    textAlign: TextAlign.center,
                    style: TongtaiDesignTokens.captionStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Paints a green income bar and a red expense bar per month, scaled to [peak].
class _CashflowPainter extends CustomPainter {
  _CashflowPainter({required this.months, required this.peak});

  final List<MonthlyCashflow> months;
  final double peak;

  @override
  void paint(Canvas canvas, Size size) {
    if (months.isEmpty) return;

    final slot = size.width / months.length;
    final barWidth = (slot / 2 - 4).clamp(4.0, 20.0);
    const minBar = 2.0;
    final baseline = size.height;

    final incomePaint = Paint()..color = TongtaiFinanceScreen._income;
    final expensePaint = Paint()..color = TongtaiFinanceScreen._expense;

    double heightFor(double value) => peak <= 0
        ? minBar
        : (value / peak * (size.height - 4)).clamp(
            value <= 0 ? 0.0 : minBar,
            size.height,
          );

    for (var i = 0; i < months.length; i++) {
      final centre = i * slot + slot / 2;
      final incomeH = heightFor(months[i].income);
      final expenseH = heightFor(months[i].expense);

      final incomeRect = Rect.fromLTRB(
        centre - barWidth - 1,
        baseline - incomeH,
        centre - 1,
        baseline,
      );
      final expenseRect = Rect.fromLTRB(
        centre + 1,
        baseline - expenseH,
        centre + barWidth + 1,
        baseline,
      );
      const radius = Radius.circular(3);
      canvas.drawRRect(
        RRect.fromRectAndCorners(incomeRect, topLeft: radius, topRight: radius),
        incomePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          expenseRect,
          topLeft: radius,
          topRight: radius,
        ),
        expensePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CashflowPainter oldDelegate) =>
      oldDelegate.months != months || oldDelegate.peak != peak;
}

class _ExpenseBreakdownCard extends StatelessWidget {
  const _ExpenseBreakdownCard({required this.categories, required this.total});

  final List<CategoryAmount> categories;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      decoration: _cardDecoration,
      child: Column(
        children: [
          for (final c in categories) ...[
            _ExpenseBar(category: c, share: total <= 0 ? 0 : c.amount / total),
            if (c != categories.last)
              const SizedBox(height: TongtaiDesignTokens.spacing3),
          ],
        ],
      ),
    );
  }
}

class _ExpenseBar extends StatelessWidget {
  const _ExpenseBar({required this.category, required this.share});

  final CategoryAmount category;
  final double share;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category.category,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${TongtaiFormatters.vnd(category.amount)} · ${(share * 100).round()}%',
              style: TongtaiDesignTokens.captionStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing1),
        ClipRRect(
          borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusFull),
          child: LinearProgressIndicator(
            value: share.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: TongtaiDesignTokens.lightHover,
            valueColor: const AlwaysStoppedAnimation<Color>(
              TongtaiDesignTokens.error,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.transactions});

  final List<FinanceTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TongtaiDesignTokens.spacing4,
      ),
      decoration: _cardDecoration,
      child: Column(
        children: [for (final t in transactions) _RecentRow(transaction: t)],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.transaction});

  final FinanceTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final income = transaction.isIncome;
    final color = income
        ? TongtaiFinanceScreen._income
        : TongtaiFinanceScreen._expense;
    final sign = income ? '+' : '-';
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: TongtaiDesignTokens.spacing3,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(
              income ? Icons.south_west : Icons.north_east,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: TongtaiDesignTokens.spacing3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description.isEmpty
                      ? transaction.category
                      : transaction.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TongtaiDesignTokens.smallStyle.copyWith(
                    color: TongtaiDesignTokens.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${transaction.category} · ${TongtaiFormatters.isoDate(transaction.date)}',
                  style: TongtaiDesignTokens.captionStyle.copyWith(
                    color: TongtaiDesignTokens.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: TongtaiDesignTokens.spacing2),
          Text(
            '$sign${TongtaiFormatters.vnd(transaction.amount)}',
            style: TongtaiDesignTokens.smallStyle.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown until the business has recorded any money movement this year.
class _FinanceEmptyState extends StatelessWidget {
  const _FinanceEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TongtaiFoxMascot.face(size: 72),
            const SizedBox(height: TongtaiDesignTokens.spacing4),
            Text(
              'Chưa có giao dịch tài chính',
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.heading3Style.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing2),
            Text(
              'Ghi khoản thu/chi đầu tiên và bảng tài chính sẽ hiện ở đây.\n'
              'Your income & expenses appear here after the first entry.',
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final BoxDecoration _cardDecoration = BoxDecoration(
  color: TongtaiDesignTokens.lightBackground,
  borderRadius: BorderRadius.circular(TongtaiDesignTokens.cardBorderRadius),
  border: Border.all(color: TongtaiDesignTokens.lightBorder),
);
