import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capability/customer_capability.dart';
import '../capability/revenue_capability.dart';
import 'tongtai_consumer_provider.dart';
import 'tongtai_orders_provider.dart';

/// **On-demand Capability Contexts** (WTM-153/154, ADR-TON-016).
///
/// One provider per deep-analysis capability, each over the **production**
/// repositories — the same `orderRepositoryProvider` / `customerRepositoryProvider`
/// Home, Reports and every capability screen read (One Data Path, ADR-TON-015).
///
/// These are deliberately **not** composed into `businessContextServiceProvider`:
/// `BusinessContext` stays a flat snapshot of lightweight summaries, and the
/// heavy analysis is loaded only by the screen or Rule Twin that asks for it.
/// Wiring one of these into the business snapshot would recreate exactly the
/// God Object ADR-TON-016 forbids.
///
/// `FutureProvider` means a watcher gets loading/error/data for free and the
/// result is cached until a dependency changes. Tests override the repository
/// providers with in-memory ones (and inject a clock through the underlying
/// `RevenueCapabilityProvider` / `CustomerCapabilityProvider` directly).

/// Revenue history, growth, trend, volatility and seasonality (WTM-153).
final revenueCapabilityProvider = FutureProvider<RevenueCapabilityContext>(
  (ref) => RevenueCapabilityProvider(ref.watch(orderRepositoryProvider)).load(),
);

/// Per-customer RFM, lifecycle segmentation and win-back candidates (WTM-154).
final customerCapabilityProvider = FutureProvider<CustomerCapabilityContext>(
  (ref) => CustomerCapabilityProvider(
    ref.watch(customerRepositoryProvider),
    ref.watch(orderRepositoryProvider),
  ).load(),
);
