import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/transaction_form.dart';

/// WTM-113 — the transaction form's pure validation + conversion.
void main() {
  group('TransactionFormData.validate', () {
    test('a blank form reports amount and category errors', () {
      final errors = const TransactionFormData().validate();
      expect(errors[TransactionField.amount], isNotNull);
      expect(errors[TransactionField.category], isNotNull);
    });

    test('zero or negative amount is rejected', () {
      expect(
        const TransactionFormData(
          amountText: '0',
          category: 'Nhập hàng',
        ).validate()[TransactionField.amount],
        isNotNull,
      );
    });

    test('a positive amount with a category is valid', () {
      const data = TransactionFormData(
        amountText: '1500000',
        category: 'Nhập hàng',
      );
      expect(data.isValid, isTrue);
      expect(data.validate(), isEmpty);
    });

    test('thousands dots are stripped when parsing the amount', () {
      const data = TransactionFormData(amountText: '1.500.000');
      expect(data.parsedAmount, 1500000);
    });
  });

  group('TransactionFormData.toTransaction', () {
    test('builds the domain transaction, trimming text', () {
      const data = TransactionFormData(
        type: TransactionType.income,
        amountText: '2000000',
        category: '  Bán hàng  ',
        description: '  Bán sỉ  ',
      );
      final txn = data.toTransaction(
        id: 't1',
        fallbackDate: DateTime(2026, 7, 24),
      );

      expect(txn.id, 't1');
      expect(txn.type, TransactionType.income);
      expect(txn.amount, 2000000);
      expect(txn.category, 'Bán hàng');
      expect(txn.description, 'Bán sỉ');
      expect(txn.date, DateTime(2026, 7, 24));
    });

    test('uses the chosen date over the fallback', () {
      const data = TransactionFormData(
        amountText: '100000',
        category: 'Khác',
        date: null,
      );
      final withDate = data.copyWith(date: DateTime(2026, 6, 1));
      final txn = withDate.toTransaction(
        id: 't2',
        fallbackDate: DateTime(2026, 7, 24),
      );
      expect(txn.date, DateTime(2026, 6, 1));
    });
  });
}
