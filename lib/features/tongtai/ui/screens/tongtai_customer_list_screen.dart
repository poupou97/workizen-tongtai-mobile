import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';

import '../../consumer/customer.dart';
import '../../consumer/customer_directory_controller.dart';
import '../../consumer/customer_directory_service.dart';
import '../../consumer/customer_order_history_service.dart';
import '../../core/screen_data_controller.dart';
import '../../core/tongtai_formatters.dart';
import '../../inventory/product.dart';
import '../../orders/order_controller.dart';
import '../../providers/tongtai_consumer_provider.dart';
import '../../providers/tongtai_inventory_provider.dart';
import '../../providers/tongtai_orders_provider.dart';
import '../widgets/tongtai_fox_mascot.dart';
import '../widgets/tongtai_screen_data.dart';
import 'tongtai_customer_form_screen.dart';
import 'tongtai_customer_history_screen.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../providers/tongtai_data_invalidation.dart';
import '../../opportunity/opportunity.dart';
import '../../opportunity/opportunity_for.dart';
import '../../providers/tongtai_context_provider.dart';
import 'tongtai_opportunity_detail_screen.dart';

/// Color for a [CustomerTier] badge (WTM-75 AC: visual indicators for VIP /
/// high-value customers). Pulled out as a pure function so the mapping is
/// directly unit-testable without pumping a widget.
/// ⚠️ **Vàng và đồng KHÔNG chuyển sang Design System.** Chúng là tên **kim
/// loại** — một thang hạng khách quen thuộc — chứ không phải một mức ngữ nghĩa.
/// Ép `vip` thành `warning` sẽ biến "khách quý nhất" thành "khách cần chú ý".
Color tongtaiCustomerTierColor(CustomerTier tier) => switch (tier) {
  CustomerTier.vip => const Color(0xFFD4AF37), // gold
  CustomerTier.gold => TtColors.warning, // amber
  // ⭐ WTM-431 — bạc là **hằng kim loại**, không phải vai ngữ nghĩa.
  //
  // Ba hạng kia viết thẳng mã màu kim loại; riêng bạc mượn `TtColors.unknown`.
  // Một khái niệm, hai chủ (P-27): đổi màu "chưa biết" ở Design System sẽ lặng
  // lẽ đổi màu hạng Bạc, mà hai thứ ấy chẳng liên quan gì nhau.
  //
  // Và `neutral` cũng KHÔNG đúng: bạc không nói "không phán xét", nó nói
  // **bạc**. `#A8A9AD` là sắc bạc thật, cùng họ với vàng/đồng ở trên dưới.
  CustomerTier.silver => const Color(0xFFA8A9AD), // silver
  CustomerTier.bronze => const Color(0xFFB45309), // bronze
};

/// Customer list screen (WTM-75) — Customer Intelligence / CRM hub.
///
/// Local-first customer directory: a searchable, location-filterable, sortable
/// customer list with VIP/high-value tier badges and 20-per-page pagination.
/// Tapping a row opens the customer in the Add/Edit form; the FAB adds a new
/// one (WTM-76). Data is loaded through the [CustomerDirectoryController] from a
/// [CustomerRepository] (WTM-123 — Drift-backed for the real app, empty for a
/// new user); once hydrated, filtering, sorting and paging happen synchronously.
class TongtaiCustomerListScreen extends ConsumerStatefulWidget {
  const TongtaiCustomerListScreen({
    super.key,
    this.service,
    this.directory,
    this.orderHistory,
  });

  /// Injectable read-only seed for tests; when [directory] is omitted an
  /// in-memory controller is created from this (empty when both are null).
  final CustomerDirectoryService? service;

  /// Injectable mutable directory (WTM-76). When provided it takes precedence
  /// over [service] and is *not* disposed here (its owner disposes it).
  final CustomerDirectoryController? directory;

  /// Injectable purchase-history source (WTM-77); defaults to the built-in
  /// sample orders.
  final CustomerOrderHistoryService? orderHistory;

  @override
  ConsumerState<TongtaiCustomerListScreen> createState() =>
      _TongtaiCustomerListScreenState();
}

class _TongtaiCustomerListScreenState
    extends ConsumerState<TongtaiCustomerListScreen> {
  late final CustomerDirectoryController _directory;
  late final bool _ownsDirectory;
  final TextEditingController _searchController = TextEditingController();

  /// Real order source + inventory for the Create Order flow (WTM-126), wired
  /// only in the real-app path so purchase history can create + show real
  /// orders. Null in test/injected modes (history stays read-only there).
  OrderController? _orders;

  /// Directory hydration + the product catalogue behind Create Order, as one
  /// visible unit (WTM-148). This screen is the one the Founder repro landed
  /// on: an unreadable customer table must never look like an empty address
  /// book again.
  late final ScreenDataController<List<Product>> _data;

  List<Product> get _products => _data.state.value ?? const [];

  CustomerQuery _query = const CustomerQuery();

  @override
  void initState() {
    super.initState();
    if (widget.directory != null) {
      _directory = widget.directory!;
      _ownsDirectory = false;
    } else if (widget.service != null) {
      // Test seed: an in-memory directory over the supplied customers.
      _directory = CustomerDirectoryController.inMemory(widget.service!.all);
      _ownsDirectory = true;
    } else {
      // Real app: persistent Drift directory (WTM-123), empty for new users.
      _directory = CustomerDirectoryController(
        ref.read(customerRepositoryProvider),
        // WTM-201: counters derived from real orders, not the stored fields.
        orders: ref.read(orderRepositoryProvider),
      );
      _ownsDirectory = true;
      // Real order source for Create Order (WTM-126).
      _orders = OrderController(ref.read(orderRepositoryProvider));
    }
    _data = ScreenDataController<List<Product>>(
      _read,
      // Injected directory/service ⇒ test mode, where Create Order is not
      // wired and there is no product catalogue to wait for.
      initialValue: _orders == null ? const <Product>[] : null,
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'customer',
    )..start();
  }

  Future<List<Product>> _read() async {
    if (_ownsDirectory) await _directory.hydrate();
    final orders = _orders;
    if (orders == null) return const [];
    await orders.hydrate();
    return ref.read(productRepositoryProvider).loadAll();
  }

  @override
  void dispose() {
    _data.dispose();
    _searchController.dispose();
    _orders?.dispose();
    if (_ownsDirectory) _directory.dispose();
    super.dispose();
  }

  /// Open the Add/Edit form (WTM-76). [customer] null = add; non-null = edit.
  /// On save the returned customer is upserted and the list snaps to page 1.
  Future<void> _openForm(BuildContext context, {Customer? customer}) async {
    final result = await Navigator.of(context).push<Customer>(
      MaterialPageRoute(
        builder: (_) => TongtaiCustomerFormScreen(
          customer: customer,
          locations: _directory.service.locations,
          findDuplicates: (name, phone) => _directory.findDuplicates(
            name: name,
            phone: phone,
            exceptId: customer?.id,
          ),
        ),
      ),
    );
    if (!context.mounted || result == null) return;
    final failure = await runTongtaiAction(
      () => _directory.upsert(result),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'customer',
    );
    if (failure != null && context.mounted) {
      showTongtaiFailure(context, failure);
      return;
    }
    if (!context.mounted) return;
    // WTM-224 — the one "business data changed" signal, so a customer added
    // here reaches Home's counts, the capability contexts and the journey.
    invalidateBusinessDataProviders(ref);
    setState(() => _query = _query.copyWith(pageIndex: 0));
  }

  /// Open the customer's purchase history (WTM-77) — with the real order source
  /// + inventory wired in the real app so the seller can create orders (WTM-126).
  void _openHistory(BuildContext context, Customer customer) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TongtaiCustomerHistoryScreen(
          customer: customer,
          service: widget.orderHistory,
          orderController: _orders,
          products: _products,
        ),
      ),
    );
  }

  // Any change to the search text, location or sort resets to the first page so
  // the user is never stranded on a now-out-of-range page.
  void _onSearchChanged(String value) {
    setState(() => _query = _query.copyWith(text: value, pageIndex: 0));
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = _query.copyWith(text: '', pageIndex: 0));
  }

  void _selectLocation(String? location) {
    setState(() {
      _query = location == null
          ? _query.copyWith(clearLocation: true, pageIndex: 0)
          : _query.copyWith(location: location, pageIndex: 0);
    });
  }

  void _selectSort(CustomerSort sort) {
    setState(() => _query = _query.copyWith(sort: sort, pageIndex: 0));
  }

  void _toggleDirection() {
    setState(
      () =>
          _query = _query.copyWith(ascending: !_query.ascending, pageIndex: 0),
    );
  }

  void _goToPage(int index) {
    setState(() => _query = _query.copyWith(pageIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_directory, _data]),
      builder: (context, _) {
        final service = _directory.service;
        final page = service.page(_query);

        return Scaffold(
          backgroundColor: TtColors.surfaceSecondary,
          appBar: AppBar(
            title: Text(context.l10n.titleCustomers),
            elevation: 0,
            backgroundColor: TtColors.surfaceSecondary,
            foregroundColor: TtColors.textPrimary,
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('customer-action-add'),
            onPressed: () => _openForm(context),
            backgroundColor: TtFab.background,
            foregroundColor: TtFab.foreground,
            icon: const Icon(Icons.add),
            label: Text(context.l10n.custAdd),
          ),
          // The pagination controls sit in the bottom bar so the (endFloat)
          // FAB is lifted clear above them instead of obscuring the Next-page
          // button — same layout fix as the Inventory screen (WTM-69).
          bottomNavigationBar: page.totalCount > 0
              ? SafeArea(
                  top: false,
                  child: _PaginationBar(
                    page: page,
                    onPrevious: page.hasPrevious
                        ? () => _goToPage(page.pageIndex - 1)
                        : null,
                    onNext: page.hasNext
                        ? () => _goToPage(page.pageIndex + 1)
                        : null,
                  ),
                )
              : null,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TtSpace.x4,
                    TtSpace.x3,
                    TtSpace.x4,
                    TtSpace.x2,
                  ),
                  child: _SearchField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onClear: _query.text.isEmpty ? null : _clearSearch,
                  ),
                ),
                _LocationFilter(
                  locations: service.locations,
                  selected: _query.location,
                  onSelected: _selectLocation,
                ),
                _SortBar(
                  sort: _query.sort,
                  ascending: _query.ascending,
                  onSort: _selectSort,
                  onToggleDirection: _toggleDirection,
                ),
                _ResultsHeader(count: page.totalCount),
                Expanded(
                  child: TongtaiScreenData<List<Product>>(
                    prefix: 'customer',
                    state: _data.state,
                    onRetry: _data.retry,
                    isEmpty: (_) => page.isEmpty,
                    emptyBuilder: (_) => const _EmptyState(),
                    builder: (context, _) => _CustomerList(
                      customers: page.items,
                      onEdit: (customer) =>
                          _openForm(context, customer: customer),
                      onHistory: (customer) => _openHistory(context, customer),
                      opportunities:
                          ref.watch(generatedOpportunitiesProvider).value ??
                          const [],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('customer-search-field'),
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.l10n.custSearchHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                tooltip: context.l10n.actionClear,
                onPressed: onClear,
              ),
        filled: true,
        fillColor: TtColors.surfaceTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TtRadius.sm),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: TtSpace.x4),
      ),
    );
  }
}

class _LocationFilter extends StatelessWidget {
  const _LocationFilter({
    required this.locations,
    required this.selected,
    required this.onSelected,
  });

  final List<String> locations;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return _ChipsRow(
      rowKey: const Key('customer-filter-location'),
      label: context.l10n.labelLocation,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: TtSpace.x2),
          child: ChoiceChip(
            label: Text(context.l10n.filterAll),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
        ),
        for (final location in locations)
          Padding(
            padding: const EdgeInsets.only(right: TtSpace.x2),
            child: ChoiceChip(
              label: Text(location),
              selected: selected == location,
              onSelected: (isSelected) =>
                  onSelected(isSelected ? location : null),
            ),
          ),
      ],
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({
    required this.sort,
    required this.ascending,
    required this.onSort,
    required this.onToggleDirection,
  });

  final CustomerSort sort;
  final bool ascending;
  final ValueChanged<CustomerSort> onSort;
  final VoidCallback onToggleDirection;

  @override
  Widget build(BuildContext context) {
    return _ChipsRow(
      rowKey: const Key('customer-filter-sort'),
      label: context.l10n.labelSort,
      trailing: IconButton(
        icon: Icon(ascending ? Icons.arrow_upward : Icons.arrow_downward),
        tooltip: ascending
            ? context.l10n.sortAscending
            : context.l10n.sortDescending,
        onPressed: onToggleDirection,
      ),
      children: [
        for (final option in CustomerSort.values)
          Padding(
            padding: const EdgeInsets.only(right: TtSpace.x2),
            child: ChoiceChip(
              label: Text(option.label(context.l10n.languageCode)),
              selected: sort == option,
              onSelected: (_) => onSort(option),
            ),
          ),
      ],
    );
  }
}

/// A labelled, horizontally-scrolling row of chips with an optional trailing
/// action — shared chrome for the location and sort rows.
class _ChipsRow extends StatelessWidget {
  const _ChipsRow({
    required this.label,
    required this.children,
    this.trailing,
    this.rowKey,
  });

  final String label;
  final List<Widget> children;
  final Widget? trailing;

  /// Stable test id supplied by the owning row (`customer-filter-*`); this
  /// widget is shared by the location and sort rows so the key comes from the
  /// caller rather than being hard-coded here.
  final Key? rowKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: rowKey,
      padding: const EdgeInsets.symmetric(
        horizontal: TtSpace.x4,
        vertical: TtSpace.x1,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: TtType.body.copyWith(
                color: TtColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: children),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TtSpace.x4,
        TtSpace.x3,
        TtSpace.x4,
        TtSpace.x2,
      ),
      child: Text(
        context.l10n.countCustomers(count),
        key: const Key('customer-count-badge'),
        style: TtType.body.copyWith(color: TtColors.textSecondary),
      ),
    );
  }
}

class _CustomerList extends StatelessWidget {
  const _CustomerList({
    required this.customers,
    required this.onEdit,
    required this.onHistory,
    this.opportunities = const [],
  });

  final List<Customer> customers;
  final ValueChanged<Customer> onEdit;
  final ValueChanged<Customer> onHistory;

  /// What the Rule Engine already generated (WTM-225) — read, never recomputed
  /// here: Consumer does not get its own idea of who has gone quiet.
  final List<Opportunity> opportunities;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(TtSpace.x4, 0, TtSpace.x4, TtSpace.x4),
      itemCount: customers.length,
      separatorBuilder: (context, _) => const SizedBox(height: TtSpace.x3),
      itemBuilder: (context, index) => _CustomerRow(
        customer: customers[index],
        onTap: () => onEdit(customers[index]),
        onHistory: () => onHistory(customers[index]),
        // The fifth beat: this customer has gone quiet, and the product has
        // already worked out what to do about it.
        opportunity: opportunities.winBackFor(customers[index].id),
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({
    required this.customer,
    required this.onTap,
    required this.onHistory,
    this.opportunity,
  });

  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onHistory;

  /// The win-back opportunity generated for this customer, if any. `null` for
  /// a customer who is not quiet — a button to an opportunity that does not
  /// exist is the WTM-169 defect.
  final Opportunity? opportunity;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('customer-item-${customer.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(TtRadius.md),
      child: Container(
        padding: const EdgeInsets.all(TtSpace.x3),
        decoration: BoxDecoration(
          color: TtColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(TtRadius.md),
          border: Border.all(color: TtColors.border),
          boxShadow: TtElevation.soft,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TtType.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: TtColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: TtSpace.x2),
                      _TierChip(tier: customer.tier),
                    ],
                  ),
                  const SizedBox(height: TtSpace.x1),
                  Text(
                    customer.location.isEmpty
                        ? customer.maskedPhone
                        : '${customer.maskedPhone} • ${customer.location}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TtType.caption.copyWith(
                      color: TtColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: TtSpace.x1),
                  Text(
                    customer.lastPurchaseDate == null
                        ? context.l10n.customerNoPurchases
                        : context.l10n.customerLastPurchase(
                            TongtaiFormatters.isoDate(
                              customer.lastPurchaseDate!,
                            ),
                          ),
                    style: TtType.caption.copyWith(
                      color: TtColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: TtSpace.x3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  TongtaiFormatters.vnd(customer.totalSpent),
                  style: TtType.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: TtColors.textPrimary,
                  ),
                ),
                const SizedBox(height: TtSpace.x1),
                if (opportunity case final o?) ...[
                  TextButton(
                    key: Key('customer-opportunity-${customer.id}'),
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) =>
                            TongtaiOpportunityDetailScreen(opportunity: o),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(context.l10n.customerSeeOpportunity),
                  ),
                  const SizedBox(height: TtSpace.x1),
                ],
                Text(
                  context.l10n.countOrders(customer.orderCount),
                  style: TtType.caption.copyWith(color: TtColors.textSecondary),
                ),
                IconButton(
                  key: Key('customer-history-${customer.id}'),
                  tooltip: context.l10n.custPurchaseHistory,
                  icon: const Icon(
                    Icons.receipt_long_outlined,
                    size: 20,
                    color: TtColors.infoOnLight,
                  ),
                  onPressed: onHistory,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Value-tier badge — the WTM-75 visual indicator. High-value tiers (VIP / Gold)
/// get a star icon so they stand out at a glance.
class _TierChip extends StatelessWidget {
  const _TierChip({required this.tier});

  final CustomerTier tier;

  @override
  Widget build(BuildContext context) {
    final color = tongtaiCustomerTierColor(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TtSpace.x2, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TtRadius.full),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tier.isHighValue) ...[
            Icon(Icons.star, size: 12, color: color),
            const SizedBox(width: 2),
          ],
          Text(
            tier.label(context.l10n.languageCode),
            style: TtType.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.onPrevious,
    required this.onNext,
  });

  final CustomerPage page;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TtSpace.x4,
        vertical: TtSpace.x2,
      ),
      decoration: const BoxDecoration(
        color: TtColors.surfaceSecondary,
        border: Border(top: BorderSide(color: TtColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              context.l10n.invShowingRange(
                page.firstItemNumber,
                page.lastItemNumber,
                page.totalCount,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TtType.caption.copyWith(color: TtColors.textSecondary),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const Key('customer-action-prev-page'),
                icon: const Icon(Icons.chevron_left),
                tooltip: context.l10n.actionPrevPage,
                onPressed: onPrevious,
              ),
              Text(
                context.l10n.invPageOf(page.pageIndex + 1, page.pageCount),
                key: const Key('customer-page-indicator'),
                style: TtType.body.copyWith(
                  color: TtColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                key: const Key('customer-action-next-page'),
                icon: const Icon(Icons.chevron_right),
                tooltip: context.l10n.actionNextPage,
                onPressed: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('customer-empty'),
      child: Padding(
        padding: const EdgeInsets.all(TtSpace.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TongtaiFoxMascot.face(size: 64),
            const SizedBox(height: TtSpace.x3),
            Text(
              context.l10n.custEmptySearch,
              textAlign: TextAlign.center,
              style: TtType.bodyLarge.copyWith(
                color: TtColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TtSpace.x1),
            Text(
              context.l10n.custEmptySearchHint,
              textAlign: TextAlign.center,
              style: TtType.body.copyWith(color: TtColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
