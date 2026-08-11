import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../core/screen_data_controller.dart';
import '../../core/tongtai_formatters.dart';
import '../../producer/business_input.dart';
import '../../producer/business_input_repository.dart';
import '../../providers/tongtai_context_provider.dart';
import '../../providers/tongtai_data_invalidation.dart';
import '../widgets/tongtai_screen_data.dart';
import 'tongtai_business_input_form_screen.dart';
import '../../journey/journey_metric.dart';
import '../../journey/journey_node.dart';
import '../../providers/tongtai_journey_provider.dart';
import 'tongtai_journey_screen.dart';

/// Danh sách **nguồn đầu vào** của doanh nghiệp (WTM-234 / ADR-TON-023).
///
/// Producer không phải danh bạ nhà cung cấp: nó quản lý **toàn bộ đầu vào**, và
/// nhà cung cấp hàng hoá chỉ là một loại. Dogfood Workizen làm rõ chỗ trống —
/// đầu vào của một doanh nghiệp AI-first (AI provider, hạ tầng, công cụ, người)
/// hôm nay rơi hết vào `FinanceCategory.other`, nên **không capability nào trả
/// lời được câu cơ bản nhất: "tháng này tôi cam kết trả bao nhiêu?"**
///
/// Màn này trả lời câu đó, và trả lời **kèm phần nó không biết**: tổng cam kết
/// luôn đi cùng số nguồn chưa đủ dữ liệu. Một tổng không tự khai mình thiếu gì
/// sẽ được đọc như một tổng đầy đủ — cùng kỷ luật `null ≠ 0` của repo này, áp
/// cho một phép cộng thay vì một trường.
class TongtaiBusinessInputsScreen extends ConsumerStatefulWidget {
  const TongtaiBusinessInputsScreen({
    super.key,
    this.repository,
    this.clock,
    this.idFactory,
  });

  /// Nguồn dữ liệu; `null` = lấy từ provider (chế độ thật).
  final BusinessInputRepository? repository;

  final DateTime Function()? clock;
  final String Function()? idFactory;

  @override
  ConsumerState<TongtaiBusinessInputsScreen> createState() =>
      _TongtaiBusinessInputsScreenState();
}

class _TongtaiBusinessInputsScreenState
    extends ConsumerState<TongtaiBusinessInputsScreen> {
  late final ScreenDataController<_InputsData> _data;

  BusinessInputRepository get _repository =>
      widget.repository ?? ref.read(businessInputRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _data = ScreenDataController<_InputsData>(
      _read,
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'inputs',
    )..load();
  }

  /// Nguồn đầu vào **và** bước hành trình đang chờ về chúng, đọc cùng một lần.
  ///
  /// Bước hành trình đọc từ Journey — Single Source of Truth (WTM-223) — chứ
  /// không phải một trạng thái thứ hai màn này tự giữ.
  Future<_InputsData> _read() async {
    final inputs = await _repository.loadAll();
    return (inputs: inputs, step: await _pendingJourneyStep());
  }

  /// Bước hành trình còn dang dở nói về chi phí đầu vào, nếu có (WTM-235).
  Future<JourneyNode?> _pendingJourneyStep() async {
    // Đọc thẳng provider, KHÔNG rẽ nhánh "chế độ test". Một nhánh như vậy làm
    // test chạy đường khác đường của người dùng — đúng lỗi WTM-190, nơi test
    // tự dựng một bundle nhỏ hơn bundle thật rồi xanh suốt trong khi bản trên
    // máy thiếu hai dataset. Test muốn kịch bản nào thì override provider.
    final journey = await ref.read(activeJourneyProvider.future);
    if (journey == null) return null;
    for (final node in journey.nodes) {
      if (node.state == JourneyNodeState.done) continue;
      final destination = journeyNodeDestination(node);
      if (destination == JourneyDestination.inputs) return node;
    }
    return null;
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  Future<void> _openForm({BusinessInput? input}) async {
    final result = await Navigator.of(context).push<BusinessInput>(
      MaterialPageRoute(
        builder: (_) => TongtaiBusinessInputFormScreen(
          input: input,
          clock: widget.clock,
          idFactory: widget.idFactory,
        ),
      ),
    );
    if (!mounted || result == null) return;
    // Một nguồn người bán vừa gõ mà lưu hỏng trong im lặng là đúng lỗi WTM-148
    // ở phía ghi.
    final failure = await runTongtaiAction(
      () => _repository.upsert(result),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'inputs',
    );
    if (!mounted) return;
    if (failure != null) {
      showTongtaiFailure(
        context,
        failure,
        onRetry: () => _openForm(input: input),
      );
      return;
    }
    await _data.refresh();
    if (mounted) invalidateBusinessDataProviders(ref);
  }

  Future<void> _delete(BusinessInput input) async {
    final failure = await runTongtaiAction(
      () => _repository.delete(input.id),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'inputs',
    );
    if (!mounted) return;
    if (failure != null) {
      showTongtaiFailure(context, failure, onRetry: () => _delete(input));
      return;
    }
    await _data.refresh();
    if (mounted) invalidateBusinessDataProviders(ref);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        key: const Key('inputs-header'),
        title: Text(l10n.titleBusinessInputs),
        elevation: 0,
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('inputs-action-add'),
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: Text(l10n.inputAddTitle),
      ),
      body: ListenableBuilder(
        listenable: _data,
        builder: (context, _) => TongtaiScreenData<_InputsData>(
          prefix: 'inputs',
          state: _data.state,
          onRetry: _data.retry,
          builder: _body,
        ),
      ),
    );
  }

  Widget _body(BuildContext context, _InputsData data) {
    final l10n = context.l10n;
    final inputs = data.inputs;
    final summary = BusinessInputSummary.from(inputs);
    return ListView(
      padding: const EdgeInsets.all(TtSpace.x4),
      children: [
        _CommitmentCard(summary: summary),
        // Nhịp 5 của Business Loop: khai xong một nguồn thì người bán phải
        // biết việc tiếp theo — và biết NGAY TẠI CHỖ họ vừa làm việc, không
        // phải đi tìm. Đọc từ Journey (SSoT), thường trực, không Snackbar.
        if (data.step case final step?) ...[
          const SizedBox(height: TtSpace.x3),
          _JourneyStepCard(step: step),
        ],
        const SizedBox(height: TtSpace.x4),
        if (inputs.isEmpty)
          Padding(
            key: const Key('inputs-empty'),
            padding: const EdgeInsets.symmetric(vertical: TtSpace.x6),
            child: Text(
              l10n.inputsEmpty,
              textAlign: TextAlign.center,
              style: TtType.body.copyWith(color: TtColors.textSecondary),
            ),
          )
        else
          for (final input in inputs)
            _InputTile(
              input: input,
              onTap: () => _openForm(input: input),
              onDelete: () => _delete(input),
            ),
        // Chỗ cho FAB, để mục cuối không nằm dưới nút.
        const SizedBox(height: 88),
      ],
    );
  }
}

/// Những gì màn này cần trong một lần đọc: các nguồn, và bước hành trình đang
/// chờ về chúng.
typedef _InputsData = ({List<BusinessInput> inputs, JourneyNode? step});

/// Bước hành trình về chi phí đầu vào, đọc từ Journey (WTM-235).
///
/// Thường trực, không phải Snackbar: *"Không dùng Snackbar như điểm kết thúc
/// của Business Flow"* (Founder 2026-08-02). Và chỉ **mời**, không tự chuyển
/// màn — người bán giữ quyền quyết định.
class _JourneyStepCard extends StatelessWidget {
  const _JourneyStepCard({required this.step});

  final JourneyNode step;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      key: const Key('inputs-journey-step'),
      width: double.infinity,
      padding: const EdgeInsets.all(TtSpace.x3),
      decoration: BoxDecoration(
        color: TtColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(TtRadius.md),
        border: Border.all(color: TtColors.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.inputsJourneyStepTitle,
            style: TtType.caption.copyWith(
              color: TtColors.successOnLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TtSpace.x1),
          Text(
            step.title,
            style: TtType.body.copyWith(color: TtColors.textPrimary),
          ),
          const SizedBox(height: TtSpace.x2),
          OutlinedButton.icon(
            key: const Key('inputs-open-journey'),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const TongtaiJourneyScreen()),
            ),
            icon: const Icon(Icons.route_outlined),
            label: Text(l10n.oppOpenJourney),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tổng cam kết hằng tháng **kèm phần chưa biết**.
class _CommitmentCard extends StatelessWidget {
  const _CommitmentCard({required this.summary});

  final BusinessInputSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TtSpace.x4),
      decoration: BoxDecoration(
        color: TtColors.surfaceTertiary,
        borderRadius: BorderRadius.circular(TtRadius.md),
        border: Border.all(color: TtColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.inputsCommitmentLabel,
            style: TtType.body.copyWith(color: TtColors.textSecondary),
          ),
          const SizedBox(height: TtSpace.x1),
          Text(
            TongtaiFormatters.vnd(summary.monthlyCommitment),
            key: const Key('inputs-summary-commitment'),
            style: TtType.h1.copyWith(
              color: TtColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TtSpace.x2),
          Text(
            summary.isComplete
                ? l10n.inputsAllCounted
                : l10n.inputsUnknownCount(summary.unknownCount),
            key: const Key('inputs-summary-unknown'),
            style: TtType.caption.copyWith(
              color: summary.isComplete
                  ? TtColors.textSecondary
                  : TtColors.readableOn(TtColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputTile extends StatelessWidget {
  const _InputTile({
    required this.input,
    required this.onTap,
    required this.onDelete,
  });

  final BusinessInput input;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final monthly = input.monthlyCommitment;
    return Card(
      key: Key('inputs-item-${input.id}'),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: TtSpace.x2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TtRadius.md),
        side: const BorderSide(color: TtColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(input.name),
        subtitle: Text(
          '${l10n.inputKindName(input.kind.code)} · '
          '${l10n.inputCadenceName(input.cadence?.code)}',
          style: TtType.caption.copyWith(color: TtColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              // `null` = nguồn này KHÔNG góp vào cam kết (chưa đủ dữ liệu hoặc
              // trả theo mức dùng). Hiện "0 ₫" ở đây sẽ nói nó miễn phí.
              monthly == null
                  ? l10n.inputNotCounted
                  : TongtaiFormatters.vnd(monthly),
              key: Key('inputs-item-${input.id}-monthly'),
              style: TtType.body.copyWith(
                color: monthly == null
                    ? TtColors.textSecondary
                    : TtColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              key: Key('inputs-item-${input.id}-delete'),
              tooltip: l10n.inputDelete,
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
