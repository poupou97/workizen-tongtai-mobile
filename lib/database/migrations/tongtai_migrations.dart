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
///
/// ## Schema v5 (WTM-121 — Persistence snapshot, ADR-TON-009)
/// v5 adds the nullable `products_table.domain_snapshot` column: a versioned
/// full-domain JSON blob for extended fields (e.g. imagePaths) not yet promoted
/// to structured columns. Additive + nullable, so upgrading installs keep their
/// rows. First application of the "structured columns + versioned snapshot"
/// convention (option B).
///
/// ## Schema v6 (WTM-123 — Consumer persistence snapshot, ADR-TON-009)
/// v6 adds the nullable `customers_table.domain_snapshot` column (tags,
/// addresses, notes). Same additive-nullable convention as v5.
///
/// ## Schema v18 (WTM-283 — Connection, N0.2)
/// v18 adds `connections_table` (external-platform connection **metadata**) and
/// drops `integrations_table` — a bootstrap-v1 table nothing ever wrote, whose
/// four `*Encrypted` columns encoded a decision that violates the Founder's
/// credential rule: secrets belong in Keychain/Keystore, never in the business
/// database (and therefore never in an unencrypted `.ttbk`).
///
/// ## Schema v17 (WTM-282 — Provenance, N0.1)
/// v17 adds the nullable `orders_table.provenance_code` column: which of the
/// four canonical sources a row came from (`manual` · `sample` · `derived` ·
/// `connector`). **No backfill on purpose** — a row that predates v17 never
/// declared its origin, and writing a guess to disk would turn that guess into
/// a declaration. The repository infers from the id prefix at read time and
/// marks the result as inferred.
///
/// ## Schema v7 (WTM-124 — Journey persistence snapshot, ADR-TON-009)
/// v7 adds the nullable `journeys_table.domain_snapshot` column: the divergent
/// `BusinessGoal` domain fields (type, achievedAmount, growth, endDate, notes)
/// not carried by the goal/status/budget/steps structured columns. Same
/// additive-nullable convention as v5/v6.
library;

import 'package:drift/drift.dart';

import '../search/tongtai_fts_schema.dart';

/// Current on-device schema version.
///
/// This must stay in lock-step with `AppDatabase.schemaVersion` and with the
/// version recorded by the shared-preferences first-launch check
/// (see `SchemaVersionStore`). Bump this by exactly one and add a matching
/// `onUpgrade` step whenever a table or column changes.
const int kTongtaiSchemaVersion = 18;

/// Thêm cột **chỉ khi nó chưa có** — làm cho một bước migration chạy lại được.
///
/// Vì sao cần: `onUpgrade` chạy cả chuỗi bước rồi mới ghi `user_version`. Một
/// bước ở CUỐI chuỗi hỏng ⇒ version không tiến ⇒ lần mở sau chạy lại **từ
/// đầu** và vấp vào chính những bước đã áp dụng: *"duplicate column name"*.
/// Cơ sở dữ liệu người bán kẹt vĩnh viễn, và bản vá cho bước hỏng cũng không
/// cứu được vì app chết trước khi tới đó.
///
/// Tìm thấy trên máy Founder (2026-08-02): v14 hỏng vì thiếu `kind`, lần mở
/// kế tiếp chết ở `source_opportunity_id` — một bước đã chạy xong từ WTM-191.
/// Sửa bước hỏng là chưa đủ; **chuỗi migration phải tha thứ được cho việc
/// chạy lại**.
Future<void> _addColumnIfMissing(
  GeneratedDatabase db,
  Migrator m,
  TableInfo<Table, dynamic> table,
  GeneratedColumn column,
) async {
  final info = await db
      .customSelect("PRAGMA table_info('${table.actualTableName}')")
      .get();
  final exists = info.any((row) => row.read<String>('name') == column.name);
  if (!exists) await m.addColumn(table, column);
}

/// Drift table name of the per-message chat table (WTM-81), added in schema
/// v4. Same allTables-lookup convention as [kSupplierFavoritesTableName].
const String kChatMessagesTableName = 'chat_messages_table';

/// Drift table name of the Supplier Favorites table (WTM-65), added in schema
/// v2. Kept as a constant so the [MigrationStrategy.onUpgrade] step can locate
/// the generated [TableInfo] via `db.allTables` without importing `AppDatabase`
/// (which would create an import cycle back into this migration library).
const String kSupplierFavoritesTableName = 'supplier_favorites_table';

/// Drift table name of the AI Business Profile table (WTM-177), added in schema
/// v8. Same allTables-lookup convention as [kSupplierFavoritesTableName].
const String kBusinessProfilesTableName = 'business_profiles_table';

/// Drift table names of the Business Journey tree (WTM-185, ADR-TON-021), added
/// in schema v9. Note `journeys_table` is NOT one of these — it stores
/// `BusinessGoal` and has since WTM-124; see `tables/business_journeys.dart`.
const List<String> kBusinessJourneyTableNames = [
  'business_journeys_table',
  kBusinessJourneyNodesTableName,
  'business_journey_plans_table',
];

/// Drift table name of the journey node table. Named separately because the
/// v11 step (WTM-191) adds a column to this one specifically.
const String kBusinessJourneyNodesTableName = 'business_journey_nodes_table';

/// Drift table name of the opportunity reaction store (WTM-190), added in
/// schema v10. See `tables/opportunity_reactions.dart` for why only the
/// seller's judgement is stored and not the opportunity itself.
const String kOpportunityReactionsTableName = 'opportunity_reactions_table';

/// The unused integration table, dropped in schema v18 (WTM-283).
///
/// It shipped in v1 and **nothing ever wrote a row to it** — but unlike the
/// opportunity table, this one was actively harmful while it sat there: its
/// `api_key_encrypted` / `access_token_encrypted` columns told every future
/// reader that tokens belong in the business database.
const String kDroppedIntegrationsTableName = 'integrations_table';

/// The unused opportunity table, dropped in schema v10 (WTM-190).
///
/// It shipped in v1 and **nothing ever wrote a row to it** — opportunities are
/// derived data, regenerated by the rule engine on every read. Leaving it in
/// the schema made the app look like it stored opportunities, which is very
/// close to the reason the audit took so long to notice that the seller's
/// *reactions* were the thing not being stored. An empty table that lies about
/// the design is worth more gone than kept.
const String kDroppedOpportunitiesTableName = 'opportunities_table';

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
        await _addColumnIfMissing(
          db,
          m,
          products,
          products.columnsByName['description']!,
        );
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
      if (from < 5) {
        // v5 (WTM-121 — persistence snapshot, ADR-TON-009). Add the nullable
        // products.domain_snapshot column. Fresh installs already got it via
        // createAll; upgrading installs gain it here. Nullable, so existing rows
        // keep NULL until next written.
        final products = db.allTables.firstWhere(
          (t) => t.actualTableName == 'products_table',
        );
        await _addColumnIfMissing(
          db,
          m,
          products,
          products.columnsByName['domain_snapshot']!,
        );
      }
      if (from < 6) {
        // v6 (WTM-123 — Consumer persistence snapshot, ADR-TON-009). Add the
        // nullable customers.domain_snapshot column (tags, addresses, notes).
        // Same additive-nullable convention as v5.
        final customers = db.allTables.firstWhere(
          (t) => t.actualTableName == 'customers_table',
        );
        await _addColumnIfMissing(
          db,
          m,
          customers,
          customers.columnsByName['domain_snapshot']!,
        );
      }
      if (from < 7) {
        // v7 (WTM-124 — Journey persistence snapshot, ADR-TON-009). Add the
        // nullable journeys.domain_snapshot column. Same additive-nullable
        // convention as v5/v6.
        final journeys = db.allTables.firstWhere(
          (t) => t.actualTableName == 'journeys_table',
        );
        await _addColumnIfMissing(
          db,
          m,
          journeys,
          journeys.columnsByName['domain_snapshot']!,
        );
      }
      if (from < 8) {
        // v8 (WTM-177 — AI Business Profile). Additive: a new table only, no
        // existing table touched (ADR-TON-009). Upgrading installs land with an
        // empty profile table, which reads as "not answered" — the same state a
        // fresh install starts in, so nothing downstream has to special-case an
        // upgrade.
        final profiles = db.allTables.firstWhere(
          (t) => t.actualTableName == kBusinessProfilesTableName,
        );
        await m.createTable(profiles);
      }
      if (from < 9) {
        // v9 (WTM-185 — Business Journey tree, ADR-TON-021). Additive: three
        // new tables, nothing existing touched. `BusinessGoal` (journeys_table)
        // is deliberately left alone, so a seller who already has goals keeps
        // every one of them and needs no backfill — they simply have no journey
        // until they open one.
        for (final name in kBusinessJourneyTableNames) {
          final table = db.allTables.firstWhere(
            (t) => t.actualTableName == name,
          );
          await m.createTable(table);
        }
      }
      if (from < 10) {
        // v10 (WTM-190 — opportunity reactions). Additive: one new table.
        // Before this, every "save" and every "dismiss" was lost when the app
        // closed — the seller pressed a button that had no lasting effect.
        final reactions = db.allTables.firstWhere(
          (t) => t.actualTableName == kOpportunityReactionsTableName,
        );
        await m.createTable(reactions);
        // …and drop the table that never held anything. Safe to do here rather
        // than leave behind: nothing in the app has ever inserted into it, so
        // there is no row to lose. `IF EXISTS` because a database created by a
        // build that already dropped it must upgrade cleanly too.
        await db.customStatement(
          'DROP TABLE IF EXISTS $kDroppedOpportunitiesTableName',
        );
      }
      if (from < 18) {
        // v18 (WTM-283 / N0.2 — Connection). Bảng mới cho metadata kết nối…
        final conns = db.allTables.firstWhere(
          (t) => t.actualTableName == 'connections_table',
        );
        await m.createTable(conns);
        // …và xoá `integrations_table`: có từ bootstrap v1, CHƯA TỪNG có dòng
        // nào, nhưng mang bốn cột `*Encrypted` — tức mã hoá sẵn quyết định
        // "token nằm trong SQLite nghiệp vụ", trái luật credential của Founder.
        //
        // An toàn để xoá chứ không phải để lại: không đường ghi nào từng tồn
        // tại, nên không có dòng nào để mất. `IF EXISTS` vì một DB tạo bởi bản
        // dựng đã xoá nó cũng phải nâng cấp sạch (tiền lệ WTM-190).
        await db.customStatement(
          'DROP TABLE IF EXISTS $kDroppedIntegrationsTableName',
        );
      }
      if (from < 17) {
        // v17 (WTM-282 / N0.1 — Provenance). Một cột nullable trên
        // `orders_table`: bản ghi này từ đâu tới.
        //
        // KHÔNG backfill. Đơn cũ không khai nguồn gốc, và ghi một suy đoán
        // xuống đĩa sẽ biến nó thành lời khai — lần đọc sau không còn ai biết
        // đó từng là phỏng đoán. Repository suy từ tiền tố id lúc đọc và đánh
        // dấu `inferred`; xem `Provenance.fromStored`.
        //
        // Thêm cột, KHÔNG rebuild bảng — bài học v14.
        final orders = db.allTables.firstWhere(
          (t) => t.actualTableName == 'orders_table',
        );
        await _addColumnIfMissing(
          db,
          m,
          orders,
          orders.columnsByName['provenance_code']!,
        );
      }
      if (from < 16) {
        // v16 (WTM-229 / ADR-TON-023 — Business Input). Bảng mới, tạo thẳng:
        // không có dữ liệu cũ để chuyển, và `createTable` không đụng bảng nào
        // đang có (bài học v14: thêm và rebuild không đi chung vô tư).
        final inputs = db.allTables.firstWhere(
          (t) => t.actualTableName == 'business_inputs_table',
        );
        await m.createTable(inputs);
      }
      if (from < 15) {
        // v15 (WTM-228 / ADR-TON-023 — Business Type). Thêm một cột nullable,
        // KHÔNG rebuild bảng: bài học v14 là `TableMigration` sao chép mọi cột
        // của schema mới ra khỏi bảng cũ, nên thêm cột và rebuild không được
        // đi chung một cách vô tư.
        final profiles = db.allTables.firstWhere(
          (t) => t.actualTableName == kBusinessProfilesTableName,
        );
        await _addColumnIfMissing(
          db,
          m,
          profiles,
          profiles.columnsByName['type_code']!,
        );
      }
      if (from < 14) {
        // v14 (WTM-227 / ADR-TON-023 — Product Type). Two changes to
        // `products_table`, both about the app being able to say "this does
        // not apply" instead of a number that means something else:
        //   * `kind` — canonical ProductKind code; NULL reads back as
        //     `physical`, which is the TRUTH about every pre-v14 row: they
        //     were entered under a physical-only model.
        //   * `total_stock` becomes nullable. It used to default to 0, and
        //     that 0 is exactly what made Inventory shout "Hết hàng" and the
        //     Rule Engine generate a restock opportunity — for a piece of
        //     software.
        // ORDER MATTERS, and getting it wrong shipped a broken upgrade:
        // `TableMigration` copies every column of the NEW schema out of the
        // OLD table, so it must not run while a new column is still missing —
        // the first device install failed with `no such column: "kind"` and
        // every screen showed "Could not read your data". v13 got away with a
        // bare rebuild because it only DROPPED columns; adding one is what
        // breaks. So: add the column first, then rebuild for the nullability
        // change.
        // Cột lấy qua `allTables` như các bước khác trong file này — module
        // migration cố ý KHÔNG import AppDatabase (sẽ tạo vòng import).
        final products = db.allTables.firstWhere(
          (t) => t.actualTableName == 'products_table',
        );
        await _addColumnIfMissing(
          db,
          m,
          products,
          products.$columns.firstWhere((c) => c.name == 'kind'),
        );
        await m.alterTable(TableMigration(products));
      }
      if (from < 13) {
        // v13 (WTM-212 — Derived Truth Violation ELIMINATED, not contained).
        // One sweep drops every fully dead derived column: nothing writes them
        // (the last live write, journeys.progress_percent, stopped in this
        // change), nothing reads them (p0/derived_data_governance_test), and
        // none are in `.ttbk` — the codec encodes domain objects, not raw
        // columns, which is what makes this drop safe for every existing
        // backup. TableMigration rebuilds each table from its new definition,
        // copying the live columns by name.
        for (final name in [
          'journeys_table',
          'customers_table',
          'products_table',
        ]) {
          final table = db.allTables.firstWhere(
            (t) => t.actualTableName == name,
          );
          await m.alterTable(TableMigration(table));
        }
      }
      if (from < 12) {
        // v12 (WTM-209 — sales channel on orders). `orders_table.channel_id`
        // was a foreign key into `channels_table`, a dead v1 table nothing
        // ever wrote — so every real canonical code failed the constraint
        // (SqliteException 787, caught by the first test that wrote
        // 'shopee'). The rebuild below re-creates orders_table from its NEW
        // definition (no FK), copying every row by column name; then the dead
        // table is dropped, the WTM-190 precedent (`opportunities_table`).
        final orders = db.allTables.firstWhere(
          (t) => t.actualTableName == 'orders_table',
        );
        await m.alterTable(TableMigration(orders));
        await db.customStatement('DROP TABLE IF EXISTS channels_table');
      }
      if (from < 11) {
        // v11 (WTM-191 — opportunity → journey). Additive: one nullable column
        // on the node table. Existing nodes read as "not from an opportunity",
        // which is exactly what they are.
        final nodes = db.allTables.firstWhere(
          (t) => t.actualTableName == kBusinessJourneyNodesTableName,
        );
        await _addColumnIfMissing(
          db,
          m,
          nodes,
          nodes.columnsByName['source_opportunity_id']!,
        );
      }
    },
    beforeOpen: (OpeningDetails details) async {
      await db.customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
