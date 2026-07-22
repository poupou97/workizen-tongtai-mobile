import 'package:flutter/material.dart';

/// Producer/Sourcing screen for Tổng Tài
/// Shows supplier network, opportunities, and AI capability pills.
class TongtaiProducerScreen extends StatelessWidget {
  const TongtaiProducerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Producer Hub'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Summary card
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
                      'AI Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF10B981)),
                      ),
                      child: const Text(
                        'Analyzing supplier opportunities and market trends...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // AI Capabilities section
            Text(
              'AI Capabilities',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CapabilityPill(
                  label: 'Opportunity Scoring',
                  color: Color(0xFF10B981),
                ),
                _CapabilityPill(
                  label: 'Supplier Ranking',
                  color: Color(0xFF10B981),
                ),
                _CapabilityPill(
                  label: 'Market Trends',
                  color: Color(0xFF10B981),
                ),
                _CapabilityPill(
                  label: 'Price Analysis',
                  color: Color(0xFF10B981),
                ),
                _CapabilityPill(
                  label: 'Quality Rating',
                  color: Color(0xFF10B981),
                ),
                _CapabilityPill(
                  label: 'Delivery Time',
                  color: Color(0xFF10B981),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Opportunities section
            Text(
              'Recent Opportunities',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('No opportunities discovered yet'),
              ),
            ),
            const SizedBox(height: 24),
            // Suppliers section
            Text(
              'Verified Suppliers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('No suppliers connected yet')),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapabilityPill extends StatelessWidget {
  final String label;
  final Color color;

  const _CapabilityPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
