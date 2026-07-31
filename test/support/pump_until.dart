import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps until [finder] matches, or fails with a readable reason.
///
/// **Why this exists (WTM-148 / ADR-TON-017).** The shared screen seam renders
/// a *non-animating* loading state on purpose — a local SQLite read finishes in
/// milliseconds, and an indeterminate spinner would both flash at the user and
/// make `pumpAndSettle` hang forever on a screen that never stops scheduling
/// frames.
///
/// The trade-off is that `pumpAndSettle` no longer *waits* for a load either:
/// with no frames scheduled it returns after the first one. So a widget test
/// that wants the loaded screen must pump across the real async gaps. This
/// helper does that in one obvious call instead of a hand-tuned pile of
/// `await tester.pump()`s whose count nobody can justify later.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 40,
  Duration step = const Duration(milliseconds: 10),
}) async {
  for (var i = 0; i < maxPumps; i++) {
    // Real SQLite I/O completes off the test clock, so give it wall time
    // (`runAsync`) before pumping the frame its `setState` scheduled.
    await tester.runAsync(() => Future<void>.delayed(step));
    await tester.pump();
    if (finder.evaluate().isNotEmpty) return;
  }
  // Name the seam state that IS on screen — "still loading" and "failed to
  // load" need very different fixes, and guessing wastes the next hour.
  final seamKeys = tester.allWidgets
      .map((w) => w.key)
      .whereType<ValueKey<String>>()
      .map((k) => k.value)
      .where((k) => k.contains('-error') || k.contains('-loading'))
      .toSet()
      .join(', ');
  final code = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .whereType<String>()
      .where((t) => t.contains('.'))
      .join(' | ');
  fail(
    'pumpUntilFound gave up after $maxPumps pumps: $finder never appeared. '
    'Seam state on screen: ${seamKeys.isEmpty ? 'none' : seamKeys} '
    '($code).',
  );
}
