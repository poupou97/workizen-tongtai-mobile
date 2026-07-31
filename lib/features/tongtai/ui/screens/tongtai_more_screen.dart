import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../../../core/l10n/language_notifier.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../core/screen_data_controller.dart';
import '../../providers/tongtai_data_invalidation.dart';
import '../widgets/tongtai_screen_data.dart';
import '../../providers/tongtai_sample_provider.dart';
import '../../sample/historical_data_generator.dart';
import '../../providers/tongtai_onboarding_provider.dart';
import 'tongtai_ai_key_screen.dart';
import 'tongtai_customer_risk_screen.dart';
import 'tongtai_backup_screen.dart';
import 'tongtai_export_screen.dart';
import 'tongtai_finance_screen.dart';
import 'tongtai_forecast_screen.dart';
import 'tongtai_goals_screen.dart';
import 'tongtai_reports_screen.dart';
import 'tongtai_timeline_screen.dart';
import 'tongtai_privacy_policy_screen.dart';

/// Opens the language picker (WTM-119) and persists the choice; the app
/// re-renders in the chosen locale via [languageProvider].
Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
  final current = ref.read(languageProvider);
  final picked = await showDialog<String>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(dialogContext.l10n.languagePickerTitle),
      children: [
        for (final code in kSupportedLocaleCodes)
          SimpleDialogOption(
            key: Key('language-option-$code'),
            onPressed: () => Navigator.of(dialogContext).pop(code),
            child: Row(
              children: [
                Icon(
                  code == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: code == current
                      ? TongtaiDesignTokens.producerGreen
                      : TongtaiDesignTokens.lightTextSecondary,
                ),
                const SizedBox(width: TongtaiDesignTokens.spacing3),
                Text(localeDisplayName(code)),
              ],
            ),
          ),
      ],
    ),
  );
  if (picked != null) {
    await ref.read(languageProvider.notifier).setLocale(picked);
  }
}

/// More/Settings screen for Tổng Tài
/// Provides access to settings, help, and additional features.
class TongtaiMoreScreen extends ConsumerWidget {
  const TongtaiMoreScreen({super.key});

  /// WTM-144/ADR-TON-014: seeds the sample fixtures into the PRODUCTION
  /// repositories (idempotent) after an explicit confirmation — every screen
  /// then shows the same data; removable below.
  ///
  /// Like every handler below it ends with [invalidateBusinessDataProviders]:
  /// the capability contexts and Rule Twins are cached `FutureProvider`s, so
  /// without it the predictive screens keep serving the pre-seed answer until
  /// the app restarts (WTM-149 device defect 1).
  Future<void> _seedSamples(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.moreLoadSampleConfirmTitle),
        content: Text(dialogContext.l10n.moreLoadSampleConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('more-demo-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.l10n.moreLoadSampleAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    // WTM-148: seeding writes to five repositories. A failure here used to
    // throw into the void (the FK-787 "Reset sample data" crash) — now it is
    // reported, retryable, and the caches are only invalidated on success.
    final failure = await runTongtaiAction(
      () => ref.read(sampleDataSeederProvider).seed(),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'more',
    );
    if (!context.mounted) return;
    if (failure != null) {
      showTongtaiFailure(
        context,
        failure,
        onRetry: () => _seedSamples(context, ref),
      );
      return;
    }
    invalidateBusinessDataProviders(ref);
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.moreSampleLoadedSnack)));
  }

  /// WTM-149/ADR-TON-016: seeds 12 consecutive months of history so the
  /// seller can try Revenue forecast + Customer risk on realistic data.
  /// Same sample lifecycle as [_seedSamples] — ordinary rows, `sample-`
  /// prefixed, removed by "Xóa dữ liệu mẫu"; user data untouched.
  Future<void> _seedHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.moreLoadHistoryConfirmTitle),
        content: Text(dialogContext.l10n.moreLoadHistoryConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('more-history-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.l10n.moreLoadSampleAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final failure = await runTongtaiAction(
      () => ref
          .read(historicalDataSeederProvider)
          .seed(const HistoricalDataSpec()),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'more',
    );
    if (!context.mounted) return;
    if (failure != null) {
      showTongtaiFailure(
        context,
        failure,
        onRetry: () => _seedHistory(context, ref),
      );
      return;
    }
    invalidateBusinessDataProviders(ref);
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.moreHistoryLoadedSnack)));
  }

  /// Removes ONLY the `sample-` prefixed rows — user data stays (tested).
  Future<void> _removeSamples(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.moreRemoveSampleConfirmTitle),
        content: Text(dialogContext.l10n.moreRemoveSampleConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('more-remove-sample-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.l10n.moreRemoveSampleAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final failure = await runTongtaiAction(
      () => ref.read(sampleDataSeederProvider).removeAll(),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'more',
    );
    if (!context.mounted) return;
    if (failure != null) {
      showTongtaiFailure(
        context,
        failure,
        onRetry: () => _removeSamples(context, ref),
      );
      return;
    }
    invalidateBusinessDataProviders(ref);
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.moreSampleRemovedSnack)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.l10n.navMore),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // App settings section
            _SettingsSection(
              title: context.l10n.moreSettings,
              items: [
                _SettingsItem(
                  icon: Icons.person_outline,
                  label: context.l10n.moreProfile,
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  label: context.l10n.moreNotifications,
                  onTap: () {},
                ),
                _SettingsItem(
                  key: const Key('more-language'),
                  icon: Icons.language,
                  label: context.l10n.settingsLanguage,
                  onTap: () => _pickLanguage(context, ref),
                ),
                _SettingsItem(
                  icon: Icons.dark_mode_outlined,
                  label: context.l10n.moreTheme,
                  onTap: () {},
                ),
              ],
            ),
            // AI Assistant section (WTM-61) — BYOK Grok (xAI) key management.
            _SettingsSection(
              title: context.l10n.titleAiAssistant,
              items: [
                _SettingsItem(
                  key: const Key('more-ai-key'),
                  icon: Icons.auto_awesome,
                  label: context.l10n.moreGrokKey,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const TongtaiAiKeyScreen(),
                    ),
                  ),
                ),
              ],
            ),
            // Business settings section
            _SettingsSection(
              title: context.l10n.moreBusinessSection,
              items: [
                _SettingsItem(
                  key: const Key('more-demo-mode'),
                  icon: Icons.science_outlined,
                  label: context.l10n.moreLoadSample,
                  onTap: () => _seedSamples(context, ref),
                ),
                _SettingsItem(
                  key: const Key('more-load-history'),
                  icon: Icons.timeline,
                  label: context.l10n.moreLoadHistory,
                  onTap: () => _seedHistory(context, ref),
                ),
                _SettingsItem(
                  key: const Key('more-remove-sample'),
                  icon: Icons.delete_sweep_outlined,
                  label: context.l10n.moreRemoveSample,
                  onTap: () => _removeSamples(context, ref),
                ),
                _SettingsItem(
                  key: const Key('more-timeline'),
                  icon: Icons.timeline_outlined,
                  label: context.l10n.titleTimeline,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const TongtaiTimelineScreen(),
                    ),
                  ),
                ),
                _SettingsItem(
                  key: const Key('more-finance'),
                  icon: Icons.account_balance_wallet_outlined,
                  label: context.l10n.titleFinance,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const TongtaiFinanceScreen(),
                    ),
                  ),
                ),
                _SettingsItem(
                  key: const Key('more-reports'),
                  icon: Icons.bar_chart_outlined,
                  label: context.l10n.titleReports,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const TongtaiReportsScreen(),
                    ),
                  ),
                ),
                // Predictive Foundation (WTM-160/161 · ADR-TON-016): the
                // deterministic revenue-forecast and churn/win-back twins —
                // no AI, no key, no network.
                _SettingsItem(
                  key: const Key('more-forecast'),
                  icon: Icons.insights_outlined,
                  label: context.l10n.titleForecast,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const TongtaiForecastScreen(),
                    ),
                  ),
                ),
                _SettingsItem(
                  key: const Key('more-customer-risk'),
                  icon: Icons.trending_down,
                  label: context.l10n.titleCustomerRisk,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const TongtaiCustomerRiskScreen(),
                    ),
                  ),
                ),
                _SettingsItem(
                  key: const Key('more-goals'),
                  icon: Icons.flag_outlined,
                  label: context.l10n.titleBusinessGoals,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const TongtaiGoalsScreen(),
                    ),
                  ),
                ),
                _SettingsItem(
                  key: const Key('more-export'),
                  icon: Icons.ios_share,
                  label: context.l10n.titleExport,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const TongtaiExportScreen(),
                    ),
                  ),
                ),
                _SettingsItem(
                  key: const Key('more-backup'),
                  icon: Icons.settings_backup_restore,
                  label: context.l10n.titleBackup,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const TongtaiBackupScreen(),
                    ),
                  ),
                ),
                _SettingsItem(
                  icon: Icons.business_outlined,
                  label: context.l10n.moreBusinessInfo,
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.people_outline,
                  label: context.l10n.moreTeam,
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.security_outlined,
                  label: context.l10n.morePermissions,
                  onTap: () {},
                ),
              ],
            ),
            // Support section
            _SettingsSection(
              title: context.l10n.moreSupportSection,
              items: [
                _SettingsItem(
                  icon: Icons.school_outlined,
                  label: context.l10n.moreReplayTutorial,
                  onTap: () =>
                      ref.read(tongtaiOnboardingProvider.notifier).reset(),
                ),
                _SettingsItem(
                  icon: Icons.help_outline,
                  label: context.l10n.moreHelp,
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.info_outlined,
                  label: context.l10n.moreAbout,
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.feedback_outlined,
                  label: context.l10n.moreSendFeedback,
                  onTap: () {},
                ),
              ],
            ),
            // Legal section
            _SettingsSection(
              title: context.l10n.moreLegalSection,
              items: [
                _SettingsItem(
                  icon: Icons.description_outlined,
                  label: context.l10n.moreTerms,
                  onTap: () {},
                ),
                _SettingsItem(
                  key: const Key('more-privacy'),
                  icon: Icons.privacy_tip_outlined,
                  label: context.l10n.morePrivacy,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TongtaiPrivacyPolicyScreen(),
                    ),
                  ),
                ),
              ],
            ),
            // Logout button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(context.l10n.moreLogout),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        ...items.map((item) => item),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6B7280)),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
      onTap: onTap,
    );
  }
}
