import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../navigation/tongtai_design_tokens.dart';
import 'tongtai_fox_mascot.dart';
import 'tongtai_more_action.dart';

/// Concept-1 screen header (WTM-216): mascot · title · subtitle.
///
/// Every main screen in `concept-1` wears the same header — the Origami fox,
/// the screen's name, and one line saying what the screen is for. Before this
/// the app shipped a bare `AppBar(title: Text(...))`, so the mascot only ever
/// appeared in empty states and the seller met the brand least often on the
/// screens they use most.
///
/// **One builder, not five copies.** The header is chrome, but the reason the
/// data layer forbids per-screen copies (ADR-TON-015) applies here too: five
/// hand-built headers drift apart, and the drift is invisible until someone
/// screenshots two tabs side by side.
///
/// A function rather than a `PreferredSizeWidget`: `preferredSize` is read by
/// `Scaffold` before any `build`, so it cannot see the `BuildContext` — and
/// the height MUST see it, because a two-line title at a 2.0× system font
/// outgrows `kToolbarHeight` (the WTM-169 overflow class).
AppBar tongtaiScreenHeader(
  BuildContext context, {
  required String screen,
  required String title,
  required String subtitle,
  List<Widget> actions = const [TongtaiMoreAction()],
  Color? backgroundColor,
  Color? foregroundColor,
}) {
  final scaler = MediaQuery.textScalerOf(context);
  return AppBar(
    key: Key('$screen-header'),
    elevation: 0,
    backgroundColor: backgroundColor ?? TongtaiDesignTokens.lightBackground,
    foregroundColor: foregroundColor ?? TongtaiDesignTokens.lightTextPrimary,
    // Title + subtitle stack, so the bar grows with the system font instead of
    // clipping the subtitle away.
    toolbarHeight: math.max(kToolbarHeight, scaler.scale(kToolbarHeight)),
    title: Row(
      children: [
        // The mascot is a drawing, not text — scaling it with the font would
        // eat the width the title needs at 2.0×.
        const TongtaiFoxMascot.avatar(size: 32),
        const SizedBox(width: TongtaiDesignTokens.spacing2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TongtaiDesignTokens.heading3Style.copyWith(
                  color:
                      foregroundColor ?? TongtaiDesignTokens.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                key: Key('$screen-header-subtitle'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TongtaiDesignTokens.captionStyle.copyWith(
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    actions: actions,
  );
}

/// The subtitle each capability's header carries, keyed by screen so a caller
/// cannot pair Inventory's header with Consumer's line.
///
/// Takes [AppStrings] rather than a `BuildContext` so the whole mapping is
/// unit-testable against both locales without pumping a widget.
String tongtaiScreenSubtitle(AppStrings l10n, String screen) {
  return switch (screen) {
    'producer' => l10n.subtitleProducer,
    'inventory' => l10n.subtitleInventory,
    'consumer' => l10n.subtitleConsumer,
    'opportunity' => l10n.subtitleOpportunity,
    'finance' => l10n.subtitleFinance,
    'reports' => l10n.subtitleReports,
    // No message: the l10n scanner rightly bans English prose under `ui/`, and
    // `ArgumentError.value` already names the offending value and parameter.
    _ => throw ArgumentError.value(screen, 'screen'),
  };
}
