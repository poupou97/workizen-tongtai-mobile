import 'package:flutter_riverpod/flutter_riverpod.dart';
// `ProviderOrFamily` — the type `invalidate` accepts — lives in Riverpod 3's
// `misc` surface, not the default export.
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import 'tongtai_capability_provider.dart';
import 'tongtai_context_provider.dart';
import 'tongtai_predictive_provider.dart';

/// **The one list of caches over the business data** (WTM-149, device defect 1).
///
/// Every entry is a non-auto-dispose `FutureProvider`: Riverpod computes it
/// once and hands the SAME value to every later reader until something
/// invalidates it. That is exactly what you want while the data is still —
/// opening Revenue forecast twice must not re-scan the order book — and exactly
/// what is WRONG the moment the data changes underneath.
///
/// The bug this list exists to kill, found on device: More → "Load 12 months of
/// sample data" → Revenue forecast (12 months) → More → "Remove sample data" →
/// Revenue forecast **still showed the full 12-month forecast**. Home looked
/// right only because it re-reads its repositories in `initState`. Nothing but
/// an app restart cleared the predictive screens. That breaks the Founder's
/// cross-screen contract (Summary Count == Domain Visible Records, ADR-TON-014 /
/// ADR-TON-015 One Data Path) and the "resetting sample data is safe and
/// observable" gate.
///
/// **Any** action that writes to a repository must therefore invalidate them —
/// through [invalidateBusinessDataProviders], never by hand. Listing them at one
/// call site would only move the bug: the next data-mutating action would have
/// to remember a list it cannot see. Add a new cached read of the business data
/// here, and every existing caller is fixed for free.
///
/// Deliberately NOT here:
/// - `businessContextServiceProvider`, `*ContextProvider`,
///   `businessMetricsServiceProvider` — plain `Provider`s returning a *service*.
///   They hold no data; each `load()` re-reads the repositories.
/// - `tongtaiUserIdProvider`, `tongtaiHasAiKeyProvider` — cached, but over
///   identity/BYOK state, which sample data cannot change.
/// - `orderRepositoryProvider` & the other repository seams — invalidating one
///   would rebuild the repository object (and, transitively, risk churning the
///   database handle) without changing a single row.
final List<ProviderOrFamily> kBusinessDataProviders = <ProviderOrFamily>[
  // Capability contexts — the heavy analysis the twins are computed over.
  revenueCapabilityProvider,
  customerCapabilityProvider,
  // Rule Twins (ADR-TON-016). Invalidating the capabilities above already
  // invalidates these transitively; they are listed anyway so the contract is
  // readable and survives a future twin that stops watching a capability.
  revenueForecastProvider,
  customerRiskProvider,
  businessAlertsProvider,
  // The Opportunity Rule Engine's output — read by Home, Reports, Timeline,
  // Producer and the Opportunity feed.
  generatedOpportunitiesProvider,
];

/// Drops every cached read of the business data ([kBusinessDataProviders]).
///
/// Call this from a widget after **any** successful mutation of the business
/// data — seeding samples, seeding generated history, removing samples, and any
/// future bulk import/reset. It is cheap and safe when nothing is listening:
/// invalidating an uninitialised provider is a no-op, and an initialised one
/// simply recomputes the next time it is read.
///
/// ```dart
/// await ref.read(sampleDataSeederProvider).removeAll();
/// invalidateBusinessDataProviders(ref);
/// ```
void invalidateBusinessDataProviders(WidgetRef ref) {
  for (final provider in kBusinessDataProviders) {
    ref.invalidate(provider);
  }
}

/// [invalidateBusinessDataProviders] for a bare [ProviderContainer].
///
/// Same list, same effect — `WidgetRef` and `ProviderContainer` share no public
/// `invalidate` interface, so the two entry points wrap one list rather than
/// letting a caller re-derive it. Used by tests and by any future non-widget
/// caller (a background import, a restore-from-backup service).
void invalidateBusinessDataProvidersIn(ProviderContainer container) {
  for (final provider in kBusinessDataProviders) {
    container.invalidate(provider);
  }
}
