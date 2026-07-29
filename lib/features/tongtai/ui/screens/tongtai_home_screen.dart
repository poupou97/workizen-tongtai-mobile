import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../consumer/customer_directory_service.dart';
import '../../core/tongtai_formatters.dart';
import '../../inventory/product_inventory_service.dart';
import '../../journey/business_goal.dart';
import '../../metrics/business_health.dart';
import '../../metrics/business_metrics.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../opportunity/opportunity.dart';
import '../../orders/order.dart' show kSampleCustomerOrders;
import '../../producer/supplier_search_service.dart';
import '../../providers/tongtai_context_provider.dart';
import '../../providers/tongtai_journey_provider.dart';
import '../../providers/tongtai_search_provider.dart';
import 'tongtai_chat_screen.dart';
import 'tongtai_customer_list_screen.dart';
import 'tongtai_goals_screen.dart';
import 'tongtai_inventory_screen.dart';
import 'tongtai_opportunity_feed_screen.dart';
import 'tongtai_reports_screen.dart';
import 'tongtai_unified_search_screen.dart';

/// Home dashboard for Tổng Tài — the app's front door.
///
/// **User Data First (WTM-128, Founder G-1):** every figure is the user's real
/// business data — module counts + the KPIs from [BusinessMetricsService] (the
/// KPI source of truth) and a [BusinessHealth] read. Zero is valid business data
/// (never "No Data"). A brand-new business sees onboarding CTAs; sample data
/// only ever appears behind the explicit "Explore Demo Mode" action, never
/// preloaded. All sources are injectable for deterministic tests.
class TongtaiHomeScreen extends ConsumerStatefulWidget {
  const TongtaiHomeScreen({
    super.key,
    this.metrics,
    this.health,
    this.clock,
    this.supplierCount,
    this.inventoryCount,
    this.customerCount,
    this.goals,
    this.opportunities,
  });

  /// A demo dashboard populated with sample data — the explicit "Explore Demo
  /// Mode" action. Nothing here is written to the real database.
  factory TongtaiHomeScreen.demo({Key? key, DateTime Function()? clock}) {
    return TongtaiHomeScreen(
      key: key,
      clock: clock,
      metrics: BusinessMetrics.from(
        orders: kSampleCustomerOrders,
        customersCount: kSampleCustomers.length,
      ),
      health: BusinessHealth.healthy,
      supplierCount: kSampleSuppliers.length,
      inventoryCount: kSampleProducts.length,
      customerCount: kSampleCustomers.length,
      goals: kSampleBusinessGoals,
      opportunities: kSampleOpportunities,
    );
  }

  /// Injectable KPIs (source of truth); when null they load from the
  /// [businessMetricsServiceProvider].
  final BusinessMetrics? metrics;

  /// Injectable health read; when null it is derived from [metrics].
  final BusinessHealth? health;

  final DateTime Function()? clock;
  final int? supplierCount;
  final int? inventoryCount;
  final int? customerCount;
  final List<BusinessGoal>? goals;

  /// AI-generated opportunities for the preview row; real source lands with the
  /// Opportunity capability. A real user starts with none.
  final List<Opportunity>? opportunities;

  @override
  ConsumerState<TongtaiHomeScreen> createState() => _TongtaiHomeScreenState();
}

class _TongtaiHomeScreenState extends ConsumerState<TongtaiHomeScreen> {
  BusinessMetrics _metrics = BusinessMetrics.empty;
  BusinessHealth _health = BusinessHealth.notEnoughData;
  List<BusinessGoal> _goals = const [];
  int _producers = 0;
  int _inventory = 0;
  int _consumer = 0;
  int _journey = 0;

  @override
  void initState() {
    super.initState();
    if (widget.metrics != null) {
      // Injected / demo mode — data is available synchronously.
      _metrics = widget.metrics!;
      _health = widget.health ?? BusinessHealth.from(_metrics);
      _producers = widget.supplierCount ?? 0;
      _inventory = widget.inventoryCount ?? 0;
      _consumer = widget.customerCount ?? _metrics.customersCount;
      _goals = widget.goals ?? const [];
      _journey = _goals.length;
    } else {
      // Real app: render the dashboard progressively (starts at the empty/zero
      // state, fills in when the repositories resolve). No blocking spinner, so
      // there is no perpetual animation to stall widget tests.
      _load();
    }
  }

  Future<void> _load() async {
    // Home consumes the BusinessContext Aggregate Root (WTM-129) for its KPIs +
    // capability counts + health — the same seam AI reads. Journey (goals) and
    // Producer (favourites) are not in the Phase-1 context yet, so they load
    // alongside. Resolve every provider before the first await (the widget may be
    // disposed mid-load).
    final contextService = ref.read(businessContextServiceProvider);
    final goalRepo = ref.read(businessGoalRepositoryProvider);
    final favoritesStore = ref.read(tongtaiSearchFavoritesStoreProvider);
    final context = await contextService.load();
    final goals = await goalRepo.loadAll();
    final favorites = await favoritesStore.loadAll();
    if (!mounted) return;
    setState(() {
      _metrics = context.metrics;
      _health = widget.health ?? context.health;
      _inventory = context.inventory.productCount;
      _consumer = context.customers.total;
      _goals = goals;
      _journey = goals.length;
      _producers = favorites.length;
    });
  }

  /// A brand-new business — nothing created in any capability yet.
  bool get _isEmptyBusiness =>
      _consumer == 0 &&
      _inventory == 0 &&
      _journey == 0 &&
      _metrics.ordersCount == 0;

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

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final topOpportunities =
        (widget.opportunities ?? const <Opportunity>[]).toList()
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
            // ── Welcome + health + module counts ──────────────────────
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
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Welcome to Tổng Tài',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _HealthBadge(health: _health),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your AI-powered business assistant for sourcing, '
                      'inventory, customers, and more.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 16),
                    _ModuleSummaryGrid(
                      producers: _producers,
                      inventory: _inventory,
                      consumers: _consumer,
                      journeys: _journey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Get started (new business) ────────────────────────────
            if (_isEmptyBusiness) ...[
              _GetStartedCard(
                onCustomer: () =>
                    _push(context, const TongtaiCustomerListScreen()),
                onProduct: () => _push(context, const TongtaiInventoryScreen()),
                onOrder: () =>
                    _push(context, const TongtaiCustomerListScreen()),
                onGoal: () => _push(context, const TongtaiGoalsScreen()),
                onDemo: () =>
                    _push(context, TongtaiHomeScreen.demo(clock: widget.clock)),
              ),
              const SizedBox(height: 24),
            ],

            // ── Business KPIs — real values, zero is valid (WTM-128) ──
            _SectionHeader(
              title: 'Business KPIs',
              actionKey: const Key('home-open-reports'),
              actionLabel: 'Xem báo cáo',
              onAction: () => _push(context, const TongtaiReportsScreen()),
            ),
            const SizedBox(height: 12),
            _KpiRow(metrics: _metrics),
            const SizedBox(height: 24),

            // ── Top opportunities (AI-generated; empty for new users) ─
            _SectionHeader(
              title: 'Top Opportunities',
              actionKey: const Key('home-open-opportunities'),
              actionLabel: 'View all',
              onAction: () =>
                  _push(context, const TongtaiOpportunityFeedScreen()),
            ),
            const SizedBox(height: 12),
            if (topOpportunities.isEmpty)
              const _EmptyBox('No opportunities available')
            else
              ...topOpportunities
                  .take(3)
                  .map((o) => _OpportunityTile(opportunity: o)),
            const SizedBox(height: 24),

            // ── Today's missions = active goals ───────────────────────
            Text(
              "Today's Missions",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_goals.isEmpty)
              const _EmptyBox('No missions yet')
            else
              ..._goals.take(3).map((g) => _MissionTile(goal: g)),
          ],
        ),
      ),
    );
  }
}

/// Coarse business-health chip (WTM-128). Home renders the value; the assessor
/// behind it can later become AI-powered without changing this UI.
class _HealthBadge extends StatelessWidget {
  const _HealthBadge({required this.health});

  final BusinessHealth health;

  @override
  Widget build(BuildContext context) {
    final healthy = health.isHealthy;
    final color = healthy
        ? TongtaiDesignTokens.success
        : TongtaiDesignTokens.neutral;
    return Tooltip(
      message: health.reason,
      child: Container(
        key: const Key('home-health-badge'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusFull),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              healthy ? Icons.favorite : Icons.hourglass_empty,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              health.label('en'),
              style: TongtaiDesignTokens.captionStyle.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Onboarding CTAs for a brand-new business (WTM-128, Founder priority order).
/// Demo Mode is always an explicit action — sample data is never preloaded.
class _GetStartedCard extends StatelessWidget {
  const _GetStartedCard({
    required this.onCustomer,
    required this.onProduct,
    required this.onOrder,
    required this.onGoal,
    required this.onDemo,
  });

  final VoidCallback onCustomer;
  final VoidCallback onProduct;
  final VoidCallback onOrder;
  final VoidCallback onGoal;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bắt đầu · Get started',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Nhập dữ liệu kinh doanh đầu tiên của bạn.',
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _CtaTile(
              tileKey: const Key('home-cta-customer'),
              icon: Icons.person_add_alt_1,
              label: 'Create your first customer',
              onTap: onCustomer,
            ),
            _CtaTile(
              tileKey: const Key('home-cta-product'),
              icon: Icons.add_box_outlined,
              label: 'Add your first product',
              onTap: onProduct,
            ),
            _CtaTile(
              tileKey: const Key('home-cta-order'),
              icon: Icons.receipt_long_outlined,
              label: 'Create your first order',
              onTap: onOrder,
            ),
            _CtaTile(
              tileKey: const Key('home-cta-goal'),
              icon: Icons.flag_outlined,
              label: 'Set your first business goal',
              onTap: onGoal,
            ),
            _CtaTile(
              tileKey: const Key('home-cta-demo'),
              icon: Icons.play_circle_outline,
              label: 'Explore Demo Mode',
              onTap: onDemo,
            ),
          ],
        ),
      ),
    );
  }
}

class _CtaTile extends StatelessWidget {
  const _CtaTile({
    required this.tileKey,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Key tileKey;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: tileKey,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: TongtaiDesignTokens.consumerBlue),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
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
/// The headline KPIs on Home — read straight from [BusinessMetrics] (the KPI
/// source of truth, WTM-127). Real values are always shown; **zero is valid
/// business data** and is never replaced with a "No Data" placeholder (WTM-128).
class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.metrics});

  final BusinessMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KpiTile(
            tileKey: const Key('home-kpi-revenue'),
            label: 'Doanh thu',
            value: TongtaiFormatters.vndShort(metrics.revenue),
            color: TongtaiDesignTokens.financePurple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiTile(
            tileKey: const Key('home-kpi-orders'),
            label: 'Đơn hàng',
            value: '${metrics.ordersCount}',
            color: TongtaiDesignTokens.consumerBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiTile(
            tileKey: const Key('home-kpi-aov'),
            label: 'Đơn TB',
            value: TongtaiFormatters.vndShort(metrics.averageOrderValue),
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
