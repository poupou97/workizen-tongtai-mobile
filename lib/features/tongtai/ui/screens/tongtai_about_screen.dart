import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../export/backup_format.dart' show kTongtaiAppVersion;
import '../../navigation/tongtai_design_tokens.dart';

/// "About Tổng Tài" (WTM-170).
///
/// The row existed in Settings with `onTap: () {}`. This is the smallest thing
/// that makes it true: what the app is, which version is running, and where the
/// data lives — the last being the question the row is usually tapped for.
///
/// The version comes from [kTongtaiAppVersion], which a governance test already
/// pins to `pubspec.yaml`, so this screen cannot drift into claiming a version
/// that was never built.
class TongtaiAboutScreen extends StatelessWidget {
  const TongtaiAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(title: Text(l10n.moreAbout)),
      body: SafeArea(
        child: ListView(
          key: const Key('about-list'),
          padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: TongtaiDesignTokens.producerGreen.withValues(
                        alpha: 0.12,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      size: 36,
                      color: TongtaiDesignTokens.producerGreenText,
                    ),
                  ),
                  const SizedBox(height: TongtaiDesignTokens.spacing3),
                  Text(
                    'Tổng Tài',
                    style: TongtaiDesignTokens.heading2Style.copyWith(
                      color: TongtaiDesignTokens.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: TongtaiDesignTokens.spacing1),
                  Text(
                    l10n.aboutVersion(kTongtaiAppVersion),
                    key: const Key('about-version'),
                    style: TongtaiDesignTokens.captionStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing6),
            _AboutSection(title: l10n.aboutWhatTitle, body: l10n.aboutWhatBody),
            const SizedBox(height: TongtaiDesignTokens.spacing5),
            _AboutSection(title: l10n.aboutDataTitle, body: l10n.aboutDataBody),
            const SizedBox(height: TongtaiDesignTokens.spacing5),
            _AboutSection(title: l10n.aboutAiTitle, body: l10n.aboutAiBody),
          ],
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TongtaiDesignTokens.bodyStyle.copyWith(
            fontWeight: FontWeight.w700,
            color: TongtaiDesignTokens.lightTextPrimary,
          ),
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing2),
        Text(
          body,
          style: TongtaiDesignTokens.smallStyle.copyWith(
            color: TongtaiDesignTokens.lightTextPrimary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
