import 'package:flutter/material.dart';

import '../../core/tongtai_formatters.dart';
import '../../inventory/product.dart';
import '../../navigation/tongtai_design_tokens.dart';

/// Inventory Picker (WTM-126) — the only way to add an order line: the seller
/// picks a real inventory [Product] (never free text, Founder G-2). Searchable
/// by name/SKU/category; tapping a row pops the chosen product to the caller
/// (the Create Order form), which then captures quantity + sold price.
class TongtaiInventoryPickerScreen extends StatefulWidget {
  const TongtaiInventoryPickerScreen({super.key, required this.products});

  /// The inventory to choose from (the local catalog).
  final List<Product> products;

  @override
  State<TongtaiInventoryPickerScreen> createState() =>
      _TongtaiInventoryPickerScreenState();
}

class _TongtaiInventoryPickerScreenState
    extends State<TongtaiInventoryPickerScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Product> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.products;
    return widget.products
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = _filtered;
    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: const Text('Pick a product'),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search name, SKU or category',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: TongtaiDesignTokens.lightHover,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      TongtaiDesignTokens.componentBorderRadius,
                    ),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Text(
                        'No products match',
                        style: TongtaiDesignTokens.bodyStyle.copyWith(
                          color: TongtaiDesignTokens.lightTextSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TongtaiDesignTokens.spacing4,
                      ),
                      itemCount: products.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final p = products[i];
                        return ListTile(
                          key: Key('picker-product-${p.id}'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(p.name),
                          subtitle: Text(
                            '${p.sku} • ${p.category} • '
                            '${TongtaiFormatters.vnd(p.pricePerUnit)}',
                            style: TongtaiDesignTokens.captionStyle.copyWith(
                              color: TongtaiDesignTokens.lightTextSecondary,
                            ),
                          ),
                          trailing: Text(
                            p.stockStatus.labelEn,
                            style: TongtaiDesignTokens.captionStyle,
                          ),
                          onTap: () => Navigator.of(context).pop(p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
