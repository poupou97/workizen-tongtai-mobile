import '../core/tongtai_formatters.dart';
import '../core/tongtai_enums.dart';
import 'opportunity.dart';

/// A single suggested step in an opportunity's action plan (WTM-92).
class OpportunityActionStep {
  const OpportunityActionStep(this.titleVi, this.detailVi);

  /// Imperative step title, e.g. "Xác minh giá 2 nguồn".
  final String titleVi;

  /// One-line "why / how" for the step.
  final String detailVi;
}

/// A rule-based action plan for pursuing an [opportunity] (WTM-92).
///
/// Deterministic and derived from the opportunity archetype — the real
/// AI-generated plan arrives with WTM-88/93. Kept pure (no widgets) so the
/// mapping is directly unit-testable.
List<OpportunityActionStep> opportunityActionPlan(Opportunity opportunity) {
  final steps = _stepsFor(opportunity.type);
  // Every plan closes on the same decision gate, phrased with this
  // opportunity's own expected impact.
  //
  // It used to quote an ROI percentage — from `estimatedRoi`, which was a
  // **constant per rule** (WTM-193). The seller read a specific-looking target
  // that nobody had computed. Expected impact is a real number from their own
  // data, so the gate is now checkable against something true.
  final impact = TongtaiFormatters.vnd(opportunity.expectedImpact);
  return [
    ...steps,
    OpportunityActionStep(
      'Quyết định scale',
      'Nếu lợi nhuận thực tiến gần mức kỳ vọng ($impact) thì nhân rộng, '
          'ngược lại dừng và rút kinh nghiệm.',
    ),
  ];
}

List<OpportunityActionStep> _stepsFor(OpportunityType type) => switch (type) {
  OpportunityType.arbitrage => const [
    OpportunityActionStep(
      'Xác minh giá 2 nguồn',
      'Kiểm tra lại giá mua và giá bán ở cả hai kênh, chụp màn hình làm bằng.',
    ),
    OpportunityActionStep(
      'Tính đủ chi phí',
      'Cộng phí vận chuyển, phí sàn, thuế để ra lợi nhuận thực trên mỗi đơn.',
    ),
    OpportunityActionStep(
      'Đặt thử lô nhỏ',
      'Mua một lô nhỏ để kiểm tra chất lượng và thời gian giao trước khi ôm hàng.',
    ),
  ],
  OpportunityType.seasonal => const [
    OpportunityActionStep(
      'Dự báo nhu cầu mùa',
      'Ước lượng số lượng bán được dựa trên mùa vụ và dữ liệu năm trước.',
    ),
    OpportunityActionStep(
      'Chốt nhà cung cấp sớm',
      'Đặt trước với nhà cung cấp để có giá tốt và đủ hàng trước cao điểm.',
    ),
    OpportunityActionStep(
      'Chuẩn bị khuyến mãi',
      'Lên nội dung + ngân sách quảng cáo để bung đúng lúc nhu cầu lên cao.',
    ),
  ],
  OpportunityType.crossBorder => const [
    OpportunityActionStep(
      'Kiểm tra quy định',
      'Rà soát thủ tục nhập/xuất, giấy tờ và thuế cho mặt hàng này.',
    ),
    OpportunityActionStep(
      'Tìm đối tác logistics',
      'Chọn đơn vị vận chuyển quốc tế uy tín, so sánh chi phí và thời gian.',
    ),
    OpportunityActionStep(
      'Thử đơn mẫu',
      'Gửi/nhận một đơn mẫu để đo tổng chi phí và thời gian giao thực tế.',
    ),
  ],
  OpportunityType.trend => const [
    OpportunityActionStep(
      'Xác nhận độ nóng',
      'Đối chiếu nhiều nguồn (mạng xã hội, sàn) xem trend có thật và còn tăng.',
    ),
    OpportunityActionStep(
      'Nhập lô test nhỏ',
      'Nhập số lượng nhỏ để thử thị trường, tránh tồn kho nếu trend hạ nhiệt.',
    ),
    OpportunityActionStep(
      'Chạy quảng cáo thử',
      'Chạy một chiến dịch nhỏ, đo tỉ lệ chuyển đổi trước khi tăng ngân sách.',
    ),
  ],
};
