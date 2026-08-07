import 'package:flutter/foundation.dart';

/// Mức tin cậy của một liên kết danh tính — **tập thứ tự**, không phải số thực
/// (ADR-TON-024).
///
/// Một số thực (0.87) nghe khoa học và **không quyết định được gì**: không ai
/// biết ngưỡng nào là đủ, và mỗi chỗ đọc sẽ tự chọn một ngưỡng khác.
enum IdentityConfidence {
  /// Nền tảng bảo đảm khoá **duy nhất** cho một người — Shopee `buyer_id`
  /// trong cùng một shop, Messenger PSID.
  exact('exact', 3),

  /// Trùng khớp **chính xác** một định danh mạnh — số điện thoại, email.
  strong('strong', 2),

  /// Giống nhau, không bằng chứng — tên gần giống, địa chỉ gần giống.
  weak('weak', 1),

  /// Không có cơ sở.
  none('none', 0);

  const IdentityConfidence(this.code, this.rank);

  final String code;

  /// Thứ hạng để so sánh. Có thứ tự nên `>=` mới có nghĩa; một `Map` mã→số
  /// rời rạc sẽ để mỗi chỗ tự chế ngưỡng riêng.
  final int rank;

  /// Mã lạ ⇒ `null`, **không** rơi về mức nào.
  static IdentityConfidence? fromCode(String? code) {
    for (final c in IdentityConfidence.values) {
      if (c.code == code) return c;
    }
    return null;
  }

  /// Đủ để **tự động liên kết** hay chưa.
  ///
  /// Chỉ `exact`. `strong` **không** đủ, và đó là quyết định có chủ ý: hai
  /// người thật **có thể** dùng chung một số điện thoại — vợ chồng, mẹ con,
  /// số cửa hàng. Ở Việt Nam đó là chuyện phổ biến, không phải trường hợp
  /// biên. Gộp nhầm hai khách tệ hơn không gộp.
  bool get canAutoLink => this == IdentityConfidence.exact;

  /// Đủ để **đề xuất** cho người bán bấm xác nhận.
  bool get canSuggest => rank >= IdentityConfidence.strong.rank;
}

/// Ai đã quyết định liên kết này.
enum IdentityLinkKind {
  /// Người bán tự gắn. **Thắng mọi luật tự động.**
  manual('manual'),

  /// Luật khớp gắn tự động (chỉ xảy ra với `exact`).
  automatic('automatic'),

  /// Nền tảng xác nhận đây là cùng một người.
  verified('verified');

  const IdentityLinkKind(this.code);

  final String code;

  static IdentityLinkKind? fromCode(String? code) {
    for (final k in IdentityLinkKind.values) {
      if (k.code == code) return k;
    }
    return null;
  }
}

/// Một danh tính trên nền tảng ngoài, trỏ về một `Customer` của người bán.
///
/// Shopee Buyer · TikTok Buyer · Messenger PSID · Telegram Chat · Email ·
/// Shopify Customer — tất cả có thể trỏ về **cùng một người mua**.
@immutable
class ExternalIdentity {
  const ExternalIdentity({
    required this.id,
    required this.platform,
    required this.externalId,
    required this.connectionId,
    required this.customerId,
    required this.confidence,
    required this.linkKind,
    required this.linkedAt,
    this.displayName,
    this.verifiedAt,
  });

  final String id;

  /// Mã canonical của nền tảng — `shopee` · `tiktok` · `messenger` · …
  final String platform;

  /// Mã do **nền tảng** cấp. Không bao giờ là nhãn hiển thị (ADR-TON-018).
  final String externalId;

  /// Kết nối nào mang danh tính này về (WTM-283).
  ///
  /// **Bắt buộc.** Cùng một `externalId` ở hai tài khoản Shopee khác nhau là
  /// **hai người khác nhau** — bỏ trường này là mở đường cho một loại nhầm
  /// không sửa được.
  final String connectionId;

  /// Khách hàng của người bán mà danh tính này trỏ về.
  final String customerId;

  final IdentityConfidence confidence;
  final IdentityLinkKind linkKind;
  final DateTime linkedAt;

  /// Tên hiển thị lúc thấy — **chỉ để người bán nhận ra mặt**.
  ///
  /// KHÔNG dùng để khớp: khớp theo tên là nguồn của `weak`, và `weak` không
  /// tự động hoá gì cả.
  final String? displayName;

  /// Khi nào nền tảng xác nhận. `null` = **chưa xác nhận**, không phải "xác
  /// nhận lúc 0".
  final DateTime? verifiedAt;

  /// Lựa chọn thủ công của người bán **thắng** mọi luật tự động.
  ///
  /// Cùng kỷ luật đã áp ở FK 787 (dữ liệu người dùng thắng dữ liệu mẫu) và ở
  /// Rule Twin (người quyết định, AI chỉ giải thích).
  bool get outranksAutomation => linkKind == IdentityLinkKind.manual;

  ExternalIdentity copyWith({
    String? customerId,
    IdentityConfidence? confidence,
    IdentityLinkKind? linkKind,
    DateTime? verifiedAt,
  }) => ExternalIdentity(
    id: id,
    platform: platform,
    externalId: externalId,
    connectionId: connectionId,
    customerId: customerId ?? this.customerId,
    confidence: confidence ?? this.confidence,
    linkKind: linkKind ?? this.linkKind,
    linkedAt: linkedAt,
    displayName: displayName,
    verifiedAt: verifiedAt ?? this.verifiedAt,
  );

  @override
  bool operator ==(Object other) => other is ExternalIdentity && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ExternalIdentity($platform:$externalId → $customerId)';
}

/// Việc đã xảy ra với một liên kết danh tính.
enum IdentityLinkAction {
  linked('linked'),
  unlinked('unlinked'),
  moved('moved');

  const IdentityLinkAction(this.code);

  final String code;

  static IdentityLinkAction? fromCode(String? code) {
    for (final a in IdentityLinkAction.values) {
      if (a.code == code) return a;
    }
    return null;
  }
}

/// Một dòng lịch sử — **không bao giờ xoá**.
///
/// ## Vì sao lịch sử là điều kiện để tự động hoá được phép tồn tại
///
/// Không có nó thì không trả lời được *"vì sao khách này có đơn từ TikTok?"*,
/// và cũng không **hoàn tác an toàn** được. Tự động hoá chỉ được phép khi hoàn
/// tác rẻ; lịch sử là thứ làm cho hoàn tác rẻ.
///
/// [actor] phân biệt `seller` với `rule:<tên luật>` — để khi một luật khớp hoá
/// ra sai, tìm được **tất cả** thứ nó đã gắn và gỡ hàng loạt.
@immutable
class IdentityLinkEvent {
  const IdentityLinkEvent({
    required this.id,
    required this.identityId,
    required this.action,
    required this.at,
    required this.actor,
    this.fromCustomerId,
    this.toCustomerId,
    this.confidence,
  });

  /// Người bán tự làm.
  static const String actorSeller = 'seller';

  /// Một luật khớp làm. Dùng `rule:<tên>` để gỡ hàng loạt được về sau.
  static String actorRule(String ruleName) => 'rule:$ruleName';

  final String id;
  final String identityId;
  final IdentityLinkAction action;
  final DateTime at;
  final String actor;
  final String? fromCustomerId;
  final String? toCustomerId;
  final IdentityConfidence? confidence;

  @override
  String toString() =>
      'IdentityLinkEvent(${action.code} $identityId by $actor)';
}
