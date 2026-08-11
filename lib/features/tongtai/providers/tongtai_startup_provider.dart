import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../startup/startup_pipeline.dart';
import 'tongtai_inventory_provider.dart';
import 'tongtai_onboarding_provider.dart';
import 'tongtai_orders_provider.dart';

/// Nguồn khởi động thật — WTM-367.
///
/// Bốn bước, và mỗi bước là việc **dù sao cũng phải xảy ra** trước khi Trang
/// chủ vẽ được. Không có bước nào thêm vào cho thanh dài hơn.
class RiverpodStartupSource implements StartupSource {
  const RiverpodStartupSource(this.ref);

  final Ref ref;

  @override
  Future<void> openDatabase() async {
    // Đọc một bảng bất kỳ là cách ép Drift mở kết nối và chạy migration. Đây
    // là phần chậm nhất khi lên phiên bản, và cũng là phần duy nhất người bán
    // thật sự phải chờ.
    await ref.read(productRepositoryProvider).loadAll();
  }

  @override
  Future<bool> loadOnboardingCompleted() async =>
      ref.read(tongtaiOnboardingStoreProvider).isCompleted();

  @override
  Future<int> countProducts() async =>
      (await ref.read(productRepositoryProvider).loadAll()).length;

  @override
  Future<int> countOrders() async =>
      (await ref.read(orderRepositoryProvider).loadAll()).length;
}

final startupPipelineProvider = Provider<StartupPipeline>(
  (ref) =>
      StartupPipeline(source: RiverpodStartupSource(ref), clock: Stopwatch.new),
);
