import 'dart:convert';

/// Versioned extended-domain snapshot codec (ADR-TON-009) shared by every
/// repository that persists via the "structured columns + snapshot" convention.
///
/// Structured columns stay the source of truth for promoted fields; this blob
/// carries the extended/nested fields not yet promoted. Decoding is deliberately
/// **tolerant** — a null / empty / non-object / corrupt / unknown-version blob
/// never breaks a load; the caller falls back to the structured columns.

/// Encodes [extended] fields with a [version] tag.
String encodeDomainSnapshot(Map<String, dynamic> extended, {int version = 1}) =>
    jsonEncode(<String, dynamic>{'v': version, ...extended});

/// Decodes a snapshot blob into a map; returns `{}` for null/empty/corrupt/
/// non-object input. The `v` key carries the version for future migration.
Map<String, dynamic> decodeDomainSnapshot(String? json) {
  if (json == null || json.isEmpty) return const {};
  try {
    final decoded = jsonDecode(json);
    return decoded is Map<String, dynamic> ? decoded : const {};
  } catch (_) {
    return const {}; // corrupt JSON → fall back to structured columns
  }
}

/// Snapshot version, or 0 when absent/invalid.
int snapshotVersion(Map<String, dynamic> snapshot) =>
    snapshot['v'] is int ? snapshot['v'] as int : 0;

/// A `List<String>` from [key], tolerant of missing keys / wrong element types.
List<String> snapshotStringList(Map<String, dynamic> snapshot, String key) =>
    (snapshot[key] as List?)?.whereType<String>().toList() ?? const [];

/// A `String` from [key], defaulting to `''` when missing or non-string.
String snapshotString(Map<String, dynamic> snapshot, String key) =>
    snapshot[key] is String ? snapshot[key] as String : '';

/// An `int` from [key], tolerant of doubles and missing/invalid values.
int snapshotInt(Map<String, dynamic> snapshot, String key, {int fallback = 0}) {
  final v = snapshot[key];
  if (v is int) return v;
  if (v is double) return v.round();
  return fallback;
}

/// A `double` from [key], tolerant of ints and missing/invalid values.
double snapshotDouble(
  Map<String, dynamic> snapshot,
  String key, {
  double fallback = 0,
}) {
  final v = snapshot[key];
  if (v is num) return v.toDouble();
  return fallback;
}

/// Encodes a `List<String>` for a *structured* JSON-array column (e.g.
/// `customers_table.segments`). Kept beside the snapshot codec so every
/// repository encodes list columns the same, tolerant way.
String encodeJsonStringList(List<String> values) => jsonEncode(values);

/// Decodes a structured JSON-array column into a `List<String>`; returns `[]`
/// for null/empty/corrupt/non-array input — a bad blob never breaks a load.
List<String> decodeJsonStringList(String? json) {
  if (json == null || json.isEmpty) return const [];
  try {
    final decoded = jsonDecode(json);
    return decoded is List ? decoded.whereType<String>().toList() : const [];
  } catch (_) {
    return const [];
  }
}
