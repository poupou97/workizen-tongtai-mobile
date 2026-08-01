import '../profile/business_profile.dart';
import 'package:flutter/foundation.dart';

import '../core/tongtai_enums.dart';
import '../inventory/product.dart';

/// One line of a customer's order — an **immutable business snapshot** of an
/// inventory product at sale time (Founder WTM-126). A line always references an
/// inventory product ([productId]) and records the product identity + the
/// **actual sold price** ([unitPrice]) as they were when the order was placed, so
/// historical orders and reports never change when inventory prices/names change
/// later.
@immutable
class OrderItem {
  const OrderItem({
    required this.productName,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    this.productId = '',
    this.sku = '',
    this.unit = '',
  });

  /// Builds a line from an inventory [product] (Founder WTM-126: order lines must
  /// reference an inventory product, never free text). Snapshots the product's
  /// identity and takes [soldPrice] — the *actual* sold price, which may override
  /// the inventory default [Product.pricePerUnit].
  factory OrderItem.fromProduct(
    Product product, {
    required int quantity,
    double? soldPrice,
    String unit = '',
  }) => OrderItem(
    productId: product.id,
    productName: product.name,
    sku: product.sku,
    category: product.category,
    unit: unit,
    quantity: quantity,
    unitPrice: soldPrice ?? product.pricePerUnit,
  );

  /// The inventory product this line references. Empty only for a legacy line
  /// written before WTM-126.
  final String productId;

  /// Product display name at sale time, e.g. "Quạt mini cầm tay".
  final String productName;

  /// Stock-keeping unit at sale time, e.g. "SKU-EL-001" (empty if unknown).
  final String sku;

  /// Product category, e.g. "Electronics" — the AC4 category filter facet.
  final String category;

  /// Unit of sale (e.g. "cái", "hộp") at sale time; empty until Inventory
  /// carries an explicit unit field.
  final String unit;

  /// Units purchased.
  final int quantity;

  /// The **actual sold price** per unit in Vietnamese đồng at sale time — an
  /// immutable snapshot that never follows later inventory-price changes.
  final double unitPrice;

  /// This line's total (quantity × sold price).
  double get lineTotal => quantity * unitPrice;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderItem &&
          other.productId == productId &&
          other.productName == productName &&
          other.sku == sku &&
          other.category == category &&
          other.unit == unit &&
          other.quantity == quantity &&
          other.unitPrice == unitPrice);

  @override
  int get hashCode => Object.hash(
    productId,
    productName,
    sku,
    category,
    unit,
    quantity,
    unitPrice,
  );
}

/// A sales order (WTM-77, persisted WTM-125) — pure domain model over the Orders
/// capability's `orders_table`. Holds the customer, a human order number, the
/// date, lifecycle [status], and the immutable line-item snapshots.
///
/// **Future compatibility (Founder WTM-126):** the model is deliberately kept
/// open so later capabilities attach **without breaking existing orders** —
/// Payment/paymentStatus and Shipment/shippingCost already have `orders_table`
/// columns; Invoice, Return and Warranty can arrive as additive columns or a
/// versioned `domain_snapshot` (ADR-TON-009) plus their own child tables, read by
/// the Repository. No downstream consumer decodes the order itself, so adding a
/// field never ripples callers.
@immutable
class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.customerId,
    required this.orderNumber,
    required this.date,
    required this.status,
    required this.items,
    this.paymentStatus,
    this.channel,
  });

  /// Stable identifier.
  final String id;

  /// The customer this order belongs to.
  final String customerId;

  /// Human-facing order number, e.g. "DH-2026-0142" (AC2).
  final String orderNumber;

  /// When the order was placed (AC1/AC2).
  final DateTime date;

  /// Fulfilment status (AC2) — the shared WTM-60 [OrderStatus] enum (EN/VI).
  final OrderStatus status;

  /// Whether the money for this order has arrived (WTM-211).
  ///
  /// The column has been in the schema since v1 — the third field behind
  /// `costPrice` (WTM-204) and `channelId` (WTM-209) that had a home nobody
  /// wired. Canonical codes: `paid` · `unpaid` · `partial`. **`null` means
  /// "not recorded"**, and it is treated as paid-unknown, never as debt —
  /// declaring a seller's old orders unpaid because a feature shipped later
  /// would invent receivables out of thin air.
  final String? paymentStatus;

  /// True only when the seller **said** the money has not arrived.
  bool get isUnpaid =>
      paymentStatus == kPaymentUnpaid || paymentStatus == kPaymentPartial;

  /// Where this order was sold (WTM-209) — the same [SalesChannel] vocabulary
  /// the business profile uses, so an order cannot claim a channel the app
  /// does not know.
  ///
  /// `null` means **not recorded**, never "shop": inventing a default channel
  /// would fabricate a per-channel breakdown the seller never gave (the
  /// `null ≠ 0` rule, applied to a label). Self-recorded, local-first — no
  /// marketplace connection involved (D-5); syncing real storefront data is
  /// Phase 3 per D-12.
  final SalesChannel? channel;

  /// The purchased lines (AC3). Never empty for a real order.
  final List<OrderItem> items;

  /// Total units across all lines.
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  /// Order total in đồng (AC2), derived from the lines.
  double get totalAmount => items.fold(0, (sum, item) => sum + item.lineTotal);

  /// Distinct categories in this order — what the AC4 category filter matches.
  Set<String> get categories => {for (final item in items) item.category};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CustomerOrder && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CustomerOrder($id, $orderNumber, ${status.name})';

  /// The same record under different ids — the sample-seeding remap hook
  /// (WTM-144/ADR-TON-014). [newCustomerId] rewires the order to the remapped
  /// sample customer.
  CustomerOrder withIds({required String newId, String? newCustomerId}) =>
      CustomerOrder(
        id: newId,
        customerId: newCustomerId ?? customerId,
        orderNumber: orderNumber,
        date: date,
        status: status,
        items: items,
      );
}

/// Deterministic sample orders for the sample customer directory, until a
/// Drift-backed order source is wired in (same convention as
/// `kSampleCustomers`). Dates are fixed so sorting/filter tests are stable.
final List<CustomerOrder> kSampleCustomerOrders = [
  // ── Phương Nguyễn (c01) — frequent electronics buyer, one cancelled ──────
  CustomerOrder(
    id: 'o01',
    customerId: 'c01',
    orderNumber: 'DH-2026-0101',
    date: DateTime(2026, 7, 10),
    status: OrderStatus.delivered,
    items: const [
      OrderItem(
        productName: 'Quạt mini cầm tay',
        category: 'Electronics',
        quantity: 2,
        unitPrice: 89000,
      ),
      OrderItem(
        productName: 'Sạc dự phòng 10k mAh',
        category: 'Electronics',
        quantity: 1,
        unitPrice: 250000,
      ),
    ],
  ),
  CustomerOrder(
    id: 'o02',
    customerId: 'c01',
    orderNumber: 'DH-2026-0086',
    date: DateTime(2026, 5, 18),
    status: OrderStatus.delivered,
    items: const [
      OrderItem(
        productName: 'Áo thun cotton',
        category: 'Fashion',
        quantity: 3,
        unitPrice: 120000,
      ),
    ],
  ),
  CustomerOrder(
    id: 'o03',
    customerId: 'c01',
    orderNumber: 'DH-2026-0064',
    date: DateTime(2026, 3, 2),
    status: OrderStatus.cancelled,
    items: const [
      OrderItem(
        productName: 'Đèn ngủ LED',
        category: 'Home',
        quantity: 1,
        unitPrice: 145000,
      ),
    ],
  ),
  // ── Bảo Lê (c07) — single order ──────────────────────────────────────────
  CustomerOrder(
    id: 'o04',
    customerId: 'c07',
    orderNumber: 'DH-2026-0095',
    date: DateTime(2026, 6, 30),
    status: OrderStatus.shipped,
    items: const [
      OrderItem(
        productName: 'Bình giữ nhiệt 500ml',
        category: 'Home',
        quantity: 2,
        unitPrice: 165000,
      ),
    ],
  ),
  // ── Thu Hà (c10) — VIP with a spread of orders ───────────────────────────
  CustomerOrder(
    id: 'o05',
    customerId: 'c10',
    orderNumber: 'DH-2026-0102',
    date: DateTime(2026, 7, 13),
    status: OrderStatus.confirmed,
    items: const [
      OrderItem(
        productName: 'Tai nghe bluetooth',
        category: 'Electronics',
        quantity: 1,
        unitPrice: 420000,
      ),
    ],
  ),
  CustomerOrder(
    id: 'o06',
    customerId: 'c10',
    orderNumber: 'DH-2026-0090',
    date: DateTime(2026, 6, 8),
    status: OrderStatus.delivered,
    items: const [
      OrderItem(
        productName: 'Váy linen',
        category: 'Fashion',
        quantity: 2,
        unitPrice: 350000,
      ),
      OrderItem(
        productName: 'Khăn lụa',
        category: 'Fashion',
        quantity: 1,
        unitPrice: 180000,
      ),
    ],
  ),
  CustomerOrder(
    id: 'o07',
    customerId: 'c10',
    orderNumber: 'DH-2026-0071',
    date: DateTime(2026, 4, 15),
    status: OrderStatus.delivered,
    items: const [
      OrderItem(
        productName: 'Nồi chiên không dầu',
        category: 'Home',
        quantity: 1,
        unitPrice: 1250000,
      ),
    ],
  ),
  CustomerOrder(
    id: 'o08',
    customerId: 'c10',
    orderNumber: 'DH-2026-0055',
    date: DateTime(2026, 2, 20),
    status: OrderStatus.pending,
    items: const [
      OrderItem(
        productName: 'Bộ dao nhà bếp',
        category: 'Home',
        quantity: 1,
        unitPrice: 390000,
      ),
    ],
  ),
];

/// Canonical payment codes (WTM-211) — stored, never display labels.
const String kPaymentPaid = 'paid';
const String kPaymentUnpaid = 'unpaid';
const String kPaymentPartial = 'partial';
