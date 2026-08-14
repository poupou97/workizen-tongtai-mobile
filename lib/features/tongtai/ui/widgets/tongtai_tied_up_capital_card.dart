import 'package:flutter/material.dart';

import '../../../../core/design/tt.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../core/tongtai_formatters.dart';
import '../../inventory/slow_moving_capital.dart';

/// **Vốn đang nằm trong hàng chậm bán** — WTM-411 (concept-1 `cp3`).
///
/// ## Vì sao thẻ này có một cái nút
///
/// `ANALYSIS.md` điều 2: *"`cp3`, `cp7`, `cp8` **không thẻ nào chỉ để đọc**"* —
/// đó là câu trả lời của concept cho khoảng cách *thấy 19 / làm 5* của app. Một
/// con số tiền đang nằm mà không dẫn tới danh sách để làm gì đó thì chỉ là một
/// nỗi lo mới.
///
/// ## ⛔ Nói ra phần CHƯA TÍNH ĐƯỢC
///
/// `tiedUpAmount` chỉ cộng mặt hàng **có** giá vốn. Nếu còn mặt hàng chưa khai,
/// thẻ phải nói — vì con số đang **thấp hơn sự thật**, và một tổng thiếu mà
/// trông như đủ khiến người bán yên tâm nhầm.
///
/// Câu chữ mời khai, **không trách**: mặt hàng thiếu giá vốn là điều *app* chưa
/// hỏi, không phải lỗi người bán.
///
/// ## Màu
///
/// Hổ phách = **CHÚ Ý**, không phải đỏ. Tiền nằm trong hàng chậm bán là chuyện
/// đáng nhìn, không phải chuyện hỏng: hàng vẫn còn đó, vẫn bán được. Tô đỏ là
/// đẩy một việc cần xem thành một việc khẩn cấp.
class TongtaiTiedUpCapitalCard extends StatelessWidget {
  const TongtaiTiedUpCapitalCard({
    required this.capital,
    required this.onViewList,
    super.key,
  });

  final SlowMovingCapital capital;
  final VoidCallback onViewList;

  static const Key cardKey = Key('inventory-tied-up-capital');

  @override
  Widget build(BuildContext context) {
    // Không có hàng chậm ⇒ không có gì để nói. Không dựng thẻ rỗng, cùng luật
    // §15 mà khối thuộc tính và khối so sánh NCC đều theo.
    if (!capital.hasSlowMoving) return const SizedBox.shrink();

    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(TtSpace.x4, TtSpace.x3, TtSpace.x4, 0),
      child: Material(
        color: TtColors.warningSoft,
        borderRadius: BorderRadius.circular(TtRadius.lg),
        child: InkWell(
          key: cardKey,
          onTap: onViewList,
          borderRadius: BorderRadius.circular(TtRadius.lg),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TtRadius.lg),
              border: Border.all(
                color: TtColors.warning.withValues(alpha: 0.3),
              ),
            ),
            padding: const EdgeInsets.all(TtSpace.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: TtColors.warningOnDark,
                    ),
                    const SizedBox(width: TtSpace.x2),
                    Expanded(
                      child: Text(
                        l10n.invTiedUpTitle,
                        style: TtType.label.copyWith(
                          color: TtColors.warningOnDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TtSpace.x2),
                Text(
                  TongtaiFormatters.vndShort(capital.tiedUpAmount),
                  key: const Key('inventory-tied-up-amount'),
                  style: TtType.h1.copyWith(
                    color: TtColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.invTiedUpBody(
                    capital.slowMovingCount,
                    capital.windowDays,
                  ),
                  style: TtType.caption.copyWith(color: TtColors.textSecondary),
                ),
                // ⛔ Dòng này là lời thú nhận rằng con số trên **chưa đủ**.
                // Bỏ nó đi thì tổng thiếu trông như tổng đủ.
                if (capital.isPartial) ...[
                  const SizedBox(height: TtSpace.x2),
                  Text(
                    l10n.invTiedUpUnknownCost(capital.unknownCostCount),
                    key: const Key('inventory-tied-up-unknown-cost'),
                    style: TtType.caption.copyWith(
                      color: TtColors.textTertiary,
                    ),
                  ),
                ],
                const SizedBox(height: TtSpace.x3),
                Row(
                  children: [
                    Text(
                      l10n.invTiedUpAction,
                      style: TtType.label.copyWith(
                        color: TtColors.warningOnDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.arrow_forward,
                      size: 13,
                      color: TtColors.warningOnDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
