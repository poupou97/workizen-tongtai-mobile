import '../../../../database/database.dart';
import '../../consumer/customer_repository.dart';
import '../../core/provenance.dart';
import '../../finance/settlement_repository.dart';
import '../../inventory/product_repository.dart';
import '../../logistics/shipment.dart';
import '../../logistics/shipment_repository.dart';
import '../../orders/order_repository.dart';
import '../commerce_models.dart';
import '../commerce_repository.dart';
import 'commerce_import.dart';

/// Ghi một lần nhập xuống **đường production** — WTM-326 (§15).
///
/// ## ⛔ Không seed thẳng SQLite
///
/// Founder §15: *"Không seed trực tiếp SQLite để làm demo nếu production
/// import path đã tồn tại hoặc có thể dùng. Mục tiêu là test:
/// `FILE → PARSE → VALIDATE → MAP → REPOSITORY → BUSINESS DOMAIN`."*
///
/// Nên ở đây không có `customStatement` nào, không `batch insert` thẳng bảng
/// nào. Mọi bản ghi đi qua đúng repository mà màn hình đọc — nếu đường ghi có
/// lỗi, lỗi đó xuất hiện **ngay lúc demo** chứ không chờ tới người dùng thật.
///
/// ## Một transaction
///
/// Hỏng giữa chừng thì không còn gì cả. Nửa danh mục nằm trong máy người bán
/// là trạng thái tệ nhất: nó trông như đã nhập xong.
class CommerceImporter {
  CommerceImporter({
    required AppDatabase database,
    required this.products,
    required this.customers,
    required this.orders,
    required this.settlements,
    required this.commerce,
    required this.shipments,
    required this.now,
    required this.newId,
  }) : _db = database;

  final AppDatabase _db;
  final ProductRepository products;
  final CustomerRepository customers;
  final OrderRepository orders;
  final SettlementRepository settlements;
  final CommerceRepository commerce;
  final ShipmentRepository shipments;
  final DateTime Function() now;
  final String Function() newId;

  /// Ghi những gì đã xem trước. Chỉ nhận [preview] — **không** đọc lại file.
  ///
  /// Vì sao quan trọng: người bán duyệt **cái họ nhìn thấy**. Đọc lại file lúc
  /// ghi mở ra khả năng file đã đổi giữa hai bước, và lúc đó thứ được ghi
  /// không phải thứ được duyệt.
  Future<CommerceImportResult> apply(
    CommerceImportPreview preview, {
    required String sourceVendor,
    bool isDemo = false,
  }) async {
    final jobId = 'imp-${newId()}';
    final importedAt = now();

    // Bản ghi mang khoá lần nhập — đó là thứ cho phép xoá đúng phạm vi sau này.
    final taggedProducts = [
      for (final p in preview.products)
        p.copyWith(importJobId: jobId, provenance: ProvenanceSource.fileBridge),
    ];
    final taggedVariants = [
      for (final v in preview.variants)
        ProductVariant(
          id: v.id,
          productId: v.productId,
          name: v.name,
          sku: v.sku,
          option1Name: v.option1Name,
          option1Value: v.option1Value,
          option2Name: v.option2Name,
          option2Value: v.option2Value,
          costPrice: v.costPrice,
          sellingPrice: v.sellingPrice,
          quantity: v.quantity,
          externalId: v.externalId,
          provenance: ProvenanceSource.fileBridge,
          importJobId: jobId,
        ),
    ];
    final taggedQuotes = [
      for (final q in preview.quotes)
        SupplierQuote(
          id: q.id,
          productId: q.productId,
          supplierId: q.supplierId,
          supplierName: q.supplierName,
          platform: q.platform,
          country: q.country,
          sourceUrl: q.sourceUrl,
          rating: q.rating,
          unitCost: q.unitCost,
          currency: q.currency,
          minimumOrderQuantity: q.minimumOrderQuantity,
          leadTimeDays: q.leadTimeDays,
          paymentTerms: q.paymentTerms,
          shippingMethod: q.shippingMethod,
          notes: q.notes,
          externalId: q.externalId,
          provenance: ProvenanceSource.fileBridge,
          importJobId: jobId,
          quotedAt: q.quotedAt,
        ),
    ];

    final counts = <String, int>{};

    await _db.transaction(() async {
      // Thứ tự có ràng buộc: sản phẩm trước phiên bản/báo giá (khoá ngoại),
      // khách trước đơn, đơn trước đối soát. Sai thứ tự thì SQLite từ chối và
      // cả lần nhập bị cuộn lại — không mất dữ liệu, nhưng cũng không nhập
      // được gì, và thông báo lỗi sẽ nói về khoá ngoại chứ không nói về việc
      // kinh doanh.
      if (taggedProducts.isNotEmpty) {
        await products.upsertAll(taggedProducts);
        counts['products'] = taggedProducts.length;
      }
      if (taggedVariants.isNotEmpty) {
        await commerce.upsertVariants(taggedVariants);
        counts['variants'] = taggedVariants.length;
      }
      if (taggedQuotes.isNotEmpty) {
        await commerce.upsertQuotes(taggedQuotes);
        counts['quotes'] = taggedQuotes.length;
      }
      if (preview.customers.isNotEmpty) {
        await customers.upsertAll(preview.customers);
        counts['customers'] = preview.customers.length;
      }
      if (preview.orders.isNotEmpty) {
        await orders.upsertAll(preview.orders);
        counts['orders'] = preview.orders.length;
      }
      if (preview.settlements.isNotEmpty) {
        await settlements.upsertAll(preview.settlements);
        counts['settlements'] = preview.settlements.length;
      }
      if (preview.shipments.isNotEmpty) {
        await shipments.upsertAll([
          for (final s in preview.shipments)
            Shipment(
              id: s.id,
              orderId: s.orderId,
              trackingNumber: s.trackingNumber,
              carrier: s.carrier,
              status: s.status,
              lastUpdate: s.lastUpdate,
              eta: s.eta,
              origin: s.origin,
              destination: s.destination,
              notes: s.notes,
              externalId: s.externalId,
              provenance: ProvenanceSource.fileBridge,
              importJobId: jobId,
            ),
        ]);
        counts['shipments'] = preview.shipments.length;
      }

      await commerce.saveImportJob(
        ImportJob(
          id: jobId,
          source: ProvenanceSource.fileBridge,
          sourceVendor: sourceVendor,
          sourceFile: preview.sourceName,
          sourceChecksum: preview.checksum,
          recordCounts: counts,
          warnings: [
            for (final w in preview.warnings) '${w.subject}: ${w.detail}',
          ],
          isDemo: isDemo,
          importedAt: importedAt,
        ),
      );
    });

    return CommerceImportResult(
      job: ImportJob(
        id: jobId,
        source: ProvenanceSource.fileBridge,
        sourceVendor: sourceVendor,
        sourceFile: preview.sourceName,
        sourceChecksum: preview.checksum,
        recordCounts: counts,
        isDemo: isDemo,
        importedAt: importedAt,
      ),
      counts: counts,
      // Những dòng bị chặn — nói ra, thay vì để người bán tự phát hiện thiếu
      // sau ba tuần.
      skipped: preview.errors,
    );
  }
}
