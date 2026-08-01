import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../navigation/tongtai_design_tokens.dart';

/// Custom bottom navigation bar for Tổng Tài with 5 main tabs.
/// Handles tab selection, visual styling per design system, and state management.
class TongtaiBottomNav extends ConsumerWidget {
  /// The currently selected tab index
  final int selectedIndex;

  /// Callback when a tab is selected
  final ValueChanged<int> onTabSelected;

  const TongtaiBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: TongtaiDesignTokens.navBarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavTab(
                index: TongtaiTabs.home,
                selectedIndex: selectedIndex,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: context.l10n.navHome,
                onTap: onTabSelected,
              ),
              _NavTab(
                index: TongtaiTabs.producer,
                selectedIndex: selectedIndex,
                icon: Icons.shopping_bag_outlined,
                selectedIcon: Icons.shopping_bag,
                label: context.l10n.navProducer,
                color: TongtaiDesignTokens.producerGreen,
                onTap: onTabSelected,
              ),
              _NavTab(
                index: TongtaiTabs.inventory,
                selectedIndex: selectedIndex,
                icon: Icons.warehouse_outlined,
                selectedIcon: Icons.warehouse,
                label: context.l10n.navInventory,
                color: TongtaiDesignTokens.inventoryOrange,
                onTap: onTabSelected,
              ),
              _NavTab(
                index: TongtaiTabs.consumer,
                selectedIndex: selectedIndex,
                icon: Icons.people_outline,
                selectedIcon: Icons.people,
                label: context.l10n.navConsumer,
                color: TongtaiDesignTokens.consumerBlue,
                onTap: onTabSelected,
              ),
              _NavTab(
                index: TongtaiTabs.opportunity,
                selectedIndex: selectedIndex,
                icon: Icons.lightbulb_outline,
                selectedIcon: Icons.lightbulb,
                label: context.l10n.navOpportunity,
                color: TongtaiDesignTokens.copilotViolet,
                onTap: onTabSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual navigation tab with active/inactive styling
class _NavTab extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Color? color;
  final ValueChanged<int> onTap;

  const _NavTab({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.color,
    required this.onTap,
  });

  bool get isSelected => selectedIndex == index;

  @override
  Widget build(BuildContext context) {
    final tabColor = color ?? TongtaiDesignTokens.neutral;
    final isActive = isSelected;

    // `Expanded`: five tabs share the width evenly instead of each taking its
    // natural size. Without it the bar overflowed by 50 px on a narrow phone
    // the moment "More" became "Cơ hội"/"Opportunity" (WTM-192) — a label a
    // few characters longer is all it takes when nothing is flexible.
    return Expanded(
      child: GestureDetector(
        // Stable test ID (`<screen>-<role>`): behaviour tests select a tab by
        // index, never by its translated label (WTM-192).
        key: Key('nav-tab-$index'),
        // `opaque`, not the default `deferToChild`: the tab is an icon above a
        // label with a gap between them, and `deferToChild` makes that gap —
        // including the tab's own centre — **dead to touch**. A seller aiming at
        // the middle of a tab would hit nothing (WTM-192).
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? selectedIcon : icon,
              size: TongtaiDesignTokens.navBarIconSize,
              color: isActive
                  ? tabColor
                  : TongtaiDesignTokens.lightTextSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? tabColor
                    : TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
            // Active indicator: colored underline
            if (isActive)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: tabColor,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(width: 4, height: 4),
          ],
        ),
      ),
    );
  }
}
