import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../action/business_action.dart';
import '../../agent/automation_card.dart';
import '../../agent/autonomy_settings.dart';
import '../../agent/business_brief.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../providers/tongtai_agentic_provider.dart';
import '../widgets/tongtai_automation_card.dart';

/// **Trải nghiệm #4 · Mức tự động** — WTM-306 (Epic WTM-302).
///
/// ## ⛔ Bảy việc không chọn được `Tự động`, và đó là CẤU TRÚC
///
/// Màn này **không** hiện một cảnh báo rồi vẫn cho bấm. Một vùng chỉ mời chọn
/// `Tự động` khi có ít nhất một việc được phép tự chạy, và những việc trong
/// danh sách cấm hiện thành một khối riêng *"Luôn hỏi bạn"* — nhìn thấy được,
/// không tắt được.
///
/// Đó là lớp thứ hai. Lớp thứ nhất nằm ở `AutonomySettings.resolve`, vì cấu
/// hình có thể tới từ một bản khôi phục của máy khác và bản khôi phục không đi
/// qua màn hình nào.
///
/// ## `Tự động` mang nhãn **Xem trước** (Task Order §9)
///
/// Chưa có runner chạy nền, nên bật `Tự động` hôm nay đổi **câu chuyện** chứ
/// chưa đổi **hành vi**. Nói thẳng điều đó ra còn hơn để người bán tin rằng có
/// thứ đang chạy sau lưng họ.
class TongtaiAutonomyScreen extends ConsumerWidget {
  const TongtaiAutonomyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(autonomySettingsProvider);

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(l10n.titleAutonomy),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('autonomy-list'),
          padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
          children: [
            Text(
              l10n.autonomySubtitle,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing4),
            for (final area in AutonomyArea.values) ...[
              _AreaCard(
                area: area,
                mode: settings.modeOf(area),
                onPick: (mode) => ref
                    .read(autonomySettingsProvider.notifier)
                    .setMode(area, mode),
              ),
              const SizedBox(height: TongtaiDesignTokens.spacing4),
            ],

            // Thẻ orchestration đọc **cùng** cấu hình ở trên, nên gạt một công
            // tắc là thấy ngay dòng APPROVAL đổi. Đó là cách chứng minh cho
            // người bán rằng công tắc thật sự nối vào cái gì.
            TongtaiAutomationCard(
              keyPrefix: 'autonomy-example',
              card: AutomationCard.forKind(
                BriefKind.customerAtRisk,
                settings: settings,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing5),
          ],
        ),
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({
    required this.area,
    required this.mode,
    required this.onPick,
  });

  final AutonomyArea area;
  final AutonomyMode mode;
  final ValueChanged<AutonomyMode> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final alwaysAsk = area.alwaysAsk;

    return Container(
      key: Key('autonomy-area-${area.code}'),
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusXl),
        border: Border.all(color: TongtaiDesignTokens.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tongtaiAutonomyAreaLabel(l10n, area),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing3),

          for (final option in const [
            AutonomyMode.suggest,
            AutonomyMode.confirm,
            AutonomyMode.auto,
          ])
            _ModeOption(
              area: area,
              mode: option,
              selected: mode == option,
              // ⛔ Cấu trúc, không phải cảnh báo: vùng không có gì tự chạy thì
              // ô `Tự động` KHÔNG bấm được.
              enabled: option != AutonomyMode.auto || area.offersAuto,
              onPick: onPick,
            ),

          if (!area.offersAuto) ...[
            const SizedBox(height: 4),
            Text(
              l10n.autonomyNoAuto,
              key: Key('autonomy-no-auto-${area.code}'),
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: TongtaiDesignTokens.neutralText,
              ),
            ),
          ],

          if (mode == AutonomyMode.auto) ...[
            const SizedBox(height: TongtaiDesignTokens.spacing3),
            _PreviewNotice(area: area),
          ],

          if (alwaysAsk.isNotEmpty) ...[
            const SizedBox(height: TongtaiDesignTokens.spacing4),
            _AlwaysAsk(area: area, actions: alwaysAsk),
          ],
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.area,
    required this.mode,
    required this.selected,
    required this.enabled,
    required this.onPick,
  });

  final AutonomyArea area;
  final AutonomyMode mode;
  final bool selected;
  final bool enabled;
  final ValueChanged<AutonomyMode> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = selected
        ? TongtaiDesignTokens.consumerBlueText
        : TongtaiDesignTokens.neutralText;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        key: Key('autonomy-${area.code}-${mode.code}'),
        onTap: enabled ? () => onPick(mode) : null,
        borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusLg),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: color,
              ),
              const SizedBox(width: TongtaiDesignTokens.spacing3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tongtaiAutonomyModeLabel(l10n, mode),
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: TongtaiDesignTokens.lightTextPrimary,
                          ),
                        ),
                        if (mode == AutonomyMode.auto) ...[
                          const SizedBox(width: 8),
                          _PreviewBadge(area: area),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tongtaiAutonomyModeBody(l10n, mode),
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: TongtaiDesignTokens.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge({required this.area});

  final AutonomyArea area;

  @override
  Widget build(BuildContext context) => Container(
    key: Key('autonomy-preview-${area.code}'),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: TongtaiDesignTokens.warning.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusFull),
    ),
    child: Text(
      context.l10n.autonomyPreviewBadge,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: TongtaiDesignTokens.inventoryOrangeText,
      ),
    ),
  );
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice({required this.area});

  final AutonomyArea area;

  @override
  Widget build(BuildContext context) => Container(
    key: Key('autonomy-preview-notice-${area.code}'),
    width: double.infinity,
    padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
    decoration: BoxDecoration(
      color: TongtaiDesignTokens.warning.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusLg),
    ),
    child: Text(
      context.l10n.autonomyPreviewBody,
      style: const TextStyle(
        fontSize: 12.5,
        height: 1.45,
        color: TongtaiDesignTokens.lightTextPrimary,
      ),
    ),
  );
}

/// ⛔ Khối **luôn hỏi bạn** — nhìn thấy được, không tắt được.
class _AlwaysAsk extends StatelessWidget {
  const _AlwaysAsk({required this.area, required this.actions});

  final AutonomyArea area;
  final List<BusinessActionType> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      key: Key('autonomy-always-ask-${area.code}'),
      width: double.infinity,
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
      decoration: BoxDecoration(
        color: TongtaiDesignTokens.lightHover,
        borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_outline,
                size: 16,
                color: TongtaiDesignTokens.neutralText,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.autonomyAlwaysAsk,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TongtaiDesignTokens.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.autonomyAlwaysAskBody,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          for (final action in actions)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '· ${tongtaiActionLabel(l10n, action)}',
                key: Key('autonomy-locked-${action.code}'),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: TongtaiDesignTokens.lightTextPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Nhãn (l10n, không đọc `.name` của enum) ────────────────────────────────

String tongtaiAutonomyAreaLabel(AppStrings l10n, AutonomyArea area) =>
    switch (area) {
      AutonomyArea.customerCare => l10n.autonomyAreaCustomerCare,
      AutonomyArea.inventory => l10n.autonomyAreaInventory,
      AutonomyArea.marketing => l10n.autonomyAreaMarketing,
    };

String tongtaiAutonomyModeLabel(AppStrings l10n, AutonomyMode mode) =>
    switch (mode) {
      AutonomyMode.off => l10n.autonomyModeSuggest,
      AutonomyMode.suggest => l10n.autonomyModeSuggest,
      AutonomyMode.confirm => l10n.autonomyModeConfirm,
      AutonomyMode.auto => l10n.autonomyModeAuto,
    };

String tongtaiAutonomyModeBody(AppStrings l10n, AutonomyMode mode) =>
    switch (mode) {
      AutonomyMode.off => l10n.autonomyModeSuggestBody,
      AutonomyMode.suggest => l10n.autonomyModeSuggestBody,
      AutonomyMode.confirm => l10n.autonomyModeConfirmBody,
      AutonomyMode.auto => l10n.autonomyModeAutoBody,
    };

/// Nhãn nghiệp vụ của một hành động — người bán không đọc `customer.send_message`.
String tongtaiActionLabel(
  AppStrings l10n,
  BusinessActionType type,
) => switch (type) {
  BusinessActionType.customerSendMessage => l10n.actLabelSendMessage,
  BusinessActionType.customerSendColdMessage => l10n.actLabelColdMessage,
  BusinessActionType.customerContactOutsideBook => l10n.actLabelContactOutside,
  BusinessActionType.customerMergeRecords => l10n.actLabelMergeCustomers,
  BusinessActionType.inventoryCreatePurchaseOrder => l10n.actLabelPurchaseOrder,
  BusinessActionType.inventoryOrderAboveLimit => l10n.actLabelOrderAboveLimit,
  BusinessActionType.productUpdatePrice => l10n.actLabelUpdatePrice,
  BusinessActionType.campaignPause => l10n.actLabelCampaignPause,
  BusinessActionType.campaignAdjustBudget => l10n.actLabelCampaignBudget,
  // Ba loại còn lại không thuộc vùng nào nên không tới được màn này. Vẫn
  // liệt kê tường minh: một `_ =>` sẽ nuốt luôn loại hành động TIẾP THEO
  // ai đó thêm vào, và loại đó có thể là loại cần nhãn nhất.
  BusinessActionType.storageBackupUpload => l10n.actLabelBackupUpload,
  BusinessActionType.ownerNotify => l10n.actLabelOwnerNotify,
  BusinessActionType.applyProposedChange ||
  BusinessActionType.financeTransferMoney ||
  BusinessActionType.overwriteSellerEnteredData => l10n.autonomyAlwaysAsk,
};
