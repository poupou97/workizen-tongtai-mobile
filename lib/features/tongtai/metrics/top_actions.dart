/// **Top Actions** — một chủ duy nhất cho câu *"hôm nay đáng làm gì"* (WTM-388).
///
/// ## Vì sao thứ này phải tồn tại
///
/// Trên Nokia 6.1, Trang chủ nói **ba con số** cùng lúc:
///
/// > *"Hôm nay tôi tìm được **43 cơ hội** cho bạn."*
/// > *"Có **17 việc** đáng chú ý hôm nay"*
/// > *"**Chưa có nhiệm vụ nào**"*
///
/// Người bán không biết mình có 43 việc, 17 việc, hay không việc nào. Ba con số
/// ấy đến từ ba nguồn khác nhau — bộ luật cơ hội, bộ tín hiệu brief, và danh
/// sách nhiệm vụ hành trình — và **không ai sở hữu câu trả lời cuối cùng**.
///
/// Đúng hình dạng P-27/P-28 quen thuộc: một khái niệm (*"hôm nay làm gì"*),
/// nhiều chủ, và màn hình là nơi mâu thuẫn lộ ra.
///
/// ## Quyết định Founder (2026-08-12)
///
/// > Home gom về **một** Top Action count. Opportunities/signals là **nguồn
/// > phía sau**, không cạnh tranh KPI trên Home.
///
/// Nên: nguồn vẫn có bao nhiêu tuỳ nó; **Home chỉ nói một con số**, và con số
/// ấy là *"bao nhiêu việc đáng làm nhất hôm nay"* — đã cắt ngưỡng.
///
/// ## ⛔ Cắt ngưỡng KHÔNG phải giấu bớt
///
/// 43 cơ hội vẫn còn nguyên ở tab Cơ hội. Thứ đổi là **Home thôi ném cả 43 vào
/// mặt người bán** rồi để họ tự chọn. Một danh sách 43 mục không phải sự minh
/// bạch — nó là việc đẩy phần khó nhất (chọn cái nào) sang phía người ít thời
/// gian nhất.
library;

/// Bao nhiêu việc là *"đáng làm nhất hôm nay"*.
///
/// Năm: đủ để một buổi sáng có việc mà làm, và đủ ít để người bán đọc hết
/// trước khi mở cửa hàng. Con số này là một **quyết định sản phẩm**, nên nó
/// nằm ở đây có tên, không nằm rải trong các màn.
const int kTopActionsLimit = 5;

/// Trang chủ đang ở trạng thái nào — ba trạng thái, không có trạng thái thứ tư.
///
/// Giữ đúng ba nghĩa của ADR-TON-017, và **khác biệt giữa hai trạng thái cuối
/// là thứ quan trọng nhất**: *"hôm nay không có gì"* là một phán quyết về công
/// việc; *"chưa đủ dữ liệu"* là một phán quyết về **dữ liệu**. Nói nhầm cái thứ
/// hai thành cái thứ nhất là chê doanh nghiệp của người ta trong khi lỗi nằm ở
/// chỗ app chưa có gì để nhìn.
enum TopActionsState {
  /// Có việc đáng làm — [TopActions.count] là số thật, đã cắt ngưỡng.
  hasWork,

  /// Đã nhìn, và hôm nay không có gì nổi lên. Một câu trả lời thật.
  noneToday,

  /// Chưa đủ dữ liệu để nhìn.
  notEnoughData,
}

/// Câu trả lời duy nhất Trang chủ được phép nói về *"hôm nay làm gì"*.
class TopActions {
  const TopActions._(this.state, this.count, this.available);

  /// Gộp các nguồn thành **một** câu trả lời.
  ///
  /// [signalCount] là số việc bộ luật thấy đáng chú ý (cơ hội + tín hiệu
  /// brief). [hasData] đến từ `BusinessContext` — chủ duy nhất của câu hỏi
  /// *"doanh nghiệp này đã có gì chưa"*.
  factory TopActions.from({
    required int signalCount,
    required bool hasData,
    int limit = kTopActionsLimit,
  }) {
    final available = signalCount < 0 ? 0 : signalCount;
    if (available == 0) {
      // ⛔ Không có việc **không** đồng nghĩa không có dữ liệu. Phân biệt hai
      // câu này là điều đầu tiên một người dùng mới nhìn thấy.
      return TopActions._(
        hasData ? TopActionsState.noneToday : TopActionsState.notEnoughData,
        0,
        0,
      );
    }
    final capped = available < limit ? available : limit;
    return TopActions._(TopActionsState.hasWork, capped, available);
  }

  final TopActionsState state;

  /// Con số Trang chủ nói ra — **đã cắt ngưỡng**, luôn ≤ [kTopActionsLimit].
  final int count;

  /// Tổng số việc nguồn thấy, trước khi cắt. Dùng cho lối *"xem tất cả"*, và
  /// **không** được hiện thành một con số thứ hai cạnh [count] trên Home.
  final int available;

  bool get hasWork => state == TopActionsState.hasWork;

  /// Còn bao nhiêu việc nằm sau lối *"xem tất cả"*.
  int get remaining => available - count;
}
