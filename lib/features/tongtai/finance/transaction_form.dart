import 'finance_category.dart';
import 'package:flutter/foundation.dart';

import '../core/tongtai_enums.dart';
import 'finance_transaction.dart';

/// Validation fields for the transaction form (WTM-113).
enum TransactionField { amount, category }

/// Common categories offered as quick-pick chips, per direction (WTM-113).
const List<String> kIncomeCategories = ['Bán hàng', 'Khác'];
const List<String> kExpenseCategories = [
  'Nhập hàng',
  'Thuê mặt bằng',
  'Quảng cáo',
  'Vận chuyển',
  'Phí sàn',
  'Khác',
];

/// Immutable snapshot of the Add Transaction form (WTM-113).
///
/// The amount is held as raw text so the form can validate user input (blank /
/// non-numeric / non-positive) before parsing. Pure Dart — no Flutter widgets —
/// so validation and conversion are unit-testable without pumping a screen.
@immutable
class TransactionFormData {
  const TransactionFormData({
    this.type = TransactionType.expense,
    this.amountText = '',
    this.category = '',
    this.description = '',
    this.date,
  });

  final TransactionType type;
  final String amountText;
  final String category;
  final String description;

  /// Chosen date; the screen falls back to "today" when null.
  final DateTime? date;

  TransactionFormData copyWith({
    TransactionType? type,
    String? amountText,
    String? category,
    String? description,
    DateTime? date,
  }) {
    return TransactionFormData(
      type: type ?? this.type,
      amountText: amountText ?? this.amountText,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
    );
  }

  /// Parsed amount in đồng, or `null` when blank/non-numeric. Thousands dots and
  /// spaces are stripped so "1.200.000" and "1200000" both parse.
  double? get parsedAmount {
    final cleaned = amountText.replaceAll('.', '').replaceAll(' ', '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// Field-keyed validation errors. An empty map means the form is valid.
  Map<TransactionField, String> validate() {
    final errors = <TransactionField, String>{};
    final amount = parsedAmount;
    if (amount == null || amount <= 0) {
      errors[TransactionField.amount] = 'Nhập số tiền hợp lệ (> 0)';
    }
    if (category.trim().isEmpty) {
      errors[TransactionField.category] = 'Chọn hoặc nhập nhóm';
    }
    return errors;
  }

  bool get isValid => validate().isEmpty;

  /// Builds the domain transaction. Only call when [isValid]; [id] is supplied
  /// by the caller and [fallbackDate] stands in for a null [date].
  FinanceTransaction toTransaction({
    required String id,
    required DateTime fallbackDate,
  }) {
    return FinanceTransaction(
      id: id,
      type: type,
      category: FinanceCategory.fromStorage(category.trim()),
      categoryNote: FinanceCategory.noteFor(category.trim()),
      amount: parsedAmount!,
      date: date ?? fallbackDate,
      description: description.trim(),
    );
  }
}
