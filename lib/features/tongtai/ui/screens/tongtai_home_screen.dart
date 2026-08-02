import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tongtai_formatters.dart';
import '../../finance/finance_summary.dart';
import '../../journey/journey.dart';
import '../../journey/journey_controller.dart';
import '../../journey/journey_node.dart';
import '../../journey/journey_planner.dart';
import '../../providers/tongtai_finance_provider.dart';
import '../../providers/tongtai_profile_provider.dart';
import '../../journey/business_goal.dart';
import '../../metrics/business_health.dart';
import '../../metrics/business_metrics.dart';
import '../../core/screen_data_controller.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../journey/journey_progress.dart';
import '../../providers/tongtai_navigation_provider.dart';
import '../../providers/tongtai_orders_provider.dart';
import '../widgets/tongtai_screen_data.dart';
import '../widgets/tongtai_more_action.dart';
import '../../opportunity/opportunity.dart';
import '../../providers/tongtai_context_provider.dart';
import '../../providers/tongtai_data_invalidation.dart';
import '../../providers/tongtai_journey_provider.dart';
import '../../providers/tongtai_sample_provider.dart';
import '../../providers/tongtai_search_provider.dart';
import 'tongtai_chat_screen.dart';
import 'tongtai_customer_list_screen.dart';
import 'tongtai_goals_screen.dart';
import 'tongtai_journey_screen.dart';
import 'tongtai_inventory_screen.dart';
import 'tongtai_finance_screen.dart';
import 'tongtai_reports_screen.dart';
import 'tongtai_unified_search_screen.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../journey/journey_metric.dart';
import 'tongtai_opportunity_feed_screen.dart';
import '../../metrics/home_headline.dart';
import '../widgets/tongtai_fox_mascot.dart';
import 'tongtai_business_inputs_screen.dart';
import '../../producer/business_input.dart';

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
  bool _seeding = false;

  /// The whole dashboard in one read (WTM-148). Home reads five sources; if
  /// any of them throws, every tile on this screen would otherwise show a
  /// confident zero — the most damaging version of the silent-empty bug,
  /// because zero revenue reads as a fact about the business.
  late final ScreenDataController<_HomeData> _data;

  _HomeData get _d => _data.state.value ?? _injected() ?? _HomeData.empty;

  BusinessMetrics get _metrics => _d.metrics;
  BusinessHealth get _health => widget.health ?? _d.health;
  List<BusinessGoal> get _goals => _d.goals;
  int get _producers => _d.producers;
  int get _inventory => _d.inventory;
  int get _consumer => _d.consumer;
  int get _journey => _d.goals.length;
  List<Opportunity> get _loadedOpportunities => _d.opportunities;
  bool get _hasSamples => _d.hasSamples;

  /// Injected / demo mode — everything is known synchronously.
  _HomeData? _injected() {
    final metrics = widget.metrics;
    if (metrics == null) return null;
    return _HomeData(
      metrics: metrics,
      health: widget.health ?? BusinessHealth.from(metrics),
      producers: widget.supplierCount ?? 0,
      inventory: widget.inventoryCount ?? 0,
      consumer: widget.customerCount ?? metrics.customersCount,
      goals: widget.goals ?? const [],
      opportunities: const [],
      hasSamples: false,
      hasData: metrics.ordersCount > 0 || metrics.customersCount > 0,
    );
  }

  @override
  void initState() {
    super.initState();
    _data = ScreenDataController<_HomeData>(
      _read,
      // Injected mode renders on the first frame; real mode renders
      // progressively, exactly as before — what is new is that a failing read
      // now says so instead of leaving the zeros to speak for it.
      initialValue: _injected(),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'home',
    );
    if (widget.metrics == null) _data.load();
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  Future<_HomeData> _read() async {
    // Home consumes the BusinessContext Aggregate Root (WTM-129) for its KPIs +
    // capability counts + health — the same seam AI reads. Journey (goals) and
    // Producer (favourites) are not in the Phase-1 context yet, so they load
    // alongside. Resolve every provider before the first await (the widget may be
    // disposed mid-load).
    final contextService = ref.read(businessContextServiceProvider);
    final goalRepo = ref.read(businessGoalRepositoryProvider);
    final favoritesStore = ref.read(tongtaiSearchFavoritesStoreProvider);
    final seeder = ref.read(sampleDataSeederProvider);
    final opportunitiesFuture = ref.read(generatedOpportunitiesProvider.future);
    final context = await contextService.load();
    // WTM-200: derive goal progress from real orders, exactly as the Goals
    // screen does. Reading the persisted `achievedAmount` gave Home a second,
    // staler answer — the seller added an order and saw 60% on Goals while Home
    // still said 40%, for the same goal on the same day. WTM-138's own note
    // says "the persisted goals stay untouched", i.e. the stored field was
    // designed to stop being the truth; Home was still reading it.
    final goals = deriveGoalsProgress(
      await goalRepo.loadAll(),
      await ref.read(orderRepositoryProvider).loadAll(),
      DateTime.now(),
    );
    final favorites = await favoritesStore.loadAll();
    final List<Opportunity> generated = await opportunitiesFuture;
    // WTM-210: the mission block reads the journey — one source for "today's
    // work". The tiles used to render goals wearing a mission label, so Home
    // and the Journey screen described the same idea from two sources.
    final journey = await ref.read(journeyRepositoryProvider).loadActive();
    return _HomeData(
      metrics: context.metrics,
      health: context.health,
      inventory: context.inventory.productCount,
      consumer: context.customers.total,
      goals: goals,
      producers: favorites.length,
      opportunities: generated,
      hasSamples: await seeder.hasSamples(),
      hasData: context.hasData,
      journey: journey,
    );
  }

  /// A brand-new business — nothing created in any capability yet.
  bool get _isEmptyBusiness =>
      _consumer == 0 &&
      _inventory == 0 &&
      _journey == 0 &&
      _metrics.ordersCount == 0;

  /// "Xem thử Demo" (WTM-144/ADR-TON-014): seeds the sample fixtures into the
  /// PRODUCTION repositories — no parallel demo screen — then reloads so this
  /// same dashboard (and every other screen) shows them.
  Future<void> _seedSamples() async {
    setState(() => _seeding = true);
    final failure = await runTongtaiAction(
      () => ref.read(sampleDataSeederProvider).seed(),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'home',
    );
    if (!mounted) return;
    setState(() => _seeding = false);
    if (failure != null) {
      showTongtaiFailure(context, failure, onRetry: _seedSamples);
      return;
    }
    // The cached capability/twin/opportunity providers must drop their pre-seed
    // answers BEFORE the refresh reads them again (WTM-149 device defect 1) —
    // `generatedOpportunitiesProvider` is one of them, so without this Home
    // would repaint with the numbers it had before the seed.
    invalidateBusinessDataProviders(ref);
    await _data.refresh();
    if (!mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.homeSampleLoadedSnack)));
  }

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

  /// Returns when the pushed screen is popped — WTM-220 needs that moment to
  /// re-measure the journey the seller just did work for.
  Future<void> _push(BuildContext context, Widget screen) {
    return Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => screen));
  }

  /// The mission tiles, or the honest state that explains what to do next.
  List<Widget> _missionBlock(BuildContext context) {
    final journey = _d.journey;
    if (journey == null) {
      // No journey yet. With a goal, one tap starts the plan right here — the
      // WTM-187 leftover: `startJourney` never had a production caller. With
      // no goal there is nothing to plan for, and the message says so instead
      // of dressing goals up as missions.
      if (_goals.isEmpty) {
        return [_EmptyBox(context.l10n.homeStartJourneyNeedGoal)];
      }
      return [
        _EmptyBox(context.l10n.homeNoMissions),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const Key('home-start-journey'),
          onPressed: _startJourney,
          icon: const Icon(Icons.route_outlined),
          label: Text(context.l10n.homeStartJourney),
        ),
      ];
    }
    // Actionable first: steps and missions the seller can do; milestones only
    // when nothing finer-grained is pending.
    final pending = [
      for (final n in journey.nodes)
        if (!n.isDone && n.kind != JourneyNodeKind.milestone) n,
    ];
    final shown = pending.isNotEmpty
        ? pending
        : [
            for (final n in journey.nodes)
              if (!n.isDone) n,
          ];
    if (shown.isEmpty) return [_EmptyBox(context.l10n.homeNoMissions)];
    return [
      for (final node in shown.take(3))
        _JourneyMissionTile(
          node: node,
          // WTM-220: a mission tile opens the WORK, not a list of missions.
          // Sending the seller to the journey screen was a half-step — they
          // already know what the mission is; what they lacked was the door.
          // Steps with nowhere honest to go still open the journey, where the
          // full plan and its provenance live.
          onOpen: () async {
            final destination = journeyNodeDestination(node);
            if (destination == null) {
              _push(context, const TongtaiJourneyScreen());
              return;
            }
            await _push(context, _destinationScreen(destination));
            if (!mounted) return;
            await _refreshJourneyProgress();
          },
        ),
    ];
  }

  /// The screen a journey step's work happens in (WTM-220). The mapping rule
  /// itself lives in the domain (`journeyNodeDestination`) — this only turns
  /// its answer into a widget.
  Widget _destinationScreen(JourneyDestination destination) =>
      switch (destination) {
        JourneyDestination.finance => const TongtaiFinanceScreen(),
        JourneyDestination.customers => const TongtaiCustomerListScreen(),
        JourneyDestination.inventory => const TongtaiInventoryScreen(),
        JourneyDestination.opportunity => const TongtaiOpportunityFeedScreen(),
        JourneyDestination.inputs => const TongtaiBusinessInputsScreen(),
      };

  /// Re-measures the journey after the seller comes back from doing the work,
  /// so Home's mission block reflects it immediately (WTM-220).
  Future<void> _refreshJourneyProgress() async {
    // WTM-224: measuring lives in the read path now — re-read and the journey
    // arrives already measured, whoever did the work and wherever they were.
    ref.invalidate(journeyMetricsProvider);
    ref.invalidate(journeysProvider);
    if (mounted) await _data.refresh();
  }

  /// Plans and stores a journey for the seller's first goal (WTM-210).
  Future<void> _startJourney() async {
    final l10n = context.l10n;
    final goal = _goals.first;
    final profile = await ref.read(businessProfileProvider.future);
    final expenses = await ref.read(financeRepositoryProvider).loadAll();
    // WTM-211: the planner sees the receivables, from the same owner Finance
    // shows — a journey planned here knows about money stuck in unpaid orders.
    final summary = FinanceService(
      expenses,
      orders: await ref.read(orderRepositoryProvider).loadAll(),
    ).summaryAsOf(DateTime.now());
    // WTM-235: kế hoạch phải thấy cả chi phí ĐẦU VÀO, không chỉ tiền đã tiêu
    // và tiền khách nợ. `unknownCount` đi kèm có chủ đích — planner cần biết
    // tổng cam kết còn thiếu để không phán xét nó như một con số đủ.
    final inputs = await ref.read(businessInputRepositoryProvider).loadAll();
    final inputSummary = BusinessInputSummary.from(inputs);
    if (!mounted) return;
    final failure = await runTongtaiAction(
      () async {
        final journey =
            await JourneyController(
              ref.read(journeyRepositoryProvider),
            ).startJourney(
              JourneyPlanInput(
                goal: goal,
                profile: profile,
                productCount: _d.inventory,
                customerCount: _d.consumer,
                orderCount: _metrics.ordersCount,
                expenseCount: expenses.length,
                receivables: summary.receivables,
                debtorCount: summary.debtorCount,
                inputCount: inputSummary.total,
                countedInputs: inputSummary.total - inputSummary.unknownCount,
                monthlyCommitment: inputSummary.monthlyCommitment,
              ),
              journeyId: 'journey-${goal.id}',
            );
        if (journey == null) {
          // The planner refused — a brand-new business cannot be planned for,
          // and an empty plan on screen would be worse than saying so.
          throw StateError('insufficient');
        }
      },
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'home',
    );
    if (!mounted) return;
    if (failure != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.journeyInsufficientBody)));
      return;
    }
    _data.refresh();
  }

  @override
  Widget build(BuildContext context) {
    // The business data can change from another screen (restore a backup, seed
    // or remove sample data). This screen is kept alive by the shell's
    // IndexedStack, so its `initState` load never runs again — without this it
    // would keep rendering a business that no longer exists (WTM-174).
    ref.listen(businessDataRevisionProvider, (_, _) => _data.refresh());
    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(context.l10n.titleHomeDashboard),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            tooltip: context.l10n.actionSearch,
            icon: const Icon(Icons.search),
            onPressed: () => _openSearch(context),
          ),
          IconButton(
            key: const Key('home-open-chat'),
            tooltip: context.l10n.homeChatTooltip,
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => _openChat(context),
          ),
          const TongtaiMoreAction(),
        ],
      ),
      body: ListenableBuilder(
        listenable: _data,
        builder: (context, _) => TongtaiScreenData<_HomeData>(
          prefix: 'home',
          state: _data.state,
          onRetry: _data.retry,
          builder: _dashboard,
        ),
      ),
    );
  }

  Widget _dashboard(BuildContext context, _HomeData data) {
    // Real mode: the Rule Engine's generated opportunities over persisted data
    // (WTM-144 one-source); injected lists are for tests/previews only.
    final topOpportunities =
        (widget.opportunities ?? _loadedOpportunities).toList()..sort(
          (a, b) => (b.score.value ?? -1).compareTo(a.score.value ?? -1),
        );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero (WTM-221) ────────────────────────────────────────────
          // The Concept opens Home with the app talking to the seller, not a
          // row of numbers they must read for themselves — that is what an
          // "AI Business OS" front door looks like. The sentence is chosen by
          // a rule over real counts (`homeHeadlineKind`) and the count comes
          // from the Rule Engine, so this renders with no AI key and no
          // network (ADR-TON-016).
          _Hero(
            opportunityCount: topOpportunities.length,
            hasData: data.hasData,
            onAsk: () => _openChat(context),
          ),
          const SizedBox(height: 16),

          // ── Today's missions — from the JOURNEY (WTM-210 · D-11) ──
          //
          // FIRST after the hero, as the Concept has it (WTM-222). This block
          // used to sit at the very bottom, under the KPIs and the
          // opportunities: a seller had to scroll past two other stories to
          // reach the one thing they were meant to do today. Order on a screen
          // IS a statement about what matters, and D-11 already made that
          // statement — the Journey is the product's centre.
          //
          // The tiles read the JOURNEY, not goals wearing a mission label
          // (WTM-210) — Home and the journey screen describe "today's work"
          // from one source.
          _SectionHeader(
            title: context.l10n.homeTodaysMissions,
            actionKey: const Key('home-open-journey'),
            actionLabel: context.l10n.actionViewAll,
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TongtaiJourneyScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._missionBlock(context),
          const SizedBox(height: 24),

          // ── Sample-data banner (WTM-144/ADR-TON-014): when sample rows
          //    are present, every screen shows them as ordinary data — this
          //    banner is the one reminder + pointer to the remover in More. ─
          if (_hasSamples) ...[
            Container(
              key: const Key('home-sample-banner'),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TongtaiDesignTokens.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: TongtaiDesignTokens.warning.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.science_outlined,
                    size: 20,
                    color: TongtaiDesignTokens.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.homeSampleBanner,
                      style: TongtaiDesignTokens.captionStyle.copyWith(
                        color: TongtaiDesignTokens.lightTextPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
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
                      Expanded(
                        child: Text(
                          context.l10n.homeWelcome,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Scale down instead of overflowing on narrow
                      // screens at accessibility text sizes (P0 §3).
                      // Flexible bounds the width — a bare FittedBox in a
                      // Row gets unbounded constraints and never shrinks.
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _HealthBadge(health: _health),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.homeAiSubtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
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
              onOrder: () => _push(context, const TongtaiCustomerListScreen()),
              onGoal: () => _push(context, const TongtaiGoalsScreen()),
              onDemo: _seeding ? () {} : _seedSamples,
            ),
            const SizedBox(height: 24),
          ],

          // ── Quick actions (WTM-144): once the business has data the
          //    Get-started card retires, but Home keeps one-tap shortcuts —
          //    field feedback: the Founder thought the features were gone. ──
          if (!_isEmptyBusiness) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  key: const Key('home-quick-customer'),
                  avatar: const Icon(Icons.person_add_alt, size: 18),
                  label: Text(context.l10n.homeAddCustomer),
                  onPressed: () =>
                      _push(context, const TongtaiCustomerListScreen()),
                ),
                ActionChip(
                  key: const Key('home-quick-product'),
                  avatar: const Icon(Icons.add_box_outlined, size: 18),
                  label: Text(context.l10n.homeAddProduct),
                  onPressed: () =>
                      _push(context, const TongtaiInventoryScreen()),
                ),
                ActionChip(
                  key: const Key('home-quick-order'),
                  avatar: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: Text(context.l10n.homeAddOrder),
                  onPressed: () =>
                      _push(context, const TongtaiCustomerListScreen()),
                ),
                ActionChip(
                  key: const Key('home-quick-goal'),
                  avatar: const Icon(Icons.flag_outlined, size: 18),
                  label: Text(context.l10n.homeAddGoal),
                  onPressed: () => _push(context, const TongtaiGoalsScreen()),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // ── Business KPIs — real values, zero is valid (WTM-128) ──
          _SectionHeader(
            title: context.l10n.sectionBusinessKpis,
            actionKey: const Key('home-open-reports'),
            actionLabel: context.l10n.homeViewReports,
            onAction: () => _push(context, const TongtaiReportsScreen()),
            // WTM-206: Finance was reachable only through More — three taps
            // into the toolbox — while this very row shows the revenue and the
            // journey now asks the seller to record expenses (WTM-198).
            // Telling someone to do a thing and hiding the door is a design
            // arguing with itself.
            secondaryActionKey: const Key('home-open-finance'),
            secondaryActionLabel: context.l10n.titleFinance,
            onSecondaryAction: () =>
                _push(context, const TongtaiFinanceScreen()),
          ),
          const SizedBox(height: 12),
          _KpiRow(metrics: _metrics),
          const SizedBox(height: 24),

          // ── Top opportunities (AI-generated; empty for new users) ─
          _SectionHeader(
            title: context.l10n.sectionTopOpportunities,
            actionKey: const Key('home-open-opportunities'),
            actionLabel: context.l10n.actionViewAll,
            // WTM-192: **switch to the tab**, don't push a copy. Opportunity is
            // a tab now, and pushing would give the seller two instances of the
            // same screen with independent filter/sort state — the parallel
            // state One Data Path (ADR-TON-015) exists to prevent.
            onAction: () => ref
                .read(tongtaiSelectedTabProvider.notifier)
                .select(TongtaiTabs.opportunity),
          ),
          const SizedBox(height: 12),
          if (topOpportunities.isEmpty)
            _EmptyBox(context.l10n.homeNoOpportunities)
          else
            ...topOpportunities
                .take(3)
                .map((o) => _OpportunityTile(opportunity: o)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Everything the Home dashboard shows, read as one unit.
///
/// A record rather than nine `setState` fields: with one value there is one
/// state to be loading, ready, stale or failed — nine fields could (and did)
/// disagree with each other while a partial read was in flight.
@immutable
class _HomeData {
  const _HomeData({
    required this.metrics,
    required this.health,
    required this.inventory,
    required this.consumer,
    required this.goals,
    required this.producers,
    required this.opportunities,
    required this.hasSamples,
    required this.hasData,
    this.journey,
  });

  static const _HomeData empty = _HomeData(
    metrics: BusinessMetrics.empty,
    health: BusinessHealth.notEnoughData,
    inventory: 0,
    consumer: 0,
    goals: [],
    producers: 0,
    opportunities: [],
    hasSamples: false,
    hasData: false,
  );

  /// The one active journey, or `null` when the seller has not started one
  /// (WTM-210). What "Nhiệm vụ hôm nay" is actually made of.
  final Journey? journey;

  /// Whether this business has anything in it at all — read from
  /// `BusinessContext.hasData`, the owner (WTM-221). Home must not re-derive
  /// it: two answers to "is this business empty" is exactly the defect family
  /// WTM-196/200/201/205 removed.
  final bool hasData;

  final BusinessMetrics metrics;
  final BusinessHealth health;
  final int inventory;
  final int consumer;
  final List<BusinessGoal> goals;
  final int producers;
  final List<Opportunity> opportunities;
  final bool hasSamples;
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
      // Was health.label('en') below and a Vietnamese-only reason here, so the
      // Vietnamese build showed "Not enough data" and the English build would
      // show a Vietnamese tooltip (WTM-173). Both now follow the active locale.
      message: health.reasonFor(context.l10n.languageCode),
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
              health.label(context.l10n.languageCode),
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
              context.l10n.sectionGetStarted,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.homeEmptyBody,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _CtaTile(
              tileKey: const Key('home-cta-customer'),
              icon: Icons.person_add_alt_1,
              label: context.l10n.homeCtaCustomer,
              onTap: onCustomer,
            ),
            _CtaTile(
              tileKey: const Key('home-cta-product'),
              icon: Icons.add_box_outlined,
              label: context.l10n.homeCtaProduct,
              onTap: onProduct,
            ),
            _CtaTile(
              tileKey: const Key('home-cta-order'),
              icon: Icons.receipt_long_outlined,
              label: context.l10n.homeCtaOrder,
              onTap: onOrder,
            ),
            _CtaTile(
              tileKey: const Key('home-cta-goal'),
              icon: Icons.flag_outlined,
              label: context.l10n.homeCtaGoal,
              onTap: onGoal,
            ),
            _CtaTile(
              tileKey: const Key('home-cta-demo'),
              icon: Icons.play_circle_outline,
              label: context.l10n.homeCtaDemo,
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
    this.secondaryActionKey,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final Key actionKey;
  final String actionLabel;
  final VoidCallback onAction;

  /// Optional second action (WTM-206). The KPI header shows the money, so it
  /// carries the two doors money leads to: Reports and Finance.
  final Key? secondaryActionKey;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        // Flexible + FittedBox: at large text scales the action label must
        // shrink rather than push the Row past its bounds (P0 §3).
        // Flexible + FittedBox: at large text scales the action labels must
        // shrink rather than push the Row past its bounds (P0 §3).
        if (secondaryActionLabel case final label?)
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: TextButton(
                key: secondaryActionKey,
                onPressed: onSecondaryAction,
                child: Text(label),
              ),
            ),
          ),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: TextButton(
              key: actionKey,
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ),
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
          cardKey: const Key('home-tile-producer'),
          title: context.l10n.navProducer,
          count: '$producers',
          color: TongtaiDesignTokens.producerGreen,
        ),
        _ModuleCard(
          cardKey: const Key('home-tile-inventory'),
          title: context.l10n.navInventory,
          count: '$inventory',
          color: TongtaiDesignTokens.inventoryOrange,
        ),
        _ModuleCard(
          cardKey: const Key('home-tile-consumer'),
          title: context.l10n.navConsumer,
          count: '$consumers',
          color: TongtaiDesignTokens.consumerBlue,
        ),
        _ModuleCard(
          cardKey: const Key('home-tile-journey'),
          title: context.l10n.tileJourney,
          count: '$journeys',
          color: const Color(0xFFFBBF24),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    this.cardKey,
    required this.title,
    required this.count,
    required this.color,
  });

  final Key? cardKey;
  final String title;
  final String count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: cardKey,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      // FittedBox: the grid's fixed aspect ratio cannot grow with the text
      // scale — shrink the content instead of overflowing (P0 §3).
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
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
            label: context.l10n.kpiRevenue,
            value: TongtaiFormatters.vndShort(metrics.revenue),
            color: TongtaiDesignTokens.financePurple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiTile(
            tileKey: const Key('home-kpi-orders'),
            label: context.l10n.kpiOrders,
            value: '${metrics.ordersCount}',
            color: TongtaiDesignTokens.consumerBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiTile(
            tileKey: const Key('home-kpi-aov'),
            label: context.l10n.kpiAovShort,
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
              // '—' when nothing could be scored: a dash reads as "unknown",
              // a 0 would read as "worthless" (WTM-193).
              opportunity.score.value?.round().toString() ?? '—',
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
                  // WTM-193: was `ROI ×2.5` from a constant. Expected impact is
                  // a real number from the seller's own orders.
                  TongtaiFormatters.vnd(opportunity.expectedImpact),
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
/// One journey node on Home (WTM-210) — a real mission, not a goal in a
/// mission costume.
/// Home's opening — the Concept's front door (WTM-221).
///
/// A greeting, one sentence the app says about the seller's business right
/// now, and the way to ask it something. The sentence is picked by
/// [homeHeadlineKind] over real counts, so it can never claim opportunities
/// that do not exist, and it needs no AI key to render: the count comes from
/// the Rule Engine (ADR-TON-016 — the twin is authoritative, AI only explains).
///
/// No microphone: voice input is a Future Capability (Founder, WTM-208), and a
/// mic that does nothing is the WTM-169 defect wearing a new icon.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.opportunityCount,
    required this.hasData,
    required this.onAsk,
  });

  final int opportunityCount;
  final bool hasData;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final headline = switch (homeHeadlineKind(
      opportunityCount: opportunityCount,
      hasData: hasData,
    )) {
      HomeHeadlineKind.opportunities => l10n.homeHeadlineOpportunities(
        opportunityCount,
      ),
      HomeHeadlineKind.noneToday => l10n.homeHeadlineNoneToday,
      HomeHeadlineKind.notEnoughData => l10n.homeHeadlineNotEnoughData,
    };

    return Column(
      key: const Key('home-hero'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const TongtaiFoxMascot.avatar(size: 40),
            const SizedBox(width: TongtaiDesignTokens.spacing3),
            Expanded(
              child: Text(
                // No name: the product has no account (D-4), so it does not
                // know the seller's — and inventing one would be the first
                // thing it ever told them that was untrue.
                l10n.homeGreeting,
                style: TongtaiDesignTokens.smallStyle.copyWith(
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing2),
        Text(
          headline,
          key: const Key('home-hero-headline'),
          style: TongtaiDesignTokens.heading2Style.copyWith(
            color: TongtaiDesignTokens.lightTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('home-ask'),
            onTap: onAsk,
            borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusFull),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: TongtaiDesignTokens.buttonHeight,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: TongtaiDesignTokens.spacing4,
                vertical: TongtaiDesignTokens.spacing3,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  TongtaiDesignTokens.radiusFull,
                ),
                border: Border.all(color: TongtaiDesignTokens.lightBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: TongtaiDesignTokens.copilotViolet,
                  ),
                  const SizedBox(width: TongtaiDesignTokens.spacing2),
                  Expanded(
                    child: Text(
                      l10n.homeAskHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TongtaiDesignTokens.smallStyle.copyWith(
                        color: TongtaiDesignTokens.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _JourneyMissionTile extends StatelessWidget {
  const _JourneyMissionTile({required this.node, required this.onOpen});

  final JourneyNode node;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('home-mission-${node.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onOpen,
        leading: Icon(
          node.state == JourneyNodeState.inProgress
              ? Icons.play_circle_outline
              : Icons.radio_button_unchecked,
          color: TongtaiDesignTokens.copilotViolet,
        ),
        title: Text(node.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        // Provenance stays visible (WTM-191): a commitment the seller made
        // from an opportunity must not read as one of the rules' ideas.
        subtitle: node.isFromOpportunity
            ? Text(context.l10n.journeyFromOpportunity)
            : null,
        trailing: const Icon(Icons.chevron_right, size: 18),
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
