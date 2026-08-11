import 'package:flutter/material.dart';

import '../../consumer/customer.dart';
import '../../consumer/customer_order_history_service.dart';
import '../../core/tongtai_enums.dart';
import '../../core/tongtai_formatters.dart';
import '../../inventory/product.dart';
import '../../core/screen_data_controller.dart';
import '../widgets/tongtai_screen_data.dart';
import '../../orders/order.dart';
import '../../orders/order_controller.dart';
import '../../consumer/customer_insight.dart';
import '../../providers/tongtai_consumer_provider.dart';
import '../../providers/tongtai_simulation_provider.dart';
import '../../simulation/demo_event.dart';
import 'tongtai_conversation_screen.dart';
import 'tongtai_create_order_screen.dart';
import '../../../../core/l10n/app_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';
import '../../providers/tongtai_data_invalidation.dart';

/// Color for an [OrderStatus] chip. Pure function so the mapping is directly
/// unit-testable without pumping a widget (same convention as
/// `tongtaiCustomerTierColor`).
Color tongtaiOrderStatusColor(OrderStatus status) => switch (status) {
  OrderStatus.pending => TtColors.warning,
  OrderStatus.confirmed || OrderStatus.shipped => TtColors.info,
  OrderStatus.delivered => TtColors.success,
  OrderStatus.cancelled => TtColors.danger,
};

/// Date-range presets for the AC4 filter. Fixed windows relative to an
/// injectable clock so tests are deterministic.
enum OrderHistoryRange {
  all,
  last30Days,
  last90Days;

  String label(AppStrings l10n) => switch (this) {
    OrderHistoryRange.all => l10n.historyRangeAll,
    OrderHistoryRange.last30Days => l10n.historyRangeLast30,
    OrderHistoryRange.last90Days => l10n.historyRangeLast90,
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
class TongtaiCustomerHistoryScreen extends ConsumerStatefulWidget {
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

  /// Injectable order source for tests; used only when [orderController] is
  /// null. When both are null the history is empty (never fixtures — P0 §3).
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
  ConsumerState<TongtaiCustomerHistoryScreen> createState() =>
      _TongtaiCustomerHistoryScreenState();
}

class _TongtaiCustomerHistoryScreenState
    extends ConsumerState<TongtaiCustomerHistoryScreen> {
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

  /// The order source: the real controller's orders when wired, else the
  /// injected service. A fresh service is built each frame so it reflects new
  /// orders. NEVER falls back to fixtures (P0 §3, WTM-146): a bare-constructed
  /// screen shows an empty history, not sample data.
  CustomerOrderHistoryService get _service => widget.orderController != null
      ? CustomerOrderHistoryService(widget.orderController!.orders)
      : (widget.service ?? CustomerOrderHistoryService(const []));

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
    // The seller just typed a whole order; losing it silently is not an option
    // (WTM-148). A failed write says so and offers the flow again.
    final failure = await runTongtaiAction(
      () => controller.upsert(order),
      screen: 'history',
    );
    if (!mounted) return;
    if (failure != null) {
      showTongtaiFailure(context, failure, onRetry: _createOrder);
      return;
    }
    // WTM-224 — an order is the single biggest business event in the app;
    // raising the one "data changed" signal here is what lets Home's revenue,
    // the Rule Twins and the journey notice it.
    invalidateBusinessDataProviders(ref);
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
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        title: Text(
          '${context.l10n.custPurchaseHistory} — ${widget.customer.name}',
        ),
        elevation: 0,
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
      ),
      floatingActionButton: widget.orderController == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('history-create-order'),
              onPressed: _createOrder,
              backgroundColor: TtColors.infoOnLight,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(context.l10n.titleCreateOrder),
            ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricsHeader(metrics: metrics),
            _CustomerStorySection(customerId: customerId),
            _CustomerSuggestionsSection(customerId: customerId),
            _FilterRow(
              label: context.l10n.labelPeriod,
              children: [
                for (final range in OrderHistoryRange.values)
                  Padding(
                    padding: const EdgeInsets.only(right: TtSpace.x2),
                    child: ChoiceChip(
                      label: Text(range.label(context.l10n)),
                      selected: _range == range,
                      onSelected: (_) => setState(() => _range = range),
                    ),
                  ),
              ],
            ),
            if (categories.isNotEmpty)
              _FilterRow(
                label: context.l10n.searchCategory,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: TtSpace.x2),
                    child: ChoiceChip(
                      label: Text(context.l10n.filterAll),
                      selected: _category == null,
                      onSelected: (_) => setState(() => _category = null),
                    ),
                  ),
                  for (final category in categories)
                    Padding(
                      padding: const EdgeInsets.only(right: TtSpace.x2),
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
                TtSpace.x4,
                TtSpace.x3,
                TtSpace.x4,
                TtSpace.x2,
              ),
              child: Text(
                context.l10n.countOrders(orders.length),
                style: TtType.body.copyWith(color: TtColors.textSecondary),
              ),
            ),
            Expanded(
              child: orders.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        TtSpace.x4,
                        0,
                        TtSpace.x4,
                        TtSpace.x4,
                      ),
                      itemCount: orders.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(height: TtSpace.x3),
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
      margin: const EdgeInsets.all(TtSpace.x4),
      padding: const EdgeInsets.all(TtSpace.x3),
      decoration: BoxDecoration(
        color: TtColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(TtRadius.md),
        border: Border.all(color: TtColors.info.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          _Metric(
            key: const Key('history-metric-orders'),
            label: context.l10n.kpiOrders,
            value: '${metrics.orderCount}',
          ),
          _Metric(
            key: const Key('history-metric-aov'),
            label: context.l10n.kpiAovShort,
            value: TongtaiFormatters.vnd(metrics.averageOrderValue),
          ),
          _Metric(
            key: const Key('history-metric-repurchase'),
            label: context.l10n.historyRepurchase,
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
            style: TtType.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: TtColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TtType.caption.copyWith(color: TtColors.textSecondary),
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
      padding: const EdgeInsets.all(TtSpace.x3),
      decoration: BoxDecoration(
        color: TtColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(TtRadius.md),
        border: Border.all(color: TtColors.border),
        boxShadow: TtElevation.soft,
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
                  style: TtType.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: TtColors.textPrimary,
                  ),
                ),
              ),
              _StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: TtSpace.x1),
          Text(
            '${TongtaiFormatters.isoDate(order.date)} • '
            '${order.totalQuantity} ${order.totalQuantity == 1 ? 'item' : 'items'}',
            style: TtType.caption.copyWith(color: TtColors.textSecondary),
          ),
          const SizedBox(height: TtSpace.x2),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${item.quantity} × ${item.productName} — '
                '${TongtaiFormatters.vnd(item.lineTotal)}',
                style: TtType.caption.copyWith(color: TtColors.textSecondary),
              ),
            ),
          const SizedBox(height: TtSpace.x1),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              TongtaiFormatters.vnd(order.totalAmount),
              style: TtType.body.copyWith(
                fontWeight: FontWeight.w700,
                color: TtColors.textPrimary,
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
      padding: const EdgeInsets.symmetric(horizontal: TtSpace.x2, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TtRadius.full),
        border: Border.all(color: color),
      ),
      child: Text(
        status.label(context.l10n.languageCode),
        style: TtType.caption.copyWith(
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
    // Scrollable: at a 2.0x system font this ran 114 px past the bottom.
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(TtSpace.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: TtColors.textSecondary,
            ),
            const SizedBox(height: TtSpace.x3),
            Text(
              context.l10n.historyEmptyOrders,
              textAlign: TextAlign.center,
              style: TtType.bodyLarge.copyWith(
                color: TtColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TtSpace.x1),
            Text(
              context.l10n.historyEmptyHint,
              textAlign: TextAlign.center,
              style: TtType.body.copyWith(color: TtColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// **Khách hàng 360** — câu chuyện, không chỉ danh sách đơn (WTM-339 · §38).
///
/// Một màn lịch sử mua hàng trả lời được *"khách này mua bao nhiêu"*. Nó
/// **không** trả lời được *"vì sao khách này giận"* — mà đó mới là câu người
/// bán cần trước khi bấm gửi bất cứ thứ gì. Ba việc gần nhất trong sổ, cộng
/// lối vào khung hội thoại, đóng đúng khoảng trống đó.
///
/// Đọc qua `customerConversationProvider` — cùng một chiếu với hộp thư, nên
/// hai màn không thể kể hai câu chuyện khác nhau (ADR-TON-015 One Data Path).
class _CustomerStorySection extends ConsumerWidget {
  const _CustomerStorySection({required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final conversation = ref
        .watch(customerConversationProvider(customerId))
        .asData
        ?.value;

    // Chưa có gì trong sổ ⇒ không chiếm chỗ. Một khung rỗng nói "chưa có việc
    // nào" trên mọi khách của một doanh nghiệp chưa bật demo là nhiễu thuần.
    if (conversation == null || conversation.events.isEmpty) {
      return const SizedBox.shrink();
    }

    final recent = conversation.events.take(3).toList(growable: false);
    // ⭐ WTM-347 · Discover — khách này từ đâu tới. Suy từ việc SỚM NHẤT có
    // mang tên một nền tảng; khách được gõ tay vào danh bạ thì không có kênh
    // nào cả, và để trống là câu trả lời thật chứ không phải thiếu sót.
    final firstTouch = firstTouchOf([
      for (final e in conversation.events.reversed)
        (vendor: e.vendor, at: e.occurredAt),
    ]);

    return Container(
      key: const Key('history-story'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(TtSpace.x4, 0, TtSpace.x4, TtSpace.x3),
      padding: const EdgeInsets.all(TtSpace.x3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TtRadius.md),
        border: Border.all(color: TtColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.customer360Story,
            style: TtType.body.copyWith(
              fontWeight: FontWeight.w800,
              color: TtColors.textPrimary,
            ),
          ),
          if (firstTouch != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.customer360FirstTouch(
                DemoVendor.displayName(firstTouch.vendor),
                TongtaiFormatters.isoDate(firstTouch.at),
              ),
              key: const Key('history-first-touch'),
              style: TtType.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: TtColors.infoOnLight,
              ),
            ),
          ],
          const SizedBox(height: TtSpace.x2),
          for (final event in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                event.headline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TtType.body.copyWith(color: TtColors.textSecondary),
              ),
            ),
          if (conversation.messages.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('history-open-conversation'),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) =>
                        TongtaiConversationScreen(customerId: customerId),
                  ),
                ),
                child: Text(
                  conversation.pendingDraft != null
                      ? '${l10n.customer360OpenConversation} · '
                            '${l10n.conversationDraftReady}'
                      : l10n.customer360OpenConversation,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// **Gợi ý cho khách này** — WTM-347 (Recommendation).
///
/// Suy từ đơn hàng THẬT: những gì khách khác mua kèm thứ khách này từng mua.
/// Rule Twin, không AI — và **rỗng khi chưa biết gì**, chứ không rơi về danh
/// sách bán chạy. Một danh sách bán chạy đội lốt gợi ý cá nhân là kiểu nói dối
/// khó phát hiện nhất: nó luôn có nội dung, nên không ai nhận ra nó chưa bao
/// giờ biết gì về khách.
class _CustomerSuggestionsSection extends ConsumerWidget {
  const _CustomerSuggestionsSection({required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final suggestions =
        ref.watch(customerSuggestionsProvider(customerId)).asData?.value ??
        const <ProductSuggestion>[];
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      key: const Key('history-suggestions'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(TtSpace.x4, 0, TtSpace.x4, TtSpace.x3),
      padding: const EdgeInsets.all(TtSpace.x3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TtRadius.md),
        border: Border.all(color: TtColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.customer360Suggestions,
            style: TtType.body.copyWith(
              fontWeight: FontWeight.w800,
              color: TtColors.textPrimary,
            ),
          ),
          const SizedBox(height: TtSpace.x2),
          for (final s in suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TtType.body.copyWith(color: TtColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Lý do đọc được, không phải một điểm số không ai kiểm được.
                  Text(
                    l10n.customer360BoughtTogether(s.boughtTogetherCount),
                    style: TtType.caption.copyWith(
                      color: TtColors.textSecondary,
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
