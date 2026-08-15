import 'package:flutter/material.dart';

import '../../../../core/design/tt.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../commerce/commerce_profit.dart';
import '../../core/tongtai_formatters.dart';
import '../../finance/true_profit.dart';
import '../../inventory/product_unit_economics.dart';

/// **Khối Tài chính của một sản phẩm** — WTM-420 (concept-1 `cp6`).
///
/// ## Hai nhóm con số, và chúng KHÔNG được đứng lẫn nhau
///
/// * **Đo được** — đã bán bao nhiêu, thu về bao nhiêu, lãi thật bao nhiêu (đã
///   trừ phí sàn). Lấy từ đơn hàng đã xảy ra.
/// * **Dự kiến** — bán hết chỗ đang tồn thì lãi bao nhiêu. Chưa xảy ra.
///
/// Trộn hai nhóm vào một hàng là đúng lỗi WTM-384 (`estimatedGain` đội lốt
/// `observedRevenue`): người bán cộng nhẩm cả hai rồi tưởng đó là tiền đã có.
/// Nên chúng nằm ở **hai khối tách rời**, và khối dự kiến mang nhãn *"dự kiến"*
/// ngay trên con số, không phải trong chú thích nhỏ bên dưới.
///
/// ## ⛔ Thiếu giá vốn thì nói ra, không im lặng
///
/// Không có giá vốn ⇒ không có lãi, không có biên. Màn **mời khai**, và câu chữ
/// không trách: giá vốn là thứ *app* chưa hỏi, không phải lỗi người bán.
class TongtaiProductFinance extends StatelessWidget {
  const TongtaiProductFinance({
    required this.economics,
    required this.sold,
    required this.windowDays,
    super.key,
  });

  static const Key sectionKey = Key('product-finance');

  final ProductUnitEconomics economics;

  /// Kết quả bán **thật** trong cửa sổ. `null` = chưa bán được cái nào.
  final ProductProfit? sold;

  final int windowDays;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profit = economics.profitPerUnit;
    final margin = economics.marginPercent;
    final projected = economics.projectedProfitOnStock;

    return Container(
      key: sectionKey,
      padding: const EdgeInsets.all(TtSpace.x4),
      decoration: BoxDecoration(
        color: TtColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(TtRadius.md),
        border: Border.all(color: TtColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.finProductSection,
            style: TtType.h2.copyWith(color: TtColors.textPrimary),
          ),
          const SizedBox(height: TtSpace.x3),

          _Row(
            label: l10n.finSellingPrice,
            value: TongtaiFormatters.vndShort(economics.sellingPrice),
          ),
          _Row(
            label: l10n.finCostPrice,
            value: economics.hasCost
                ? TongtaiFormatters.vndShort(economics.costPrice!)
                : null,
          ),

          if (profit == null)
            // Lời mời, không phải lời trách.
            Padding(
              padding: const EdgeInsets.only(top: TtSpace.x2),
              child: Text(
                l10n.finCostMissing,
                key: const Key('product-finance-cost-missing'),
                style: TtType.caption.copyWith(color: TtColors.textTertiary),
              ),
            )
          else ...[
            _Row(
              label: l10n.finProfitPerUnit,
              value: TongtaiFormatters.vndShort(profit),
              key: const Key('product-finance-profit-per-unit'),
              // Bán lỗ là sự thật cần thấy, nên số âm mặc màu cảnh báo — còn
              // số dương thì KHÔNG mặc màu mừng: lãi là chuyện bình thường.
              tone: profit < 0 ? TtStatus.danger : null,
            ),
            if (margin != null)
              _Row(
                label: l10n.finMargin,
                value: '${margin.toStringAsFixed(0)}%',
                key: const Key('product-finance-margin'),
                tone: margin < 0 ? TtStatus.danger : null,
              ),
          ],

          // ── ĐO ĐƯỢC ──────────────────────────────────────────────────────
          const SizedBox(height: TtSpace.x4),
          _GroupTitle(l10n.finMeasuredIn(windowDays)),
          if (sold == null || sold!.units == 0)
            Text(
              l10n.finNoSalesYet,
              key: const Key('product-finance-no-sales'),
              style: TtType.caption.copyWith(color: TtColors.textTertiary),
            )
          else ...[
            _Row(label: l10n.finUnitsSold, value: '${sold!.units}'),
            _Row(
              label: l10n.finRevenue,
              value: TongtaiFormatters.vndShort(sold!.revenue),
            ),
            _Row(
              label: l10n.finRealProfit,
              key: const Key('product-finance-real-profit'),
              // ⛔ Lợi nhuận thật `null` khi thiếu dữ liệu (giá vốn, đối soát).
              // Nó KHÔNG rơi về 0 — `TrueProfit` là kiểu tổng có nhánh "chưa
              // tính được, và đây là thiếu gì".
              value: switch (sold!.profit) {
                ProfitKnown(amount: final a) => TongtaiFormatters.vndShort(a),
                _ => null,
              },
            ),
          ],

          // ── DỰ KIẾN ──────────────────────────────────────────────────────
          if (projected != null) ...[
            const SizedBox(height: TtSpace.x4),
            _GroupTitle(l10n.finProjectedOnStock(economics.stockOnHand!)),
            Text(
              TongtaiFormatters.vndShort(projected),
              key: const Key('product-finance-projected'),
              style: TtType.h2.copyWith(
                color: projected < 0
                    ? TtStatus.danger.color
                    : TtColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: TtSpace.x2),
    child: Text(
      text,
      style: TtType.label.copyWith(
        color: TtColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Một dòng nhãn — giá trị. `value == null` ⇒ hiện **dấu chưa biết**, không
/// hiện `0`.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.tone, super.key});

  final String label;
  final String? value;
  final TtStatus? tone;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TtType.body.copyWith(color: TtColors.textSecondary),
          ),
        ),
        Text(
          value ?? '—',
          style: TtType.body.copyWith(
            color: value == null
                ? TtColors.textTertiary
                : (tone?.color ?? TtColors.textPrimary),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
