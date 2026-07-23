import 'package:flutter/foundation.dart';

import 'business_goal.dart';

/// Mutable, in-memory set of business goals backing the Goals screens
/// (WTM-87) — same ChangeNotifier + upsert pattern as
/// `ProductCatalogController` (WTM-69) / `CustomerDirectoryController`
/// (WTM-76). Local-first; a Drift-backed repository over `JourneysTable` can
/// replace the in-memory list without touching callers.
class BusinessGoalController extends ChangeNotifier {
  BusinessGoalController(Iterable<BusinessGoal> initial)
    : _goals = [...initial];

  /// Convenience: seeded with the built-in sample goals.
  factory BusinessGoalController.sample() =>
      BusinessGoalController(kSampleBusinessGoals);

  final List<BusinessGoal> _goals;

  /// Current goals, newest-updated first, as an unmodifiable snapshot.
  List<BusinessGoal> get goals {
    final sorted = List.of(_goals)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(sorted);
  }

  /// Number of goals.
  int get count => _goals.length;

  /// Insert [goal] (new id) or replace the existing goal with the same id,
  /// then notify listeners. Returns `true` when it replaced (edit), `false`
  /// when appended (add).
  bool upsert(BusinessGoal goal) {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    final replaced = index >= 0;
    if (replaced) {
      _goals[index] = goal;
    } else {
      _goals.add(goal);
    }
    notifyListeners();
    return replaced;
  }
}

/// Deterministic sample goals so the screen has real data to exercise until
/// goals are wired to Drift — same convention as `kSampleCustomers`.
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
