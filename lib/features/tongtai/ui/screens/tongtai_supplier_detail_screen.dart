import 'package:flutter/material.dart';

import '../../../../core/design/tt.dart';

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
      backgroundColor: TtColors.surfaceSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TtRadius.lg)),
      ),
      builder: (_) => _MessageComposerSheet(supplierName: profile.name),
    );
    if (sent == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.supplierMessageSent(profile.name))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        title: Text(context.l10n.labelSupplier),
        elevation: 0,
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
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
                    padding: const EdgeInsets.all(TtSpace.x4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileHeader(profile: profile),
                        const SizedBox(height: TtSpace.x4),
                        _AboutSection(description: profile.description),
                        const SizedBox(height: TtSpace.x4),
                        _RatingsSection(profile: profile),
                        // ⛔ WTM-421: KHÔNG dựng lại khối "danh mục sản phẩm"
                        // và "lịch sử giao dịch" ở đây. Cả hai từng hiện những
                        // con số sinh bằng công thức từ `reviewCount` —
                        // `4 + ((reviewCount + len(category) + i*7) % 24)` và
                        // `reviewCount + 20` — mà giao diện trình bày y hệt
                        // giá bán hay tồn kho. Xem `supplier_profile.dart`.
                        const SizedBox(height: TtSpace.x4),
                        _ContactSection(
                          profile: profile,
                          onMessage: () => _openMessageSheet(context),
                        ),
                        const SizedBox(height: TtSpace.x6),
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
        const SizedBox(width: TtSpace.x4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                style: TtType.h1.copyWith(color: TtColors.textPrimary),
              ),
              const SizedBox(height: TtSpace.x1),
              Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 16,
                    color: TtColors.textSecondary,
                  ),
                  const SizedBox(width: TtSpace.x1),
                  Expanded(
                    child: Text(
                      profile.location,
                      style: TtType.body.copyWith(
                        color: TtColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TtSpace.x2),
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
        color: TtColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TtRadius.md),
      ),
      child: Text(
        initials,
        style: TtType.h2.copyWith(
          color: TtColors.successOnLight,
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
        const Icon(Icons.star, size: 18, color: TtColors.warning),
        const SizedBox(width: TtSpace.x1),
        Text(
          profile.rating.toStringAsFixed(1),
          style: TtType.body.copyWith(
            fontWeight: FontWeight.w700,
            color: TtColors.textPrimary,
          ),
        ),
        const SizedBox(width: TtSpace.x1),
        // Flexible + localized: the review count was hardcoded English and
        // pushed the header 190 px past the edge at a 2.0x font (WTM-168).
        Flexible(
          child: Text(
            context.l10n.supplierReviewCount(profile.reviewCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TtType.body.copyWith(color: TtColors.textSecondary),
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
        style: TtType.bodyLarge.copyWith(color: TtColors.textPrimary),
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
      title: context.l10n.supRatings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                profile.rating.toStringAsFixed(1),
                style: TtType.display.copyWith(color: TtColors.textPrimary),
              ),
              const SizedBox(width: TtSpace.x1),
              const Icon(Icons.star, size: 20, color: TtColors.warning),
              const SizedBox(width: TtSpace.x2),
              Flexible(
                child: Text(
                  context.l10n.supplierFromReviews(profile.reviewCount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TtType.body.copyWith(color: TtColors.textSecondary),
                ),
              ),
            ],
          ),
          // ⛔ WTM-421: huy hiệu chứng chỉ đã bị gỡ.
          //
          // `ISO 9001` được gán cho **mọi** nhà cung cấp, phần còn lại suy từ
          // danh mục sản phẩm. Đó là một tuyên bố về pháp lý và chất lượng mà
          // app không hề kiểm — nặng hơn mọi con số bịa khác trên màn, vì
          // người bán có thể nhập hàng dựa vào nó.
          //
          // Đánh giá sao ở trên thì GIỮ: nó đến từ hồ sơ nhà cung cấp được
          // nhập vào, tức có nguồn, dù nguồn ấy là bên thứ ba.
        ],
      ),
    );
  }
}

// ── Product catalog (AC2) ─────────────────────────────────────────────────────

// ── Historical transaction summary (AC5) ──────────────────────────────────────

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
            const SizedBox(height: TtSpace.x2),
            _ContactRow(
              icon: Icons.phone_outlined,
              value: profile.contactPhone!,
            ),
          ],
          const SizedBox(height: TtSpace.x4),
          SizedBox(
            width: double.infinity,
            child: TtPrimaryButton(
              key: const Key('supplier-detail-action-message'),
              label: context.l10n.supMessage,
              icon: Icons.chat_bubble_outline,
              onPressed: onMessage,
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
        Icon(icon, size: 18, color: TtColors.textSecondary),
        const SizedBox(width: TtSpace.x2),
        Expanded(
          child: Text(
            value,
            style: TtType.bodyLarge.copyWith(color: TtColors.textPrimary),
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
        TtSpace.x4,
        TtSpace.x4,
        TtSpace.x4,
        TtSpace.x4 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.supplierMessageTitle(widget.supplierName),
            style: TtType.h2.copyWith(color: TtColors.textPrimary),
          ),
          const SizedBox(height: TtSpace.x3),
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            minLines: 3,
            maxLines: 5,
            autofocus: true,
            decoration: InputDecoration(
              hintText: context.l10n.supAskHint,
              filled: true,
              fillColor: TtColors.surfaceTertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TtRadius.sm),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: TtSpace.x3),
          SizedBox(
            width: double.infinity,
            child: TtPrimaryButton(
              label: context.l10n.actionSend,
              icon: Icons.send,
              onPressed: _canSend
                  ? () => Navigator.of(context).pop(true)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
