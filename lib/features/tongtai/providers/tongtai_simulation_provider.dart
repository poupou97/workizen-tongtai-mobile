import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/prefs.dart';
import '../simulation/demo_event.dart';
import '../simulation/demo_event_repository.dart';
import '../simulation/simulation_engine.dart';
import 'tongtai_chat_provider.dart' show tongtaiDatabaseProvider;
import 'tongtai_commerce_provider.dart';
import 'tongtai_consumer_provider.dart';
import 'tongtai_inventory_provider.dart';
import 'tongtai_orders_provider.dart';

/// **Doanh nghiệp demo, nối vào app** — WTM-338 (Epic WTM-336).
///
/// Riverpod-only (ADR-TON-002).

final demoEventRepositoryProvider = Provider<DemoEventRepository>(
  (ref) => DemoEventRepository(ref.watch(tongtaiDatabaseProvider)),
);

final simulationEngineProvider = Provider<SimulationEngine>(
  (ref) => SimulationEngine(
    events: ref.watch(demoEventRepositoryProvider),
    orders: ref.watch(orderRepositoryProvider),
    products: ref.watch(productRepositoryProvider),
    customers: ref.watch(customerRepositoryProvider),
    settlements: ref.watch(settlementRepositoryProvider),
    shipments: ref.watch(shipmentRepositoryProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  ),
);

/// Dòng thời gian doanh nghiệp — sổ sự kiện **đã áp**, mới nhất trước (§37).
final businessTimelineProvider = FutureProvider<List<DemoEvent>>(
  (ref) => ref.watch(demoEventRepositoryProvider).loadTimeline(),
);

/// Đang ở ngày thứ mấy của thế giới mô phỏng. `null` = chưa bắt đầu.
final simulationDayProvider = FutureProvider<int?>((ref) async {
  final engine = ref.watch(simulationEngineProvider);
  if (await engine.startedAt() == null) return null;
  return engine.currentDay();
});
