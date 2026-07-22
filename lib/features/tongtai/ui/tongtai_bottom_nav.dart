import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                label: 'Home',
                onTap: onTabSelected,
              ),
              _NavTab(
                index: TongtaiTabs.producer,
                selectedIndex: selectedIndex,
                icon: Icons.shopping_bag_outlined,
                selectedIcon: Icons.shopping_bag,
                label: 'Producer',
                color: TongtaiDesignTokens.producerGreen,
                onTap: onTabSelected,
              ),
              _NavTab(
                index: TongtaiTabs.inventory,
                selectedIndex: selectedIndex,
                icon: Icons.warehouse_outlined,
                selectedIcon: Icons.warehouse,
                label: 'Inventory',
                color: TongtaiDesignTokens.inventoryOrange,
                onTap: onTabSelected,
              ),
              _NavTab(
                index: TongtaiTabs.consumer,
                selectedIndex: selectedIndex,
                icon: Icons.people_outline,
                selectedIcon: Icons.people,
                label: 'Consumer',
                color: TongtaiDesignTokens.consumerBlue,
                onTap: onTabSelected,
              ),
              _NavTab(
                index: TongtaiTabs.more,
                selectedIndex: selectedIndex,
                icon: Icons.menu_outlined,
                selectedIcon: Icons.menu,
                label: 'More',
                color: TongtaiDesignTokens.setupGray,
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

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? selectedIcon : icon,
            size: TongtaiDesignTokens.navBarIconSize,
            color: isActive ? tabColor : TongtaiDesignTokens.lightTextSecondary,
          ),
          const SizedBox(height: 4),
          Text(
            label,
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
    );
  }
}
