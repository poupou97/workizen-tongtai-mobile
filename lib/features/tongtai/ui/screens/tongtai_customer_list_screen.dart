import 'package:flutter/material.dart';

import '../../consumer/customer.dart';
import '../../consumer/customer_directory_service.dart';
import '../../core/tongtai_formatters.dart';
import '../../navigation/tongtai_design_tokens.dart';

/// Color for a [CustomerTier] badge (WTM-75 AC: visual indicators for VIP /
/// high-value customers). Pulled out as a pure function so the mapping is
/// directly unit-testable without pumping a widget.
Color tongtaiCustomerTierColor(CustomerTier tier) => switch (tier) {
  CustomerTier.vip => const Color(0xFFD4AF37), // gold
  CustomerTier.gold => TongtaiDesignTokens.warning, // amber
  CustomerTier.silver => TongtaiDesignTokens.neutral, // gray
  CustomerTier.bronze => const Color(0xFFB45309), // bronze
};

/// Customer list screen (WTM-75) — Customer Intelligence / CRM hub.
///
/// Local-first customer directory: a searchable, location-filterable, sortable
/// customer list with VIP/high-value tier badges and 20-per-page pagination.
/// All data comes from the in-memory [CustomerDirectoryService], so filtering,
/// sorting and paging happen synchronously.
class TongtaiCustomerListScreen extends StatefulWidget {
  const TongtaiCustomerListScreen({super.key, this.service});

  /// Injectable for tests; defaults to the built-in sample directory.
  final CustomerDirectoryService? service;

  @override
  State<TongtaiCustomerListScreen> createState() =>
      _TongtaiCustomerListScreenState();
}

class _TongtaiCustomerListScreenState extends State<TongtaiCustomerListScreen> {
  late final CustomerDirectoryService _service;
  final TextEditingController _searchController = TextEditingController();

  CustomerQuery _query = const CustomerQuery();

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? CustomerDirectoryService.sample();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final page = _service.page(_query);

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: const Text('Customers'),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TongtaiDesignTokens.spacing4,
                TongtaiDesignTokens.spacing3,
                TongtaiDesignTokens.spacing4,
                TongtaiDesignTokens.spacing2,
              ),
              child: _SearchField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onClear: _query.text.isEmpty ? null : _clearSearch,
              ),
            ),
            _LocationFilter(
              locations: _service.locations,
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
              child: page.isEmpty
                  ? const _EmptyState()
                  : _CustomerList(customers: page.items),
            ),
            if (page.totalCount > 0)
              _PaginationBar(
                page: page,
                onPrevious: page.hasPrevious
                    ? () => _goToPage(page.pageIndex - 1)
                    : null,
                onNext: page.hasNext
                    ? () => _goToPage(page.pageIndex + 1)
                    : null,
              ),
          ],
        ),
      ),
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
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search name, phone or location',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear',
                onPressed: onClear,
              ),
        filled: true,
        fillColor: TongtaiDesignTokens.lightHover,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            TongtaiDesignTokens.componentBorderRadius,
          ),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TongtaiDesignTokens.spacing4,
        ),
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
      label: 'Location',
      children: [
        Padding(
          padding: const EdgeInsets.only(right: TongtaiDesignTokens.spacing2),
          child: ChoiceChip(
            label: const Text('All'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
        ),
        for (final location in locations)
          Padding(
            padding: const EdgeInsets.only(right: TongtaiDesignTokens.spacing2),
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
      label: 'Sort',
      trailing: IconButton(
        icon: Icon(ascending ? Icons.arrow_upward : Icons.arrow_downward),
        tooltip: ascending ? 'Sort ascending' : 'Sort descending',
        onPressed: onToggleDirection,
      ),
      children: [
        for (final option in CustomerSort.values)
          Padding(
            padding: const EdgeInsets.only(right: TongtaiDesignTokens.spacing2),
            child: ChoiceChip(
              label: Text(option.labelEn),
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
  const _ChipsRow({required this.label, required this.children, this.trailing});

  final String label;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TongtaiDesignTokens.spacing4,
        vertical: TongtaiDesignTokens.spacing1,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
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
        TongtaiDesignTokens.spacing4,
        TongtaiDesignTokens.spacing3,
        TongtaiDesignTokens.spacing4,
        TongtaiDesignTokens.spacing2,
      ),
      child: Text(
        count == 1 ? '1 customer' : '$count customers',
        style: TongtaiDesignTokens.smallStyle.copyWith(
          color: TongtaiDesignTokens.lightTextSecondary,
        ),
      ),
    );
  }
}

class _CustomerList extends StatelessWidget {
  const _CustomerList({required this.customers});

  final List<Customer> customers;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        TongtaiDesignTokens.spacing4,
        0,
        TongtaiDesignTokens.spacing4,
        TongtaiDesignTokens.spacing4,
      ),
      itemCount: customers.length,
      separatorBuilder: (context, _) =>
          const SizedBox(height: TongtaiDesignTokens.spacing3),
      itemBuilder: (context, index) => _CustomerRow(customer: customers[index]),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                        style: TongtaiDesignTokens.bodyStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: TongtaiDesignTokens.lightTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: TongtaiDesignTokens.spacing2),
                    _TierChip(tier: customer.tier),
                  ],
                ),
                const SizedBox(height: TongtaiDesignTokens.spacing1),
                Text(
                  '${customer.maskedPhone} • ${customer.location}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TongtaiDesignTokens.captionStyle.copyWith(
                    color: TongtaiDesignTokens.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: TongtaiDesignTokens.spacing1),
                Text(
                  'Last purchase '
                  '${TongtaiFormatters.isoDate(customer.lastPurchaseDate)}',
                  style: TongtaiDesignTokens.captionStyle.copyWith(
                    color: TongtaiDesignTokens.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: TongtaiDesignTokens.spacing3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                TongtaiFormatters.vnd(customer.totalSpent),
                style: TongtaiDesignTokens.smallStyle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: TongtaiDesignTokens.lightTextPrimary,
                ),
              ),
              const SizedBox(height: TongtaiDesignTokens.spacing1),
              Text(
                customer.orderCount == 1
                    ? '1 order'
                    : '${customer.orderCount} orders',
                style: TongtaiDesignTokens.captionStyle.copyWith(
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(
        horizontal: TongtaiDesignTokens.spacing2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusFull),
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
            tier.labelEn,
            style: TongtaiDesignTokens.captionStyle.copyWith(
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
        horizontal: TongtaiDesignTokens.spacing4,
        vertical: TongtaiDesignTokens.spacing2,
      ),
      decoration: const BoxDecoration(
        color: TongtaiDesignTokens.lightBackground,
        border: Border(top: BorderSide(color: TongtaiDesignTokens.lightBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'Showing ${page.firstItemNumber}–${page.lastItemNumber} '
              'of ${page.totalCount}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TongtaiDesignTokens.captionStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous page',
                onPressed: onPrevious,
              ),
              Text(
                'Page ${page.pageIndex + 1} of ${page.pageCount}',
                style: TongtaiDesignTokens.smallStyle.copyWith(
                  color: TongtaiDesignTokens.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next page',
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
      child: Padding(
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline,
              size: 48,
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing3),
            Text(
              'No customers match your search',
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.bodyStyle.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing1),
            Text(
              'Try a different keyword or clear the location filter.',
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
