import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../agent/business_brief.dart';
import '../commerce/commerce_models.dart';
import '../commerce/commerce_opportunity_service.dart';
import '../commerce/commerce_profit.dart';
import '../commerce/supplier_comparison.dart';
import '../commerce/commerce_repository.dart';
import '../commerce/attributes/attribute_models.dart';
import '../commerce/attributes/attribute_repository.dart';
import '../commerce/attributes/product_attribute_enricher.dart';
import '../commerce/attributes/product_attribute_view.dart';
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

/// **Tầng thuộc tính động (DYNAMIC)** — WTM-334 (Epic WTM-324).
///
/// Riverpod-only (ADR-TON-002). Đọc từ CÙNG một database provider như phần còn
/// lại của app, nên backup không bao giờ đọc từ một database khác.
final attributeRepositoryProvider = Provider<AttributeRepository>(
  (ref) => AttributeRepository(ref.watch(tongtaiDatabaseProvider)),
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

// ── C6 · thuộc tính động theo nhóm (WTM-335) ──────────────────────────────────

/// Thuộc tính động của **một** sản phẩm, đã gom theo nhóm — tải **on-demand ở
/// màn chi tiết** (ADR-TON-019). Đây là đường đọc DUY NHẤT của tầng value: nó
/// nằm ở một provider file được phép (`tongtai_commerce_provider.dart`), nên
/// governance `lib/`-scan vẫn xanh, và không màn danh sách/summary nào chạm tới.
///
/// Trả về danh sách rỗng khi sản phẩm không có thuộc tính nào ⇒ màn chi tiết
/// **không dựng khối rỗng** (§15).
final productAttributeGroupsProvider =
    FutureProvider.family<List<AttributeDisplayGroup>, String>((
      ref,
      productId,
    ) async {
      final repo = ref.watch(attributeRepositoryProvider);
      final values = await repo.loadValuesForEntity(
        kProductAttributeEntityType,
        productId,
      );
      // Không có giá trị thì dừng ngay: khỏi tải định nghĩa/nhóm cho một sản
      // phẩm chẳng có thuộc tính nào.
      if (values.isEmpty) return const [];
      final definitions = await repo.loadDefinitions();
      final groups = await repo.loadGroups();
      final groupItems = <AttributeGroupItem>[
        for (final group in groups) ...await repo.loadGroupItems(group.id),
      ];
      return buildAttributeDisplayGroups(
        values: values,
        definitions: definitions,
        groups: groups,
        groupItems: groupItems,
      );
    });

/// Bộ làm giàu thuộc tính cho dataset mẫu (WTM-335). Sống ở tầng attribute nên
/// governance scan cho phép; `SampleBusinessSeeder` chỉ giữ nó qua kiểu
/// **không bị canh** [ProductAttributeEnricher], không tự chạm value store.
final productAttributeEnricherProvider = Provider<ProductAttributeEnricher>(
  (ref) => ProductAttributeEnricher(ref.watch(attributeRepositoryProvider)),
);
