import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../journey/business_goal_repository.dart';
import '../journey/journey.dart';
import '../journey/journey_repository.dart';
import 'tongtai_chat_provider.dart' show tongtaiDatabaseProvider;

/// The real, persistent Business Journey source (WTM-124) — Drift over the local
/// business's goals. **User Data First**: a new user starts with no goals; the
/// sample goals are Demo-Mode only ([SampleBusinessGoalRepository]) and are
/// never wired here. Tests inject an in-memory repository instead.
final businessGoalRepositoryProvider = Provider<BusinessGoalRepository>(
  (ref) => DriftBusinessGoalRepository(ref.watch(tongtaiDatabaseProvider)),
);

/// The Business Journey tree (WTM-185, ADR-TON-021).
///
/// Separate from [businessGoalRepositoryProvider] on purpose: a goal is the
/// *intent*, a journey is the *plan for reaching it*. They live in different
/// tables and a seller can have a goal with no journey — which is exactly the
/// state every existing user is in after upgrading to schema v9.
final journeyRepositoryProvider = Provider<JourneyRepository>(
  (ref) => JourneyRepository(ref.watch(tongtaiDatabaseProvider)),
);

/// Every journey with its tree and plan versions. Registered in
/// `kBusinessDataProviders` so a restore cannot leave the previous business's
/// plan on screen — or, worse, feed it to the AI as if it were this seller's.
final journeysProvider = FutureProvider<List<Journey>>(
  (ref) => ref.watch(journeyRepositoryProvider).loadAll(),
);

/// The one journey being worked on, or `null`.
final activeJourneyProvider = FutureProvider<Journey?>(
  (ref) => ref.watch(journeyRepositoryProvider).loadActive(),
);
