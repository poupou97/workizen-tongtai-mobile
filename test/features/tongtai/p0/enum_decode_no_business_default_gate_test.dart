import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **An unrecognised stored code is a corrupt record, never a business
/// default** — ADR-TON-018, enforced for the v1 enums by WTM-457.
///
/// ## Why this rule needs a suite of its own
///
/// The v1 enums decoded garbage to a real value: `OrderStatus.fromStorage`
/// unknown → `pending`, `TransactionType` unknown → `expense`, `JourneyStatus`
/// → `notStarted`, `OpportunityType` → `trend`. A delivered order silently read
/// as "waiting to be handled"; a corrupt income row silently became a cost.
/// Meanwhile every *new* enum (`ProvenanceSource`, `SalesChannel`,
/// `SettlementKind`, …) was built to forbid exactly that — two generations of
/// discipline living side by side.
///
/// WTM-457 fixed the four. But nothing *fails* when a decoder quietly points an
/// `orElse` back at a real value — the app still runs, the suite still passes,
/// and no one notices until a broken record wears a plausible business status.
/// So, like `settlement_no_derived_write_governance_test` and
/// `derived_data_governance_test`, this suite builds the thing that fails.
///
/// ## The rule
///
/// In an enum-definition file, an `orElse` inside a `fromStorage`/`fromCode`
/// decoder may fall back only to the **explicit corrupt marker** (`unknown`) —
/// never to a real business value. Returning `null` or `throw`ing is also fine
/// (both surface the corruption); those simply do not use this `orElse` shape.
void main() {
  // Enum-definition files whose `fromStorage`/`fromCode` decode stored codes.
  // Deliberately NOT UI files: e.g. the onboarding screen's
  // `firstWhere(orElse: () => OnboardingGoal.justExplore)` searches an in-memory
  // list, it does not decode a stored code, so it is out of scope.
  const enumFiles = <String>[
    'lib/features/tongtai/core/tongtai_enums.dart',
    'lib/features/tongtai/core/provenance.dart',
    'lib/features/tongtai/commerce/commerce_models.dart',
    'lib/features/tongtai/finance/settlement.dart',
    'lib/features/tongtai/finance/finance_category.dart',
    'lib/features/tongtai/profile/business_profile.dart',
    'lib/features/tongtai/sync/sync_operation.dart',
  ];

  /// The only fallback value an `orElse` may name: the explicit corrupt marker.
  const allowedFallback = 'unknown';

  /// Matches `orElse: () => SomeEnum.someMember`. It intentionally does NOT
  /// match `orElse: () => throw ...` (a `throw` has no `Enum.member` right after
  /// `=>`) nor `orElse: () => null` — both are honest, surfacing forms.
  final orElseEnumFallback = RegExp(
    r'orElse:\s*\(\)\s*=>\s*([A-Za-z_]\w*)\.([A-Za-z_]\w*)',
  );

  String stripComments(String source) {
    final noBlock = source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    return noBlock
        .split('\n')
        .map((line) {
          final i = line.indexOf('//');
          return i == -1 ? line : line.substring(0, i);
        })
        .join('\n');
  }

  /// Every offending `orElse` fallback in [code]: `Enum.member` where member is
  /// not the allowed corrupt marker. Empty means the file is clean.
  List<String> violations(String code) => [
    for (final m in orElseEnumFallback.allMatches(code))
      if (m.group(2) != allowedFallback) '${m.group(1)}.${m.group(2)}',
  ];

  late final Map<String, String> sources;

  setUpAll(() {
    sources = {for (final f in enumFiles) f: File(f).readAsStringSync()};
  });

  test('the scanner actually reads the files (guards against a fake PASS)', () {
    // Lesson paid for in WTM-291: a scan that finds nothing because it read
    // nothing looks exactly like a clean scan. Prove it read the real thing.
    expect(sources[enumFiles.first], contains('enum OrderStatus'));
    expect(
      sources['lib/features/tongtai/core/tongtai_enums.dart'],
      contains('enum TransactionType'),
    );
    // And that comments really are stripped, so a fallback *named in a doc
    // comment* (this file is full of them) cannot trip the gate.
    expect(
      stripComments('final x = 1; // orElse: () => Foo.bar'),
      isNot(contains('Foo.bar')),
    );
  });

  test('no enum decoder falls back to a real business value', () {
    for (final entry in sources.entries) {
      final found = violations(stripComments(entry.value));
      expect(
        found,
        isEmpty,
        reason:
            '${entry.key} has an `orElse` decoding an unknown code to a real '
            'value ($found). ADR-TON-018 (WTM-457): a corrupt code must surface '
            'as `$allowedFallback`, `null`, or a throw — never a real status. '
            'Masking it is how a broken record wears a plausible business state.',
      );
    }
  });

  test('the gate BITES: it catches the exact regression it exists to stop', () {
    // P-48: a gate is only trustworthy once you have watched it catch the thing
    // it must catch. This is the mutation, baked in.
    const reintroducedBug = '''
      static OrderStatus fromStorage(String? value) =>
          OrderStatus.values.firstWhere(
            (s) => s.name == value,
            orElse: () => OrderStatus.pending,
          );
    ''';
    expect(
      violations(stripComments(reintroducedBug)),
      contains('OrderStatus.pending'),
      reason: 'the pre-WTM-457 default MUST be flagged',
    );

    // And it must NOT fire on any of the three honest shapes — otherwise it
    // would block the very fix it is protecting.
    const withUnknownMarker =
        'orElse: () => OrderStatus.unknown,'; // the WTM-457 fix
    const withThrow =
        "orElse: () => throw ArgumentError.value(value),"; // SyncOperationType
    const withNull = 'orElse: () => null,';
    for (final honest in [withUnknownMarker, withThrow, withNull]) {
      expect(
        violations(stripComments(honest)),
        isEmpty,
        reason: 'honest fallback wrongly flagged: `$honest`',
      );
    }
  });
}
