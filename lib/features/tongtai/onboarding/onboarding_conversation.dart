/// The onboarding conversation — deterministic, and it runs with **no AI at
/// all** (WTM-178).
///
/// ## Why the script is rule-based
/// The epic asks for "ấn tượng đầu là hội thoại, không phải slide", and lists a
/// fallback for sellers without an API key. WTM-176 turned that around: most of
/// the target users **have no API key**, and LAN AI is not built. A conversation
/// that needs a provider would make the first screen of the product an error
/// message for the majority.
///
/// So the fallback is the **main path**. This file is a Rule Twin in the sense
/// of ADR-TON-016: it produces the whole flow from the seller's answers, with
/// no network, no key and no model. AI, when present, may *add* a sentence — it
/// may never be required for a step to appear.
///
/// ## What it collects
/// Exactly the four [BusinessProfile] questions, in the order that reads like a
/// conversation rather than a form. Nothing else: the profile's privacy
/// boundary (WTM-177) is the boundary here too, which is why every step offers
/// **choices**, never a text box.
library;

import '../profile/business_profile.dart';

/// One question in the conversation.
class OnboardingStep {
  const OnboardingStep({
    required this.id,
    required this.optionCodes,
    this.multiSelect = false,
  });

  /// Stable id — used for the l10n key, the test key and the analytics-free
  /// progress state. Never shown.
  final String id;

  /// Canonical codes of the answers offered, in display order.
  final List<String> optionCodes;

  /// Whether the seller may pick several (only the channels step).
  final bool multiSelect;
}

/// The script. Order matters: trade first because it is the question a seller
/// can answer without thinking, and the one that makes every later question
/// feel relevant.
/// WTM-232: không còn `const` vì bước "kênh bán" suy thẳng từ `SalesChannel`
/// thay vì chép tay — danh sách chép tay vừa để sót ba kênh số mới, và người
/// bán sản phẩm số sẽ đi qua onboarding mà không có ô nào đúng để chọn.
final List<OnboardingStep> kOnboardingSteps = [
  OnboardingStep(
    id: 'trade',
    optionCodes: [
      'fashion',
      'food',
      'cosmetics',
      'electronics',
      'home_goods',
      'services',
      'other',
    ],
  ),
  OnboardingStep(
    id: 'channels',
    // WTM-232: suy thẳng từ enum thay vì chép tay. Danh sách chép tay này
    // vừa để sót ba kênh số mới, và người bán sản phẩm số sẽ đi qua onboarding
    // mà không có ô nào đúng để chọn — đúng vấn đề story đang sửa.
    optionCodes: [for (final c in SalesChannel.values) c.code],
    multiSelect: true,
  ),
  OnboardingStep(
    id: 'size',
    optionCodes: ['solo', 'small', 'growing', 'established'],
  ),
  OnboardingStep(
    id: 'seasonality',
    optionCodes: ['none', 'tet', 'school_year', 'summer', 'year_end'],
  ),
];

/// Immutable progress through the script.
///
/// Held as a value rather than as widget state so the flow can be tested
/// without pumping a widget, and so "back" is a plain arithmetic operation
/// instead of a stack of navigator routes.
class OnboardingConversation {
  const OnboardingConversation({
    this.stepIndex = 0,
    this.profile = BusinessProfile.empty,
  });

  final int stepIndex;
  final BusinessProfile profile;

  bool get isComplete => stepIndex >= kOnboardingSteps.length;

  /// The step being asked, or `null` once the conversation is over.
  OnboardingStep? get currentStep =>
      isComplete ? null : kOnboardingSteps[stepIndex];

  /// Answers already given for [currentStep], as canonical codes.
  ///
  /// Drives the "chips come back selected when you go back" behaviour — a
  /// conversation that forgets what you just told it does not feel like one.
  Set<String> get selectedCodes {
    final step = currentStep;
    if (step == null) return const {};
    return switch (step.id) {
      'trade' => {?profile.trade?.code},
      'size' => {?profile.size?.code},
      'channels' => profile.channels.map((c) => c.code).toSet(),
      'seasonality' => {?profile.seasonality?.code},
      _ => const {},
    };
  }

  /// Records an answer for the current step. Tapping a selected option clears
  /// it — the same rule as the profile editor, for the same reason: an answer
  /// given by mistake has to be removable.
  OnboardingConversation answer(String code) {
    final step = currentStep;
    if (step == null) return this;
    final selected = selectedCodes.contains(code);
    return copyWith(
      profile: switch (step.id) {
        'trade' => _withTrade(selected ? null : BusinessTrade.fromCode(code)),
        'size' => _withSize(selected ? null : BusinessSize.fromCode(code)),
        'seasonality' => _withSeasonality(
          selected ? null : BusinessSeasonality.fromCode(code),
        ),
        'channels' => _withChannelToggled(code, on: !selected),
        _ => profile,
      },
    );
  }

  /// Moves on. Skipping is answering nothing — deliberately the same operation,
  /// so a seller who taps "bỏ qua" is not on a different code path that could
  /// behave differently.
  OnboardingConversation next() =>
      copyWith(stepIndex: (stepIndex + 1).clamp(0, kOnboardingSteps.length));

  OnboardingConversation back() =>
      copyWith(stepIndex: (stepIndex - 1).clamp(0, kOnboardingSteps.length));

  OnboardingConversation copyWith({int? stepIndex, BusinessProfile? profile}) =>
      OnboardingConversation(
        stepIndex: stepIndex ?? this.stepIndex,
        profile: profile ?? this.profile,
      );

  BusinessProfile _withTrade(BusinessTrade? trade) => BusinessProfile(
    trade: trade,
    size: profile.size,
    channels: profile.channels,
    seasonality: profile.seasonality,
  );

  BusinessProfile _withSize(BusinessSize? size) => BusinessProfile(
    trade: profile.trade,
    size: size,
    channels: profile.channels,
    seasonality: profile.seasonality,
  );

  BusinessProfile _withSeasonality(BusinessSeasonality? seasonality) =>
      BusinessProfile(
        trade: profile.trade,
        size: profile.size,
        channels: profile.channels,
        seasonality: seasonality,
      );

  BusinessProfile _withChannelToggled(String code, {required bool on}) {
    final channel = SalesChannel.fromCode(code);
    if (channel == null) return profile;
    final channels = [
      for (final c in SalesChannel.values)
        if (c == channel ? on : profile.channels.contains(c)) c,
    ];
    return BusinessProfile(
      trade: profile.trade,
      size: profile.size,
      channels: channels,
      seasonality: profile.seasonality,
    );
  }
}
