import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';

/// Producer/Sourcing screen for Tổng Tài
/// Shows supplier network, opportunities, and AI capability pills.
class TongtaiProducerScreen extends StatelessWidget {
  const TongtaiProducerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.l10n.titleProducerHub),
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
                    Text(
                      context.l10n.producerAiSummary,
                      style: const TextStyle(
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
                      child: Text(
                        context.l10n.producerAnalyzing,
                        style: const TextStyle(
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
              context.l10n.producerAiCapabilities,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CapabilityPill(
                  label: context.l10n.producerCapScoring,
                  color: const Color(0xFF10B981),
                ),
                _CapabilityPill(
                  label: context.l10n.producerCapRanking,
                  color: const Color(0xFF10B981),
                ),
                _CapabilityPill(
                  label: context.l10n.producerCapTrends,
                  color: const Color(0xFF10B981),
                ),
                _CapabilityPill(
                  label: context.l10n.producerCapPrice,
                  color: const Color(0xFF10B981),
                ),
                _CapabilityPill(
                  label: context.l10n.producerCapQuality,
                  color: const Color(0xFF10B981),
                ),
                _CapabilityPill(
                  label: context.l10n.producerCapDelivery,
                  color: const Color(0xFF10B981),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Opportunities section
            Text(
              context.l10n.producerRecentOpps,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text(context.l10n.producerEmptyOpps)),
            ),
            const SizedBox(height: 24),
            // Suppliers section
            Text(
              context.l10n.producerVerifiedSuppliers,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text(context.l10n.producerEmptySuppliers)),
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
