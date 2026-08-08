import 'package:flutter/foundation.dart';

import '../action/business_action.dart';
import '../action/demo_action_handlers.dart';
import '../proposal/proposed_change.dart';
import 'agent_task.dart';

/// **"Tổng Tài đã làm gì"** — WTM-305 (trải nghiệm #5).
///
/// ## Không phải log của lập trình viên
///
/// Founder Task Order §10 nói rõ điều đó. Nên mỗi dòng ở đây là một câu tiếng
/// Việt về **nghiệp vụ**, và nó đến từ một bản ghi thật — `ProposedChange`,
/// `BusinessAction`, `AgentTask`. Không dòng nào được dựng từ hư không, và
/// không dòng nào chứa tên bảng, mã lỗi hay id kỹ thuật.
///
/// ## Hai loại dòng, và cả hai đều truy được về dữ liệu
///
/// | Loại | Từ đâu |
/// |---|---|
/// | *"đã xem 26 khách"* | số bản ghi mà động cơ brief thật sự đã đọc |
/// | *"bạn duyệt: nâng giá…"* | một bản ghi có vòng đời |
///
/// Loại đầu dễ biến thành lời khoe suông. Nên nó lấy **đúng** con số động cơ
/// brief đã đọc, không phải một con số đẹp hơn.

/// Sắc thái của một dòng — quyết định biểu tượng và màu, không quyết định chữ.
enum ActivityTone {
  /// Đã xong, không cần ai làm gì.
  done,

  /// Có thứ đáng chú ý.
  attention,

  /// Đang chờ người bán.
  waiting,
}

@immutable
class ActivityEntry {
  const ActivityEntry({
    required this.at,
    required this.tone,
    required this.text,
    this.correlationId,
    this.isDemo = false,
  });

  final DateTime at;
  final ActivityTone tone;

  /// Câu người bán đọc. **Dữ liệu**, không phải nhãn giao diện — nó chứa tên
  /// và con số của chính doanh nghiệp này.
  final String text;

  /// Nối về chuỗi việc đã sinh ra dòng này. Không hiện ra màn hình; có ở đây
  /// để một dòng bấm được sẽ mở đúng câu chuyện.
  final String? correlationId;

  /// Việc chưa ra khỏi máy này.
  final bool isDemo;

  @override
  String toString() => 'ActivityEntry(${tone.name} $text)';
}

/// Dựng dòng thời gian hoạt động — **hàm thuần** trên các bản ghi đã có.
class AgentActivityService {
  const AgentActivityService();

  /// [customersScanned] / [productsScanned] là số bản ghi động cơ brief **thật
  /// sự đã đọc** lượt gần nhất. Truyền 0 khi chưa chạy lượt nào — và 0 thì
  /// **không** sinh ra dòng nào, chứ không phải sinh ra "đã xem 0 khách".
  List<ActivityEntry> build({
    required DateTime now,
    List<ProposedChange> proposals = const [],
    List<BusinessAction> actions = const [],
    List<AgentTask> tasks = const [],
    int customersScanned = 0,
    int productsScanned = 0,
  }) {
    // `nonNulls` là chỗ các dòng "không kể" biến mất. Trả `null` chứ không
    // trả một dòng rỗng: một dòng rỗng lọt ra màn hình là một khoảng trắng
    // không ai giải thích được.
    final entries = <ActivityEntry?>[
      ..._scanEntries(now, customersScanned, productsScanned),
      ..._proposalEntries(proposals),
      ..._actionEntries(actions),
      ..._taskEntries(now, tasks),
    ].nonNulls.toList()..sort((a, b) => b.at.compareTo(a.at));

    return List.unmodifiable(entries);
  }

  // ── Đã xem gì ────────────────────────────────────────────────────────────

  Iterable<ActivityEntry> _scanEntries(
    DateTime now,
    int customers,
    int products,
  ) sync* {
    if (customers > 0) {
      yield ActivityEntry(
        at: now,
        tone: ActivityTone.done,
        text: 'Đã xem $customers khách hàng',
      );
    }
    if (products > 0) {
      yield ActivityEntry(
        at: now,
        tone: ActivityTone.done,
        text: 'Đã kiểm $products mặt hàng',
      );
    }
  }

  // ── Đề xuất ──────────────────────────────────────────────────────────────

  Iterable<ActivityEntry?> _proposalEntries(
    List<ProposedChange> proposals,
  ) sync* {
    for (final p in proposals) {
      final subject = p.subjectLabel;
      // Ngày của một dòng là ngày **việc đó xảy ra**: lúc quyết nếu đã quyết,
      // lúc đề nghị nếu chưa. Dùng `createdAt` cho cả hai sẽ xếp một quyết
      // định hôm nay xuống dưới một đề xuất tuần trước.
      final at = p.decidedAt ?? p.createdAt;
      yield switch (p.status) {
        ProposalStatus.proposed => ActivityEntry(
          at: at,
          tone: ActivityTone.waiting,
          text: 'Đang chờ bạn: ${p.summary}',
          correlationId: p.correlationId,
        ),
        ProposalStatus.applied => ActivityEntry(
          at: at,
          tone: ActivityTone.done,
          text: subject == null
              ? 'Bạn đã duyệt: ${p.summary}'
              : 'Bạn đã duyệt thay đổi cho $subject',
          correlationId: p.correlationId,
        ),
        ProposalStatus.dismissed => ActivityEntry(
          at: at,
          tone: ActivityTone.done,
          text: 'Bạn đã bỏ qua: ${p.summary}',
          correlationId: p.correlationId,
        ),
        // Bị một đề xuất mới hơn thay thế — không phải chuyện người bán làm,
        // nên nó không thuộc câu chuyện của họ.
        ProposalStatus.superseded => null,
      };
    }
  }

  // ── Hành động ────────────────────────────────────────────────────────────

  Iterable<ActivityEntry?> _actionEntries(List<BusinessAction> actions) sync* {
    for (final a in actions) {
      final at = a.completedAt ?? a.plannedAt;
      final demo = a.vendor == ActionVendor.demo || isDemoResult(a.externalId);
      final what = a.subjectLabel ?? a.summary;

      yield switch (a.status) {
        // `planned` đã được kể ở phía đề xuất hoặc ở brief; kể lại ở đây chỉ
        // làm dòng thời gian dài ra mà không thêm thông tin nào.
        ActionStatus.planned => null,
        ActionStatus.approved || ActionStatus.running => ActivityEntry(
          at: at,
          tone: ActivityTone.waiting,
          text: 'Đang làm: ${a.summary}',
          correlationId: a.correlationId,
          isDemo: demo,
        ),
        ActionStatus.succeeded => ActivityEntry(
          at: at,
          tone: ActivityTone.done,
          text: demo ? 'Đã diễn tập: ${a.summary}' : 'Đã làm: ${a.summary}',
          correlationId: a.correlationId,
          isDemo: demo,
        ),
        ActionStatus.failed => ActivityEntry(
          at: at,
          tone: ActivityTone.attention,
          text: 'Chưa làm được: ${a.summary}',
          correlationId: a.correlationId,
          isDemo: demo,
        ),
        ActionStatus.cancelled => ActivityEntry(
          at: at,
          tone: ActivityTone.done,
          text: 'Bạn đã bỏ qua: $what',
          correlationId: a.correlationId,
        ),
      };
    }
  }

  // ── Việc hẹn lại ─────────────────────────────────────────────────────────

  Iterable<ActivityEntry?> _taskEntries(
    DateTime now,
    List<AgentTask> tasks,
  ) sync* {
    for (final t in tasks) {
      if (t.isFinished) {
        yield switch (t.outcome) {
          AgentTaskOutcome.completed => ActivityEntry(
            at: t.finishedAt!,
            tone: ActivityTone.done,
            text: 'Đã xem lại: ${t.reason}',
            correlationId: t.correlationId,
          ),
          // "Hết lượt thử" và "không còn gì để làm" là hai chuyện khác nhau,
          // và chỉ chuyện đầu đáng để người bán biết.
          AgentTaskOutcome.retired => ActivityEntry(
            at: t.finishedAt!,
            tone: ActivityTone.attention,
            text: 'Tôi thử mấy lần nhưng chưa xong: ${t.reason}',
            correlationId: t.correlationId,
          ),
          AgentTaskOutcome.obsolete || null => null,
        };
        continue;
      }
      yield ActivityEntry(
        at: t.createdAt,
        tone: ActivityTone.waiting,
        text: 'Sẽ xem lại ${_when(now, t.dueAt)}: ${t.reason}',
        correlationId: t.correlationId,
      );
    }
  }

  /// *"trong 7 ngày"* / *"hôm nay"* — khoảng, không phải một mốc ISO.
  static String _when(DateTime now, DateTime due) {
    final days = due.difference(now).inDays;
    if (days <= 0) return 'hôm nay';
    if (days == 1) return 'ngày mai';
    return 'trong $days ngày';
  }
}
