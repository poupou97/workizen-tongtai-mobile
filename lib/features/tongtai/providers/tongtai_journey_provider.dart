import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../journey/business_goal_repository.dart';
import 'tongtai_chat_provider.dart' show tongtaiDatabaseProvider;

/// The real, persistent Business Journey source (WTM-124) — Drift over the local
/// business's goals. **User Data First**: a new user starts with no goals; the
/// sample goals are Demo-Mode only ([SampleBusinessGoalRepository]) and are
/// never wired here. Tests inject an in-memory repository instead.
final businessGoalRepositoryProvider = Provider<BusinessGoalRepository>(
  (ref) => DriftBusinessGoalRepository(ref.watch(tongtaiDatabaseProvider)),
);
