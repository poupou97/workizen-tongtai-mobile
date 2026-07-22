import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tongtai_onboarding_provider.dart';
import 'screens/tongtai_onboarding_screen.dart';
import 'tongtai_app_shell.dart';

/// Root entry point for Tổng Tài that shows the onboarding tutorial on first
/// launch, then the main app shell (WTM-59).
///
/// It watches the persisted "onboarding seen" flag: while it is `false` the
/// tutorial is shown, and finishing or skipping it flips the flag (persisted
/// locally) so the app drops straight to Home on every later launch. The
/// Settings "Replay Tutorial" action clears the flag, which brings the gate
/// back here — so re-triggering the tutorial needs no extra navigation.
class TongtaiRootGate extends ConsumerWidget {
  const TongtaiRootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCompletedOnboarding = ref.watch(tongtaiOnboardingProvider);

    if (!hasCompletedOnboarding) {
      return TongtaiOnboardingScreen(
        onFinished: () =>
            ref.read(tongtaiOnboardingProvider.notifier).complete(),
      );
    }

    return const TongtaiAppShell();
  }
}
