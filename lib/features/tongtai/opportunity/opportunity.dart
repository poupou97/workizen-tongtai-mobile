import 'package:flutter/foundation.dart';

import '../core/tongtai_enums.dart';
import 'opportunity_score.dart';

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
/// **Derived data, deliberately not stored** (WTM-190): the rule engine
/// regenerates the whole feed from products, customers, orders and goals on
/// every read, so persisting it would create a parallel copy that One Data Path
/// (ADR-TON-015) forbids and that would drift. The empty `opportunities_table`
/// that shipped in v1 was dropped in schema v10 for exactly that reason.
///
/// What *is* stored is [reaction] — the seller's judgement is the one part of
/// this object the app cannot recompute. See `OpportunityReactionRepository`.
/// Reuses the WTM-60 [OpportunityType] enum.
@immutable
class Opportunity {
  const Opportunity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.expectedImpact,
    required this.score,
    this.roi,
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

  /// How this opportunity scored, and which factors had no data (WTM-193).
  ///
  /// Replaces the old `aiScore` + `estimatedRoi` pair, both of which were
  /// **constants per rule** — so "sort by relevance" and "sort by ROI" produced
  /// the same order, the order of the rules.
  ///
  /// ROI is gone rather than faked: computing it needs a **cost price**, and
  /// `Product` has only a selling price. Per the Founder's O-1 rule — *keep the
  /// domain, hide the capability that has no data* — the sort facet is hidden
  /// (`OpportunitySort.roi` stays in the enum), because a facet that sorts by a
  /// constant is a promise the product cannot keep.
  final OpportunityScore score;

  /// Convenience for widgets that just want a number, or `null` when nothing
  /// could be scored.
  double? get aiScore => score.value;

  /// Return multiple on the money at stake — profit over investment — or
  /// `null` when the cost side is unknown (WTM-207).
  ///
  /// ADR-TON-022 removed the old `estimatedRoi` because it was a constant per
  /// rule; the ROI facet and the High Risk badge went with it, with "needs a
  /// cost price" recorded as the condition for their return. WTM-204 supplied
  /// the field; this is the return. `null` keeps the ADR's rule: it means
  /// *nobody knows*, never *zero return* — a win-back or goal catch-up has no
  /// cost side to compute, and pretending otherwise is the defect coming back.
  final double? roi;

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
    score: score,
    roi: roi,
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

/// Deterministic sample opportunities so the feed has real data to exercise —
/// same convention as `kSampleCustomers`.
///
/// Their scores go through [scoreOpportunity], the **same** function the rule
/// engine uses, rather than being hand-written numbers. A sample that scored by
/// a different route would let the real path break without any sample noticing.
const double _sampleBaseline = 120000000;
final List<Opportunity> kSampleOpportunities = [
  Opportunity(
    id: 'o01',
    type: OpportunityType.seasonal,
    title: 'Quạt tích điện sắp vào mùa nóng',
    description:
        'Tìm kiếm "quạt tích điện" tăng mạnh trước hè; tồn kho của bạn còn '
        'thấp so với nhịp bán tháng trước.',
    expectedImpact: 45000000,
    score: scoreOpportunity(
      impact: 45000000,
      baseline: _sampleBaseline,
      orders: 9,
    ),
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
    score: scoreOpportunity(
      impact: 12000000,
      baseline: _sampleBaseline,
      orders: 3,
    ),
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
    score: scoreOpportunity(
      impact: 28000000,
      baseline: _sampleBaseline,
      orders: 6,
    ),
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
    score: scoreOpportunity(
      impact: 15000000,
      baseline: _sampleBaseline,
      orders: 2,
    ),
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
    score: scoreOpportunity(
      impact: 60000000,
      baseline: _sampleBaseline,
      orders: 8,
    ),
    discoveredAt: DateTime(2026, 7, 19),
  ),
];
