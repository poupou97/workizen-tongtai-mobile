/// Full-text search over the Tổng Tài catalogue, backed by SQLite FTS5 (WTM-72).
///
/// Thin query layer on top of the FTS5 virtual tables created in
/// `tongtai_fts_schema.dart`. Callers hand in raw user text; this service turns
/// it into a safe FTS5 `MATCH` expression, runs the ranked query, and returns
/// fully-hydrated base rows ([ProductsTableData] / [ProducersTableData]) in
/// relevance order (`bm25`, best first).
library;

import 'package:drift/drift.dart';

import '../database.dart';
import 'tongtai_fts_schema.dart';

/// Turns free user text into a safe FTS5 `MATCH` expression, or `null`.
///
/// Each whitespace-separated word becomes a case-/diacritic-folded prefix term
/// (`"word"*`) and the terms are AND-ed together (FTS5's default), so typing
/// `"ca phe"` matches a row whose text contains both `Cà` and `phê`. Wrapping
/// each term in double quotes neutralises FTS5 operator characters
/// (`* : ( ) " -` …), so arbitrary user input can never form a malformed or
/// injected query. The Vietnamese letter đ/Đ is folded to `d` to match the
/// index side (unicode61 does not fold it — see `_foldDe` in the FTS schema).
/// Returns `null` when the query has no searchable term (blank, whitespace, or
/// only punctuation), signalling callers to skip the query and return no results
/// rather than run an empty `MATCH`.
String? buildTongtaiFtsMatchQuery(String raw) {
  final terms = <String>[];
  for (final word in raw.trim().split(RegExp(r'\s+'))) {
    // Strip the two characters that would break a double-quoted FTS5 string
    // (`"` ends the string; `*` is the prefix operator we append ourselves),
    // then fold đ/Đ so the query matches the đ-folded index.
    final cleaned = word
        .replaceAll('"', '')
        .replaceAll('*', '')
        .replaceAll('đ', 'd')
        .replaceAll('Đ', 'd')
        .trim();
    if (cleaned.isEmpty) continue;
    terms.add('"$cleaned"*');
  }
  if (terms.isEmpty) return null;
  return terms.join(' ');
}

/// Local-first full-text search — no backend (ADR-002).
class TongtaiSearchService {
  TongtaiSearchService(this._db);

  final AppDatabase _db;

  /// Products whose name, description or category match [query], best first.
  ///
  /// Returns at most [limit] rows ordered by FTS5 `bm25` relevance. A query with
  /// no searchable term yields an empty list.
  Future<List<ProductsTableData>> searchProducts(
    String query, {
    int limit = 50,
  }) async {
    final match = buildTongtaiFtsMatchQuery(query);
    if (match == null) return const [];

    final rows = await _db.customSelect(
      'SELECT p.* FROM $kProductsFtsTable f '
      'JOIN products_table p ON p.rowid = f.rowid '
      'WHERE $kProductsFtsTable MATCH ? '
      'ORDER BY bm25($kProductsFtsTable) '
      'LIMIT ?',
      variables: [Variable<String>(match), Variable<int>(limit)],
      readsFrom: {_db.productsTable},
    ).get();

    return rows.map((r) => _db.productsTable.map(r.data)).toList();
  }

  /// Suppliers whose name, category or country match [query], best first.
  ///
  /// Returns at most [limit] rows ordered by FTS5 `bm25` relevance. A query with
  /// no searchable term yields an empty list.
  Future<List<ProducersTableData>> searchSuppliers(
    String query, {
    int limit = 50,
  }) async {
    final match = buildTongtaiFtsMatchQuery(query);
    if (match == null) return const [];

    final rows = await _db.customSelect(
      'SELECT s.* FROM $kSuppliersFtsTable f '
      'JOIN producers_table s ON s.rowid = f.rowid '
      'WHERE $kSuppliersFtsTable MATCH ? '
      'ORDER BY bm25($kSuppliersFtsTable) '
      'LIMIT ?',
      variables: [Variable<String>(match), Variable<int>(limit)],
      readsFrom: {_db.producersTable},
    ).get();

    return rows.map((r) => _db.producersTable.map(r.data)).toList();
  }
}
