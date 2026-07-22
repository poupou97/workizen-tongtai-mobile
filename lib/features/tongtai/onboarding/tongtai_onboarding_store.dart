import 'package:shared_preferences/shared_preferences.dart';

/// Persistence boundary for the "has the user seen onboarding?" flag (WTM-59).
///
/// The read is synchronous so the Riverpod controller can decide on first build
/// — before the first frame — whether to show the tutorial, with no async gap
/// that would let Home flash first. Writes are async because the underlying
/// platform store is. Follows the same interface + in-memory-fake pattern as the
/// tab-state store (WTM-56) so the controller is testable without platform
/// channels.
abstract interface class TongtaiOnboardingStore {
  /// `true` once the user has completed or skipped the tutorial. `false` on a
  /// fresh install, so the tutorial shows exactly once on first launch.
  bool isCompleted();

  /// Records that the tutorial has been seen (completed or skipped).
  Future<void> markCompleted();

  /// Clears the flag so the tutorial can be replayed (Settings re-trigger).
  Future<void> reset();

  /// SharedPreferences key holding the completion flag.
  static const String storageKey = 'tongtai.onboarding_completed';
}

/// Production store backed by [SharedPreferences]. The flag is a simple bool;
/// no secure storage is needed as this carries no sensitive data.
class SharedPrefsTongtaiOnboardingStore implements TongtaiOnboardingStore {
  SharedPrefsTongtaiOnboardingStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  bool isCompleted() =>
      _prefs.getBool(TongtaiOnboardingStore.storageKey) ?? false;

  @override
  Future<void> markCompleted() =>
      _prefs.setBool(TongtaiOnboardingStore.storageKey, true);

  @override
  Future<void> reset() => _prefs.remove(TongtaiOnboardingStore.storageKey);
}

/// In-memory store for tests (no platform channels required).
class InMemoryTongtaiOnboardingStore implements TongtaiOnboardingStore {
  InMemoryTongtaiOnboardingStore([this._completed = false]);

  bool _completed;

  @override
  bool isCompleted() => _completed;

  @override
  Future<void> markCompleted() async => _completed = true;

  @override
  Future<void> reset() async => _completed = false;
}
