/// Durable Agent — mô hình việc, **độc lập với nơi chạy** (WTM-301 · D-4).
///
/// ## ⭐ Điều kiện của Founder, và nó nằm ngay ở dòng import
///
/// > *"V1 có thể chạy khi Mobile/Compute runtime hoạt động, nhưng domain/task
/// > model **không được phụ thuộc vòng đời mobile**. Cùng một task về sau phải
/// > chạy được trên Workizen Managed Worker / Oracle VM 24/7 mà **không đổi
/// > business model**."*
///
/// File này **không import `package:flutter`**. Không `WidgetsBinding`, không
/// `AppLifecycleState`, không `WorkManager`. Đó không phải sở thích — nó là
/// hợp đồng, và `durable_task_is_location_independent_test` canh nó.
///
/// Phép thử thật: nếu logic nhận việc chạy được trong một test **thuần Dart**,
/// thì nó chạy được trên worker. "Ai chạy" là **cấu hình**, không phải mô hình.
library;

import 'package:meta/meta.dart';

/// Loại việc — **từ vựng đóng**.
///
/// `reason` đi kèm mỗi việc được viết cho **người đọc**, không phải cho log.
/// Đó là thứ đi thẳng vào lời nhắn cho agent và vào màn hình người bán.
enum AgentTaskKind {
  /// Đối chiếu một danh tính ngoài với danh bạ khách.
  identify('identify'),

  /// Xem lại một bản ghi sau một khoảng thời gian.
  recheck('recheck'),

  /// Đọc nhịp giao hàng từ connector (dogfood Workizen).
  deliveryPulse('delivery_pulse'),

  /// Tính lại lợi nhuận thật khi có dữ liệu đối soát mới.
  settlementReview('settlement_review'),

  /// Rà tồn kho và dự báo.
  inventoryReview('inventory_review');

  const AgentTaskKind(this.code);

  final String code;

  static AgentTaskKind? fromCode(String? code) {
    for (final k in AgentTaskKind.values) {
      if (k.code == code) return k;
    }
    return null;
  }
}

/// Kết cục của một việc.
enum AgentTaskOutcome {
  completed('completed'),

  /// Hết lượt thử. Không phải "thất bại một lần" — là **thôi không thử nữa**.
  retired('retired'),

  /// Không còn đối tượng để làm.
  obsolete('obsolete');

  const AgentTaskOutcome(this.code);

  final String code;

  static AgentTaskOutcome? fromCode(String? code) {
    for (final o in AgentTaskOutcome.values) {
      if (o.code == code) return o;
    }
    return null;
  }
}

/// Số lần thử tối đa trước khi cho một việc nghỉ hưu.
const int kMaxAgentTaskAttempts = 4;

/// Thời hạn giữ việc mặc định.
///
/// Hết hạn ⇒ ai đó nhận lại được. Đây là thứ làm cho *"tiến trình chết"* và
/// *"app bị kill"* thành **cùng một tình huống** — và đó chính là lý do mô hình
/// này chạy được ở cả hai nơi.
const Duration kAgentTaskLease = Duration(minutes: 10);

/// Một việc bền vững.
///
/// ## Không trường nào mang nghĩa "mobile"
///
/// Không `appSessionId`, không `isForeground`, không `workManagerId`. Nếu có
/// một trường như vậy thì đổi runner sẽ phải đổi bảng — và điều kiện của
/// Founder gãy.
@immutable
class AgentTask {
  const AgentTask({
    required this.id,
    required this.kind,
    required this.reason,
    required this.dueAt,
    required this.createdAt,
    this.correlationId,
    this.subjectKind,
    this.subjectId,
    this.priority = 0,
    this.budget = 4,
    this.attempts = 0,
    this.leasedUntil,
    this.startedAt,
    this.finishedAt,
    this.outcome,
  }) : assert(reason != '', 'một việc không lý do là một việc không ai hiểu');

  final String id;
  final String? correlationId;

  final AgentTaskKind kind;

  /// **Viết cho người đọc.**
  ///
  /// *"Khách này 45 ngày chưa mua"*, không phải *"scheduled recheck"*. Nó đi
  /// vào lời nhắn cho agent và vào màn hình người bán — nên nó là dữ liệu, không
  /// phải log.
  final String reason;

  final String? subjectKind;
  final String? subjectId;

  /// Khi nào **đến hạn**. Quá khứ = sẵn sàng chạy.
  final DateTime dueAt;

  /// Việc ưu tiên cao chạy trước khi cùng đến hạn.
  final int priority;

  /// Số lượt gọi vendor lần chạy này được tiêu.
  ///
  /// Đếm **lượt gọi**, không đếm tiền — đủ cho việc nghiên cứu. Hành động tiêu
  /// tiền đi qua `BusinessAction` (WTM-300) và có `limits` riêng.
  final int budget;

  final int attempts;

  /// Ai đó đang giữ việc này tới lúc nào. `null` = **không ai giữ**.
  final DateTime? leasedUntil;

  final DateTime createdAt;
  final DateTime? startedAt;

  /// `null` = **chưa xong**, không phải "xong lúc 0".
  final DateTime? finishedAt;

  final AgentTaskOutcome? outcome;

  bool get isFinished => finishedAt != null;

  /// Đã hết lượt thử chưa.
  bool get isExhausted => attempts >= kMaxAgentTaskAttempts;

  /// Có thể nhận việc này tại thời điểm [now] không.
  ///
  /// **Hàm thuần** — đây là trái tim của giao thức, và nó cố ý không biết gì về
  /// cơ sở dữ liệu lẫn nơi chạy. Cùng một luật đúng cho runner trong app và
  /// cho worker trên máy chủ.
  bool isClaimableAt(DateTime now) {
    if (isFinished) return false;
    if (isExhausted) return false;
    if (dueAt.isAfter(now)) return false;
    final lease = leasedUntil;
    return lease == null || lease.isBefore(now);
  }

  /// Lời nhắn cho agent ở lần thử này.
  ///
  /// Lần thử ≥ 2 được dặn **tiếp tục**, không làm lại — thread của phiên vẫn
  /// còn, nên thử lại rẻ.
  String briefFor(int attempt) {
    if (attempt <= 1) return reason;
    return 'Đây là lần thử thứ $attempt; lần trước chưa xong. '
        'Tiếp tục từ những gì đã có, đừng bắt đầu lại. $reason';
  }

  AgentTask copyWith({
    int? attempts,
    DateTime? leasedUntil,
    DateTime? startedAt,
    DateTime? finishedAt,
    AgentTaskOutcome? outcome,
    DateTime? dueAt,
  }) => AgentTask(
    id: id,
    correlationId: correlationId,
    kind: kind,
    reason: reason,
    subjectKind: subjectKind,
    subjectId: subjectId,
    dueAt: dueAt ?? this.dueAt,
    priority: priority,
    budget: budget,
    attempts: attempts ?? this.attempts,
    leasedUntil: leasedUntil ?? this.leasedUntil,
    createdAt: createdAt,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt ?? this.finishedAt,
    outcome: outcome ?? this.outcome,
  );

  @override
  bool operator ==(Object other) => other is AgentTask && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AgentTask(${kind.code} due=$dueAt attempts=$attempts)';
}

/// Thứ tự chạy: ưu tiên cao trước, cùng ưu tiên thì đến hạn sớm trước.
///
/// Hàm thuần, tách khỏi SQL — để runner nào cũng sắp xếp giống nhau, kể cả
/// runner không dùng SQL.
int compareAgentTaskPriority(AgentTask a, AgentTask b) {
  final byPriority = b.priority.compareTo(a.priority);
  if (byPriority != 0) return byPriority;
  return a.dueAt.compareTo(b.dueAt);
}
