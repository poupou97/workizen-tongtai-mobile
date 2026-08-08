import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../agent/brief_inbox.dart';
import '../../agent/business_brief.dart';
import '../../navigation/tongtai_design_tokens.dart';

/// Các mảnh giao diện dùng chung cho brief — WTM-304 (Epic WTM-302).
///
/// Sống ở `widgets/` chứ không nằm trong màn nào vì **hai** bề mặt hiển thị
/// cùng một việc: thẻ trên Home và danh sách trong màn Tổng Tài. Viết hai lần
/// thì hai chỗ sẽ nói khác nhau về cùng một khách vào ngày ai đó sửa một bên —
/// đúng họ lỗi P-27 mà repo này đã dọn bốn lần.

/// Màu của một mức khẩn. Dùng bộ token có sẵn, không tự chế thang màu thứ hai.
Color tongtaiBriefColor(BriefSeverity severity) => switch (severity) {
  BriefSeverity.critical => TongtaiDesignTokens.error,
  BriefSeverity.warning => TongtaiDesignTokens.warning,
  BriefSeverity.info => TongtaiDesignTokens.info,
};

/// Biểu tượng theo **loại việc**, không theo mức khẩn.
///
/// Người bán nhận ra *"chuyện về khách"* nhanh hơn *"chuyện màu đỏ"*; mức khẩn
/// đã có màu và thứ tự lo phần đó.
IconData tongtaiBriefIcon(BriefKind kind) => switch (kind) {
  BriefKind.customerAtRisk => Icons.person_outline,
  BriefKind.stockRunningOut => Icons.inventory_2_outlined,
  BriefKind.marginTooThin => Icons.trending_down,
  BriefKind.businessSignal => Icons.insights_outlined,
};

String tongtaiBriefStatusLabel(AppStrings l10n, BriefDecision decision) =>
    switch (decision) {
      BriefDecision.pending => l10n.briefStatusPending,
      BriefDecision.accepted => l10n.briefStatusAccepted,
      BriefDecision.dismissed => l10n.briefStatusDismissed,
      BriefDecision.postponed => l10n.briefStatusPostponed,
    };

/// Hậu tố kebab-case cho key ổn định — **không** lấy từ `decision.name`, vốn là
/// camelCase và sẽ phá quy ước mà bộ quét key kiểm.
String tongtaiBriefStatusKey(BriefDecision decision) => switch (decision) {
  BriefDecision.pending => 'pending',
  BriefDecision.accepted => 'accepted',
  BriefDecision.dismissed => 'dismissed',
  BriefDecision.postponed => 'postponed',
};

/// Lời chào theo buổi — thứ đầu tiên người bán đọc.
///
/// Nhận [now] từ chỗ gọi thay vì tự đọc đồng hồ: một widget tự biết giờ là một
/// widget không test được lúc 3 giờ sáng.
String tongtaiBriefGreeting(AppStrings l10n, DateTime now) {
  if (now.hour < 11) return l10n.briefGreetingMorning;
  if (now.hour < 18) return l10n.briefGreetingAfternoon;
  return l10n.briefGreetingEvening;
}

/// Nhãn **dữ liệu mẫu**.
///
/// Founder đã một lần nhầm màn demo với dashboard thật (WTM-143). Bản vá lúc
/// đó là một banner ở màn hình; đây là nhãn đi **theo từng việc**, vì brief
/// trộn chung việc về dữ liệu mẫu và việc về dữ liệu thật trong một danh sách.
class TongtaiDemoBadge extends StatelessWidget {
  const TongtaiDemoBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: TongtaiDesignTokens.setupGray.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusFull),
    ),
    child: Text(
      context.l10n.briefDemoBadge,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: TongtaiDesignTokens.neutralText,
      ),
    ),
  );
}

/// Một dòng "vì sao" — chính là `detail` của một bằng chứng.
class TongtaiBriefReason extends StatelessWidget {
  const TongtaiBriefReason({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6, right: 8),
          child: SizedBox(
            width: 4,
            height: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: TongtaiDesignTokens.neutralText,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Thẻ đầy đủ của một việc — dùng trong màn Tổng Tài.
///
/// Trật tự trên thẻ là trật tự người bán cần: **chuyện gì** (to nhất) → **vì
/// sao** → **nên làm**. Không phải trật tự của model.
class TongtaiBriefTile extends StatelessWidget {
  const TongtaiBriefTile({
    super.key,
    required this.item,
    required this.keyPrefix,
    this.decision,
    this.onTap,
    this.maxReasons = 3,
  });

  final BriefItem item;

  /// Tiền tố key ổn định của màn đang hiển thị (`agent`, `home`…).
  final String keyPrefix;

  final BriefDecision? decision;
  final VoidCallback? onTap;
  final int maxReasons;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = tongtaiBriefColor(item.severity);
    final reasons = [
      for (final e in item.evidence)
        if (e.detail != null) e.detail!,
    ].take(maxReasons);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusXl),
      child: InkWell(
        key: Key('$keyPrefix-item-${item.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusXl),
        child: Container(
          padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
          decoration: BoxDecoration(
            border: Border.all(color: TongtaiDesignTokens.lightBorder),
            borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusXl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      tongtaiBriefIcon(item.kind),
                      size: 20,
                      color: TongtaiDesignTokens.readableText(color),
                    ),
                  ),
                  const SizedBox(width: TongtaiDesignTokens.spacing3),
                  Expanded(
                    child: Text(
                      item.headline,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: TongtaiDesignTokens.lightTextPrimary,
                      ),
                    ),
                  ),
                  if (item.isDemo) ...[
                    const SizedBox(width: 8),
                    const TongtaiDemoBadge(),
                  ],
                ],
              ),
              if (reasons.isNotEmpty) ...[
                const SizedBox(height: TongtaiDesignTokens.spacing3),
                Text(l10n.briefWhyTitle, style: _sectionLabel),
                const SizedBox(height: 6),
                for (final reason in reasons) TongtaiBriefReason(text: reason),
              ],
              if (item.isActionable) ...[
                const SizedBox(height: TongtaiDesignTokens.spacing3),
                Text(l10n.briefSuggestTitle, style: _sectionLabel),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.suggestion,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TongtaiDesignTokens.readableText(color),
                        ),
                      ),
                    ),
                    if (decision != null)
                      _StatusChip(
                        key: Key(
                          '$keyPrefix-status-${tongtaiBriefStatusKey(decision!)}'
                          '-${item.id}',
                        ),
                        decision: decision!,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static const TextStyle _sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: TongtaiDesignTokens.neutralText,
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({super.key, required this.decision});

  final BriefDecision decision;

  @override
  Widget build(BuildContext context) {
    final color = switch (decision) {
      BriefDecision.pending => TongtaiDesignTokens.info,
      BriefDecision.accepted => TongtaiDesignTokens.success,
      BriefDecision.dismissed => TongtaiDesignTokens.neutral,
      BriefDecision.postponed => TongtaiDesignTokens.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusFull),
      ),
      child: Text(
        tongtaiBriefStatusLabel(context.l10n, decision),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: TongtaiDesignTokens.readableText(color),
        ),
      ),
    );
  }
}
