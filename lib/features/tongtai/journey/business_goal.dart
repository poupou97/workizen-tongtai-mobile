import 'package:flutter/foundation.dart';

/// The kind of business goal a seller can pursue (WTM-87 AC2 — templates for
/// different business types). Mirrors the goal archetypes in
/// `docs/01-PRODUCT/BUSINESS-JOURNEY-BIBLE.md`; bilingual like every domain
/// enum (WTM-60 convention).
enum GoalType {
  revenue,
  newChannel,
  customerGrowth,
  productLaunch;

  String get labelEn => switch (this) {
    GoalType.revenue => 'Grow revenue',
    GoalType.newChannel => 'Open a new sales channel',
    GoalType.customerGrowth => 'Acquire customers',
    GoalType.productLaunch => 'Launch a product',
  };

  String get labelVi => switch (this) {
    GoalType.revenue => 'Tăng doanh thu',
    GoalType.newChannel => 'Mở kênh bán mới',
    GoalType.customerGrowth => 'Tăng khách hàng',
    GoalType.productLaunch => 'Ra mắt sản phẩm',
  };

  /// Label for a language code ('vi' -> Vietnamese, otherwise English).
  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// How a goal is tracking against its timeline (WTM-87 AC4). Derived, never
/// stored — see [BusinessGoal.pace].
enum GoalPace {
  ahead,
  onTrack,
  behind,
  completed,
  notStarted;

  String get labelEn => switch (this) {
    GoalPace.ahead => 'Ahead',
    GoalPace.onTrack => 'On track',
    GoalPace.behind => 'Behind',
    GoalPace.completed => 'Completed',
    GoalPace.notStarted => 'Not started',
  };

  String get labelVi => switch (this) {
    GoalPace.ahead => 'Vượt tiến độ',
    GoalPace.onTrack => 'Đúng tiến độ',
    GoalPace.behind => 'Chậm tiến độ',
    GoalPace.completed => 'Hoàn thành',
    GoalPace.notStarted => 'Chưa bắt đầu',
  };

  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// A template pre-filling the goal form (WTM-87 AC2). Values are suggestions —
/// every field stays editable in the form.
@immutable
class GoalTemplate {
  const GoalTemplate({
    required this.type,
    required this.nameEn,
    required this.nameVi,
    required this.suggestedTarget,
    required this.suggestedDays,
    required this.suggestedGrowthTarget,
  });

  final GoalType type;
  final String nameEn;
  final String nameVi;

  /// Suggested revenue target in đồng (0 for non-revenue goals).
  final double suggestedTarget;

  /// Suggested timeline length in days.
  final int suggestedDays;

  /// Suggested secondary metric (orders / customers / units — depends on type).
  final int suggestedGrowthTarget;

  String name(String languageCode) => languageCode == 'vi' ? nameVi : nameEn;
}

/// Built-in goal templates (WTM-87 AC2), one per [GoalType]. Amounts reflect
/// a typical Vietnamese SME seller's scale (đồng).
const List<GoalTemplate> kTongtaiGoalTemplates = [
  GoalTemplate(
    type: GoalType.revenue,
    nameEn: 'Reach 100M ₫ this quarter',
    nameVi: 'Đạt 100 triệu ₫ trong quý',
    suggestedTarget: 100000000,
    suggestedDays: 90,
    suggestedGrowthTarget: 200, // orders
  ),
  GoalTemplate(
    type: GoalType.newChannel,
    nameEn: 'Open a TikTok Shop channel',
    nameVi: 'Mở kênh TikTok Shop',
    suggestedTarget: 30000000,
    suggestedDays: 60,
    suggestedGrowthTarget: 50, // orders via the new channel
  ),
  GoalTemplate(
    type: GoalType.customerGrowth,
    nameEn: 'Gain 100 new customers',
    nameVi: 'Thêm 100 khách hàng mới',
    suggestedTarget: 0,
    suggestedDays: 60,
    suggestedGrowthTarget: 100, // customers
  ),
  GoalTemplate(
    type: GoalType.productLaunch,
    nameEn: 'Launch a new product line',
    nameVi: 'Ra mắt dòng sản phẩm mới',
    suggestedTarget: 50000000,
    suggestedDays: 45,
    suggestedGrowthTarget: 100, // units sold
  ),
];

/// A seller-defined business goal (WTM-87) — pure, immutable domain model in
/// the same shape family as the Drift `JourneysTable` (goal text, progress,
/// timeline, revenue fields), so a Drift-backed repository can replace the
/// in-memory controller without touching callers.
@immutable
class BusinessGoal {
  const BusinessGoal({
    required this.id,
    required this.name,
    required this.type,
    required this.targetAmount,
    required this.achievedAmount,
    required this.growthTarget,
    required this.growthAchieved,
    required this.startDate,
    required this.endDate,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Stable identifier.
  final String id;

  /// Display name, e.g. "Đạt 100 triệu ₫ trong quý".
  final String name;

  /// The goal archetype (drives labels + which metric matters most).
  final GoalType type;

  /// Revenue target in đồng; 0 when the goal is not revenue-denominated.
  final double targetAmount;

  /// Revenue achieved so far, in đồng — updated via the edit flow today,
  /// wired to real order data when Reports land (WTM-96).
  final double achievedAmount;

  /// Secondary metric target (orders / customers / units, per [type]).
  final int growthTarget;

  /// Secondary metric achieved so far.
  final int growthAchieved;

  /// Timeline (AC1): inclusive start and end dates.
  final DateTime startDate;
  final DateTime endDate;

  /// Free-form context the seller adds for themselves (and, later, the AI
  /// plan generator — WTM-88).
  final String notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Primary progress fraction 0..1 (AC4): revenue-based when a revenue
  /// target exists, otherwise growth-metric-based. Clamped at 1.
  double get progress {
    final double raw;
    if (targetAmount > 0) {
      raw = achievedAmount / targetAmount;
    } else if (growthTarget > 0) {
      raw = growthAchieved / growthTarget;
    } else {
      raw = 0;
    }
    return raw.clamp(0.0, 1.0);
  }

  /// Fraction of the timeline elapsed at [now], 0..1. 0 before [startDate],
  /// 1 after [endDate].
  double timelineElapsed(DateTime now) {
    if (!now.isAfter(startDate)) return 0;
    if (!now.isBefore(endDate)) return 1;
    final total = endDate.difference(startDate).inMinutes;
    if (total <= 0) return 1;
    return now.difference(startDate).inMinutes / total;
  }

  /// Whole days remaining at [now]; never negative.
  int daysRemaining(DateTime now) {
    final remaining = endDate.difference(now).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  /// How the goal is pacing at [now] (AC4): progress compared to timeline
  /// elapsed, with a ±10-point comfort band.
  GoalPace pace(DateTime now) {
    if (progress >= 1) return GoalPace.completed;
    final elapsed = timelineElapsed(now);
    if (elapsed == 0) return GoalPace.notStarted;
    if (progress >= elapsed + 0.1) return GoalPace.ahead;
    if (progress + 0.1 < elapsed) return GoalPace.behind;
    return GoalPace.onTrack;
  }

  /// Rule-based, deterministic recommendation for the goal's current state
  /// (WTM-87 AC5). Bilingual. The AI-generated action plan (WTM-88) will
  /// build on this seam — this never calls a network.
  String recommendation(DateTime now, {String languageCode = 'vi'}) {
    final vi = languageCode == 'vi';
    return switch (pace(now)) {
      GoalPace.completed =>
        vi
            ? 'Mục tiêu đã hoàn thành — đặt mục tiêu tiếp theo để giữ đà tăng trưởng.'
            : 'Goal achieved — set the next goal to keep the momentum.',
      GoalPace.notStarted =>
        vi
            ? 'Chưa tới ngày bắt đầu. Chuẩn bị nguồn hàng và kênh bán trước.'
            : 'Not started yet. Prepare sourcing and channels first.',
      GoalPace.ahead =>
        vi
            ? 'Đang vượt tiến độ — cân nhắc nâng mục tiêu hoặc mở rộng kênh bán.'
            : 'Ahead of schedule — consider raising the target or expanding channels.',
      GoalPace.onTrack =>
        vi
            ? 'Đang đúng tiến độ — duy trì nhịp bán hiện tại và theo dõi tồn kho.'
            : 'On track — keep the current pace and watch inventory.',
      GoalPace.behind =>
        vi
            ? 'Đang chậm tiến độ (${(progress * 100).round()}% sau ${(timelineElapsed(now) * 100).round()}% thời gian) — đẩy khuyến mãi hoặc thêm kênh bán.'
            : 'Behind schedule (${(progress * 100).round()}% at ${(timelineElapsed(now) * 100).round()}% of the timeline) — run promotions or add a channel.',
    };
  }

  BusinessGoal copyWith({
    String? name,
    GoalType? type,
    double? targetAmount,
    double? achievedAmount,
    int? growthTarget,
    int? growthAchieved,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    DateTime? updatedAt,
  }) {
    return BusinessGoal(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      targetAmount: targetAmount ?? this.targetAmount,
      achievedAmount: achievedAmount ?? this.achievedAmount,
      growthTarget: growthTarget ?? this.growthTarget,
      growthAchieved: growthAchieved ?? this.growthAchieved,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is BusinessGoal && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BusinessGoal($id, $name, ${type.name})';
}

/// Deterministic sample goals so Demo/Preview surfaces have real data to
/// exercise — same convention as `kSampleCustomers`. Lives in the domain file
/// (not the controller) so the Drift repository can read it without importing
/// the controller (which would form a cycle). Not `const` because the dates are
/// runtime [DateTime]s.
final List<BusinessGoal> kSampleBusinessGoals = [
  BusinessGoal(
    id: 'g01',
    name: 'Đạt 100 triệu ₫ trong quý 3',
    type: GoalType.revenue,
    targetAmount: 100000000,
    achievedAmount: 62000000,
    growthTarget: 200,
    growthAchieved: 118,
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 9, 30),
    notes: 'Tập trung đơn Shopee + khách sỉ Hà Nội.',
    createdAt: DateTime(2026, 7, 1),
    updatedAt: DateTime(2026, 7, 20),
  ),
  BusinessGoal(
    id: 'g02',
    name: 'Mở kênh TikTok Shop',
    type: GoalType.newChannel,
    targetAmount: 30000000,
    achievedAmount: 4500000,
    growthTarget: 50,
    growthAchieved: 6,
    startDate: DateTime(2026, 7, 15),
    endDate: DateTime(2026, 9, 15),
    notes: '',
    createdAt: DateTime(2026, 7, 15),
    updatedAt: DateTime(2026, 7, 18),
  ),
];
