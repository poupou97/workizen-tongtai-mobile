import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/onboarding/onboarding_conversation.dart';
import 'package:tongtai/features/tongtai/profile/business_profile.dart';

/// WTM-178 — the onboarding conversation engine.
///
/// Pure value logic, so the flow is provable without pumping a widget. The
/// property that matters most: **it never needs AI**, which is why there is
/// nothing to inject and nothing to stub in this file.
void main() {
  group('the script', () {
    test('asks the four profile questions and nothing else', () {
      expect(kOnboardingSteps.map((s) => s.id), [
        'trade',
        'channels',
        'size',
        'seasonality',
      ]);
    });

    test('only the channels step accepts several answers', () {
      final multi = kOnboardingSteps.where((s) => s.multiSelect);
      expect(multi.map((s) => s.id), ['channels']);
    });

    test('every option code is one the profile model recognises', () {
      // A typo here would silently drop an answer: `fromCode` returns null for
      // an unknown code, so the seller would tap a chip and nothing would be
      // saved. Catching it in the script is cheaper than debugging that.
      for (final step in kOnboardingSteps) {
        for (final code in step.optionCodes) {
          final known = switch (step.id) {
            'trade' => BusinessTrade.fromCode(code) != null,
            'size' => BusinessSize.fromCode(code) != null,
            'channels' => SalesChannel.fromCode(code) != null,
            'seasonality' => BusinessSeasonality.fromCode(code) != null,
            _ => false,
          };
          expect(known, isTrue, reason: '${step.id} → "$code" is not a code');
        }
      }
    });

    test('offers every value the model can hold', () {
      // The inverse check: an enum value with no chip is unreachable, so a
      // seller could never describe that business.
      expect(
        kOnboardingSteps[0].optionCodes,
        hasLength(BusinessTrade.values.length),
      );
      expect(
        kOnboardingSteps[1].optionCodes,
        hasLength(SalesChannel.values.length),
      );
      expect(
        kOnboardingSteps[2].optionCodes,
        hasLength(BusinessSize.values.length),
      );
      expect(
        kOnboardingSteps[3].optionCodes,
        hasLength(BusinessSeasonality.values.length),
      );
    });
  });

  group('walking the conversation', () {
    test('starts at the first question with nothing answered', () {
      const c = OnboardingConversation();
      expect(c.currentStep?.id, 'trade');
      expect(c.profile.isEmpty, isTrue);
      expect(c.isComplete, isFalse);
    });

    test('an answer lands on the profile', () {
      final c = const OnboardingConversation().answer('fashion');
      expect(c.profile.trade, BusinessTrade.fashion);
    });

    test('answering does not advance — the seller taps next', () {
      // Auto-advance on tap makes a mis-tap unfixable: the question is gone
      // before you can correct it.
      final c = const OnboardingConversation().answer('fashion');
      expect(c.currentStep?.id, 'trade');
    });

    test('runs the whole script to completion', () {
      var c = const OnboardingConversation()
          .answer('food')
          .next()
          .answer('shopee')
          .answer('zalo')
          .next()
          .answer('solo')
          .next()
          .answer('tet')
          .next();

      expect(c.isComplete, isTrue);
      expect(c.currentStep, isNull);
      expect(c.profile.trade, BusinessTrade.food);
      expect(c.profile.channels, hasLength(2));
      expect(c.profile.size, BusinessSize.solo);
      expect(c.profile.seasonality, BusinessSeasonality.tet);
    });

    test('skipping every question completes with an empty profile', () {
      // The most common path for a hurried seller, and it must be a normal
      // outcome rather than an error state.
      var c = const OnboardingConversation();
      for (var i = 0; i < kOnboardingSteps.length; i++) {
        c = c.next();
      }
      expect(c.isComplete, isTrue);
      expect(c.profile.isEmpty, isTrue);
    });
  });

  group('correcting an answer', () {
    test('tapping the selected option clears it', () {
      final c = const OnboardingConversation()
          .answer('fashion')
          .answer('fashion');
      expect(c.profile.trade, isNull);
    });

    test('picking a different option replaces the first', () {
      final c = const OnboardingConversation()
          .answer('fashion')
          .answer('cosmetics');
      expect(c.profile.trade, BusinessTrade.cosmetics);
    });

    test('channels toggle independently', () {
      final c = const OnboardingConversation()
          .next()
          .answer('shop')
          .answer('zalo')
          .answer('shop');
      expect(c.profile.channels, [SalesChannel.zalo]);
    });

    test('going back shows what was already answered', () {
      // A conversation that forgets what you just told it does not feel like
      // one.
      final c = const OnboardingConversation().answer('food').next().back();
      expect(c.currentStep?.id, 'trade');
      expect(c.selectedCodes, {'food'});
    });

    test('an earlier answer survives answering later questions', () {
      final c = const OnboardingConversation()
          .answer('food')
          .next()
          .answer('shop')
          .next()
          .answer('solo');
      expect(c.profile.trade, BusinessTrade.food);
      expect(c.profile.channels, [SalesChannel.shop]);
    });
  });

  group('edges', () {
    test('back at the first question stays put', () {
      expect(const OnboardingConversation().back().stepIndex, 0);
    });

    test('next past the end stays complete', () {
      var c = const OnboardingConversation();
      for (var i = 0; i < kOnboardingSteps.length + 3; i++) {
        c = c.next();
      }
      expect(c.stepIndex, kOnboardingSteps.length);
    });

    test('answering after completion is a no-op, not a crash', () {
      var c = const OnboardingConversation();
      for (var i = 0; i < kOnboardingSteps.length; i++) {
        c = c.next();
      }
      expect(c.answer('fashion').profile.isEmpty, isTrue);
    });

    test('an unknown code is ignored rather than stored', () {
      final c = const OnboardingConversation().answer('quantum_widgets');
      expect(c.profile.trade, isNull);
    });
  });
}
