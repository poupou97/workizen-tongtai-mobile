import 'agent_task.dart';
import 'agent_task_queue.dart';

/// Kết quả một lượt chạy — con số để **hiện lên màn hình**, không phải để log.
class AgentRunReport {
  const AgentRunReport({
    required this.claimed,
    required this.completed,
    required this.retired,
  });

  static const AgentRunReport none = AgentRunReport(
    claimed: 0,
    completed: 0,
    retired: 0,
  );

  /// Số việc đến hạn được nhận lượt này.
  final int claimed;

  /// Số việc làm xong.
  final int completed;

  /// Số việc **thôi không thử nữa** (hết lượt).
  final int retired;

  bool get didSomething => claimed > 0 || retired > 0;
}

/// **Runner V1** — chạy khi app đang mở (WTM-307 · Founder Task Order §12).
///
/// ## Cố ý tối thiểu, và cố ý KHÔNG chạy nền
///
/// Không 24/7 · không Oracle worker · không background service. Mục tiêu duy
/// nhất là Founder **nhìn thấy** một việc đi trọn vòng trên máy mình:
///
/// ```
/// scheduled → claimed → processed → recheck
/// ```
///
/// ## Vì sao đây chỉ là "đổi runner", không phải "đổi kiến trúc"
///
/// Mô hình việc đã độc lập với nơi chạy từ WTM-301: giao thức nhận việc là một
/// hàm thuần trên model, và cả suite bằng chứng chạy bằng `package:test` không
/// có Flutter binding nào. Nên lớp này chỉ trả lời câu *"ai gọi `claimDue`"* —
/// đổi nó về sau **không đụng bảng, không đụng luật**.
///
/// ## Lượt chạy này làm gì với một việc
///
/// V1 xử lý loại `recheck` bằng cách **đánh dấu đã xem lại**. Nghe như không
/// làm gì — nhưng thứ thật sự làm việc là động cơ brief: nó dựng lại từ dữ
/// liệu **hiện tại** mỗi lần đọc. Nếu khách đã quay lại mua thì việc biến mất
/// khỏi brief; nếu chưa thì nó xuất hiện lại với con số mới.
///
/// Nói cách khác: *"xem lại"* ở Tổng Tài không phải chạy một truy vấn riêng —
/// nó là **cho phép sự thật hiện tại nói lại**. Một runner tự đi tính lại sẽ
/// là đường dẫn xuất thứ hai, đúng thứ P-27 cấm.
class AgentRunner {
  const AgentRunner(this._tasks, {this.batch = 5});

  final AgentTaskQueue _tasks;

  /// Bao nhiêu việc mỗi lượt. Nhỏ có chủ ý: một lượt chạy lúc mở app không
  /// được giữ giao diện lại.
  final int batch;

  /// Chạy một lượt: nghỉ hưu việc hết lượt thử, rồi nhận và xử lý việc đến hạn.
  ///
  /// Thứ tự quan trọng — nghỉ hưu **trước**, nếu không một việc đã hết lượt sẽ
  /// bị nhận thêm một lần nữa ở chính lượt này và con số báo cáo sẽ nói dối.
  Future<AgentRunReport> runOnce() async {
    final retired = await _tasks.retireExhausted();
    final claimed = await _tasks.claimDue(limit: batch);

    var completed = 0;
    for (final task in claimed) {
      final outcome = await _process(task);
      if (outcome != null && await _tasks.finish(task.id, outcome)) {
        completed++;
      }
    }

    return AgentRunReport(
      claimed: claimed.length,
      completed: completed,
      retired: retired,
    );
  }

  /// `null` = **để nguyên** cho lượt sau.
  ///
  /// Không đóng một việc mình chưa biết cách làm: lease hết hạn thì nó tự
  /// quay lại, còn đóng nhầm thì nó biến mất khỏi câu chuyện vĩnh viễn.
  Future<AgentTaskOutcome?> _process(
    AgentTask task,
  ) async => switch (task.kind) {
    // Đánh dấu đã xem lại. Dữ liệu hiện tại tự nói phần còn lại — xem doc lớp.
    AgentTaskKind.recheck => AgentTaskOutcome.completed,
    AgentTaskKind.identify => AgentTaskOutcome.completed,

    // Ba loại này cần connector hoặc capability chưa có. Để nguyên còn hơn
    // đóng chúng với một kết cục mình không thật sự đạt được.
    AgentTaskKind.deliveryPulse ||
    AgentTaskKind.settlementReview ||
    AgentTaskKind.inventoryReview => null,
  };
}
