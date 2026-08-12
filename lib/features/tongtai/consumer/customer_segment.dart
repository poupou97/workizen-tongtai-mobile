/// **Phân khúc khách hàng** — WTM-381.
///
/// ## Vì sao thứ này phải tồn tại
///
/// `Customer.segments` là `List<String>` **tự do**, và nó có **hai chủ** cùng
/// ghi vào: bộ sinh dữ liệu lịch sử ghi **nhãn hiển thị tiếng Việt**, còn bộ
/// nhập XLSX ghi **ô của bảng tính nguyên văn** — tức là mã máy. Màn Khách hàng
/// in ra nguyên xi thứ nó nhận được.
///
/// Trên máy thật (Nokia 6.1) người bán nhìn thấy **mười một** chip, trong đó có
/// `new`, `one_time`, `vip`, `dormant`, `returning` — và tệ hơn: *"Khách mới
/// (6)"* đứng ngay cạnh *"new (8)"*. Cùng một phân khúc, hai cái tên, **hai con
/// số**. Người bán không thể biết mình có 6 hay 8 khách mới.
///
/// Đó không phải lỗi hiển thị. Đó là **Business Truth mâu thuẫn trên một màn
/// hình** — và nguyên nhân là hình dạng P-27/P-28 quen thuộc: một khái niệm,
/// hai chủ.
///
/// ## Cách chữa: một bộ từ vựng ĐÓNG
///
/// Mã canonical để **lưu** (ADR-TON-018: enum lưu bằng mã, cấm nhãn hiển thị),
/// nhãn để **hiện** (ADR-TON-007: UI một locale, chuỗi đi qua một chỗ).
///
/// [CustomerSegment.parse] cố ý nhận **cả nhãn tiếng Việt cũ**: dữ liệu đã seed
/// trên máy người dùng đang mang nhãn hiển thị, và bắt họ nạp lại chỉ để sửa
/// một cái tên là đổi giá phải trả sang phía sai người. Dữ liệu cũ **tự lành
/// lúc đọc**, không cần migration.
///
/// ⛔ Chuỗi **không** phân giải được thì vẫn hiện nguyên văn — đó là phân khúc
/// người dùng tự đặt, và im lặng nuốt nó đi còn tệ hơn in ra một mã máy.
library;

enum CustomerSegment {
  newcomer('new'),
  returning('returning'),
  loyal('loyal'),
  vip('vip'),
  oneTime('one_time'),
  slowing('slowing'),
  atRisk('at_risk'),
  dormant('dormant'),
  churned('churned');

  const CustomerSegment(this.code);

  /// Mã canonical — thứ **được lưu**, và thứ mọi nguồn dữ liệu quy về.
  final String code;

  String get labelVi => switch (this) {
    CustomerSegment.newcomer => 'Khách mới',
    CustomerSegment.returning => 'Khách quay lại',
    CustomerSegment.loyal => 'Khách trung thành',
    CustomerSegment.vip => 'Khách VIP',
    CustomerSegment.oneTime => 'Mới mua một lần',
    CustomerSegment.slowing => 'Đang giảm nhịp',
    CustomerSegment.atRisk => 'Nguy cơ rời bỏ',
    CustomerSegment.dormant => 'Lâu chưa quay lại',
    CustomerSegment.churned => 'Đã rời bỏ',
  };

  String get labelEn => switch (this) {
    CustomerSegment.newcomer => 'New customer',
    CustomerSegment.returning => 'Returning',
    CustomerSegment.loyal => 'Loyal',
    CustomerSegment.vip => 'VIP',
    CustomerSegment.oneTime => 'Bought once',
    CustomerSegment.slowing => 'Slowing down',
    CustomerSegment.atRisk => 'At risk',
    CustomerSegment.dormant => 'Dormant',
    CustomerSegment.churned => 'Churned',
  };

  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;

  /// Phân giải một chuỗi bất kỳ về phân khúc canonical, hoặc `null` khi đó là
  /// chữ của chính người dùng.
  ///
  /// Nhận ba dạng, và **phải** nhận cả ba:
  ///
  /// * mã canonical (`new`, `one_time`) — thứ nay được ghi xuống;
  /// * nhãn tiếng Việt (`Khách mới`) — thứ đã nằm sẵn trong máy người dùng;
  /// * vài biến thể tiếng Anh hay gặp trong bảng tính người bán tự xuất.
  static CustomerSegment? parse(String raw) {
    final key = raw.trim().toLowerCase();
    if (key.isEmpty) return null;
    for (final s in CustomerSegment.values) {
      if (key == s.code ||
          key == s.labelVi.toLowerCase() ||
          key == s.labelEn.toLowerCase()) {
        return s;
      }
    }
    return switch (key) {
      // Biến thể hay gặp — mỗi dòng là một thứ đã thấy trong dữ liệu thật,
      // không phải phỏng đoán cho đẹp danh sách.
      'new customer' ||
      'newcomer' ||
      'khách hàng mới' => CustomerSegment.newcomer,
      'one time' || 'onetime' || 'single purchase' => CustomerSegment.oneTime,
      'inactive' || 'khách ngủ đông' => CustomerSegment.dormant,
      'at risk' || 'atrisk' || 'rủi ro' => CustomerSegment.atRisk,
      'lost' || 'churn' => CustomerSegment.churned,
      'loyal customers' || 'khách thân thiết' => CustomerSegment.loyal,
      'slowing' || 'slowing down' => CustomerSegment.slowing,
      _ => null,
    };
  }

  /// Chuẩn hoá một chuỗi để **lưu**: mã canonical nếu nhận ra, còn không thì
  /// giữ nguyên văn của người dùng (đã cắt khoảng trắng thừa).
  static String normalise(String raw) => parse(raw)?.code ?? raw.trim();

  /// Nhãn để **hiện**: nhãn canonical nếu nhận ra, còn không thì nguyên văn.
  static String display(String raw, String languageCode) =>
      parse(raw)?.label(languageCode) ?? raw.trim();
}
