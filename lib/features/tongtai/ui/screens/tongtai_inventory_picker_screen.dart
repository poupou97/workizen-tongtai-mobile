import 'package:flutter/material.dart';

import '../../../../core/design/tt.dart';

import '../../core/tongtai_formatters.dart';
import '../../inventory/product.dart';
import '../../inventory/product_category.dart';
import '../../../../core/l10n/app_strings.dart';

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
              p.category.toLowerCase().contains(q) ||
              ProductCategory.display(
                p.category,
                'vi',
              ).toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = _filtered;
    return Scaffold(
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        title: Text(context.l10n.pickerTitle),
        elevation: 0,
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(TtSpace.x4),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: context.l10n.pickerSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: TtColors.surfaceTertiary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TtRadius.sm),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n.pickerNoMatch,
                        style: TtType.bodyLarge.copyWith(
                          color: TtColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TtSpace.x4,
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
                            '${p.sku} • '
                            '${ProductCategory.display(p.category, context.l10n.languageCode)} • '
                            '${TongtaiFormatters.vnd(p.pricePerUnit)}',
                            style: TtType.caption.copyWith(
                              color: TtColors.textSecondary,
                            ),
                          ),
                          // Không có tồn kho ⇒ không có nhãn trạng thái kho.
                          trailing: p.stockStatus == null
                              ? null
                              : Text(
                                  p.stockStatus!.label(
                                    context.l10n.languageCode,
                                  ),
                                  style: TtType.caption,
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
