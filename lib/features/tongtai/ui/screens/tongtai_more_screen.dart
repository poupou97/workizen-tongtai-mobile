import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/tongtai_onboarding_provider.dart';
import 'tongtai_ai_key_screen.dart';
import 'tongtai_export_screen.dart';
import 'tongtai_goals_screen.dart';
import 'tongtai_reports_screen.dart';

/// More/Settings screen for Tổng Tài
/// Provides access to settings, help, and additional features.
class TongtaiMoreScreen extends ConsumerWidget {
  const TongtaiMoreScreen({super.key});

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
                  label: 'Language',
                  onTap: () {},
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
