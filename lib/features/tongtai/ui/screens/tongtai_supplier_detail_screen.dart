import 'package:flutter/material.dart';

import '../../core/tongtai_formatters.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../producer/supplier.dart';
import '../../producer/supplier_profile.dart';
import '../../../../core/l10n/app_strings.dart';

/// Content width to use for the detail view given the available [width].
///
/// Pulled out as a pure function so the responsive behaviour is directly
/// unit-testable: phones use the full width, while wide tablets/landscape cap
/// the reading column so the profile does not stretch edge-to-edge.
double supplierDetailContentWidth(double width) => width > 720 ? 680 : width;

/// Supplier Detail View (WTM-64) — Producer/Sourcing Hub.
///
/// Presents a comprehensive supplier profile: business profile (name, logo,
/// description), product catalog with category breakdown, rating/reviews and
/// certification badges, historical transaction summary, and contact details
/// with an in-app messaging entry point. All data comes from an in-memory
/// [SupplierProfile] (local-first, no backend — ADR-002).
class TongtaiSupplierDetailScreen extends StatelessWidget {
  const TongtaiSupplierDetailScreen({super.key, required this.profile});

  /// Convenience: build the screen straight from a base [Supplier].
  TongtaiSupplierDetailScreen.forSupplier(Supplier supplier, {Key? key})
    : this(key: key, profile: buildSupplierProfile(supplier));

  final SupplierProfile profile;

  Future<void> _openMessageSheet(BuildContext context) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TongtaiDesignTokens.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TongtaiDesignTokens.radiusXl),
        ),
      ),
      builder: (_) => _MessageComposerSheet(supplierName: profile.name),
    );
    if (sent == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message sent to ${profile.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(context.l10n.labelSupplier),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = supplierDetailContentWidth(constraints.maxWidth);
            return SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: width,
                  child: Padding(
                    padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileHeader(profile: profile),
                        const SizedBox(height: TongtaiDesignTokens.spacing4),
                        _AboutSection(description: profile.description),
                        const SizedBox(height: TongtaiDesignTokens.spacing4),
                        _RatingsSection(profile: profile),
                        const SizedBox(height: TongtaiDesignTokens.spacing4),
                        _CatalogSection(profile: profile),
                        const SizedBox(height: TongtaiDesignTokens.spacing4),
                        _TransactionsSection(summary: profile.transactions),
                        const SizedBox(height: TongtaiDesignTokens.spacing4),
                        _ContactSection(
                          profile: profile,
                          onMessage: () => _openMessageSheet(context),
                        ),
                        const SizedBox(height: TongtaiDesignTokens.spacing6),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Business profile header (AC1) ─────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final SupplierProfile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('supplier-detail-header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LogoMonogram(initials: profile.initials),
        const SizedBox(width: TongtaiDesignTokens.spacing4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                style: TongtaiDesignTokens.heading2Style.copyWith(
                  color: TongtaiDesignTokens.lightTextPrimary,
                ),
              ),
              const SizedBox(height: TongtaiDesignTokens.spacing1),
              Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 16,
                    color: TongtaiDesignTokens.lightTextSecondary,
                  ),
                  const SizedBox(width: TongtaiDesignTokens.spacing1),
                  Expanded(
                    child: Text(
                      profile.location,
                      style: TongtaiDesignTokens.smallStyle.copyWith(
                        color: TongtaiDesignTokens.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TongtaiDesignTokens.spacing2),
              _RatingRow(profile: profile),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogoMonogram extends StatelessWidget {
  const _LogoMonogram({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: TongtaiDesignTokens.producerGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusLg),
      ),
      child: Text(
        initials,
        style: TongtaiDesignTokens.heading3Style.copyWith(
          color: TongtaiDesignTokens.producerGreenText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.profile});

  final SupplierProfile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star, size: 18, color: Color(0xFFF59E0B)),
        const SizedBox(width: TongtaiDesignTokens.spacing1),
        Text(
          profile.rating.toStringAsFixed(1),
          style: TongtaiDesignTokens.smallStyle.copyWith(
            fontWeight: FontWeight.w700,
            color: TongtaiDesignTokens.lightTextPrimary,
          ),
        ),
        const SizedBox(width: TongtaiDesignTokens.spacing1),
        // Flexible + localized: the review count was hardcoded English and
        // pushed the header 190 px past the edge at a 2.0x font (WTM-168).
        Flexible(
          child: Text(
            context.l10n.supplierReviewCount(profile.reviewCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TongtaiDesignTokens.smallStyle.copyWith(
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── About / description (AC1) ─────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: context.l10n.supAbout,
      child: Text(
        description,
        style: TongtaiDesignTokens.bodyStyle.copyWith(
          color: TongtaiDesignTokens.lightTextPrimary,
        ),
      ),
    );
  }
}

// ── Ratings & certifications (AC3) ────────────────────────────────────────────

class _RatingsSection extends StatelessWidget {
  const _RatingsSection({required this.profile});

  final SupplierProfile profile;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      sectionKey: const Key('supplier-detail-ratings'),
      title: context.l10n.supRatingsCerts,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                profile.rating.toStringAsFixed(1),
                style: TongtaiDesignTokens.heading1Style.copyWith(
                  color: TongtaiDesignTokens.lightTextPrimary,
                ),
              ),
              const SizedBox(width: TongtaiDesignTokens.spacing1),
              const Icon(Icons.star, size: 20, color: Color(0xFFF59E0B)),
              const SizedBox(width: TongtaiDesignTokens.spacing2),
              Flexible(
                child: Text(
                  context.l10n.supplierFromReviews(profile.reviewCount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TongtaiDesignTokens.smallStyle.copyWith(
                    color: TongtaiDesignTokens.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          Wrap(
            spacing: TongtaiDesignTokens.spacing2,
            runSpacing: TongtaiDesignTokens.spacing2,
            children: [
              for (final cert in profile.certifications)
                _CertificationBadge(label: cert),
            ],
          ),
        ],
      ),
    );
  }
}

class _CertificationBadge extends StatelessWidget {
  const _CertificationBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TongtaiDesignTokens.spacing3,
        vertical: TongtaiDesignTokens.spacing1,
      ),
      decoration: BoxDecoration(
        color: TongtaiDesignTokens.producerGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusFull),
        border: Border.all(
          color: TongtaiDesignTokens.producerGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_outlined,
            size: 14,
            color: TongtaiDesignTokens.producerGreenText,
          ),
          const SizedBox(width: TongtaiDesignTokens.spacing1),
          Text(
            label,
            style: TongtaiDesignTokens.captionStyle.copyWith(
              color: TongtaiDesignTokens.producerGreenText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product catalog (AC2) ─────────────────────────────────────────────────────

class _CatalogSection extends StatelessWidget {
  const _CatalogSection({required this.profile});

  final SupplierProfile profile;

  @override
  Widget build(BuildContext context) {
    final categoryCount = profile.catalog.length;
    return _DetailSection(
      sectionKey: const Key('supplier-detail-catalog'),
      title: context.l10n.supProductCatalog,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${profile.productCount} products across '
            '$categoryCount ${categoryCount == 1 ? 'category' : 'categories'}',
            style: TongtaiDesignTokens.smallStyle.copyWith(
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          for (final row in profile.catalog)
            Padding(
              padding: const EdgeInsets.only(
                bottom: TongtaiDesignTokens.spacing2,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.category_outlined,
                    size: 16,
                    color: TongtaiDesignTokens.producerGreenText,
                  ),
                  const SizedBox(width: TongtaiDesignTokens.spacing2),
                  Expanded(
                    child: Text(
                      row.category,
                      style: TongtaiDesignTokens.bodyStyle.copyWith(
                        color: TongtaiDesignTokens.lightTextPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${row.count} products',
                    style: TongtaiDesignTokens.smallStyle.copyWith(
                      color: TongtaiDesignTokens.lightTextSecondary,
                      fontWeight: FontWeight.w600,
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

// ── Historical transaction summary (AC5) ──────────────────────────────────────

class _TransactionsSection extends StatelessWidget {
  const _TransactionsSection({required this.summary});

  final SupplierTransactionSummary summary;

  @override
  Widget build(BuildContext context) {
    final repeatPercent = (summary.repeatBuyerRate * 100).round();
    return _DetailSection(
      sectionKey: const Key('supplier-detail-transactions'),
      title: context.l10n.supTransactionHistory,
      child: Wrap(
        spacing: TongtaiDesignTokens.spacing3,
        runSpacing: TongtaiDesignTokens.spacing3,
        children: [
          _MetricTile(
            icon: Icons.inventory_2_outlined,
            label: context.l10n.supTotalVolume,
            value:
                '${TongtaiFormatters.compact(summary.totalVolumeUnits)} units',
          ),
          _MetricTile(
            icon: Icons.repeat,
            label: context.l10n.supTotalOrders,
            value: '${summary.totalOrders}',
          ),
          _MetricTile(
            icon: Icons.local_shipping_outlined,
            label: context.l10n.kpiAovShort,
            value:
                '${TongtaiFormatters.compact(summary.averageOrderVolume.round())} units',
          ),
          _MetricTile(
            icon: Icons.people_alt_outlined,
            label: context.l10n.supRepeatBuyers,
            value: '$repeatPercent%',
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
      decoration: BoxDecoration(
        color: TongtaiDesignTokens.lightHover,
        borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: TongtaiDesignTokens.producerGreen),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          Text(
            value,
            style: TongtaiDesignTokens.heading3Style.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing1),
          Text(
            label,
            style: TongtaiDesignTokens.captionStyle.copyWith(
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contact + messaging (AC4) ─────────────────────────────────────────────────

class _ContactSection extends StatelessWidget {
  const _ContactSection({required this.profile, required this.onMessage});

  final SupplierProfile profile;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: context.l10n.supContact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.contactEmail != null)
            _ContactRow(
              icon: Icons.email_outlined,
              value: profile.contactEmail!,
            ),
          if (profile.contactPhone != null) ...[
            const SizedBox(height: TongtaiDesignTokens.spacing2),
            _ContactRow(
              icon: Icons.phone_outlined,
              value: profile.contactPhone!,
            ),
          ],
          const SizedBox(height: TongtaiDesignTokens.spacing4),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('supplier-detail-action-message'),
              style: FilledButton.styleFrom(
                backgroundColor: TongtaiDesignTokens.producerGreenText,
                minimumSize: const Size.fromHeight(
                  TongtaiDesignTokens.buttonHeight,
                ),
              ),
              onPressed: onMessage,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: Text(context.l10n.supMessage),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: TongtaiDesignTokens.lightTextSecondary),
        const SizedBox(width: TongtaiDesignTokens.spacing2),
        Expanded(
          child: Text(
            value,
            style: TongtaiDesignTokens.bodyStyle.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reusable section wrapper ──────────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.child,
    this.sectionKey,
  });

  final String title;
  final Widget child;

  /// Stable test id (`supplier-detail-*`) supplied by the section that owns
  /// this wrapper; the wrapper itself is shared by every detail section.
  final Key? sectionKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: sectionKey,
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      decoration: BoxDecoration(
        color: TongtaiDesignTokens.lightBackground,
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.cardBorderRadius,
        ),
        border: Border.all(color: TongtaiDesignTokens.lightBorder),
        boxShadow: TongtaiDesignTokens.elevation1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TongtaiDesignTokens.heading3Style.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          child,
        ],
      ),
    );
  }
}

// ── Message composer bottom sheet (AC4 — messaging capability) ────────────────

class _MessageComposerSheet extends StatefulWidget {
  const _MessageComposerSheet({required this.supplierName});

  final String supplierName;

  @override
  State<_MessageComposerSheet> createState() => _MessageComposerSheetState();
}

class _MessageComposerSheetState extends State<_MessageComposerSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSend => _controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // Sit above the keyboard when it opens.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        TongtaiDesignTokens.spacing4,
        TongtaiDesignTokens.spacing4,
        TongtaiDesignTokens.spacing4,
        TongtaiDesignTokens.spacing4 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Message ${widget.supplierName}',
            style: TongtaiDesignTokens.heading3Style.copyWith(
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            minLines: 3,
            maxLines: 5,
            autofocus: true,
            decoration: InputDecoration(
              hintText: context.l10n.supAskHint,
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
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: TongtaiDesignTokens.producerGreenText,
                minimumSize: const Size.fromHeight(
                  TongtaiDesignTokens.buttonHeight,
                ),
              ),
              onPressed: _canSend
                  ? () => Navigator.of(context).pop(true)
                  : null,
              icon: const Icon(Icons.send, size: 18),
              label: Text(context.l10n.actionSend),
            ),
          ),
        ],
      ),
    );
  }
}
