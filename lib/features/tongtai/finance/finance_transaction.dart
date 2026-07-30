import 'package:flutter/foundation.dart';

import '../core/tongtai_enums.dart';

/// A single financial transaction (WTM-27) — money in or out, mirroring the
/// Drift `TransactionsTable` shape (id, type, category, amount, date,
/// description, payment method) so an in-memory service can later be swapped for
/// a Drift-backed one without touching callers.
@immutable
class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.description = '',
    this.paymentMethod = '',
  });

  /// Stable identifier.
  final String id;

  /// Money in ([TransactionType.income]) or out ([TransactionType.expense]).
  final TransactionType type;

  /// Human category, e.g. "Nhập hàng", "Thuê mặt bằng", "Bán hàng".
  final String category;

  /// Amount in Vietnamese đồng — always positive; direction lives in [type].
  final double amount;

  /// When the transaction occurred.
  final DateTime date;

  /// Free-text note.
  final String description;

  /// How it was paid, e.g. "bankTransfer", "cash", "momo".
  final String paymentMethod;

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is FinanceTransaction && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'FinanceTransaction($id, ${type.name}, $category, $amount)';

  /// The same record under a different id — the sample-seeding remap hook
  /// (WTM-144/ADR-TON-014).
  FinanceTransaction withId(String newId) => FinanceTransaction(
    id: newId,
    type: type,
    category: category,
    amount: amount,
    date: date,
    description: description,
    paymentMethod: paymentMethod,
  );
}

/// Deterministic sample transactions so the Finance dashboard has real data to
/// exercise until it is wired to Drift — same convention as `kSampleProducts`
/// / `kSampleCustomerOrders`. A small VN reseller across Feb–Jul 2026:
/// YTD income 24.560.000 ₫, expenses 18.020.000 ₫ → profit 6.540.000 ₫.
final List<FinanceTransaction> kSampleTransactions = [
  // ── Feb 2026 ──────────────────────────────────────────────────────────
  FinanceTransaction(
    id: 't01',
    type: TransactionType.income,
    category: 'Bán hàng',
    amount: 3200000,
    date: DateTime(2026, 2, 8),
    description: 'Bán lô quạt tích điện',
    paymentMethod: 'bankTransfer',
  ),
  FinanceTransaction(
    id: 't02',
    type: TransactionType.expense,
    category: 'Nhập hàng',
    amount: 1800000,
    date: DateTime(2026, 2, 5),
    description: 'Nhập quạt tích điện',
    paymentMethod: 'bankTransfer',
  ),
  FinanceTransaction(
    id: 't03',
    type: TransactionType.expense,
    category: 'Thuê mặt bằng',
    amount: 500000,
    date: DateTime(2026, 2, 1),
    description: 'Tiền thuê kho tháng 2',
    paymentMethod: 'cash',
  ),
  // ── Mar 2026 ──────────────────────────────────────────────────────────
  FinanceTransaction(
    id: 't04',
    type: TransactionType.income,
    category: 'Bán hàng',
    amount: 4100000,
    date: DateTime(2026, 3, 12),
    description: 'Bán áo thun + phụ kiện',
    paymentMethod: 'momo',
  ),
  FinanceTransaction(
    id: 't05',
    type: TransactionType.expense,
    category: 'Nhập hàng',
    amount: 2200000,
    date: DateTime(2026, 3, 6),
    description: 'Nhập áo thun cotton',
    paymentMethod: 'bankTransfer',
  ),
  FinanceTransaction(
    id: 't06',
    type: TransactionType.expense,
    category: 'Thuê mặt bằng',
    amount: 500000,
    date: DateTime(2026, 3, 1),
    description: 'Tiền thuê kho tháng 3',
    paymentMethod: 'cash',
  ),
  FinanceTransaction(
    id: 't07',
    type: TransactionType.expense,
    category: 'Quảng cáo',
    amount: 350000,
    date: DateTime(2026, 3, 18),
    description: 'Quảng cáo TikTok',
    paymentMethod: 'bankTransfer',
  ),
  // ── Apr 2026 ──────────────────────────────────────────────────────────
  FinanceTransaction(
    id: 't08',
    type: TransactionType.income,
    category: 'Bán hàng',
    amount: 3800000,
    date: DateTime(2026, 4, 15),
    description: 'Bán đồ gia dụng',
    paymentMethod: 'bankTransfer',
  ),
  FinanceTransaction(
    id: 't09',
    type: TransactionType.expense,
    category: 'Nhập hàng',
    amount: 2000000,
    date: DateTime(2026, 4, 4),
    description: 'Nhập nồi chiên không dầu',
    paymentMethod: 'bankTransfer',
  ),
  FinanceTransaction(
    id: 't10',
    type: TransactionType.expense,
    category: 'Thuê mặt bằng',
    amount: 500000,
    date: DateTime(2026, 4, 1),
    description: 'Tiền thuê kho tháng 4',
    paymentMethod: 'cash',
  ),
  FinanceTransaction(
    id: 't11',
    type: TransactionType.expense,
    category: 'Phí sàn',
    amount: 300000,
    date: DateTime(2026, 4, 20),
    description: 'Phí sàn Shopee',
    paymentMethod: 'bankTransfer',
  ),
  // ── May 2026 ──────────────────────────────────────────────────────────
  FinanceTransaction(
    id: 't12',
    type: TransactionType.income,
    category: 'Bán hàng',
    amount: 4600000,
    date: DateTime(2026, 5, 18),
    description: 'Bán váy linen + khăn lụa',
    paymentMethod: 'momo',
  ),
  FinanceTransaction(
    id: 't13',
    type: TransactionType.expense,
    category: 'Nhập hàng',
    amount: 2400000,
    date: DateTime(2026, 5, 7),
    description: 'Nhập hàng thời trang',
    paymentMethod: 'bankTransfer',
  ),
  FinanceTransaction(
    id: 't14',
    type: TransactionType.expense,
    category: 'Thuê mặt bằng',
    amount: 500000,
    date: DateTime(2026, 5, 1),
    description: 'Tiền thuê kho tháng 5',
    paymentMethod: 'cash',
  ),
  FinanceTransaction(
    id: 't15',
    type: TransactionType.expense,
    category: 'Quảng cáo',
    amount: 420000,
    date: DateTime(2026, 5, 22),
    description: 'Quảng cáo Facebook',
    paymentMethod: 'bankTransfer',
  ),
  // ── Jun 2026 ──────────────────────────────────────────────────────────
  FinanceTransaction(
    id: 't16',
    type: TransactionType.income,
    category: 'Bán hàng',
    amount: 5200000,
    date: DateTime(2026, 6, 14),
    description: 'Bán tai nghe + bình giữ nhiệt',
    paymentMethod: 'bankTransfer',
  ),
  FinanceTransaction(
    id: 't17',
    type: TransactionType.expense,
    category: 'Nhập hàng',
    amount: 2600000,
    date: DateTime(2026, 6, 5),
    description: 'Nhập hàng điện tử',
    paymentMethod: 'bankTransfer',
  ),
  FinanceTransaction(
    id: 't18',
    type: TransactionType.expense,
    category: 'Thuê mặt bằng',
    amount: 500000,
    date: DateTime(2026, 6, 1),
    description: 'Tiền thuê kho tháng 6',
    paymentMethod: 'cash',
  ),
  FinanceTransaction(
    id: 't19',
    type: TransactionType.expense,
    category: 'Vận chuyển',
    amount: 600000,
    date: DateTime(2026, 6, 25),
    description: 'Phí vận chuyển đơn sỉ',
    paymentMethod: 'cash',
  ),
  // ── Jul 2026 ──────────────────────────────────────────────────────────
  FinanceTransaction(
    id: 't20',
    type: TransactionType.income,
    category: 'Bán hàng',
    amount: 3660000,
    date: DateTime(2026, 7, 11),
    description: 'Bán hàng đầu tháng 7',
    paymentMethod: 'momo',
  ),
  FinanceTransaction(
    id: 't21',
    type: TransactionType.expense,
    category: 'Nhập hàng',
    amount: 1900000,
    date: DateTime(2026, 7, 4),
    description: 'Nhập hàng bổ sung',
    paymentMethod: 'bankTransfer',
  ),
  FinanceTransaction(
    id: 't22',
    type: TransactionType.expense,
    category: 'Thuê mặt bằng',
    amount: 500000,
    date: DateTime(2026, 7, 1),
    description: 'Tiền thuê kho tháng 7',
    paymentMethod: 'cash',
  ),
  FinanceTransaction(
    id: 't23',
    type: TransactionType.expense,
    category: 'Quảng cáo',
    amount: 450000,
    date: DateTime(2026, 7, 9),
    description: 'Quảng cáo Facebook',
    paymentMethod: 'bankTransfer',
  ),
];
