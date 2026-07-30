import 'package:flutter_riverpod/flutter_riverpod.dart';

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
