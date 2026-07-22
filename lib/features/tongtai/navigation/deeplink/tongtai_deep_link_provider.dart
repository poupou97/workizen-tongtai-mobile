// Deep-link controller for Tổng Tài (WTM-57).
//
// Bridges a parsed [TongtaiRoute] to the app's live navigation. On a valid link
// it selects the destination's bottom-nav tab and records the route as the
// "active" one so a detail screen (once it exists) can pick up the target id.
// On an invalid link it records a [TongtaiDeepLinkFailure] the UI can surface.
//
// Cold-start handling (app killed → launched from a link): the launch URL is
// fed to [TongtaiDeepLinkController.handleInitialLink] *before* the shell
// builds, so the very first frame already shows the right tab and remembers the
// pending detail route. State restoration is therefore just: parse → set state.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/tongtai_navigation_provider.dart';
import 'tongtai_deep_link.dart';
import 'tongtai_deep_link_parser.dart';

/// Immutable snapshot of deep-link handling.
@immutable
class TongtaiDeepLinkState {
  const TongtaiDeepLinkState({
    this.activeRoute,
    this.lastFailure,
    this.sequence = 0,
  });

  /// The most recently resolved route, still waiting to be consumed by its
  /// destination screen. `null` before any link is handled, or after a screen
  /// consumes it via [TongtaiDeepLinkController.consumeActiveRoute].
  final TongtaiRoute? activeRoute;

  /// The most recent failure, for one-shot display (e.g. a SnackBar). Paired
  /// with [sequence] so listeners can tell repeated identical failures apart.
  final TongtaiDeepLinkFailure? lastFailure;

  /// Monotonically increasing counter bumped on every handled link. Lets a
  /// `ref.listen` fire even when the same link (same failure) arrives twice.
  final int sequence;

  TongtaiDeepLinkState _next({
    TongtaiRoute? activeRoute,
    TongtaiDeepLinkFailure? lastFailure,
  }) =>
      TongtaiDeepLinkState(
        activeRoute: activeRoute,
        lastFailure: lastFailure,
        sequence: sequence + 1,
      );

  @override
  bool operator ==(Object other) =>
      other is TongtaiDeepLinkState &&
      other.activeRoute == activeRoute &&
      other.lastFailure == lastFailure &&
      other.sequence == sequence;

  @override
  int get hashCode => Object.hash(activeRoute, lastFailure, sequence);

  @override
  String toString() =>
      'TongtaiDeepLinkState(activeRoute: $activeRoute, lastFailure: '
      '$lastFailure, sequence: $sequence)';
}

/// Controls deep-link resolution and the resulting navigation.
final tongtaiDeepLinkControllerProvider =
    NotifierProvider<TongtaiDeepLinkController, TongtaiDeepLinkState>(
  TongtaiDeepLinkController.new,
);

class TongtaiDeepLinkController extends Notifier<TongtaiDeepLinkState> {
  /// The parser used to resolve links. Overridable in tests, though the
  /// default is stateless and rarely needs replacing.
  TongtaiDeepLinkParser get _parser => TongtaiDeepLinkParser.instance;

  @override
  TongtaiDeepLinkState build() => const TongtaiDeepLinkState();

  /// Resolve [rawLink] and, on success, navigate to it.
  ///
  /// Returns the raw [TongtaiDeepLinkResult] so callers (and tests) can inspect
  /// the outcome. Navigation for a valid link means selecting the destination's
  /// bottom-nav tab; the [TongtaiRoute] (with any entity id) is stored as
  /// [TongtaiDeepLinkState.activeRoute] for the destination screen to consume.
  TongtaiDeepLinkResult handle(String rawLink) {
    final result = _parser.parse(rawLink);
    switch (result) {
      case TongtaiDeepLinkSuccess(:final route):
        // Select the tab that hosts this destination. Fire-and-forget: the
        // notifier persists asynchronously, but the in-memory tab flips
        // synchronously so the first frame is already correct.
        ref.read(tongtaiSelectedTabProvider.notifier).select(route.tabIndex);
        state = state._next(activeRoute: route);
      case TongtaiDeepLinkFailure():
        // Keep any previously active route; only surface the new failure.
        state = state._next(
          activeRoute: state.activeRoute,
          lastFailure: result,
        );
    }
    return result;
  }

  /// Handle a cold-start launch link. No-ops (returns `null`) when the app was
  /// launched normally (no link), so callers can pass a possibly-null URL
  /// straight through without a guard.
  TongtaiDeepLinkResult? handleInitialLink(String? rawLink) {
    if (rawLink == null || rawLink.trim().isEmpty) return null;
    return handle(rawLink);
  }

  /// Called by a destination screen once it has navigated to [activeRoute], so
  /// a later rebuild doesn't re-trigger the same navigation.
  void consumeActiveRoute() {
    if (state.activeRoute == null) return;
    state = state._next(activeRoute: null, lastFailure: state.lastFailure);
  }
}
