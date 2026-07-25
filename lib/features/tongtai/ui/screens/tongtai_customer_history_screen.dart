import 'package:flutter/material.dart';

import '../../consumer/customer.dart';
import '../../consumer/customer_order_history_service.dart';
import '../../core/tongtai_enums.dart';
import '../../core/tongtai_formatters.dart';
import '../../inventory/product.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../orders/order.dart';
import '../../orders/order_controller.dart';
import 'tongtai_create_order_screen.dart';

/// Color for an [OrderStatus] chip. Pure function so the mapping is directly
/// unit-testable without pumping a widget (same convention as
/// `tongtaiCustomerTierColor`).
Color tongtaiOrderStatusColor(OrderStatus status) => switch (status) {
  OrderStatus.pending => TongtaiDesignTokens.warning,
  OrderStatus.confirmed || OrderStatus.shipped => TongtaiDesignTokens.info,
  OrderStatus.delivered => TongtaiDesignTokens.success,
  OrderStatus.cancelled => TongtaiDesignTokens.error,
};

/// Date-range presets for the AC4 filter. Fixed windows relative to an
/// injectable clock so tests are deterministic.
enum OrderHistoryRange {
  all,
  last30Days,
  last90Days;

  String get labelEn => switch (this) {
    OrderHistoryRange.all => 'All time',
    OrderHistoryRange.last30Days => 'Last 30 days',
    OrderHistoryRange.last90Days => 'Last 90 days',
  };

  /// The `from` bound this preset represents; null = unbounded (all time).
  DateTime? fromFor(DateTime now) => switch (this) {
    OrderHistoryRange.all => null,
    OrderHistoryRange.last30Days => now.subtract(const Duration(days: 30)),
    OrderHistoryRange.last90Days => now.subtract(const Duration(days: 90)),
  };
}

/// Customer Purchase History screen (WTM-77).
///
/// Shows one customer's orders newest-first (AC1) with order number, date,
/// status and total (AC2), the purchased items with quantities (AC3), a
/// date-range preset + product-category filter (AC4), and an aggregate header
/// with average order value and repurchase rate (AC5). Local-first: all data
/// comes from the in-memory [CustomerOrderHistoryService].
class TongtaiCustomerHistoryScreen extends StatefulWidget {
  const TongtaiCustomerHistoryScreen({
    super.key,
    required this.customer,
    this.service,
    this.clock,
    this.orderController,
    this.products = const [],
  });

  /// Whose history to show.
  final Customer customer;

  /// Injectable sample source for tests; used only when [orderController] is
  /// null. Defaults to the built-in sample orders.
  final CustomerOrderHistoryService? service;

  /// Injectable clock for the date-range presets (defaults to [DateTime.now]).
  final DateTime Function()? clock;

  /// The real order source (WTM-125/126). When provided, this screen reads the
  /// customer's persisted orders through it and shows a "Create Order" action;
  /// when null the screen stays read-only over [service] (User Data First: the
  /// real app always passes a controller).
  final OrderController? orderController;

  /// The inventory the Create Order flow picks lines from (WTM-126).
  final List<Product> products;

  @override
  State<TongtaiCustomerHistoryScreen> createState() =>
      _TongtaiCustomerHistoryScreenState();
}

class _TongtaiCustomerHistoryScreenState
    extends State<TongtaiCustomerHistoryScreen> {
  late final DateTime Function() _clock;

  OrderHistoryRange _range = OrderHistoryRange.all;
  String? _category;

  @override
  void initState() {
    super.initState();
    _clock = widget.clock ?? DateTime.now;
  }

  OrderHistoryQuery get _query =>
      OrderHistoryQuery(from: _range.fromFor(_clock()), category: _category);

  /// The order source: the real controller's orders when wired, else the sample
  /// service. A fresh service is built each frame so it reflects new orders.
  CustomerOrderHistoryService get _service => widget.orderController != null
      ? CustomerOrderHistoryService(widget.orderController!.orders)
      : (widget.service ?? CustomerOrderHistoryService.sample());

  Future<void> _createOrder() async {
    final controller = widget.orderController!;
    final order = await Navigator.of(context).push<CustomerOrder>(
      MaterialPageRoute(
        builder: (_) => TongtaiCreateOrderScreen(
          customer: widget.customer,
          products: widget.products,
          clock: widget.clock,
        ),
      ),
    );
    if (!mounted || order == null) return;
    await controller.upsert(order);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final customerId = widget.customer.id;
    final service = _service;
    final orders = service.ordersFor(customerId, _query);
    final metrics = service.metricsFor(customerId);
    final categories = service.categoriesFor(customerId);

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text('Purchase History — ${widget.customer.name}'),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
      ),
      floatingActionButton: widget.orderController == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('history-create-order'),
              onPressed: _createOrder,
              backgroundColor: TongtaiDesignTokens.consumerBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Create Order'),
            ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricsHeader(metrics: metrics),
            _FilterRow(
              label: 'Period',
              children: [
                for (final range in OrderHistoryRange.values)
                  Padding(
                    padding: const EdgeInsets.only(
                      right: TongtaiDesignTokens.spacing2,
                    ),
                    child: ChoiceChip(
                      label: Text(range.labelEn),
                      selected: _range == range,
                      onSelected: (_) => setState(() => _range = range),
                    ),
                  ),
              ],
            ),
            if (categories.isNotEmpty)
              _FilterRow(
                label: 'Category',
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      right: TongtaiDesignTokens.spacing2,
                    ),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: _category == null,
                      onSelected: (_) => setState(() => _category = null),
                    ),
                  ),
                  for (final category in categories)
                    Padding(
                      padding: const EdgeInsets.only(
                        right: TongtaiDesignTokens.spacing2,
                      ),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: _category == category,
                        onSelected: (selected) => setState(
                          () => _category = selected ? category : null,
                        ),
                      ),
                    ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TongtaiDesignTokens.spacing4,
                TongtaiDesignTokens.spacing3,
                TongtaiDesignTokens.spacing4,
                TongtaiDesignTokens.spacing2,
              ),
              child: Text(
                orders.length == 1 ? '1 order' : '${orders.length} orders',
                style: TongtaiDesignTokens.smallStyle.copyWith(
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              ),
            ),
            Expanded(
              child: orders.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        TongtaiDesignTokens.spacing4,
                        0,
                        TongtaiDesignTokens.spacing4,
                        TongtaiDesignTokens.spacing4,
                      ),
                      itemCount: orders.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(height: TongtaiDesignTokens.spacing3),
                      itemBuilder: (context, index) =>
                          _OrderCard(order: orders[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aggregate header: order count, average order value, repurchase rate (AC5).
class _MetricsHeader extends StatelessWidget {
  const _MetricsHeader({required this.metrics});

  final OrderHistoryMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
      decoration: BoxDecoration(
        color: TongtaiDesignTokens.consumerBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.cardBorderRadius,
        ),
        border: Border.all(
          color: TongtaiDesignTokens.consumerBlue.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          _Metric(
            key: const Key('history-metric-orders'),
            label: 'Orders',
            value: '${metrics.orderCount}',
          ),
          _Metric(
            key: const Key('history-metric-aov'),
            label: 'Avg order',
            value: TongtaiFormatters.vnd(metrics.averageOrderValue),
          ),
          _Metric(
            key: const Key('history-metric-repurchase'),
            label: 'Repurchase',
            value: '${(metrics.repurchaseRate * 100).round()}%',
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TongtaiDesignTokens.bodyStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
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

/// A labelled, horizontally-scrolling row of chips (filter chrome).
class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.label, required this.children});

  final String label;
  final List<Widget> children;

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
        ],
      ),
    );
  }
}

/// One order: number, date, status, total (AC2) + item lines (AC3).
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final CustomerOrder order;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TongtaiDesignTokens.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: TongtaiDesignTokens.lightTextPrimary,
                  ),
                ),
              ),
              _StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing1),
          Text(
            '${TongtaiFormatters.isoDate(order.date)} • '
            '${order.totalQuantity} ${order.totalQuantity == 1 ? 'item' : 'items'}',
            style: TongtaiDesignTokens.captionStyle.copyWith(
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${item.quantity} × ${item.productName} — '
                '${TongtaiFormatters.vnd(item.lineTotal)}',
                style: TongtaiDesignTokens.captionStyle.copyWith(
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              ),
            ),
          const SizedBox(height: TongtaiDesignTokens.spacing1),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              TongtaiFormatters.vnd(order.totalAmount),
              style: TongtaiDesignTokens.smallStyle.copyWith(
                fontWeight: FontWeight.w700,
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = tongtaiOrderStatusColor(status);
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
      child: Text(
        status.labelEn,
        style: TongtaiDesignTokens.captionStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
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
              Icons.receipt_long_outlined,
              size: 48,
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing3),
            Text(
              'No orders in this period',
              textAlign: TextAlign.center,
              style: TongtaiDesignTokens.bodyStyle.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing1),
            Text(
              'Try a wider period or clear the category filter.',
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
