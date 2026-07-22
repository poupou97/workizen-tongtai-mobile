import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tongtai/core/prefs.dart' show sharedPreferencesProvider;
import '../onboarding/tongtai_onboarding_store.dart';

/// Persistence boundary for the onboarding completion flag (WTM-59).
///
/// Defaults to the SharedPreferences-backed store; tests override this with an
/// [InMemoryTongtaiOnboardingStore].
final tongtaiOnboardingStoreProvider = Provider<TongtaiOnboardingStore>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefsTongtaiOnboardingStore(prefs);
});

/// Whether the first-launch onboarding tutorial has already been seen.
///
/// The value is hydrated synchronously from local storage on first read, so the
/// root gate can decide what to show before the first frame — no Home flash. The
/// notifier exposes [TongtaiOnboardingController.complete] (finish/skip) and
/// [TongtaiOnboardingController.reset] (replay from Settings).
final tongtaiOnboardingProvider =
    NotifierProvider<TongtaiOnboardingController, bool>(
  TongtaiOnboardingController.new,
);

class TongtaiOnboardingController extends Notifier<bool> {
  TongtaiOnboardingStore get _store => ref.read(tongtaiOnboardingStoreProvider);

  /// `true` when onboarding has been completed/skipped and should not show.
  @override
  bool build() => ref.watch(tongtaiOnboardingStoreProvider).isCompleted();

  /// Marks the tutorial as seen (called on finish or skip) and persists it, so
  /// it never shows again on subsequent launches.
  Future<void> complete() async {
    state = true;
    await _store.markCompleted();
  }

  /// Clears the flag so the tutorial replays — used by the Settings
  /// "Replay Tutorial" action.
  Future<void> reset() async {
    state = false;
    await _store.reset();
  }
}
