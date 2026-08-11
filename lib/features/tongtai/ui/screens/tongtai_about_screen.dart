import 'package:flutter/material.dart';

import '../../../../core/design/tt.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../export/backup_format.dart' show kTongtaiAppVersion;

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
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(title: Text(l10n.moreAbout)),
      body: SafeArea(
        child: ListView(
          key: const Key('about-list'),
          padding: const EdgeInsets.all(TtSpace.x4),
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: TtColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      size: 36,
                      color: TtColors.successOnLight,
                    ),
                  ),
                  const SizedBox(height: TtSpace.x3),
                  Text(
                    'Tổng Tài',
                    style: TtType.h1.copyWith(color: TtColors.textPrimary),
                  ),
                  const SizedBox(height: TtSpace.x1),
                  Text(
                    l10n.aboutVersion(kTongtaiAppVersion),
                    key: const Key('about-version'),
                    style: TtType.caption.copyWith(
                      color: TtColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TtSpace.x6),
            _AboutSection(title: l10n.aboutWhatTitle, body: l10n.aboutWhatBody),
            const SizedBox(height: TtSpace.x5),
            _AboutSection(title: l10n.aboutDataTitle, body: l10n.aboutDataBody),
            const SizedBox(height: TtSpace.x5),
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
          style: TtType.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: TtColors.textPrimary,
          ),
        ),
        const SizedBox(height: TtSpace.x2),
        Text(
          body,
          style: TtType.body.copyWith(color: TtColors.textPrimary, height: 1.5),
        ),
      ],
    );
  }
}
