import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/navigation/tongtai_design_tokens.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_component_showcase_screen.dart';

/// Real widget tests for the design-system showcase (WTM-62): the screen is
/// actually built and pumped, and token values are asserted.
void main() {
  testWidgets('showcase renders all design-system sections', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TongtaiComponentShowcaseScreen()),
    );

    expect(find.text('Design System'), findsOneWidget); // AppBar
    expect(find.text('Typography'), findsOneWidget); // visible at top

    // Later sections are below the fold in a lazy ListView — scroll each in.
    for (final section in const [
      'Domain Colors',
      'Semantic Colors',
      'Buttons',
      'Badges',
      'Cards & Elevation',
    ]) {
      await tester.scrollUntilVisible(
        find.text(section),
        300,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text(section), findsOneWidget);
    }
  });

  testWidgets('showcase renders live button variants', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TongtaiComponentShowcaseScreen()),
    );

    // Bring the Buttons section into view first (lazy ListView).
    await tester.scrollUntilVisible(
      find.text('Ghost'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.byType(FilledButton), findsOneWidget); // Primary
    expect(find.byType(OutlinedButton), findsOneWidget); // Secondary
    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Secondary'), findsOneWidget);
    expect(find.text('Ghost'), findsOneWidget);
  });

  test('design tokens expose a complete, self-consistent scale', () {
    // Spacing scale is on the 4px base unit.
    expect(TongtaiDesignTokens.spacing1, 4);
    expect(TongtaiDesignTokens.spacing4, 16);

    // Radius scale present.
    expect(TongtaiDesignTokens.radiusSm, 4);
    expect(TongtaiDesignTokens.radiusLg, 12);

    // Five elevation levels (0 flat + 4 shadowed).
    expect(TongtaiDesignTokens.elevation0, isEmpty);
    expect(TongtaiDesignTokens.elevation1, hasLength(1));
    expect(TongtaiDesignTokens.elevation4, hasLength(1));

    // Touch target meets the 44px accessibility minimum.
    expect(TongtaiDesignTokens.buttonHeight, greaterThanOrEqualTo(44));
  });
}
