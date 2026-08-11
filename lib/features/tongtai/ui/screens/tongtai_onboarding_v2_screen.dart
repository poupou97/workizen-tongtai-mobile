import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../core/screen_data_controller.dart';
import '../../journey/business_goal.dart';
import '../../journey/journey_controller.dart';
import '../../journey/journey_planner.dart';
import '../../../../core/design/tt.dart';
import '../../agent/business_brief.dart';
import '../../core/tongtai_formatters.dart';
import '../../onboarding/analysis_pipeline.dart';
import '../../onboarding/first_insight.dart';
import '../../onboarding/first_plan.dart';
import '../../onboarding/onboarding_conversation.dart';
import '../../onboarding/onboarding_flow.dart';
import '../../providers/tongtai_data_invalidation.dart';
import '../../providers/tongtai_journey_provider.dart';
import '../../providers/tongtai_onboarding_v2_provider.dart';
import '../../providers/tongtai_profile_provider.dart';
import '../../providers/tongtai_sample_provider.dart';
import '../widgets/tongtai_mascot_pose.dart';
import '../widgets/tongtai_screen_data.dart' show showTongtaiFailure;
import 'tongtai_customer_list_screen.dart';
import 'tongtai_customer_risk_screen.dart';
import 'tongtai_finance_screen.dart';
import 'tongtai_goals_screen.dart';
import 'tongtai_import_screen.dart';
import 'tongtai_inventory_screen.dart';
import 'tongtai_journey_screen.dart';
import 'tongtai_opportunity_feed_screen.dart';
import 'tongtai_reports_screen.dart';

/// **Onboarding V2** — Epic WTM-349.
///
/// Bảy chặng trong một `Scaffold`, không phải bảy route: đường đi là một giá
/// trị ([OnboardingFlow]), nên "quay lại" là một phép trừ và không có chồng
/// route nào để lệch khỏi trạng thái.
///
/// ## Cái màn này KHÔNG làm
///
/// * Không gọi AI. Không mạng. Không khoá.
/// * Không hỏi tài khoản — [D-4] còn hiệu lực (§16 directive).
/// * Không tự tính lại kết luận nào: nó đọc [FirstInsight] mà pipeline trả về.
/// * Không `Future.delayed` để "cho có cảm giác đang chạy".
class TongtaiOnboardingV2Screen extends ConsumerStatefulWidget {
  const TongtaiOnboardingV2Screen({super.key, required this.onDone});

  /// Gọi khi người bán rời onboarding, dù rời bằng đường nào.
  final void Function(OnboardingOutcome outcome) onDone;

  @override
  ConsumerState<TongtaiOnboardingV2Screen> createState() =>
      _TongtaiOnboardingV2ScreenState();
}

/// Thứ onboarding bàn giao cho Trang chủ — WTM-357.
@immutable
class OnboardingOutcome {
  const OnboardingOutcome({this.insight, this.plan});

  static const OnboardingOutcome none = OnboardingOutcome();

  final FirstInsight? insight;
  final FirstPlan? plan;
}

class _TongtaiOnboardingV2ScreenState
    extends ConsumerState<TongtaiOnboardingV2Screen> {
  OnboardingFlow _flow = const OnboardingFlow();

  final List<AnalysisProgress> _progress = [];
  AnalysisRun? _run;
  bool _analysing = false;

  final List<OnboardingGoal> _goals = [];
  FirstPlan? _plan;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final stage = _flow.stage;
    return Scaffold(
      backgroundColor: TtColors.surfaceSecondary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TtSpace.x5),
          child: switch (stage) {
            null => const SizedBox.shrink(),
            OnboardingStage.welcome => _Welcome(onStart: _next),
            OnboardingStage.profile => _Profile(
              conversation: _flow.conversation,
              onAnswer: (code) =>
                  setState(() => _flow = _flow.answerProfile(code)),
              onNext: _profileNext,
              onBack: _flow.conversation.stepIndex == 0 ? null : _profileBack,
              onSkipAll: _skipProfile,
            ),
            OnboardingStage.dataStart => _DataStart(
              preparing: _flow.preparing,
              busy: _saving,
              onChoose: _chooseData,
              onBack: _back,
            ),
            OnboardingStage.analysis => _Analysis(
              progress: _progress,
              done: _run != null,
              onContinue: _next,
            ),
            OnboardingStage.insight => _Insight(
              insight: _run?.insight,
              onContinue: _next,
            ),
            OnboardingStage.goal => _Goal(
              selected: _goals,
              onToggle: _toggleGoal,
              onNext: _goalNext,
              onBack: _back,
            ),
            OnboardingStage.plan => _Plan(
              plan: _plan,
              saving: _saving,
              onFinish: _finish,
              onOpen: _openDestination,
            ),
          },
        ),
      ),
    );
  }

  void _next() => setState(() => _flow = _flow.next());
  void _back() => setState(() => _flow = _flow.back());

  // ── Hồ sơ ────────────────────────────────────────────────────────────────

  void _profileNext() {
    final advanced = _flow.conversation.next();
    setState(() {
      _flow = advanced.isComplete
          ? _flow.copyWith(conversation: advanced).next()
          : _flow.copyWith(conversation: advanced);
    });
  }

  /// Bỏ qua cả năm câu, đi thẳng tới cửa dữ liệu.
  ///
  /// Người vội vẫn phải đi qua cửa dữ liệu — đó không phải một bước thủ tục mà
  /// là **chỗ rẽ** quyết định họ nhận được gì. Bỏ qua nó sẽ thả họ vào một ứng
  /// dụng trống, tức là đúng vấn đề V1 mà Epic này sinh ra để sửa.
  ///
  /// Cùng đường mã với trả lời-rỗng: bỏ qua là *trả lời không gì cả*, không
  /// phải một nhánh riêng có thể hành xử khác (S1 AC4).
  void _skipProfile() => setState(() {
    var c = _flow.conversation;
    while (!c.isComplete) {
      c = c.next();
    }
    _flow = _flow.copyWith(conversation: c).next();
  });

  void _profileBack() => setState(
    () => _flow = _flow.copyWith(conversation: _flow.conversation.back()),
  );

  // ── Cửa dữ liệu ──────────────────────────────────────────────────────────

  Future<void> _chooseData(DataStartChoice choice) async {
    setState(() => _flow = _flow.chooseDataStart(choice));

    switch (choice) {
      case DataStartChoice.csv:
        // Tái dùng nguyên màn nhập đã chạy. Huỷ giữa chừng thì quay về đây,
        // không kẹt: người bán vẫn đang đứng ở cửa dữ liệu.
        await Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const TongtaiImportScreen()),
        );
        if (!mounted) return;
      case DataStartChoice.sample:
        setState(() => _saving = true);
        final failure = await runTongtaiAction(
          () => ref.read(sampleBusinessSeederProvider).seed(),
          screen: 'onboarding_v2',
        );
        if (!mounted) return;
        setState(() => _saving = false);
        if (failure != null) {
          showTongtaiFailure(context, failure);
          return;
        }
        invalidateBusinessDataProviders(ref);
      case DataStartChoice.none:
        // Đường B — không phân tích gì, và đó là điểm mấu chốt của nó.
        _next();
        return;
    }

    _next();
    unawaitedAnalysis();
  }

  /// Chạy pipeline. Tách khỏi [_chooseData] để đọc được rằng phân tích **chỉ**
  /// xảy ra trên đường có dữ liệu.
  void unawaitedAnalysis() {
    if (_analysing || _flow.path?.analysesData != true) return;
    _analysing = true;
    ref
        .read(onboardingAnalysisPipelineProvider)
        .run(
          now: DateTime.now(),
          onDone: (run) {
            if (!mounted) return;
            setState(() => _run = run);
          },
        )
        .listen((p) {
          if (!mounted) return;
          setState(() => _progress.add(p));
        });
  }

  // ── Mục tiêu ─────────────────────────────────────────────────────────────

  void _toggleGoal(OnboardingGoal goal) {
    setState(() {
      if (_goals.remove(goal)) return;
      // "Chỉ khám phá" loại trừ mọi thứ khác — chọn nó cùng một mục tiêu khác
      // là hai câu trả lời mâu thuẫn.
      if (goal == OnboardingGoal.justExplore) {
        _goals
          ..clear()
          ..add(goal);
        return;
      }
      _goals.remove(OnboardingGoal.justExplore);
      if (_goals.length >= kMaxOnboardingGoals) return;
      _goals.add(goal);
    });
  }

  void _goalNext() {
    setState(() {
      _plan = const FirstPlanBuilder().build(
        goals: _goals,
        insight:
            _run?.insight ??
            const FirstInsight.insufficient(kInsightNotAnalysed),
      );
      _flow = _flow.next();
    });
  }

  /// Mở chỗ làm của một việc.
  ///
  /// ⚠️ Dogfood máy thật (WTM-360) bắt được: phụ đề hứa *"mỗi việc mở thẳng
  /// vào chỗ làm"* và dòng hành động tô cam **trông bấm được**, nhưng không có
  /// `onTap` nào. Đó là CTA chết ở dạng khó thấy nhất — nó không hỏng, nó chỉ
  /// im lặng. Không test nào bắt được vì test chỉ kiểm `destination` **có mặt**
  /// trong danh sách đóng, không kiểm màn hình có DÙNG nó không.
  Future<void> _openDestination(PlanDestination destination) => Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => screenFor(destination)));

  // ── Kết thúc ─────────────────────────────────────────────────────────────

  Future<void> _finish() async {
    setState(() => _saving = true);

    if (_flow.conversation.profile.isNotEmpty) {
      final failure = await runTongtaiAction(
        () => ref
            .read(businessProfileRepositoryProvider)
            .save(_flow.conversation.profile),
        screen: 'onboarding_v2',
      );
      if (!mounted) return;
      if (failure != null) showTongtaiFailure(context, failure);
      ref.invalidate(businessProfileProvider);
    }

    for (final goal in _goals) {
      final archetype = goal.archetype;
      if (archetype == null) continue;
      final template = kTongtaiGoalTemplates.firstWhere(
        (t) => t.type == archetype,
      );
      final now = DateTime.now();
      final failure = await runTongtaiAction(
        () => ref
            .read(businessGoalRepositoryProvider)
            .upsert(
              BusinessGoal(
                id:
                    '$_kOnboardingGoalPrefix${goal.code}-'
                    '${now.microsecondsSinceEpoch}',
                name: template.nameVi,
                type: archetype,
                targetAmount: template.suggestedTarget,
                growthTarget: template.suggestedGrowthTarget,
                achievedAmount: 0,
                growthAchieved: 0,
                startDate: now,
                endDate: now.add(Duration(days: template.suggestedDays)),
                createdAt: now,
                updatedAt: now,
              ),
            ),
        screen: 'onboarding_v2',
      );
      if (!mounted) return;
      if (failure != null) showTongtaiFailure(context, failure);
    }

    // ⚠️ Dogfood (WTM-360): Trang chủ hiện *"Việc hôm nay — chưa có nhiệm vụ
    // nào"* ngay dưới một brief liệt kê ba việc. Hai khối cạnh nhau, một nói
    // có việc, một nói không.
    //
    // Nguyên nhân không phải lời văn: khối "Việc hôm nay" đọc **hành trình**,
    // và onboarding mới chỉ tạo *mục tiêu*. Sửa bằng cách đổi chữ sẽ giấu đi
    // đúng thứ cần sửa — một mục tiêu chưa sinh ra kế hoạch thì chưa phải một
    // mục tiêu, nó là một điều ước.
    await _startJourneyForFirstGoal();

    if (!mounted) return;
    invalidateBusinessDataProviders(ref);
    widget.onDone(OnboardingOutcome(insight: _run?.insight, plan: _plan));
  }
}

// ── Hành trình cho mục tiêu vừa chọn ─────────────────────────────────────────

extension _StartJourney on _TongtaiOnboardingV2ScreenState {
  Future<void> _startJourneyForFirstGoal() async {
    final goal = _goals.firstWhere(
      (g) => g.createsGoal,
      orElse: () => OnboardingGoal.justExplore,
    );
    if (!goal.createsGoal) return;

    final goals = await ref.read(businessGoalRepositoryProvider).loadAll();
    final mine = goals.where((g) => g.id.startsWith(_kOnboardingGoalPrefix));
    if (mine.isEmpty) return;

    // Số đếm lấy từ chính lượt phân tích vừa chạy — không đọc lại repository,
    // vì hai lần đọc quanh một lần ghi là hai câu trả lời có thể khác nhau.
    final run = _run;
    await runTongtaiAction(
      () => JourneyController(ref.read(journeyRepositoryProvider)).startJourney(
        JourneyPlanInput(
          goal: mine.last,
          profile: _flow.conversation.profile,
          productCount: run?.countOf(AnalysisStage.products) ?? 0,
          customerCount: run?.countOf(AnalysisStage.customers) ?? 0,
          orderCount: run?.countOf(AnalysisStage.orders) ?? 0,
        ),
        journeyId: '$_kOnboardingGoalPrefix${mine.last.id}',
      ),
      screen: 'onboarding_v2',
    );
  }
}

/// Màn hình cho một đích của kế hoạch.
///
/// `switch` **vét cạn** trên enum, nên thêm một [PlanDestination] mà quên nối
/// màn là lỗi biên dịch — không phải một nút im lặng. Đó chính là khoảng trống
/// mà dogfood WTM-360 tìm ra: đích được khai đầy đủ, nhưng không ai dùng nó.
Widget screenFor(PlanDestination destination) => switch (destination) {
  PlanDestination.home => const TongtaiGoalsScreen(),
  PlanDestination.inventory => const TongtaiInventoryScreen(),
  // Màn cảnh báo tồn nhận `catalog` do màn Kho sở hữu. Dựng một catalog thứ
  // hai ở đây sẽ tạo đúng thứ P-27 cấm: hai chủ cho một khái niệm. Kho là chỗ
  // việc thật sự xảy ra, và nó hiện cảnh báo ngay đầu màn.
  PlanDestination.stockAlerts => const TongtaiInventoryScreen(),
  PlanDestination.customerList => const TongtaiCustomerListScreen(),
  PlanDestination.customerRisk => const TongtaiCustomerRiskScreen(),
  PlanDestination.opportunity => const TongtaiOpportunityFeedScreen(),
  PlanDestination.finance => const TongtaiFinanceScreen(),
  PlanDestination.reports => const TongtaiReportsScreen(),
  PlanDestination.goals => const TongtaiGoalsScreen(),
  PlanDestination.journey => const TongtaiJourneyScreen(),
  PlanDestination.importData => const TongtaiImportScreen(),
};

/// Tiền tố id mục tiêu do onboarding tạo.
///
/// Phân biệt với mục tiêu `sample-` của bộ dữ liệu mẫu: *"Xoá dữ liệu mẫu"*
/// chỉ được xoá phần mẫu, và tiền tố là thứ làm điều đó đúng theo cấu trúc
/// chứ không theo trí nhớ.
const String _kOnboardingGoalPrefix = 'onboarding-';

// ── Chặng 1 · Gặp Tổng Tài ───────────────────────────────────────────────────

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      key: const Key('onboarding-v2-welcome'),
      children: [
        const SizedBox(height: TtSpace.x6),
        // §17: linh vật xuất hiện khi AI **tự giới thiệu**. Đây đúng là lúc đó
        // — và là một trong sáu chỗ duy nhất nó được phép có mặt.
        Center(
          child: TongtaiMascotPose(
            MascotPose.greeting,
            height: 160,
            semanticsLabel: l10n.obV2MascotGreeting,
          ),
        ),
        const SizedBox(height: TtSpace.x5),
        Text(l10n.obV2WelcomeTitle, style: TtType.h1),
        const SizedBox(height: TtSpace.x3),
        Text(
          l10n.obV2WelcomeBody,
          style: TtType.body.copyWith(color: TtColors.textPrimary, height: 1.6),
        ),
        const SizedBox(height: TtSpace.x8),
        _Value(
          icon: Icons.trending_up,
          color: TtColors.success,
          title: l10n.obV2ValueOpportunityTitle,
          body: l10n.obV2ValueOpportunityBody,
        ),
        _Value(
          icon: Icons.warning_amber_rounded,
          color: TtColors.brand,
          title: l10n.obV2ValueRiskTitle,
          body: l10n.obV2ValueRiskBody,
        ),
        _Value(
          icon: Icons.auto_awesome,
          color: TtColors.ai,
          title: l10n.obV2ValueActionTitle,
          body: l10n.obV2ValueActionBody,
        ),
        const SizedBox(height: TtSpace.x8),
        // ⛔ KHÔNG có "Đã có tài khoản? Đăng nhập" ở đây (§16 directive).
        // Tài khoản mâu thuẫn với D-4 / Local First, và một dòng chữ dưới cái
        // nút không phải chỗ để đưa ra quyết định kiến trúc đó.
        TtPrimaryButton(
          key: const Key('onboarding-v2-start'),
          label: l10n.obStart,
          onPressed: onStart,
        ),
      ],
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: TtSpace.x5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: TtSpace.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TtType.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: TtColors.textPrimary,
                ),
              ),
              Text(
                body,
                style: TtType.caption.copyWith(
                  color: TtColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ── Chặng 2 · Hồ sơ ──────────────────────────────────────────────────────────

class _Profile extends StatelessWidget {
  const _Profile({
    required this.conversation,
    required this.onAnswer,
    required this.onNext,
    required this.onBack,
    required this.onSkipAll,
  });

  final OnboardingConversation conversation;
  final ValueChanged<String> onAnswer;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkipAll;

  String _label(AppStrings l10n, String stepId, String code) =>
      switch (stepId) {
        'business_type' => l10n.profileBusinessType(code),
        'trade' => l10n.profileTrade(code),
        'size' => l10n.profileSize(code),
        'channels' => l10n.profileChannel(code),
        _ => l10n.profileSeasonality(code),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final step = conversation.currentStep!;
    final selected = conversation.selectedCodes;
    return ListView(
      key: const Key('onboarding-v2-profile'),
      children: [
        Text(
          '${l10n.obProgress} ${conversation.stepIndex + 1}/'
          '${kOnboardingSteps.length}',
          key: const Key('onboarding-v2-profile-progress'),
          style: TtType.caption.copyWith(color: TtColors.textSecondary),
        ),
        const SizedBox(height: TtSpace.x3),
        Text(
          l10n.obQuestion(step.id),
          style: TtType.h1.copyWith(color: TtColors.textPrimary),
        ),
        const SizedBox(height: TtSpace.x5),
        Wrap(
          spacing: TtSpace.x2,
          runSpacing: TtSpace.x2,
          children: [
            for (var i = 0; i < step.optionCodes.length; i++)
              ChoiceChip(
                key: Key('onboarding-v2-option-$i'),
                label: Text(_label(l10n, step.id, step.optionCodes[i])),
                selected: selected.contains(step.optionCodes[i]),
                onSelected: (_) => onAnswer(step.optionCodes[i]),
              ),
          ],
        ),
        const SizedBox(height: TtSpace.x6),
        Row(
          children: [
            if (onBack != null)
              TextButton(
                key: const Key('onboarding-v2-profile-back'),
                onPressed: onBack,
                child: Text(l10n.obBack),
              ),
            const Spacer(),
            TtPrimaryButton(
              key: const Key('onboarding-v2-profile-next'),
              label: l10n.obNext,
              onPressed: onNext,
              // Trong `Row`: không giãn, nếu không `width: double.infinity`
              // gặp ràng buộc ngang vô hạn và cả màn không dựng được.
              expand: false,
            ),
          ],
        ),
        Center(
          child: TextButton(
            key: const Key('onboarding-v2-profile-skip-all'),
            onPressed: onSkipAll,
            child: Text(l10n.obV2SkipProfile),
          ),
        ),
      ],
    );
  }
}

// ── Chặng 3 · Đưa dữ liệu ────────────────────────────────────────────────────

class _DataStart extends StatelessWidget {
  const _DataStart({
    required this.preparing,
    required this.busy,
    required this.onChoose,
    required this.onBack,
  });

  final bool preparing;
  final bool busy;
  final ValueChanged<DataStartChoice> onChoose;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      key: const Key('onboarding-v2-data'),
      children: [
        Text(
          l10n.obV2DataTitle,
          style: TtType.h1.copyWith(color: TtColors.textPrimary),
        ),
        const SizedBox(height: TtSpace.x2),
        Text(
          l10n.obV2DataBody,
          style: TtType.caption.copyWith(color: TtColors.textSecondary),
        ),
        const SizedBox(height: TtSpace.x6),
        _DataDoor(
          testKey: 'onboarding-v2-data-csv',
          icon: Icons.description_outlined,
          color: TtColors.info,
          title: l10n.obV2DataCsvTitle,
          body: l10n.obV2DataCsvBody,
          onTap: busy ? null : () => onChoose(DataStartChoice.csv),
        ),
        _DataDoor(
          testKey: 'onboarding-v2-data-sample',
          icon: Icons.auto_awesome,
          color: TtColors.ai,
          title: l10n.obV2DataSampleTitle,
          body: l10n.obV2DataSampleBody,
          onTap: busy ? null : () => onChoose(DataStartChoice.sample),
        ),
        _DataDoor(
          testKey: 'onboarding-v2-data-none',
          icon: Icons.lightbulb_outline,
          color: TtColors.success,
          title: l10n.obV2DataNoneTitle,
          body: l10n.obV2DataNoneBody,
          highlighted: preparing,
          onTap: busy ? null : () => onChoose(DataStartChoice.none),
        ),
        const SizedBox(height: TtSpace.x4),
        // ⛔ Sàn thương mại điện tử và Google Drive KHÔNG có nút ở đây: chưa có
        // connector nào tồn tại, và một nút mang tên Shopee mà không kết nối
        // được Shopee là lời nói dối đắt nhất một màn onboarding có thể kể.
        // Một dòng chữ tĩnh thì trung thực; một logo bấm được thì không.
        Text(
          l10n.obV2DataConnectorsLater,
          key: const Key('onboarding-v2-data-connectors-note'),
          style: TtType.caption.copyWith(color: TtColors.textSecondary),
        ),
        const SizedBox(height: TtSpace.x5),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('onboarding-v2-data-back'),
            onPressed: busy ? null : onBack,
            child: Text(l10n.obBack),
          ),
        ),
      ],
    );
  }
}

class _DataDoor extends StatelessWidget {
  const _DataDoor({
    required this.testKey,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.onTap,
    this.highlighted = false,
  });

  final String testKey;
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Card(
    key: Key(testKey),
    margin: const EdgeInsets.only(bottom: TtSpace.x3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(TtRadius.md),
      side: BorderSide(
        color: highlighted ? color : TtColors.border,
        width: highlighted ? 2 : 1,
      ),
    ),
    child: ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TtType.body.copyWith(
          fontWeight: FontWeight.w600,
          color: TtColors.textPrimary,
        ),
      ),
      subtitle: Text(
        body,
        style: TtType.caption.copyWith(color: TtColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

// ── Chặng 4 · Đang hiểu doanh nghiệp ─────────────────────────────────────────

class _Analysis extends StatelessWidget {
  const _Analysis({
    required this.progress,
    required this.done,
    required this.onContinue,
  });

  final List<AnalysisProgress> progress;
  final bool done;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      key: const Key('onboarding-v2-analysis'),
      children: [
        const SizedBox(height: TtSpace.x4),
        Center(
          child: TongtaiMascotPose(
            MascotPose.working,
            height: 130,
            semanticsLabel: l10n.obV2MascotWorking,
          ),
        ),
        const SizedBox(height: TtSpace.x4),
        Text(
          l10n.obV2AnalysisTitle,
          style: TtType.h1.copyWith(color: TtColors.textPrimary),
        ),
        const SizedBox(height: TtSpace.x2),
        Text(
          l10n.obV2AnalysisBody,
          style: TtType.caption.copyWith(color: TtColors.textSecondary),
        ),
        const SizedBox(height: TtSpace.x6),
        // Mỗi dòng chỉ tồn tại vì chặng của nó ĐÃ CHẠY XONG. Danh sách này
        // không có phần "sẽ chạy" — không có chỗ nào để một con số xuất hiện
        // trước việc sinh ra nó.
        for (final p in progress)
          Padding(
            key: Key('onboarding-v2-stage-${p.stage.code}'),
            padding: const EdgeInsets.only(bottom: TtSpace.x3),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: TtColors.success,
                  size: 20,
                ),
                const SizedBox(width: TtSpace.x3),
                Expanded(
                  child: Text(
                    l10n.obV2AnalysisStage(p.stage.code, p.count),
                    style: TtType.body.copyWith(color: TtColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: TtSpace.x6),
        if (done)
          TtPrimaryButton(
            key: const Key('onboarding-v2-analysis-continue'),
            label: l10n.obV2Continue,
            onPressed: onContinue,
          ),
      ],
    );
  }
}

// ── Chặng 5 · First Insight ──────────────────────────────────────────────────

class _Insight extends StatelessWidget {
  const _Insight({required this.insight, required this.onContinue});

  final FirstInsight? insight;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = insight;
    // ⭐ Ba trạng thái, ba câu khác nhau. Gộp "chưa đủ dữ liệu" với "đã xét,
    // không có gì" là cách một màn im lặng thành lời trấn an sai.
    final (title, body) = switch (result) {
      null || FirstInsight(isInsufficient: true) => (
        l10n.obV2InsightInsufficientTitle,
        l10n.obV2InsightInsufficientBody,
      ),
      FirstInsight(isQuiet: true) => (
        l10n.obV2InsightQuietTitle,
        l10n.obV2InsightQuietBody,
      ),
      _ => (l10n.obV2InsightTitle, l10n.obV2InsightBody),
    };

    // ⭐ Tư thế đổi theo **kết luận**, không theo màn: trình bày một phát hiện,
    // bình thản khi không có gì gấp, và ngồi im khi chưa có gì để xem. Một con
    // cáo hớn hở trên màn "chưa đủ dữ liệu" là hình ảnh nói dối trước cả chữ.
    final (pose, poseLabel) = switch (result) {
      null || FirstInsight(isInsufficient: true) => (
        MascotPose.idle,
        l10n.obV2MascotIdle,
      ),
      FirstInsight(isQuiet: true) => (MascotPose.calm, l10n.obV2MascotCalm),
      _ => (MascotPose.explaining, l10n.obV2MascotExplaining),
    };

    return ListView(
      key: const Key('onboarding-v2-insight'),
      children: [
        const SizedBox(height: TtSpace.x3),
        Center(
          child: TongtaiMascotPose(
            pose,
            height: 120,
            semanticsLabel: poseLabel,
          ),
        ),
        const SizedBox(height: TtSpace.x3),
        Text(
          title,
          key: const Key('onboarding-v2-insight-title'),
          style: TtType.h1.copyWith(color: TtColors.textPrimary),
        ),
        const SizedBox(height: TtSpace.x2),
        Text(
          body,
          style: TtType.caption.copyWith(
            color: TtColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: TtSpace.x5),
        if (result != null)
          for (final f in result.findings)
            _FindingCard(
              key: Key('onboarding-v2-finding-${f.subjectId}'),
              finding: f,
            ),
        if (result != null && !result.snapshot.isEmpty) ...[
          const SizedBox(height: TtSpace.x3),
          _Snapshot(snapshot: result.snapshot),
        ],
        const SizedBox(height: TtSpace.x6),
        TtPrimaryButton(
          key: const Key('onboarding-v2-insight-continue'),
          label: l10n.obV2Continue,
          onPressed: onContinue,
        ),
      ],
    );
  }
}

class _FindingCard extends StatelessWidget {
  const _FindingCard({super.key, required this.finding});

  final FirstFinding finding;

  @override
  Widget build(BuildContext context) {
    // Mức khẩn đi qua **một** bảng ánh xạ của Design System. Trước đây màn này
    // có `switch` màu riêng — hai bảng ánh xạ sẽ lệch nhau đúng vào ngày ai đó
    // sửa một bên (P-27/P-28).
    final status = switch (finding.severity) {
      BriefSeverity.critical => TtStatus.danger,
      BriefSeverity.warning => TtStatus.warning,
      BriefSeverity.info => TtStatus.info,
    };
    final color = status.color;
    // ⚠️ Dogfood WTM-360: bốn thẻ trên máy thật trông **giống hệt nhau** —
    // "đã hết hàng" và "khách chưa quay lại" chỉ khác ở một sắc độ viền mà mắt
    // không tách được. Màu được đọc TRƯỚC chữ (bài học WTM-340: chip tím chứ
    // không xanh lá), nên mức khẩn phải là một vạch ĐẶC.
    //
    // Hai cách làm sai đã thử trước khi ra hình này, cả hai đều chỉ ném lúc
    // *vẽ* chứ không lúc biên dịch:
    //   · `Row(stretch)` trần trong `ListView` — chiều cao không có biên;
    //   · viền bốn cạnh khác màu kèm `borderRadius` — Flutter cấm.
    // `IntrinsicHeight` cho hàng một chiều cao có biên, `ClipRRect` cho góc
    // bo mà không cần viền không đồng nhất.
    return Container(
      key: const Key('onboarding-v2-finding-card'),
      margin: const EdgeInsets.only(bottom: TtSpace.x3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TtRadius.md),
        border: Border.all(color: TtColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              key: const Key('onboarding-v2-finding-severity'),
              width: 4,
              color: color,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(TtSpace.x4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      finding.headline,
                      style: TtType.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: TtColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: TtSpace.x1),
                    // Lý do đọc thẳng từ bằng chứng của luật — không viết lại.
                    // Hai danh sách lý do sẽ lệch nhau đúng vào ngày ai đó sửa
                    // một bên.
                    Text(
                      finding.reason,
                      style: TtType.caption.copyWith(
                        color: TtColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Snapshot extends StatelessWidget {
  const _Snapshot({required this.snapshot});

  final BusinessSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      key: const Key('onboarding-v2-snapshot'),
      spacing: TtSpace.x3,
      runSpacing: TtSpace.x3,
      children: [
        if (snapshot.revenue case final r?)
          _Tile(
            label: l10n.obV2SnapshotRevenue,
            value: TongtaiFormatters.vnd(r),
          ),
        _Tile(label: l10n.obV2SnapshotOrders, value: '${snapshot.orders}'),
        // ⭐ Lời `null` ⇒ nói "chưa tính được", KHÔNG hiện một con số đoán.
        _Tile(
          key: const Key('onboarding-v2-snapshot-profit'),
          label: l10n.obV2SnapshotProfit,
          value: switch (snapshot.profit) {
            final p? => TongtaiFormatters.vnd(p),
            _ => l10n.obV2ProfitUnknown,
          },
          muted: snapshot.profit == null,
        ),
        if (snapshot.inventoryValue case final v?)
          _Tile(
            label: l10n.obV2SnapshotInventory,
            value: TongtaiFormatters.vnd(v),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.label,
    required this.value,
    this.muted = false,
  });

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: TtSpace.x4,
      vertical: TtSpace.x3,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(TtRadius.md),
      border: Border.all(color: TtColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TtType.caption.copyWith(color: TtColors.textSecondary),
        ),
        Text(
          value,
          style: TtType.body.copyWith(
            fontWeight: FontWeight.w600,
            color: muted ? TtColors.textSecondary : TtColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}

// ── Chặng 6 · Mục tiêu ───────────────────────────────────────────────────────

class _Goal extends StatelessWidget {
  const _Goal({
    required this.selected,
    required this.onToggle,
    required this.onNext,
    required this.onBack,
  });

  final List<OnboardingGoal> selected;
  final ValueChanged<OnboardingGoal> onToggle;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      key: const Key('onboarding-v2-goal'),
      children: [
        Text(
          l10n.obV2GoalTitle,
          style: TtType.h1.copyWith(color: TtColors.textPrimary),
        ),
        const SizedBox(height: TtSpace.x2),
        Text(
          l10n.obV2GoalBody,
          style: TtType.caption.copyWith(color: TtColors.textSecondary),
        ),
        const SizedBox(height: TtSpace.x5),
        Wrap(
          spacing: TtSpace.x2,
          runSpacing: TtSpace.x2,
          children: [
            for (final goal in OnboardingGoal.values)
              ChoiceChip(
                key: Key('onboarding-v2-goal-${goal.code}'),
                label: Text(l10n.obV2Goal(goal.code)),
                selected: selected.contains(goal),
                onSelected: (_) => onToggle(goal),
              ),
          ],
        ),
        const SizedBox(height: TtSpace.x3),
        Text(
          l10n.obV2GoalLimit,
          style: TtType.caption.copyWith(color: TtColors.textSecondary),
        ),
        const SizedBox(height: TtSpace.x6),
        Row(
          children: [
            TextButton(
              key: const Key('onboarding-v2-goal-back'),
              onPressed: onBack,
              child: Text(l10n.obBack),
            ),
            const Spacer(),
            TtPrimaryButton(
              key: const Key('onboarding-v2-goal-next'),
              label: l10n.obNext,
              onPressed: onNext,
              // Trong `Row`: không giãn, nếu không `width: double.infinity`
              // gặp ràng buộc ngang vô hạn và cả màn không dựng được.
              expand: false,
            ),
          ],
        ),
      ],
    );
  }
}

// ── Chặng 7 · Kế hoạch đầu tiên ──────────────────────────────────────────────

class _Plan extends StatelessWidget {
  const _Plan({
    required this.plan,
    required this.saving,
    required this.onFinish,
    required this.onOpen,
  });

  final FirstPlan? plan;
  final bool saving;
  final VoidCallback onFinish;
  final ValueChanged<PlanDestination> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actions = plan?.actions ?? const <PlanAction>[];
    return ListView(
      key: const Key('onboarding-v2-plan'),
      children: [
        Center(
          child: TongtaiMascotPose(
            MascotPose.planning,
            height: 110,
            semanticsLabel: l10n.obV2MascotPlanning,
          ),
        ),
        const SizedBox(height: TtSpace.x3),
        Text(
          l10n.obV2PlanTitle,
          style: TtType.h1.copyWith(color: TtColors.textPrimary),
        ),
        const SizedBox(height: TtSpace.x2),
        Text(
          l10n.obV2PlanBody,
          style: TtType.caption.copyWith(color: TtColors.textSecondary),
        ),
        const SizedBox(height: TtSpace.x5),
        for (final a in actions)
          Card(
            key: Key('onboarding-v2-plan-${a.priority}'),
            margin: const EdgeInsets.only(bottom: TtSpace.x3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TtRadius.md),
              side: const BorderSide(color: TtColors.border),
            ),
            // Cả thẻ là vùng chạm, không chỉ dòng chữ cam: một dòng chữ trông
            // bấm được mà chỉ bấm trúng khi nhắm đúng vài chục pixel thì vẫn là
            // một lời hứa hỏng.
            child: InkWell(
              key: Key('onboarding-v2-plan-open-${a.priority}'),
              onTap: () => onOpen(a.destination),
              child: Padding(
                padding: const EdgeInsets.all(TtSpace.x4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${a.priority}. ${a.problem}',
                      style: TtType.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: TtColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: TtSpace.x1),
                    Text(
                      '${l10n.obV2PlanEvidence}: ${a.evidence}',
                      style: TtType.caption.copyWith(
                        color: TtColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: TtSpace.x2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.action,
                            style: TtType.body.copyWith(color: TtColors.brand),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: TtColors.brand),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: TtSpace.x6),
        TtPrimaryButton(
          key: const Key('onboarding-v2-finish'),
          label: l10n.obV2PlanCta,
          onPressed: saving ? null : onFinish,
        ),
      ],
    );
  }
}
