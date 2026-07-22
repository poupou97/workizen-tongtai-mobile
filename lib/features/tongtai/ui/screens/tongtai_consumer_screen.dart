import 'package:flutter/material.dart';

/// Consumer/Customer Intelligence screen for Tổng Tài
/// Manages customer relationships and CDP (Customer Data Platform).
class TongtaiConsumerScreen extends StatelessWidget {
  const TongtaiConsumerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Customer Intelligence'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card with customer count badge
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Customers',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '0',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _CustomerStat(
                          label: 'Active',
                          value: '0',
                          color: const Color(0xFF3B82F6),
                        ),
                        _CustomerStat(
                          label: 'VIP',
                          value: '0',
                          color: const Color(0xFF3B82F6),
                        ),
                        _CustomerStat(
                          label: 'New',
                          value: '0',
                          color: const Color(0xFF3B82F6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Customer segments
            Text(
              'Customer Segments',
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
                child: Text('No customer segments defined yet'),
              ),
            ),
            const SizedBox(height: 24),
            // Recent interactions
            Text(
              'Recent Interactions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('No recent interactions')),
            ),
            const SizedBox(height: 24),
            // Customer lifecycle
            Text(
              'Customer Lifecycle',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LifecycleStage(
                    stage: 'Awareness',
                    count: '0',
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 12),
                  _LifecycleStage(
                    stage: 'Consideration',
                    count: '0',
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 12),
                  _LifecycleStage(
                    stage: 'Purchase',
                    count: '0',
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 12),
                  _LifecycleStage(
                    stage: 'Retention',
                    count: '0',
                    color: const Color(0xFF3B82F6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CustomerStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _LifecycleStage extends StatelessWidget {
  final String stage;
  final String count;
  final Color color;

  const _LifecycleStage({
    required this.stage,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(stage, style: const TextStyle(fontSize: 14)),
        Text(
          count,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
