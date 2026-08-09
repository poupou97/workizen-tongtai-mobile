import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/prefs.dart';
import '../simulation/conversation_reply.dart';
import '../simulation/customer_conversation.dart';
import '../simulation/demo_event.dart';
import '../simulation/demo_event_repository.dart';
import '../simulation/simulation_engine.dart';
import 'tongtai_agentic_provider.dart';
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

/// Hội thoại khách hàng — **chiếu** của sổ sự kiện, không phải bảng thứ hai
/// (WTM-339 · WTM-296 §10).
final customerConversationsProvider =
    FutureProvider<List<CustomerConversation>>((ref) async {
      final events = await ref
          .watch(demoEventRepositoryProvider)
          .loadTimeline(limit: 500);
      final customers = await ref.watch(customerRepositoryProvider).loadAll();
      return projectConversations(events: events, customers: customers);
    });

/// Một hội thoại. Đọc lại từ danh sách để chỉ có **một** đường dựng dữ liệu
/// (ADR-TON-015 One Data Path) — màn chi tiết không tự truy vấn kiểu riêng.
final customerConversationProvider =
    FutureProvider.family<CustomerConversation?, String>((
      ref,
      customerId,
    ) async {
      final all = await ref.watch(customerConversationsProvider.future);
      for (final c in all) {
        if (c.customerId == customerId) return c;
      }
      return null;
    });

final conversationReplyServiceProvider = Provider<ConversationReplyService>(
  (ref) => ConversationReplyService(
    actions: ref.watch(businessActionExecutorProvider),
    events: ref.watch(demoEventRepositoryProvider),
  ),
);
