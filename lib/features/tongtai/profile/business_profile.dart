/// AI Business Profile — the domain model (WTM-177).
///
/// Answers four questions about *what kind of business this is*, so AI advice
/// stops being generic. Every field is optional: the profile is skippable, and
/// a half-answered profile is more useful than none.
///
/// ## Codes, never labels
/// Every value is a **canonical code** (`fashion`, `solo`, `tet`), never a
/// display string. Same rule as `.ttbk` v2 (ADR-TON-018): a label is localized,
/// so storing one means the record changes meaning when the seller switches
/// language — and it means an English build cannot read a Vietnamese file.
///
/// ## The privacy boundary
/// This object is injected into **every AI prompt**, so in BYOK mode it leaves
/// the device on every question. It therefore carries **only categorical facts
/// about the trade** — and deliberately has **no free-text field**, because a
/// free-text field is where a seller writes a customer's name and phone number.
///
/// `tongtai_business_profile_privacy_test.dart` fails if that ever changes.
library;

/// What the business sells.
enum BusinessTrade {
  fashion('fashion'),
  food('food'),
  cosmetics('cosmetics'),
  electronics('electronics'),
  homeGoods('home_goods'),
  services('services'),
  other('other');

  const BusinessTrade(this.code);

  /// Canonical, stable, never localized. Persisted and sent to AI.
  final String code;

  /// Unknown codes read as `null`, not as a default. A code this build does
  /// not recognise is missing information, not `other` — the same rule
  /// ADR-TON-018 sets for restoring an unknown enum.
  static BusinessTrade? fromCode(String? code) {
    if (code == null) return null;
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// Roughly how big the operation is.
enum BusinessSize {
  solo('solo'),
  small('small'),
  growing('growing'),
  established('established');

  const BusinessSize(this.code);

  final String code;

  static BusinessSize? fromCode(String? code) {
    if (code == null) return null;
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// Where the business sells. A seller usually picks several.
enum SalesChannel {
  shop('shop'),
  market('market'),
  shopee('shopee'),
  tiktok('tiktok'),
  facebook('facebook'),
  zalo('zalo'),
  wholesale('wholesale');

  const SalesChannel(this.code);

  final String code;

  static SalesChannel? fromCode(String? code) {
    if (code == null) return null;
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// Whether the trade has a predictable peak.
enum BusinessSeasonality {
  none('none'),
  tet('tet'),
  schoolYear('school_year'),
  summer('summer'),
  yearEnd('year_end');

  const BusinessSeasonality(this.code);

  final String code;

  static BusinessSeasonality? fromCode(String? code) {
    if (code == null) return null;
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// The profile itself. Immutable; edits produce a new instance.
class BusinessProfile {
  const BusinessProfile({
    this.trade,
    this.size,
    this.channels = const [],
    this.seasonality,
    this.updatedAt,
  });

  /// The state a device starts in and returns to: nothing answered.
  static const BusinessProfile empty = BusinessProfile();

  final BusinessTrade? trade;
  final BusinessSize? size;
  final List<SalesChannel> channels;
  final BusinessSeasonality? seasonality;

  /// When the seller last edited it. `null` while nothing has been answered.
  final DateTime? updatedAt;

  /// True when the seller has told us nothing at all. Callers use this to skip
  /// the prompt block entirely rather than send an empty section.
  bool get isEmpty =>
      trade == null && size == null && channels.isEmpty && seasonality == null;

  bool get isNotEmpty => !isEmpty;

  /// Channel codes joined for storage. Sorted so the stored value is stable
  /// regardless of the order the seller tapped them — otherwise two identical
  /// profiles would compare unequal and look like an edit.
  String? get channelCodes {
    if (channels.isEmpty) return null;
    final codes = channels.map((c) => c.code).toList()..sort();
    return codes.join(',');
  }

  static List<SalesChannel> channelsFromCodes(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    return raw
        .split(',')
        .map(SalesChannel.fromCode)
        .whereType<SalesChannel>()
        .toList();
  }

  BusinessProfile copyWith({
    BusinessTrade? trade,
    BusinessSize? size,
    List<SalesChannel>? channels,
    BusinessSeasonality? seasonality,
    DateTime? updatedAt,
  }) => BusinessProfile(
    trade: trade ?? this.trade,
    size: size ?? this.size,
    channels: channels ?? this.channels,
    seasonality: seasonality ?? this.seasonality,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Serialised for `.ttbk` — codes only, matching ADR-TON-018.
  Map<String, dynamic> toJson() => {
    'trade': trade?.code,
    'size': size?.code,
    'channels': channels.map((c) => c.code).toList(),
    'seasonality': seasonality?.code,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static BusinessProfile fromJson(Map<String, dynamic> json) => BusinessProfile(
    trade: BusinessTrade.fromCode(json['trade'] as String?),
    size: BusinessSize.fromCode(json['size'] as String?),
    channels:
        (json['channels'] as List?)
            ?.map((c) => SalesChannel.fromCode(c as String?))
            .whereType<SalesChannel>()
            .toList() ??
        const [],
    seasonality: BusinessSeasonality.fromCode(json['seasonality'] as String?),
    updatedAt: json['updatedAt'] is String
        ? DateTime.tryParse(json['updatedAt'] as String)
        : null,
  );
}
