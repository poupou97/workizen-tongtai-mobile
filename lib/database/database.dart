import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/perf/startup_trace.dart';

import 'tables/users.dart';
import 'tables/businesses.dart';
import 'tables/producers.dart';
import 'tables/products.dart';
import 'tables/customers.dart';
import 'tables/orders.dart';
import 'tables/channels.dart';
import 'tables/journeys.dart';
import 'tables/journey_steps.dart';
import 'tables/transactions.dart';
import 'tables/documents.dart';
import 'tables/alerts.dart';
import 'tables/ai_chats.dart';
import 'tables/integrations.dart';
import 'tables/sync_queue_items.dart';
import 'tables/supplier_favorites.dart';
import 'tables/chat_messages.dart';
import 'tables/business_profiles.dart';
import 'tables/business_journeys.dart';
import 'tables/opportunity_reactions.dart';

import 'migrations/tongtai_migrations.dart';

part 'database.g.dart';

/// Tổng Tài SQLite Database
///
/// Local-first, BYOK (Bring Your Own Key) database for the Tổng Tài app.
/// All 15 core business entities are stored locally on-device.
///
/// Entities:
/// 1. User - Business owner profile and authentication
/// 2. Business - Root entity for business hierarchy
/// 3. Producer - Supplier/sourcing partner records
/// 4. Product - Product catalog and inventory
/// 5. Customer - CRM records and segmentation
/// 6. Order - Sales transaction tracking
/// 7. Channel - Sales channel integration (Shopee, TikTok, etc.)
/// 8. Opportunity - AI-discovered business opportunities
/// 9. Journey - Business goal tracking and orchestration
/// 10. JourneyStep - Individual steps within a journey
/// 11. Transaction - Financial transaction tracking
/// 12. Document - Document storage (contracts, invoices, receipts, OCR)
/// 13. Alert - Notifications and AI recommendations
/// 14. AIChat - Conversation history with AI Copilot
/// 15. Integration - External provider integrations and credentials
///
/// Plus infrastructure / feature tables (not core business entities):
/// 16. SyncQueueItem - Offline-first outbox of pending cloud-sync operations
///     (WTM-54); drained by a future Phase-3 sync worker.
/// 17. SupplierFavorite - The user's starred suppliers for quick access
///     (WTM-65); each add/remove is also queued for cloud sync.
/// 18. ChatMessage - Per-message AI Copilot chat history (WTM-81); local-only
///     by ADR-TON-004 (never enqueued to the sync outbox).
@DriftDatabase(
  tables: [
    UsersTable,
    BusinessesTable,
    ProducersTable,
    ProductsTable,
    CustomersTable,
    OrdersTable,
    ChannelsTable,
    JourneysTable,
    JourneyStepsTable,
    TransactionsTable,
    DocumentsTable,
    AlertsTable,
    AIChatTable,
    IntegrationsTable,
    SyncQueueItemsTable,
    SupplierFavoritesTable,
    BusinessProfilesTable,
    BusinessJourneysTable,
    BusinessJourneyNodesTable,
    BusinessJourneyPlansTable,
    OpportunityReactionsTable,
    ChatMessagesTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Create app database instance (production: file-backed on-device).
  AppDatabase() : super(_openConnection());

  /// Create an app database from a supplied executor.
  ///
  /// Used by tests to run against an in-memory SQLite instance
  /// (`NativeDatabase.memory()`), so no Flutter bindings or documents
  /// directory are required.
  AppDatabase.forExecutor(super.executor);

  @override
  int get schemaVersion => kTongtaiSchemaVersion;

  /// Schema creation + evolution + foreign-key enforcement (WTM-52).
  ///
  /// Delegated to [buildTongtaiMigrationStrategy] so the migration logic lives
  /// in `migrations/` and can be unit-tested in isolation. On a fresh install
  /// `onCreate` creates all 17 tables (15 business entities + the SyncQueueItem
  /// outbox + the SupplierFavorite table) and then builds the FTS5 search index
  /// (`suppliers_fts` / `products_fts`, WTM-72 — see `search/tongtai_fts_schema
  /// .dart`); `beforeOpen` turns on `PRAGMA foreign_keys` so
  /// `.references(..., onDelete: cascade)` cascades at runtime.
  @override
  MigrationStrategy get migration => buildTongtaiMigrationStrategy(this);

  /// Open SQLite database connection
  ///
  /// Database file: tongtai.db
  /// Location: Application documents directory
  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'tongtai.db'));
      // Cold-start measurement (WTM-166): this callback runs on the FIRST
      // query, not at app launch — which is exactly the fact worth recording.
      StartupTrace.mark('db-open');
      return NativeDatabase(file);
    });
  }
}
