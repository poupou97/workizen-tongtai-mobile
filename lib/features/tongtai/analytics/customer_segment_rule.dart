import '../capability/customer_capability.dart';
import '../consumer/customer_segment.dart';
import 'customer_rfm.dart';

/// **Phân khúc khách suy ra từ đơn hàng thật** — WTM-419 (concept-1 `cp4` #7).
///
/// `ANALYSIS.md` chốt: *"RFM từ đơn thật; khách chưa mua ⇒ không xếp phân
/// khúc"*.
///
/// ## Vì sao luật này KHÔNG đẻ ngưỡng mới
///
/// App đã có một chủ cho câu hỏi *"khách này đang ở đâu trong vòng đời"*:
/// [customerLifecycleStage], thang **1,0× / 1,5× / 3,0× nhịp mua của chính
/// khách đó**. Điểm rủi ro khách hàng neo vào đúng thang ấy để hai con số cạnh
/// nhau không bao giờ nói ngược nhau.
///
/// Nên luật này **mượn nguyên** thang đó và chỉ thêm đúng hai câu hỏi mà vòng
/// đời không trả lời được:
///
///   * *mua bao nhiêu lần rồi* — phân biệt "mua một lần" với "quay lại" với
///     "trung thành";
///   * *chi tiêu so với phần còn lại của tệp* — phân biệt VIP.
///
/// Đẻ một thang thứ hai ở đây là cách chắc chắn để hai màn nói hai chuyện về
/// cùng một khách (P-41: một ngưỡng khai ở bốn chỗ, chỉ một chỗ có thật).
///
/// ## ⛔ Khách chưa mua KHÔNG được xếp phân khúc
///
/// `null`, không phải "khách mới". Một liên hệ trong danh bạ chưa từng mua thì
/// mọi tín hiệu RFM đều **vắng**, không phải bằng 0 — xếp họ vào "khách mới" là
/// biến một ô trống thành một lời khẳng định, và nó thổi phồng đúng con số
/// người bán dùng để đánh giá mình đang có bao nhiêu khách.
///
/// ## Còn `dormant` thì sao
///
/// [CustomerSegment.dormant] ("lâu chưa quay lại") **không** do luật này sinh
/// ra. Nó chồng lấn với `atRisk`/`churned` mà không có ranh giới nào rút ra
/// được từ dữ liệu, nên nó chỉ tồn tại như nhãn **đến từ nguồn ngoài** (file
/// nhập, hệ thống cũ). Bịa một ranh giới cho nó là thêm một chủ thứ hai đúng
/// vào chỗ vừa dọn.

/// Số đơn tối thiểu để gọi là **trung thành**.
///
/// Ba, vì ba là con số nhỏ nhất chứng minh một **nhịp**: mua, quay lại, rồi
/// quay lại nữa. Hai đơn mới chỉ là một lần lặp — có thể do khuyến mãi, có thể
/// do tình cờ. Đây là chỗ duy nhất trong luật này có một con số do người chọn;
/// mọi ngưỡng còn lại đều mượn từ vòng đời.
const int kCustomerLoyalMinOrders = 3;

/// Ngưỡng chi tiêu để gọi là **VIP**: nhóm 20% chi nhiều nhất của tệp.
///
/// Là **phân vị**, không phải một số tiền cố định: một shop bán áo và một shop
/// bán máy móc không thể chung một mốc "VIP" tính bằng đồng.
const double kCustomerVipQuantile = 0.8;

/// Số khách đã mua tối thiểu để "top 20%" có nghĩa gì đó.
///
/// Dưới mốc này **không ai là VIP**. Với 2 khách, "nhóm 20% chi nhiều nhất"
/// không phải một phát biểu về hạng — nó chỉ là "người chi nhiều hơn", và gọi
/// người ấy là VIP là phong hạng cho một mẫu chưa đủ để có hạng.
const int kCustomerVipMinBuyers = 5;

/// Phân khúc cho **cả tệp** — cần cả tệp vì VIP là câu hỏi so sánh.
///
/// Khoá vắng mặt trong kết quả nghĩa là khách chưa mua ⇒ **không xếp**.
Map<String, CustomerSegment> customerSegmentsFrom({
  required List<CustomerRfm> profiles,
  required DateTime now,
}) {
  final buyers = [
    for (final p in profiles)
      if (p.hasOrders) p,
  ];
  if (buyers.isEmpty) return const {};

  // Phân vị tính TRÊN NGƯỜI ĐÃ MUA. Gộp cả người chưa mua (chi tiêu 0) sẽ kéo
  // mốc xuống và biến một khách trung bình thành VIP.
  //
  // ⚠️ `infinity` = không ai là VIP, và đó là câu trả lời đúng ở hai trường
  // hợp: tệp quá nhỏ để có hạng, hoặc mọi người chi như nhau. Bản đầu dùng
  // `>=` trên một tệp phẳng và phong VIP cho **toàn bộ** tệp — con số vô
  // nghĩa nhất có thể in ra một màn quản trị khách hàng.
  final vipFloor = buyers.length < kCustomerVipMinBuyers
      ? double.infinity
      : (CustomerRfmService.monetaryQuantiles(buyers, const [
              kCustomerVipQuantile,
            ]).firstOrNull ??
            double.infinity);

  return {
    for (final p in buyers)
      p.customerId: _segmentOf(p, now: now, vipFloor: vipFloor),
  };
}

CustomerSegment _segmentOf(
  CustomerRfm profile, {
  required DateTime now,
  required double vipFloor,
}) {
  // Vòng đời trả lời trước: một khách đã rời bỏ thì việc họ từng mua 10 lần
  // không làm họ thành "trung thành" ở thì hiện tại.
  switch (customerLifecycleStage(profile)) {
    case CustomerLifecycleStage.neverPurchased:
      // Không tới được: `buyers` đã lọc. Giữ nhánh để enum còn đủ.
      return CustomerSegment.newcomer;
    case CustomerLifecycleStage.churned:
      return CustomerSegment.churned;
    case CustomerLifecycleStage.atRisk:
      return CustomerSegment.atRisk;
    case CustomerLifecycleStage.cooling:
      return CustomerSegment.slowing;
    case CustomerLifecycleStage.active:
      break;
  }

  if (profile.frequency <= 1) {
    // Mua đúng một lần: "mới" hay "một lần" phụ thuộc đơn ấy cách đây bao lâu.
    return isNewCustomer(profile, now: now)
        ? CustomerSegment.newcomer
        : CustomerSegment.oneTime;
  }
  if (profile.frequency >= kCustomerLoyalMinOrders) {
    // So sánh NGẶT: nếu cả tệp chi bằng nhau thì mốc trùng giá trị chung, và
    // `>=` sẽ phong VIP cho tất cả. Chi bằng nhau nghĩa là không ai nổi bật.
    return profile.monetary > vipFloor
        ? CustomerSegment.vip
        : CustomerSegment.loyal;
  }
  return CustomerSegment.returning;
}

/// Đếm theo phân khúc — thứ màn Khách hàng cần để dựng thẻ.
Map<CustomerSegment, int> customerSegmentTally({
  required List<CustomerRfm> profiles,
  required DateTime now,
}) {
  final tally = <CustomerSegment, int>{};
  for (final segment in customerSegmentsFrom(
    profiles: profiles,
    now: now,
  ).values) {
    tally[segment] = (tally[segment] ?? 0) + 1;
  }
  return tally;
}
