/// **Tổng Tài đang hiểu doanh nghiệp** — WTM-353 (S4, Epic WTM-349).
///
/// ## Đây là chỗ dễ thành sân khấu nhất trong cả sản phẩm
///
/// Một thanh tiến trình chạy theo `Duration` cố định, kể cả khi không có dữ
/// liệu, là **diễn**. Nó cũng là thứ dễ viết nhất và trông đẹp nhất, nên nó là
/// cám dỗ thật chứ không phải một khả năng lý thuyết.
///
/// Cách file này chặn điều đó là **cấu trúc, không phải kỷ luật**: mỗi dòng
/// tiến trình được **sinh ra bởi chính công việc đã xong**, không phải được lên
/// lịch chạy song song với nó. Không có chỗ nào để đặt một con số trước khi
/// việc tạo ra nó chạy — muốn bịa thì phải sửa kiểu dữ liệu.
///
/// ```
/// tải sản phẩm  → phát (products, products.length)
/// tải đơn hàng  → phát (orders,   orders.length)
/// tải khách     → phát (customers,customers.length)
/// quét tồn kho  → phát (stock,    số mặt hàng đã xét)
/// chạy luật     → phát (signals,  số phát hiện)
/// ```
///
/// ## Đường B không đi qua đây
///
/// Máy trạng thái đã chặn ở `stagesFor` (WTM-350). Nếu vì lý do nào đó vẫn gọi
/// tới, [AnalysisPipeline.run] phát ra số đếm **thật** — tức là 0 — chứ không
/// phát ra một con số đẹp. Không có nhánh "nếu rỗng thì giả vờ".
library;

import 'package:flutter/foundation.dart';

import '../consumer/customer.dart';
import '../inventory/product.dart';
import '../inventory/stock_alert_service.dart';
import '../orders/order.dart';
import 'first_insight.dart';
import 'first_insight_input.dart';

/// Chặng nào của việc hiểu doanh nghiệp.
enum AnalysisStage {
  products('products'),
  orders('orders'),
  customers('customers'),
  stock('stock'),
  signals('signals');

  const AnalysisStage(this.code);

  final String code;
}

/// Một chặng **đã xong**, kèm số bản ghi thật nó vừa xử lý.
@immutable
class AnalysisProgress {
  const AnalysisProgress({required this.stage, required this.count});

  final AnalysisStage stage;

  /// Số bản ghi thật. Không có đường nào để giá trị này là một hằng số: nó
  /// luôn là `length` của thứ vừa tải hoặc vừa quét.
  final int count;

  @override
  String toString() => 'AnalysisProgress(${stage.code}=$count)';
}

/// Kết quả cuối — các chặng đã chạy, và kết luận.
@immutable
class AnalysisRun {
  const AnalysisRun({required this.stages, required this.insight});

  final List<AnalysisProgress> stages;
  final FirstInsight insight;

  int countOf(AnalysisStage stage) =>
      stages.firstWhere((s) => s.stage == stage).count;
}

/// Nơi pipeline lấy dữ liệu.
///
/// Ba hàm tải đầu tương ứng ba chặng **đếm được**, nên chúng phải tách rời —
/// gộp lại thành một lời gọi thì ba dòng tiến trình chỉ còn là ba lát cắt của
/// một con số, và đó là bước đầu tiên trên đường về lại sân khấu.
///
/// [assemble] gom nốt phần còn lại (RFM, rủi ro, cảnh báo, đối soát). Nó cố ý
/// **không** phải một chặng: người bán không đọc "đang tải dòng đối soát", và
/// dựng một dòng cho nó chỉ để thanh dài thêm là trang trí.
abstract interface class AnalysisSource {
  Future<List<Product>> loadProducts();
  Future<List<CustomerOrder>> loadOrders();
  Future<List<Customer>> loadCustomers();

  Future<FirstInsightInput> assemble({
    required DateTime now,
    required List<Product> products,
    required List<CustomerOrder> orders,
    required List<Customer> customers,
  });
}

class AnalysisPipeline {
  const AnalysisPipeline({
    required this.source,
    this.engine = const FirstInsightEngine(),
  });

  final AnalysisSource source;
  final FirstInsightEngine engine;

  /// Chạy, phát tiến trình khi mỗi chặng **xong**.
  ///
  /// Không `Future.delayed`, không `Duration`. Chạy xong nhanh thì màn hình
  /// được phép làm mượt chuyển cảnh — nhưng đó là việc của màn hình, và trạng
  /// thái nghiệp vụ ở đây vẫn đúng.
  Stream<AnalysisProgress> run({
    required DateTime now,
    required void Function(AnalysisRun) onDone,
  }) async* {
    final stages = <AnalysisProgress>[];

    AnalysisProgress step(AnalysisStage stage, int count) {
      final p = AnalysisProgress(stage: stage, count: count);
      stages.add(p);
      return p;
    }

    final products = await source.loadProducts();
    yield step(AnalysisStage.products, products.length);

    final orders = await source.loadOrders();
    yield step(AnalysisStage.orders, orders.length);

    final customers = await source.loadCustomers();
    yield step(AnalysisStage.customers, customers.length);

    // Quét tồn kho là việc thật: `StockAlertService` là chủ duy nhất của khái
    // niệm "sắp hết hàng" (WTM-213), nên chặng này gọi nó chứ không tự đếm.
    final alerts = StockAlertService(products).alerts;
    yield step(AnalysisStage.stock, alerts.length);

    final input = await source.assemble(
      now: now,
      products: products,
      orders: orders,
      customers: customers,
    );
    final insight = engine.analyse(input);
    yield step(AnalysisStage.signals, insight.findings.length);

    onDone(AnalysisRun(stages: List.unmodifiable(stages), insight: insight));
  }
}
