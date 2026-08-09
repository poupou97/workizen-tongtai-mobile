import 'package:flutter/foundation.dart';

/// Nơi hành động được thực thi (WTM-300 · D-3).
///
/// ## ⭐ `internal` là điểm mấu chốt của cả phase này
///
/// Cửa ghi phải phủ **cả ghi vào cơ sở dữ liệu của chính Tổng Tài**, không chỉ
/// gọi vendor ngoài. Đó đúng là chỗ COMP AI hụt: `set_field_value` ghi DB của
/// chính nó nên **không ai nghĩ nó cần đi qua action** — và thế là sinh ra
/// đường ghi thứ ba, không evidence, không vòng đời, không idempotency.
enum ActionVendor {
  /// Ghi vào chính Tổng Tài.
  internal('internal'),

  /// **Chưa gửi đi đâu cả** — hành động được diễn tập trọn vòng đời trên máy,
  /// nhưng không có nền tảng ngoài nào nhận nó (WTM-303, Founder Task Order §7).
  ///
  /// Đây là một *vendor*, không phải một lá cờ, và đó là chủ ý: một cờ
  /// `isDemo` thì có đường bỏ qua khi hiển thị. Nơi thực thi là **trường bắt
  /// buộc** của mọi hành động, nên không màn nào quên mất nó được. Đổi sang
  /// Telegram thật về sau là đổi đúng một trường.
  demo('demo'),

  telegram('telegram'),

  /// Google — Drive hôm nay, Gmail/Calendar khi người bán bật (WTM-317).
  google('google'),

  /// Jira + Confluence — **một** vendor vì dùng chung một credential (WTM-319).
  atlassian('atlassian'),
  messenger('messenger'),
  shopee('shopee'),
  tiktokShop('tiktok_shop'),
  email('email');

  const ActionVendor(this.code);

  final String code;

  static ActionVendor? fromCode(String? code) {
    for (final v in ActionVendor.values) {
      if (v.code == code) return v;
    }
    return null;
  }
}

/// Mức rủi ro — quyết định hành động có được phép tự chạy không.
///
/// COMP AI **không có** trường này, và họ không cần: hành động tệ nhất của một
/// CRM là ghi sai chức danh, sửa mất năm giây. Hành động của Tổng Tài **tiêu
/// tiền thật của người bán**.
enum ActionRisk {
  /// Sai thì sửa được, không ai thiệt.
  low('low'),

  /// Người ngoài nhìn thấy, hoặc dữ liệu nghiệp vụ đổi.
  medium('medium'),

  /// Tiền, hoặc không hoàn tác được.
  high('high');

  const ActionRisk(this.code);

  final String code;

  static ActionRisk? fromCode(String? code) {
    for (final r in ActionRisk.values) {
      if (r.code == code) return r;
    }
    return null;
  }
}

/// Loại hành động — **từ vựng đóng**, `<miền>.<việc>`.
///
/// Mỗi loại mang sẵn [risk] và [neverAutoByDefault]: mức rủi ro là **thuộc
/// tính của việc**, không phải lựa chọn của người cấu hình.
enum BusinessActionType {
  // ── Ghi vào chính Tổng Tài ─────────────────────────────────────────────
  /// Áp dụng một `ProposedChange` đã được duyệt.
  applyProposedChange('proposal.apply', ActionRisk.low),

  /// Báo cho **chính chủ shop** qua kênh họ đã nối (WTM-318).
  ///
  /// `low` vì nó nhắn cho **người đã chủ động bật nó lên**, không nhắn cho
  /// khách. Đây là khác biệt quan trọng: `customerSendMessage` là `medium` vì
  /// nó chạm tới một người thứ ba; cái này chỉ chạm tới người đang cầm máy.
  ownerNotify('owner.notify', ActionRisk.low),

  /// Đưa một bản sao lưu lên kho ngoài (WTM-317).
  ///
  /// `low` vì nó **chỉ tạo thêm** một bản sao — không sửa, không xoá, không
  /// tiêu tiền. Hỏng thì thử lại; không ai thiệt.
  storageBackupUpload('storage.backup_upload', ActionRisk.low),

  // ── Khách hàng ─────────────────────────────────────────────────────────
  customerSendMessage('customer.send_message', ActionRisk.medium),

  /// Nhắn cho người **chưa từng mua**. Rủi ro spam ⇒ mất kênh, không chỉ mất
  /// một khách.
  customerSendColdMessage(
    'customer.send_cold_message',
    ActionRisk.high,
    neverAutoByDefault: true,
  ),

  /// Liên hệ người **ngoài danh bạ** — ranh giới riêng tư (D-4, không tài khoản).
  customerContactOutsideBook(
    'customer.contact_outside_book',
    ActionRisk.high,
    neverAutoByDefault: true,
  ),

  /// Xoá hoặc gộp bản ghi khách. Đã cấm bằng cấu trúc (ADR-TON-024 luật 4);
  /// có mặt ở đây để danh sách cấm **đầy đủ**, không phải để mở đường.
  customerMergeRecords(
    'customer.merge_records',
    ActionRisk.high,
    neverAutoByDefault: true,
  ),

  // ── Kho / mua hàng ─────────────────────────────────────────────────────
  inventoryCreatePurchaseOrder(
    'inventory.create_purchase_order',
    ActionRisk.high,
  ),

  /// Vượt hạn mức chi đã đặt. Tiền thật.
  inventoryOrderAboveLimit(
    'inventory.order_above_limit',
    ActionRisk.high,
    neverAutoByDefault: true,
  ),

  // ── Giá ────────────────────────────────────────────────────────────────
  /// Ảnh hưởng mọi đơn sau đó — người bán phải là người quyết.
  productUpdatePrice(
    'product.update_price',
    ActionRisk.high,
    neverAutoByDefault: true,
  ),

  // ── Tiền ───────────────────────────────────────────────────────────────
  /// Không hoàn tác được, và sai một lần là mất tiền thật.
  financeTransferMoney(
    'finance.transfer_money',
    ActionRisk.high,
    neverAutoByDefault: true,
  ),

  // ── Dữ liệu người bán tự nhập ──────────────────────────────────────────
  /// Nguyên tắc 3 — người thắng máy.
  overwriteSellerEnteredData(
    'data.overwrite_seller_entered',
    ActionRisk.high,
    neverAutoByDefault: true,
  ),

  // ── Marketing ──────────────────────────────────────────────────────────
  campaignPause('campaign.pause', ActionRisk.medium),
  campaignAdjustBudget('campaign.adjust_budget', ActionRisk.high);

  const BusinessActionType(
    this.code,
    this.risk, {
    this.neverAutoByDefault = false,
  });

  final String code;
  final ActionRisk risk;

  /// ⛔ **Tuyệt đối không tự chạy mặc định** — Founder duyệt 2026-08-08.
  ///
  /// Đây là **hằng số trong code kèm assert**, không phải một mặc định cấu
  /// hình: một mặc định thì sửa được bằng một lần bấm nhầm, một assert thì
  /// không.
  final bool neverAutoByDefault;

  static BusinessActionType? fromCode(String? code) {
    for (final t in BusinessActionType.values) {
      if (t.code == code) return t;
    }
    return null;
  }
}

/// Vòng đời thực thi.
///
/// Khác hẳn vòng đời của `ProposedChange` (WTM-299), và **cố ý không gộp**:
/// đề xuất là *đổi một sự thật* (hoàn tác bằng cách đổi trạng thái), hành động
/// là *một việc làm ra ngoài* (**có thể không hoàn tác được**).
enum ActionStatus {
  /// Đã dựng, chưa được phép chạy.
  planned('planned'),

  /// Đã được duyệt (người bấm, hoặc policy cho phép).
  approved('approved'),

  /// Đang chạy — mang lease.
  running('running'),

  succeeded('succeeded'),
  failed('failed'),
  cancelled('cancelled');

  const ActionStatus(this.code);

  final String code;

  static ActionStatus? fromCode(String? code) {
    for (final s in ActionStatus.values) {
      if (s.code == code) return s;
    }
    return null;
  }

  /// Trạng thái cuối — không đổi được nữa.
  bool get isTerminal =>
      this == ActionStatus.succeeded || this == ActionStatus.cancelled;

  /// Có thể nhận để chạy (kể cả chạy lại sau thất bại).
  bool get isClaimable =>
      this == ActionStatus.approved || this == ActionStatus.failed;
}

/// Mức tự chủ cho một cặp (capability, actionType).
///
/// Bốn mức khớp đúng bốn mức của Founder Vision.
enum AutonomyMode {
  /// L0 · AI đọc, không đề nghị.
  off('off'),

  /// L1 · tạo `ProposedChange`, không tạo action.
  suggest('suggest'),

  /// L2 · tạo action `planned`, chờ người bấm.
  confirm('confirm'),

  /// L3 · tự chạy **trong limits**.
  auto('auto');

  const AutonomyMode(this.code);

  final String code;

  static AutonomyMode? fromCode(String? code) {
    for (final m in AutonomyMode.values) {
      if (m.code == code) return m;
    }
    return null;
  }
}

/// Giới hạn cho chế độ [AutonomyMode.auto].
@immutable
class AutonomyLimits {
  const AutonomyLimits({this.maxPerPeriod, this.maxAmount, this.period});

  final int? maxPerPeriod;
  final double? maxAmount;
  final Duration? period;

  bool get isEmpty =>
      maxPerPeriod == null && maxAmount == null && period == null;
}

/// Luật tự chủ — **bốn trường, không phải một policy engine**.
///
/// Không có rule cho một cặp ⇒ mặc định [AutonomyMode.suggest]. Nghĩa là thêm
/// một loại hành động mới **không tự động được quyền chạy**.
@immutable
class AutonomyRule {
  /// Không `const`: assert phải đọc `actionType.neverAutoByDefault`, và một
  /// hằng số biên dịch không đọc được trường của đối tượng khác. Giữ assert
  /// quan trọng hơn giữ `const` — danh sách cấm phải chặn được ngay tại nơi
  /// dựng rule, không phải lúc chạy. (Cùng lựa chọn với `SuggestLink` WTM-291
  /// và `CanonicalEvent` WTM-294.)
  AutonomyRule({
    required this.actionType,
    required this.mode,
    this.limits = const AutonomyLimits(),
  }) : assert(
         mode != AutonomyMode.auto || !limits.isEmpty,
         'AUTO phải có giới hạn — một quyền tự chạy không giới hạn là một '
         'quyền không ai kiểm được',
       ),
       assert(
         mode != AutonomyMode.auto || !actionType.neverAutoByDefault,
         'loại hành động này nằm trong danh sách TUYỆT ĐỐI không auto '
         '(Founder duyệt 2026-08-08)',
       );

  final BusinessActionType actionType;
  final AutonomyMode mode;
  final AutonomyLimits limits;
}

/// Một việc **làm ra ngoài** — cửa ghi duy nhất cho mọi side effect của Agent.
///
/// ## Vì sao phải có cửa duy nhất, bằng chứng từ source
///
/// COMP AI có **ba** kỷ luật ghi song song: fact ledger (evidence + vòng đời),
/// ghi thẳng (không gì cả), `agentAction` (idempotency + vòng đời). Không
/// đường nào đủ cả ba. Và bề mặt **mới nhất** rơi vào đường **yếu nhất** —
/// `set_field_value` thêm 5 ngày sau ledger, bỏ qua hoàn toàn.
///
/// Lý do: họ có 24 file test, **0 file kiểm ranh giới**.
@immutable
class BusinessAction {
  const BusinessAction({
    required this.id,
    required this.type,
    required this.vendor,
    required this.subjectKind,
    required this.subjectId,
    required this.summary,
    required this.proposedBy,
    required this.idempotencyKey,
    required this.requestHash,
    required this.plannedAt,
    this.subjectLabel,
    this.parameters = const {},
    this.correlationId,
    this.requestedBy,
    this.status = ActionStatus.planned,
    this.attemptCount = 0,
    this.leasedUntil,
    this.startedAt,
    this.completedAt,
    this.externalId,
    this.errorCode,
    this.errorMessage,
  }) : assert(summary != '', 'hành động phải nói được nó làm gì'),
       assert(idempotencyKey != '', 'thiếu khoá chống lặp'),
       assert(
         status != ActionStatus.approved || requestedBy != null,
         'đã duyệt thì phải biết ai duyệt',
       );

  final String id;
  final String? correlationId;

  final BusinessActionType type;
  final ActionVendor vendor;

  final String subjectKind;
  final String subjectId;

  /// Nhãn người bán nhận ra.
  final String? subjectLabel;

  /// Câu tiếng Việt người bán đọc được — lưu cùng bản ghi, không dựng lúc hiển
  /// thị, để lời giải thích không lệch khỏi dữ liệu.
  final String summary;

  final Map<String, Object?> parameters;

  /// Ai đề nghị — `agent` · `rule:<tên>` · `seller`.
  final String proposedBy;

  /// Ai duyệt. `null` = **chưa ai duyệt**.
  final String? requestedBy;

  /// **Khoá chống lặp.** Cùng khoá + cùng payload ⇒ replay an toàn; cùng khoá +
  /// payload khác ⇒ **từ chối**.
  final String idempotencyKey;

  /// Vân tay của payload. Thiếu nó thì hai việc khác nhau lỡ trùng khoá sẽ
  /// **lặng lẽ nuốt nhau**.
  final String requestHash;

  final ActionStatus status;
  final int attemptCount;

  /// Hết hạn thì ai đó nhận lại được — kể cả khi tiến trình trước đã chết.
  final DateTime? leasedUntil;

  final DateTime plannedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  /// Mã của kết quả ở hệ ngoài. `null` = **chưa có kết quả**.
  final String? externalId;

  final String? errorCode;
  final String? errorMessage;

  ActionRisk get risk => type.risk;

  /// Mức tự chủ này có được phép chạy hành động này không.
  ///
  /// Hàm thuần — không đọc cấu hình, không chạm DB.
  static bool allowsAuto(BusinessActionType type, AutonomyMode mode) =>
      mode == AutonomyMode.auto && !type.neverAutoByDefault;

  BusinessAction copyWith({
    ActionStatus? status,
    String? requestedBy,
    int? attemptCount,
    DateTime? leasedUntil,
    DateTime? startedAt,
    DateTime? completedAt,
    String? externalId,
    String? errorCode,
    String? errorMessage,
  }) => BusinessAction(
    id: id,
    correlationId: correlationId,
    type: type,
    vendor: vendor,
    subjectKind: subjectKind,
    subjectId: subjectId,
    subjectLabel: subjectLabel,
    summary: summary,
    parameters: parameters,
    proposedBy: proposedBy,
    requestedBy: requestedBy ?? this.requestedBy,
    idempotencyKey: idempotencyKey,
    requestHash: requestHash,
    status: status ?? this.status,
    attemptCount: attemptCount ?? this.attemptCount,
    leasedUntil: leasedUntil ?? this.leasedUntil,
    plannedAt: plannedAt,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt ?? this.completedAt,
    externalId: externalId ?? this.externalId,
    errorCode: errorCode ?? this.errorCode,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  bool operator ==(Object other) => other is BusinessAction && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'BusinessAction(${type.code} @${vendor.code} [${status.code}])';
}
