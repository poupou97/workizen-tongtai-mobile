import 'package:flutter/material.dart';

import '../../core/tongtai_formatters.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../opportunity/opportunity.dart';
import '../../opportunity/opportunity_pipeline.dart';
import '../../reports/business_report.dart';
import '../widgets/tongtai_fox_mascot.dart';
import 'tongtai_opportunity_feed_screen.dart';

/// Reports & Analytics dashboard (WTM-95 layout/widgets, WTM-96 revenue KPI).
///
/// Local-first: the numbers come from the in-memory [ReportsService] (sample
/// orders in Phase 2). Four headline KPIs, a six-month revenue trend drawn with
/// a lightweight [CustomPainter] (no chart package), a top-categories/products/
/// customers breakdown (WTM-97) and the open opportunity pipeline (WTM-98). All
/// data sources are injectable so every figure is deterministic under test.
class TongtaiReportsScreen extends StatelessWidget {
  const TongtaiReportsScreen({
    super.key,
    this.service,
    this.clock,
    this.opportunities,
  });

  /// Injectable for tests; defaults to the built-in sample orders.
  final ReportsService? service;

  /// Injectable clock (defaults to [DateTime.now]) — fixes "today" for MTD/YTD.
  final DateTime Function()? clock;

  /// Injectable opportunity list for the pipeline card (WTM-98); defaults to
  /// the built-in sample opportunities.
  final List<Opportunity>? opportunities;

  @override
  Widget build(BuildContext context) {
    final reports = service ?? ReportsService.sample();
    final now = (clock ?? DateTime.now)();
    final report = reports.reportAsOf(now);
    final pipeline = opportunityPipeline(opportunities ?? kSampleOpportunities);

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: const Text('Reports & Analytics · Báo cáo'),
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
        elevation: 0,
      ),
      body: report.hasSales
          ? _ReportBody(report: report, pipeline: pipeline)
          : const _ReportsEmptyState(),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report, required this.pipeline});

  final BusinessReport report;
  final OpportunityPipeline pipeline;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      children: [
        // ── Headline KPIs (WTM-96) ──────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                key: const Key('reports-kpi-revenue-mtd'),
                label: 'Doanh thu tháng · MTD',
                value: TongtaiFormatters.vnd(report.revenueMtd),
                accent: TongtaiDesignTokens.financePurple,
                icon: Icons.calendar_month_outlined,
              ),
            ),
            const SizedBox(width: TongtaiDesignTokens.spacing3),
            Expanded(
              child: _KpiCard(
                key: const Key('reports-kpi-revenue-ytd'),
                label: 'Doanh thu năm · YTD',
                value: TongtaiFormatters.vnd(report.revenueYtd),
                accent: TongtaiDesignTokens.financePurple,
                icon: Icons.trending_up,
              ),
            ),
          ],
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                key: const Key('reports-kpi-orders'),
                label: 'Đơn hàng (năm) · Orders',
                value: '${report.ordersYtd}',
                accent: TongtaiDesignTokens.consumerBlue,
                icon: Icons.receipt_long_outlined,
              ),
            ),
            const SizedBox(width: TongtaiDesignTokens.spacing3),
            Expanded(
              child: _KpiCard(
                key: const Key('reports-kpi-aov'),
                label: 'Giá trị đơn TB · AOV',
                value: TongtaiFormatters.vnd(report.averageOrderValue),
                accent: TongtaiDesignTokens.producerGreen,
                icon: Icons.shopping_bag_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: TongtaiDesignTokens.spacing6),

        // ── Revenue trend (WTM-95) ──────────────────────────────────────
        _SectionTitle('Doanh thu theo tháng · Revenue trend'),
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        _RevenueTrendCard(report: report),

        const SizedBox(height: TongtaiDesignTokens.spacing6),

        // ── Top categories (WTM-95) ─────────────────────────────────────
        _SectionTitle('Nhóm bán chạy · Top categories'),
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        _TopCategoriesCard(
          categories: report.topCategories,
          total: report.revenueYtd,
        ),

        const SizedBox(height: TongtaiDesignTokens.spacing6),

        // ── Top products (WTM-97) ───────────────────────────────────────
        _SectionTitle('Sản phẩm bán chạy · Top products'),
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        _TopProductsCard(products: report.topProducts),

        const SizedBox(height: TongtaiDesignTokens.spacing6),

        // ── Top customers (WTM-97) ──────────────────────────────────────
        _SectionTitle('Khách hàng hàng đầu · Top customers'),
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        _TopCustomersCard(customers: report.topCustomers),

        const SizedBox(height: TongtaiDesignTokens.spacing6),

        // ── Opportunity pipeline (WTM-98) ───────────────────────────────
        _SectionHeader(
          title: 'Cơ hội đang mở · Pipeline',
          actionKey: const Key('reports-open-opportunities'),
          onAction: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => const TongtaiOpportunityFeedScreen(),
            ),
          ),
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        _PipelineCard(pipeline: pipeline),
      ],
    );
  }
}

/// A section title with a trailing "Xem tất cả" action.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionKey,
    required this.onAction,
  });

  final String title;
  final Key actionKey;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SectionTitle(title)),
        TextButton(
          key: actionKey,
          onPressed: onAction,
          child: const Text('Xem tất cả'),
        ),
      ],
    );
  }
}

/// Open-pipeline summary: active count + combined expected impact + the
/// strongest opportunity.
class _PipelineCard extends StatelessWidget {
  const _PipelineCard({required this.pipeline});

  final OpportunityPipeline pipeline;

  @override
  Widget build(BuildContext context) {
    if (!pipeline.hasActive) {
      return Container(
        key: const Key('reports-pipeline'),
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
        decoration: _cardDecoration,
        child: Text(
          'Không có cơ hội đang mở',
          style: TongtaiDesignTokens.smallStyle.copyWith(
            color: TongtaiDesignTokens.lightTextSecondary,
          ),
        ),
      );
    }
    final top = pipeline.top!;
    return Container(
      key: const Key('reports-pipeline'),
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _PipelineStat(
                  label: 'Đang mở',
                  value: '${pipeline.activeCount}',
                ),
              ),
              Expanded(
                child: _PipelineStat(
                  label: 'Giá trị pipeline',
                  value: TongtaiFormatters.vndShort(pipeline.pipelineValue),
                ),
              ),
            ],
          ),
          const Divider(height: TongtaiDesignTokens.spacing6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: TongtaiDesignTokens.copilotViolet.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(
                    TongtaiDesignTokens.radiusFull,
                  ),
                ),
                child: Text(
                  '${top.aiScore.round()}',
                  style: TongtaiDesignTokens.captionStyle.copyWith(
                    color: TongtaiDesignTokens.financePurple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: TongtaiDesignTokens.spacing3),
              Expanded(
                child: Text(
                  top.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TongtaiDesignTokens.smallStyle.copyWith(
                    color: TongtaiDesignTokens.lightTextPrimary,
                    fontWeight: FontWeight.w600,
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

class _PipelineStat extends StatelessWidget {
  const _PipelineStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TongtaiDesignTokens.heading3Style.copyWith(
            color: TongtaiDesignTokens.copilotViolet,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TongtaiDesignTokens.captionStyle.copyWith(
            color: TongtaiDesignTokens.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

/// Top products as a ranked list with revenue + units sold.
class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.products});

  final List<ProductRevenue> products;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('reports-top-products'),
      padding: const EdgeInsets.symmetric(
        horizontal: TongtaiDesignTokens.spacing4,
      ),
      decoration: _cardDecoration,
      child: Column(
        children: [
          for (var i = 0; i < products.length; i++)
            _RankRow(
              rank: i + 1,
              accent: TongtaiDesignTokens.inventoryOrange,
              title: products[i].name,
              subtitle: 'Đã bán ${products[i].quantity}',
              value: TongtaiFormatters.vndShort(products[i].revenue),
            ),
        ],
      ),
    );
  }
}

/// Top customers as a ranked list with spend + order count.
class _TopCustomersCard extends StatelessWidget {
  const _TopCustomersCard({required this.customers});

  final List<CustomerSpend> customers;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('reports-top-customers'),
      padding: const EdgeInsets.symmetric(
        horizontal: TongtaiDesignTokens.spacing4,
      ),
      decoration: _cardDecoration,
      child: Column(
        children: [
          for (var i = 0; i < customers.length; i++)
            _RankRow(
              rank: i + 1,
              accent: TongtaiDesignTokens.consumerBlue,
              title: customers[i].name,
              subtitle: '${customers[i].orders} đơn',
              value: TongtaiFormatters.vndShort(customers[i].spend),
            ),
        ],
      ),
    );
  }
}

/// A ranked list row: rank chip · title/subtitle · trailing value.
class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final int rank;
  final Color accent;
  final String title;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: TongtaiDesignTokens.spacing3,
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: TongtaiDesignTokens.captionStyle.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: TongtaiDesignTokens.spacing3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TongtaiDesignTokens.smallStyle.copyWith(
                    color: TongtaiDesignTokens.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TongtaiDesignTokens.captionStyle.copyWith(
                    color: TongtaiDesignTokens.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: TongtaiDesignTokens.spacing2),
          Text(
            value,
            style: TongtaiDesignTokens.smallStyle.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single headline metric on a soft, accent-tinted card.
class _KpiCard extends StatelessWidget {
  const _KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
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

/// The six-month revenue trend: bars drawn by [_RevenueBarsPainter] with month
/// ticks and the peak month called out.
class _RevenueTrendCard extends StatelessWidget {
  const _RevenueTrendCard({required this.report});

  final BusinessReport report;

  @override
  Widget build(BuildContext context) {
    final months = report.monthlyRevenue;
    return Container(
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cao nhất · Peak ${TongtaiFormatters.vnd(report.peakMonthlyRevenue)}',
            style: TongtaiDesignTokens.captionStyle.copyWith(
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          SizedBox(
            height: 160,
            child: CustomPaint(
              key: const Key('reports-revenue-chart'),
              size: Size.infinite,
              painter: _RevenueBarsPainter(
                months: months,
                peak: report.peakMonthlyRevenue,
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

/// Paints one bar per month, scaled to [peak], with a rounded top. Kept
/// dependency-free (no chart package) — the app is deliberately lean.
class _RevenueBarsPainter extends CustomPainter {
  _RevenueBarsPainter({required this.months, required this.peak});

  final List<MonthlyRevenue> months;
  final double peak;

  @override
  void paint(Canvas canvas, Size size) {
    if (months.isEmpty) return;

    const gap = 12.0;
    final slot = size.width / months.length;
    final barWidth = (slot - gap).clamp(6.0, 44.0);
    // A visible sliver even for a zero month keeps the axis readable.
    const minBarHeight = 3.0;

    final barPaint = Paint()..color = TongtaiDesignTokens.financePurple;
    final zeroPaint = Paint()..color = TongtaiDesignTokens.lightBorder;
    final baseline = size.height;

    for (var i = 0; i < months.length; i++) {
      final revenue = months[i].revenue;
      final fraction = peak <= 0 ? 0.0 : revenue / peak;
      final barHeight = revenue <= 0
          ? minBarHeight
          : (fraction * (size.height - 4)).clamp(minBarHeight, size.height);
      final left = i * slot + (slot - barWidth) / 2;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTRB(left, baseline - barHeight, left + barWidth, baseline),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(rect, revenue <= 0 ? zeroPaint : barPaint);
    }
  }

  @override
  bool shouldRepaint(_RevenueBarsPainter oldDelegate) =>
      oldDelegate.months != months || oldDelegate.peak != peak;
}

/// Top categories as labelled share-of-revenue bars.
class _TopCategoriesCard extends StatelessWidget {
  const _TopCategoriesCard({required this.categories, required this.total});

  final List<CategoryRevenue> categories;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      decoration: _cardDecoration,
      child: Column(
        children: [
          for (final c in categories) ...[
            _CategoryBar(
              category: c,
              share: total <= 0 ? 0 : c.revenue / total,
            ),
            if (c != categories.last)
              const SizedBox(height: TongtaiDesignTokens.spacing3),
          ],
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.category, required this.share});

  final CategoryRevenue category;
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
              '${TongtaiFormatters.vnd(category.revenue)} · ${(share * 100).round()}%',
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
              TongtaiDesignTokens.inventoryOrange,
            ),
          ),
        ),
      ],
    );
  }
}

/// Shown until the business has its first billable order this year.
class _ReportsEmptyState extends StatelessWidget {
  const _ReportsEmptyState();

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
              'Chưa có doanh thu để báo cáo',
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.heading3Style.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing2),
            Text(
              'Bán đơn hàng đầu tiên và các chỉ số sẽ hiện ở đây.\n'
              'Your KPIs appear here after the first sale.',
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
