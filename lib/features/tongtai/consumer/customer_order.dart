import 'package:flutter/foundation.dart';

import '../core/tongtai_enums.dart';

/// One line of a customer's order: a product, how many, and at what price
/// (WTM-77 AC3 — items purchased in each order with quantities).
@immutable
class OrderItem {
  const OrderItem({
    required this.productName,
    required this.category,
    required this.quantity,
    required this.unitPrice,
  });

  /// Product display name, e.g. "Quạt mini cầm tay".
  final String productName;

  /// Product category, e.g. "Electronics" — the AC4 category filter facet.
  final String category;

  /// Units purchased.
  final int quantity;

  /// Price per unit in Vietnamese đồng at purchase time.
  final double unitPrice;

  /// This line's total (quantity × unit price).
  double get lineTotal => quantity * unitPrice;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderItem &&
          other.productName == productName &&
          other.category == category &&
          other.quantity == quantity &&
          other.unitPrice == unitPrice);

  @override
  int get hashCode => Object.hash(productName, category, quantity, unitPrice);
}

/// A customer's past order (WTM-77) — pure domain model mirroring the Drift
/// `OrdersTable` shape (id, date, status, JSON items) so an in-memory service
/// can later be swapped for a Drift-backed one without touching callers.
@immutable
class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.customerId,
    required this.orderNumber,
    required this.date,
    required this.status,
    required this.items,
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
