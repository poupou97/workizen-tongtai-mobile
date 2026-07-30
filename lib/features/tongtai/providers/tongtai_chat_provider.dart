import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database.dart';
import '../ai/workizen_ai_context.dart';
import '../ai/workizen_ai_router.dart';
import '../chat/chat_controller.dart';
import '../chat/chat_message.dart';
import '../chat/chat_message_store.dart';
import '../consumer/customer_order_history_service.dart';
import 'tongtai_ai_provider.dart';
import 'tongtai_consumer_provider.dart';
import 'tongtai_inventory_provider.dart';
import 'tongtai_orders_provider.dart';

/// The app's Drift database (platform resource, WTM-81).
///
/// Created lazily on first read — `AppDatabase` uses a `LazyDatabase`, so the
/// SQLite file is only opened when the first query runs. Disposed with the
/// container. Widget tests override [tongtaiChatStoreProvider] instead of
/// this, so no test ever touches the real file system.
final tongtaiDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Persistence for AI Copilot chat messages (WTM-81) — Drift-backed in
/// production, local-only per ADR-TON-004. Tests override this with an
/// [InMemoryChatMessageStore].
final tongtaiChatStoreProvider = Provider<ChatMessageStore>(
  (ref) => DriftChatMessageStore(ref.watch(tongtaiDatabaseProvider)),
);

/// The reply pipeline behind the chat screen (WTM-82, ADR-TON-006 · rewired
/// by WTM-144 P0 §1): every turn grounds Workizen AI in the CURRENT rows of
/// the production repositories — the same source every screen reads. The old
/// sample-defaulted context builder is gone. Tests override this provider
/// with a fixed responder.
final tongtaiChatResponderProvider = Provider<ChatResponder>((ref) {
  return _RealDataChatResponder(() async {
    final customers = await ref.read(customerRepositoryProvider).loadAll();
    final products = await ref.read(productRepositoryProvider).loadAll();
    final orders = await ref.read(orderRepositoryProvider).loadAll();
    final context = WorkizenAiContextBuilder(
      customers: customers,
      products: products,
      orderHistory: CustomerOrderHistoryService(orders),
    );
    return WorkizenAiRouter(
      service: ref.read(tongtaiAiServiceProvider),
      context: context,
      fallback: RuleBasedChatResponder(context: context),
    );
  });
});

/// Rebuilds a data-grounded router for every turn, so the chat always answers
/// from the latest persisted rows (local SQLite — cheap to reload).
class _RealDataChatResponder implements ChatResponder {
  const _RealDataChatResponder(this._buildDelegate);

  final Future<ChatResponder> Function() _buildDelegate;

  @override
  Future<String> reply(List<ChatMessage> history, String prompt) async {
    final delegate = await _buildDelegate();
    return delegate.reply(history, prompt);
  }
}
