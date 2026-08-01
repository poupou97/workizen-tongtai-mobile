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
  // WTM-212: churnRisk · avgOrderValue · lifetimeValue · progressPercent ·
  // completedSteps · totalSteps · spent · profitPerUnit · currentPrice ·
  // stockByWarehouse were DROPPED in schema v13 — the evidence this suite's
  // own rule demands for removing an entry: the columns no longer exist, so
  // there is nothing left to read. What remains here is derived data that is
  // still stored for a reason and must still never be read for display.
  const derivedColumns = <String, String>{
    // NOT `revenueImpact`: despite the name it stores `BusinessGoal
    // .targetAmount` (`business_goal_repository` line 102), which the seller
    // sets. **Source data wearing a derived-sounding name** — the second such
    // trap in this schema after `totalStock`, which is really `quantity`.
    // Judge by what the repository does, never by the column name.
    // orders_table — written for a future SQL aggregation, never read. The
    // domain rebuilds every order from `items`, and `CustomerOrder.totalAmount`
    // is a getter over them (WTM-203). Dormant while nobody reads it.
    'totalQuantity': 'summed from the order items, which are the real source',
    // customers_table — storage for the Customer domain fields, carried by
    // `.ttbk` (encodeCustomer), which is the audit's criterion #3: a
    // legitimate reason to persist. Display must still derive at read time
    // (deriveCustomerCounters, WTM-201) — reading these for UI re-creates the
    // "0 đơn · ₫0" defect.
    'orderCount':
        'CustomerRfmService owns the count; the column exists for the '
        'backup contract, display derives at read (WTM-201)',
    'totalSpent':
        'CustomerRfm.monetary owns lifetime spend; column kept for the '
        'backup contract only',
  };

  /// Where a derived column may legitimately appear.
  ///
  /// - the table definition itself declares it;
  /// - the generated Drift code mirrors the table;
  /// - a repository may **write** one to satisfy the backup contract, but the
  ///   read path must not feed it into the domain.
  const allowedDirs = [
    'lib/database/',
    // The storage boundary for the customer counters: the repository maps
    // column ↔ domain field, and the domain field is what `.ttbk` carries.
    // The rule targets UI/business-logic reads — display goes through
    // deriveCustomerCounters (WTM-201), and the SSoT suite proves it.
    'lib/features/tongtai/consumer/customer_repository.dart',
  ];

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
      containsAll(['orderCount', 'totalSpent']),
      reason:
          'the customer counters already caused WTM-201 — they stay listed '
          'as long as the columns exist for the backup contract',
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
