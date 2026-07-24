import 'package:flutter/foundation.dart';

import 'business_goal.dart';
import 'business_goal_repository.dart';

// kSampleBusinessGoals now lives in business_goal.dart (so the Drift repository
// can read it without an import cycle); re-exported here so existing importers
// keep resolving it via the controller.
export 'business_goal.dart' show kSampleBusinessGoals;

/// Set of business goals backing the Goals screens (WTM-87), reads/writes
/// through a [BusinessGoalRepository] (WTM-124) — Drift (real, persistent),
/// Sample (demo) or in-memory (tests). Same repo-backed pattern as
/// `ProductCatalogController` (WTM-121) / `CustomerDirectoryController`
/// (WTM-123). Local-first; the UI never knows which source is behind it.
class BusinessGoalController extends ChangeNotifier {
  BusinessGoalController(this._repository);

  /// Demo/preview goals (read-only sample data). Not persisted.
  factory BusinessGoalController.sample() =>
      BusinessGoalController(const SampleBusinessGoalRepository());

  /// In-memory goals for tests, optionally pre-filled.
  factory BusinessGoalController.inMemory([
    Iterable<BusinessGoal> initial = const [],
  ]) => BusinessGoalController(InMemoryBusinessGoalRepository(initial));

  final BusinessGoalRepository _repository;
  final List<BusinessGoal> _goals = [];
  bool _hydrated = false;

  /// True once [hydrate] has loaded from the repository.
  bool get isHydrated => _hydrated;

  /// Current goals, newest-updated first, as an unmodifiable snapshot.
  List<BusinessGoal> get goals {
    final sorted = List.of(_goals)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(sorted);
  }

  /// Number of goals.
  int get count => _goals.length;

  /// Loads the goals from the repository (call once when the screen mounts).
  Future<void> hydrate() async {
    final loaded = await _repository.loadAll();
    _goals
      ..clear()
      ..addAll(loaded);
    _hydrated = true;
    notifyListeners();
  }

  /// Persist [goal] (new id) or replace the existing goal with the same id,
  /// then notify listeners. Returns `true` when it replaced (edit), `false`
  /// when appended (add).
  Future<bool> upsert(BusinessGoal goal) async {
    await _repository.upsert(goal);
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
