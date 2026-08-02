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
///
/// Dùng chung giữa [BusinessProfile.channels] và `CustomerOrder.channel`
/// (WTM-209) — thêm một kênh ở đây là đủ cho cả hai, và đó chính là lý do nó
/// phải là **một** enum chứ không phải hai.
///
/// **Mã cũ không bao giờ đổi** (ADR-TON-018): đổi một mã sẽ làm mọi đơn đã ghi
/// mất kênh khi khôi phục.
enum SalesChannel {
  shop('shop'),
  market('market'),
  shopee('shopee'),
  tiktok('tiktok'),
  facebook('facebook'),
  zalo('zalo'),
  wholesale('wholesale'),

  // ── Kênh cho doanh nghiệp số / dịch vụ (WTM-232, ADR-TON-023) ──────────
  // Trước đây bảy kênh trên đều là bán lẻ vật lý, nên một doanh nghiệp số
  // KHÔNG CÓ Ô NÀO ĐÚNG để chọn: mọi đơn thành "chưa ghi" và mục "Doanh thu
  // theo kênh" trống vĩnh viễn — không phải vì người bán lười ghi.
  /// Bán trên trang của chính mình.
  website('website'),

  /// Chợ ứng dụng (App Store, Google Play…).
  appStore('app_store'),

  /// Bán trực tiếp / theo hợp đồng — dịch vụ, B2B.
  direct('direct');

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
/// Loại hình kinh doanh (ADR-TON-023, ưu tiên #2 của Founder).
///
/// **Khác với [BusinessTrade].** Trade là *ngành hàng* (thời trang, thực
/// phẩm…); type là *cách doanh nghiệp vận hành*. Một xưởng may và một studio
/// phần mềm đều có thể chọn ngành "khác", trong khi mô hình vận hành của họ
/// không có điểm chung nào. Gộp hai chiều này lại là mất thông tin, nên đây là
/// một trường riêng chứ không phải giá trị mới của trade.
enum BusinessType {
  /// Bán vật: có nhập, có tồn, có giao.
  physical('physical'),

  /// Bán thứ sao chép được: phần mềm, khoá học, tệp.
  digital('digital'),

  /// Bán thời gian và năng lực.
  service('service'),

  /// Vừa vật vừa số/dịch vụ — phổ biến hơn người ta tưởng.
  hybrid('hybrid');

  const BusinessType(this.code);

  /// Mã lưu xuống DB và `.ttbk`. **Không bao giờ là nhãn hiển thị.**
  final String code;

  /// Mã lạ hoặc vắng mặt ⇒ `null` = **chưa khai**.
  ///
  /// Cố ý KHÔNG mặc định `physical`: người bán có sẵn chưa từng được hỏi câu
  /// này, và trả lời hộ họ là bịa dữ liệu — khác hẳn `ProductKind`, nơi mọi
  /// dòng cũ *thật sự* là hàng vật lý vì mô hình trước đó chỉ có một loại.
  static BusinessType? fromCode(String? code) {
    for (final t in BusinessType.values) {
      if (t.code == code) return t;
    }
    return null;
  }
}

class BusinessProfile {
  const BusinessProfile({
    this.type,
    this.trade,
    this.size,
    this.channels = const [],
    this.seasonality,
    this.updatedAt,
  });

  /// The state a device starts in and returns to: nothing answered.
  static const BusinessProfile empty = BusinessProfile();

  /// Loại hình vận hành — `null` khi người bán chưa được hỏi (ADR-TON-023).
  final BusinessType? type;

  final BusinessTrade? trade;
  final BusinessSize? size;
  final List<SalesChannel> channels;
  final BusinessSeasonality? seasonality;

  /// When the seller last edited it. `null` while nothing has been answered.
  final DateTime? updatedAt;

  /// True when the seller has told us nothing at all. Callers use this to skip
  /// the prompt block entirely rather than send an empty section.
  bool get isEmpty =>
      type == null &&
      trade == null &&
      size == null &&
      channels.isEmpty &&
      seasonality == null;

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
    BusinessType? type,
    BusinessTrade? trade,
    BusinessSize? size,
    List<SalesChannel>? channels,
    BusinessSeasonality? seasonality,
    DateTime? updatedAt,
  }) => BusinessProfile(
    type: type ?? this.type,
    trade: trade ?? this.trade,
    size: size ?? this.size,
    channels: channels ?? this.channels,
    seasonality: seasonality ?? this.seasonality,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Serialised for `.ttbk` — codes only, matching ADR-TON-018.
  Map<String, dynamic> toJson() => {
    'type': type?.code,
    'trade': trade?.code,
    'size': size?.code,
    'channels': channels.map((c) => c.code).toList(),
    'seasonality': seasonality?.code,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static BusinessProfile fromJson(Map<String, dynamic> json) => BusinessProfile(
    // Vắng mặt ở mọi file `.ttbk` viết trước ADR-TON-023 ⇒ `null` = chưa khai,
    // đúng sự thật: người bán chưa từng được hỏi câu này.
    type: BusinessType.fromCode(json['type'] as String?),
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
