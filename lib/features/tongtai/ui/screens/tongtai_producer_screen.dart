import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../core/tongtai_formatters.dart';
import '../../opportunity/opportunity.dart';
import '../../producer/supplier_favorite.dart';
import '../../producer/supplier_favorites_controller.dart';
import '../../producer/supplier_search_service.dart' show kSampleSuppliers;
import '../../providers/tongtai_context_provider.dart';
import '../../providers/tongtai_search_provider.dart';
import 'tongtai_supplier_favorites_screen.dart';

/// Producer/Sourcing tab for Tổng Tài (WTM-24).
///
/// P0 correction 2026-07-30: previously a static design shell that read no
/// data (same defect class as the Consumer tab — Home counted favourites
/// while this tab always showed the empty states). It now reads the SAME
/// sources Home does: the persisted favourites store and the rule-generated
/// opportunities (locked by p0/count_list_contract_test.dart).
///
/// Supplier names resolve from the curated Phase-2 catalog (kSampleSuppliers,
/// the allowlisted sourcing directory — there is no supplier repository yet).
class TongtaiProducerScreen extends ConsumerStatefulWidget {
  const TongtaiProducerScreen({super.key});

  @override
  ConsumerState<TongtaiProducerScreen> createState() =>
      _TongtaiProducerScreenState();
}

class _TongtaiProducerScreenState extends ConsumerState<TongtaiProducerScreen> {
  static const _green = Color(0xFF10B981);

  List<SupplierFavorite> _favorites = const [];
  List<Opportunity> _opportunities = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = ref.read(tongtaiSearchFavoritesStoreProvider);
    final favorites = await store.loadAll();
    final opportunities = await ref.read(generatedOpportunitiesProvider.future);
    if (!mounted) return;
    setState(() {
      _favorites = favorites;
      _opportunities = opportunities;
    });
  }

  String _supplierName(String supplierId) {
    for (final s in kSampleSuppliers) {
      if (s.id == supplierId) return s.name;
    }
    return supplierId;
  }

  Future<void> _openFavorites() async {
    final controller = SupplierFavoritesController(
      ref.read(tongtaiSearchFavoritesStoreProvider),
    );
    await controller.load();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TongtaiSupplierFavoritesScreen(favorites: controller),
      ),
    );
    controller.dispose();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final topOpportunities =
        (_opportunities.toList()
              ..sort((a, b) => b.aiScore.compareTo(a.aiScore)))
            .take(3)
            .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.titleProducerHub),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card — deterministic counts from the same sources Home
            // reads (zero is valid business data, WTM-128).
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
                      l10n.producerAiSummary,
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
                        border: Border.all(color: _green),
                      ),
                      child: Text(
                        l10n.producerSummaryLine(
                          _opportunities.length,
                          _favorites.length,
                        ),
                        key: const Key('producer-summary-line'),
                        style: const TextStyle(fontSize: 14, color: _green),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // AI Capabilities — static feature descriptions (chrome).
            Text(
              l10n.producerAiCapabilities,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CapabilityPill(label: l10n.producerCapScoring, color: _green),
                _CapabilityPill(label: l10n.producerCapRanking, color: _green),
                _CapabilityPill(label: l10n.producerCapTrends, color: _green),
                _CapabilityPill(label: l10n.producerCapPrice, color: _green),
                _CapabilityPill(label: l10n.producerCapQuality, color: _green),
                _CapabilityPill(label: l10n.producerCapDelivery, color: _green),
              ],
            ),
            const SizedBox(height: 24),
            // Opportunities — the SAME rule-generated list the feed and Home
            // read, top 3 by score.
            Text(
              l10n.producerRecentOpps,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (topOpportunities.isEmpty)
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text(l10n.producerEmptyOpps)),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    for (final o in topOpportunities)
                      ListTile(
                        dense: true,
                        title: Text(o.title),
                        subtitle: Text(
                          '+${TongtaiFormatters.vnd(o.expectedImpact)}'
                          ' · ${l10n.oppScoreLabel} ${o.aiScore.round()}',
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            // Suppliers — the persisted favourites Home's Producer tile
            // counts; names from the curated catalog.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.producerVerifiedSuppliers,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '${_favorites.length}',
                  key: const Key('producer-fav-count'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_favorites.isEmpty)
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text(l10n.producerEmptySuppliers)),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    for (final f in _favorites)
                      ListTile(
                        dense: true,
                        title: Text(_supplierName(f.supplierId)),
                        trailing: const Icon(
                          Icons.favorite,
                          size: 16,
                          color: _green,
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const Key('producer-view-favorites'),
                        onPressed: _openFavorites,
                        child: Text(l10n.actionViewAll),
                      ),
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
