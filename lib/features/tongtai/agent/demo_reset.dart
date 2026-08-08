import '../action/business_action_executor.dart';
import '../proposal/proposed_change_repository.dart';
import '../sample/historical_data_generator.dart';
import 'agent_task_queue.dart';

/// Kết quả một lần đặt lại — để màn hình nói được **cái gì đã bị xoá**.
class DemoResetReport {
  const DemoResetReport({
    required this.proposals,
    required this.actions,
    required this.tasks,
  });

  final int proposals;
  final int actions;
  final int tasks;

  int get decisions => proposals + actions + tasks;
}

/// **Đặt lại dữ liệu mẫu** — WTM-307 (Founder Task Order §14).
///
/// > *"Founder phải có một cách đơn giản: Reset Demo Business → seed lại đúng
/// > dữ liệu ban đầu. Không phải uninstall/reinstall app."*
///
/// ## Vì sao gieo lại thôi là chưa đủ
///
/// Từ WTM-303, một lượt brief để lại **quyết định** — đề xuất, hành động, lời
/// hẹn. Gieo lại dữ liệu mẫu mà giữ chúng thì lần thử thứ hai sẽ mở ra với
/// *"bạn đã bỏ qua việc này"*, và Founder không bao giờ thấy lại được flow từ
/// đầu.
///
/// Nên đặt lại phải dọn **cả hai**: dữ liệu nghiệp vụ mẫu và các quyết định
/// nói về nó.
///
/// ## ⭐ Và chỉ dọn thứ thuộc về dữ liệu mẫu
///
/// Ba kho ở đây xoá theo `subjectId` bắt đầu bằng `sample-`, không phải
/// `deleteAll`. Người bán có thể vừa có dữ liệu mẫu vừa có khách thật — đặt
/// lại demo mà cuốn theo quyết định họ đã ra cho khách thật là mất dữ liệu.
class DemoResetService {
  const DemoResetService({
    required this.history,
    required this.proposals,
    required this.actions,
    required this.tasks,
  });

  final HistoricalDataSeeder history;
  final ProposedChangeRepository proposals;
  final BusinessActionExecutor actions;
  final AgentTaskQueue tasks;

  /// Dọn quyết định cũ rồi gieo lại — **theo thứ tự đó**.
  ///
  /// Gieo trước rồi dọn sau sẽ có một khoảnh khắc dữ liệu mới đứng cạnh quyết
  /// định cũ, và nếu bước dọn hỏng giữa chừng thì đó là trạng thái người bán ở
  /// lại: dữ liệu ban đầu, nhưng mang tiền sử của lần chơi trước.
  Future<DemoResetReport> reset({
    HistoricalDataSpec spec = const HistoricalDataSpec(),
  }) async {
    final report = DemoResetReport(
      proposals: await proposals.deleteForSampleSubjects(),
      actions: await actions.deleteForSampleSubjects(),
      tasks: await tasks.deleteForSampleSubjects(),
    );
    await history.seed(spec);
    return report;
  }
}
