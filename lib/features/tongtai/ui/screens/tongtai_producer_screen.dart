import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../core/screen_data_controller.dart';
import '../../core/tongtai_formatters.dart';
import '../../opportunity/opportunity.dart';
import '../../producer/supplier_favorite.dart';
import '../../producer/supplier_favorites_controller.dart';
import '../../producer/supplier_search_service.dart' show kSampleSuppliers;
import '../../providers/tongtai_context_provider.dart';
import '../../providers/tongtai_search_provider.dart';
import '../../providers/tongtai_data_invalidation.dart';
import '../widgets/tongtai_screen_data.dart';
import '../widgets/tongtai_screen_header.dart';
import 'tongtai_supplier_favorites_screen.dart';
import '../../navigation/tongtai_design_tokens.dart';

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

  /// Both sources behind this tab load together (WTM-148): if either the
  /// favourites store or the opportunity generator throws, the tab says so
  /// instead of quietly rendering the empty states it used to be made of.
  late final ScreenDataController<_ProducerData> _data;

  @override
  void initState() {
    super.initState();
    _data = ScreenDataController<_ProducerData>(
      _read,
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'producer',
    )..load();
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  Future<_ProducerData> _read() async {
    final store = ref.read(tongtaiSearchFavoritesStoreProvider);
    return (
      favorites: await store.loadAll(),
      opportunities: await ref.read(generatedOpportunitiesProvider.future),
    );
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
    await _data.refresh();
  }

  @override
  Widget build(BuildContext context) {
    // The business data can change from another screen (restore a backup, seed
    // or remove sample data). This screen is kept alive by the shell's
    // IndexedStack, so its `initState` load never runs again — without this it
    // would keep rendering a business that no longer exists (WTM-174).
    ref.listen(businessDataRevisionProvider, (_, _) => _data.refresh());
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: tongtaiScreenHeader(
        context,
        screen: 'producer',
        title: l10n.titleProducerHub,
        subtitle: tongtaiScreenSubtitle(context.l10n, 'producer'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListenableBuilder(
        listenable: _data,
        builder: (context, _) => TongtaiScreenData<_ProducerData>(
          prefix: 'producer',
          state: _data.state,
          onRetry: _data.retry,
          builder: _body,
        ),
      ),
    );
  }

  Widget _body(BuildContext context, _ProducerData data) {
    final l10n = context.l10n;
    final favorites = data.favorites;
    final opportunities = data.opportunities;
    final topOpportunities =
        (opportunities.toList()..sort(
              (a, b) => (b.score.value ?? -1).compareTo(a.score.value ?? -1),
            ))
            .take(3)
            .toList();

    return SingleChildScrollView(
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
                        opportunities.length,
                        favorites.length,
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
                        ' · ${l10n.oppScoreLabel} '
                        '${o.score.value?.round() ?? '—'}',
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
                '${favorites.length}',
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
          if (favorites.isEmpty)
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
                  for (final f in favorites)
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
    );
  }
}

/// What the Producer tab needs in one read — favourites and the rule-generated
/// opportunities, loaded together so a partial failure cannot masquerade as an
/// empty hub.
typedef _ProducerData = ({
  List<SupplierFavorite> favorites,
  List<Opportunity> opportunities,
});

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
          // The pill keeps the capability colour for its tint and border; the
          // label needs the readable twin or it sits at 2.31:1 (WTM-169).
          color: TongtaiDesignTokens.readableText(color),
        ),
      ),
    );
  }
}
