import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/telemetry/tongtai_telemetry.dart';

/// WTM-108 (D-7 → ADR-TON-005) — the telemetry seam is privacy-safe by
/// default: without the Founder-provided Firebase config the app runs on the
/// no-op, and initialization can never take the app down.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the provider default is the silent no-op', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final telemetry = container.read(tongtaiTelemetryProvider);
    expect(telemetry, isA<NoopTelemetry>());
    expect(telemetry.enabled, isFalse);
  });

  test('NoopTelemetry swallows events and errors silently', () async {
    const telemetry = NoopTelemetry();
    await telemetry.logEvent('export_run', {'rows': 3});
    await telemetry.recordError(StateError('x'), StackTrace.current);
    // Nothing to observe — the contract is simply "never throws".
  });

  test(
    'initTongtaiTelemetry never throws — no config → no-op fallback',
    () async {
      // In the test environment there is no Firebase platform config, exactly
      // like a build without google-services.json: init must degrade silently.
      final telemetry = await initTongtaiTelemetry();
      expect(telemetry, isA<NoopTelemetry>());
      expect(telemetry.enabled, isFalse);
    },
  );
}
