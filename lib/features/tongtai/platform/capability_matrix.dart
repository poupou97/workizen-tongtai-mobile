import 'package:flutter/foundation.dart';

import 'vendor_catalog.dart';

/// Một ô của ma trận — **ba sự thật khác nhau**, không phải một dấu ✅
/// (WTM-293 · N2 · ADR-TON-024 luật 3).
///
/// | Cột | Câu hỏi nó trả lời | Ai đổi được |
/// |---|---|---|
/// | [platformSupports] | Nền tảng **có API** cho việc này không? | nghiên cứu vendor |
/// | [connectorCovers] | **Connector của mình** đã làm chưa? | người viết connector |
/// | [verifiedOnDogfood] | Đã chạy thật trên dữ liệu Workizen chưa? | bằng chứng |
///
/// Ba cột chênh nhau là **bình thường** và phải nhìn thấy được. Nếu AI đọc
/// nhầm cột đầu thành cột ba, nó sẽ nói với người bán *"đồng bộ tồn kho Shopee
/// được"* trong khi **chưa ai viết dòng code nào** — đó không phải lỗi hiển
/// thị, đó là AI nói dối một cách tự tin, đúng thứ ADR-TON-016 sinh ra để chặn.
@immutable
class CapabilityCell {
  const CapabilityCell({
    required this.platform,
    required this.capability,
    this.platformSupports = false,
    this.connectorCovers = false,
    this.verifiedOnDogfood = false,
    this.evidence,
  }) : assert(
         !connectorCovers || platformSupports,
         'C không được vượt P — connector không phủ được thứ nền tảng không có; '
         'thấy vậy nghĩa là một trong hai ô sai',
       ),
       assert(
         !verifiedOnDogfood || connectorCovers,
         'D không được vượt C — chưa viết thì chạy thật bằng gì',
       ),
       assert(
         !verifiedOnDogfood || evidence != null,
         'D chỉ được bật KÈM BẰNG CHỨNG: số đo thật, ngày, story',
       );

  /// Mã nhà cung cấp, khớp `Vendor.id`.
  final String platform;

  final PlatformCapability capability;

  /// **P** — nền tảng có API cho việc này.
  final bool platformSupports;

  /// **C** — connector của mình đã làm.
  final bool connectorCovers;

  /// **D** — đã chạy thật trên dữ liệu Workizen.
  final bool verifiedOnDogfood;

  /// Bằng chứng cho [verifiedOnDogfood]: số đo thật, ngày, story.
  ///
  /// Bắt buộc khi cột D bật. Không có bằng chứng thì không phải D — đó là ý
  /// định, và ý định không nói được với người bán.
  final String? evidence;

  /// Chuyển thành lời **hứa được với người bán** — hoặc `null`.
  ///
  /// Đây là **cổng duy nhất** ra khỏi ma trận về phía AI. Xem [CapabilityClaim].
  CapabilityClaim? toClaim() => verifiedOnDogfood
      ? CapabilityClaim._(
          platform: platform,
          capability: capability,
          evidence: evidence!,
        )
      : null;

  @override
  String toString() =>
      'CapabilityCell($platform/${capability.code} '
      'P=$platformSupports C=$connectorCovers D=$verifiedOnDogfood)';
}

/// Một điều **đã chạy thật** và do đó nói được với người bán.
///
/// ## ⭐ Vì sao kiểu này tồn tại thay vì đọc thẳng ô ma trận
///
/// ADR-TON-024 luật 3: *"AI chỉ được hứa ở mức `verifiedOnDogfood`"*. Một nội
/// quy như vậy sẽ bị vi phạm ngày đầu tiên có người viết
/// `if (cell.platformSupports) return 'làm được'`.
///
/// Nên luật được cài bằng **kiểu dữ liệu**: lớp này **không có** trường
/// `platformSupports` hay `connectorCovers`, và constructor của nó là
/// **private** — cách duy nhất tạo ra một [CapabilityClaim] là qua
/// [CapabilityCell.toClaim], và cổng đó chỉ mở khi cột D bật.
///
/// Tầng AI nhận `List<CapabilityClaim>`, nên nó **không cầm** hai cột kia.
/// Không cầm thì không đọc nhầm được.
@immutable
class CapabilityClaim {
  const CapabilityClaim._({
    required this.platform,
    required this.capability,
    required this.evidence,
  });

  final String platform;
  final PlatformCapability capability;

  /// Luôn có — một lời hứa không kèm bằng chứng thì không phải lời hứa này.
  final String evidence;

  @override
  String toString() => 'CapabilityClaim($platform/${capability.code})';
}

/// Ma trận năng lực — **dữ liệu**, không phải bảng trong tài liệu.
///
/// Tĩnh trong code cùng lý do với [VendorCatalog]: đây là kiến thức của app,
/// không phải dữ liệu người bán.
///
/// **Không ô nào ngoài GitHub có C hay D.** Đó là sự thật hôm nay, và ma trận
/// tồn tại để nó không bị đọc nhầm thành khả năng.
abstract final class CapabilityMatrix {
  static const List<CapabilityCell> all = [
    // GitHub — connector duy nhất đã chạy thật (WTM-268/274).
    CapabilityCell(
      platform: 'github',
      capability: PlatformCapability.delivery,
      platformSupports: true,
      connectorCovers: true,
      verifiedOnDogfood: true,
      evidence:
          'WTM-268/274 · 2026-08-06 · commits 211 · pulls 155 · '
          'releases 0 · 360 event_id ổn định qua hai lần gọi',
    ),

    // Sàn thương mại điện tử — nền tảng có API, connector CHƯA có.
    CapabilityCell(
      platform: 'shopee',
      capability: PlatformCapability.orders,
      platformSupports: true,
    ),
    CapabilityCell(
      platform: 'shopee',
      capability: PlatformCapability.products,
      platformSupports: true,
    ),
    CapabilityCell(
      platform: 'shopee',
      capability: PlatformCapability.inventory,
      platformSupports: true,
    ),
    CapabilityCell(
      platform: 'shopee',
      capability: PlatformCapability.customers,
      platformSupports: true,
    ),
    CapabilityCell(
      platform: 'shopee',
      capability: PlatformCapability.settlement,
      platformSupports: true,
    ),
    CapabilityCell(
      platform: 'tiktok_shop',
      capability: PlatformCapability.orders,
      platformSupports: true,
    ),
    CapabilityCell(
      platform: 'tiktok_shop',
      capability: PlatformCapability.products,
      platformSupports: true,
    ),
    CapabilityCell(
      platform: 'tiktok_shop',
      capability: PlatformCapability.inventory,
      platformSupports: true,
    ),
    CapabilityCell(
      platform: 'tiktok_shop',
      capability: PlatformCapability.customers,
      platformSupports: true,
    ),
    CapabilityCell(
      platform: 'tiktok_shop',
      capability: PlatformCapability.settlement,
      platformSupports: true,
    ),
    CapabilityCell(
      platform: 'shopify',
      capability: PlatformCapability.orders,
      platformSupports: true,
    ),
    CapabilityCell(
      platform: 'shopify',
      capability: PlatformCapability.products,
      platformSupports: true,
    ),
    CapabilityCell(
      platform: 'shopify',
      capability: PlatformCapability.settlement,
      platformSupports: true,
    ),

    // Nhắn tin.
    CapabilityCell(
      platform: 'telegram',
      capability: PlatformCapability.chat,
      platformSupports: true,
    ),
    CapabilityCell(
      platform: 'telegram',
      capability: PlatformCapability.customers,
      platformSupports: true,
    ),
    CapabilityCell(
      platform: 'facebook',
      capability: PlatformCapability.chat,
      platformSupports: true,
    ),
    CapabilityCell(
      platform: 'facebook',
      capability: PlatformCapability.customers,
      platformSupports: true,
    ),
    CapabilityCell(
      platform: 'facebook',
      capability: PlatformCapability.ads,
      platformSupports: true,
    ),
    CapabilityCell(
      platform: 'gmail',
      capability: PlatformCapability.chat,
      platformSupports: true,
    ),

    // Thanh toán.
    CapabilityCell(
      platform: 'stripe',
      capability: PlatformCapability.payments,
      platformSupports: true,
    ),
    CapabilityCell(
      platform: 'stripe',
      capability: PlatformCapability.settlement,
      platformSupports: true,
    ),
    CapabilityCell(
      platform: 'revenuecat',
      capability: PlatformCapability.payments,
      platformSupports: true,
    ),
    CapabilityCell(
      platform: 'revenuecat',
      capability: PlatformCapability.settlement,
      platformSupports: true,
    ),

    // Phân tích.
    CapabilityCell(
      platform: 'ga4',
      capability: PlatformCapability.analytics,
      platformSupports: true,
    ),
  ];

  static CapabilityCell? cell(String platform, PlatformCapability capability) {
    for (final c in all) {
      if (c.platform == platform && c.capability == capability) return c;
    }
    return null;
  }

  /// Mọi điều **đã chạy thật** — đầu vào duy nhất của tầng AI.
  static List<CapabilityClaim> get claims =>
      all.map((c) => c.toClaim()).nonNulls.toList();

  static List<CapabilityClaim> claimsFor(String platform) =>
      claims.where((c) => c.platform == platform).toList();
}
