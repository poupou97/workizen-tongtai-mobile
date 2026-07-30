import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Operational telemetry seam (WTM-108, D-7 → ADR-TON-005).
///
/// **Policy (Founder red-lines):** operational events + crash reporting ONLY,
/// for closed-beta quality. No ad SDKs, no marketing tracking, no user
/// profiling, no personalized ads — ever. Business data never leaves the
/// device through this seam: events carry counts/flags, never content.
///
/// **Build-safe by design:** the app initializes Firebase only when the
/// Founder-provided platform config exists (google-services.json /
/// GoogleService-Info.plist). Without it, [initTongtaiTelemetry] returns the
/// no-op implementation and the app behaves exactly as before.
abstract interface class TongtaiTelemetry {
  /// Whether a real backend is attached (false = no-op).
  bool get enabled;

  /// Logs one operational event (screen opened, export run, …). [params]
  /// must be counts/flags only — never business content.
  Future<void> logEvent(String name, [Map<String, Object>? params]);

  /// Records a non-fatal error for crash triage.
  Future<void> recordError(Object error, StackTrace? stack);
}

/// The privacy-safe default: does nothing, everywhere.
class NoopTelemetry implements TongtaiTelemetry {
  const NoopTelemetry();

  @override
  bool get enabled => false;

  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) async {}

  @override
  Future<void> recordError(Object error, StackTrace? stack) async {}
}

/// Firebase-backed telemetry (Analytics + Crashlytics), used only when the
/// platform config exists and initialization succeeded.
class FirebaseTelemetry implements TongtaiTelemetry {
  const FirebaseTelemetry(this._analytics, this._crashlytics);

  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;

  @override
  bool get enabled => true;

  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) =>
      _analytics.logEvent(name: name, parameters: params);

  @override
  Future<void> recordError(Object error, StackTrace? stack) =>
      _crashlytics.recordError(error, stack);
}

/// Riverpod seam — overridden in main() with the initialized implementation;
/// the no-op default keeps every test and headless context silent.
final tongtaiTelemetryProvider = Provider<TongtaiTelemetry>(
  (ref) => const NoopTelemetry(),
);

/// Initializes telemetry per D-7: Firebase when the platform config exists,
/// the no-op otherwise. Never throws — a telemetry problem must never take
/// the app down (quality tooling, not a feature).
Future<TongtaiTelemetry> initTongtaiTelemetry() async {
  try {
    await Firebase.initializeApp();
    final crashlytics = FirebaseCrashlytics.instance;
    // Crash reporting only outside debug builds; debug noise helps nobody.
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    return FirebaseTelemetry(FirebaseAnalytics.instance, crashlytics);
  } catch (_) {
    // No config file (or init failure) → privacy-safe silence.
    return const NoopTelemetry();
  }
}
