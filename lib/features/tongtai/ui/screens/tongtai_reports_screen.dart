import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/business_health_ai.dart';
import '../../ai/business_plan.dart';
import '../../ai/business_recommendation.dart';
import '../../ai/business_summary.dart';
import '../../core/tongtai_formatters.dart';
import '../../metrics/business_metrics.dart';
import '../../core/screen_data_controller.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../widgets/tongtai_screen_data.dart';
import '../../opportunity/opportunity.dart' show Opportunity;
import '../../opportunity/opportunity_pipeline.dart';
import '../../providers/tongtai_ai_provider.dart';
import '../../providers/tongtai_context_provider.dart';
import '../../providers/tongtai_metrics_provider.dart';
import '../../providers/tongtai_orders_provider.dart';
import '../../reports/business_report.dart';
import '../widgets/tongtai_fox_mascot.dart';
import 'tongtai_opportunity_feed_screen.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';

/// Reports & Analytics dashboard (WTM-95 layout/widgets, WTM-96 revenue KPI,
/// WTM-127 real data).
///
/// **User Data First:** the numbers come from the persisted Orders + Consumer
/// repositories — a new user with no sales sees the empty state. The four
/// headline KPIs (revenue, orders, customers, AOV) are read from
/// [BusinessMetricsService] (the KPI single source of truth, Founder), never
/// recomputed here; the trend + breakdowns come from [ReportsService] over the
/// same real orders. All sources are injectable so every figure is deterministic
/// under test.
class TongtaiReportsScreen extends ConsumerStatefulWidget {
  const TongtaiReportsScreen({
    super.key,
    this.service,
    this.metrics,
    this.clock,
    this.opportunities,
    this.summaryService,
    this.recommendationService,
    this.planService,
    this.healthAiService,
  });

  /// Injectable breakdown source for tests; when null the screen loads real
  /// persisted orders (via [orderRepositoryProvider]).
  final ReportsService? service;

  /// Injectable headline KPIs for tests; when null they are loaded from the
  /// [businessMetricsServiceProvider] (the KPI source of truth).
  final BusinessMetrics? metrics;

  /// Injectable clock (defaults to [DateTime.now]) — fixes "today" for the trend.
  final DateTime Function()? clock;

  /// Injectable opportunity list for the pipeline card (WTM-98); defaults to
  /// the built-in sample opportunities (AI-generated — real source lands with
  /// the Opportunity capability, later in the Founder sequence).
  final List<Opportunity>? opportunities;

  /// Injectable summary source for tests (WTM-116/G-3A); when null the screen
  /// uses [businessSummaryServiceProvider].
  final BusinessSummaryService? summaryService;

  /// Injectable recommendation source for tests (WTM-135/G-3B); when null the
  /// screen uses [businessRecommendationServiceProvider].
  final BusinessRecommendationService? recommendationService;

  /// Injectable planner source for tests (WTM-136/G-3C); when null the screen
  /// uses [businessPlanServiceProvider].
  final BusinessPlanService? planService;

  /// Injectable health-assessment source for tests (WTM-137/G-3D); when null
  /// the screen uses [businessHealthAiServiceProvider].
  final BusinessHealthAiService? healthAiService;

  @override
  ConsumerState<TongtaiReportsScreen> createState() =>
      _TongtaiReportsScreenState();
}

class _TongtaiReportsScreenState extends ConsumerState<TongtaiReportsScreen> {
  /// Which window the breakdown sections are scoped to (WTM-115). Defaults to
  /// this-year, matching the classic YTD breakdown.
  ReportPeriod _period = ReportPeriod.thisYear;

  /// G-3A/G-3B (WTM-116/135): the on-demand Workizen AI answer (summary or
  /// recommendations). Null until requested.
  AiCardResult? _aiResult;
  bool _aiRunning = false;

  Future<void> _runSummary() async {
    if (_aiRunning) return;
    setState(() => _aiRunning = true);
    final BusinessSummaryService service =
        widget.summaryService ?? ref.read(businessSummaryServiceProvider);
    final summary = await service.summarize();
    if (!mounted) return;
    setState(() {
      _aiResult = AiCardResult(
        title: context.l10n.aiResultSummary,
        text: summary.text,
        sourceLabel: summary.isAi
            ? (summary.provider?.displayName ?? 'AI')
            : 'Rule-based',
      );
      _aiRunning = false;
    });
  }

  Future<void> _runRecommendation() async {
    if (_aiRunning) return;
    setState(() => _aiRunning = true);
    final BusinessRecommendationService service =
        widget.recommendationService ??
        ref.read(businessRecommendationServiceProvider);
    final recommendation = await service.recommend();
    if (!mounted) return;
    setState(() {
      _aiResult = AiCardResult(
        title: context.l10n.aiResultRecommendations,
        text: recommendation.text,
        sourceLabel: recommendation.isAi
            ? (recommendation.provider?.displayName ?? 'AI')
            : 'Rule-based',
      );
      _aiRunning = false;
    });
  }

  Future<void> _runPlan() async {
    if (_aiRunning) return;
    setState(() => _aiRunning = true);
    final BusinessPlanService service =
        widget.planService ?? ref.read(businessPlanServiceProvider);
    final plan = await service.plan();
    if (!mounted) return;
    setState(() {
      _aiResult = AiCardResult(
        title: context.l10n.aiResultWeeklyPlan,
        text: plan.text,
        sourceLabel: plan.isAi
            ? (plan.provider?.displayName ?? 'AI')
            : 'Rule-based',
      );
      _aiRunning = false;
    });
  }

  Future<void> _runHealth() async {
    if (_aiRunning) return;
    setState(() => _aiRunning = true);
    final BusinessHealthAiService service =
        widget.healthAiService ?? ref.read(businessHealthAiServiceProvider);
    final assessment = await service.assess();
    if (!mounted) return;
    final l10n = context.l10n;
    setState(() {
      _aiResult = AiCardResult(
        // The badge status stays rule-based (G-3D) — the title carries it so
        // the AI text is always read against the authoritative status.
        title:
            '${l10n.aiHealth}: ${assessment.ruleHealth.label(l10n.languageCode)}',
        text: assessment.text,
        sourceLabel: assessment.isAi
            ? (assessment.provider?.displayName ?? 'AI')
            : 'Rule-based',
      );
      _aiRunning = false;
    });
  }

  /// Everything the report is computed from, read as one unit (WTM-148). A
  /// failed read here is the most expensive kind of silent empty: "no sales"
  /// is a statement about the business, and this screen must never make it by
  /// accident.
  late final ScreenDataController<_ReportsData> _data;

  ReportsService? get _reports => _data.state.value?.reports;
  BusinessMetrics? get _metrics => _data.state.value?.metrics;
  List<Opportunity> get _generatedOpportunities =>
      _data.state.value?.opportunities ?? const [];

  @override
  void initState() {
    super.initState();
    _data = ScreenDataController<_ReportsData>(
      _read,
      // Test / injected mode — no async load. NEVER fall back to fixtures
      // (P0 §3, WTM-146): a metrics-only injection gets an empty order book,
      // not sample data.
      initialValue: _injected(),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'reports',
    );
    if (_injected() == null) _data.load();
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  _ReportsData? _injected() {
    if (widget.service == null && widget.metrics == null) return null;
    final reports = widget.service ?? ReportsService(const []);
    return (
      reports: reports,
      metrics:
          widget.metrics ??
          BusinessMetrics.from(
            orders: reports.all,
            customersCount: reports.all.map((o) => o.customerId).toSet().length,
          ),
      opportunities: const <Opportunity>[],
    );
  }

  Future<_ReportsData> _read() async => (
    reports: ReportsService(await ref.read(orderRepositoryProvider).loadAll()),
    metrics: await ref.read(businessMetricsServiceProvider).load(),
    // Real generated opportunities (WTM-139) back the pipeline card in real
    // mode; sample only when the test injects a list.
    opportunities: await ref.read(generatedOpportunitiesProvider.future),
  );

  @override
  Widget build(BuildContext context) {
    final now = (widget.clock ?? DateTime.now)();
    final report = _reports?.reportAsOf(now);
    final metrics = _metrics ?? BusinessMetrics.empty;
    final breakdown =
        _reports?.breakdownFor(now, _period) ?? PeriodBreakdown.empty;
    final pipeline = opportunityPipeline(
      // One source (WTM-144 P0 §1): real generated opportunities only — the
      // sample fallback is gone; tests inject their fixtures explicitly.
      widget.opportunities ?? _generatedOpportunities,
    );

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(context.l10n.titleReports),
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _data,
        builder: (context, _) => TongtaiScreenData<_ReportsData>(
          prefix: 'reports',
          state: _data.state,
          onRetry: _data.retry,
          isEmpty: (_) => !metrics.hasSales || report == null,
          emptyBuilder: (_) => const _ReportsEmptyState(),
          builder: (context, _) => _ReportBody(
            report: report!,
            metrics: metrics,
            breakdown: breakdown,
            period: _period,
            onPeriodChanged: (p) => setState(() => _period = p),
            pipeline: pipeline,
            aiResult: _aiResult,
            aiRunning: _aiRunning,
            onSummarize: _runSummary,
            onRecommend: _runRecommendation,
            onPlan: _runPlan,
            onHealth: _runHealth,
          ),
        ),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({
    required this.report,
    required this.metrics,
    required this.breakdown,
    required this.period,
    required this.onPeriodChanged,
    required this.pipeline,
    required this.aiResult,
    required this.aiRunning,
    required this.onSummarize,
    required this.onRecommend,
    required this.onPlan,
    required this.onHealth,
  });

  final BusinessReport report;
  final BusinessMetrics metrics;

  /// Period-scoped sales breakdown (WTM-115) — categories/products/customers.
  final PeriodBreakdown breakdown;
  final ReportPeriod period;
  final ValueChanged<ReportPeriod> onPeriodChanged;

  final OpportunityPipeline pipeline;

  /// G-3A/B/C: the on-demand Workizen AI answer (summary / recommendations /
  /// weekly plan).
  final AiCardResult? aiResult;
  final bool aiRunning;
  final VoidCallback onSummarize;
  final VoidCallback onRecommend;
  final VoidCallback onPlan;
  final VoidCallback onHealth;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      children: [
        // ── Headline KPIs — the four canonical metrics from the KPI source of
        //    truth (WTM-127, BusinessMetricsService). Never recomputed here. ──
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                key: const Key('reports-kpi-revenue'),
                label: context.l10n.kpiRevenue,
                value: TongtaiFormatters.vnd(metrics.revenue),
                accent: TongtaiDesignTokens.financePurple,
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: TongtaiDesignTokens.spacing3),
            Expanded(
              child: _KpiCard(
                key: const Key('reports-kpi-orders'),
                label: context.l10n.kpiOrders,
                value: '${metrics.ordersCount}',
                accent: TongtaiDesignTokens.consumerBlue,
                icon: Icons.receipt_long_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                key: const Key('reports-kpi-customers'),
                label: context.l10n.kpiCustomers,
                value: '${metrics.customersCount}',
                accent: TongtaiDesignTokens.inventoryOrange,
                icon: Icons.people_outline,
              ),
            ),
            const SizedBox(width: TongtaiDesignTokens.spacing3),
            Expanded(
              child: _KpiCard(
                key: const Key('reports-kpi-aov'),
                label: context.l10n.kpiAov,
                value: TongtaiFormatters.vnd(metrics.averageOrderValue),
                accent: TongtaiDesignTokens.producerGreen,
                icon: Icons.shopping_bag_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: TongtaiDesignTokens.spacing6),

        // ── Workizen AI (WTM-116 G-3A summary · WTM-135 G-3B recommend) ─
        _AiSummaryCard(
          result: aiResult,
          running: aiRunning,
          onSummarize: onSummarize,
          onRecommend: onRecommend,
          onPlan: onPlan,
          onHealth: onHealth,
        ),

        const SizedBox(height: TongtaiDesignTokens.spacing6),

        // ── Revenue trend (WTM-95) ──────────────────────────────────────
        _SectionTitle(context.l10n.sectionRevenueTrend),
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        _RevenueTrendCard(report: report),

        const SizedBox(height: TongtaiDesignTokens.spacing6),

        // ── Period selector — scopes the breakdowns below (WTM-115) ─────
        _SectionTitle(context.l10n.sectionBreakdownByPeriod),
        const SizedBox(height: TongtaiDesignTokens.spacing2),
        _PeriodSelector(period: period, onChanged: onPeriodChanged),

        const SizedBox(height: TongtaiDesignTokens.spacing5),

        // ── Top categories (WTM-95, period-scoped WTM-115) ──────────────
        _SectionTitle(context.l10n.sectionTopCategories),
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        _TopCategoriesCard(
          categories: breakdown.topCategories,
          total: breakdown.revenue,
        ),

        const SizedBox(height: TongtaiDesignTokens.spacing6),

        // ── Top products (WTM-97, period-scoped WTM-115) ────────────────
        _SectionTitle(context.l10n.sectionTopProducts),
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        _TopProductsCard(products: breakdown.topProducts),

        const SizedBox(height: TongtaiDesignTokens.spacing6),

        // ── Top customers (WTM-97, period-scoped WTM-115) ───────────────
        _SectionTitle(context.l10n.sectionTopCustomers),
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        _TopCustomersCard(customers: breakdown.topCustomers),

        const SizedBox(height: TongtaiDesignTokens.spacing6),

        // ── Opportunity pipeline (WTM-98) ───────────────────────────────
        _SectionHeader(
          title: context.l10n.sectionPipeline,
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

/// One rendered Workizen AI answer for the Reports AI card — pre-flattened by
/// the screen so the card never touches AI types directly.
class AiCardResult {
  const AiCardResult({
    required this.title,
    required this.text,
    required this.sourceLabel,
  });

  final String title;
  final String text;

  /// Provenance chip label — the provider's display name, or "Rule-based".
  final String sourceLabel;
}

/// Workizen AI card (WTM-116 G-3A summary · WTM-135 G-3B recommendations). On
/// demand — the seller picks an action; the answer renders with a provenance
/// chip. Read-only: both actions are text over the BusinessContext; nothing is
/// executed.
class _AiSummaryCard extends StatelessWidget {
  const _AiSummaryCard({
    required this.result,
    required this.running,
    required this.onSummarize,
    required this.onRecommend,
    required this.onPlan,
    required this.onHealth,
  });

  final AiCardResult? result;
  final bool running;
  final VoidCallback onSummarize;
  final VoidCallback onRecommend;
  final VoidCallback onPlan;
  final VoidCallback onHealth;

  @override
  Widget build(BuildContext context) {
    const accent = TongtaiDesignTokens.copilotViolet;
    return Container(
      key: const Key('reports-ai-summary'),
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.cardBorderRadius,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: accent),
              const SizedBox(width: TongtaiDesignTokens.spacing2),
              Expanded(
                child: Text(
                  result == null
                      ? 'Workizen AI'
                      : 'Workizen AI — ${result!.title}',
                  style: TongtaiDesignTokens.smallStyle.copyWith(
                    color: TongtaiDesignTokens.lightTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (result != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TongtaiDesignTokens.spacing2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                      TongtaiDesignTokens.radiusFull,
                    ),
                  ),
                  child: Text(
                    result!.sourceLabel,
                    key: const Key('reports-ai-summary-source'),
                    style: TongtaiDesignTokens.captionStyle.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          if (running)
            TongtaiInlineBusy(label: context.l10n.reportsAnalyzing)
          else ...[
            if (result != null) ...[
              Text(
                result!.text,
                key: const Key('reports-ai-summary-text'),
                style: TongtaiDesignTokens.smallStyle.copyWith(
                  color: TongtaiDesignTokens.lightTextPrimary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: TongtaiDesignTokens.spacing3),
            ],
            Wrap(
              spacing: TongtaiDesignTokens.spacing2,
              runSpacing: TongtaiDesignTokens.spacing1,
              children: [
                OutlinedButton.icon(
                  key: const Key('reports-ai-summary-run'),
                  onPressed: onSummarize,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: Text(context.l10n.aiSummarize),
                ),
                OutlinedButton.icon(
                  key: const Key('reports-ai-recommend-run'),
                  onPressed: onRecommend,
                  icon: const Icon(Icons.tips_and_updates_outlined, size: 16),
                  label: Text(context.l10n.aiRecommend),
                ),
                OutlinedButton.icon(
                  key: const Key('reports-ai-plan-run'),
                  onPressed: onPlan,
                  icon: const Icon(Icons.checklist_outlined, size: 16),
                  label: Text(context.l10n.aiPlan),
                ),
                OutlinedButton.icon(
                  key: const Key('reports-ai-health-run'),
                  onPressed: onHealth,
                  icon: const Icon(Icons.favorite_outline, size: 16),
                  label: Text(context.l10n.aiHealth),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Period chips (WTM-115) scoping the breakdown sections below them. The
/// headline KPIs are unaffected — they stay all-business (BusinessMetrics).
class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.period, required this.onChanged});

  final ReportPeriod period;
  final ValueChanged<ReportPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const Key('reports-period-selector'),
      spacing: TongtaiDesignTokens.spacing2,
      runSpacing: TongtaiDesignTokens.spacing1,
      children: [
        for (final p in ReportPeriod.values)
          ChoiceChip(
            key: Key('reports-period-${p.name}'),
            label: Text(p.label(context.l10n.languageCode)),
            selected: p == period,
            onSelected: (_) => onChanged(p),
            selectedColor: TongtaiDesignTokens.financePurple.withValues(
              alpha: 0.15,
            ),
            labelStyle: TongtaiDesignTokens.smallStyle.copyWith(
              color: p == period
                  ? TongtaiDesignTokens.financePurple
                  : TongtaiDesignTokens.lightTextSecondary,
              fontWeight: p == period ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
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
          child: Text(context.l10n.actionViewAll),
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
          context.l10n.reportsNoPipeline,
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
                  label: context.l10n.reportsOpenLabel,
                  value: '${pipeline.activeCount}',
                ),
              ),
              Expanded(
                child: _PipelineStat(
                  label: context.l10n.reportsPipelineValue,
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
              subtitle:
                  '${context.l10n.reportsSoldPrefix} ${products[i].quantity}',
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
              subtitle: context.l10n.reportsOrdersCount(customers[i].orders),
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
            '${context.l10n.reportsPeakPrefix} ${TongtaiFormatters.vnd(report.peakMonthlyRevenue)}',
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
              context.l10n.reportsEmptyTitle,
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.heading3Style.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing2),
            Text(
              context.l10n.reportsEmptyBody,
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

/// Everything the Reports screen is computed from, in one read.
typedef _ReportsData = ({
  ReportsService reports,
  BusinessMetrics metrics,
  List<Opportunity> opportunities,
});
