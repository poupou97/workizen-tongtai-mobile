import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// P0 §3 (WTM-146) — no UI screen may silently fall back to fixture data.
///
/// The §1 bugs (Export/Chat/Timeline/Reports showing sample data in real mode)
/// all shared one shape: a `?? Something.sample()` default in a widget. This
/// scan bans `.sample()` from `lib/features/tongtai/ui/` forever.
///
/// Allowlisted: the Producer sourcing directory (supplier search + favorites).
/// Phase 2 ships a curated static supplier catalog by design — there is no
/// supplier repository, so the catalog is reference data, not a mask over
/// user data (documented in the P0 Review Package).
void main() {
  test('ui/ never calls .sample() outside the curated supplier catalog', () {
    const allowlist = [
      'tongtai_supplier_search_screen.dart',
      'tongtai_supplier_favorites_screen.dart',
    ];
    final offenders = <String>[];
    final uiDir = Directory('lib/features/tongtai/ui');
    for (final f
        in uiDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      if (allowlist.any((ok) => f.path.endsWith(ok))) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//') || line.startsWith('///')) continue;
        if (lines[i].contains('.sample()')) {
          offenders.add('${f.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Fallback fixture ngầm trong UI bị cấm (P0 §3) — màn hình phải đọc '
          'production repositories hoặc nhận service inject tường minh:\n'
          '${offenders.join('\n')}',
    );
  });
}
