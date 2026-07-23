import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database.dart';
import '../chat/chat_message_store.dart';

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
