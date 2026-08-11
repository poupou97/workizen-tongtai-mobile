import 'dart:ui' show Locale;

/// # ⛔ Phase 2 ship ĐÚNG MỘT locale giao diện — WTM-308
///
/// ## Vì sao không phải chuyện dịch thiếu
///
/// Trên máy đặt tiếng Anh, màn Tổng Tài đọc ra thế này:
///
/// ```
/// Good afternoon
/// 4 things worth your attention today
///  · Duy Trần đã 77 ngày chưa quay lại
///  · Máy pha cà phê mini đã hết hàng
/// ```
///
/// Nhãn theo máy, **nội dung theo dữ liệu**. Và nội dung không dịch được: câu
/// brief chứa tên khách và con số của chính doanh nghiệp này, rồi được **lưu
/// cùng bản ghi** (`ProposedChange.summary` · `BusinessAction.summary` ·
/// `AgentTask.reason`).
///
/// Kỷ luật đó có lý do — WTM-299: *"cấu hình và lời giải thích của nó phải đi
/// cùng nhau, nếu không bản dịch sẽ lệch khỏi dữ liệu."* Dựng lại câu theo
/// locale lúc hiển thị sẽ khiến mở một quyết định cũ đọc ra **câu khác câu lúc
/// bấm**.
///
/// ## Nên bỏ nửa nào
///
/// Bỏ nửa tiếng Anh. Người bán SME Việt Nam là người dùng, `CLAUDE.md` đã ghi
/// *"UI chỉ một locale"* (ADR-TON-007), và một giao diện tiếng Anh úp lên nội
/// dung tiếng Việt là **một bản dịch dở dang bày ra cho người dùng**.
///
/// `AppStringsEn` **giữ nguyên trong mã**: ngày thêm một thị trường là một
/// quyết định sản phẩm thật, và lúc đó bộ chuỗi đã sẵn ở đây. Cái bị bỏ là
/// việc **để máy tự chọn hộ**.
const String kAppLocaleCode = 'vi';

/// Locale duy nhất của giao diện.
const Locale kAppLocale = Locale(kAppLocaleCode);
