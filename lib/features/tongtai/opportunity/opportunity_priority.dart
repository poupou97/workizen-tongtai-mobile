import 'opportunity.dart';

/// Mức ưu tiên hiển thị trên mỗi dòng "Việc Tổng Tài đề xuất" (WTM-404).
///
/// ## ⛔ Vì sao KHÔNG phải ngưỡng điểm tuyệt đối
///
/// Cách hiển nhiên là cắt thang điểm: `≥70 ⇒ Cao`, `≥40 ⇒ Trung bình`. Nó sai,
/// và tài liệu của chính [OpportunityScore] nói vì sao:
///
/// - Điểm được xây từ **bốn** yếu tố, nhưng hai trong bốn (*chất lượng nhà
///   cung cấp*, *mức cạnh tranh*) **không tính được trên máy này** — cộng
///   **30% trọng số** luôn vắng mặt. `coverage` báo đúng điều đó.
/// - Một điểm 61 với `coverage = 0.7` **không cùng đơn vị** với một điểm 61 đủ
///   bốn yếu tố. Dán nhãn *"Ưu tiên: Trung bình"* lên nó là khẳng định một độ
///   chính xác mà phép đo không có — đúng lớp lỗi ADR-TON-016 cấm (*Rule Twin
///   không được bịa số khi thiếu dữ liệu*).
///
/// ## Luật thật: **thứ hạng**, không phải độ lớn
///
/// Tài liệu của [OpportunityScore] nói thẳng điểm sinh ra để **xếp thứ tự**
/// ("sort by relevance"). Thứ hạng là đúng thứ nó chống đỡ được: *"trong những
/// việc hôm nay, đây là việc đáng làm trước nhất"* — một câu không cần tới 30%
/// trọng số đang vắng.
///
/// Nên chip đọc **vị trí trong danh sách đã sắp xếp** mà Trang chủ đang hiện,
/// và [unknown] khi cơ hội **không chấm được điểm nào** (`score.value == null`)
/// — cùng lý do WTM-193 hiện dấu `—` thay vì số 0: không biết ≠ vô giá trị.
enum OpportunityPriority {
  /// Việc đứng đầu danh sách đang hiện.
  high,

  /// Việc thứ hai.
  medium,

  /// Từ thứ ba trở đi.
  low,

  /// Không chấm được điểm ⇒ không xếp hạng được.
  unknown;

  /// Mức ưu tiên của [opportunity] khi nó đứng ở vị trí [rank] (0 = đầu) trong
  /// danh sách **đã sắp theo điểm** mà người bán đang nhìn.
  ///
  /// ⚠️ [rank] phải là vị trí trong danh sách ĐANG HIỆN, không phải trong toàn
  /// bộ kho cơ hội: chip nói *"đáng làm trước nhất trong những việc này"*, và
  /// đó là câu duy nhất nó chứng minh được.
  static OpportunityPriority at(Opportunity opportunity, int rank) {
    if (opportunity.score.value == null) return unknown;
    return switch (rank) {
      0 => high,
      1 => medium,
      _ => low,
    };
  }
}
