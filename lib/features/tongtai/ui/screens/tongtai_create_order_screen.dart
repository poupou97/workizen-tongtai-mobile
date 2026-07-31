import 'package:flutter/material.dart';

import '../../consumer/customer.dart';
import '../../core/tongtai_enums.dart';
import '../../core/tongtai_formatters.dart';
import '../../inventory/product.dart';
import '../../navigation/tongtai_design_tokens.dart';
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
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(context.l10n.titleCreateOrder),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
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
        backgroundColor: TongtaiDesignTokens.consumerBlueText,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.orderAddItem),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
              child: Text(
                context.l10n.orderForCustomer(widget.customer.name),
                style: TongtaiDesignTokens.bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _StatusRow(
              status: _status,
              onSelected: (s) => setState(() => _status = s),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TongtaiDesignTokens.spacing4,
                vertical: TongtaiDesignTokens.spacing2,
              ),
              child: Text(
                _items.length == 1 ? '1 item' : '${_items.length} items',
                style: TongtaiDesignTokens.smallStyle.copyWith(
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              ),
            ),
            Expanded(
              child: _items.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n.orderEmptyItems,
                        style: TongtaiDesignTokens.bodyStyle.copyWith(
                          color: TongtaiDesignTokens.lightTextSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TongtaiDesignTokens.spacing4,
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
                            style: TongtaiDesignTokens.captionStyle.copyWith(
                              color: TongtaiDesignTokens.lightTextSecondary,
                            ),
                          ),
                          trailing: IconButton(
                            key: Key('order-line-remove-$i'),
                            icon: const Icon(Icons.close, size: 18),
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
          padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.labelTotal,
                style: TongtaiDesignTokens.captionStyle.copyWith(
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              ),
              Text(
                TongtaiFormatters.vnd(_total),
                key: const Key('create-order-total'),
                style: TongtaiDesignTokens.bodyStyle.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
        horizontal: TongtaiDesignTokens.spacing4,
        vertical: TongtaiDesignTokens.spacing1,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            child: Text(
              context.l10n.labelStatus,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
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
                      padding: const EdgeInsets.only(
                        right: TongtaiDesignTokens.spacing2,
                      ),
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
