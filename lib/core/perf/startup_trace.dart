import 'package:flutter/foundation.dart';

/// Cold-start measurement seam (WTM-166).
///
/// Android already tells us process start → first frame (`am start -W`,
/// `ActivityTaskManager: Displayed`). What it cannot tell us is the part a
/// seller actually waits for: **first frame is not Home with numbers on it.**
/// This records the marks in between so the two are never confused, and so an
/// optimisation can be shown to have moved a specific one.
///
/// **Off unless asked for.** Everything here is behind
/// `--dart-define=TT_STARTUP_TRACE=true`; a normal release build records
/// nothing and prints nothing. Measurement must still happen on a *release*
/// build — a debug/profile number says nothing about what ships (and a desktop
/// number says less).
///
/// **Durations only.** A mark is a name and a millisecond count. No business
/// content, no record counts, no file paths — and this never reaches telemetry
/// (ADR-TON-005/D-7): it goes to logcat on the machine doing the measuring.
class StartupTrace {
  StartupTrace._();

  /// Compile-time switch. `const` so the tree-shaker removes the whole trace
  /// from a normal release build rather than merely skipping it at runtime.
  static const bool enabled = bool.fromEnvironment('TT_STARTUP_TRACE');

  /// Marks that must all land before the trace is worth printing — the four
  /// tabs the shell builds eagerly plus the first frame. Printing earlier
  /// would report a cold start that has not finished.
  static const Set<String> _completesAt = {
    'first-frame',
    'home-data',
    'producer-data',
    'inventory-data',
    'consumer-data',
  };

  static final Stopwatch _since = Stopwatch();
  static final Map<String, int> _marks = <String, int>{};
  static bool _reported = false;

  /// Starts the clock at the top of `main()`. This is **not** process start:
  /// Dart VM + engine init happen before any Dart code runs, and that part is
  /// only visible in Android's own number. Reports say which is which.
  static void begin() {
    if (!enabled) return;
    _since.start();
  }

  /// Records [name] at the current offset from [begin]. First write wins, so a
  /// screen rebuilding later cannot overwrite its own cold-start timing.
  static void mark(String name) {
    if (!enabled || !_since.isRunning) return;
    _marks.putIfAbsent(name, () => _since.elapsedMilliseconds);
    _reportIfComplete();
  }

  static void _reportIfComplete() {
    if (_reported || !_completesAt.every(_marks.containsKey)) return;
    _reported = true;
    final ordered = _marks.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    for (final e in ordered) {
      debugPrint('TT-STARTUP ${e.key}=${e.value}ms');
    }
  }

  /// Test seam — the marks are static, so a test that asserts on them has to
  /// be able to start from nothing.
  @visibleForTesting
  static void resetForTest() {
    _since
      ..stop()
      ..reset();
    _marks.clear();
    _reported = false;
  }

  @visibleForTesting
  static Map<String, int> get marksForTest => Map.unmodifiable(_marks);

  @visibleForTesting
  static bool get reportedForTest => _reported;
}
