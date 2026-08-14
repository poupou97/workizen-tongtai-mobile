import 'package:flutter/material.dart';

import '../../../../core/design/tt.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../commerce/supplier_comparison.dart';
import '../../core/tongtai_formatters.dart';

/// **So sánh nhà cung cấp trên màn sản phẩm** — WTM-409 (concept-1 `cp11`).
///
/// ## Vì sao khối này tồn tại
///
/// `SupplierComparison` tính xong từ WTM-329 và bản demo có sẵn **124 báo giá /
/// 12 nhà cung cấp**, nhưng `grep SupplierComparison lib/**/ui/` trả **rỗng** —
/// luật chạy trong bóng tối, người bán mở một sản phẩm và không thấy rằng có
/// nguồn khác rẻ hơn.
///
/// ## ⛔ `null` là "chưa biết", KHÔNG phải "bằng nhau"
///
/// Đây là chỗ dễ nói dối nhất, và lớp miền đã cảnh báo nguyên văn: *"coi `null`
/// là 0 sẽ biến một nguồn chưa ai hỏi giao bao lâu thành một nguồn giao nhanh
/// ngang"*. Nên:
///
/// * `slowerByDays == null` ⇒ **không** in dòng thời gian giao; thay vào đó ghi
///   *"chưa biết thời gian giao"* trong danh sách chưa-biết.
/// * `extraMinimumOrder == null` ⇒ tương tự với số lượng tối thiểu.
/// * Không có nguồn nào lấp bằng trung bình cho đẹp bảng.
///
/// ## Nêu ĐÁNH ĐỔI, không đưa phán quyết
///
/// *"Rẻ hơn 12% mà giao chậm hơn 6 ngày là một **đánh đổi**, không phải một câu
/// trả lời"* — nguyên văn trong `SupplierComparison`. Khối này liệt kê cả hai
/// mặt và đóng bằng một câu nhắc rằng người bán mới là người quyết. Nó **không**
/// tô nguồn nào thành "nên chọn", kể cả khi `clearWin` khác `null`: `clearWin`
/// dùng để **xếp thứ tự**, không dùng để thay người bán ra quyết định.
class TongtaiSupplierComparison extends StatelessWidget {
  const TongtaiSupplierComparison({required this.comparison, super.key});

  final SupplierComparison comparison;

  static const Key sectionKey = Key('product-detail-suppliers');

  @override
  Widget build(BuildContext context) {
    // Một báo giá duy nhất thì không có gì để **so**. Không dựng khung rỗng —
    // cùng luật §15 mà khối thuộc tính đã theo: không giá trị ⇒ không tiêu đề.
    if (!comparison.isComparable) return const SizedBox.shrink();

    final l10n = context.l10n;
    final current = comparison.current!;

    return Column(
      key: sectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.supplierSectionTitle,
          style: TtType.h3.copyWith(color: TtColors.textPrimary),
        ),
        const SizedBox(height: TtSpace.x3),

        // ── Nguồn đang nhập ────────────────────────────────────────────
        _QuoteTile(
          badge: l10n.supplierCurrent,
          name: current.supplierName,
          unitCost: current.unitCost,
          highlighted: true,
        ),
        const SizedBox(height: TtSpace.x3),

        Text(
          l10n.supplierAlternatives,
          style: TtType.label.copyWith(color: TtColors.textSecondary),
        ),
        const SizedBox(height: TtSpace.x2),

        for (final option in comparison.alternatives) ...[
          _OptionTile(option: option),
          const SizedBox(height: TtSpace.x2),
        ],

        const SizedBox(height: TtSpace.x1),
        Text(
          l10n.supplierTradeOffNote,
          key: const Key('product-detail-suppliers-tradeoff'),
          style: TtType.caption.copyWith(color: TtColors.textSecondary),
        ),
      ],
    );
  }
}

class _QuoteTile extends StatelessWidget {
  const _QuoteTile({
    required this.badge,
    required this.name,
    required this.unitCost,
    this.highlighted = false,
  });

  final String badge;
  final String name;
  final double unitCost;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TtSpace.x3),
      decoration: BoxDecoration(
        color: highlighted ? TtColors.surfaceTertiary : TtColors.surface,
        borderRadius: BorderRadius.circular(TtRadius.sm),
        border: Border.all(color: TtColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge,
                  style: TtType.caption.copyWith(color: TtColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TtType.body.copyWith(
                    color: TtColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: TtSpace.x2),
          Text(
            TongtaiFormatters.vndShort(unitCost),
            style: TtType.body.copyWith(
              color: TtColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Một lựa chọn khác, kèm **cả hai mặt** của đánh đổi.
class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.option});

  final SupplierOption option;

  String? _unknownLabel(AppStrings l10n, String code) => switch (code) {
    'lead_time' => l10n.supplierUnknownLeadTime,
    'moq' => l10n.supplierUnknownMoq,
    'rating' => l10n.supplierUnknownRating,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final saving = option.savingRatio;
    final slower = option.slowerByDays;
    final extraMoq = option.extraMinimumOrder;

    // Mặt TỐT và mặt XẤU tách riêng, mỗi mặt màu đúng nghĩa của nó — không
    // gộp thành một câu để rồi phải chọn một màu cho cả hai.
    final pros = <String>[
      if (saving != null && option.isCheaper)
        l10n.supplierCheaperBy((saving * 100).round()),
      if (slower != null && slower < 0) l10n.supplierFasterByDays(-slower),
    ];
    final cons = <String>[
      if (slower != null && slower > 0) l10n.supplierSlowerByDays(slower),
      if (extraMoq != null && extraMoq > 0)
        l10n.supplierExtraMoq(TongtaiFormatters.compact(extraMoq)),
    ];
    final unknowns = [
      for (final code in option.unknowns) ?_unknownLabel(l10n, code),
    ];

    return Container(
      key: Key('supplier-option-${option.quote.id}'),
      padding: const EdgeInsets.all(TtSpace.x3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TtRadius.sm),
        border: Border.all(color: TtColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  option.quote.supplierName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TtType.body.copyWith(
                    color: TtColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: TtSpace.x2),
              Text(
                TongtaiFormatters.vndShort(option.quote.unitCost),
                style: TtType.body.copyWith(
                  color: TtColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          for (final line in pros) ...[
            const SizedBox(height: 2),
            Text(line, style: TtType.caption.copyWith(color: TtColors.success)),
          ],
          for (final line in cons) ...[
            const SizedBox(height: 2),
            Text(line, style: TtType.caption.copyWith(color: TtColors.danger)),
          ],
          // ⛔ Xám = KHÔNG BIẾT. Những dòng này KHÔNG phải điểm trừ của nguồn
          // hàng — chúng là điều app chưa hỏi, nên chúng không được mang màu
          // xấu, và cũng không được biến mất.
          for (final line in unknowns) ...[
            const SizedBox(height: 2),
            Text(
              line,
              style: TtType.caption.copyWith(color: TtColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}
