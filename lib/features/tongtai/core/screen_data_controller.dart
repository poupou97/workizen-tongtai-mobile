library;

import 'package:flutter/foundation.dart';

import '../../../core/telemetry/tongtai_telemetry.dart';
import 'screen_state.dart';

/// Runs a screen's data load and keeps its [ScreenState] honest (WTM-148,
/// ADR-TON-017).
///
/// This replaces the `initState → _load() → setState` pattern that every
/// screen hand-rolled and that silently swallowed a throwing repository. What
/// the controller adds over the hand-rolled version is exactly the behaviour
/// nobody wrote twenty-five times:
///
/// - a thrown error becomes a **classified, displayable** [TongtaiFailure]
///   instead of an unhandled future;
/// - a failed **refresh keeps the value already on screen** (stale) rather
///   than blanking a page that was working a second ago;
/// - out-of-order responses cannot overwrite newer ones (generation counter);
/// - a response arriving after [dispose] is dropped instead of throwing;
/// - the failure is reported to telemetry as **kind + code only** — the
///   message stays on the device (see [TongtaiFailure]).
///
/// It is a plain [ChangeNotifier], not a Riverpod notifier, so the screens
/// that already own a `ChangeNotifier` controller (catalog, chat, feed…) can
/// hold one without changing their architecture, and widget tests can drive it
/// with no container at all.
class ScreenDataController<T> extends ChangeNotifier {
  ScreenDataController(
    this._load, {
    T? initialValue,
    this.telemetry,
    this.screen,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       _state = initialValue == null
           ? ScreenState<T>.loading()
           : ScreenState<T>.ready(
               initialValue,
               loadedAt: (clock ?? DateTime.now)(),
             );

  final Future<T> Function() _load;
  final DateTime Function() _clock;

  /// Where failures are reported, resolved **lazily and only on failure**.
  ///
  /// A factory rather than an instance so a screen can write
  /// `() => ref.read(tongtaiTelemetryProvider)` without touching Riverpod at
  /// `initState` time: screens are pumped without a `ProviderScope` in plenty
  /// of widget tests, and an eager read would make the seam itself the reason
  /// those tests fail. Null (the default) means report nothing.
  final TongtaiTelemetry Function()? telemetry;

  /// Screen identifier for telemetry (`consumer`, `inventory`, …). Matches the
  /// stable test-ID prefix so an event can be traced to a screen without
  /// carrying any of that screen's content.
  final String? screen;

  ScreenState<T> _state;
  ScreenState<T> get state => _state;

  /// Bumped on every start; a response whose generation is stale is dropped.
  /// Without this, a slow first read landing after a fast retry would replace
  /// newer data with older data — the class of bug that looks like a caching
  /// problem and is really a race.
  int _generation = 0;
  bool _disposed = false;

  /// Whether a read is currently in flight.
  bool get isBusy => _state.isLoading || _state.isRefreshing;

  /// First read: nothing is known, so the screen shows the loading state.
  Future<void> load() => _run(ScreenState<T>.loading());

  /// The call a screen makes once, on mount.
  ///
  /// With an `initialValue` (a widget-injected service, a preview fixture) the
  /// screen already has something true to render, so this **refreshes** rather
  /// than blanking to a loading state first. That keeps the progressive render
  /// several screens were deliberately built around — the seam adds error
  /// handling to that behaviour instead of replacing it with a spinner.
  Future<void> start() => _state.hasValue ? refresh() : load();

  /// Re-read while keeping the current value on screen (returning from a form,
  /// pull-to-refresh, provider invalidation). Falls back to a plain load when
  /// there is nothing to keep.
  Future<void> refresh() => _run(_state.toRefreshing());

  /// What the retry affordance calls. Identical to [refresh]; named separately
  /// because the call sites read better and tests assert on intent.
  Future<void> retry() => refresh();

  Future<void> _run(ScreenState<T> pending) async {
    final generation = ++_generation;
    _emit(pending);
    try {
      final value = await _load();
      if (_disposed || generation != _generation) return;
      _emit(_state.toReady(value, _clock()));
    } catch (error, stackTrace) {
      if (_disposed || generation != _generation) return;
      final failure = TongtaiFailure.from(error, stackTrace);
      _emit(_state.toFailed(failure));
      _report(failure);
    }
  }

  /// Reports the failure without its message.
  ///
  /// `logEvent` gets the two bounded tokens; `recordError` gets the
  /// [TongtaiFailure] itself, whose `toString()` deliberately omits `detail`
  /// — so a crash report can name the failure without carrying a row value,
  /// a customer name or a revenue figure off the device (ADR-TON-005 red-line).
  void _report(TongtaiFailure failure) {
    _reportTongtaiFailure(failure, telemetry, screen);
  }

  void _emit(ScreenState<T> next) {
    _state = next;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Telemetry event name for a failed screen load. Declared in
/// `docs/05-OPERATIONS/TELEMETRY-EVENTS.md`; its only parameters are
/// `screen`, `kind` and `code`.
const String kScreenErrorEvent = 'screen_error';

/// Runs a **write/action** (save, delete, export, seed) and returns the
/// failure instead of throwing.
///
/// Loads have [ScreenDataController]; actions have this. Before WTM-148 an
/// action that threw left no trace at all — `tongtai_export_screen` had a
/// `try/finally` with no `catch`, so a failed export just stopped the spinner
/// and looked like success.
///
/// Returns `null` on success. Callers surface the failure with
/// `showTongtaiFailure` (see `ui/widgets/tongtai_screen_data.dart`) — the
/// return value is deliberately not ignorable-by-accident.
Future<TongtaiFailure?> runTongtaiAction(
  Future<void> Function() body, {
  TongtaiTelemetry Function()? telemetry,
  String? screen,
}) async {
  try {
    await body();
    return null;
  } catch (error, stackTrace) {
    final failure = TongtaiFailure.from(error, stackTrace);
    _reportTongtaiFailure(failure, telemetry, screen);
    return failure;
  }
}

/// Reports a failure as **kind + code + screen**, and nothing else.
///
/// Wrapped because telemetry must never take the app down (the same never-throw
/// policy as `initTongtaiTelemetry`): a screen that already failed to load must
/// not then crash because the reporting seam was unavailable — which is exactly
/// what a scope-less widget test looks like.
void _reportTongtaiFailure(
  TongtaiFailure failure,
  TongtaiTelemetry Function()? telemetry,
  String? screen,
) {
  if (telemetry == null) return;
  try {
    final sink = telemetry();
    sink.logEvent(kScreenErrorEvent, <String, Object>{
      ...failure.telemetryParams,
      'screen': ?screen,
    });
    sink.recordError(failure, null);
  } catch (_) {
    // Reporting is quality tooling, never a feature.
  }
}
