import 'package:flutter/material.dart';

import '../../navigation/tongtai_design_tokens.dart';
import '../../producer/supplier.dart';
import '../../producer/supplier_favorites_controller.dart';
import '../../producer/supplier_search_service.dart';
import 'tongtai_supplier_detail_screen.dart';
import '../../../../core/l10n/app_strings.dart';

/// Favorite Suppliers screen (WTM-65) — the user's starred sourcing shortlist.
///
/// Lists every favorited supplier, ordered most-recently-added first (AC3), each
/// with a filled heart to un-favorite in one tap (AC1/AC2). Empty until the user
/// stars a supplier from the search results or a supplier detail view. Data is
/// resolved from the in-memory [SupplierSearchService] directory against the
/// ids held by the shared [SupplierFavoritesController].
class TongtaiSupplierFavoritesScreen extends StatefulWidget {
  const TongtaiSupplierFavoritesScreen({
    super.key,
    required this.favorites,
    this.service,
  });

  /// Shared favorites state (owns persistence + sync via its store).
  final SupplierFavoritesController favorites;

  /// Supplier directory used to resolve favorite ids; defaults to the built-in
  /// sample directory.
  final SupplierSearchService? service;

  @override
  State<TongtaiSupplierFavoritesScreen> createState() =>
      _TongtaiSupplierFavoritesScreenState();
}

class _TongtaiSupplierFavoritesScreenState
    extends State<TongtaiSupplierFavoritesScreen> {
  late final SupplierSearchService _service;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? SupplierSearchService.sample();
    if (!widget.favorites.isLoaded) {
      widget.favorites.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(context.l10n.titleFavoriteSuppliers),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.favorites,
          builder: (context, _) {
            final suppliers = widget.favorites.favoriteSuppliers(_service.all);
            if (suppliers.isEmpty) return const _EmptyFavorites();
            return ListView.separated(
              padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
              itemCount: suppliers.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: TongtaiDesignTokens.spacing3),
              itemBuilder: (context, index) => _FavoriteTile(
                supplier: suppliers[index],
                onRemove: () => widget.favorites.toggle(suppliers[index].id),
                onOpen: () => _openDetail(context, suppliers[index]),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, Supplier supplier) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TongtaiSupplierDetailScreen.forSupplier(supplier),
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.supplier,
    required this.onRemove,
    required this.onOpen,
  });

  final Supplier supplier;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.cardBorderRadius,
        ),
        child: Container(
          padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
          decoration: BoxDecoration(
            color: TongtaiDesignTokens.lightBackground,
            borderRadius: BorderRadius.circular(
              TongtaiDesignTokens.cardBorderRadius,
            ),
            border: Border.all(color: TongtaiDesignTokens.lightBorder),
            boxShadow: TongtaiDesignTokens.elevation1,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TongtaiDesignTokens.bodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: TongtaiDesignTokens.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: TongtaiDesignTokens.spacing1),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: TongtaiDesignTokens.lightTextSecondary,
                        ),
                        const SizedBox(width: TongtaiDesignTokens.spacing1),
                        Expanded(
                          child: Text(
                            supplier.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TongtaiDesignTokens.captionStyle.copyWith(
                              color: TongtaiDesignTokens.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TongtaiDesignTokens.spacing1),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: TongtaiDesignTokens.spacing1),
                        Text(
                          '${supplier.rating.toStringAsFixed(1)} '
                          '(${supplier.reviewCount})',
                          style: TongtaiDesignTokens.captionStyle.copyWith(
                            color: TongtaiDesignTokens.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TongtaiDesignTokens.spacing2),
              // Filled heart — one tap removes from favorites (AC1/AC2).
              IconButton(
                onPressed: onRemove,
                tooltip: context.l10n.favRemove,
                icon: const Icon(
                  Icons.favorite,
                  color: TongtaiDesignTokens.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_border,
              size: 48,
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing3),
            Text(
              context.l10n.favEmpty,
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.bodyStyle.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing1),
            Text(
              context.l10n.favEmptyHint,
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
