import 'business_goal.dart';

/// One suggested step toward a business goal (WTM-88).
class GoalActionStep {
  const GoalActionStep(this.titleVi, this.detailVi);

  final String titleVi;
  final String detailVi;
}

/// A rule-based plan to reach a business [goal] (WTM-88).
///
/// Deterministic and tuned by the goal archetype and current pace — the real
/// AI-generated plan (Claude/xAI) arrives later. Kept pure (no widgets) so the
/// mapping is directly unit-testable. When the goal is behind pace it opens with
/// an urgency step phrased with the concrete gap.
List<GoalActionStep> goalActionPlan(BusinessGoal goal, DateTime now) {
  final steps = <GoalActionStep>[];

  if (goal.pace(now) == GoalPace.behind) {
    final pct = (goal.progress * 100).round();
    final days = goal.daysRemaining(now);
    steps.add(
      GoalActionStep(
        'Đang chậm tiến độ — ưu tiên ngay',
        'Còn $days ngày mà mới đạt $pct%. Dồn lực vào việc tác động nhanh nhất '
            'bên dưới trước.',
      ),
    );
  }

  steps.addAll(_stepsFor(goal.type));

  steps.add(
    const GoalActionStep(
      'Theo dõi hằng tuần',
      'Cập nhật số đã đạt mỗi tuần để biết còn cách mục tiêu bao xa và điều '
          'chỉnh kịp thời.',
    ),
  );

  return steps;
}

/// Short guidance tips for a goal archetype (WTM-90, lite — inline tips rather
/// than external links in Phase 2).
List<String> goalGuidanceTips(GoalType type) => switch (type) {
  GoalType.revenue => const [
    'Doanh thu = số đơn × giá trị mỗi đơn — cải thiện cả hai.',
    'Khách cũ rẻ hơn khách mới; chăm họ trước khi tìm khách mới.',
  ],
  GoalType.newChannel => const [
    'Bắt đầu với một kênh, làm tốt rồi mới mở kênh tiếp theo.',
    'Đồng bộ giá và tồn kho giữa các kênh để tránh nhầm lẫn.',
  ],
  GoalType.customerGrowth => const [
    'Chi phí có được khách mới nên nhỏ hơn lợi nhuận trọn đời của họ.',
    'Data khách (SĐT, lịch sử mua) là tài sản — lưu lại có hệ thống.',
  ],
  GoalType.productLaunch => const [
    'Nhập lô nhỏ để thử thị trường trước khi ôm hàng lớn.',
    'Chuẩn bị nội dung ra mắt trước ngày mở bán, đừng để nước tới chân.',
  ],
  GoalType.profit => const [
    'Lời = doanh thu − giá vốn − phí sàn. Thiếu một vế là con số sai.',
    'Bán nhiều mà mỏng biên thì càng bán càng mệt — sửa giá trước khi đẩy đơn.',
  ],
  GoalType.inventory => const [
    'Hàng nằm quá 90 ngày là tiền đang ngủ — thà bớt giá để lấy vốn ra.',
    'Khai giá vốn thì mới biết mỗi kệ hàng đang giữ bao nhiêu tiền.',
  ],
  GoalType.sourcing => const [
    'Ba báo giá cho cùng một mặt hàng là mức tối thiểu để biết mình mua đắt.',
    'Giá rẻ mà giao chậm có khi đắt hơn — so cả điều kiện giao, không chỉ giá.',
  ],
};

List<GoalActionStep> _stepsFor(GoalType type) => switch (type) {
  GoalType.profit => const [
    GoalActionStep(
      'Khai giá vốn cho hàng bán chạy',
      'Không có giá vốn thì mọi con số lợi nhuận đều là phỏng đoán.',
    ),
    GoalActionStep(
      'Chặn mặt hàng bán gần bằng giá vốn',
      'Sửa giá hoặc bỏ bán — mỗi đơn như thế đang lấy công làm lãi.',
    ),
    GoalActionStep(
      'Đối soát phí sàn',
      'Phí sàn ăn vào lời thật; chưa đối soát thì chưa biết mình còn bao nhiêu.',
    ),
  ],
  GoalType.inventory => const [
    GoalActionStep(
      'Xử lý hàng chậm bán',
      'Giảm giá hoặc bán kèm để lấy vốn ra khỏi hàng đang nằm.',
    ),
    GoalActionStep(
      'Đặt mức đặt lại cho hàng chạy',
      'Có mức đặt lại thì hết hàng được báo trước, không phải phát hiện sau.',
    ),
    GoalActionStep(
      'Khai tồn kho còn thiếu',
      'Mặt hàng chưa khai tồn là một khoảng mù, không phải một số không.',
    ),
  ],
  GoalType.sourcing => const [
    GoalActionStep(
      'Thêm nhà cung cấp để so',
      'Một nguồn duy nhất vừa là rủi ro vừa là lý do không biết giá thị trường.',
    ),
    GoalActionStep(
      'So báo giá cho mặt hàng nhập nhiều nhất',
      'Giảm được 5% ở mặt hàng nhập nhiều đáng hơn 20% ở mặt hàng lẻ.',
    ),
    GoalActionStep(
      'So cả điều kiện giao, không chỉ giá',
      'MOQ và thời gian giao đổi được thành tiền — tính chúng vào khi so.',
    ),
  ],
  GoalType.revenue => const [
    GoalActionStep(
      'Tăng giá trị mỗi đơn',
      'Gợi ý combo, bán kèm để khách mua nhiều hơn trong mỗi lần đặt.',
    ),
    GoalActionStep(
      'Kích hoạt khách cũ',
      'Nhắn ưu đãi cho khách đã mua để họ quay lại — nguồn doanh thu rẻ nhất.',
    ),
    GoalActionStep(
      'Chạy khuyến mãi có hạn',
      'Đặt mốc giảm giá ngắn ngày để thúc đẩy khách chốt đơn sớm.',
    ),
  ],
  GoalType.newChannel => const [
    GoalActionStep(
      'Chọn kênh phù hợp',
      'So sánh Shopee / TikTok Shop / Facebook theo tệp khách của bạn.',
    ),
    GoalActionStep(
      'Đăng sản phẩm chủ lực',
      'Đưa 5–10 sản phẩm bán chạy nhất lên kênh mới trước để tạo lực.',
    ),
    GoalActionStep(
      'Chạy quảng cáo thử',
      'Ngân sách nhỏ để đo phản hồi trước khi mở rộng đầu tư.',
    ),
  ],
  GoalType.customerGrowth => const [
    GoalActionStep(
      'Ưu đãi khách mới',
      'Voucher lần đầu để hạ rào cản, giúp khách mua thử dễ hơn.',
    ),
    GoalActionStep(
      'Chương trình giới thiệu',
      'Thưởng cho khách rủ bạn bè — khách giới thiệu thường trung thành hơn.',
    ),
    GoalActionStep(
      'Chăm sóc data khách',
      'Lưu thông tin và nhắc lại đúng lúc để tăng tỉ lệ quay lại.',
    ),
  ],
  GoalType.productLaunch => const [
    GoalActionStep(
      'Xác nhận nhu cầu + giá',
      'Khảo sát nhanh và định giá cạnh tranh trước khi nhập hàng.',
    ),
    GoalActionStep(
      'Chuẩn bị tồn kho',
      'Đảm bảo đủ hàng cho đợt ra mắt, tránh cháy hàng quá sớm.',
    ),
    GoalActionStep(
      'Kế hoạch truyền thông',
      'Lên lịch bài đăng + ưu đãi ra mắt để tạo sức hút ngày mở bán.',
    ),
  ],
};
