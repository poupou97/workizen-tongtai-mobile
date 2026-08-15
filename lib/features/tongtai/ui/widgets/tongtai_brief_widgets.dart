import 'package:flutter/material.dart';

import '../../../../core/design/tt.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../agent/brief_inbox.dart';
import '../../agent/business_brief.dart';

/// Các mảnh giao diện dùng chung cho brief — WTM-304 (Epic WTM-302).
///
/// Sống ở `widgets/` chứ không nằm trong màn nào vì **hai** bề mặt hiển thị
/// cùng một việc: thẻ trên Home và danh sách trong màn Tổng Tài. Viết hai lần
/// thì hai chỗ sẽ nói khác nhau về cùng một khách vào ngày ai đó sửa một bên —
/// đúng họ lỗi P-27 mà repo này đã dọn bốn lần.

/// Mức khẩn của một việc, **dịch sang** thang ngữ nghĩa dùng chung.
///
/// ⚠️ Trước WTM-375 hàm dưới tự `switch` thẳng sang `TtColors` — tức là bảng
/// ánh xạ mức → màu **thứ hai**, song song với [TtStatus]. Hai bảng sẽ lệch
/// nhau đúng vào ngày ai đó sửa một bên (P-27/P-28), và lần này thứ tìm ra nó
/// là suite quét cả thư mục chứ không phải mắt người.
///
/// Nay đây chỉ còn là phép **dịch tên miền**: `BriefSeverity` là ngôn ngữ của
/// nghiệp vụ, `TtStatus` là ngôn ngữ của thị giác. Màu vẫn chỉ có một chủ.
TtStatus tongtaiBriefStatus(BriefSeverity severity) => switch (severity) {
  BriefSeverity.critical => TtStatus.danger,
  BriefSeverity.warning => TtStatus.warning,
  BriefSeverity.info => TtStatus.info,
};

/// Màu của một mức khẩn — đi qua [TtStatus], không tự chế thang màu thứ hai.
Color tongtaiBriefColor(BriefSeverity severity) =>
    tongtaiBriefStatus(severity).color;

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

// ⛔ WTM-348 — KHÔNG còn nhãn "Dữ liệu mẫu" trên từng việc.
//
// Founder chốt 2026-08-09: bản demo phải trông như thật. Hôm đó mới gỡ băng-rôn
// trên Trang chủ mà sót cái nhãn này, nên nó vẫn hiện trên từng thẻ brief.
//
// Nhãn nói về **dữ liệu**, không nói về trạng thái kỹ thuật, nên gỡ nó không
// phạm luật "cấm fake trạng thái engineering" (§40). Dấu vết vẫn còn nguyên ở
// chỗ đáng tin hơn một cái chip: bản ghi mang tiền tố `sample-`/`importJobId`,
// và "Xóa dữ liệu mẫu" vẫn xoá đúng chúng.

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
                color: TtColors.textSecondary,
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
              color: TtColors.textSecondary,
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
      borderRadius: BorderRadius.circular(TtRadius.lg),
      child: InkWell(
        key: Key('$keyPrefix-item-${item.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(TtRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(TtSpace.x4),
          decoration: BoxDecoration(
            border: Border.all(color: TtColors.border),
            borderRadius: BorderRadius.circular(TtRadius.lg),
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
                      color: TtColors.readableOn(color),
                    ),
                  ),
                  const SizedBox(width: TtSpace.x3),
                  Expanded(
                    child: Text(
                      item.headline,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: TtColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (reasons.isNotEmpty) ...[
                const SizedBox(height: TtSpace.x3),
                Text(l10n.briefWhyTitle, style: _sectionLabel),
                const SizedBox(height: 6),
                for (final reason in reasons) TongtaiBriefReason(text: reason),
              ],
              if (item.isActionable) ...[
                const SizedBox(height: TtSpace.x3),
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
                          color: TtColors.readableOn(color),
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
    color: TtColors.textSecondary,
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({super.key, required this.decision});

  final BriefDecision decision;

  @override
  Widget build(BuildContext context) {
    final color = switch (decision) {
      BriefDecision.pending => TtColors.info,
      BriefDecision.accepted => TtColors.success,
      // Người dùng ĐÃ bỏ qua — quyết định có rồi (WTM-431).
      BriefDecision.dismissed => TtColors.neutral,
      BriefDecision.postponed => TtColors.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TtRadius.full),
      ),
      child: Text(
        tongtaiBriefStatusLabel(context.l10n, decision),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: TtColors.readableOn(color),
        ),
      ),
    );
  }
}
