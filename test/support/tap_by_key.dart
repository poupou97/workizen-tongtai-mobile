import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tap helpers that fail loudly instead of quietly doing nothing.
///
/// ## Why this exists
/// `tester.tap` **only prints a warning** when the offset it computed does not
/// hit the target. The test keeps running, the tap never happened, and every
/// later assertion runs against the screen the tester never left. Three
/// separate times in one session that turned into a green test proving
/// nothing:
///
/// - the profile editor — Save sat below the fold, so "saving works" tapped
///   empty space;
/// - the onboarding conversation — Next was inside a `ListView` and simply not
///   built, so `find` returned zero widgets;
/// - the same conversation again — a missed tap on Start meant four assertions
///   ran on the greeting, and *two of them passed vacuously*, including one
///   asserting a button was absent from a screen that was never shown.
///
/// The second failure mode is the dangerous one: a test that passes because
/// the thing it checks for is missing **along with everything else**.
///
/// Use [tapByKey] for anything that might be off-screen, and
/// [expectScreen] after a navigation step.
extension TongtaiTapExtensions on WidgetTester {
  /// Scrolls [key] into view inside [scrollableUnder], then taps it — and
  /// **fails** if the widget is not there or the tap would miss.
  ///
  /// [scrollableUnder] is the key of the scrolling container (usually the
  /// screen's list). Omit it for a screen that does not scroll.
  Future<void> tapByKey(
    String key, {
    String? scrollableUnder,
    String? reason,
  }) async {
    final finder = find.byKey(Key(key));

    if (scrollableUnder != null) {
      await scrollUntilVisible(
        finder,
        120,
        scrollable: find.descendant(
          of: find.byKey(Key(scrollableUnder)),
          matching: find.byType(Scrollable),
        ),
      );
      await pumpAndSettle();
    }

    expect(
      finder,
      findsOneWidget,
      reason:
          reason ??
          'tapByKey("$key") found no widget — in a lazy list an off-screen '
              'child is never built, so this is "not rendered", not "missed".',
    );

    // warnIfMissed stays on: the warning text names the obstructing widget,
    // which is the useful part. The assertion below is what makes it fatal.
    await tap(finder);
    await pumpAndSettle();
  }

  /// Scrolls [key] into view without tapping it, and fails if it never
  /// appears.
  ///
  /// `ensureVisible` cannot be used for this: in a lazy list an off-screen
  /// child has no element yet, so it throws before it can scroll anywhere.
  Future<void> scrollToKey(String key, {required String under}) async {
    final finder = find.byKey(Key(key));
    await scrollUntilVisible(
      finder,
      120,
      scrollable: find.descendant(
        of: find.byKey(Key(under)),
        matching: find.byType(Scrollable),
      ),
    );
    await pumpAndSettle();
    expect(
      finder,
      findsOneWidget,
      reason: 'scrollToKey("$key") never brought it into view',
    );
  }

  /// Asserts the screen keyed [key] is on screen.
  ///
  /// Call this straight after a navigation tap. Without it a missed tap is
  /// indistinguishable from a successful one until some later assertion fails
  /// for a reason that has nothing to do with the real cause.
  void expectScreen(String key, {String? reason}) {
    expect(
      find.byKey(Key(key)),
      findsOneWidget,
      reason:
          reason ??
          'expected to be on "$key" — if a tap was supposed to bring us here, '
              'it silently missed.',
    );
  }
}
