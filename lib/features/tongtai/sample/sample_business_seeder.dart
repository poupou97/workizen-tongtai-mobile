import '../commerce/commerce_models.dart';
import '../commerce/commerce_repository.dart';
import '../consumer/customer_repository.dart';
import '../finance/settlement_repository.dart';
import '../orders/order_repository.dart';
import '../commerce/import/commerce_import.dart';
import '../commerce/import/commerce_importer.dart';
import 'historical_data_generator.dart';
import 'sample_data_seeder.dart';

/// **Một doanh nghiệp mẫu, một nút** — WTM-343.
///
/// ## Ba chủ cho một khái niệm
///
/// Trước đây có ba đường nạp dữ liệu mẫu, và chúng **đè lên nhau**:
///
/// | Đường | Cho ra | Vấn đề |
/// |---|---|---|
/// | *Nạp dữ liệu mẫu* | vài chục bản ghi viết tay | bị đường dưới xoá sạch |
/// | *Nạp dữ liệu mẫu 12 tháng* | 12 tháng lịch sử | gọi `removeAll()` trước, nên xoá luôn đường trên |
/// | *Nhập dữ liệu cửa hàng → bộ mẫu* | 100 sản phẩm + báo giá + đối soát | nằm ở màn khác, người bán không biết có |
///
/// Người bán không có ba khái niệm đó trong đầu; họ có **một**: *"cho tôi xem
/// nó chạy trên một cửa hàng thật trông như thế nào"*. Ba lối vào cho một câu
/// hỏi là ba chỗ để chọn nhầm — và trong trường hợp này còn là hai chỗ lặng lẽ
/// xoá dữ liệu của nhau.
///
/// Đây là bẫy P-27 quen thuộc, lần này ở tầng điều hướng chứ không ở tầng dữ
/// liệu: **một khái niệm, một chủ.**
///
/// ## Vì sao phải cả hai lớp, không chọn một
///
/// Hai lớp trả lời hai câu hỏi khác nhau và **không thay thế nhau được**:
///
/// * **12 tháng lịch sử** — thứ duy nhất làm Dự báo doanh thu và Rủi ro khách
///   hàng có gì để nói. Bộ 100 sản phẩm chỉ có ~1 tháng đơn, Rule Twin sẽ
///   **từ chối kết luận** (và từ chối là câu trả lời đúng của nó).
/// * **Bộ 100 sản phẩm** — thứ duy nhất mang **báo giá nhà cung cấp, đối soát
///   sàn, phiên bản, kiện hàng**. Không có nó thì Lời thật sau phí, So sánh
///   nguồn và Vận chuyển không có dữ liệu nào để chạy.
///
/// Thứ tự bắt buộc: lịch sử **trước** (nó gọi `removeAll()`), rồi mới nhập
/// thương mại. Đảo lại là tự xoá phần vừa nhập.
class SampleBusinessSeeder {
  const SampleBusinessSeeder({
    required this.history,
    required this.importer,
    required this.commerce,
    required this.samples,
    required this.customers,
    required this.orders,
    required this.settlements,
    required this.bundledSource,
  });

  final HistoricalDataSeeder history;
  final CommerceImporter importer;
  final CommerceRepository commerce;
  final SampleDataSeeder samples;
  final CustomerRepository customers;
  final OrderRepository orders;
  final SettlementRepository settlements;

  /// Bộ 100 sản phẩm đóng kèm app. Hàm chứ không phải giá trị: đọc asset là
  /// việc tốn bộ nhớ, và nó chỉ cần xảy ra lúc người bán thật sự bấm.
  final Future<CommerceImportSource> Function() bundledSource;

  /// Nạp **cả doanh nghiệp mẫu**. Idempotent — bấm hai lần không nhân đôi.
  Future<SampleBusinessReport> seed({
    HistoricalDataSpec spec = const HistoricalDataSpec(),
  }) async {
    // 1 · Lịch sử 12 tháng. Gọi `removeAll()` bên trong, nên phải chạy TRƯỚC.
    await history.seed(spec);

    // 2 · Lớp thương mại. Xoá lần nhập cũ trước để bấm lại không cộng dồn —
    // cùng kỷ luật idempotent với lớp trên, chứ không phải hai luật khác nhau.
    await removeBundledImport();
    final source = await bundledSource();
    final preview = await source.read();
    final result = await importer.apply(
      preview,
      sourceVendor: ImportVendor.bundledDemo,
      isDemo: true,
    );

    return SampleBusinessReport(
      months: spec.months,
      // Đếm **sau khi ghi**, không đếm lúc xem trước: hai con số này có thể
      // khác nhau, và khi khác thì con số sau mới là sự thật.
      products: result.counts['products'] ?? 0,
      orders: result.counts['orders'] ?? 0,
      customers: result.counts['customers'] ?? 0,
      importJobId: result.job.id,
    );
  }

  /// Xoá **mọi thứ mẫu** — cả hai lớp, một lần bấm.
  ///
  /// Dữ liệu người bán tự nhập không bị đụng tới: lớp lịch sử xoá theo tiền tố
  /// `sample-`, lớp thương mại xoá theo đúng `importJobId` của bộ đóng kèm.
  Future<void> removeAll() async {
    await removeBundledImport();
    await samples.removeAll();
  }

  /// Chỉ lớp thương mại.
  ///
  /// ## Vì sao phải hai cơ chế, không một
  ///
  /// `deleteImport(jobId)` xoá **sản phẩm · phiên bản · báo giá · kiện hàng** —
  /// những bảng thật sự mang cột `importJobId`.
  ///
  /// **Khách hàng, đơn hàng và dòng đối soát KHÔNG có cột đó.** Nên nếu chỉ gọi
  /// `deleteImport`, câu "Chỉ xoá những gì lần nhập này mang vào" ở màn Nhập dữ
  /// liệu là **nói sai** với đúng ba loại bản ghi đó — chúng ở lại vĩnh viễn.
  ///
  /// Với bộ đóng kèm ta xoá thêm theo **không gian mã của chính bộ đó**
  /// ([kBundledDemoIdPrefix]). Đây không phải quét bừa theo `import-`: tiền tố
  /// chung sẽ ăn luôn file Excel **của người bán**, vốn đi qua cùng đường nhập.
  Future<void> removeBundledImport() async {
    for (final job in await commerce.loadImportJobs()) {
      if (job.sourceVendor == ImportVendor.bundledDemo) {
        await commerce.deleteImport(job.id);
      }
    }
    // Đơn TRƯỚC khách: `orders.customer_id` là khoá ngoại, xoá khách khi đơn
    // còn sống là SqliteException 787 — đúng crash "Đặt lại dữ liệu mẫu" cũ.
    await orders.deleteByIdPrefix(kBundledDemoIdPrefix);
    await settlements.deleteByIdPrefix(kBundledDemoIdPrefix);
    await customers.deleteByIdPrefix(kBundledDemoIdPrefix, keep: const {});
  }
}

/// Không gian mã của bộ dữ liệu đóng kèm — `import-` + `DEMO-` của chính file.
///
/// Hẹp có chủ ý: `import-` một mình sẽ ăn luôn file Excel của người bán.
const String kBundledDemoIdPrefix = 'import-DEMO-';

/// Đã nạp những gì — để câu xác nhận nói bằng con số thật, không nói chung chung.
class SampleBusinessReport {
  const SampleBusinessReport({
    required this.months,
    required this.products,
    required this.orders,
    required this.customers,
    required this.importJobId,
  });

  final int months;
  final int products;
  final int orders;
  final int customers;
  final String importJobId;
}
