import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database.dart';
import '../ai/workizen_ai_context.dart';
import '../ai/workizen_ai_router.dart';
import '../chat/chat_controller.dart';
import '../chat/chat_message_store.dart';
import 'tongtai_ai_provider.dart';

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

/// Local business context injected into every Workizen AI turn (WTM-82).
final tongtaiAiContextBuilderProvider = Provider<WorkizenAiContextBuilder>(
  (ref) => WorkizenAiContextBuilder(),
);

/// The reply pipeline behind the chat screen (WTM-82, ADR-TON-006): Workizen
/// AI Router over the BYOK service, with the rule-based offline fallback.
/// Tests override this with a fixed responder.
final tongtaiChatResponderProvider = Provider<ChatResponder>((ref) {
  final context = ref.watch(tongtaiAiContextBuilderProvider);
  return WorkizenAiRouter(
    service: ref.watch(tongtaiAiServiceProvider),
    context: context,
    fallback: RuleBasedChatResponder(context: context),
  );
});
