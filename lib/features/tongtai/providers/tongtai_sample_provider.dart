import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sample/historical_data_generator.dart';
import 'tongtai_commerce_provider.dart';
import '../sample/sample_business_seeder.dart';
import '../sample/sample_data_seeder.dart';
import 'tongtai_consumer_provider.dart';
import 'tongtai_finance_provider.dart';
import 'tongtai_inventory_provider.dart';
import 'tongtai_journey_provider.dart';
import 'tongtai_orders_provider.dart';

/// Sample-data lifecycle over the PRODUCTION repositories (WTM-144 /
/// ADR-TON-014): "Xem thử Demo" seeds, "Xóa dữ liệu mẫu" removes — every
/// screen keeps reading the one real source.
final sampleDataSeederProvider = Provider<SampleDataSeeder>(
  (ref) => SampleDataSeeder(
    customers: ref.watch(customerRepositoryProvider),
    products: ref.watch(productRepositoryProvider),
    orders: ref.watch(orderRepositoryProvider),
    goals: ref.watch(businessGoalRepositoryProvider),
    finance: ref.watch(financeRepositoryProvider),
  ),
);

/// Months-to-years of generated business history over the SAME repositories and
/// the SAME `sample-` lifecycle (WTM-149 Predictive Foundation): it wraps
/// [sampleDataSeederProvider], so "Xóa dữ liệu mẫu" removes generated history
/// exactly like the hand-written fixtures — there is no second seeding path.
///
/// Opportunities and Timeline events are NOT seeded: the existing rule engine
/// and event sources derive them from this data (ADR-TON-014 one source).
final historicalDataSeederProvider = Provider<HistoricalDataSeeder>(
  (ref) =>
      HistoricalDataSeeder(sampleSeeder: ref.watch(sampleDataSeederProvider)),
);

/// **Một doanh nghiệp mẫu, một nút** — WTM-343.
///
/// Gộp ba đường nạp mẫu cũ (viết tay · 12 tháng · bộ 100 sản phẩm) làm một.
/// Xem `SampleBusinessSeeder` để biết vì sao phải cả hai lớp.
final sampleBusinessSeederProvider = Provider<SampleBusinessSeeder>(
  (ref) => SampleBusinessSeeder(
    history: ref.watch(historicalDataSeederProvider),
    importer: ref.watch(commerceImporterProvider),
    commerce: ref.watch(commerceRepositoryProvider),
    samples: ref.watch(sampleDataSeederProvider),
    customers: ref.watch(customerRepositoryProvider),
    orders: ref.watch(orderRepositoryProvider),
    settlements: ref.watch(settlementRepositoryProvider),
    bundledSource: () => ref.read(bundledDemoSourceProvider),
  ),
);
