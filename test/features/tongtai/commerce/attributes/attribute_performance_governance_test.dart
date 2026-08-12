import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// WTM-334 — the **performance** governance rule (spec §"Luật hiệu năng",
/// ADR-TON-019).
///
/// Attributes are read **only at the detail screen, on demand**. ADR-TON-019
/// measured that repeated hydration reads are ~80% of cold-start cost, so the
/// dynamic value store must never be joined into a list, a summary, a
/// Capability Context, or the BusinessContext. This suite reads the source and
/// fails if the attribute value store is reachable from anywhere but the places
/// that are allowed to touch it — the same shape as
/// `derived_data_governance_test`.
void main() {
  /// Symbols whose appearance means "someone can read dynamic attribute
  /// values here". The table and the repository are the two doors; the value
  /// read methods are named so a screen cannot reach them by accident.
  const guardedSymbols = [
    'AttributeValuesTable',
    'attributeValuesTable',
    'AttributeRepository',
    'attributeRepositoryProvider',
    'loadValuesForEntity',
    'loadAllValues',
  ];

  /// The only places allowed to name those symbols:
  /// - the schema (table definitions + generated Drift code);
  /// - the attribute feature itself;
  /// - the backup layer (`.ttbk` must carry the datasets);
  /// - the two provider files that declare and wire the repository.
  const allowedPrefixes = [
    'lib/database/',
    'lib/features/tongtai/commerce/attributes/',
    'lib/features/tongtai/export/',
    'lib/features/tongtai/providers/tongtai_commerce_provider.dart',
    'lib/features/tongtai/providers/tongtai_backup_provider.dart',
  ];

  final symbol = RegExp('\\b(${guardedSymbols.join('|')})\\b');

  Iterable<File> dartFilesUnder(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  test('the dynamic attribute value store is unreachable from list / summary / '
      'Capability Context / BusinessContext', () {
    final offenders = <String>[];
    for (final file in dartFilesUnder('lib')) {
      final path = file.path;
      if (allowedPrefixes.any(path.startsWith)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final trimmed = lines[i].trimLeft();
        if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
        if (symbol.hasMatch(lines[i])) {
          offenders.add('$path:${i + 1}: ${trimmed.trim()}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Thuộc tính động chỉ được đọc on-demand ở màn chi tiết (ADR-TON-019). '
          'Mỗi dòng dưới đây kéo tầng value vào một chỗ cấm (danh sách · '
          'summary · Capability Context · BusinessContext):\n'
          '${offenders.join('\n')}',
    );
  });

  test('the guard actually watches a real symbol (proof of life)', () {
    // A scan that matches nothing is a scan that protects nothing. Prove the
    // read path exists where it is allowed, so the test above can genuinely
    // fail the day a screen re-introduces a forbidden read.
    final repo = File(
      'lib/features/tongtai/commerce/attributes/attribute_repository.dart',
    ).readAsStringSync();
    expect(repo, contains('loadValuesForEntity'));
  });
}
