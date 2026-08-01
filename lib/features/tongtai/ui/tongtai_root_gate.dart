import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tongtai_onboarding_provider.dart';
import 'screens/tongtai_onboarding_conversation_screen.dart';
import 'tongtai_app_shell.dart';

/// Root entry point for Tổng Tài that shows the onboarding conversation on
/// first launch, then the main app shell (WTM-59, conversation since WTM-178).
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
      // WTM-178: six static slides replaced by a conversation. The slides told
      // a seller what the app has; the conversation asks what the seller does,
      // and the answers make every later AI reply specific instead of generic.
      return TongtaiOnboardingConversationScreen(
        onDone: () => ref.read(tongtaiOnboardingProvider.notifier).complete(),
      );
    }

    return const TongtaiAppShell();
  }
}
