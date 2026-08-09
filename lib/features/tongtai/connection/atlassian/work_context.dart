import 'package:flutter/foundation.dart';

import 'atlassian_client.dart';

/// **Công việc đang thế nào** — Capability Context của Jira (ADR-TON-016).
///
/// ## ⛔ Đây KHÔNG phải Jira mobile client
///
/// Founder viết thẳng: *không board, không sprint, không backlog.* Ý định là
/// một câu trả lời cho một câu hỏi:
///
/// > *"Tổng Tài, cho tôi biết công việc Workizen đang thế nào."*
///
/// Nên thứ đi ra khỏi lớp này là **một dòng tóm tắt** cộng vài con số truy
/// được — không phải một danh sách issue để vuốt.
///
/// ## Đếm theo `statusCategory`, không theo tên cột
///
/// Tên cột mỗi project một kiểu (`ANALYSIS` · `Ready` · `Code Review`…) và ai
/// cũng đổi được từ giao diện Jira. `statusCategory` chỉ có ba giá trị và
/// Atlassian giữ ổn định. Đếm theo tên cột là đếm theo một thứ sẽ đổi mà không
/// ai báo — và con số sẽ sai âm thầm.
@immutable
class WorkContext {
  const WorkContext({
    required this.projectKey,
    required this.open,
    required this.inProgress,
    required this.doneThisWeek,
    required this.highPriorityOpen,
    required this.stale,
    required this.observedAt,
  });

  /// Dựng từ issue thật. Hàm thuần — không mạng, không DB, test được thẳng.
  factory WorkContext.derive({
    required String projectKey,
    required List<AtlassianIssue> issues,
    required DateTime now,
    Set<String> highPriorityNames = const {'Highest', 'High', 'P0', 'P1'},
    Duration staleAfter = const Duration(days: 14),
  }) {
    final weekAgo = now.subtract(const Duration(days: 7));
    final staleBefore = now.subtract(staleAfter);

    var open = 0;
    var inProgress = 0;
    var doneThisWeek = 0;
    var highPriorityOpen = 0;
    var stale = 0;

    for (final issue in issues) {
      if (issue.isDone) {
        final updated = issue.updatedAt;
        // `null` ⇒ **không đếm**. Không biết xong lúc nào thì không nói được
        // nó xong tuần này — đoán ở đây là bịa một con số cho Founder đọc.
        if (updated != null && updated.isAfter(weekAgo)) doneThisWeek++;
        continue;
      }
      open++;
      if (issue.isInProgress) inProgress++;
      if (issue.priority != null &&
          highPriorityNames.contains(issue.priority)) {
        highPriorityOpen++;
      }
      final updated = issue.updatedAt;
      if (updated != null && updated.isBefore(staleBefore)) stale++;
    }

    return WorkContext(
      projectKey: projectKey,
      open: open,
      inProgress: inProgress,
      doneThisWeek: doneThisWeek,
      highPriorityOpen: highPriorityOpen,
      stale: stale,
      observedAt: now,
    );
  }

  final String projectKey;

  /// Chưa xong — mọi thứ không ở `done`.
  final int open;

  final int inProgress;

  /// Xong trong bảy ngày gần nhất. Issue `done` mà **không có** mốc cập nhật
  /// thì không được đếm ở đây.
  final int doneThisWeek;

  final int highPriorityOpen;

  /// Đang mở mà hai tuần không ai đụng — thứ hay bị quên nhất.
  final int stale;

  final DateTime observedAt;

  /// Không có issue nào ⇒ **chưa kết luận được**, khác "mọi thứ đều ổn".
  ///
  /// Cùng kỷ luật Rule Twin (ADR-TON-016): từ chối trả lời khi thiếu dữ liệu
  /// là một câu trả lời, và nó khác hẳn với một câu trả lời lạc quan.
  bool get hasData => open + doneThisWeek > 0;

  /// Một câu, bằng ngôn ngữ người đọc — không có mã issue, không có tên cột.
  ///
  /// Trả `null` khi chưa đủ dữ liệu. Chỗ gọi hiện trạng thái *insufficient*,
  /// **không** hiện "0 việc đang mở".
  String? get headline {
    if (!hasData) return null;
    final parts = <String>[
      if (open > 0) '$open việc đang mở',
      if (inProgress > 0) '$inProgress đang làm',
      if (highPriorityOpen > 0) '$highPriorityOpen ưu tiên cao',
      if (stale > 0) '$stale bỏ quên trên hai tuần',
      if (doneThisWeek > 0) '$doneThisWeek xong tuần này',
    ];
    return '$projectKey: ${parts.join(' · ')}';
  }
}
