import 'package:flutter/foundation.dart';

import '../core/tongtai_enums.dart';

/// The seller's reaction to a surfaced opportunity (WTM-91 AC4/AC5).
enum OpportunityReaction {
  none,
  saved, // bookmarked for later review
  interested, // swiped right — actively pursuing
  dismissed; // swiped left — hidden from the feed

  String get labelEn => switch (this) {
    OpportunityReaction.none => 'New',
    OpportunityReaction.saved => 'Saved',
    OpportunityReaction.interested => 'Interested',
    OpportunityReaction.dismissed => 'Dismissed',
  };

  String get labelVi => switch (this) {
    OpportunityReaction.none => 'Mới',
    OpportunityReaction.saved => 'Đã lưu',
    OpportunityReaction.interested => 'Quan tâm',
    OpportunityReaction.dismissed => 'Đã bỏ qua',
  };

  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// A surfaced business opportunity (WTM-91) — pure domain model mirroring the
/// Drift `OpportunitiesTable` shape (type, title, ROI/investment, scores,
/// discoveredAt), so a Drift-backed source can replace the in-memory feed
/// without touching callers. Reuses the WTM-60 [OpportunityType] enum.
@immutable
class Opportunity {
  const Opportunity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.expectedImpact,
    required this.estimatedRoi,
    required this.aiScore,
    required this.discoveredAt,
    this.reaction = OpportunityReaction.none,
  });

  /// Stable identifier.
  final String id;

  /// Opportunity archetype (AC2 filter facet).
  final OpportunityType type;

  /// Headline, e.g. "Quạt tích điện sắp vào mùa nóng" (AC1).
  final String title;

  /// What the opportunity is and why it exists (AC1).
  final String description;

  /// Expected impact in đồng of additional revenue (AC1).
  final double expectedImpact;

  /// Estimated ROI multiple, e.g. 2.4 = 240% return (AC3 sort key).
  final double estimatedRoi;

  /// Relevance score 0–100 (AC3 sort key). Deterministic/seeded today; the
  /// AI scorer arrives with WTM-93.
  final double aiScore;

  /// When the opportunity was surfaced (AC3 recency sort key).
  final DateTime discoveredAt;

  /// The seller's reaction (AC4/AC5).
  final OpportunityReaction reaction;

  bool get isDismissed => reaction == OpportunityReaction.dismissed;
  bool get isSaved => reaction == OpportunityReaction.saved;

  Opportunity copyWith({OpportunityReaction? reaction}) => Opportunity(
    id: id,
    type: type,
    title: title,
    description: description,
    expectedImpact: expectedImpact,
    estimatedRoi: estimatedRoi,
    aiScore: aiScore,
    discoveredAt: discoveredAt,
    reaction: reaction ?? this.reaction,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Opportunity && other.id == id && other.reaction == reaction);

  @override
  int get hashCode => Object.hash(id, reaction);

  @override
  String toString() => 'Opportunity($id, ${type.name}, ${reaction.name})';
}

/// Deterministic sample opportunities so the feed has real data to exercise
/// until WTM-93's AI scorer lands — same convention as `kSampleCustomers`.
final List<Opportunity> kSampleOpportunities = [
  Opportunity(
    id: 'o01',
    type: OpportunityType.seasonal,
    title: 'Quạt tích điện sắp vào mùa nóng',
    description:
        'Tìm kiếm "quạt tích điện" tăng mạnh trước hè; tồn kho của bạn còn '
        'thấp so với nhịp bán tháng trước.',
    expectedImpact: 45000000,
    estimatedRoi: 2.4,
    aiScore: 92,
    discoveredAt: DateTime(2026, 7, 21),
  ),
  Opportunity(
    id: 'o02',
    type: OpportunityType.arbitrage,
    title: 'Chênh lệch giá bình giữ nhiệt giữa 2 nguồn',
    description:
        'Nguồn Quảng Châu đang rẻ hơn nguồn hiện tại ~18% cho cùng phân khúc '
        '500ml.',
    expectedImpact: 12000000,
    estimatedRoi: 1.8,
    aiScore: 74,
    discoveredAt: DateTime(2026, 7, 20),
  ),
  Opportunity(
    id: 'o03',
    type: OpportunityType.trend,
    title: 'Đồ gia dụng mini cho căn hộ studio',
    description:
        'Xu hướng nội dung "căn hộ nhỏ" kéo nhu cầu đồ gia dụng cỡ nhỏ; phù '
        'hợp danh mục Home hiện có.',
    expectedImpact: 28000000,
    estimatedRoi: 2.1,
    aiScore: 81,
    discoveredAt: DateTime(2026, 7, 22),
  ),
  Opportunity(
    id: 'o04',
    type: OpportunityType.crossBorder,
    title: 'Khăn lụa thủ công có cầu từ Singapore',
    description:
        'Nhóm khách SG hỏi mua khăn lụa qua kênh chat; chưa có kênh giao '
        'xuyên biên giới.',
    expectedImpact: 15000000,
    estimatedRoi: 1.5,
    aiScore: 58,
    discoveredAt: DateTime(2026, 7, 18),
  ),
  Opportunity(
    id: 'o05',
    type: OpportunityType.seasonal,
    title: 'Set quà Trung thu cho khách sỉ',
    description:
        'Khách sỉ bắt đầu gom đơn quà Trung thu sớm; biên tốt khi chốt trước '
        'tháng 8.',
    expectedImpact: 60000000,
    estimatedRoi: 2.9,
    aiScore: 88,
    discoveredAt: DateTime(2026, 7, 19),
  ),
];
