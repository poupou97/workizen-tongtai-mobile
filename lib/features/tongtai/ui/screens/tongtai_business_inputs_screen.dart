import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../core/screen_data_controller.dart';
import '../../core/tongtai_formatters.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../producer/business_input.dart';
import '../../producer/business_input_repository.dart';
import '../../providers/tongtai_context_provider.dart';
import '../../providers/tongtai_data_invalidation.dart';
import '../widgets/tongtai_screen_data.dart';
import 'tongtai_business_input_form_screen.dart';

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
  late final ScreenDataController<List<BusinessInput>> _data;

  BusinessInputRepository get _repository =>
      widget.repository ?? ref.read(businessInputRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _data = ScreenDataController<List<BusinessInput>>(
      () => _repository.loadAll(),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'inputs',
    )..load();
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
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        key: const Key('inputs-header'),
        title: Text(l10n.titleBusinessInputs),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('inputs-action-add'),
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: Text(l10n.inputAddTitle),
      ),
      body: ListenableBuilder(
        listenable: _data,
        builder: (context, _) => TongtaiScreenData<List<BusinessInput>>(
          prefix: 'inputs',
          state: _data.state,
          onRetry: _data.retry,
          builder: _body,
        ),
      ),
    );
  }

  Widget _body(BuildContext context, List<BusinessInput> inputs) {
    final l10n = context.l10n;
    final summary = BusinessInputSummary.from(inputs);
    return ListView(
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      children: [
        _CommitmentCard(summary: summary),
        const SizedBox(height: TongtaiDesignTokens.spacing4),
        if (inputs.isEmpty)
          Padding(
            key: const Key('inputs-empty'),
            padding: const EdgeInsets.symmetric(
              vertical: TongtaiDesignTokens.spacing6,
            ),
            child: Text(
              l10n.inputsEmpty,
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
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

/// Tổng cam kết hằng tháng **kèm phần chưa biết**.
class _CommitmentCard extends StatelessWidget {
  const _CommitmentCard({required this.summary});

  final BusinessInputSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      decoration: BoxDecoration(
        color: TongtaiDesignTokens.lightHover,
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.cardBorderRadius,
        ),
        border: Border.all(color: TongtaiDesignTokens.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.inputsCommitmentLabel,
            style: TongtaiDesignTokens.smallStyle.copyWith(
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing1),
          Text(
            TongtaiFormatters.vnd(summary.monthlyCommitment),
            key: const Key('inputs-summary-commitment'),
            style: TongtaiDesignTokens.heading2Style.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          Text(
            summary.isComplete
                ? l10n.inputsAllCounted
                : l10n.inputsUnknownCount(summary.unknownCount),
            key: const Key('inputs-summary-unknown'),
            style: TongtaiDesignTokens.captionStyle.copyWith(
              color: summary.isComplete
                  ? TongtaiDesignTokens.lightTextSecondary
                  : TongtaiDesignTokens.readableText(
                      TongtaiDesignTokens.warning,
                    ),
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
      margin: const EdgeInsets.only(bottom: TongtaiDesignTokens.spacing2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.cardBorderRadius,
        ),
        side: const BorderSide(color: TongtaiDesignTokens.lightBorder),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(input.name),
        subtitle: Text(
          '${l10n.inputKindName(input.kind.code)} · '
          '${l10n.inputCadenceName(input.cadence?.code)}',
          style: TongtaiDesignTokens.captionStyle.copyWith(
            color: TongtaiDesignTokens.lightTextSecondary,
          ),
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
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: monthly == null
                    ? TongtaiDesignTokens.lightTextSecondary
                    : TongtaiDesignTokens.lightTextPrimary,
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
