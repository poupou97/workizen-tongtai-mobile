library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../core/screen_state.dart';
import '../../navigation/tongtai_design_tokens.dart';

/// The **one** way a Tổng Tài screen renders loading, empty, insufficient,
/// stale, refreshing and failed (WTM-148, ADR-TON-017).
///
/// Hand a [ScreenState] in and a builder for the happy path; everything else
/// is handled here, with stable keys derived from [prefix] so behaviour tests
/// drive any screen the same way:
///
/// | Key | State |
/// |---|---|
/// | `<prefix>-loading` | first read in flight |
/// | `<prefix>-refreshing` | newer read in flight, old value still shown |
/// | `<prefix>-empty` | loaded, legitimately no records |
/// | `<prefix>-insufficient` | loaded, domain refuses to conclude |
/// | `<prefix>-error` | read failed, nothing to show |
/// | `<prefix>-error-retry` | retry affordance (retryable kinds only) |
/// | `<prefix>-error-detail` | the raw technical message, on demand |
/// | `<prefix>-stale` | read failed, previous value still shown |
///
/// Why one widget instead of a snippet each screen copies: the copies drift.
/// Twenty-five slightly different "something went wrong" cards is how a
/// product ends up unable to tell a user whether their data is missing or
/// merely unreadable — which is the bug this replaces.
class TongtaiScreenData<T> extends StatelessWidget {
  const TongtaiScreenData({
    super.key,
    required this.prefix,
    required this.state,
    required this.builder,
    this.onRetry,
    this.isEmpty,
    this.emptyMessage,
    this.emptyBuilder,
    this.insufficiencyOf,
    this.insufficientExtra,
  });

  /// Stable test-ID prefix of the owning screen (`consumer`, `inventory`, …),
  /// per the `<screen>-<role>` convention (ADR-TON-015 §3).
  final String prefix;

  final ScreenState<T> state;

  /// The happy path. Called for ready, refreshing and stale — a stale screen
  /// still shows its data, with a banner saying so.
  final Widget Function(BuildContext context, T value) builder;

  /// Re-runs the load. Omit only where a retry is genuinely impossible; the
  /// error state then explains instead of offering a dead button.
  final Future<void> Function()? onRetry;

  /// Whether a loaded value holds no records. Without it, an empty list simply
  /// renders through [builder] — which is right for screens whose "empty" is
  /// already part of their layout.
  final bool Function(T value)? isEmpty;

  /// Message for the shared empty state. Defaults to `stateEmpty`.
  final String? emptyMessage;

  /// Full replacement for the shared empty state, for screens whose empty view
  /// is a real call to action (Home's onboarding, for instance).
  final Widget Function(BuildContext context)? emptyBuilder;

  /// Lets the domain declare "I cannot conclude from this" — a Rule Twin's
  /// `insufficient` verdict (ADR-TON-016). Returning non-null replaces the
  /// content with the shared refusal, which is neither empty nor an error.
  final TongtaiInsufficiency? Function(BuildContext context, T value)?
  insufficiencyOf;

  /// Extra content under the shared refusal — the real months a forecast could
  /// not be made from, for instance. "We cannot tell yet" does not mean
  /// "nothing exists", and a screen that has more truth to show should show it
  /// *inside* the shared state rather than forking its own.
  final Widget? Function(BuildContext context, T value)? insufficientExtra;

  @override
  Widget build(BuildContext context) {
    final value = state.value;

    // Failed with nothing to fall back on: the whole screen is the failure.
    if (state.hasFailed && value == null) {
      return TongtaiFailureView(
        prefix: prefix,
        failure: state.failure!,
        onRetry: onRetry,
      );
    }

    if (value == null) {
      return TongtaiLoadingView(prefix: prefix);
    }

    final content = _content(context, value);

    // ready / refreshing / stale all render the SAME skeleton: a header slot,
    // then the content. Keeping the tree shape constant is not cosmetic — a
    // Column that appears and disappears around a list re-creates every row,
    // and a re-created `Dismissible` forgets it was dismissed. Same structural
    // position, same element, preserved state.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.isStale)
          // Stale: the data stays, the banner tells the truth about its age.
          TongtaiStaleBanner(
            prefix: prefix,
            failure: state.failure!,
            loadedAt: state.loadedAt!,
            onRetry: onRetry,
          )
        else
          // A hairline, not a spinner over the page: the data underneath is
          // still valid and still readable while the newer read runs. Static
          // for the same reason as [TongtaiLoadingView] — a refresh that
          // outlives one frame is already unusual on a local database.
          SizedBox(
            height: 2,
            child: state.isRefreshing
                ? ColoredBox(
                    key: Key('$prefix-refreshing'),
                    color: TongtaiDesignTokens.consumerBlue,
                  )
                : null,
          ),
        Expanded(child: content),
      ],
    );
  }

  Widget _content(BuildContext context, T value) {
    final insufficiency = insufficiencyOf?.call(context, value);
    if (insufficiency != null) {
      return TongtaiInsufficientView(
        prefix: prefix,
        insufficiency: insufficiency,
        extra: insufficientExtra?.call(context, value),
      );
    }
    if (isEmpty?.call(value) ?? false) {
      // A custom empty view carries the `<prefix>-empty` stable ID itself
      // (ADR-TON-015 §3) — wrapping it here would double the key on the
      // screens that already do so.
      return emptyBuilder?.call(context) ??
          TongtaiEmptyView(prefix: prefix, message: emptyMessage);
    }
    return builder(context, value);
  }
}

/// [TongtaiScreenData] for a screen whose data comes from a Riverpod
/// `AsyncValue` (a `FutureProvider`) instead of a [ScreenDataController].
///
/// Both data-path shapes exist in this app for good reasons — provider-backed
/// screens get invalidation for free (`invalidateBusinessDataProviders`),
/// controller-backed screens get an explicit lifecycle — and both must render
/// the SAME states with the SAME keys, or the governance rule is only half a
/// rule.
///
/// The one thing an `AsyncValue` cannot supply is *when* its value was read,
/// which the stale banner needs. This widget stamps that moment itself, when a
/// new value actually arrives, rather than inventing "now" at paint time.
class TongtaiAsyncScreenData<T> extends StatefulWidget {
  const TongtaiAsyncScreenData({
    super.key,
    required this.prefix,
    required this.async,
    required this.builder,
    this.onRetry,
    this.isEmpty,
    this.emptyMessage,
    this.emptyBuilder,
    this.insufficiencyOf,
    this.insufficientExtra,
    this.clock,
  });

  final String prefix;
  final AsyncValue<T> async;
  final Widget Function(BuildContext context, T value) builder;
  final Future<void> Function()? onRetry;
  final bool Function(T value)? isEmpty;
  final String? emptyMessage;
  final Widget Function(BuildContext context)? emptyBuilder;
  final TongtaiInsufficiency? Function(BuildContext context, T value)?
  insufficiencyOf;
  final Widget? Function(BuildContext context, T value)? insufficientExtra;

  /// Injectable for tests that assert on the stale banner's time.
  final DateTime Function()? clock;

  @override
  State<TongtaiAsyncScreenData<T>> createState() =>
      _TongtaiAsyncScreenDataState<T>();
}

class _TongtaiAsyncScreenDataState<T> extends State<TongtaiAsyncScreenData<T>> {
  ScreenState<T> _state = ScreenState<T>.loading();

  @override
  void initState() {
    super.initState();
    _state = _fold(_state, widget.async);
  }

  @override
  void didUpdateWidget(TongtaiAsyncScreenData<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.async, widget.async)) {
      _state = _fold(_state, widget.async);
    }
  }

  /// Folds the new `AsyncValue` into the state we already had, so a value that
  /// did not change keeps its original [ScreenState.loadedAt] and a failure
  /// keeps the last good value (stale) exactly as the controller does.
  ScreenState<T> _fold(ScreenState<T> previous, AsyncValue<T> async) {
    final clock = widget.clock ?? DateTime.now;
    if (async.hasError) {
      return previous.toFailed(
        TongtaiFailure.from(async.error!, async.stackTrace),
      );
    }
    final value = async.value;
    if (value == null) {
      return async.isLoading ? previous.toRefreshing() : previous;
    }
    // Same value object as last time ⇒ same read: do not restamp, or the stale
    // banner would drift forward while nothing was actually re-read.
    if (previous.hasValue && identical(previous.value, value)) {
      return async.isLoading
          ? previous.toRefreshing()
          : previous.toReady(value, previous.loadedAt!);
    }
    return previous.toReady(value, clock());
  }

  @override
  Widget build(BuildContext context) => TongtaiScreenData<T>(
    prefix: widget.prefix,
    state: _state,
    builder: widget.builder,
    onRetry: widget.onRetry,
    isEmpty: widget.isEmpty,
    emptyMessage: widget.emptyMessage,
    emptyBuilder: widget.emptyBuilder,
    insufficiencyOf: widget.insufficiencyOf,
    insufficientExtra: widget.insufficientExtra,
  );
}

// ── The individual states, usable on their own ──────────────────────────────

/// First read in flight.
///
/// **Deliberately not animated.** Tổng Tài is local-first: a screen load is a
/// SQLite read measured in milliseconds, so a spinner would flash and vanish —
/// noise, not information. It also keeps a property the screens had before
/// this seam and would have quietly lost: with no perpetual animation, every
/// widget test can `pumpAndSettle` instead of racing an indicator that never
/// stops scheduling frames.
///
/// The semantic label is explicit because a placeholder announces nothing to a
/// screen reader on its own.
class TongtaiLoadingView extends StatelessWidget {
  const TongtaiLoadingView({super.key, required this.prefix});

  final String prefix;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      key: Key('$prefix-loading'),
      child: Semantics(
        label: l10n.stateLoading,
        liveRegion: true,
        child: Text(
          l10n.stateLoading,
          style: TongtaiDesignTokens.smallStyle.copyWith(
            color: TongtaiDesignTokens.lightTextSecondary,
          ),
        ),
      ),
    );
  }
}

/// Loaded, and there is genuinely nothing to show.
class TongtaiEmptyView extends StatelessWidget {
  const TongtaiEmptyView({super.key, required this.prefix, this.message});

  final String prefix;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _CenteredState(
      stateKey: Key('$prefix-empty'),
      icon: Icons.inbox_outlined,
      iconColor: TongtaiDesignTokens.lightTextSecondary,
      title: message ?? l10n.stateEmpty,
    );
  }
}

/// Loaded, but the domain refuses to conclude (ADR-TON-016).
///
/// Deliberately distinct from both empty and error: "we cannot tell yet" is an
/// answer, and rendering it as zeros would be the fabricated result the Rule
/// Twins exist to prevent.
class TongtaiInsufficientView extends StatelessWidget {
  const TongtaiInsufficientView({
    super.key,
    required this.prefix,
    required this.insufficiency,
    this.extra,
  });

  final String prefix;
  final TongtaiInsufficiency insufficiency;

  /// Real content the screen can still stand behind (a history, a partial
  /// list). Rendered under the refusal, never instead of it.
  final Widget? extra;

  @override
  Widget build(BuildContext context) => _CenteredState(
    stateKey: Key('$prefix-insufficient'),
    icon: Icons.help_outline,
    iconColor: TongtaiDesignTokens.warning,
    title: insufficiency.title ?? context.l10n.stateInsufficientTitle,
    body: insufficiency.body ?? context.l10n.stateInsufficientBody,
    chips: insufficiency.reasons,
    trailing: extra == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: TongtaiDesignTokens.spacing6),
            child: extra,
          ),
  );
}

/// The read failed and there is nothing to fall back on.
///
/// Shows the classified sentence AND the machine-precise [TongtaiFailure.code]
/// — WTM-148 forbids replacing a technical error with a vague one. The raw
/// message sits one tap away rather than in the user's face, but it is never
/// discarded and never sent anywhere.
class TongtaiFailureView extends StatelessWidget {
  const TongtaiFailureView({
    super.key,
    required this.prefix,
    required this.failure,
    this.onRetry,
  });

  final String prefix;
  final TongtaiFailure failure;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _CenteredState(
      stateKey: Key('$prefix-error'),
      icon: Icons.error_outline,
      iconColor: TongtaiDesignTokens.error,
      title: tongtaiFailureTitle(l10n, failure.kind),
      body: tongtaiFailureBody(l10n, failure.kind),
      liveRegion: true,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (failure.isRetryable && onRetry != null) ...[
            const SizedBox(height: TongtaiDesignTokens.spacing4),
            SizedBox(
              height: TongtaiDesignTokens.buttonHeight,
              child: ElevatedButton.icon(
                key: Key('$prefix-error-retry'),
                onPressed: () => onRetry!(),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.stateRetry),
              ),
            ),
          ],
          const SizedBox(height: TongtaiDesignTokens.spacing4),
          _TechnicalDetail(prefix: prefix, failure: failure),
        ],
      ),
    );
  }
}

/// The read failed but the previous value is still on screen.
///
/// The banner is the whole point of keeping that value: data the user can
/// still act on, plus an unambiguous statement of how old it is. Silently
/// showing yesterday's numbers would be worse than showing an error.
class TongtaiStaleBanner extends StatelessWidget {
  const TongtaiStaleBanner({
    super.key,
    required this.prefix,
    required this.failure,
    required this.loadedAt,
    this.onRetry,
  });

  final String prefix;
  final TongtaiFailure failure;
  final DateTime loadedAt;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final time =
        '${loadedAt.hour.toString().padLeft(2, '0')}:'
        '${loadedAt.minute.toString().padLeft(2, '0')}';
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        key: Key('$prefix-stale'),
        width: double.infinity,
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
        color: TongtaiDesignTokens.warning.withValues(alpha: 0.12),
        // Wrap, not Row: at 320 px with large text the retry button drops to
        // its own line instead of overflowing (Testing Bible P-07).
        child: Wrap(
          spacing: TongtaiDesignTokens.spacing3,
          runSpacing: TongtaiDesignTokens.spacing2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(
              Icons.history_toggle_off,
              size: 18,
              color: TongtaiDesignTokens.warning,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.stateStaleTitle,
                    style: TongtaiDesignTokens.smallStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l10n.stateStaleBody(time),
                    key: Key('$prefix-stale-body'),
                    style: TongtaiDesignTokens.captionStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (failure.isRetryable && onRetry != null)
              TextButton(
                key: Key('$prefix-stale-retry'),
                onPressed: () => onRetry!(),
                child: Text(l10n.stateRetry),
              ),
          ],
        ),
      ),
    );
  }
}

/// A busy indicator for an in-place action (an AI explanation, a save) — the
/// single approved way to say "working" outside a full-screen load, so the
/// governance test can ban bare spinners in screens.
class TongtaiInlineBusy extends StatelessWidget {
  const TongtaiInlineBusy({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final text = label ?? context.l10n.stateLoading;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // An action the user explicitly started (an AI call, an export) CAN
        // take seconds, so this one really does animate — the distinction is
        // "did I ask for this?", not "is something happening?".
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: TongtaiDesignTokens.spacing2),
        Flexible(
          child: Text(
            text,
            style: TongtaiDesignTokens.smallStyle.copyWith(
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Failure wording, shared by every surface ────────────────────────────────

/// Headline for a failure kind. A function rather than a map so a new kind is
/// a compile error here, not a silently missing string.
String tongtaiFailureTitle(AppStrings l10n, TongtaiFailureKind kind) =>
    switch (kind) {
      TongtaiFailureKind.storage => l10n.errorStorageTitle,
      TongtaiFailureKind.network => l10n.errorNetworkTitle,
      TongtaiFailureKind.permission => l10n.errorPermissionTitle,
      TongtaiFailureKind.configuration => l10n.errorConfigurationTitle,
      TongtaiFailureKind.unexpected => l10n.errorUnexpectedTitle,
    };

/// What the user can do about it.
String tongtaiFailureBody(AppStrings l10n, TongtaiFailureKind kind) =>
    switch (kind) {
      TongtaiFailureKind.storage => l10n.errorStorageBody,
      TongtaiFailureKind.network => l10n.errorNetworkBody,
      TongtaiFailureKind.permission => l10n.errorPermissionBody,
      TongtaiFailureKind.configuration => l10n.errorConfigurationBody,
      TongtaiFailureKind.unexpected => l10n.errorUnexpectedBody,
    };

/// Surfaces a failed **action** (save, delete, export) without stealing the
/// screen. Loads use [TongtaiScreenData]; one-shot actions use this, so a
/// write can never fail silently the way the export screen's catch-less
/// `try/finally` used to.
void showTongtaiFailure(
  BuildContext context,
  TongtaiFailure failure, {
  VoidCallback? onRetry,
}) {
  final l10n = context.l10n;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        tongtaiFailureTitle(l10n, failure.kind),
        key: const Key('failure-snack'),
      ),
      duration: const Duration(seconds: 6),
      action: failure.isRetryable && onRetry != null
          ? SnackBarAction(label: l10n.stateRetry, onPressed: onRetry)
          : null,
    ),
  );
}

// ── Internals ───────────────────────────────────────────────────────────────

/// The raw exception text, one tap away. Kept verbatim (capped for layout) so
/// a real cause is never traded for a friendly non-statement — and never sent
/// off the device (see [TongtaiFailure.telemetryParams]).
class _TechnicalDetail extends StatefulWidget {
  const _TechnicalDetail({required this.prefix, required this.failure});

  final String prefix;
  final TongtaiFailure failure;

  @override
  State<_TechnicalDetail> createState() => _TechnicalDetailState();
}

class _TechnicalDetailState extends State<_TechnicalDetail> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final detail = widget.failure.detail;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The code is always visible: it is short, stable and the one string
        // worth quoting in a support message.
        Text(
          widget.failure.code,
          key: Key('${widget.prefix}-error-code'),
          textAlign: TextAlign.center,
          style: TongtaiDesignTokens.captionStyle.copyWith(
            color: TongtaiDesignTokens.lightTextSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (detail != null) ...[
          TextButton(
            key: Key('${widget.prefix}-error-detail-toggle'),
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(l10n.stateTechnicalDetail),
          ),
          if (_expanded)
            Text(
              detail,
              key: Key('${widget.prefix}-error-detail'),
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.captionStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
        ],
      ],
    );
  }
}

/// Shared layout for the centred states. Scrollable so nothing clips at
/// 320 px with a 1.3× text scale.
class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.stateKey,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.body,
    this.chips = const <String>[],
    this.trailing,
    this.liveRegion = false,
  });

  final Key stateKey;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? body;
  final List<String> chips;
  final Widget? trailing;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      key: stateKey,
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: iconColor),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TongtaiDesignTokens.bodyStyle.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: TongtaiDesignTokens.spacing2),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          ],
          if (chips.isNotEmpty) ...[
            const SizedBox(height: TongtaiDesignTokens.spacing3),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: TongtaiDesignTokens.spacing2,
              runSpacing: TongtaiDesignTokens.spacing1,
              children: [for (final chip in chips) _ReasonChip(label: chip)],
            ),
          ],
          ?trailing,
        ],
      ),
    );
    return Center(
      child: liveRegion
          ? Semantics(container: true, liveRegion: true, child: content)
          : content,
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: TongtaiDesignTokens.spacing2,
      vertical: 2,
    ),
    decoration: BoxDecoration(
      color: TongtaiDesignTokens.lightHover,
      borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusFull),
    ),
    child: Text(
      label,
      style: TongtaiDesignTokens.captionStyle.copyWith(
        color: TongtaiDesignTokens.lightTextSecondary,
      ),
    ),
  );
}
