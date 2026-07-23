import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'csv_exporter.dart';

/// One completed export (WTM-99 AC5 — history logged and viewable).
@immutable
class TongtaiExportRecord {
  const TongtaiExportRecord({
    required this.type,
    required this.fileName,
    required this.rowCount,
    required this.exportedAt,
  });

  final TongtaiExportType type;
  final String fileName;
  final int rowCount;
  final DateTime exportedAt;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'fileName': fileName,
    'rowCount': rowCount,
    'exportedAt': exportedAt.toIso8601String(),
  };

  static TongtaiExportRecord fromJson(Map<String, dynamic> json) =>
      TongtaiExportRecord(
        type: TongtaiExportType.values.byName(json['type'] as String),
        fileName: json['fileName'] as String,
        rowCount: json['rowCount'] as int,
        exportedAt: DateTime.parse(json['exportedAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TongtaiExportRecord &&
          other.type == type &&
          other.fileName == fileName &&
          other.rowCount == rowCount &&
          other.exportedAt == exportedAt);

  @override
  int get hashCode => Object.hash(type, fileName, rowCount, exportedAt);
}

/// Persistence boundary for the export history (WTM-99 AC5) — same
/// interface + in-memory-fake pattern as the onboarding/tab-state stores.
/// Only metadata is stored (type, file name, row count, timestamp) — never
/// the exported data itself.
abstract interface class TongtaiExportHistoryStore {
  /// History, newest first.
  Future<List<TongtaiExportRecord>> load();

  /// Prepend [record], keeping at most [maxEntries].
  Future<void> add(TongtaiExportRecord record);

  /// Most entries retained.
  static const int maxEntries = 20;
}

/// Production store backed by [SharedPreferences] (a small JSON list — no
/// secure storage needed, this is non-sensitive metadata).
class SharedPrefsTongtaiExportHistoryStore
    implements TongtaiExportHistoryStore {
  SharedPrefsTongtaiExportHistoryStore(this._prefs);

  static const String storageKey = 'tongtai.export.history';

  final SharedPreferences _prefs;

  @override
  Future<List<TongtaiExportRecord>> load() async {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final item in list)
          TongtaiExportRecord.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      return const []; // corrupted history is dropped, never crashes export
    }
  }

  @override
  Future<void> add(TongtaiExportRecord record) async {
    final current = await load();
    final next = [
      record,
      ...current,
    ].take(TongtaiExportHistoryStore.maxEntries).toList();
    await _prefs.setString(
      storageKey,
      jsonEncode([for (final r in next) r.toJson()]),
    );
  }
}

/// In-memory store for tests.
class InMemoryTongtaiExportHistoryStore implements TongtaiExportHistoryStore {
  final List<TongtaiExportRecord> _records = [];

  @override
  Future<List<TongtaiExportRecord>> load() async => List.unmodifiable(_records);

  @override
  Future<void> add(TongtaiExportRecord record) async {
    _records.insert(0, record);
    if (_records.length > TongtaiExportHistoryStore.maxEntries) {
      _records.removeRange(
        TongtaiExportHistoryStore.maxEntries,
        _records.length,
      );
    }
  }
}
