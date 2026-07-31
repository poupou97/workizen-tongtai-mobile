import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../navigation/tongtai_design_tokens.dart';

/// The privacy policy, in the app (WTM-37).
///
/// Until now the "Privacy Policy" row in Settings was `onTap: () {}` — a seller
/// who wanted to know what happens to their customer list tapped it and got
/// nothing. That is worse than no row at all.
///
/// Every claim here is checked against behaviour in
/// `docs/05-OPERATIONS/PRIVACY-POLICY.md`, which is the source of truth this
/// screen and the store listing both copy from. **Wiring a new telemetry event
/// means editing that file and this screen's strings in the same change** — a
/// policy that says less than the app does is a false statement, not a missing
/// document.
class TongtaiPrivacyPolicyScreen extends StatelessWidget {
  const TongtaiPrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sections = <(String, String)>[
      (l10n.privacyLocalTitle, l10n.privacyLocalBody),
      (l10n.privacyAiTitle, l10n.privacyAiBody),
      (l10n.privacyTelemetryTitle, l10n.privacyTelemetryBody),
      (l10n.privacyCrashTitle, l10n.privacyCrashBody),
      (l10n.privacyNoAdsTitle, l10n.privacyNoAdsBody),
      (l10n.privacyBackupTitle, l10n.privacyBackupBody),
      (l10n.privacySampleTitle, l10n.privacySampleBody),
      (l10n.privacyRightsTitle, l10n.privacyRightsBody),
    ];

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: SafeArea(
        child: ListView.separated(
          key: const Key('privacy-list'),
          padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
          itemCount: sections.length + 1,
          separatorBuilder: (_, _) =>
              const SizedBox(height: TongtaiDesignTokens.spacing5),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Text(
                l10n.privacyUpdated,
                key: const Key('privacy-updated'),
                style: TongtaiDesignTokens.captionStyle.copyWith(
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              );
            }
            final (title, body) = sections[index - 1];
            return Column(
              key: Key('privacy-section-${index - 1}'),
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
          },
        ),
      ),
    );
  }
}
