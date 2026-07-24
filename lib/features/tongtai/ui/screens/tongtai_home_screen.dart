import 'package:flutter/material.dart';

import '../../consumer/customer_directory_service.dart';
import '../../core/tongtai_formatters.dart';
import '../../inventory/product_inventory_service.dart';
import '../../journey/business_goal.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../opportunity/opportunity.dart';
import '../../producer/supplier_search_service.dart';
import '../../reports/business_report.dart';
import 'tongtai_chat_screen.dart';
import 'tongtai_opportunity_feed_screen.dart';
import 'tongtai_reports_screen.dart';
import 'tongtai_unified_search_screen.dart';

/// Home dashboard for Tổng Tài — the app's front door.
///
/// Reads the same local sample data every other screen uses (products,
/// customers, suppliers, goals, opportunities) plus the [ReportsService] revenue
/// figures, so the dashboard reflects the real state of the business instead of
/// placeholder zeros. All data sources are injectable for deterministic tests.
class TongtaiHomeScreen extends StatelessWidget {
  const TongtaiHomeScreen({
    super.key,
    this.reportsService,
    this.clock,
    this.supplierCount,
    this.inventoryCount,
    this.customerCount,
    this.goals,
    this.opportunities,
  });

  final ReportsService? reportsService;
  final DateTime Function()? clock;
  final int? supplierCount;
  final int? inventoryCount;
  final int? customerCount;
  final List<BusinessGoal>? goals;
  final List<Opportunity>? opportunities;

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TongtaiUnifiedSearchRoute()),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TongtaiChatScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final now = (clock ?? DateTime.now)();
    final report = (reportsService ?? ReportsService.sample()).reportAsOf(now);
    final goalList = goals ?? kSampleBusinessGoals;
    final topOpportunities = (opportunities ?? kSampleOpportunities).toList()
      ..sort((a, b) => b.aiScore.compareTo(a.aiScore));

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: const Text('Home Dashboard'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => _openSearch(context),
          ),
          IconButton(
            key: const Key('home-open-chat'),
            tooltip: 'Workizen AI chat',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => _openChat(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome + module counts ──────────────────────────────────
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to Tổng Tài',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your AI-powered business assistant for sourcing, '
                      'inventory, customers, and more.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 16),
                    _ModuleSummaryGrid(
                      producers: supplierCount ?? kSampleSuppliers.length,
                      inventory: inventoryCount ?? kSampleProducts.length,
                      consumers: customerCount ?? kSampleCustomers.length,
                      journeys: goalList.length,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Business KPIs (WTM-96 revenue into the front door) ────────
            _SectionHeader(
              title: 'Business KPIs',
              actionKey: const Key('home-open-reports'),
              actionLabel: 'Xem báo cáo',
              onAction: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const TongtaiReportsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _KpiRow(report: report),
            const SizedBox(height: 24),

            // ── Top opportunities ─────────────────────────────────────────
            _SectionHeader(
              title: 'Top Opportunities',
              actionKey: const Key('home-open-opportunities'),
              actionLabel: 'View all',
              onAction: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => const TongtaiOpportunityFeedScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (topOpportunities.isEmpty)
              const _EmptyBox('No opportunities available')
            else
              ...topOpportunities
                  .take(3)
                  .map((o) => _OpportunityTile(opportunity: o)),
            const SizedBox(height: 24),

            // ── Today's missions = active goals ───────────────────────────
            Text(
              "Today's Missions",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (goalList.isEmpty)
              const _EmptyBox('No missions yet')
            else
              ...goalList.take(3).map((g) => _MissionTile(goal: g)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionKey,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final Key actionKey;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        TextButton(
          key: actionKey,
          onPressed: onAction,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

/// The four module tiles with live counts.
class _ModuleSummaryGrid extends StatelessWidget {
  const _ModuleSummaryGrid({
    required this.producers,
    required this.inventory,
    required this.consumers,
    required this.journeys,
  });

  final int producers;
  final int inventory;
  final int consumers;
  final int journeys;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: [
        _ModuleCard(
          title: 'Producer',
          count: '$producers',
          color: TongtaiDesignTokens.producerGreen,
        ),
        _ModuleCard(
          title: 'Inventory',
          count: '$inventory',
          color: TongtaiDesignTokens.inventoryOrange,
        ),
        _ModuleCard(
          title: 'Consumer',
          count: '$consumers',
          color: TongtaiDesignTokens.consumerBlue,
        ),
        _ModuleCard(
          title: 'Journey',
          count: '$journeys',
          color: const Color(0xFFFBBF24),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.count,
    required this.color,
  });

  final String title;
  final String count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Revenue YTD + order count + AOV, pulled from the reports aggregator.
class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.report});

  final BusinessReport report;

  @override
  Widget build(BuildContext context) {
    if (!report.hasSales) {
      return const _EmptyBox('KPI metrics will appear here');
    }
    return Row(
      children: [
        Expanded(
          child: _KpiTile(
            tileKey: const Key('home-kpi-revenue'),
            label: 'Doanh thu năm',
            value: TongtaiFormatters.vndShort(report.revenueYtd),
            color: TongtaiDesignTokens.financePurple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiTile(
            label: 'Đơn hàng',
            value: '${report.ordersYtd}',
            color: TongtaiDesignTokens.consumerBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiTile(
            label: 'Đơn TB',
            value: TongtaiFormatters.vndShort(report.averageOrderValue),
            color: TongtaiDesignTokens.producerGreen,
          ),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    this.tileKey,
    required this.label,
    required this.value,
    required this.color,
  });

  final Key? tileKey;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: tileKey,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// One AI-scored opportunity, with its relevance score and ROI.
class _OpportunityTile extends StatelessWidget {
  const _OpportunityTile({required this.opportunity});

  final Opportunity opportunity;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TongtaiDesignTokens.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: TongtaiDesignTokens.copilotViolet.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${opportunity.aiScore.round()}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: TongtaiDesignTokens.financePurple,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opportunity.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: TongtaiDesignTokens.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ROI ×${opportunity.estimatedRoi.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TongtaiDesignTokens.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One active goal shown as a "mission" with its progress.
class _MissionTile extends StatelessWidget {
  const _MissionTile({required this.goal});

  final BusinessGoal goal;

  @override
  Widget build(BuildContext context) {
    final pct = (goal.progress * 100).round();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TongtaiDesignTokens.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: TongtaiDesignTokens.lightTextPrimary,
                  ),
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: TongtaiDesignTokens.producerGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 6,
              backgroundColor: TongtaiDesignTokens.lightHover,
              valueColor: const AlwaysStoppedAnimation<Color>(
                TongtaiDesignTokens.producerGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: Text(label)),
    );
  }
}
