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
import '../../metrics/home_trend.dart';
import '../../core/screen_data_controller.dart';
import '../../../../core/design/tt.dart';
import '../../navigation/tongtai_design_tokens.dart' show TongtaiTabs;
import '../../journey/journey_progress.dart';
import '../../providers/tongtai_navigation_provider.dart';
import '../../providers/tongtai_orders_provider.dart';
import '../widgets/tongtai_screen_data.dart';
import '../widgets/tongtai_more_action.dart';
import '../../opportunity/opportunity.dart';
import '../../opportunity/opportunity_priority.dart';
import '../widgets/tt_metric_card.dart';
import 'tongtai_opportunity_detail_screen.dart';
import '../../providers/tongtai_capability_provider.dart';
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
import '../../metrics/top_actions.dart';
import '../widgets/tongtai_brief_card.dart';
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
    // WTM-404 — đường xu hướng trên thẻ KPI đọc **Capability Context** của
    // doanh thu, đúng đường ADR-TON-016 dựng cho phân tích chuyên sâu:
    // BusinessContext chỉ giữ summary nhẹ (`metrics.revenue` là MỘT số), còn
    // hình dạng theo tháng nằm ở capability và tải on-demand. Home không tự
    // cộng lại chuỗi từ đơn hàng — làm vậy là câu trả lời thứ hai cho cùng câu
    // hỏi, và hai câu trả lời sẽ lệch nhau đúng vào ngày ai đó sửa một bên.
    final revenueCapabilityFuture = ref.read(revenueCapabilityProvider.future);
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
    // WTM-404 — lợi nhuận và tỉ suất lãi gộp trên thẻ "Sức khoẻ doanh nghiệp".
    // Cùng `FinanceService` mà màn Tài chính và planner hành trình dùng
    // (WTM-211), nên Home không thể nói một con số lợi nhuận khác với màn Tài
    // chính cho cùng một ngày.
    final finance = FinanceService(
      await ref.read(financeRepositoryProvider).loadAll(),
      orders: await ref.read(orderRepositoryProvider).loadAll(),
    ).summaryAsOf(DateTime.now());
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
      trend: HomeTrend.from(
        (await revenueCapabilityFuture).series,
        // Lợi nhuận cần **chi phí**; chuỗi doanh thu không có nó. Đây là cùng
        // `FinanceService` mà màn Tài chính dùng — Home không tự trừ thu-chi.
        profitByMonth: [for (final m in finance.monthly) m.net],
      ),
      finance: finance,
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
  ///
  /// WTM-343: **cùng một seeder với More.** Trước đây Home gieo bộ viết tay
  /// còn More gieo 12 tháng, nên hai nút cùng tên "xem thử" cho ra hai doanh
  /// nghiệp khác nhau — và người bán không có cách nào biết mình đang xem cái
  /// nào.
  Future<void> _seedSamples() async {
    setState(() => _seeding = true);
    final failure = await runTongtaiAction(
      () => ref.read(sampleBusinessSeederProvider).seed(),
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
        // ⭐ WTM-390: trước đây ô này chỉ nói *"tạo một mục tiêu trước"* rồi
        // dừng — người bán đọc xong không đi được đâu. Một ô trống biết mình
        // thiếu gì mà không mở đường đi tới đó là một ngõ cụt, không phải một
        // lời hướng dẫn.
        return [
          _EmptyBox(context.l10n.homeStartJourneyNeedGoal),
          const SizedBox(height: 8),
          TtPrimaryButton(
            key: const Key('home-empty-create-goal'),
            label: context.l10n.homeAddGoal,
            icon: Icons.flag_outlined,
            expand: false,
            onPressed: () => _push(context, const TongtaiGoalsScreen()),
          ),
        ];
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
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        // ⭐ WTM-404 — cửa trước mang TÊN SẢN PHẨM, không phải chữ "Bảng điều
        // khiển".
        //
        // Founder mở app cạnh `cp_home.png` và thấy một thanh tiêu đề nói
        // *"Bảng điều khiển"*. Đó là tên một **loại màn hình** — mọi phần mềm
        // quản lý đều có một cái. Concept mở bằng linh vật + *"Tổng Tài AI"* +
        // huy hiệu *"AI Business OS"*: ba thứ nói app này **là ai**, ngay dòng
        // đầu tiên người xem demo nhìn thấy.
        //
        // `titleHomeDashboard` vẫn còn: nó là nhãn **điều hướng** (route,
        // semantics, lịch sử) chứ không phải nhãn thương hiệu.
        title: const _BrandTitle(),
        titleSpacing: TtSpace.x4,
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

          // ── AI Morning Brief (WTM-304 · Epic WTM-302) ─────────────────
          //
          // Ngay sau hero và TRÊN mọi ô số. Hero nói app biết doanh nghiệp
          // này; brief nói nó đã NHÌN doanh nghiệp này sáng nay — *"Tổng Tài
          // đã nhìn doanh nghiệp trước khi tôi mở app"* (Task Order §6).
          //
          // Đặt nó dưới các ô KPI sẽ biến nó thành một mục nữa trong bảng
          // điều khiển. Thứ tự trên màn hình LÀ một lời khẳng định về thứ gì
          // quan trọng — cùng lập luận đã đưa "việc hôm nay" lên trên KPI ở
          // WTM-222.
          //
          // Thẻ tự lo trạng thái của nó: chưa tính xong thì không chiếm chỗ,
          // hỏng thì nói ra. Nó KHÔNG đi qua `_data` vì brief là một đường
          // đọc khác nhịp — Rule Twin trên toàn sổ sách, không phải năm con
          // số của Home.
          // `showCount: false` — WTM-388. Trên Home thẻ này là nguồn phía
          // sau, không phải một bảng đếm thứ hai.
          TongtaiBriefCard(clock: widget.clock, showCount: false),
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
          // ⭐ WTM-388: khối này nói về **hành trình mục tiêu**, không phải
          // "việc hôm nay".
          //
          // Nó từng mang tiêu đề *"Việc hôm nay"* và hiện *"Chưa có nhiệm vụ
          // nào"* — đứng ngay dưới câu *"Hôm nay có 5 việc đáng làm nhất"*.
          // Hai câu cùng nhận là "hôm nay", nói ngược nhau, cách nhau một màn
          // hình.
          //
          // Nội dung không đổi; thứ đổi là nó **thôi nhận mình là câu trả lời
          // cho "hôm nay làm gì"** — câu đó nay chỉ có một chủ, ở hero.
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

          // ⛔ WTM-343 — KHÔNG còn băng-rôn "đang hiển thị dữ liệu mẫu".
          //
          // Founder chốt 2026-08-09: bản demo phải trông như thật. Băng-rôn
          // nói về **dữ liệu**, không nói về trạng thái kỹ thuật, nên bỏ nó
          // không phạm luật "cấm fake trạng thái engineering" (§40).
          //
          // Hai thứ giữ lại để rủi ro "nhầm mẫu là số của mình" không thành
          // mất mát: mỗi bản ghi vẫn mang dấu `sample-` / `importJobId`, và
          // "Xóa dữ liệu mẫu" vẫn xoá đúng chúng mà không đụng dữ liệu thật.
          // ── Bốn năng lực, mỗi cái một thẻ (WTM-404) ───────────────
          //
          // ⭐ Trước đây khối này là một `Card` mang tiêu đề *"Chào mừng…"*, một
          // dòng phụ, một huy hiệu sức khoẻ, và bên trong là lưới 2×2 những ô
          // chỉ có tên + con số. Founder mở app cạnh concept và nói *"demo như
          // này thì không ai muốn xem"* — đây là khối khiến Home trông như một
          // **trang quản trị**: bốn con số trần, không cái nào nói mình đang đi
          // lên hay xuống, không cái nào có lối đi tiếp.
          //
          // Concept-1 vẽ chúng thành **một hàng thẻ cuộn ngang**, mỗi thẻ có ô
          // biểu tượng · con số · đơn vị · mức đổi · đường xu hướng · "Xem
          // ngay →". Giữ hàng cuộn ngang chứ không đổi thành lưới: bốn thẻ đủ
          // rộng để đọc được trên 411dp chỉ khi chúng KHÔNG phải chia đôi màn.
          //
          // Câu *"Chào mừng…"* bỏ hẳn — hero ngay trên đã chào rồi, và hai lời
          // chào cách nhau một màn hình là thứ WTM-388 vừa dọn ở chỗ khác.
          // Huy hiệu sức khoẻ chuyển xuống cạnh tiêu đề "Sức khoẻ doanh
          // nghiệp", nơi nó nói về đúng thứ nó đo.
          _CapabilityRail(
            producers: _producers,
            inventory: _inventory,
            consumers: _consumer,
            journeys: _journey,
            finance: data.finance,
            onProducer: () =>
                _push(context, const TongtaiBusinessInputsScreen()),
            onInventory: () => _push(context, const TongtaiInventoryScreen()),
            onConsumer: () => _push(context, const TongtaiCustomerListScreen()),
            onJourney: () => _push(context, const TongtaiJourneyScreen()),
            onFinance: () => _push(context, const TongtaiFinanceScreen()),
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

          // ── Việc Tổng Tài đề xuất — TRƯỚC các con số ──────────────
          //
          // ⭐ WTM-404: khối này đổi chỗ với "Sức khoẻ doanh nghiệp". Concept-1
          // đặt việc-phải-làm trên KPI, và đó là cùng lập luận WTM-222 đã dùng
          // để đưa nhiệm vụ lên trên KPI: **thứ tự trên màn hình LÀ một lời
          // khẳng định về thứ gì quan trọng.** Một AI Business OS mở ra bằng
          // *"làm cái này đi"*, không phải bằng bảng số để tự đọc lấy.
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
            _SuggestedActionsCard(
              opportunities: topOpportunities.take(3).toList(),
              onOpen: (o) => _push(
                context,
                TongtaiOpportunityDetailScreen(opportunity: o),
              ),
            ),
          const SizedBox(height: 24),

          // ── Sức khoẻ doanh nghiệp — real values, zero is valid (WTM-128) ──
          _SectionHeader(
            title: context.l10n.sectionBusinessKpis,
            actionKey: const Key('home-open-reports'),
            actionLabel: context.l10n.homeViewReports,
            onAction: () => _push(context, const TongtaiReportsScreen()),
            // ⛔ WTM-404 — bỏ nút "Tài chính" thứ hai ở đây.
            //
            // WTM-206 thêm nó vì lúc ấy Tài chính chỉ vào được qua More — ba
            // cú chạm trong hộp công cụ. Lý do ấy **đã hết**: thẻ "Tài chính"
            // trong hàng năng lực phía trên mở đúng màn ấy bằng một cú chạm, và
            // nó còn nói luôn công nợ đang là bao nhiêu.
            //
            // Giữ cả hai thì tiêu đề mục gãy làm đôi trên Nokia 6.1 — hai cửa
            // vào cùng một phòng, trả giá bằng cái tiêu đề.
          ),
          const SizedBox(height: 8),
          // Huy hiệu sức khoẻ đứng ngay dưới tiêu đề đo đúng thứ nó nói. Trước
          // WTM-404 nó nằm cạnh câu "Chào mừng…", tức một phán quyết về doanh
          // nghiệp treo cạnh một lời chào.
          Align(
            alignment: Alignment.centerLeft,
            child: _HealthBadge(health: _health),
          ),
          const SizedBox(height: 12),
          _KpiRow(metrics: _metrics, trend: data.trend, finance: data.finance),
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
    this.trend = HomeTrend.none,
    this.finance,
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

  /// Chuỗi tháng đứng sau các đường xu hướng trên thẻ KPI (WTM-404).
  final HomeTrend trend;

  /// Lợi nhuận + tỉ suất, từ cùng `FinanceService` màn Tài chính dùng.
  /// `null` khi Home chạy ở chế độ tiêm dữ liệu (test/preview) — thẻ tương ứng
  /// **biến mất**, không hiện số 0 giả.
  final FinanceSummary? finance;

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
    final color = healthy ? TtColors.success : TtColors.unknown;
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
          borderRadius: BorderRadius.circular(TtRadius.full),
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
              style: TtType.caption.copyWith(
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
              style: TtType.body.copyWith(color: TtColors.textSecondary),
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
      leading: Icon(icon, color: TtColors.info),
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
          child: Text(
            title,
            // ⭐ WTM-404 — MỘT dòng. Trên Nokia 6.1 *"Chỉ số kinh doanh"* xuống
            // hai dòng và ôm lấy hai nút bên phải; đọc ra thành *"Chỉ số kinh /
            // doanh · Tài chính · Xem báo cáo"*. Tiêu đề mục là một mốc để mắt
            // bám, và một cái mốc gãy đôi thì thôi làm mốc.
            //
            // Cắt bằng `…` chứ không thu nhỏ: ở đây tiêu đề đứng cạnh chữ khác
            // cùng cỡ, một tiêu đề nhỏ dần theo độ dài sẽ làm cả trang mất
            // thang bậc — khác trường hợp `_BrandTitle`, nơi cái tên phải giữ
            // đủ chữ nên thu nhỏ mới đúng.
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        // Flexible + FittedBox: at large text scales the action label must
        // shrink rather than push the Row past its bounds (P0 §3).
        //
        // ⛔ WTM-404 bỏ khả năng "hành động thứ hai": chỗ duy nhất dùng nó là
        // nút Tài chính, mà nút ấy nay thừa (thẻ năng lực đã mở đúng màn). Giữ
        // lại một tham số không ai truyền là để dành sẵn chỗ cho lần sau ai đó
        // nhét thêm một cửa nữa vào cùng cái tiêu đề.
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

/// Revenue YTD + order count + AOV, pulled from the reports aggregator.
/// The headline KPIs on Home — read straight from [BusinessMetrics] (the KPI
/// source of truth, WTM-127). Real values are always shown; **zero is valid
/// business data** and is never replaced with a "No Data" placeholder (WTM-128).
class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.metrics,
    required this.trend,
    required this.finance,
  });

  final BusinessMetrics metrics;
  final HomeTrend trend;
  final FinanceSummary? finance;

  /// Nhãn mức đổi, hoặc `null` khi **không có mốc để so**.
  ///
  /// Ba luật ở [HomeTrend] quyết định `null`; ở đây chỉ định dạng. Tách như vậy
  /// để luật kiểm được bằng unit test không cần dựng widget.
  static (String, TtTrend)? _delta(AppStrings l10n, double? percent) {
    if (percent == null) return null;
    final rounded = percent.abs() < 0.5 ? 0 : percent.round();
    if (rounded == 0) return null; // tròn về 0 ⇒ không có gì để khoe
    final sign = rounded > 0 ? '+' : '−';
    return (
      l10n.homeVsPrevMonth('$sign${rounded.abs()}%'),
      rounded > 0 ? TtTrend.up : TtTrend.down,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final revenueDelta = _delta(l10n, trend.revenueChangePercent);
    final ordersDelta = _delta(l10n, trend.ordersChangePercent);
    final profitDelta = _delta(l10n, trend.profitChangePercent);
    final f = finance;
    return _CardRail(
      children: [
        TtMetricCard(
          key: const Key('home-kpi-revenue'),
          label: l10n.kpiRevenue,
          value: TongtaiFormatters.vndShort(metrics.revenue),
          iconData: Icons.trending_up,
          iconColor: TtColors.brandOnDark,
          deltaLabel: revenueDelta?.$1,
          trend: revenueDelta?.$2 ?? TtTrend.unknown,
          series: trend.revenue,
        ),
        if (f != null)
          TtMetricCard(
            key: const Key('home-kpi-profit'),
            label: l10n.kpiProfit,
            value: TongtaiFormatters.vndShort(f.profitYtd),
            iconData: Icons.savings_outlined,
            iconColor: TtColors.aiOnLight,
            deltaLabel: profitDelta?.$1,
            trend: profitDelta?.$2 ?? TtTrend.unknown,
            series: trend.profit,
          ),
        TtMetricCard(
          key: const Key('home-kpi-orders'),
          label: l10n.kpiOrders,
          value: '${metrics.ordersCount}',
          iconData: Icons.receipt_long_outlined,
          iconColor: TtColors.infoOnLight,
          deltaLabel: ordersDelta?.$1,
          trend: ordersDelta?.$2 ?? TtTrend.unknown,
          series: trend.orders,
        ),
        TtMetricCard(
          key: const Key('home-kpi-aov'),
          label: l10n.kpiAovShort,
          value: TongtaiFormatters.vndShort(metrics.averageOrderValue),
          iconData: Icons.calculate_outlined,
          iconColor: TtColors.successOnLight,
          // ⛔ Không có đường: đơn trung bình theo tháng KHÔNG phải
          // `revenue[i] / orders[i]` lấy từ hai chuỗi này rồi chia — nó có
          // luật riêng ở `MonthlyRevenuePoint.averageOrderValue`. Chia tay ở
          // đây là dựng câu trả lời thứ hai cho cùng một chỉ số, đúng hình
          // dạng P-27/P-28. Thà thiếu một đường còn hơn thêm một chủ.
        ),
      ],
    );
  }
}

/// Bốn thẻ năng lực ở đầu Home — concept-1 hàng cuộn ngang (WTM-404).
class _CapabilityRail extends StatelessWidget {
  const _CapabilityRail({
    required this.producers,
    required this.inventory,
    required this.consumers,
    required this.journeys,
    required this.finance,
    required this.onProducer,
    required this.onInventory,
    required this.onConsumer,
    required this.onJourney,
    required this.onFinance,
  });

  final int producers;
  final int inventory;
  final int consumers;
  final int journeys;
  final FinanceSummary? finance;
  final VoidCallback onProducer;
  final VoidCallback onInventory;
  final VoidCallback onConsumer;
  final VoidCallback onJourney;
  final VoidCallback onFinance;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final f = finance;
    // ⚠️ Bốn thẻ này KHÔNG có `deltaLabel` và KHÔNG có `series`.
    //
    // Concept vẽ chúng kèm *"↑ 20% so với hôm qua"* và một đường. Chúng ta
    // chưa đo được: không repository nào giữ ảnh chụp "số sản phẩm hôm qua",
    // và một chuỗi nội suy từ ngày tạo bản ghi sẽ là **một xu hướng bịa**
    // (WTM-384, `estimatedGain` đội lốt `observedRevenue`).
    //
    // Vậy nên thẻ hiện đúng thứ đo được: con số, đơn vị, và lối đi tiếp. Ô
    // "Doanh thu" có mốc so ở khối Sức khoẻ bên dưới, nên ở đây nó cũng chỉ
    // nói con số — hai chỗ cùng một chỉ số phải nói cùng một điều.
    return _CardRail(
      children: [
        TtMetricCard(
          key: const Key('home-tile-producer'),
          label: l10n.navProducer,
          value: '$producers',
          unitLabel: l10n.homeUnitInputs,
          iconData: Icons.shopping_bag_outlined,
          iconColor: TtColors.successOnLight,
          tint: TtColors.successSoft,
          actionLabel: l10n.actionOpen,
          onTap: onProducer,
        ),
        TtMetricCard(
          key: const Key('home-tile-inventory'),
          label: l10n.navInventory,
          value: '$inventory',
          unitLabel: l10n.homeUnitProducts,
          iconData: Icons.warehouse_outlined,
          iconColor: TtColors.infoOnLight,
          tint: TtColors.infoSoft,
          actionLabel: l10n.actionOpen,
          onTap: onInventory,
        ),
        TtMetricCard(
          key: const Key('home-tile-consumer'),
          label: l10n.navConsumer,
          value: '$consumers',
          unitLabel: l10n.homeUnitCustomers,
          iconData: Icons.people_outline,
          iconColor: TtColors.brandOnDark,
          tint: TtColors.brandSoft,
          actionLabel: l10n.actionOpen,
          onTap: onConsumer,
        ),
        // ⭐ Thẻ thứ năm — concept vẽ bốn, ở đây phải là năm.
        //
        // Bỏ nó đi thì `count_list_contract_test` đỏ ngay: hợp đồng
        // ADR-TON-015 (*Summary Count == Domain Visible Records*) có một cặp
        // cho **mục tiêu**, và cặp ấy chỉ kiểm được khi Home còn công bố con
        // số. Hàng cuộn ngang nên thẻ thứ năm không tốn chỗ nào — đây là lý do
        // chọn hàng cuộn thay vì lưới 2×2 cố định.
        //
        // ⛔ Cách sai là xoá cặp khỏi suite cho test xanh: khối "Nhiệm vụ hôm
        // nay" phía trên nói về **hành trình đang chạy**, không công bố tổng số
        // mục tiêu, nên nó KHÔNG thay thế được phép kiểm này.
        TtMetricCard(
          key: const Key('home-tile-journey'),
          label: l10n.journeyTitle,
          value: '$journeys',
          unitLabel: l10n.homeUnitGoals,
          iconData: Icons.flag_outlined,
          iconColor: TtColors.warningOnDark,
          tint: TtColors.warningSoft,
          actionLabel: l10n.actionOpen,
          onTap: onJourney,
        ),
        // ⛔ Thẻ này KHÔNG hiện doanh thu.
        //
        // Bản đầu của WTM-404 để nó hiện `metrics.revenue`, và suite bắt ngay:
        // *"Found 2 widgets with text 4,06tr ₫"* — cùng một con số, hai chỗ,
        // một màn hình. Concept có vẻ làm thế, nhưng hai con số của nó là hai
        // **cửa sổ khác nhau** (*doanh thu hôm nay* ở thẻ năng lực vs *doanh
        // thu* ở khối sức khoẻ); chép hình mà bỏ mất khác biệt ấy là dựng đúng
        // lỗi "hai câu trả lời cho một câu hỏi".
        //
        // Công nợ là con số **chỉ Tài chính có**, và nó đáng một cú chạm: tiền
        // đã bán nhưng chưa về.
        if (f != null)
          TtMetricCard(
            key: const Key('home-tile-finance'),
            label: l10n.titleFinance,
            value: TongtaiFormatters.vndShort(f.receivables),
            unitLabel: l10n.financeReceivablesTitle,
            iconData: Icons.account_balance_wallet_outlined,
            iconColor: TtColors.aiOnLight,
            tint: TtColors.aiSoft,
            actionLabel: l10n.actionOpen,
            onTap: onFinance,
          ),
      ],
    );
  }
}

/// Hàng thẻ cuộn ngang — nhịp của concept-1.
///
/// ## Vì sao cuộn ngang chứ không lưới 2×2
///
/// Trên 411dp một lưới hai cột cho mỗi thẻ ~186dp; trừ viền và đệm còn ~160dp
/// cho một con số cỡ `h1`, một đơn vị, một mức đổi và một đường. Thẻ nào cũng
/// chật, và thẻ tiền (`24,56tr đ`) tràn trước tiên. Hàng cuộn cho mỗi thẻ
/// [cardWidth] cố định, đọc được ở mọi bề rộng máy.
///
/// ⚠️ **`IntrinsicHeight` bọc `Row`, không phải `ListView`.** Thẻ cao thấp khác
/// nhau tuỳ có mũi tên/đường hay không; để chúng tự do sẽ cho một hàng răng
/// cưa. Không dùng `childAspectRatio` cố định — nó cắt cụt thẻ cao nhất, đúng
/// lỗi tràn Home mà đợt P0 phải sửa.
class _CardRail extends StatelessWidget {
  const _CardRail({required this.children});

  final List<Widget> children;

  /// Đủ cho `24,56tr đ` ở cỡ `h1` mà không phải thu nhỏ.
  static const double cardWidth = 168;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Không thêm đệm: trang đã có `padding: 16`. Trên Nokia 6.1 (411dp) phần
      // còn lại là 379dp, tức hai thẻ đủ + ~31dp của thẻ thứ ba ló ra — đúng
      // tín hiệu "còn nữa, cuộn đi" mà concept vẽ bằng cách cắt ngang thẻ cuối.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: TtSpace.x3),
              SizedBox(width: cardWidth, child: children[i]),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Việc Tổng Tài đề xuất" — ba dòng trong MỘT thẻ (WTM-404, concept-1).
///
/// Trước đây mỗi cơ hội là một hộp viền riêng, mở đầu bằng một vòng tròn điểm
/// số trần (`61`, `47`, `44`). Trên máy Founder ba con số ấy là thứ nổi nhất
/// trong khối — mà chúng **không nói được phải làm gì**, và người bán không có
/// thang nào để biết 61 là cao hay thấp.
///
/// Concept chuyển trọng tâm sang **hành động**: một ô biểu tượng theo loại cơ
/// hội, tiêu đề, một dòng nói vì sao, một chip mức ưu tiên, và một nút. Điểm số
/// vẫn còn — nó là thứ **xếp thứ tự** ba dòng này — nhưng thôi làm nhân vật
/// chính.
class _SuggestedActionsCard extends StatelessWidget {
  const _SuggestedActionsCard({
    required this.opportunities,
    required this.onOpen,
  });

  final List<Opportunity> opportunities;
  final void Function(Opportunity) onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('home-suggested-actions'),
      decoration: BoxDecoration(
        color: TtColors.surface,
        borderRadius: BorderRadius.circular(TtRadius.lg),
        border: Border.all(color: TtColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < opportunities.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: TtColors.divider),
            _SuggestedActionRow(
              opportunity: opportunities[i],
              // Thứ hạng trong danh sách ĐANG HIỆN — xem
              // [OpportunityPriority]: điểm chỉ chống đỡ được thứ tự, không
              // chống đỡ được một ngưỡng tuyệt đối.
              rank: i,
              onOpen: () => onOpen(opportunities[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestedActionRow extends StatelessWidget {
  const _SuggestedActionRow({
    required this.opportunity,
    required this.rank,
    required this.onOpen,
  });

  final Opportunity opportunity;
  final int rank;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final code = Localizations.localeOf(context).languageCode;
    final priority = OpportunityPriority.at(opportunity, rank);
    return Padding(
      padding: const EdgeInsets.all(TtSpace.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(TtSpace.x2),
            decoration: BoxDecoration(
              color: TtColors.aiSoft,
              borderRadius: BorderRadius.circular(TtRadius.sm),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 18,
              color: TtColors.aiOnLight,
            ),
          ),
          const SizedBox(width: TtSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opportunity.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TtType.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: TtColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  // WTM-384: nhãn nói con số là **quan sát** hay **ước tính** —
                  // cùng luật màn chi tiết dùng. Một con số tiền không có nhãn
                  // ấy là một ước tính mặc áo phép đo.
                  '${opportunity.impactBasis.isEstimate ? l10n.oppImpact : l10n.oppObservedPrefix}: '
                  '${TongtaiFormatters.vndShort(opportunity.expectedImpact)}'
                  ' · ${opportunity.type.label(code)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TtType.caption.copyWith(color: TtColors.textSecondary),
                ),
                const SizedBox(height: TtSpace.x2),
                // ⚠️ `Flexible` + `spaceBetween`, KHÔNG phải `Spacer`.
                //
                // Với `Spacer`, chip giữ nguyên bề rộng tự nhiên và ở 320dp ·
                // cỡ chữ 1.3× hàng này tràn 33px — *"Ưu tiên: Trung bình"* +
                // nút *"Xử lý ngay"* rộng hơn dòng. `Flexible` cho chip co lại
                // (và cắt bằng `…`) trong khi nút giữ nguyên: nút là **lối
                // thoát**, mất chữ trên nút là mất đường đi.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: _PriorityChip(priority: priority)),
                    TextButton(
                      key: Key('home-action-${opportunity.id}'),
                      onPressed: onOpen,
                      style: TextButton.styleFrom(
                        foregroundColor: TtColors.brandOnDark,
                        padding: const EdgeInsets.symmetric(
                          horizontal: TtSpace.x3,
                        ),
                        minimumSize: const Size(0, TtButtonMetrics.height),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(TtRadius.sm),
                          side: const BorderSide(color: TtColors.brand),
                        ),
                      ),
                      child: Text(l10n.actionHandleNow),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip mức ưu tiên — *"Ưu tiên: Cao / Trung bình / Thấp"*.
class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final OpportunityPriority priority;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, fg, bg) = switch (priority) {
      OpportunityPriority.high => (
        l10n.oppPriorityHigh,
        TtColors.dangerOnLight,
        TtColors.dangerSoft,
      ),
      OpportunityPriority.medium => (
        l10n.oppPriorityMedium,
        TtColors.warningOnDark,
        TtColors.warningSoft,
      ),
      OpportunityPriority.low => (
        l10n.oppPriorityLow,
        TtColors.infoOnLight,
        TtColors.infoSoft,
      ),
      OpportunityPriority.unknown => (
        l10n.oppPriorityUnknown,
        TtColors.textSecondary,
        TtColors.unknownSoft,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TtSpace.x2,
        vertical: TtSpace.x1,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TtRadius.full),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TtType.caption.copyWith(color: fg, fontWeight: FontWeight.w600),
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
/// Tên sản phẩm ở đầu Trang chủ — linh vật · "Tổng Tài AI" · huy hiệu
/// "AI Business OS" (WTM-404, concept-1).
///
/// ⚠️ **Vẫn phải là tiêu đề tuyến đường.** Thay `Text` bằng một `Row` sẽ làm
/// TalkBack đọc rời từng mảnh và mất vai *header*; `Semantics(header: true,
/// label: …)` gộp chúng lại thành một nhãn, và `excludeSemantics` chặn các
/// mảnh con phát ra lần nữa (P-36: cây semantics là thứ phải kiểm bằng
/// `tester.ensureSemantics()`, không phải bằng mắt).
class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      key: const Key('home-brand-title'),
      header: true,
      label: '${l10n.startupBrand} — ${l10n.brandTagline}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TongtaiFoxMascot.face(size: 30),
          const SizedBox(width: TtSpace.x2),
          // Thu nhỏ thay vì tràn ở màn hẹp / cỡ chữ trợ năng — cùng khuôn P0
          // §3 mà `_HealthBadge` dùng. `Flexible` chặn bề rộng: một `FittedBox`
          // trần trong `Row` nhận ràng buộc vô hạn và không bao giờ co lại.
          //
          // ⚠️ Chọn co chữ chứ KHÔNG cắt bằng `ellipsis`: *"Tổng Tài A…"* là
          // một cái tên sai, còn chữ nhỏ vẫn là đúng cái tên ấy.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.startupBrand,
                    style: TtType.title.copyWith(
                      color: TtColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TtSpace.x2,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      // Viên cam giống concept. Cam = màu THƯƠNG HIỆU ở đây,
                      // và nó gắn với một cái tên — không gắn với một con số
                      // hay một trạng thái, nên không phạm luật A2.
                      color: TtColors.brandSoft,
                      borderRadius: BorderRadius.circular(TtRadius.full),
                    ),
                    child: Text(
                      l10n.brandTagline,
                      style: TtType.caption.copyWith(
                        color: TtColors.brandOnDark,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    // ⭐ WTM-388 — MỘT con số, và nó đã cắt ngưỡng.
    //
    // Trước đây câu này công bố **tổng** số cơ hội (43 trên máy Founder), rồi
    // thẻ brief nói 17 và khối nhiệm vụ nói "chưa có" — ba con số, một màn.
    // Nay Home chỉ nói *"N việc đáng làm nhất"*; 43 cơ hội vẫn còn nguyên ở
    // tab Cơ hội, chỉ thôi bị ném cả vào mặt người bán ở cửa trước.
    final top = TopActions.from(
      signalCount: opportunityCount,
      hasData: hasData,
    );
    final headline = switch (top.state) {
      TopActionsState.hasWork => l10n.homeHeadlineTopActions(top.count),
      TopActionsState.noneToday => l10n.homeHeadlineNoneToday,
      TopActionsState.notEnoughData => l10n.homeHeadlineNotEnoughData,
    };

    return Column(
      key: const Key('home-hero'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const TongtaiFoxMascot.avatar(size: 40),
            const SizedBox(width: TtSpace.x3),
            Expanded(
              child: Text(
                // No name: the product has no account (D-4), so it does not
                // know the seller's — and inventing one would be the first
                // thing it ever told them that was untrue.
                l10n.homeGreeting,
                style: TtType.body.copyWith(color: TtColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: TtSpace.x2),
        Text(
          headline,
          key: const Key('home-hero-headline'),
          style: TtType.h1.copyWith(
            color: TtColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: TtSpace.x3),
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('home-ask'),
            onTap: onAsk,
            borderRadius: BorderRadius.circular(TtRadius.full),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: TtButtonMetrics.height,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: TtSpace.x4,
                vertical: TtSpace.x3,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(TtRadius.full),
                border: Border.all(color: TtColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 18, color: TtColors.ai),
                  const SizedBox(width: TtSpace.x2),
                  Expanded(
                    child: Text(
                      l10n.homeAskHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TtType.body.copyWith(
                        color: TtColors.textSecondary,
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
          color: TtColors.ai,
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

/// Ô trống của Trang chủ.
///
/// ⚠️ Trước đây nó tự vẽ bằng `Color(0xFFE5E7EB)` và `borderRadius(8)` viết
/// thẳng — hai giá trị không ai sở hữu, và chúng lệch khỏi mọi ô trống khác
/// trong app. Nay đi qua Design System.
///
/// Vẫn là **empty state**, không phải *"chưa đủ dữ liệu"*: những chỗ gọi nó đều
/// đã nhìn (không có hành trình, không có bước nào chờ) và đang nói *"đã xét và
/// không có gì"*. Chỗ nào thật sự chưa xét được thì dùng [TtInsufficientData] —
/// gộp hai câu ấy là cách một màn im lặng biến thành lời trấn an sai.
class _EmptyBox extends StatelessWidget {
  const _EmptyBox(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(TtSpace.cardPadding),
    decoration: BoxDecoration(
      color: TtColors.surface,
      border: Border.all(color: TtColors.border),
      borderRadius: BorderRadius.circular(TtRadius.lg),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: TtType.body.copyWith(color: TtColors.textSecondary),
    ),
  );
}
