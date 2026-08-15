import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../capability/customer_capability.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../core/screen_data_controller.dart';
import '../../core/screen_state.dart';
import '../../predictive/customer_risk_rule.dart';
import '../../predictive/rule_twin.dart';
import '../../providers/tongtai_consumer_provider.dart';
import '../../providers/tongtai_predictive_provider.dart';
import '../widgets/tongtai_screen_data.dart';

/// **Customer Risk screen** (WTM-161 · ADR-TON-016) — "which customers am I
/// about to lose?", answered by the deterministic [CustomerRiskRule] twin.
///
/// **One data path** (ADR-TON-015): every number on screen comes from the
/// single [customerRiskProvider] result — the screen re-derives nothing, holds
/// no clock (each day-count is the twin's own `recencyDays`, measured at the
/// context's instant) and never fabricates a zero. When the twin refuses to
/// answer, the screen says so and quotes the reasons instead of drawing an
/// assessment of zeros (Testing Bible P-03: *no data* must be distinguishable
/// from *could not compute*).
///
/// **Privacy join** (D-7 / ADR-TON-005): [CustomerRiskEntry] carries customer
/// **ids** only — no name, phone or email ever travels with the assessment.
/// The seller still needs to know *who*, so this screen — and only this screen —
/// joins those ids back to names through `customerRepositoryProvider`. The join
/// lives at the very edge of the system: the twin, the prompt block and any
/// telemetry-shaped string upstream stay PII-free by construction.
///
/// **AI never acts** (ADR-TON-016): the recommended actions are *suggestions*
/// rendered as text. Nothing here sends a message, applies a discount or
/// schedules a follow-up — the seller decides and acts in their own channel.
class TongtaiCustomerRiskScreen extends ConsumerStatefulWidget {
  const TongtaiCustomerRiskScreen({super.key});

  @override
  ConsumerState<TongtaiCustomerRiskScreen> createState() =>
      _TongtaiCustomerRiskScreenState();
}

class _TongtaiCustomerRiskScreenState
    extends ConsumerState<TongtaiCustomerRiskScreen> {
  /// customer id → display name, the ONLY place PII meets the assessment.
  ///
  /// Read from the same `customerRepositoryProvider` Home, Consumer and the
  /// customer list read, so a name shown here can never disagree with the name
  /// shown there.
  Map<String, String> _names = const <String, String>{};

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  /// Through `runTongtaiAction` (WTM-172): the risk assessment itself already
  /// goes through the shared seam, but this name lookup did not — an
  /// `await …loadAll()` with nobody watching. A failed read left `_names`
  /// empty, and an empty name map does not look like an error: it looks like a
  /// list of customers whose names are simply missing. The assessment beside
  /// them would still be rendered, which is the worst version of this bug.
  Future<void> _loadNames() async {
    Map<String, String>? loaded;
    final failure = await runTongtaiAction(
      () async {
        final customers = await ref.read(customerRepositoryProvider).loadAll();
        loaded = {for (final c in customers) c.id: c.name};
      },
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'risk',
    );
    if (!mounted) return;
    if (failure != null) {
      showTongtaiFailure(context, failure, onRetry: _loadNames);
      return;
    }
    setState(() => _names = loaded ?? const <String, String>{});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final risk = ref.watch(customerRiskProvider);

    return Scaffold(
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        title: Text(l10n.titleCustomerRisk),
        elevation: 0,
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
      ),
      body: SafeArea(
        // Through the shared seam (WTM-148). A failed load is NOT "no risk" —
        // it is "could not compute", and it now renders as a retryable failure
        // rather than as a refusal the twin never made.
        child: TongtaiAsyncScreenData<RuleTwinResult<CustomerRiskAssessment>>(
          prefix: 'risk',
          async: risk,
          onRetry: () async => ref.invalidate(customerRiskProvider),
          // The twin's only refusal today is an empty directory
          // (ReasonCode.noCustomers) — that is the *empty* state, a fact about
          // the business, not a computation that failed.
          isEmpty: (twin) =>
              twin.reasonCodes.contains(ReasonCode.noCustomers) ||
              (twin.result?.entries.isEmpty ?? false),
          emptyBuilder: (_) => const _RiskEmpty(),
          // Any OTHER refusal is "not enough data", WITH its reasons. The
          // empty-directory refusal is handled above and must not also match
          // here — a business with no customers is not a computation that
          // could not be done.
          insufficiencyOf: (context, twin) =>
              twin.result == null &&
                  !twin.reasonCodes.contains(ReasonCode.noCustomers)
              ? TongtaiInsufficiency(
                  title: context.l10n.riskNoData,
                  body: context.l10n.riskEmptyBody,
                  reasons: [
                    for (final reason in twin.reasonCodes)
                      reason.label(context.l10n.languageCode),
                  ],
                )
              : null,
          builder: (context, twin) => _body(twin),
        ),
      ),
    );
  }

  Widget _body(RuleTwinResult<CustomerRiskAssessment> twin) {
    // Non-null by construction: a refusing twin is routed to the shared
    // insufficient/empty states above.
    final assessment = twin.result!;

    // index 0 is the summary + provenance header; the rest are the ranked
    // entries, highest risk first (the twin's own total order).
    return ListView.separated(
      padding: const EdgeInsets.all(TtSpace.x4),
      itemCount: assessment.entries.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: TtSpace.x3),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _RiskHeader(twin: twin, assessment: assessment);
        }
        final entry = assessment.entries[index - 1];
        return _RiskRow(entry: entry, name: _names[entry.customerId]);
      },
    );
  }
}

// ── Stage presentation (l10n + stable keys + colour) ────────────────────────

/// User-facing label for a lifecycle [stage].
///
/// The wording lives in [AppStrings], not in `stage.labelVi` — that Vietnamese
/// label belongs to the AI prompt block and reading it from `ui/` would hard-wire
/// one language (P0 §2 lock, ADR-TON-007).
String tongtaiRiskStageLabel(AppStrings l10n, CustomerLifecycleStage stage) =>
    switch (stage) {
      CustomerLifecycleStage.neverPurchased => l10n.riskStageNeverPurchased,
      CustomerLifecycleStage.active => l10n.riskStageActive,
      CustomerLifecycleStage.cooling => l10n.riskStageCooling,
      CustomerLifecycleStage.atRisk => l10n.riskStageAtRisk,
      CustomerLifecycleStage.churned => l10n.riskStageChurned,
    };

/// Kebab-case key suffix for a [stage] — `risk-summary-<suffix>` (ADR-TON-015
/// §3 Stable Test IDs). Never derived from `stage.name`, which is camelCase and
/// would break the convention the key scan enforces.
String tongtaiRiskStageKey(CustomerLifecycleStage stage) => switch (stage) {
  CustomerLifecycleStage.neverPurchased => 'never-purchased',
  CustomerLifecycleStage.active => 'active',
  CustomerLifecycleStage.cooling => 'cooling',
  CustomerLifecycleStage.atRisk => 'at-risk',
  CustomerLifecycleStage.churned => 'churned',
};

/// Semantic colour of a [stage] — the same ladder the rule scores on, so the
/// colour can never contradict the number next to it.
Color tongtaiRiskStageColor(CustomerLifecycleStage stage) =>
    tongtaiRiskStageTone(stage).color;

/// **Vai ngữ nghĩa** của một [stage] (WTM-425). `tongtaiRiskStageColor` nay chỉ
/// chuyển tiếp về đây — một thang, một chủ, không thể lệch nhau.
///
/// ⭐ `neverPurchased` là **`neutral`, không phải `unknown`**: *chưa mua bao
/// giờ* là một sự thật đã biết chắc, không phải thiếu dữ liệu.
TtStatus tongtaiRiskStageTone(CustomerLifecycleStage stage) => switch (stage) {
  CustomerLifecycleStage.neverPurchased => TtStatus.neutral,
  CustomerLifecycleStage.active => TtStatus.success,
  CustomerLifecycleStage.cooling => TtStatus.info,
  CustomerLifecycleStage.atRisk => TtStatus.warning,
  CustomerLifecycleStage.churned => TtStatus.danger,
};

// ── Header: summary band + provenance + why ─────────────────────────────────

class _RiskHeader extends StatelessWidget {
  const _RiskHeader({required this.twin, required this.assessment});

  final RuleTwinResult<CustomerRiskAssessment> twin;
  final CustomerRiskAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.customersAtRisk(assessment.atRiskCount),
          style: TtType.h2.copyWith(color: TtColors.textPrimary),
        ),
        const SizedBox(height: TtSpace.x3),
        // Summary band — one tile per lifecycle stage (mutually exclusive, so
        // the tiles sum to the number of rows below: Summary Count == Visible
        // Records) plus the overlapping win-back count.
        Wrap(
          spacing: TtSpace.x2,
          runSpacing: TtSpace.x2,
          children: [
            for (final stage in CustomerLifecycleStage.values)
              _SummaryStat(
                statKey: Key('risk-summary-${tongtaiRiskStageKey(stage)}'),
                count: assessment.stage(stage),
                label: tongtaiRiskStageLabel(l10n, stage),
                color: tongtaiRiskStageColor(stage),
              ),
            _SummaryStat(
              statKey: const Key('risk-summary-win-back'),
              count: assessment.winBackCount,
              label: l10n.riskWinBack,
              color: TtColors.ai,
            ),
          ],
        ),
        const SizedBox(height: TtSpace.x3),
        // Provenance — this screen is arithmetic, not a guess: the seller can
        // see it needs no AI, no network and no key (ADR-TON-016).
        Container(
          key: const Key('risk-confidence'),
          padding: const EdgeInsets.symmetric(
            horizontal: TtSpace.x3,
            vertical: TtSpace.x2,
          ),
          decoration: BoxDecoration(
            color: TtColors.surfaceTertiary,
            borderRadius: BorderRadius.circular(TtRadius.full),
            border: Border.all(color: TtColors.border),
          ),
          child: Wrap(
            spacing: TtSpace.x2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(
                Icons.calculate_outlined,
                size: 16,
                color: TtColors.textSecondary,
              ),
              Text(
                l10n.forecastRuleBased,
                style: TtType.caption.copyWith(
                  color: TtColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${l10n.forecastConfidence}: '
                '${twin.confidence.label(l10n.languageCode)}',
                style: TtType.caption.copyWith(color: TtColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: TtSpace.x3),
        // WTM-280 — màn này xếp hạng khách theo rủi ro rồi gợi ý liên hệ /
        // ưu đãi. Đó là phán đoán về người thật, nên cùng câu miễn trừ với
        // màn dự báo: số là ước tính, quyết định là của người bán.
        Text(
          l10n.estimateDisclaimer,
          key: const Key('risk-estimate-disclaimer'),
          style: TtType.caption.copyWith(
            color: TtColors.textSecondary,
            height: 1.4,
          ),
        ),
        if (twin.reasonCodes.isNotEmpty) ...[
          const SizedBox(height: TtSpace.x3),
          Text(
            l10n.forecastWhy,
            style: TtType.body.copyWith(
              color: TtColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TtSpace.x2),
          _ReasonCodes(
            reasonCodes: twin.reasonCodes,
            color: TtColors.textSecondary,
          ),
        ],
        // Partial answers must carry their caveat, never silently pass as a
        // full assessment (RuleTwinResult contract).
        if (twin.sufficiency == DataSufficiency.partial) ...[
          const SizedBox(height: TtSpace.x2),
          Text(
            l10n.riskEmptyBody,
            key: const Key('risk-partial-note'),
            style: TtType.caption.copyWith(color: TtColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.statKey,
    required this.count,
    required this.label,
    required this.color,
  });

  final Key statKey;
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: statKey,
      padding: const EdgeInsets.symmetric(
        horizontal: TtSpace.x3,
        vertical: TtSpace.x2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(TtRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TtType.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TtType.caption.copyWith(
              color: TtColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── One customer ────────────────────────────────────────────────────────────

class _RiskRow extends StatelessWidget {
  const _RiskRow({required this.entry, required this.name});

  final CustomerRiskEntry entry;

  /// Joined from the directory; `null` only when the customer disappeared
  /// between the assessment and the name load — the id is then shown rather
  /// than an invented placeholder.
  final String? name;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = tongtaiRiskStageColor(entry.stage);
    final recencyDays = entry.recencyDays;
    return Container(
      key: Key('risk-item-${entry.customerId}'),
      padding: const EdgeInsets.all(TtSpace.x3),
      decoration: BoxDecoration(
        color: TtColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(TtRadius.md),
        border: Border.all(color: TtColors.border),
        boxShadow: TtElevation.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name ?? entry.customerId,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TtType.bodyLarge.copyWith(
              color: TtColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TtSpace.x2),
          Wrap(
            spacing: TtSpace.x2,
            runSpacing: TtSpace.x1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Pill(
                label: tongtaiRiskStageLabel(l10n, entry.stage),
                tone: tongtaiRiskStageTone(entry.stage),
              ),
              if (entry.winBackCandidate)
                _Pill(label: l10n.riskWinBack, tone: TtStatus.ai),
              Text(
                // The score is the twin's, rounded for display only — the
                // ranking above is still the twin's exact order.
                l10n.riskScoreLabel(entry.riskScore.round()),
                style: TtType.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              // Only when recency is known: a customer who never bought has no
              // "days since", and 0 would be a lie.
              if (recencyDays != null)
                Text(
                  l10n.daysSincePurchase(recencyDays),
                  style: TtType.caption.copyWith(color: TtColors.textSecondary),
                ),
            ],
          ),
          if (entry.reasonCodes.isNotEmpty) ...[
            const SizedBox(height: TtSpace.x2),
            _ReasonCodes(
              reasonCodes: entry.reasonCodes,
              color: TtColors.textSecondary,
            ),
          ],
          if (entry.winBackCandidate) ...[
            const SizedBox(height: TtSpace.x3),
            _RecommendedActions(customerId: entry.customerId),
          ],
        ],
      ),
    );
  }
}

/// The twin's reason codes, rendered as localized text — the SAME codes the AI
/// explanation layer quotes, so screen and prose can never tell two stories.
class _ReasonCodes extends StatelessWidget {
  const _ReasonCodes({required this.reasonCodes, required this.color});

  final List<ReasonCode> reasonCodes;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final code = context.l10n.languageCode;
    return Wrap(
      spacing: TtSpace.x2,
      runSpacing: TtSpace.x1,
      children: [
        for (final reason in reasonCodes)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: TtSpace.x2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: TtColors.surfaceTertiary,
              borderRadius: BorderRadius.circular(TtRadius.full),
            ),
            child: Text(
              reason.label(code),
              style: TtType.caption.copyWith(color: color),
            ),
          ),
      ],
    );
  }
}

/// What a seller could do about a win-back candidate.
///
/// **Suggestions only.** Deliberately not buttons: nothing in Tổng Tài sends a
/// message, applies a discount or contacts a customer on its own — AI and
/// automation explain and recommend, the human acts (ADR-TON-016). The stable
/// keys exist so a test can prove the advice is shown for exactly the customers
/// the rule flagged.
class _RecommendedActions extends StatelessWidget {
  const _RecommendedActions({required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.riskRecommendedActions,
          style: TtType.caption.copyWith(
            color: TtColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: TtSpace.x1),
        _Suggestion(
          suggestionKey: Key('risk-action-contact-$customerId'),
          icon: Icons.chat_bubble_outline,
          label: l10n.riskActionContact,
        ),
        _Suggestion(
          suggestionKey: Key('risk-action-offer-$customerId'),
          icon: Icons.card_giftcard_outlined,
          label: l10n.riskActionOffer,
        ),
      ],
    );
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({
    required this.suggestionKey,
    required this.icon,
    required this.label,
  });

  final Key suggestionKey;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: suggestionKey,
      padding: const EdgeInsets.only(top: TtSpace.x1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: TtColors.ai),
          const SizedBox(width: TtSpace.x2),
          Expanded(
            child: Text(
              label,
              style: TtType.caption.copyWith(color: TtColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.tone});

  final String label;

  /// **Vai**, không phải màu (WTM-425): giai đoạn rủi ro, hoặc `ai` cho dải
  /// "nên kéo lại" do Tổng Tài đề xuất.
  final TtStatus tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TtSpace.x2, vertical: 2),
      decoration: BoxDecoration(
        color: tone.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TtRadius.full),
        border: Border.all(color: tone.color),
      ),
      child: Text(
        label,
        style: TtType.caption.copyWith(
          color: TtColors.readableOn(tone.color),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Honest non-answers ──────────────────────────────────────────────────────

/// Nobody in the directory yet — a fact about the business, not a failure.
class _RiskEmpty extends StatelessWidget {
  const _RiskEmpty();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _CenteredNotice(
      noticeKey: const Key('risk-empty'),
      icon: Icons.people_outline,
      color: TtColors.unknown,
      title: l10n.riskEmpty,
      body: l10n.riskEmptyBody,
    );
  }
}

class _CenteredNotice extends StatelessWidget {
  const _CenteredNotice({
    required this.noticeKey,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final Key noticeKey;
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: noticeKey,
      padding: const EdgeInsets.all(TtSpace.x6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: TtSpace.x3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TtType.bodyLarge.copyWith(
              color: TtColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TtSpace.x1),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TtType.body.copyWith(color: TtColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
