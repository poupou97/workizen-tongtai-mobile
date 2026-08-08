import 'package:flutter/foundation.dart';

import '../action/business_action.dart';
import 'autonomy_settings.dart';
import 'business_brief.dart';

/// **Trải nghiệm #3 · Orchestration Card** — WTM-306.
///
/// Sáu dòng Founder đặt ra, và chúng là **cách người bán hiểu** một automation:
///
/// ```
/// WHEN      Khách VIP im lặng
/// IF        Quá 2 chu kỳ mua
/// THINK     AI phân tích lịch sử
/// APPROVAL  Hỏi tôi
/// DO        Gửi đề xuất chăm sóc
/// OBSERVE   Theo dõi đơn tiếp theo
/// ```
///
/// ## Không phải một tính năng mới — là một CÁCH ĐỌC thứ hai
///
/// Sáu dòng này **không** dựng thêm gì. Chúng mô tả đúng chuỗi đã chạy từ
/// WTM-303: Rule Twin quan sát → bằng chứng → đề xuất → duyệt → hành động →
/// việc hẹn lại.
///
/// Nếu về sau đường chạy đổi mà thẻ này không đổi, thẻ sẽ nói dối. Nên nó
/// **dẫn xuất** từ `BriefKind` + `AutonomySettings` chứ không phải một bảng
/// văn bản chép tay — cùng kỷ luật P-27 đã dọn bốn lần.
///
/// ## Không lộ hạ tầng (Task Order §8)
///
/// `n8n` · webhook · JSON · tên bảng · `AgentTask` · `correlationId` không có
/// mặt ở đây, và có test khoá điều đó. Người bán đọc *"theo dõi đơn tiếp
/// theo"*, không đọc *"scheduleRecheck(days: 7)"*.
@immutable
class AutomationCard {
  const AutomationCard({
    required this.when,
    required this.condition,
    required this.think,
    required this.approval,
    required this.act,
    required this.observe,
  });

  /// Điều gì khiến Tổng Tài để ý.
  final String when;

  /// Ngưỡng nào biến "để ý" thành "đáng nói".
  final String condition;

  /// Nó nghĩ bằng gì.
  final String think;

  /// Ai quyết — và đây là dòng đổi theo cấu hình.
  final String approval;

  /// Nó làm gì.
  final String act;

  /// Sau đó nó theo dõi cái gì.
  final String observe;

  List<(String, String)> get lines => [
    ('WHEN', when),
    ('IF', condition),
    ('THINK', think),
    ('APPROVAL', approval),
    ('DO', act),
    ('OBSERVE', observe),
  ];

  /// Dựng thẻ cho một loại việc, theo mức tự chủ **đang có hiệu lực**.
  ///
  /// [settings] quyết định đúng một dòng — `APPROVAL`. Đó là chủ ý: người bán
  /// gạt một công tắc rồi nhìn thấy **chính xác** dòng nào của câu chuyện đổi,
  /// thay vì phải tin rằng có gì đó đã đổi ở đâu đó.
  factory AutomationCard.forKind(
    BriefKind kind, {
    AutonomySettings settings = const AutonomySettings(),
  }) {
    final actionType = _actionFor(kind);
    final approval = actionType == null
        ? 'Bạn xem rồi tự quyết'
        : _approvalLine(settings.resolve(actionType), actionType);

    return switch (kind) {
      BriefKind.customerAtRisk => AutomationCard(
        when: 'Một khách quen im lặng',
        condition: 'Lâu hơn nhịp mua của chính họ',
        think: 'Xem lại lịch sử mua và giá trị của khách',
        approval: approval,
        act: 'Soạn lời chăm sóc gửi khách',
        observe: 'Theo dõi đơn tiếp theo của họ',
      ),
      BriefKind.stockRunningOut => AutomationCard(
        when: 'Một mặt hàng tụt xuống dưới mức đặt lại',
        condition: 'Còn ít hơn mức bạn đã đặt cho mặt hàng đó',
        think: 'Tính số cần nhập để về lại mức an toàn',
        approval: approval,
        act: 'Dựng phiếu nhập hàng',
        observe: 'Theo dõi tồn kho sau khi hàng về',
      ),
      BriefKind.marginTooThin => AutomationCard(
        when: 'Một mặt hàng bán gần bằng giá vốn',
        condition: 'Lãi mỗi đơn vị dưới 15%',
        think: 'Tính giá bán để lãi trở lại mức lành mạnh',
        approval: approval,
        act: 'Đề nghị giá bán mới',
        observe: 'Theo dõi lãi sau khi đổi giá',
      ),
      BriefKind.businessSignal => AutomationCard(
        when: 'Doanh thu, số đơn hoặc dòng tiền đổi hướng',
        condition: 'Khác rõ so với kỳ trước',
        think: 'So kỳ này với kỳ trước trên sổ sách của bạn',
        // Không có một việc đúng duy nhất ⇒ không hứa sẽ làm gì.
        approval: 'Bạn xem rồi tự quyết',
        act: 'Chỉ báo cho bạn biết',
        observe: 'Theo dõi kỳ sau',
      ),
    };
  }

  /// Hành động mà một loại việc sinh ra — `null` khi việc chỉ để biết.
  static BusinessActionType? _actionFor(BriefKind kind) => switch (kind) {
    BriefKind.customerAtRisk => BusinessActionType.customerSendMessage,
    BriefKind.stockRunningOut =>
      BusinessActionType.inventoryCreatePurchaseOrder,
    BriefKind.marginTooThin => BusinessActionType.productUpdatePrice,
    BriefKind.businessSignal => null,
  };

  static String _approvalLine(AutonomyMode mode, BusinessActionType type) =>
      switch (mode) {
        AutonomyMode.off => 'Tôi không nhắc gì cả',
        AutonomyMode.suggest => 'Tôi chỉ gợi ý, bạn tự làm',
        AutonomyMode.confirm => 'Hỏi bạn trước khi làm',
        // Tới được nhánh này nghĩa là `resolve` đã cho phép — tức loại hành
        // động không nằm trong danh sách cấm. Nên câu ở đây không cần dè dặt.
        AutonomyMode.auto => 'Tôi tự làm trong hạn mức bạn đặt',
      };
}
