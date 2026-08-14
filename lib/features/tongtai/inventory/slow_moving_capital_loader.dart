import '../commerce/commerce_profit.dart';
import 'product.dart';
import 'slow_moving_capital.dart';

/// Nạp **vốn đang chôn trong hàng chậm bán** cho màn Kho — WTM-411.
///
/// ## Vì sao có `catch` ở đây, và vì sao nó KHÔNG nằm trong `ui/`
///
/// ADR-TON-017 cấm bắt lỗi thủ công trong `ui/`: mỗi màn có **một** trạng thái,
/// và mỗi màn tự chế cách báo lỗi riêng là cách app mất tính nhất quán.
///
/// Nhưng thẻ này là **phần phụ đứng trên danh sách chính**. Nó cần đơn hàng để
/// biết món nào đã bán; danh sách sản phẩm thì không. Nếu để lỗi đọc đơn hàng
/// truyền lên trạng thái màn, thì một sự cố ở nguồn dữ liệu *phụ* sẽ xoá sạch
/// danh mục — người bán mở Kho ra và không thấy hàng của mình, chỉ vì phần
/// tính "vốn chôn" không đọc được.
///
/// Nên quy tắc là: **thẻ phụ tự biến mất, danh sách chính vẫn sống**. Chỗ duy
/// nhất được phép nuốt lỗi là đây — một tệp miền, ngoài `ui/`, có tên nói rõ
/// nó làm gì, và chỉ nuốt đúng một loại phụ thuộc.
///
/// ⚠️ KHÔNG mở rộng ngoại lệ này. Nếu ngày nào đó thẻ trở thành nội dung chính
/// của màn, lỗi của nó phải nổi lên như mọi lỗi khác.
Future<SlowMovingCapital> loadSlowMovingCapital({
  required Future<CommerceProfitContext> profit,
  required Iterable<Product> products,
}) async {
  final CommerceProfitContext context;
  try {
    context = await profit;
  } on Object {
    // Không đọc được đơn hàng ⇒ không biết món nào đã bán ⇒ **không đoán**.
    // `none` làm thẻ tự ẩn; nó không hiện một con số dựng từ giả định.
    return SlowMovingCapital.none;
  }

  return SlowMovingCapital.from(
    products: products,
    soldProductIds: {for (final p in context.byProduct) p.productId},
    // Cửa sổ lấy từ chính bối cảnh, không viết cứng — đúng luật "một chủ cho
    // ngưỡng" của `SlowMovingCapital`.
    windowDays: context.to.difference(context.from).inDays,
  );
}
