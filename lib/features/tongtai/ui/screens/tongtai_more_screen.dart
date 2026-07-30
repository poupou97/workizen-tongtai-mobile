import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/l10n/language_notifier.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../providers/tongtai_sample_provider.dart';
import '../../providers/tongtai_onboarding_provider.dart';
import 'tongtai_ai_key_screen.dart';
import 'tongtai_export_screen.dart';
import 'tongtai_finance_screen.dart';
import 'tongtai_goals_screen.dart';
import 'tongtai_reports_screen.dart';
import 'tongtai_timeline_screen.dart';

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
  Future<void> _seedSamples(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nạp dữ liệu mẫu?'),
        content: const Text(
          'Dữ liệu mẫu sẽ được thêm vào ứng dụng như dữ liệu bình thường — '
          'mọi màn hình (Home, Kho, Khách hàng, Báo cáo, Cơ hội…) cùng hiển '
          'thị. Bạn có thể sửa từng dòng hoặc xóa toàn bộ mẫu bất cứ lúc nào; '
          'dữ liệu bạn tự nhập không bị ảnh hưởng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            key: const Key('more-demo-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Nạp mẫu'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(sampleDataSeederProvider).seed();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Đã nạp dữ liệu mẫu — xem ở mọi màn hình.'),
        ),
      );
  }

  /// Removes ONLY the `sample-` prefixed rows — user data stays (tested).
  Future<void> _removeSamples(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa toàn bộ dữ liệu mẫu?'),
        content: const Text(
          'Chỉ các bản ghi mẫu bị xóa. Dữ liệu bạn tự nhập được giữ nguyên.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            key: const Key('more-remove-sample-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xóa mẫu'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(sampleDataSeederProvider).removeAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Đã xóa toàn bộ dữ liệu mẫu.')),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('More'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // App settings section
            _SettingsSection(
              title: 'Settings',
              items: [
                _SettingsItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.language,
                  label: context.l10n.settingsLanguage,
                  onTap: () => _pickLanguage(context, ref),
                ),
                _SettingsItem(
                  icon: Icons.dark_mode_outlined,
                  label: 'Theme',
                  onTap: () {},
                ),
              ],
            ),
            // AI Assistant section (WTM-61) — BYOK Grok (xAI) key management.
            _SettingsSection(
              title: 'AI Assistant',
              items: [
                _SettingsItem(
                  icon: Icons.auto_awesome,
                  label: 'Grok (xAI) API key',
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
              title: 'Business',
              items: [
                _SettingsItem(
                  key: const Key('more-demo-mode'),
                  icon: Icons.science_outlined,
                  label: 'Nạp dữ liệu mẫu · Load sample data',
                  onTap: () => _seedSamples(context, ref),
                ),
                _SettingsItem(
                  key: const Key('more-remove-sample'),
                  icon: Icons.delete_sweep_outlined,
                  label: 'Xóa dữ liệu mẫu · Remove sample data',
                  onTap: () => _removeSamples(context, ref),
                ),
                _SettingsItem(
                  icon: Icons.timeline_outlined,
                  label: 'Timeline · Dòng thời gian',
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const TongtaiTimelineScreen(),
                    ),
                  ),
                ),
                _SettingsItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Finance · Tài chính',
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const TongtaiFinanceScreen(),
                    ),
                  ),
                ),
                _SettingsItem(
                  icon: Icons.bar_chart_outlined,
                  label: 'Reports & Analytics · Báo cáo',
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const TongtaiReportsScreen(),
                    ),
                  ),
                ),
                _SettingsItem(
                  icon: Icons.flag_outlined,
                  label: 'Business Goals',
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const TongtaiGoalsScreen(),
                    ),
                  ),
                ),
                _SettingsItem(
                  icon: Icons.ios_share,
                  label: 'Export Data (CSV)',
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const TongtaiExportScreen(),
                    ),
                  ),
                ),
                _SettingsItem(
                  icon: Icons.business_outlined,
                  label: 'Business Info',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.people_outline,
                  label: 'Team',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.security_outlined,
                  label: 'Permissions',
                  onTap: () {},
                ),
              ],
            ),
            // Support section
            _SettingsSection(
              title: 'Support',
              items: [
                _SettingsItem(
                  icon: Icons.school_outlined,
                  label: 'Replay Tutorial',
                  onTap: () =>
                      ref.read(tongtaiOnboardingProvider.notifier).reset(),
                ),
                _SettingsItem(
                  icon: Icons.help_outline,
                  label: 'Help & Support',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.info_outlined,
                  label: 'About Tổng Tài',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.feedback_outlined,
                  label: 'Send Feedback',
                  onTap: () {},
                ),
              ],
            ),
            // Legal section
            _SettingsSection(
              title: 'Legal',
              items: [
                _SettingsItem(
                  icon: Icons.description_outlined,
                  label: 'Terms of Service',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  onTap: () {},
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
                  child: const Text('Logout'),
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
