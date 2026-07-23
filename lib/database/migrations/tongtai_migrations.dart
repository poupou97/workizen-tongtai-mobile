/// Drift schema-migration definitions for the Tổng Tài database (WTM-52).
///
/// This is the single source of truth for *how* the on-device SQLite schema is
/// created and evolved. `AppDatabase` delegates its
/// `GeneratedDatabase.migration` here so the migration logic is testable in
/// isolation and kept out of the connection-wiring code.
///
/// ## Schema v1 (initial)
/// v1 creates every table declared on `AppDatabase` via [Migrator.createAll].
///
/// ## Schema v2 (WTM-65 — Supplier Favorites)
/// v2 adds the `supplier_favorites_table`. A fresh install still gets every
/// table via `createAll` in [MigrationStrategy.onCreate]; an existing v1 install
/// gains just the new table via the `from < 2` step in
/// [MigrationStrategy.onUpgrade].
///
/// ## Schema v3 (WTM-72 — FTS5 Search Index)
/// v3 adds the `products_table.description` column and the two FTS5 virtual
/// tables (`suppliers_fts`, `products_fts`) plus their sync triggers (see
/// `search/tongtai_fts_schema.dart`). A fresh install creates the description
/// column via `createAll` and then builds the FTS schema in
/// [MigrationStrategy.onCreate]; an existing v2 install runs the `from < 3` step
/// which adds the column, creates the FTS schema, and backfills + optimizes the
/// index from the rows already on disk.
///
/// ## Schema v4 (WTM-81 — Chat Message Persistence)
/// v4 adds the per-message `chat_messages_table` (+ conversation and sent-at
/// indices) backing the AI Copilot chat. Local-only by ADR-TON-004.
library;

import 'package:drift/drift.dart';

import '../search/tongtai_fts_schema.dart';

/// Current on-device schema version.
///
/// This must stay in lock-step with `AppDatabase.schemaVersion` and with the
/// version recorded by the shared-preferences first-launch check
/// (see `SchemaVersionStore`). Bump this by exactly one and add a matching
/// `onUpgrade` step whenever a table or column changes.
const int kTongtaiSchemaVersion = 4;

/// Drift table name of the per-message chat table (WTM-81), added in schema
/// v4. Same allTables-lookup convention as [kSupplierFavoritesTableName].
const String kChatMessagesTableName = 'chat_messages_table';

/// Drift table name of the Supplier Favorites table (WTM-65), added in schema
/// v2. Kept as a constant so the [MigrationStrategy.onUpgrade] step can locate
/// the generated [TableInfo] via `db.allTables` without importing `AppDatabase`
/// (which would create an import cycle back into this migration library).
const String kSupplierFavoritesTableName = 'supplier_favorites_table';

/// Builds the [MigrationStrategy] used by [AppDatabase].
///
/// * [onCreate] runs on a fresh install and creates all tables. Because SQLite
///   does not enforce foreign keys while `PRAGMA foreign_keys` is on during a
///   `CREATE`, ordering of `createAll()` is handled by Drift.
/// * [onUpgrade] is where future `from -> to` steps go. At v1 there is nothing
///   to upgrade; we assert the invariant instead of silently ignoring an
///   unexpected upgrade path.
/// * [beforeOpen] enables foreign-key enforcement for every connection (SQLite
///   defaults it OFF), so `.references(..., onDelete: cascade)` cascades at
///   runtime.
///
/// [db] is the opening database; it is captured so [beforeOpen] can issue the
/// `PRAGMA` on the same connection.
MigrationStrategy buildTongtaiMigrationStrategy(GeneratedDatabase db) {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // v3 (WTM-72): the FTS5 virtual tables + triggers are not Drift-declared
      // tables, so `createAll` does not build them. Create them once the base
      // tables exist. A fresh install has no rows yet, so no backfill is needed
      // (the triggers index every row inserted from here on).
      await createTongtaiFtsSchema(db);
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Each step guards on `from` so it runs exactly once, in order, no matter
      // how many versions a device skips between launches.
      if (from < 2) {
        // v2 (WTM-65): add the Supplier Favorites table. It is created here for
        // upgrading installs; fresh installs already got it via `createAll` in
        // onCreate. Locate the generated table by name so this library need not
        // import AppDatabase (which would form an import cycle).
        final favorites = db.allTables.firstWhere(
          (t) => t.actualTableName == kSupplierFavoritesTableName,
        );
        await m.createTable(favorites);
      }
      if (from < 3) {
        // v3 (WTM-72 — FTS5 Search Index).
        // 1) Add the new products.description column. Locate the Drift table by
        //    name (avoiding an AppDatabase import cycle) and use its own column
        //    definition so the ALTER matches exactly what `createAll` emits on a
        //    fresh install.
        final products = db.allTables.firstWhere(
          (t) => t.actualTableName == 'products_table',
        );
        await m.addColumn(products, products.columnsByName['description']!);
        // 2) Create the FTS virtual tables + sync triggers, then 3) backfill the
        //    index from rows that predate the triggers and 4) optimize it. On an
        //    upgrade the base tables already hold data, so the backfill is what
        //    makes existing suppliers/products searchable.
        await createTongtaiFtsSchema(db);
        await backfillTongtaiFts(db);
        await optimizeTongtaiFts(db);
      }
      if (from < 4) {
        // v4 (WTM-81 — per-message chat history). Fresh installs already got
        // the table (and its indices) via `createAll`; upgrading installs gain
        // it here. Index creation is part of createTable for @TableIndex.
        final chatMessages = db.allTables.firstWhere(
          (t) => t.actualTableName == kChatMessagesTableName,
        );
        await m.createTable(chatMessages);
      }
    },
    beforeOpen: (OpeningDetails details) async {
      await db.customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
