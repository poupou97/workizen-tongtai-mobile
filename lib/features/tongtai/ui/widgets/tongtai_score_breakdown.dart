import 'package:flutter/material.dart';

import '../../../../core/design/tt.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../opportunity/opportunity_score.dart';

/// **Bung điểm cơ hội ra thành bốn yếu tố** — WTM-408 (concept-1 `cp5b`).
///
/// ## Vì sao khối này tồn tại
///
/// `OpportunityScore` đã tính đủ và **đã tự khai cái nó không biết**: hai trong
/// bốn yếu tố (chất lượng NCC · mức cạnh tranh) không tính được trên máy này,
/// nên `coverage` nhiều nhất chỉ **0.7** — và tụt xuống **0.4** khi cơ hội ấy
/// còn chưa có lịch sử đơn để đọc nhu cầu. Nhưng suốt từ WTM-193 tới nay,
/// `ui/` không bày một dòng nào về điều đó — người bán thấy `61` và không có
/// cách nào biết **ít nhất 30% trọng số đang vắng mặt**.
///
/// `ANALYSIS.md` (concept-1, Đợt 1 #2) gọi đúng tên việc này: *"dữ liệu đã có
/// kèm cả độ phủ 70% — bày ra là tự nó thành lời thú nhận trung thực"*. Đây là
/// khối rẻ nhất trong cả bộ concept mà lại làm sản phẩm thật thà hơn hẳn.
///
/// ## ⛔ `null` KHÔNG phải 0
///
/// Yếu tố vắng hiện **chữ + lý do**, không hiện `0` và không hiện thanh rỗng.
/// Một số 0 nói *"cái này vô giá trị"*; `null` nói *"không ai biết"* — và coi
/// thứ hai là thứ nhất chính là cách một sản phẩm bắt đầu nói dối mà mặt không
/// đổi sắc (nguyên văn ghi trong `OpportunityFactor.score`).
///
/// ## ⚠️ Nhãn "nhu cầu" phải nói ĐÚNG nguồn
///
/// `OpportunityFactorKind.demandVolume` ràng buộc rõ: trên máy này nó đọc từ
/// **lịch sử đơn của chính người bán**, không phải nhu cầu thị trường (định
/// nghĩa của Concept cần Google Trends / API sàn, tức cần backend). Nên nhãn là
/// *"Nhu cầu từ khách của bạn"*, và **cấm** rút gọn thành *"Nhu cầu thị
/// trường"* — rút gọn kiểu ấy là đổi một phép đo thành một lời hứa.
class TongtaiScoreBreakdown extends StatelessWidget {
  const TongtaiScoreBreakdown({required this.score, super.key});

  final OpportunityScore score;

  static const Key sectionKey = Key('opportunity-score-breakdown');

  String _labelFor(AppStrings l10n, OpportunityFactorKind kind) =>
      switch (kind) {
        OpportunityFactorKind.profitPotential => l10n.oppFactorProfit,
        OpportunityFactorKind.demandVolume => l10n.oppFactorDemand,
        OpportunityFactorKind.supplierQuality => l10n.oppFactorSupplier,
        OpportunityFactorKind.competition => l10n.oppFactorCompetition,
      };

  /// Mỗi mã một câu — **không ghép chuỗi**, để bản dịch không phải đoán ngữ
  /// pháp và để một mã lạ lộ ra thay vì lặng lẽ thành câu cụt.
  String? _reasonFor(AppStrings l10n, String? code) => switch (code) {
    OpportunityFactorUnavailable.supplierDirectoryIsSample =>
      l10n.oppUnavailSupplierSample,
    OpportunityFactorUnavailable.needsMarketData => l10n.oppUnavailNeedsMarket,
    OpportunityFactorUnavailable.noBusinessBaseline =>
      l10n.oppUnavailNoBaseline,
    OpportunityFactorUnavailable.noDemandHistory =>
      l10n.oppUnavailNoDemandHistory,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (score.factors.isEmpty) return const SizedBox.shrink();

    return Column(
      key: sectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.oppWhyThisScore,
          style: TtType.h3.copyWith(color: TtColors.textPrimary),
        ),
        if (score.isPartial) ...[
          const SizedBox(height: TtSpace.x1),
          Text(
            // Làm tròn về số nguyên phần trăm: 0.4 ⇒ "40%", 0.7 ⇒ "70%".
            l10n.oppScoreCoverage((score.coverage * 100).round()),
            key: const Key('opportunity-score-coverage'),
            style: TtType.caption.copyWith(color: TtColors.textSecondary),
          ),
        ],
        const SizedBox(height: TtSpace.x3),
        for (final factor in score.factors) ...[
          _FactorRow(
            label: _labelFor(l10n, factor.kind),
            weight: factor.weight,
            value: factor.score,
            reason: _reasonFor(l10n, factor.unavailableCode),
            noDataLabel: l10n.oppFactorNoData,
          ),
          const SizedBox(height: TtSpace.x3),
        ],
      ],
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({
    required this.label,
    required this.weight,
    required this.value,
    required this.reason,
    required this.noDataLabel,
  });

  final String label;
  final double weight;

  /// 0–100, hoặc `null` khi yếu tố này không chấm được.
  final double? value;
  final String? reason;
  final String noDataLabel;

  bool get _available => value != null;

  @override
  Widget build(BuildContext context) {
    // Xám = KHÔNG BIẾT, đúng luật màu (`GRAY = UNKNOWN`). Yếu tố vắng không
    // được mang màu ngữ nghĩa nào khác — nó không tốt, không xấu.
    final tone = _available ? TtColors.textPrimary : TtColors.textTertiary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TtType.body.copyWith(color: tone),
              ),
            ),
            const SizedBox(width: TtSpace.x2),
            // Trọng số luôn hiện, kể cả khi yếu tố vắng — đó chính là thứ cho
            // người đọc thấy **bao nhiêu phần trăm đang thiếu**.
            Text(
              '${(weight * 100).round()}%',
              style: TtType.caption.copyWith(color: TtColors.textSecondary),
            ),
            const SizedBox(width: TtSpace.x3),
            SizedBox(
              width: 44,
              child: Text(
                _available ? value!.round().toString() : '—',
                textAlign: TextAlign.end,
                style: TtType.body.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (!_available && reason != null) ...[
          const SizedBox(height: 2),
          Text(
            '$noDataLabel — ${reason!}',
            style: TtType.caption.copyWith(color: TtColors.textTertiary),
          ),
        ],
      ],
    );
  }
}
