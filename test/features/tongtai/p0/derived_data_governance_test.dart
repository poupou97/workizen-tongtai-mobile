import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **Derived data may not become a source of truth** — Founder Directive,
/// 2026-08-01 (WTM-202/203).
///
/// ## What this suite is for
/// Three defects in one day had the same origin: a **derived column sitting in
/// the schema**, still being read after a derivation rule had taken over.
///
/// - WTM-196 — revenue: orders vs hand-typed rows.
/// - WTM-200a — goal progress: `deriveGoalsProgress` vs stored `achievedAmount`.
/// - WTM-201 — customer counters: RFM vs stored `orderCount`.
///
/// Each was invisible: every side was internally consistent with its own green
/// tests. What made them findable was reading the schema and asking *"who owns
/// this number?"* — so that question is now a test.
///
/// ## Why the columns are not simply deleted
/// They are inside `.ttbk` v2, and ADR-TON-018 requires backups to be lossless.
/// Dropping them piecemeal is a destructive migration for existing sellers. The
/// step that actually prevents the bug is **not reading them** — dropping is
/// housekeeping for a future format version.
void main() {
  /// Columns that are **derived data**: some other rule owns the number, and
  /// reading these is how a second truth gets built.
  ///
  /// Listed here rather than in someone's memory, because the whole failure
  /// mode is *nobody remembered this was derived*.
  const derivedColumns = <String, String>{
    // customers_table
    'churnRisk':
        'customerLifecycleStage() owns churn risk, judged against the '
        'customer\'s own buying rhythm (WTM-200b)',
    'avgOrderValue':
        'totalSpent / orderCount — derived from two derived things',
    'lifetimeValue': 'CustomerRfm.monetary owns lifetime spend',
    // journeys_table (stores BusinessGoal)
    'progressPercent':
        'deriveGoalsProgress owns goal progress — this is achievedAmount '
        'under another name (WTM-200a)',
    'completedSteps': 'counted from the JourneyNode tree (ADR-TON-021)',
    // NOT `revenueImpact`: despite the name it stores `BusinessGoal
    // .targetAmount` (`business_goal_repository` line 102), which the seller
    // sets. **Source data wearing a derived-sounding name** — the second such
    // trap in this schema after `totalStock`, which is really `quantity`.
    // Judge by what the repository does, never by the column name.
    // products_table
    'profitPerUnit': 'listPrice - costPerUnit',
  };

  /// Where a derived column may legitimately appear.
  ///
  /// - the table definition itself declares it;
  /// - the generated Drift code mirrors the table;
  /// - a repository may **write** one to satisfy the backup contract, but the
  ///   read path must not feed it into the domain.
  const allowedDirs = ['lib/database/'];

  Iterable<File> dartFilesUnder(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  test('no derived column is read into the domain or the UI', () {
    final offenders = <String>[];

    for (final file in dartFilesUnder('lib')) {
      if (allowedDirs.any(file.path.startsWith)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
        for (final column in derivedColumns.keys) {
          // `row.<column>` / `r.<column>` — reading a persisted derived value.
          if (RegExp('\\brow\\.$column\\b').hasMatch(line) ||
              RegExp('\\bg\\.$column\\b').hasMatch(line)) {
            offenders.add(
              '${file.path}:${i + 1}: reads `$column` — '
              '${derivedColumns[column]}',
            );
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Dữ liệu dẫn xuất không được trở thành Single Source of Truth. Mỗi '
          'cột dưới đây đã có một luật sở hữu nó; đọc lại giá trị đã lưu là '
          'cách sự thật thứ hai được tạo ra:\n${offenders.join('\n')}',
    );
  });

  test('the derived-column list is not quietly emptied', () {
    // A governance suite that can be disarmed by deleting a list entry is not
    // governance. If a column genuinely stops being derived, the entry should
    // be removed **with** the evidence in the same commit.
    expect(derivedColumns, isNotEmpty);
    expect(
      derivedColumns.keys,
      containsAll(['churnRisk', 'progressPercent']),
      reason:
          'churnRisk and progressPercent are the two that already caused real '
          'defects — removing them from this list needs a very good reason',
    );
  });

  test('every derived column carries a reason, not just a name', () {
    // The name alone does not tell the next reader who owns the number.
    for (final entry in derivedColumns.entries) {
      expect(
        entry.value.length,
        greaterThan(20),
        reason: '${entry.key} needs a reason naming the rule that owns it',
      );
    }
  });
}
