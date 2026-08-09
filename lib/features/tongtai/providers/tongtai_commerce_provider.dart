import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../commerce/commerce_models.dart';
import '../commerce/commerce_repository.dart';
import '../commerce/import/commerce_import.dart';
import '../commerce/import/commerce_importer.dart';
import '../commerce/import/xlsx_commerce_source.dart';
import '../finance/settlement_repository.dart';
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
