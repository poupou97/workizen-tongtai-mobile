import 'package:flutter/material.dart';

/// Design tokens for Tổng Tài navigation and UI components.
/// Based on DESIGN-TOKENS.md and DESIGN-SYSTEM-DRAFT.md
abstract final class TongtaiDesignTokens {
  // ── Domain Colors (Color System) ────────────────────────────────────────

  /// Producer module color (Business Sourcing)
  static const Color producerGreen = Color(0xFF10B981);

  /// Inventory module color (Product & Warehouse)
  static const Color inventoryOrange = Color(0xFFF59E0B);

  /// Consumer/Customer module color (Customer Intelligence)
  static const Color consumerBlue = Color(0xFF3B82F6);

  /// Finance module color (Accounting & Cash)
  static const Color financePurple = Color(0xFF8B5CF6);

  /// AI Copilot module color (AI Assistant)
  static const Color copilotViolet = Color(0xFFA78BFA);

  /// Business Setup color (Configuration)
  static const Color setupGray = Color(0xFF6B7280);

  // ── Semantic Colors ────────────────────────────────────────────────────

  /// Success state
  static const Color success = Color(0xFF10B981);

  /// Warning state
  static const Color warning = Color(0xFFF59E0B);

  /// Error state
  static const Color error = Color(0xFFEF4444);

  /// Info state
  static const Color info = Color(0xFF3B82F6);

  /// Neutral state
  static const Color neutral = Color(0xFF6B7280);

  // ── Light Theme ────────────────────────────────────────────────────────

  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightHover = Color(0xFFF3F4F6);

  // ── Dark Theme ────────────────────────────────────────────────────────

  static const Color darkBackground = Color(0xFF111827);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFFD1D5DB);
  static const Color darkBorder = Color(0xFF374151);
  static const Color darkHover = Color(0xFF1F2937);

  // ── Typography ────────────────────────────────────────────────────────

  /// Display: 32px, 700, Line 40px
  static const TextStyle displayStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
  );

  /// Heading 1: 28px, 700, Line 34px
  static const TextStyle heading1Style = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 34 / 28,
  );

  /// Heading 2: 24px, 600, Line 32px
  static const TextStyle heading2Style = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
  );

  /// Heading 3: 20px, 600, Line 28px
  static const TextStyle heading3Style = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
  );

  /// Body: 16px, 400, Line 24px
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  /// Small: 14px, 400, Line 20px
  static const TextStyle smallStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  /// Caption: 12px, 400, Line 16px
  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
  );

  // ── Spacing Scale (4px base unit) ──────────────────────────────────────

  static const double spacing0 = 0;
  static const double spacing1 = 4;
  static const double spacing2 = 8;
  static const double spacing3 = 12;
  static const double spacing4 = 16;
  static const double spacing5 = 20;
  static const double spacing6 = 24;
  static const double spacing8 = 32;
  static const double spacing10 = 40;
  static const double spacing12 = 48;

  // ── Component Tokens ───────────────────────────────────────────────────

  /// Card border radius
  static const double cardBorderRadius = 12;

  /// Component border radius
  static const double componentBorderRadius = 8;

  /// Button height (touch target)
  static const double buttonHeight = 44;

  /// Input height
  static const double inputHeight = 48;

  /// Badge padding
  static const EdgeInsets badgePadding = EdgeInsets.symmetric(
    horizontal: spacing2,
    vertical: spacing1,
  );

  /// Bottom navigation bar height
  static const double navBarHeight = 64;

  /// Bottom navigation bar icon size
  static const double navBarIconSize = 24;

  // ── Border Radius Scale ────────────────────────────────────────────────

  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radiusFull = 999;

  // ── Elevation / Shadows (5 levels: 0 = flat) ───────────────────────────

  /// Level 0 — flat, no shadow.
  static const List<BoxShadow> elevation0 = [];

  /// Level 1 — subtle (chips, list rows).
  static const List<BoxShadow> elevation1 = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Level 2 — cards.
  static const List<BoxShadow> elevation2 = [
    BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
  ];

  /// Level 3 — raised cards, popovers.
  static const List<BoxShadow> elevation3 = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// Level 4 — modals, bottom sheets.
  static const List<BoxShadow> elevation4 = [
    BoxShadow(color: Color(0x29000000), blurRadius: 20, offset: Offset(0, 8)),
  ];
}

/// Tab navigation indices for Tổng Tài bottom navigation
abstract final class TongtaiTabs {
  static const int home = 0;
  static const int producer = 1;
  static const int inventory = 2;
  static const int consumer = 3;
  static const int more = 4;
}

/// Get color for a specific tab
Color getTabColor(int tabIndex) {
  switch (tabIndex) {
    case TongtaiTabs.producer:
      return TongtaiDesignTokens.producerGreen;
    case TongtaiTabs.inventory:
      return TongtaiDesignTokens.inventoryOrange;
    case TongtaiTabs.consumer:
      return TongtaiDesignTokens.consumerBlue;
    case TongtaiTabs.home:
    case TongtaiTabs.more:
    default:
      return TongtaiDesignTokens.neutral;
  }
}

/// Get tab name for a specific tab index
String getTabName(int tabIndex) {
  switch (tabIndex) {
    case TongtaiTabs.home:
      return 'Home';
    case TongtaiTabs.producer:
      return 'Producer';
    case TongtaiTabs.inventory:
      return 'Inventory';
    case TongtaiTabs.consumer:
      return 'Consumer';
    case TongtaiTabs.more:
      return 'More';
    default:
      return 'Unknown';
  }
}
