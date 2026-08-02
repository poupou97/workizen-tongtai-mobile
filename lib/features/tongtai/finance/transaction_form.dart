import 'finance_category.dart';
import 'package:flutter/foundation.dart';

import '../core/tongtai_enums.dart';
import 'finance_transaction.dart';

/// Validation fields for the transaction form (WTM-113).
enum TransactionField { amount, category }

/// Nhóm gợi ý cho mỗi chiều tiền, **suy từ vựng từ** (WTM-236).
///
/// Trước đây là hai danh sách **nhãn tiếng Việt chép tay**. Ba hệ quả, cả ba
/// đều thật: người bán không bao giờ chọn được `staff` (enum có, danh sách
/// không); bản tiếng Anh hiện chip tiếng Việt — mà lưới l10n chỉ quét `ui/`
/// nên mù với file này (P-23/P-29: governance chỉ bắt thứ nó được viết để
/// tìm); và mỗi mã thêm vào enum lại phải nhớ sửa tay ở đây (P-31).
///
/// Nay suy thẳng: chi = mọi nhóm **trừ** nhóm thu; thu = bán hàng + khác. Thứ
/// tự lấy theo thứ tự khai trong enum, nên `other` vẫn nằm cuối.
List<FinanceCategory> transactionCategories(TransactionType type) =>
    type == TransactionType.income
    ? const [FinanceCategory.sales, FinanceCategory.other]
    : [
        for (final c in FinanceCategory.values)
          if (!c.isIncome) c,
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
