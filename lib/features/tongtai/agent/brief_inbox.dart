import '../action/business_action.dart';
import '../action/business_action_executor.dart';
import '../proposal/proposal_gate.dart';
import '../proposal/proposed_change.dart';
import '../proposal/proposed_change_repository.dart';
import 'agent_task.dart';
import 'agent_task_queue.dart';
import 'business_brief.dart';

/// Người bán đã quyết gì về một việc.
///
/// `null` ở [BriefInbox.statusOf] nghĩa là **chưa từng ghi nhận** — khác hẳn
/// "đã bỏ qua". Hai thứ đó mà gộp lại thì một việc bị bỏ qua sẽ quay lại mỗi
/// sáng, và người bán sẽ thôi đọc brief.
enum BriefDecision {
  /// Đang chờ người bán.
  pending('pending'),

  /// Đã đồng ý — đề xuất `applied`, hoặc hành động đã duyệt/đã chạy.
  accepted('accepted'),

  /// Đã bỏ qua.
  dismissed('dismissed'),

  /// Hẹn xem lại sau.
  postponed('postponed');

  const BriefDecision(this.code);

  final String code;
}

/// Kết quả một lần ghi brief xuống máy.
class PublishReport {
  const PublishReport({
    required this.proposals,
    required this.actions,
    required this.skipped,
  });

  /// Số đề xuất đổi sự thật được lưu.
  final int proposals;

  /// Số hành động được dựng ở trạng thái `planned`.
  final int actions;

  /// Số việc **cổng từ chối** — đã bỏ qua, đã áp dụng, hoặc bằng chứng yếu.
  /// Bị từ chối là chuyện bình thường, không phải lỗi.
  final int skipped;

  int get total => proposals + actions;
}

/// Nơi các việc trong brief **trở thành bản ghi có vòng đời** — WTM-303.
///
/// ## Vì sao brief phải đi qua đây, không hiển thị thẳng
///
/// Một brief chỉ để đọc thì mỗi sáng lại nói y hệt: người bán bỏ qua một việc
/// hôm nay, mai nó quay lại. Sau ba ngày họ thôi đọc.
///
/// Cái làm brief thành *trợ lý* thay vì *bảng thông báo* là **quyết định được
/// ghi lại**. Và quyết định đã có sẵn hai chỗ ở, không cần bảng thứ sáu:
///
/// | Việc | Ở đâu | Vòng đời |
/// |---|---|---|
/// | [ChangeAFact] | `ProposedChange` | proposed → applied / dismissed |
/// | [DoSomething] | `BusinessAction` | planned → approved → succeeded |
/// | *Để sau* | `AgentTask` | hẹn lại, tự nổi lên đúng ngày |
///
/// ## Ghi lúc dựng brief, không lúc bấm
///
/// Hành động được dựng ngay ở trạng thái `planned` — *đã dựng, chưa được phép
/// chạy*. Đó đúng nghĩa `AutonomyMode.confirm`, và nó là lý do trạng thái sống
/// qua một lần tắt/mở app: người bán mở lại thấy đúng ba việc đang chờ, không
/// phải một brief dựng lại từ đầu quên mất họ đã bỏ qua cái nào.
class BriefInbox {
  const BriefInbox({
    required this.proposals,
    required this.actions,
    required this.tasks,
  });

  final ProposedChangeRepository proposals;
  final BusinessActionExecutor actions;
  final AgentTaskQueue tasks;

  /// Hẹn lại bao lâu khi người bán chọn *Để sau*.
  static const int kPostponeDays = 7;

  /// Ghi mọi việc bấm được xuống máy. **Tự chạy lại được** — id tất định nên
  /// gọi hai lần không sinh ra hai bản ghi.
  Future<PublishReport> publish(List<BriefItem> items) async {
    var proposed = 0;
    var planned = 0;
    var skipped = 0;

    for (final item in items) {
      switch (item.move) {
        case null:
          // Việc chỉ để biết. Không có gì để ghi, và cũng không có gì để bỏ
          // qua — nó biến mất khi tình trạng thay đổi.
          break;

        case ChangeAFact(
          :final domain,
          :final field,
          :final currentValue,
          :final proposedValue,
        ):
          final outcome = await proposals.propose(
            ProposedChange(
              id: item.id,
              correlationId: item.correlationId,
              domain: domain,
              subjectKind: item.subjectKind,
              subjectId: item.subjectId,
              subjectLabel: item.subjectLabel,
              field: field,
              currentValue: currentValue,
              proposedValue: proposedValue,
              evidence: item.evidence,
              proposedBy: ProposalAuthor.rule(item.kind.code),
              summary: item.suggestion,
              createdAt: item.observedAt,
              provenance: item.provenance,
            ),
            // Giá bán là một **quyết định kinh doanh**, không phải một sự thật
            // người bán khẳng định. Cổng 3 sinh ra để bảo vệ thứ họ khẳng định
            // — tên khách, địa chỉ — khỏi bị máy ghi đè. Coi mọi ô người bán
            // từng chạm vào là "của họ, cấm bàn" sẽ làm im mọi lời khuyên,
            // gồm cả lời khuyên duy nhất họ cần nghe.
            humanOwnsField: false,
          );
          if (outcome is ProposalAccepted) {
            proposed++;
          } else {
            skipped++;
          }

        case DoSomething(:final actionType, :final vendor, :final parameters):
          await actions.plan(
            BusinessAction(
              id: item.id,
              correlationId: item.correlationId,
              type: actionType,
              vendor: vendor,
              subjectKind: item.subjectKind,
              subjectId: item.subjectId,
              subjectLabel: item.subjectLabel,
              summary: item.suggestion,
              parameters: parameters,
              proposedBy: 'rule:${item.kind.code}',
              // Khoá chống lặp = chính id tất định của việc. Cùng một chuyện
              // ⇒ cùng khoá ⇒ dựng lại không sinh việc thứ hai.
              idempotencyKey: item.id,
              requestHash: BusinessActionExecutor.hashRequest(parameters),
              plannedAt: item.observedAt,
            ),
          );
          planned++;
      }
    }

    return PublishReport(
      proposals: proposed,
      actions: planned,
      skipped: skipped,
    );
  }

  /// Người bán đã quyết gì về việc này. `null` = chưa có bản ghi nào.
  ///
  /// Thứ tự hai bước quan trọng: **trạng thái của bản ghi trước, lời hẹn sau**.
  /// Một việc đã đồng ý cũng sinh ra lời hẹn xem lại, nên hỏi lời hẹn trước sẽ
  /// báo "để sau" cho đúng những việc người bán vừa làm xong.
  Future<BriefDecision?> statusOf(BriefItem item) async {
    final base = await _recordedDecision(item);
    if (base != BriefDecision.pending) return base;
    return await _hasOpenRecheck(item)
        ? BriefDecision.postponed
        : BriefDecision.pending;
  }

  Future<BriefDecision?> _recordedDecision(BriefItem item) async {
    switch (item.move) {
      case null:
        return null;

      case ChangeAFact():
        final row = await _proposalFor(item);
        return switch (row?.status) {
          null => null,
          ProposalStatus.proposed => BriefDecision.pending,
          ProposalStatus.applied => BriefDecision.accepted,
          ProposalStatus.dismissed => BriefDecision.dismissed,
          ProposalStatus.superseded => null,
        };

      case DoSomething():
        final row = await actions.byId(item.id);
        return switch (row?.status) {
          null => null,
          ActionStatus.planned => BriefDecision.pending,
          ActionStatus.cancelled => BriefDecision.dismissed,
          _ => BriefDecision.accepted,
        };
    }
  }

  Future<bool> _hasOpenRecheck(BriefItem item) async {
    final open = await tasks.loadByCorrelation(item.correlationId);
    return open.any((t) => !t.isFinished);
  }

  /// **Đồng ý.**
  ///
  /// ## Cả hai nhánh đều đi qua `BusinessAction`, và đó là điểm mấu chốt
  ///
  /// Duyệt một đề xuất giá là **ghi vào cơ sở dữ liệu của chính Tổng Tài**.
  /// Rất dễ nghĩ rằng ghi vào nhà mình thì khỏi cần đi cửa — đó đúng là chỗ
  /// COMP AI hụt (`set_field_value` bỏ qua cả vòng đời lẫn chống lặp).
  ///
  /// Nên `proposals.apply` chỉ ghi lại **quyết định**; giá trị vào bản ghi
  /// qua một `BusinessAction(applyProposedChange, vendor: internal)` — cùng
  /// transaction, cùng lease, cùng khoá chống lặp như mọi hành động khác.
  ///
  /// Chạy ngay sau khi bấm chứ không chờ vòng runner kế: người bán vừa bấm
  /// xong mà màn hình chưa đổi là một app hỏng, dù bản ghi có đúng.
  Future<ActionRunResult?> accept(BriefItem item) async {
    switch (item.move) {
      case null:
        return null;

      case ChangeAFact(:final field, :final proposedValue):
        final applied = await proposals.apply(item.id);
        if (!applied) return null;

        final parameters = <String, Object?>{
          'field': field,
          'value': proposedValue,
        };
        await actions.plan(
          BusinessAction(
            id: 'apply:${item.id}',
            correlationId: item.correlationId,
            type: BusinessActionType.applyProposedChange,
            vendor: ActionVendor.internal,
            subjectKind: item.subjectKind,
            subjectId: item.subjectId,
            subjectLabel: item.subjectLabel,
            summary: item.suggestion,
            parameters: parameters,
            proposedBy: 'rule:${item.kind.code}',
            idempotencyKey: 'apply:${item.id}',
            requestHash: BusinessActionExecutor.hashRequest(parameters),
            plannedAt: item.observedAt,
          ),
        );
        return _approveAndRun('apply:${item.id}', item);

      case DoSomething():
        return _approveAndRun(item.id, item);
    }
  }

  Future<ActionRunResult?> _approveAndRun(String id, BriefItem item) async {
    final refused = await actions.approve(id, requestedBy: 'seller');
    if (refused != null) return refused;
    final result = await actions.run(id);
    // Hẹn xem lại **chỉ khi việc thật sự xong**. Hẹn sau một lần thất bại là
    // hứa với người bán rằng có thứ đang chạy, trong khi không có gì cả.
    if (result is ActionSucceeded) await _scheduleRecheck(item);
    return result;
  }

  /// **Bỏ qua.** Không hành động nào được dựng, và việc không quay lại — luật
  /// xét lại theo miền quyết định bao giờ mới được hỏi lại (WTM-299).
  Future<void> dismiss(BriefItem item) async {
    switch (item.move) {
      case null:
        return;
      case ChangeAFact():
        await proposals.dismiss(item.id);
      case DoSomething():
        await actions.cancel(item.id);
    }
    // Lời hẹn xem lại mất đối tượng — `obsolete`, không phải `completed`.
    // "Không còn gì để làm" và "đã làm xong" là hai câu chuyện khác nhau, và
    // màn Hoạt động kể lại đúng cái nào xảy ra.
    for (final task in await tasks.loadByCorrelation(item.correlationId)) {
      if (!task.isFinished) {
        await tasks.finish(task.id, AgentTaskOutcome.obsolete);
      }
    }
  }

  /// **Để sau.** Việc giữ nguyên trạng thái chờ và tự nổi lên lại sau
  /// [kPostponeDays] ngày — người bán không phải nhớ.
  Future<AgentTask> postpone(BriefItem item, {int days = kPostponeDays}) =>
      tasks.scheduleRecheck(
        reason: 'Xem lại: ${item.headline}',
        days: days,
        subjectKind: item.subjectKind,
        subjectId: item.subjectId,
        correlationId: item.correlationId,
      );

  Future<ProposedChange?> _proposalFor(BriefItem item) async {
    final rows = await proposals.loadByCorrelation(item.correlationId);
    for (final row in rows) {
      if (row.id == item.id) return row;
    }
    return null;
  }

  Future<void> _scheduleRecheck(BriefItem item) => tasks.scheduleRecheck(
    reason: 'Kết quả của: ${item.headline}',
    days: kPostponeDays,
    subjectKind: item.subjectKind,
    subjectId: item.subjectId,
    correlationId: item.correlationId,
  );
}
