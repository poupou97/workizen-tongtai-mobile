/// **Mục tiêu + kế hoạch đầu tiên** — WTM-355 · WTM-356 (S6, S7).
///
/// Onboarding **không** kết thúc bằng *"Hoàn tất thiết lập"*. Nó kết thúc bằng
/// kế hoạch đầu tiên của người bán, sinh ra từ đúng những gì vừa nhìn thấy.
///
/// ## Hình dạng của một việc
///
/// `VẤN ĐỀ → BẰNG CHỨNG → HÀNH ĐỘNG ĐỀ XUẤT → ƯU TIÊN`
///
/// Ba phần đầu đều đến từ một [FirstFinding] thật, tức là từ một luật thật.
/// Không có phần thứ tư kiểu *"tác động dự kiến +8,4 triệu"* — xem [PlanAction].
///
/// ## ⛔ Không CTA chết
///
/// Mỗi việc mang một [PlanDestination] từ **danh sách đóng**. Một chuỗi tự do
/// ở đây là cách nút "Xem chi tiết" trỏ vào hư không: nó biên dịch được, trông
/// đúng, và chỉ hỏng lúc người bán bấm. Danh sách đóng làm việc đó thành lỗi
/// biên dịch.
library;

import 'package:flutter/foundation.dart';

import '../agent/business_brief.dart';
import '../journey/business_goal.dart';
import 'first_insight.dart';

/// Tám lựa chọn mục tiêu của onboarding.
///
/// Bảy trong tám ánh xạ **1:1** sang một [GoalType]; cái thứ tám không tạo mục
/// tiêu nào. WTM-355 mở rộng `GoalType` thêm ba nguyên mẫu chính là để tránh
/// ánh xạ méo: *"tối ưu tồn kho"* ép vào `revenue` sẽ cho người bán một kế
/// hoạch nói về khuyến mãi ngay sau khi họ nói mình muốn dọn kho.
enum OnboardingGoal {
  growRevenue('grow_revenue', GoalType.revenue),
  growProfit('grow_profit', GoalType.profit),
  findProducts('find_products', GoalType.productLaunch),
  optimizeInventory('optimize_inventory', GoalType.inventory),
  betterSourcing('better_sourcing', GoalType.sourcing),
  keepCustomers('keep_customers', GoalType.customerGrowth),
  newMarket('new_market', GoalType.newChannel),

  /// *"Chỉ khám phá trước"* — **không** tạo mục tiêu.
  ///
  /// Một nhánh khai báo rõ, không phải một mục tiêu rỗng: một bản ghi mục tiêu
  /// không tên trong màn Mục tiêu là rác người bán phải tự dọn, và nó nói dối
  /// rằng họ đã cam kết một điều gì đó.
  justExplore('just_explore', null);

  const OnboardingGoal(this.code, this.archetype);

  /// Mã canonical — lưu và test dùng mã này, không dùng nhãn.
  final String code;

  /// `null` = không tạo `BusinessGoal`.
  final GoalType? archetype;

  bool get createsGoal => archetype != null;

  static OnboardingGoal? fromCode(String? code) {
    for (final g in values) {
      if (g.code == code) return g;
    }
    return null;
  }
}

/// Nhiều nhất bao nhiêu mục tiêu được chọn cùng lúc.
///
/// Hai. Ba mục tiêu cùng lúc không phải ưu tiên, nó là danh sách ước — và một
/// kế hoạch phục vụ ba hướng thì không dẫn tới đâu cả.
const int kMaxOnboardingGoals = 2;

/// Nơi một việc dẫn tới. **Danh sách đóng** — xem chú thích đầu file.
enum PlanDestination {
  home('home'),
  inventory('inventory'),
  stockAlerts('stock_alerts'),
  customerList('customer_list'),
  customerRisk('customer_risk'),
  opportunity('opportunity'),
  finance('finance'),
  reports('reports'),
  goals('goals'),
  journey('journey'),
  importData('import');

  const PlanDestination(this.code);

  final String code;
}

/// Một việc trong kế hoạch đầu tiên.
@immutable
class PlanAction {
  const PlanAction({
    required this.problem,
    required this.evidence,
    required this.action,
    required this.priority,
    required this.destination,
    this.ruleCode,
  });

  /// Chuyện gì đang không ổn — một câu, có số.
  final String problem;

  /// Vì sao nghĩ vậy.
  final String evidence;

  /// Nên làm gì.
  final String action;

  /// 1 = làm trước. Số nhỏ lên trên.
  final int priority;

  final PlanDestination destination;

  /// Luật nào sinh ra việc này. `null` = việc đến từ **mục tiêu**, không từ một
  /// phát hiện — hợp lệ, và là đường duy nhất của người chưa có dữ liệu.
  final String? ruleCode;

  // ⛔ CỐ Ý KHÔNG CÓ TRƯỜNG "tác động dự kiến".
  //
  // *"Giá trị hàng có nguy cơ thiếu: 12,4 triệu"* là một **dữ kiện** — tồn kho
  // và giá vốn đều đã biết, nên nó thuộc về `evidence`.
  //
  // *"Việc này sẽ tăng lợi nhuận 8,4 triệu"* là một **lời hứa lợi nhuận** cho
  // một việc chưa ai làm. Không luật nào trên máy này sinh ra được nó một cách
  // trung thực. Trường đó vắng mặt ở đây để không ai điền nó "tạm" — có test
  // governance canh đúng điều này.
}

/// Kế hoạch đầu tiên.
@immutable
class FirstPlan {
  const FirstPlan({required this.goals, required this.actions});

  final List<OnboardingGoal> goals;
  final List<PlanAction> actions;

  bool get isEmpty => actions.isEmpty;
}

/// Sinh kế hoạch — tất định, từ (mục tiêu, phát hiện).
///
/// Không AI, không mạng. Cùng đầu vào ⇒ cùng kế hoạch, nên ảnh chụp demo đối
/// chiếu được với test.
class FirstPlanBuilder {
  const FirstPlanBuilder({this.maxActions = 3});

  /// Ba việc. Người bán vừa mở app lần đầu — một danh sách dài hơn thế là một
  /// bảng công việc, không phải một khởi đầu.
  final int maxActions;

  FirstPlan build({
    required List<OnboardingGoal> goals,
    required FirstInsight insight,
  }) {
    final actions = <PlanAction>[];

    // 1 · Việc đến từ phát hiện thật — mạnh nhất, nên lên trước.
    var priority = 1;
    for (final f in insight.findings) {
      if (actions.length >= maxActions) break;
      actions.add(
        PlanAction(
          problem: f.headline,
          evidence: f.reason,
          action: _actionFor(f.kind),
          priority: priority++,
          destination: _destinationFor(f.kind),
          ruleCode: f.ruleCode,
        ),
      );
    }

    // 2 · Không phát hiện nào ⇒ kế hoạch vẫn phải có việc, lấy từ mục tiêu.
    //     Đây là đường **duy nhất** của người chưa có dữ liệu, nên nó không
    //     phải một nhánh dự phòng — nó là một nửa sản phẩm.
    for (final goal in goals) {
      if (actions.length >= maxActions) break;
      final seed = _seedFor(goal);
      if (seed == null) continue;
      actions.add(
        PlanAction(
          problem: seed.problem,
          evidence: seed.evidence,
          action: seed.action,
          priority: priority++,
          destination: seed.destination,
        ),
      );
    }

    return FirstPlan(
      goals: List.unmodifiable(goals),
      actions: List.unmodifiable(actions),
    );
  }

  static String _actionFor(BriefKind kind) => switch (kind) {
    BriefKind.stockRunningOut => 'Tạo đơn nhập trước khi hết',
    BriefKind.marginTooThin => 'Xem lại giá bán mặt hàng này',
    BriefKind.customerAtRisk => 'Nhắn cho khách trước khi họ quên',
    BriefKind.businessSignal => 'Mở Báo cáo xem điều gì đã đổi',
  };

  static PlanDestination _destinationFor(BriefKind kind) => switch (kind) {
    BriefKind.stockRunningOut => PlanDestination.stockAlerts,
    BriefKind.marginTooThin => PlanDestination.inventory,
    BriefKind.customerAtRisk => PlanDestination.customerRisk,
    BriefKind.businessSignal => PlanDestination.reports,
  };

  /// Việc khởi đầu cho một mục tiêu, khi chưa có phát hiện nào.
  ///
  /// `null` cho [OnboardingGoal.justExplore]: người chọn *"chỉ khám phá"* không
  /// muốn ai giao việc cho mình, và giao một việc ở đó là không nghe họ nói.
  static _Seed? _seedFor(OnboardingGoal goal) => switch (goal) {
    OnboardingGoal.justExplore => null,
    OnboardingGoal.growRevenue => const _Seed(
      problem: 'Chưa biết doanh thu đang đến từ đâu',
      evidence: 'Chưa có đủ đơn hàng để tách theo kênh và theo khách',
      action: 'Ghi vài đơn gần nhất để có mốc so',
      destination: PlanDestination.importData,
    ),
    OnboardingGoal.growProfit => const _Seed(
      problem: 'Chưa tính được lời thật',
      evidence: 'Thiếu giá vốn thì mọi con số lợi nhuận đều là phỏng đoán',
      action: 'Khai giá vốn cho vài mặt hàng bán chạy',
      destination: PlanDestination.inventory,
    ),
    OnboardingGoal.findProducts => const _Seed(
      problem: 'Chưa có mặt hàng nào để so',
      evidence: 'Cơ hội được tính từ nhu cầu và biên lợi nhuận của hàng đã có',
      action: 'Thêm vài mặt hàng đang bán',
      destination: PlanDestination.inventory,
    ),
    OnboardingGoal.optimizeInventory => const _Seed(
      problem: 'Chưa biết vốn đang nằm ở đâu',
      evidence: 'Mặt hàng chưa khai tồn là một khoảng mù, không phải số không',
      action: 'Khai tồn kho cho hàng đang có',
      destination: PlanDestination.inventory,
    ),
    // ⛔ KHÔNG dẫn tới màn tìm nhà cung cấp: danh bạ ở đó là
    // `SupplierSearchService.sample()` — nhà cung cấp **bịa** — và Founder đã
    // chốt 2026-08-01 *"không cố xây AI bằng dữ liệu giả"*. Mở đường vào là
    // trưng danh bạ giả cho người bán thật, tức là đúng thứ Epic này cấm, chỉ
    // ở một chỗ khó thấy hơn.
    //
    // Việc THẬT đầu tiên để biết mình mua đắt hay rẻ là khai giá vốn hàng đang
    // có — làm được ngay, ở màn Kho.
    OnboardingGoal.betterSourcing => const _Seed(
      problem: 'Chưa biết mình đang mua đắt hay rẻ',
      evidence: 'Không có giá vốn thì không so được với bất kỳ báo giá nào',
      action: 'Khai giá vốn cho hàng đang nhập',
      destination: PlanDestination.inventory,
    ),
    OnboardingGoal.keepCustomers => const _Seed(
      problem: 'Chưa có khách nào trong danh bạ',
      evidence: 'Nhịp mua lại được suy từ lịch sử của chính từng khách',
      action: 'Thêm khách quen vào danh bạ',
      destination: PlanDestination.customerList,
    ),
    OnboardingGoal.newMarket => const _Seed(
      problem: 'Chưa biết kênh nào đang hiệu quả',
      evidence: 'So kênh cần đơn hàng đã gắn kênh bán',
      action: 'Ghi đơn kèm kênh bán để có mốc so',
      destination: PlanDestination.reports,
    ),
  };
}

@immutable
class _Seed {
  const _Seed({
    required this.problem,
    required this.evidence,
    required this.action,
    required this.destination,
  });

  final String problem;
  final String evidence;
  final String action;
  final PlanDestination destination;
}
