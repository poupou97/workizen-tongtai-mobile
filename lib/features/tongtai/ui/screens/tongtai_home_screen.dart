import 'package:flutter/material.dart';

import 'tongtai_chat_screen.dart';
import 'tongtai_opportunity_feed_screen.dart';
import 'tongtai_unified_search_screen.dart';

/// Home dashboard screen for Tổng Tài
/// Shows business summary, AI recommendations, and module quick access.
class TongtaiHomeScreen extends StatelessWidget {
  const TongtaiHomeScreen({super.key});

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TongtaiUnifiedSearchRoute()),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TongtaiChatScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Home Dashboard'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => _openSearch(context),
          ),
          IconButton(
            key: const Key('home-open-chat'),
            tooltip: 'Workizen AI chat',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => _openChat(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to Tổng Tài',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your AI-powered business assistant for sourcing, inventory, customers, and more.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 16),
                    // Module summary cards
                    _ModuleSummaryGrid(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Placeholder for missions section
            Text(
              'Today\'s Missions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('No missions yet')),
            ),
            const SizedBox(height: 24),
            // Opportunities section — the feed lives in its own screen (WTM-91).
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Top Opportunities',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  key: const Key('home-open-opportunities'),
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const TongtaiOpportunityFeedScreen(),
                    ),
                  ),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('No opportunities available')),
            ),
            const SizedBox(height: 24),
            // Placeholder for KPIs section
            Text(
              'Business KPIs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('KPI metrics will appear here')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleSummaryGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _ModuleCard(
          title: 'Producer',
          count: '0',
          color: const Color(0xFF10B981),
        ),
        _ModuleCard(
          title: 'Inventory',
          count: '0',
          color: const Color(0xFFF59E0B),
        ),
        _ModuleCard(
          title: 'Consumer',
          count: '0',
          color: const Color(0xFF3B82F6),
        ),
        _ModuleCard(
          title: 'Journey',
          count: '0',
          color: const Color(0xFFFBBF24),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;

  const _ModuleCard({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
