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
/// The [BusinessProfile] questions, in the order that reads like a
/// conversation rather than a form. Nothing else: the profile's privacy
/// boundary (WTM-177) is the boundary here too, which is why every step offers
/// **choices**, never a text box.
///
/// ## WTM-351 — câu thứ năm: loại hình kinh doanh
///
/// [BusinessType] (ADR-TON-023) đã là một trường của [BusinessProfile] từ lâu
/// nhưng **chưa bao giờ được onboarding hỏi**, nên nó luôn `null` với mọi
/// người bán chưa vào màn hồ sơ. Câu này lấp chỗ đó.
///
/// **Vì sao KHÔNG hỏi "online hay cửa hàng"** như concept vẽ: đó là câu hỏi về
/// *kênh bán*, và bước `channels` đã hỏi rồi. Hỏi lại là đúng cái bẫy "một
/// khái niệm, hai chủ" (P-27/P-28) đã cắn bốn lần. Câu này hỏi thứ `channels`
/// không biết: **bán vật, bán thứ sao chép được, hay bán thời gian**.
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

/// Mã đáp án của bước `business_type` → [BusinessType] của ADR-TON-023.
///
/// Bảng này là **hợp đồng** giữa câu hỏi và miền, nên nó nằm ở đây chứ không
/// rải trong `switch` của màn hình. Hai mã cố ý ánh xạ về `null`:
///
/// * `preparing` — *đang chuẩn bị kinh doanh*: chưa bán gì thì chưa có loại
///   hình. Đoán hộ một loại hình cho họ là bịa dữ liệu miền.
/// * `other` — người bán tự nói mình không thuộc nhóm nào; ghi `hybrid` cho
///   họ là ghi một câu trả lời họ không đưa.
///
/// `null` ở đây nghĩa **chưa khai**, đúng như [BusinessType.fromCode] đã định
/// nghĩa — không phải một giá trị mặc định.
const Map<String, BusinessType?> kBusinessTypeByAnswer = {
  'goods': BusinessType.physical,
  'digital': BusinessType.digital,
  'service': BusinessType.service,
  'mixed': BusinessType.hybrid,
  'preparing': null,
  'other': null,
};

/// Mã đáp án nghĩa là *"tôi chưa bắt đầu kinh doanh"*.
///
/// Không lưu xuống DB (chưa có cột nào cho nó), nhưng luồng đọc nó để gợi ý
/// cửa *"chưa có dữ liệu"* ở bước sau.
const String kBusinessTypePreparing = 'preparing';

/// The script. Order matters: business type first because it is the question a
/// seller can answer without thinking at all; trade next; and each answer makes
/// every later question feel relevant.
/// WTM-232: không còn `const` vì bước "kênh bán" suy thẳng từ `SalesChannel`
/// thay vì chép tay — danh sách chép tay vừa để sót ba kênh số mới, và người
/// bán sản phẩm số sẽ đi qua onboarding mà không có ô nào đúng để chọn.
final List<OnboardingStep> kOnboardingSteps = [
  OnboardingStep(
    id: 'business_type',
    optionCodes: kBusinessTypeByAnswer.keys.toList(growable: false),
  ),
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
    this.businessTypeCode,
  });

  final int stepIndex;
  final BusinessProfile profile;

  /// Mã đáp án **thô** của bước `business_type` — WTM-351.
  ///
  /// Giữ riêng khỏi `profile.type` vì đáp án mang nhiều thông tin hơn giá trị
  /// đã ánh xạ: `preparing` và `other` **cùng** cho `type == null`, nhưng chỉ
  /// một trong hai nghĩa là *"tôi chưa bắt đầu bán"*. Gộp chúng lại là mất đúng
  /// tín hiệu mà đường B cần.
  final String? businessTypeCode;

  /// Người bán tự khai đang chuẩn bị kinh doanh.
  bool get isPreparing => businessTypeCode == kBusinessTypePreparing;

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
      'business_type' => {?businessTypeCode},
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
    if (step.id == 'business_type') {
      // Mã lạ bị bỏ qua chứ không lưu — cùng luật với các bước khác, nơi
      // `fromCode` trả `null`. Ở đây phải viết tay vì mã thô được giữ lại.
      if (!kBusinessTypeByAnswer.containsKey(code)) return this;
      // Không đi qua `copyWith`: bỏ chọn phải xoá được về `null`, mà `copyWith`
      // với tham số nullable không phân biệt được "không truyền" với "truyền
      // null".
      return OnboardingConversation(
        stepIndex: stepIndex,
        profile: _withType(selected ? null : kBusinessTypeByAnswer[code]),
        businessTypeCode: selected ? null : code,
      );
    }
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
        businessTypeCode: businessTypeCode,
      );

  // ⚠️ Mỗi hàm dưới đây dựng lại **cả** `BusinessProfile` để một trường có thể
  // bị xoá về `null` — nghĩa là hàm nào quên chép một trường thì trường đó bị
  // xoá lặng lẽ khi người bán trả lời câu khác. `type` là trường mới nhất
  // (WTM-351) và đúng là trường dễ rơi nhất, nên có test khoá riêng cho nó.

  BusinessProfile _withType(BusinessType? type) => BusinessProfile(
    type: type,
    trade: profile.trade,
    size: profile.size,
    channels: profile.channels,
    seasonality: profile.seasonality,
  );

  BusinessProfile _withTrade(BusinessTrade? trade) => BusinessProfile(
    type: profile.type,
    trade: trade,
    size: profile.size,
    channels: profile.channels,
    seasonality: profile.seasonality,
  );

  BusinessProfile _withSize(BusinessSize? size) => BusinessProfile(
    type: profile.type,
    trade: profile.trade,
    size: size,
    channels: profile.channels,
    seasonality: profile.seasonality,
  );

  BusinessProfile _withSeasonality(BusinessSeasonality? seasonality) =>
      BusinessProfile(
        type: profile.type,
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
      type: profile.type,
      trade: profile.trade,
      size: profile.size,
      channels: channels,
      seasonality: profile.seasonality,
    );
  }
}
