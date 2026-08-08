import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../../../core/l10n/language_notifier.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../core/screen_data_controller.dart';
import '../../providers/tongtai_data_invalidation.dart';
import '../widgets/tongtai_screen_data.dart';
import '../../providers/tongtai_agentic_provider.dart';
import '../../providers/tongtai_sample_provider.dart';
import '../../sample/historical_data_generator.dart';
import '../../providers/tongtai_onboarding_provider.dart';
import 'tongtai_ai_key_screen.dart';
import 'tongtai_customer_risk_screen.dart';
import 'tongtai_business_profile_screen.dart';
import 'tongtai_feedback_screen.dart';
import 'tongtai_backup_screen.dart';
import 'tongtai_export_screen.dart';
import 'tongtai_finance_screen.dart';
import 'tongtai_forecast_screen.dart';
import 'tongtai_goals_screen.dart';
import 'tongtai_reports_screen.dart';
import 'tongtai_agent_screen.dart';
import 'tongtai_autonomy_screen.dart';
import 'tongtai_timeline_screen.dart';
import 'tongtai_privacy_policy_screen.dart';
import 'tongtai_about_screen.dart';

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

  /// **Đặt lại dữ liệu mẫu** (WTM-307 · Task Order §14) — một thao tác, không
  /// phải gỡ cài đặt app.
  ///
  /// Khác "Xem thử Demo" ở chỗ nó cũng dọn **quyết định** đã ra cho dữ liệu
  /// mẫu. Gieo lại mà giữ quyết định thì lần thử thứ hai mở ra với *"bạn đã bỏ
  /// qua việc này"*, và Founder không bao giờ xem lại được flow từ đầu.
  Future<void> _resetDemo(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.moreResetDemoConfirmTitle),
        content: Text(dialogContext.l10n.moreResetDemoConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('more-reset-demo-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.l10n.moreResetDemo),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    var removed = 0;
    final failure = await runTongtaiAction(
      () async => removed =
          (await ref.read(demoResetServiceProvider).reset()).decisions,
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'more',
    );
    if (!context.mounted) return;
    if (failure != null) {
      showTongtaiFailure(
        context,
        failure,
        onRetry: () => _resetDemo(context, ref),
      );
      return;
    }
    invalidateBusinessDataProviders(ref);
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.moreResetDemoSnack(removed))));
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
      // Stable test ID on the scroller so `tapByKey` can reach rows below the
      // fold without the silent tap-miss (TESTING-BIBLE P-21).
      body: SingleChildScrollView(
        key: const Key('more-scroll'),
        child: Column(
          children: [
            // App settings section
            _SettingsSection(
              title: context.l10n.moreSettings,
              items: [
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  label: context.l10n.moreNotifications,
                  comingSoon: true,
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
                  comingSoon: true,
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
                // Màn Tổng Tài (WTM-304) — nơi ở của agent. Cũng tới được
                // từ thẻ brief trên Home; ở đây là lối thứ hai, cho lúc thẻ
                // trống vì hôm nay không có việc nào.
                _SettingsItem(
                  key: const Key('more-agent'),
                  icon: Icons.auto_awesome_outlined,
                  label: context.l10n.titleAgent,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const TongtaiAgentScreen(),
                    ),
                  ),
                ),
                _SettingsItem(
                  key: const Key('more-reset-demo'),
                  icon: Icons.restart_alt,
                  label: context.l10n.moreResetDemo,
                  onTap: () => _resetDemo(context, ref),
                ),
                _SettingsItem(
                  key: const Key('more-autonomy'),
                  icon: Icons.tune,
                  label: context.l10n.titleAutonomy,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const TongtaiAutonomyScreen(),
                    ),
                  ),
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
                  key: const Key('more-business-profile'),
                  label: context.l10n.moreBusinessInfo,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TongtaiBusinessProfileScreen(),
                    ),
                  ),
                ),
              ],
            ),
            // Support section
            _SettingsSection(
              title: context.l10n.moreSupportSection,
              items: [
                _SettingsItem(
                  key: const Key('more-replay-tutorial'),
                  icon: Icons.school_outlined,
                  label: context.l10n.moreReplayTutorial,
                  // Close More first (WTM-192). It used to be a tab, so
                  // resetting swapped the shell's content underneath. Now it is
                  // a pushed route: without popping, the tutorial replays
                  // **behind** this screen and the seller sees nothing happen.
                  onTap: () {
                    final navigator = Navigator.of(context);
                    ref.read(tongtaiOnboardingProvider.notifier).reset();
                    if (navigator.canPop()) navigator.pop();
                  },
                ),
                _SettingsItem(
                  icon: Icons.help_outline,
                  label: context.l10n.moreHelp,
                  comingSoon: true,
                ),
                _SettingsItem(
                  icon: Icons.info_outlined,
                  key: const Key('more-about'),
                  label: context.l10n.moreAbout,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TongtaiAboutScreen(),
                    ),
                  ),
                ),
                _SettingsItem(
                  icon: Icons.feedback_outlined,
                  key: const Key('more-feedback'),
                  label: context.l10n.moreSendFeedback,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TongtaiFeedbackScreen(),
                    ),
                  ),
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
                  comingSoon: true,
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
            // No "Log out" button: there is no account to log out of (D-4 —
            // no account required). It did nothing, and offering it implied a
            // sign-in this product deliberately does not have. Removed rather
            // than greyed out, because it is not a missing feature (WTM-170).
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
  final VoidCallback? onTap;

  /// A row on the roadmap but not built. It renders visibly inert with a
  /// "coming soon" note instead of looking tappable and doing nothing — which
  /// is what eleven of these rows did until WTM-170.
  final bool comingSoon;

  const _SettingsItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.comingSoon = false,
  }) : assert(
         comingSoon || onTap != null,
         'A row that is neither tappable nor marked coming-soon is a dead '
         'control: it looks interactive and answers nothing.',
       );

  @override
  Widget build(BuildContext context) {
    final muted = TongtaiDesignTokens.lightTextSecondary;
    return ListTile(
      enabled: !comingSoon,
      leading: Icon(icon, color: muted),
      title: Text(label),
      trailing: comingSoon
          ? Text(
              context.l10n.settingsComingSoon,
              style: TongtaiDesignTokens.captionStyle.copyWith(color: muted),
            )
          : const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
      onTap: comingSoon ? null : onTap,
    );
  }
}
