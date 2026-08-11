import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../agent/business_brief.dart';
import '../commerce/commerce_models.dart';
import '../commerce/commerce_opportunity_service.dart';
import '../commerce/commerce_profit.dart';
import '../commerce/supplier_comparison.dart';
import '../commerce/commerce_repository.dart';
import '../commerce/import/commerce_import.dart';
import '../commerce/import/commerce_importer.dart';
import '../commerce/import/xlsx_commerce_source.dart';
import '../finance/settlement_repository.dart';
import '../logistics/shipment_repository.dart';
import '../logistics/shipment_rule.dart';
import 'tongtai_chat_provider.dart' show tongtaiDatabaseProvider;
import 'tongtai_consumer_provider.dart';
import 'tongtai_inventory_provider.dart';
import 'tongtai_orders_provider.dart';

/// **Miền thương mại chuẩn hoá, nối vào app** — WTM-327 (Epic WTM-324).
///
/// Riverpod-only (ADR-TON-002).
final commerceRepositoryProvider = Provider<CommerceRepository>(
  (ref) => CommerceRepository(ref.watch(tongtaiDatabaseProvider)),
);

/// Đối soát — WTM-231 dựng miền nhưng chưa có provider nào, nên nó chưa có
/// đường vào app. Lần nhập đầu tiên mang phí sàn thật là chỗ nó cần tới.
final settlementRepositoryProvider = Provider<SettlementRepository>(
  (ref) => DriftSettlementRepository(ref.watch(tongtaiDatabaseProvider)),
);

final shipmentRepositoryProvider = Provider<ShipmentRepository>(
  (ref) => ShipmentRepository(ref.watch(tongtaiDatabaseProvider)),
);

/// Chuyến giao hàng đáng nhắc — Rule Twin, chạy không cần mạng (WTM-323).
final shipmentConcernsProvider = FutureProvider<List<ShipmentConcern>>((
  ref,
) async {
  final shipments = await ref.watch(shipmentRepositoryProvider).loadAll();
  return const ShipmentRule().assess(shipments, now: DateTime.now());
});

/// Bộ nhập hàng — **đường production** (§15), không seed thẳng SQLite.
final commerceImporterProvider = Provider<CommerceImporter>((ref) {
  const uuid = Uuid();
  return CommerceImporter(
    database: ref.watch(tongtaiDatabaseProvider),
    products: ref.watch(productRepositoryProvider),
    customers: ref.watch(customerRepositoryProvider),
    orders: ref.watch(orderRepositoryProvider),
    settlements: ref.watch(settlementRepositoryProvider),
    commerce: ref.watch(commerceRepositoryProvider),
    shipments: ref.watch(shipmentRepositoryProvider),
    now: DateTime.now,
    newId: uuid.v4,
  );
});

/// Các lần đã nhập — nguồn của thẻ "Đặt lại dữ liệu demo".
final importJobsProvider = FutureProvider<List<ImportJob>>(
  (ref) => ref.watch(commerceRepositoryProvider).loadImportJobs(),
);

/// Bộ dữ liệu thương mại demo đóng gói sẵn trong app.
///
/// Có nó thì Founder nhập được **ngay**, không phải chờ Google Drive. Và quan
/// trọng hơn: nó đi **cùng một đường** với file người bán tự chọn — nếu đường
/// đó hỏng thì hỏng ở cả hai, chứ không có một lối tắt riêng cho demo.
final bundledDemoSourceProvider = Provider<Future<CommerceImportSource>>((
  ref,
) async {
  final data = await rootBundle.load(kBundledCommerceDemoAsset);
  return XlsxCommerceSource(
    bytes: data.buffer.asUint8List(),
    fileName: kBundledCommerceDemoFileName,
    now: DateTime.now(),
  );
});

const String kBundledCommerceDemoFileName =
    'TongTai-Commerce-Demo-100-Products.xlsx';
const String kBundledCommerceDemoAsset =
    'assets/demo/$kBundledCommerceDemoFileName';

// ── C4 · lời thật sau phí ─────────────────────────────────────────────────

/// **Lời thật 30 ngày** — Capability Context, tải on-demand (ADR-TON-016).
///
/// Không tự tính lợi nhuận: nó gom ba mảnh rồi giao cho `TrueProfitRule` —
/// công thức nằm ở đúng một chỗ, và đó là chỗ đã có từ WTM-231.
final commerceProfitProvider = FutureProvider<CommerceProfitContext>((
  ref,
) async {
  final orders = await ref.watch(orderRepositoryProvider).loadAll();
  final products = await ref.watch(productRepositoryProvider).loadAll();
  final settlements = await ref.watch(settlementRepositoryProvider).loadAll();
  return CommerceProfitContext.derive(
    orders: orders,
    products: products,
    settlements: settlements,
    now: DateTime.now(),
  );
});

// ── C5 · cơ hội thương mại ────────────────────────────────────────────────

/// Việc cần làm suy ra từ danh mục + lời thật + báo giá. **Không hardcode**
/// (§16): đổi một con số trong file Excel thì việc hiện ra cũng đổi theo.
final commerceOpportunitiesProvider = FutureProvider<List<BriefItem>>((
  ref,
) async {
  final products = await ref.watch(productRepositoryProvider).loadAll();
  final profit = await ref.watch(commerceProfitProvider.future);
  final quotes = await ref.watch(commerceRepositoryProvider).loadQuotes();
  return const CommerceOpportunityService().derive(
    products: products,
    profit: profit,
    quotes: quotes,
    shipments: await ref.watch(shipmentConcernsProvider.future),
    // Chỉ để tra **khách nào** đang chờ kiện đang kẹt (WTM-348).
    orders: await ref.watch(orderRepositoryProvider).loadAll(),
    now: DateTime.now(),
  );
});

/// So sánh nhà cung cấp cho **một** sản phẩm — use case P0 (§17).
final supplierComparisonProvider =
    FutureProvider.family<SupplierComparison, String>((ref, productId) async {
      final quotes = await ref
          .watch(commerceRepositoryProvider)
          .loadQuotes(productId: productId);
      return SupplierComparison.from(productId: productId, quotes: quotes);
    });
