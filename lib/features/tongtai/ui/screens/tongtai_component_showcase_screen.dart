import 'package:flutter/material.dart';

import '../../navigation/tongtai_design_tokens.dart';

/// Live catalogue of the Tổng Tài design system (WTM-62).
///
/// Renders every design-token family — typography, domain + semantic colours,
/// buttons, cards, badges and elevation — so designers and engineers can verify
/// the tokens visually and reuse the exact same building blocks in feature
/// screens. This is the single source of truth "component library" surface.
class TongtaiComponentShowcaseScreen extends StatelessWidget {
  const TongtaiComponentShowcaseScreen({super.key});

  static const String routeName = '/tongtai/showcase';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design System')),
      body: ListView(
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
        children: const [
          _Section(title: 'Typography', child: _TypographyShowcase()),
          _Section(title: 'Domain Colors', child: _DomainColorsShowcase()),
          _Section(title: 'Semantic Colors', child: _SemanticColorsShowcase()),
          _Section(title: 'Buttons', child: _ButtonsShowcase()),
          _Section(title: 'Badges', child: _BadgesShowcase()),
          _Section(title: 'Cards & Elevation', child: _CardsShowcase()),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: TongtaiDesignTokens.spacing6,
            bottom: TongtaiDesignTokens.spacing3,
          ),
          child: Text(title, style: TongtaiDesignTokens.heading3Style),
        ),
        child,
        const Divider(height: TongtaiDesignTokens.spacing8),
      ],
    );
  }
}

class _TypographyShowcase extends StatelessWidget {
  const _TypographyShowcase();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Display', style: TongtaiDesignTokens.displayStyle),
        Text('Heading 1', style: TongtaiDesignTokens.heading1Style),
        Text('Heading 2', style: TongtaiDesignTokens.heading2Style),
        Text('Heading 3', style: TongtaiDesignTokens.heading3Style),
        Text('Body text', style: TongtaiDesignTokens.bodyStyle),
        Text('Small text', style: TongtaiDesignTokens.smallStyle),
        Text('Caption text', style: TongtaiDesignTokens.captionStyle),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusMd),
          ),
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing1),
        Text(label, style: TongtaiDesignTokens.captionStyle),
      ],
    );
  }
}

class _DomainColorsShowcase extends StatelessWidget {
  const _DomainColorsShowcase();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: TongtaiDesignTokens.spacing4,
      runSpacing: TongtaiDesignTokens.spacing3,
      children: [
        _Swatch(color: TongtaiDesignTokens.producerGreen, label: 'Producer'),
        _Swatch(color: TongtaiDesignTokens.inventoryOrange, label: 'Inventory'),
        _Swatch(color: TongtaiDesignTokens.consumerBlue, label: 'Consumer'),
        _Swatch(color: TongtaiDesignTokens.financePurple, label: 'Finance'),
        _Swatch(color: TongtaiDesignTokens.copilotViolet, label: 'Copilot'),
        _Swatch(color: TongtaiDesignTokens.setupGray, label: 'Setup'),
      ],
    );
  }
}

class _SemanticColorsShowcase extends StatelessWidget {
  const _SemanticColorsShowcase();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: TongtaiDesignTokens.spacing4,
      runSpacing: TongtaiDesignTokens.spacing3,
      children: [
        _Swatch(color: TongtaiDesignTokens.success, label: 'Success'),
        _Swatch(color: TongtaiDesignTokens.warning, label: 'Warning'),
        _Swatch(color: TongtaiDesignTokens.error, label: 'Error'),
        _Swatch(color: TongtaiDesignTokens.info, label: 'Info'),
        _Swatch(color: TongtaiDesignTokens.neutral, label: 'Neutral'),
      ],
    );
  }
}

class _ButtonsShowcase extends StatelessWidget {
  const _ButtonsShowcase();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: TongtaiDesignTokens.spacing3,
      runSpacing: TongtaiDesignTokens.spacing3,
      children: [
        SizedBox(
          height: TongtaiDesignTokens.buttonHeight,
          child: FilledButton(onPressed: () {}, child: const Text('Primary')),
        ),
        SizedBox(
          height: TongtaiDesignTokens.buttonHeight,
          child: OutlinedButton(
            onPressed: () {},
            child: const Text('Secondary'),
          ),
        ),
        SizedBox(
          height: TongtaiDesignTokens.buttonHeight,
          child: TextButton(onPressed: () {}, child: const Text('Ghost')),
        ),
      ],
    );
  }
}

class _BadgesShowcase extends StatelessWidget {
  const _BadgesShowcase();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: TongtaiDesignTokens.spacing3,
      runSpacing: TongtaiDesignTokens.spacing3,
      children: [
        _badge('Success', TongtaiDesignTokens.success),
        _badge('Warning', TongtaiDesignTokens.warning),
        _badge('Error', TongtaiDesignTokens.error),
      ],
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: TongtaiDesignTokens.badgePadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusFull),
      ),
      child: Text(
        label,
        style: TongtaiDesignTokens.captionStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CardsShowcase extends StatelessWidget {
  const _CardsShowcase();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _card('Elevation 1', TongtaiDesignTokens.elevation1),
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        _card('Elevation 2', TongtaiDesignTokens.elevation2),
        const SizedBox(height: TongtaiDesignTokens.spacing3),
        _card('Elevation 3', TongtaiDesignTokens.elevation3),
      ],
    );
  }

  Widget _card(String label, List<BoxShadow> shadow) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      decoration: BoxDecoration(
        color: TongtaiDesignTokens.lightBackground,
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.cardBorderRadius,
        ),
        boxShadow: shadow,
        border: Border.all(color: TongtaiDesignTokens.lightBorder),
      ),
      child: Text(label, style: TongtaiDesignTokens.bodyStyle),
    );
  }
}
