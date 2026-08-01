import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../screens/tongtai_more_screen.dart';

/// The **More** entry point, now that it is no longer a tab (WTM-192).
///
/// The Founder's decision moved Opportunity Hub into the bottom bar in More's
/// place. Opportunity is one of the Concept's eight capabilities and something
/// a seller looks at daily; More is a **toolbox** — backup, privacy, AI key,
/// language — reached occasionally. What is used every day earns a place in the
/// bar; what is used every month does not.
///
/// That trade is only acceptable if More stays **one tap from every tab**,
/// which is what this widget guarantees: it goes in the `actions:` of all five
/// tab screens, so no setting got further away than it was.
class TongtaiMoreAction extends StatelessWidget {
  const TongtaiMoreAction({super.key});

  /// Stable test ID (`<screen>-<role>`): the same action appears on every tab,
  /// so a behaviour test can assert reachability without naming a screen.
  static const Key actionKey = Key('appbar-open-more');

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: actionKey,
      tooltip: context.l10n.navMore,
      icon: const Icon(Icons.more_horiz),
      onPressed: () => Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const TongtaiMoreScreen()),
      ),
    );
  }
}
