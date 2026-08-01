import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../core/screen_data_controller.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../onboarding/onboarding_conversation.dart';
import '../../providers/tongtai_profile_provider.dart';
import '../widgets/tongtai_screen_data.dart' show showTongtaiFailure;

/// AI-first onboarding — a conversation instead of six slides (WTM-178).
///
/// ## It runs with no AI
/// The epic listed "an escape route for sellers without an API key" as one
/// story. WTM-176 showed that route is the **main road**: most target users
/// have no key and LAN AI is not built yet. A conversation that needed a
/// provider would make the very first screen of the product an error message.
///
/// So the script is deterministic (`onboarding_conversation.dart`) and this
/// screen never calls a model. What it collects is the WTM-177 profile, which
/// is what makes later AI answers specific — the payoff is deferred, not the
/// conversation.
///
/// ## No text input, anywhere
/// Same boundary as the profile editor: every answer is a chip from a closed
/// vocabulary, so nothing a seller types can end up in an AI prompt.
class TongtaiOnboardingConversationScreen extends ConsumerStatefulWidget {
  const TongtaiOnboardingConversationScreen({super.key, required this.onDone});

  /// Called once the seller leaves the conversation, however they leave it.
  final VoidCallback onDone;

  @override
  ConsumerState<TongtaiOnboardingConversationScreen> createState() =>
      _TongtaiOnboardingConversationScreenState();
}

class _TongtaiOnboardingConversationScreenState
    extends ConsumerState<TongtaiOnboardingConversationScreen> {
  OnboardingConversation _c = const OnboardingConversation();
  bool _started = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TongtaiDesignTokens.spacing5),
          child: !_started
              ? _Greeting(
                  onStart: () => setState(() => _started = true),
                  // One tap straight into the app. The slide tutorial had a
                  // single "skip"; without this the conversation would cost a
                  // new seller six taps to get past — a regression dressed up
                  // as an improvement.
                  onSkipAll: widget.onDone,
                )
              : _c.isComplete
              ? _Closing(
                  profileIsEmpty: _c.profile.isEmpty,
                  saving: _saving,
                  onDone: _finish,
                )
              : _Question(
                  conversation: _c,
                  onAnswer: (code) => setState(() => _c = _c.answer(code)),
                  onNext: () => setState(() => _c = _c.next()),
                  onBack: _c.stepIndex == 0
                      ? null
                      : () => setState(() => _c = _c.back()),
                ),
        ),
      ),
      bottomNavigationBar: !_started || _c.isComplete
          ? null
          : _SkipBar(
              label: l10n.obSkip,
              onSkip: () => setState(() => _c = _c.next()),
            ),
    );
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    // An empty profile is not worth a write — and writing one would stamp an
    // `updatedAt` that claims the seller answered when they skipped everything.
    if (_c.profile.isNotEmpty) {
      final failure = await runTongtaiAction(
        () => ref.read(businessProfileRepositoryProvider).save(_c.profile),
        screen: 'onboarding',
      );
      if (!mounted) return;
      if (failure != null) {
        setState(() => _saving = false);
        // Onboarding must never trap a new seller: the failure is reported,
        // and the app opens anyway. Losing four categorical answers is not
        // worth blocking someone's first launch over.
        showTongtaiFailure(context, failure);
        widget.onDone();
        return;
      }
      ref.invalidate(businessProfileProvider);
    }
    if (!mounted) return;
    widget.onDone();
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.onStart, required this.onSkipAll});

  final VoidCallback onStart;
  final VoidCallback onSkipAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Scrollable, not a fixed Column with Spacers: at a 2.0x system font the
    // greeting body grows past the screen and a rigid layout overflowed by
    // 79px. Someone who needs large text is exactly the person who cannot
    // afford the first screen of the app to be broken.
    return ListView(
      key: const Key('onboarding-greeting'),
      children: [
        const SizedBox(height: TongtaiDesignTokens.spacing10),
        Text(l10n.obGreeting, style: TongtaiDesignTokens.heading1Style),
        const SizedBox(height: TongtaiDesignTokens.spacing4),
        Text(
          l10n.obGreetingBody,
          style: TongtaiDesignTokens.bodyStyle.copyWith(
            color: TongtaiDesignTokens.lightTextPrimary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing8),
        SizedBox(
          height: TongtaiDesignTokens.buttonHeight,
          child: FilledButton(
            key: const Key('onboarding-start'),
            onPressed: onStart,
            child: Text(l10n.obStart),
          ),
        ),
        Center(
          child: TextButton(
            key: const Key('onboarding-skip-all'),
            onPressed: onSkipAll,
            child: Text(l10n.obSkip),
          ),
        ),
      ],
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({
    required this.conversation,
    required this.onAnswer,
    required this.onNext,
    required this.onBack,
  });

  final OnboardingConversation conversation;
  final ValueChanged<String> onAnswer;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  String _optionLabel(AppStrings l10n, String stepId, String code) =>
      switch (stepId) {
        'trade' => l10n.profileTrade(code),
        'size' => l10n.profileSize(code),
        'channels' => l10n.profileChannel(code),
        _ => l10n.profileSeasonality(code),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final step = conversation.currentStep!;
    final selected = conversation.selectedCodes;
    return ListView(
      key: const Key('onboarding-question'),
      children: [
        Text(
          '${l10n.obProgress} ${conversation.stepIndex + 1}/'
          '${kOnboardingSteps.length}',
          key: const Key('onboarding-progress'),
          style: TongtaiDesignTokens.captionStyle.copyWith(
            color: TongtaiDesignTokens.lightTextSecondary,
          ),
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        Text(
          l10n.obQuestion(step.id),
          key: const Key('onboarding-prompt'),
          style: TongtaiDesignTokens.heading2Style.copyWith(
            color: TongtaiDesignTokens.lightTextPrimary,
          ),
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing5),
        Wrap(
          spacing: TongtaiDesignTokens.spacing2,
          runSpacing: TongtaiDesignTokens.spacing2,
          children: [
            for (var i = 0; i < step.optionCodes.length; i++)
              ChoiceChip(
                key: Key('onboarding-option-$i'),
                label: Text(_optionLabel(l10n, step.id, step.optionCodes[i])),
                selected: selected.contains(step.optionCodes[i]),
                onSelected: (_) => onAnswer(step.optionCodes[i]),
              ),
          ],
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing6),
        Row(
          children: [
            if (onBack != null)
              TextButton(
                key: const Key('onboarding-back'),
                onPressed: onBack,
                child: Text(l10n.obBack),
              ),
            const Spacer(),
            SizedBox(
              height: TongtaiDesignTokens.buttonHeight,
              child: FilledButton(
                key: const Key('onboarding-next'),
                onPressed: onNext,
                child: Text(l10n.obNext),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Closing extends StatelessWidget {
  const _Closing({
    required this.profileIsEmpty,
    required this.saving,
    required this.onDone,
  });

  final bool profileIsEmpty;
  final bool saving;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      key: const Key('onboarding-closing'),
      children: [
        const SizedBox(height: TongtaiDesignTokens.spacing10),
        Text(
          // A seller who skipped everything must not be thanked for answers
          // they did not give — it reads as the app not listening.
          profileIsEmpty ? l10n.obClosingEmpty : l10n.obClosing,
          key: const Key('onboarding-closing-text'),
          style: TongtaiDesignTokens.bodyStyle.copyWith(
            color: TongtaiDesignTokens.lightTextPrimary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing8),
        SizedBox(
          height: TongtaiDesignTokens.buttonHeight,
          child: FilledButton(
            key: const Key('onboarding-done'),
            onPressed: saving ? null : onDone,
            child: Text(l10n.obDone),
          ),
        ),
      ],
    );
  }
}

class _SkipBar extends StatelessWidget {
  const _SkipBar({required this.label, required this.onSkip});

  final String label;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    // `bottomNavigationBar` imposes no height, so an expanding child (a bare
    // `Center`) grows to fill the Scaffold and squeezes the body to nothing.
    // The first version of this bar did exactly that: the question list got
    // ~0 height, its children were never built, and taps "missed" widgets that
    // were technically present. Bound the height explicitly.
    return SizedBox(
      height: TongtaiDesignTokens.buttonHeight + TongtaiDesignTokens.spacing4,
      child: SafeArea(
        child: Center(
          child: TextButton(
            key: const Key('onboarding-skip'),
            onPressed: onSkip,
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
