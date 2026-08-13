import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../commerce/attributes/product_attribute_view.dart';
import '../../core/tongtai_formatters.dart';
import '../../inventory/product.dart';
import '../../inventory/product_category.dart';
import '../../providers/tongtai_commerce_provider.dart';
import '../widgets/tongtai_screen_data.dart';

/// Product Detail — read-only, grouped attribute view (WTM-335, `L3`).
///
/// The story's L3 surface: tapping a product on the Inventory list opens this
/// screen. It shows the core "Thông tin chính" section (always) and, **only
/// when the product actually has DYNAMIC attributes**, a grouped
/// "Thông số kỹ thuật" section underneath (§15). Attributes are read
/// **on demand** through [productAttributeGroupsProvider] — the single allowed
/// read path (ADR-TON-019) — never joined into the list that got the seller
/// here.
///
/// The screen exposes only **field · group · value** (§15): the
/// `AttributeDefinition`, its code, scope and the EAV shape stay behind the
/// [AttributeDisplayGroup] view model and never reach the UI.
class TongtaiProductDetailScreen extends ConsumerWidget {
  const TongtaiProductDetailScreen({
    super.key,
    required this.product,
    this.onEdit,
  });

  final Product product;

  /// Opens the Add/Edit form for this product. Optional so a test can pump the
  /// detail screen without wiring navigation.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(productAttributeGroupsProvider(product.id));
    return Scaffold(
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        title: Text(l10n.productDetailTitle),
        elevation: 0,
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
        actions: [
          if (onEdit != null)
            TextButton(
              key: const Key('product-detail-action-edit'),
              onPressed: onEdit,
              child: Text(l10n.productDetailEdit),
            ),
        ],
      ),
      body: SafeArea(
        // The seam owns this bounded area and renders loading/failed/stale for
        // the on-demand attribute read (ADR-TON-017/019). The core section is
        // rendered by [builder] alongside the grouped block, so a product with
        // no attributes still shows its key information — the empty grouped list
        // simply adds nothing (§15).
        child: TongtaiAsyncScreenData<List<AttributeDisplayGroup>>(
          prefix: 'product-detail',
          async: async,
          onRetry: () async =>
              ref.refresh(productAttributeGroupsProvider(product.id)),
          builder: (context, groups) =>
              _DetailBody(product: product, groups: groups),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.product, required this.groups});

  final Product product;
  final List<AttributeDisplayGroup> groups;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('product-detail-body'),
      padding: const EdgeInsets.all(TtSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProductHeader(product: product),
          const SizedBox(height: TtSpace.x4),
          _CoreSection(product: product),
          // §15: the grouped block appears ONLY when the product has
          // attributes. No values ⇒ no heading, no empty card.
          if (groups.isNotEmpty) ...[
            const SizedBox(height: TtSpace.x4),
            _SpecSection(groups: groups),
          ],
          const SizedBox(height: TtSpace.x6),
        ],
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('product-detail-header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: TtType.h1.copyWith(color: TtColors.textPrimary),
              ),
              const SizedBox(height: TtSpace.x1),
              Text(
                '${product.sku} • '
                '${ProductCategory.display(product.category, context.l10n.languageCode)}',
                style: TtType.body.copyWith(color: TtColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The core "Thông tin chính" section — typed columns only, always shown.
class _CoreSection extends StatelessWidget {
  const _CoreSection({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _DetailSection(
      sectionKey: const Key('product-detail-core'),
      title: l10n.productDetailCoreSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CoreRow(label: l10n.productDetailSku, value: product.sku),
          _CoreRow(
            label: l10n.productDetailCategory,
            value: product.category.isEmpty
                ? '—'
                : ProductCategory.display(product.category, l10n.languageCode),
          ),
          _CoreRow(
            label: l10n.productDetailPrice,
            value: TongtaiFormatters.vnd(product.pricePerUnit),
          ),
          // ADR-TON-023: a product with no stock concept shows no stock row —
          // "Tồn kho: 0" for a piece of software would be a lie.
          if (product.quantity case final q?)
            _CoreRow(
              label: l10n.productDetailStock,
              value: l10n.invQuantity(q),
            ),
          _CoreRow(
            label: l10n.productDetailKind,
            value: l10n.productKindName(product.kind.code),
          ),
          if (product.brand case final brand? when brand.isNotEmpty)
            _CoreRow(label: l10n.productDetailBrand, value: brand),
        ],
      ),
    );
  }
}

class _CoreRow extends StatelessWidget {
  const _CoreRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TtSpace.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TtType.body.copyWith(color: TtColors.textSecondary),
            ),
          ),
          const SizedBox(width: TtSpace.x3),
          Expanded(
            child: Text(
              value,
              style: TtType.bodyLarge.copyWith(
                color: TtColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The grouped "Thông số kỹ thuật" section (§15): each group is a heading, each
/// row a `· Label: Value unit` line. Reads only the [AttributeDisplayGroup]
/// view model — no definition, no code, no EAV.
class _SpecSection extends StatelessWidget {
  const _SpecSection({required this.groups});

  final List<AttributeDisplayGroup> groups;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      sectionKey: const Key('product-detail-attributes'),
      title: context.l10n.productDetailSpecSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final group in groups) _AttributeGroupBlock(group: group),
        ],
      ),
    );
  }
}

class _AttributeGroupBlock extends StatelessWidget {
  const _AttributeGroupBlock({required this.group});

  final AttributeDisplayGroup group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TtSpace.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.label,
            style: TtType.body.copyWith(
              color: TtColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TtSpace.x1),
          for (final row in group.rows) _AttributeRow(row: row),
        ],
      ),
    );
  }
}

class _AttributeRow extends StatelessWidget {
  const _AttributeRow({required this.row});

  final AttributeDisplayRow row;

  @override
  Widget build(BuildContext context) {
    final valueText = row.unit == null ? row.value : '${row.value} ${row.unit}';
    return Padding(
      padding: const EdgeInsets.only(bottom: TtSpace.x1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '· ',
            style: TtType.body.copyWith(color: TtColors.textSecondary),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TtType.body.copyWith(color: TtColors.textPrimary),
                children: [
                  TextSpan(
                    text: '${row.label}: ',
                    style: TtType.body.copyWith(color: TtColors.textSecondary),
                  ),
                  TextSpan(
                    text: valueText,
                    style: TtType.body.copyWith(
                      color: TtColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared card wrapper for a detail section, matching the supplier-detail idiom.
class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.child,
    this.sectionKey,
  });

  final String title;
  final Widget child;
  final Key? sectionKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: sectionKey,
      padding: const EdgeInsets.all(TtSpace.x4),
      decoration: BoxDecoration(
        color: TtColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(TtRadius.md),
        border: Border.all(color: TtColors.border),
        boxShadow: TtElevation.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TtType.h2.copyWith(color: TtColors.textPrimary)),
          const SizedBox(height: TtSpace.x3),
          child,
        ],
      ),
    );
  }
}
