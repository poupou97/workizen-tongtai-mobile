import 'package:flutter/material.dart';

import '../../../../core/design/tt.dart';

import '../../profile/business_profile.dart';
import '../../consumer/customer.dart';
import '../../core/tongtai_enums.dart';
import '../../core/tongtai_formatters.dart';
import '../../inventory/product.dart';
import '../../orders/order.dart';
import 'tongtai_inventory_picker_screen.dart';
import '../../../../core/l10n/app_strings.dart';

/// Create Order form (WTM-126) — the Orders capability's create flow, launched
/// from a customer's screen with that [customer] pre-selected. Each line is added
/// through the [TongtaiInventoryPickerScreen] (an inventory product, never free
/// text) followed by a quantity + sold-price prompt; the line snapshots the
/// product identity + the actual sold price at sale time. Save pops the built
/// [CustomerOrder] to the caller, which persists it via the OrderController.
class TongtaiCreateOrderScreen extends StatefulWidget {
  const TongtaiCreateOrderScreen({
    super.key,
    required this.customer,
    required this.products,
    this.clock,
    this.idFactory,
    this.orderNumberFactory,
    this.onSubmit,
  });

  /// Called with the built order on save. When null (the default), the screen
  /// pops the order to the caller instead — the launch-from-history flow awaits
  /// that pop. Injected in tests to capture the order without a route pop.
  final void Function(CustomerOrder order)? onSubmit;

  /// The customer this order is for (pre-selected; not editable here).
  final Customer customer;

  /// The inventory to pick lines from (the local catalog).
  final List<Product> products;

  /// Injectable clock (defaults to [DateTime.now]) for the order date + ids.
  final DateTime Function()? clock;

  /// Injectable id generator (defaults to a timestamp-based id).
  final String Function()? idFactory;

  /// Injectable order-number generator (defaults to `DH-<year>-<millis>`).
  final String Function(DateTime now)? orderNumberFactory;

  @override
  State<TongtaiCreateOrderScreen> createState() =>
      _TongtaiCreateOrderScreenState();
}

class _TongtaiCreateOrderScreenState extends State<TongtaiCreateOrderScreen> {
  final List<OrderItem> _items = [];
  late final DateTime Function() _clock;
  OrderStatus _status = OrderStatus.pending;

  /// Optional (WTM-209): null = not recorded, never a guessed channel.
  SalesChannel? _channel;

  @override
  void initState() {
    super.initState();
    _clock = widget.clock ?? DateTime.now;
  }

  double get _total => _items.fold(0, (sum, i) => sum + i.lineTotal);

  Future<void> _addItem() async {
    final product = await Navigator.of(context).push<Product>(
      MaterialPageRoute(
        builder: (_) => TongtaiInventoryPickerScreen(products: widget.products),
      ),
    );
    if (!mounted || product == null) return;
    final line = await _captureQuantityAndPrice(product);
    if (line == null) return;
    setState(() => _items.add(line));
  }

  /// Prompts for quantity + sold price (defaulting to the inventory price) and
  /// returns the snapshot line, or null if cancelled/invalid.
  Future<OrderItem?> _captureQuantityAndPrice(Product product) {
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController(
      text: product.pricePerUnit.toStringAsFixed(0),
    );
    return showDialog<OrderItem>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('order-item-quantity'),
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.l10n.labelQuantity,
              ),
            ),
            TextField(
              key: const Key('order-item-price'),
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.l10n.orderSoldPrice,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('order-item-add'),
            onPressed: () {
              final qty = int.tryParse(qtyController.text.trim()) ?? 0;
              final price = double.tryParse(priceController.text.trim());
              if (qty <= 0) {
                Navigator.of(context).pop();
                return;
              }
              Navigator.of(context).pop(
                OrderItem.fromProduct(product, quantity: qty, soldPrice: price),
              );
            },
            child: Text(context.l10n.actionAdd),
          ),
        ],
      ),
    );
  }

  void _removeItem(int index) => setState(() => _items.removeAt(index));

  void _save() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.orderNeedProduct)));
      return;
    }
    final now = _clock();
    final id =
        widget.idFactory?.call() ?? 'order-${now.millisecondsSinceEpoch}';
    final orderNumber =
        widget.orderNumberFactory?.call(now) ??
        'DH-${now.year}-${now.millisecondsSinceEpoch % 100000}';
    final order = CustomerOrder(
      id: id,
      customerId: widget.customer.id,
      orderNumber: orderNumber,
      date: now,
      status: _status,
      channel: _channel,
      items: List.unmodifiable(_items),
    );
    if (widget.onSubmit != null) {
      widget.onSubmit!(order);
    } else {
      Navigator.of(context).pop(order);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        title: Text(context.l10n.titleCreateOrder),
        elevation: 0,
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
        actions: [
          TextButton(
            key: const Key('create-order-save'),
            onPressed: _save,
            child: Text(context.l10n.actionSave),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create-order-add-item'),
        onPressed: _addItem,
        backgroundColor: TtFab.background,
        foregroundColor: TtFab.foreground,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.orderAddItem),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The header rows scroll as one unit: at a 2.0× system font the
            // fixed header (customer + status + channel) is taller than half a
            // small screen, and a rigid Column overflowed by 16 px the moment
            // the channel row was added (caught by p0/accessibility_test —
            // P-26's cousin: adding a ROW is also a layout change).
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(TtSpace.x4),
                      child: Text(
                        context.l10n.orderForCustomer(widget.customer.name),
                        style: TtType.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _StatusRow(
                      status: _status,
                      onSelected: (s) => setState(() => _status = s),
                    ),
                    // WTM-209: which channel this sale came through —
                    // optional, and a second tap on the selected chip clears
                    // it back to "not recorded". Self-recorded, no marketplace
                    // sync (D-5).
                    _ChannelRow(
                      channel: _channel,
                      onSelected: (c) =>
                          setState(() => _channel = _channel == c ? null : c),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TtSpace.x4,
                vertical: TtSpace.x2,
              ),
              child: Text(
                _items.length == 1 ? '1 item' : '${_items.length} items',
                style: TtType.body.copyWith(color: TtColors.textSecondary),
              ),
            ),
            Expanded(
              child: _items.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n.orderEmptyItems,
                        style: TtType.bodyLarge.copyWith(
                          color: TtColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TtSpace.x4,
                      ),
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final item = _items[i];
                        return ListTile(
                          key: Key('order-line-$i'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.productName),
                          subtitle: Text(
                            '${item.quantity} × '
                            '${TongtaiFormatters.vnd(item.unitPrice)} = '
                            '${TongtaiFormatters.vnd(item.lineTotal)}',
                            style: TtType.caption.copyWith(
                              color: TtColors.textSecondary,
                            ),
                          ),
                          trailing: IconButton(
                            key: Key('order-line-remove-$i'),
                            icon: const Icon(Icons.close, size: 18),
                            // Nói rõ XOÁ CÁI GÌ, không chỉ "Xoá" (WTM-432):
                            // đây là hành động phá huỷ, và trình đọc màn hình
                            // chỉ đọc được thứ ta đặt tên.
                            tooltip: context.l10n.orderRemoveLine(
                              item.productName,
                            ),
                            onPressed: () => _removeItem(i),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TtSpace.x4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.labelTotal,
                style: TtType.caption.copyWith(color: TtColors.textSecondary),
              ),
              Text(
                TongtaiFormatters.vnd(_total),
                key: const Key('create-order-total'),
                style: TtType.bodyLarge.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.status, required this.onSelected});

  final OrderStatus status;
  final ValueChanged<OrderStatus> onSelected;

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
              context.l10n.labelStatus,
              style: TtType.body.copyWith(
                color: TtColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final s in OrderStatus.values)
                    Padding(
                      padding: const EdgeInsets.only(right: TtSpace.x2),
                      child: ChoiceChip(
                        label: Text(s.label(context.l10n.languageCode)),
                        selected: status == s,
                        onSelected: (_) => onSelected(s),
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

/// Optional sales-channel picker (WTM-209) — same chip pattern as the status
/// row, but deselectable: "not recorded" is a legitimate final answer.
class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.channel, required this.onSelected});

  final SalesChannel? channel;
  final ValueChanged<SalesChannel> onSelected;

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
              context.l10n.labelChannel,
              style: TtType.body.copyWith(
                color: TtColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in SalesChannel.values)
                    Padding(
                      padding: const EdgeInsets.only(right: TtSpace.x2),
                      child: ChoiceChip(
                        key: Key('create-order-channel-${c.code}'),
                        label: Text(context.l10n.profileChannel(c.code)),
                        selected: channel == c,
                        onSelected: (_) => onSelected(c),
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
