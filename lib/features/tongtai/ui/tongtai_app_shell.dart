import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/deeplink/tongtai_deep_link_provider.dart';
import '../providers/tongtai_navigation_provider.dart';
import 'screens/tongtai_consumer_screen.dart';
import 'screens/tongtai_home_screen.dart';
import 'screens/tongtai_inventory_screen.dart';
import 'screens/tongtai_opportunity_feed_screen.dart';
import 'screens/tongtai_producer_screen.dart';
import 'tongtai_bottom_nav.dart';

/// Root app shell for Tổng Tài product.
/// Manages navigation between the 5 main tabs (Home, Producer, Inventory,
/// Consumer, **Opportunity**).
///
/// WTM-192 (Founder decision 2026-08-01): Opportunity Hub took the fifth slot
/// from **More**. Opportunity is one of the Concept's eight capabilities and a
/// daily read; More is a toolbox reached occasionally, and it now lives in
/// every screen's AppBar — see `TongtaiMoreAction`, which keeps it **one tap
/// from every tab** so nothing got further away.
/// Uses Riverpod for state management and persists tab selection.
///
/// Also the single place deep-link failures (WTM-57) are surfaced: an
/// unresolvable `tongtai://…` link shows a friendly SnackBar instead of
/// navigating anywhere, so a bad link never leaves the user on a broken screen.
class TongtaiAppShell extends ConsumerWidget {
  const TongtaiAppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the selected tab index — rebuilds when it changes
    final selectedIndex = ref.watch(tongtaiSelectedTabProvider);

    // Surface deep-link failures gracefully. We compare the [sequence] counter
    // so repeated identical links still notify, and only act on states that
    // actually carry a new failure.
    ref.listen<TongtaiDeepLinkState>(tongtaiDeepLinkControllerProvider, (
      previous,
      next,
    ) {
      final failure = next.lastFailure;
      final isNewEvent = previous == null || previous.sequence != next.sequence;
      if (failure == null || !isNewEvent) return;

      final languageCode =
          Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(failure.messageFor(languageCode))),
        );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: selectedIndex,
        children: const [
          TongtaiHomeScreen(),
          TongtaiProducerScreen(),
          TongtaiInventoryScreen(),
          TongtaiConsumerScreen(),
          TongtaiOpportunityFeedScreen(),
        ],
      ),
      bottomNavigationBar: TongtaiBottomNav(
        selectedIndex: selectedIndex,
        onTabSelected: (index) {
          ref.read(tongtaiSelectedTabProvider.notifier).select(index);
        },
      ),
    );
  }
}
