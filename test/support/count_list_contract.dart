import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// **Summary Count == Domain Visible Records** — the cross-screen contract
/// every Tổng Tài domain must satisfy (ADR-TON-015 §2).
///
/// Reusable so a NEW domain inherits the guarantee instead of re-writing it:
/// describe the domain once with [CountListContract] and call
/// [verifyCountListContract]. Used by
/// `test/features/tongtai/p0/count_list_contract_test.dart`.
///
/// The contract deliberately compares THREE things, because any two agreeing
/// while the third disagrees is exactly how the field bugs escaped:
///
/// 1. what the repository actually holds,
/// 2. what the summary surface (Home tile / tab badge) renders,
/// 3. what the domain screen actually shows the user.
@immutable
class CountListContract {
  const CountListContract({
    required this.domain,
    required this.summaryKey,
    required this.repositoryCount,
    this.legitimateFilter,
    this.openSummary,
    this.openDomain,
    this.itemKeyPrefix,
    this.mustBeVisible = const [],
  });

  /// Domain name, used in failure messages (`consumer`, `inventory`, …).
  final String domain;

  /// Key of the widget that renders the count (its text must be the number).
  final Key summaryKey;

  /// What the production repository holds right now — the source of truth.
  final Future<int> Function() repositoryCount;

  /// Documents a legitimate difference between the summary and the raw row
  /// count (e.g. the orders KPI excludes cancelled orders, ADR-TON-011).
  /// When set, BOTH surfaces must apply it — state it here so the contract
  /// stays explicit instead of silently tolerant.
  final String? legitimateFilter;

  /// Navigates to the surface that renders [summaryKey] (null = already there).
  final Future<void> Function(WidgetTester tester)? openSummary;

  /// Navigates to the domain screen that lists the records (null = skip the
  /// visible-records half of the contract, e.g. read-only summaries).
  final Future<void> Function(WidgetTester tester)? openDomain;

  /// Key prefix of the domain list items (`customer-item-`). When set, the
  /// contract counts rendered items with this prefix.
  final String? itemKeyPrefix;

  /// Specific records that MUST be reachable in the domain screen — use for
  /// the record classes that historically went missing (a user-created row
  /// and a seeded sample row).
  final List<ContractRecord> mustBeVisible;
}

/// One record the contract insists the user can actually reach.
///
/// [reveal] exists because "visible" and "on the first page" are not the same
/// thing: a paginated/filtered list may legitimately need a search or a scroll
/// first. What the contract forbids is the record being **unreachable** — the
/// static-shell bug (Testing Bible P-03). Domains state their own reveal step
/// so the assertion stays honest instead of quietly weakened.
@immutable
class ContractRecord {
  const ContractRecord(this.key, {this.reveal});

  /// Stable widget key of the row, e.g. `customer-item-<id>`.
  final String key;

  /// Optional navigation inside the domain screen (search/scroll/page) that a
  /// real user would perform to reach the record.
  final Future<void> Function(WidgetTester tester)? reveal;
}

/// Reads the integer rendered by the widget at [key].
int renderedCount(WidgetTester tester, Key key, {required String domain}) {
  final finder = find.byKey(key);
  expect(
    finder,
    findsOneWidget,
    reason: '[$domain] summary widget $key must be on screen',
  );
  final texts = tester
      .widgetList<Text>(
        find.descendant(of: finder, matching: find.byType(Text)),
      )
      .map((t) => t.data)
      .whereType<String>()
      .toList();
  // The keyed widget may BE the Text itself.
  final widget = tester.widget(finder);
  if (widget is Text && widget.data != null) texts.add(widget.data!);
  final numeric = texts.where((t) => int.tryParse(t.trim()) != null).toList();
  expect(
    numeric,
    hasLength(1),
    reason: '[$domain] $key must render exactly one number, got $texts',
  );
  return int.parse(numeric.single.trim());
}

/// Counts rendered list items whose key starts with [prefix].
int visibleItemCount(WidgetTester tester, String prefix) => tester.allWidgets
    .map((w) => w.key)
    .whereType<ValueKey<String>>()
    .where((k) => k.value.startsWith(prefix))
    .toSet()
    .length;

/// Verifies the contract for one domain. Throws a descriptive failure naming
/// the domain and which of the three numbers disagreed.
Future<void> verifyCountListContract(
  WidgetTester tester,
  CountListContract c,
) async {
  final expected = await c.repositoryCount();

  await c.openSummary?.call(tester);
  await tester.pumpAndSettle();
  final summary = renderedCount(tester, c.summaryKey, domain: c.domain);
  expect(
    summary,
    expected,
    reason:
        '[${c.domain}] summary shows $summary but the repository holds '
        '$expected${c.legitimateFilter == null ? '' : ' (filter: ${c.legitimateFilter})'}',
  );

  if (c.openDomain == null) return;
  await c.openDomain!.call(tester);
  await tester.pumpAndSettle();

  for (final record in c.mustBeVisible) {
    await record.reveal?.call(tester);
    await tester.pumpAndSettle();
    expect(
      find.byKey(Key(record.key)),
      findsWidgets,
      reason:
          '[${c.domain}] record ${record.key} is counted by the summary but '
          'is NOT reachable in the domain screen',
    );
  }

  if (c.itemKeyPrefix != null) {
    final visible = visibleItemCount(tester, c.itemKeyPrefix!);
    expect(
      visible,
      greaterThan(0),
      reason:
          '[${c.domain}] summary counts $expected records but the domain '
          'screen rendered NO item with key prefix "${c.itemKeyPrefix}" — '
          'the screen is not reading the same source (P-03 static shell)',
    );
    expect(
      visible,
      lessThanOrEqualTo(expected),
      reason:
          '[${c.domain}] domain screen rendered $visible items but the '
          'repository only holds $expected — the screen is showing records '
          'the summary does not know about',
    );
  }
}
