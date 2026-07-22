/// SQLite FTS5 full-text-search schema for the Tổng Tài database (WTM-72).
///
/// This is the single source of truth for the on-device search index: two FTS5
/// virtual tables (`suppliers_fts`, `products_fts`), the triggers that keep them
/// in lock-step with the base `producers_table` / `products_table`, and the
/// helpers used by the migration to build, backfill and optimize the index.
///
/// ## Why FTS5 (ADR-003, Local-First)
/// FTS5 gives fast, relevance-ranked (`bm25`) search over the catalogue without
/// a separate search service, so the app stays offline-first and BYOK. Search
/// stays on-device; nothing is shipped to a server.
///
/// ## Design
/// * **Own-content, rowid-aligned.** Each FTS table stores its own copy of the
///   indexed text plus the source string id in an `UNINDEXED` column, and its
///   `rowid` is pinned to the base row's `rowid`. That keeps trigger deletes and
///   updates O(1) (`WHERE rowid = old.rowid`) while still letting callers join
///   back to the base table on `rowid` to recover full rows.
/// * **Diacritic-insensitive.** The `unicode61 remove_diacritics 2` tokenizer
///   folds Vietnamese diacritics at both index and query time, so `"ca phe"`
///   matches `"Cà phê"` — essential for a Vietnamese-first product.
/// * **Incremental via triggers.** `AFTER INSERT/UPDATE/DELETE` triggers on the
///   base tables maintain the index automatically, so every new or edited
///   supplier/product is searchable immediately, no matter which code path wrote
///   it (WTM-72 AC: "Incremental indexing on new supplier/product additions").
library;

import 'package:drift/drift.dart';

/// FTS5 virtual-table name indexing suppliers (`producers_table`).
const String kSuppliersFtsTable = 'suppliers_fts';

/// FTS5 virtual-table name indexing products (`products_table`).
const String kProductsFtsTable = 'products_fts';

/// Base table backing [kSuppliersFtsTable].
const String _producersTable = 'producers_table';

/// Base table backing [kProductsFtsTable].
const String _productsTable = 'products_table';

/// Tokenizer applied to every FTS column.
///
/// `remove_diacritics 2` folds combining diacritics (Unicode ≥ v6.1 rules) so a
/// search for `pho` matches `phở`; `unicode61` also case-folds and splits on
/// punctuation.
const String _tokenizer = "unicode61 remove_diacritics 2";

/// An SQL expression that folds the Vietnamese letter đ/Đ to d/D for [col].
///
/// unicode61's `remove_diacritics` strips combining marks (á, ộ, ữ …) but NOT
/// đ/Đ, which is a distinct *stroked* letter rather than a base letter plus a
/// diacritic. Vietnamese uses đ heavily ("đồng", "đơn hàng", "Đà Nẵng"), so we
/// fold it ourselves on the way into the index; the query side ([build
/// TongtaiFtsMatchQuery]) folds it the same way, keeping both sides consistent.
String _foldDe(String col) => "replace(replace($col, 'đ', 'd'), 'Đ', 'D')";

/// The `CREATE VIRTUAL TABLE` + trigger statements, in dependency order.
///
/// Ordered so the virtual tables exist before the triggers that write to them.
/// Every statement is `IF NOT EXISTS`, so [createTongtaiFtsSchema] is safe to
/// call on an already-provisioned database (e.g. a re-run migration).
List<String> tongtaiFtsDdl() => <String>[
      // ── suppliers_fts ──────────────────────────────────────────────────────
      'CREATE VIRTUAL TABLE IF NOT EXISTS $kSuppliersFtsTable USING fts5('
          'supplier_id UNINDEXED, '
          'name, '
          'category, '
          'country, '
          "tokenize = '$_tokenizer'"
          ')',
      "CREATE TRIGGER IF NOT EXISTS ${kSuppliersFtsTable}_ai "
          'AFTER INSERT ON $_producersTable BEGIN '
          'INSERT INTO $kSuppliersFtsTable(rowid, supplier_id, name, category, country) '
          'VALUES (new.rowid, new.id, ${_foldDe('new.name')}, '
          '${_foldDe('new.category')}, ${_foldDe('new.country')}); '
          'END',
      "CREATE TRIGGER IF NOT EXISTS ${kSuppliersFtsTable}_ad "
          'AFTER DELETE ON $_producersTable BEGIN '
          'DELETE FROM $kSuppliersFtsTable WHERE rowid = old.rowid; '
          'END',
      "CREATE TRIGGER IF NOT EXISTS ${kSuppliersFtsTable}_au "
          'AFTER UPDATE ON $_producersTable BEGIN '
          'DELETE FROM $kSuppliersFtsTable WHERE rowid = old.rowid; '
          'INSERT INTO $kSuppliersFtsTable(rowid, supplier_id, name, category, country) '
          'VALUES (new.rowid, new.id, ${_foldDe('new.name')}, '
          '${_foldDe('new.category')}, ${_foldDe('new.country')}); '
          'END',
      // ── products_fts ───────────────────────────────────────────────────────
      'CREATE VIRTUAL TABLE IF NOT EXISTS $kProductsFtsTable USING fts5('
          'product_id UNINDEXED, '
          'name, '
          'description, '
          'category, '
          "tokenize = '$_tokenizer'"
          ')',
      "CREATE TRIGGER IF NOT EXISTS ${kProductsFtsTable}_ai "
          'AFTER INSERT ON $_productsTable BEGIN '
          'INSERT INTO $kProductsFtsTable(rowid, product_id, name, description, category) '
          'VALUES (new.rowid, new.id, ${_foldDe('new.name')}, '
          '${_foldDe('new.description')}, ${_foldDe('new.category')}); '
          'END',
      "CREATE TRIGGER IF NOT EXISTS ${kProductsFtsTable}_ad "
          'AFTER DELETE ON $_productsTable BEGIN '
          'DELETE FROM $kProductsFtsTable WHERE rowid = old.rowid; '
          'END',
      "CREATE TRIGGER IF NOT EXISTS ${kProductsFtsTable}_au "
          'AFTER UPDATE ON $_productsTable BEGIN '
          'DELETE FROM $kProductsFtsTable WHERE rowid = old.rowid; '
          'INSERT INTO $kProductsFtsTable(rowid, product_id, name, description, category) '
          'VALUES (new.rowid, new.id, ${_foldDe('new.name')}, '
          '${_foldDe('new.description')}, ${_foldDe('new.category')}); '
          'END',
    ];

/// Creates the FTS5 virtual tables and their sync triggers on [db].
///
/// Idempotent (every statement is `IF NOT EXISTS`). Call this *after* the base
/// tables exist — on a fresh install that means after `Migrator.createAll`.
Future<void> createTongtaiFtsSchema(GeneratedDatabase db) async {
  for (final statement in tongtaiFtsDdl()) {
    await db.customStatement(statement);
  }
}

/// (Re)builds the index contents from the rows already in the base tables.
///
/// Used by the schema-v3 upgrade path, where suppliers/products were written
/// before the triggers existed and so are not yet indexed. Clears each FTS
/// table first, so it is safe to call more than once (it converges to exactly
/// one index row per base row). On a fresh install the base tables are empty, so
/// this is a no-op.
Future<void> backfillTongtaiFts(GeneratedDatabase db) async {
  await db.customStatement('DELETE FROM $kSuppliersFtsTable');
  await db.customStatement(
    'INSERT INTO $kSuppliersFtsTable(rowid, supplier_id, name, category, country) '
    'SELECT rowid, id, ${_foldDe('name')}, ${_foldDe('category')}, '
    '${_foldDe('country')} FROM $_producersTable',
  );
  await db.customStatement('DELETE FROM $kProductsFtsTable');
  await db.customStatement(
    'INSERT INTO $kProductsFtsTable(rowid, product_id, name, description, category) '
    'SELECT rowid, id, ${_foldDe('name')}, ${_foldDe('description')}, '
    '${_foldDe('category')} FROM $_productsTable',
  );
}

/// Merges the FTS b-tree segments into a single, read-optimal structure.
///
/// This is the FTS5 `'optimize'` command; it makes queries faster (fewer
/// segments to scan) at a one-off write cost, which is why it is run once at
/// first-launch/backfill time rather than on every write (WTM-72 AC: "Indexes
/// built and optimized during initial app setup").
Future<void> optimizeTongtaiFts(GeneratedDatabase db) async {
  await db.customStatement(
    "INSERT INTO $kSuppliersFtsTable($kSuppliersFtsTable) VALUES('optimize')",
  );
  await db.customStatement(
    "INSERT INTO $kProductsFtsTable($kProductsFtsTable) VALUES('optimize')",
  );
}

/// Whether both FTS virtual tables currently exist in [db].
///
/// Reads `sqlite_master` for the two `USING fts5` tables; used by tests and by
/// callers that want to guard a search behind index availability.
Future<bool> tongtaiFtsSchemaExists(GeneratedDatabase db) async {
  final rows = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN "
        "('$kSuppliersFtsTable', '$kProductsFtsTable')",
      )
      .get();
  return rows.length == 2;
}
