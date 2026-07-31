library;

import 'dart:async';

import 'package:flutter/foundation.dart';

/// The **shared screen-state contract** for Tổng Tài (WTM-148, ADR-TON-017).
///
/// Every screen that reads data through an IO boundary — repository, Drift,
/// file, provider — represents what it knows with [ScreenState] and what went
/// wrong with [TongtaiFailure]. One vocabulary, one set of states, one place
/// to fix a whole class of bug.
///
/// **Why this exists.** Before WTM-148 exactly one of 34 screens handled a
/// failing load. Everywhere else the pattern was `initState → _load() →
/// setState`, so a throwing repository left the screen at its initial empty
/// value forever: **"there is no data" and "I could not read the data" looked
/// identical**. That is the same confusion that produced the Consumer count
/// bug (Testing Bible P-03) — a screen that shows nothing and says nothing.
///
/// The states are deliberately six, not two:
///
/// | State | Meaning |
/// |---|---|
/// | loading | first read in flight, nothing known yet |
/// | ready | value in hand |
/// | empty | value in hand and it legitimately holds no records |
/// | insufficient | value in hand, but the domain refuses to conclude |
/// | refreshing | value in hand, a newer read is in flight |
/// | failed | the read threw — with the previous value kept if there was one |
///
/// `empty` and `insufficient` are *answers*. `failed` is the absence of one.
/// Collapsing them is the bug this seam exists to prevent.

// ── Failure classification ──────────────────────────────────────────────────

/// What kind of thing went wrong. Coarse on purpose: the kind decides the
/// wording and whether a retry is even offered, so a long tail of kinds would
/// only produce a long tail of near-identical messages.
enum TongtaiFailureKind {
  /// The local database or a file could not be read/written.
  storage,

  /// The device could not reach a remote service (BYOK provider, …).
  network,

  /// The OS refused (camera, storage). Retrying the same call changes nothing
  /// until the user grants access.
  permission,

  /// Something the user must set up first — a missing BYOK key, an exhausted
  /// quota. Not a transient fault, so retry is not offered.
  configuration,

  /// Unclassified. Shown as-is rather than dressed up: an honest "unexpected"
  /// with the real exception beats a friendly lie.
  unexpected;

  /// Whether re-running the *same* operation could plausibly succeed.
  ///
  /// [permission] and [configuration] are false because the fix lives outside
  /// the failed call — offering "Retry" there teaches the user that the button
  /// does nothing.
  bool get isRetryable => switch (this) {
    TongtaiFailureKind.storage => true,
    TongtaiFailureKind.network => true,
    TongtaiFailureKind.unexpected => true,
    TongtaiFailureKind.permission => false,
    TongtaiFailureKind.configuration => false,
  };
}

/// An error that already knows how it should be classified.
///
/// Lets a feature module (AI, backup crypto) declare its own mapping without
/// this file importing that module — the dependency points **inwards**, so the
/// seam stays free of feature imports and any module can join it later.
abstract interface class TongtaiClassifiedError {
  /// This error, expressed in the shared vocabulary.
  TongtaiFailure get failure;
}

/// A classified failure: what kind, a stable [code], and the technical truth.
///
/// **Privacy split (Founder red-line, ADR-TON-005/016).** [detail] may quote
/// the raw exception — the user is looking at their own device and their own
/// data, and WTM-148 explicitly forbids replacing a technical error with a
/// vague one. [telemetryParams] and [toString] carry **only** [kind] and
/// [code], which are bounded, developer-authored tokens. A SQLite message can
/// embed a row value; that value must never leave the device. The negative
/// control in `predictive_privacy_test`-style tests asserts exactly this.
@immutable
class TongtaiFailure implements Exception {
  const TongtaiFailure({
    required this.kind,
    required this.code,
    this.detail,
    this.cause,
    this.stackTrace,
  }) : assert(code != '', 'a failure must carry a stable, non-empty code');

  /// Coarse category — drives wording and whether retry is offered.
  final TongtaiFailureKind kind;

  /// Stable, low-cardinality, telemetry-safe token (`storage.sqlite_787`).
  /// Developer-authored or derived from a type name — never from data.
  final String code;

  /// The technical truth, for the person holding the phone. **Never sent
  /// anywhere.** Null when the source carried nothing useful.
  final String? detail;

  /// The original error, for tests and local logging.
  final Object? cause;

  final StackTrace? stackTrace;

  /// Whether the UI should offer a retry affordance.
  bool get isRetryable => kind.isRetryable;

  /// Classifies an arbitrary thrown object.
  ///
  /// Matching is by **runtime type name**, not by importing sqlite3/dart:io
  /// types, so this file depends on nothing and a package swap cannot break
  /// the seam's compilation. Unknown errors land in [TongtaiFailureKind
  /// .unexpected] with their type name as the code — visible and greppable
  /// rather than silently bucketed.
  factory TongtaiFailure.from(Object error, [StackTrace? stackTrace]) {
    if (error is TongtaiFailure) {
      return stackTrace == null ? error : error._withStack(stackTrace);
    }
    if (error is TongtaiClassifiedError) {
      final failure = error.failure;
      return TongtaiFailure(
        kind: failure.kind,
        code: failure.code,
        detail: failure.detail ?? _detailOf(error),
        cause: error,
        stackTrace: stackTrace ?? failure.stackTrace,
      );
    }
    if (error is TimeoutException) {
      return TongtaiFailure(
        kind: TongtaiFailureKind.network,
        code: 'network.timeout',
        detail: _detailOf(error),
        cause: error,
        stackTrace: stackTrace,
      );
    }

    final typeName = error.runtimeType.toString();
    final (kind, code) = _classifyByTypeName(typeName, error);
    return TongtaiFailure(
      kind: kind,
      code: code,
      detail: _detailOf(error),
      cause: error,
      stackTrace: stackTrace,
    );
  }

  static (TongtaiFailureKind, String) _classifyByTypeName(
    String typeName,
    Object error,
  ) {
    // Local persistence — Drift and the sqlite3 bindings under it.
    if (typeName == 'SqliteException') {
      // The numeric result code is part of the exception's own text and is a
      // SQLite constant, never data: `SqliteException(787): FOREIGN KEY …`.
      final match = RegExp(r'\((\d+)\)').firstMatch(error.toString());
      final resultCode = match?.group(1);
      return (
        TongtaiFailureKind.storage,
        resultCode == null ? 'storage.sqlite' : 'storage.sqlite_$resultCode',
      );
    }
    if (typeName.startsWith('Drift') ||
        typeName == 'CouldNotRollBackException') {
      return (TongtaiFailureKind.storage, 'storage.drift');
    }
    if (typeName == 'SchemaIntegrityException') {
      return (TongtaiFailureKind.storage, 'storage.schema');
    }

    // Files: a denied path is a permission problem, a missing/broken one is
    // storage. Different sentence, different affordance.
    if (typeName == 'PathAccessException') {
      return (TongtaiFailureKind.permission, 'permission.file');
    }
    if (typeName == 'PathNotFoundException' ||
        typeName == 'PathExistsException' ||
        typeName == 'FileSystemException') {
      return (TongtaiFailureKind.storage, 'storage.file');
    }

    // Reaching a BYOK provider.
    if (typeName == 'SocketException' ||
        typeName == 'HandshakeException' ||
        typeName == 'HttpException' ||
        typeName == 'ClientException' ||
        typeName == 'WebSocketException') {
      return (TongtaiFailureKind.network, 'network.io');
    }

    // OS-level refusals we can name.
    if (typeName == 'MobileScannerException' ||
        typeName == 'CameraException' ||
        typeName == 'PermissionException') {
      return (TongtaiFailureKind.permission, 'permission.device');
    }

    return (TongtaiFailureKind.unexpected, 'unexpected.${_slug(typeName)}');
  }

  /// Keeps a type name usable as a telemetry token: identifier characters
  /// only, bounded length. Generic types (`_Foo<Bar>`) collapse to their base.
  static String _slug(String typeName) {
    final cleaned = typeName.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');
    return cleaned.isEmpty
        ? 'Unknown'
        : cleaned.substring(0, cleaned.length.clamp(0, 40));
  }

  /// The raw message, trimmed and length-capped so one runaway exception
  /// cannot push the retry button off a 320 px screen.
  static String? _detailOf(Object error) {
    final text = error.toString().trim();
    if (text.isEmpty) return null;
    return text.length <= 300 ? text : '${text.substring(0, 300)}…';
  }

  TongtaiFailure _withStack(StackTrace stackTrace) => TongtaiFailure(
    kind: kind,
    code: code,
    detail: detail,
    cause: cause,
    stackTrace: stackTrace,
  );

  /// The **only** shape that may be sent to telemetry (ADR-TON-005): two
  /// bounded developer-authored tokens, no message, no data.
  Map<String, Object> get telemetryParams => <String, Object>{
    'kind': kind.name,
    'code': code,
  };

  /// Deliberately excludes [detail]: crash reporters record `toString()`, and
  /// this object must stay safe to hand to one.
  @override
  String toString() => 'TongtaiFailure(${kind.name}/$code)';

  @override
  bool operator ==(Object other) =>
      other is TongtaiFailure &&
      other.kind == kind &&
      other.code == code &&
      other.detail == detail;

  @override
  int get hashCode => Object.hash(kind, code, detail);
}

// ── The domain's honest non-answer ──────────────────────────────────────────

/// The data loaded fine, but the domain **refuses to conclude** from it.
///
/// A Rule Twin with `DataSufficiency.insufficient` (ADR-TON-016) is the
/// canonical producer, but the state is not predictive-specific: any screen
/// whose answer needs a minimum the data does not meet can use it. Kept as
/// plain localized strings so this seam never imports the predictive layer.
///
/// This is NOT an error and NOT empty — rendering it as either is precisely
/// the fabricated-answer failure the twins were built to avoid.
@immutable
class TongtaiInsufficiency {
  const TongtaiInsufficiency({
    this.title,
    this.body,
    this.reasons = const <String>[],
  });

  /// Headline, already localized ("Chưa đủ dữ liệu để dự báo"). Null falls
  /// back to the shared `stateInsufficientTitle` — a domain only overrides it
  /// when it has something more specific to say than "not enough data".
  final String? title;

  /// One sentence on what would make an answer possible. Null falls back to
  /// the shared `stateInsufficientBody`.
  final String? body;

  /// Localized reason codes — the SAME reasons the rule reported, so screen
  /// and AI prose can never tell two stories.
  final List<String> reasons;
}

// ── Screen state ────────────────────────────────────────────────────────────

/// Which of the six states a screen is in. See the library doc for the table.
enum ScreenPhase {
  /// First read in flight; nothing is known yet.
  loading,

  /// A value is in hand.
  ready,

  /// A value is in hand and a newer read is in flight (pull-to-refresh,
  /// returning from a form). The old value stays on screen — a refresh must
  /// never blank a working page.
  refreshing,

  /// The read threw. [ScreenState.value] may still hold the previous value,
  /// which makes the state *stale* rather than empty.
  failed,
}

/// What a screen knows, and how sure it is of it.
///
/// Invariants are enforced in the constructor rather than described in a
/// comment (the ADR-TON-016 lesson — a rule a type cannot express is a rule
/// that eventually gets broken):
///
/// - `failed` ⟺ a [failure] is present;
/// - `ready`/`refreshing` ⟹ a [value] is present;
/// - a [value] always carries the [loadedAt] it was read at, so "showing data
///   from 09:41" is always sayable.
@immutable
class ScreenState<T> {
  const ScreenState._({
    required this.phase,
    this.value,
    this.failure,
    this.loadedAt,
  }) : assert(
         (phase == ScreenPhase.failed) == (failure != null),
         'failed ⟺ failure — a failed state without its failure is exactly '
         'the silent-empty bug WTM-148 removes',
       ),
       assert(
         phase != ScreenPhase.ready && phase != ScreenPhase.refreshing ||
             value != null,
         'ready/refreshing must carry a value',
       ),
       assert(
         (value == null) == (loadedAt == null),
         'a value must record when it was loaded (stale display depends on it)',
       );

  /// Nothing known yet — the first read is in flight.
  const ScreenState.loading() : this._(phase: ScreenPhase.loading);

  /// A fresh value. Redirects through the private constructor so the
  /// invariants above hold for every way a state can be built.
  const ScreenState.ready(T value, {required DateTime loadedAt})
    : this._(phase: ScreenPhase.ready, value: value, loadedAt: loadedAt);

  /// A failure with no previous value to fall back on.
  const ScreenState.failed(TongtaiFailure failure)
    : this._(phase: ScreenPhase.failed, failure: failure);

  final ScreenPhase phase;

  /// The last successfully loaded value, if any. Survives a failed refresh —
  /// that is what makes stale data possible instead of a blanked screen.
  final T? value;

  /// Present exactly when [phase] is [ScreenPhase.failed].
  final TongtaiFailure? failure;

  /// When [value] was read. Present exactly when [value] is.
  final DateTime? loadedAt;

  bool get hasValue => value != null;
  bool get isLoading => phase == ScreenPhase.loading;
  bool get isRefreshing => phase == ScreenPhase.refreshing;
  bool get hasFailed => phase == ScreenPhase.failed;

  /// A failure **on top of** a value the user can still read. The screen keeps
  /// showing the data and says plainly that it is not current.
  bool get isStale => hasFailed && hasValue;

  /// Marks a newer read as in flight, keeping the current value visible.
  /// A no-op when nothing is known yet — that is still plain [loading].
  ScreenState<T> toRefreshing() => hasValue
      ? ScreenState<T>._(
          phase: ScreenPhase.refreshing,
          value: value,
          loadedAt: loadedAt,
        )
      : ScreenState<T>.loading();

  /// Records [next] as the current value, read at [at].
  ScreenState<T> toReady(T next, DateTime at) =>
      ScreenState<T>.ready(next, loadedAt: at);

  /// Records a failure, **keeping any value already on screen** so a broken
  /// refresh degrades to stale instead of wiping the page.
  ScreenState<T> toFailed(TongtaiFailure failure) => ScreenState<T>._(
    phase: ScreenPhase.failed,
    value: value,
    failure: failure,
    loadedAt: loadedAt,
  );

  @override
  String toString() =>
      'ScreenState<$T>(${phase.name}'
      '${hasValue ? ', value' : ''}${failure == null ? '' : ', $failure'})';
}
