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

  // ── Readable-as-text twins (WTM-169) ───────────────────────────────────
  //
  // The colours above ARE the brand — they stay exactly as they are for fills,
  // borders, icons and charts, where no contrast rule applies.
  //
  // What they cannot do is carry TEXT. Measured against the surfaces this app
  // actually pairs them with, `producerGreen` reads at 2.31:1 and
  // `inventoryOrange` at 2.15:1 — WCAG AA asks for 4.5:1, and a seller reading
  // a phone in daylight is exactly the person that number is about.
  //
  // Each twin is the same hue two steps darker, verified ≥4.5:1 on white and on
  // every 10 %-tint surface these colours are used behind
  // (test/features/tongtai/p0/accessibility_test.dart).

  /// Producer green, dark enough to read (5.48:1 on white).
  static const Color producerGreenText = Color(0xFF047857);

  /// Inventory amber, dark enough to read (5.02:1) — amber at full saturation
  /// is the worst offender of the set and cannot be used for text at all.
  static const Color inventoryOrangeText = Color(0xFFB45309);

  /// Consumer blue, dark enough to read (6.70:1).
  static const Color consumerBlueText = Color(0xFF1D4ED8);

  /// Finance violet, dark enough to read (7.10:1).
  static const Color financeVioletText = Color(0xFF6D28D9);

  /// Error red, dark enough to read (6.47:1).
  static const Color errorText = Color(0xFFB91C1C);

  /// Secondary text (7.56:1 on white). `lightTextSecondary` passes on white but
  /// fails at 4.39:1 on the tinted card surfaces it is routinely placed on —
  /// so the readable twin is the one text should use.
  static const Color neutralText = Color(0xFF4B5563);

  /// The readable twin of a capability/semantic colour.
  ///
  /// Exists so a shared component that is *handed* a capability colour (pills,
  /// badges, headers) can render its label legibly without every caller having
  /// to remember a second constant. Anything unrecognised falls back to primary
  /// text, because guessing at a contrast ratio is how this bug happened.
  static Color readableText(Color base) => switch (base.toARGB32()) {
    0xFF10B981 => producerGreenText, // producerGreen / success
    0xFFF59E0B => inventoryOrangeText, // inventoryOrange / warning
    0xFF3B82F6 => consumerBlueText, // consumerBlue / info
    0xFF8B5CF6 => financeVioletText, // financePurple
    0xFFA78BFA => financeVioletText, // copilotViolet
    0xFFEF4444 => errorText, // error
    0xFF6B7280 => neutralText, // setupGray / neutral
    _ => lightTextPrimary,
  };

  // ── Light Theme ────────────────────────────────────────────────────────

  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF111827);

  /// Gray-600, not gray-500. The lighter step passes on pure white (4.83:1)
  /// and fails on every tinted card this app puts it on (4.39:1) — and
  /// secondary text is precisely where a business puts the number a seller
  /// squints at. Measured, not guessed (WTM-169).
  static const Color lightTextSecondary = Color(0xFF4B5563);
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
  /// 48 dp, not 44 — Android's minimum tap target, and the number
  /// `androidTapTargetGuideline` enforces. At 44 the rendered control measured
  /// 46 dp and failed by two pixels, which is exactly the kind of miss nobody
  /// spots by looking (WTM-169).
  static const double buttonHeight = 48;

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

  /// Slot 4, formerly `more` (WTM-192, Founder decision 2026-08-01).
  ///
  /// The index is **reused rather than appended** on purpose: a seller with
  /// tab 4 already persisted lands on Opportunity instead of an out-of-range
  /// index, and the bar stays at five — six tabs is cramped on a small phone,
  /// and the Concept has eight capabilities, so tabs were never going to
  /// represent all of them anyway.
  static const int opportunity = 4;
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
    case TongtaiTabs.opportunity:
      return TongtaiDesignTokens.copilotViolet;
    case TongtaiTabs.home:
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
    case TongtaiTabs.opportunity:
      return 'Opportunity';
    default:
      return 'Unknown';
  }
}
