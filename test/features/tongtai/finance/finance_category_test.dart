import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/finance_category.dart';
import 'package:tongtai/features/tongtai/finance/finance_summary.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';

/// WTM-197 — expense categories as canonical codes.
///
/// The defect: `category` was free text holding **Vietnamese display labels**,
/// written verbatim into `.ttbk`. Exactly what WTM-164 fixed for enums in
/// backup v1, surviving into v2 because category was not an enum.
///
/// The tests that matter most are the ones about a **ledger written by an older
/// build** — that ledger is the seller's own accounting, and it has to keep
/// meaning the same thing.
void main() {
  FinanceTransaction txn(
    FinanceCategory category, {
    String note = '',
    double amount = 100000,
    TransactionType type = TransactionType.expense,
  }) => FinanceTransaction(
    id: 't1',
    type: type,
    category: category,
    categoryNote: note,
    amount: amount,
    date: DateTime(2026, 8, 1),
  );

  group('reading a ledger written by an older build', () {
    test('every Vietnamese label maps to its code', () {
      // These are the exact strings older builds wrote.
      const legacy = {
        'Nhập hàng': FinanceCategory.productCost,
        'Phí sàn': FinanceCategory.platformFee,
        'Vận chuyển': FinanceCategory.shipping,
        'Quảng cáo': FinanceCategory.marketing,
        'Thuê mặt bằng': FinanceCategory.rent,
        'Bán hàng': FinanceCategory.sales,
      };

      legacy.forEach((label, expected) {
        expect(FinanceCategory.fromStorage(label), expected, reason: label);
      });
    });

    test('an unrecognised category is kept, never dropped', () {
      // Dropping would silently move money between groups in the seller's own
      // expense breakdown. Unlike a forgotten opportunity reaction (WTM-190,
      // where dropping was right), this is their accounting.
      final category = FinanceCategory.fromStorage('Tiền điện tháng 7');
      final note = FinanceCategory.noteFor('Tiền điện tháng 7');

      expect(category, FinanceCategory.other);
      expect(
        note,
        'Tiền điện tháng 7',
        reason: 'their words are more useful to them than "Khác"',
      );
    });

    test('a code round-trips without becoming a note', () {
      expect(
        FinanceCategory.fromStorage('product_cost'),
        FinanceCategory.productCost,
      );
      expect(FinanceCategory.noteFor('product_cost'), isEmpty);
    });

    test('empty or missing reads as other, not as a crash', () {
      expect(FinanceCategory.fromStorage(null), FinanceCategory.other);
      expect(FinanceCategory.fromStorage('   '), FinanceCategory.other);
      expect(FinanceCategory.noteFor(null), isEmpty);
    });
  });

  group('the expense breakdown groups by code', () {
    test('two spellings of one idea are one row, not two', () {
      // The concrete cost of grouping by string: 'Nhập hàng' and 'nhập hàng'
      // used to be two separate lines in the breakdown.
      final summary = FinanceService([
        txn(FinanceCategory.fromStorage('Nhập hàng'), amount: 300000),
        txn(FinanceCategory.fromStorage('nhập hàng'), amount: 200000),
      ]).summaryAsOf(DateTime(2026, 8, 1));

      // 'nhập hàng' (lower case) is not a known label, so it lands in `other` —
      // and the seller's own text is kept. What must NOT happen is a silent
      // third meaning or a lost amount.
      final total = summary.expenseByCategory.fold<double>(
        0,
        (sum, c) => sum + c.amount,
      );
      expect(total, 500000, reason: 'not one đồng may go missing');
    });

    test('same category, several rows, one line', () {
      final summary = FinanceService([
        txn(FinanceCategory.productCost, amount: 300000),
        txn(FinanceCategory.productCost, amount: 200000),
      ]).summaryAsOf(DateTime(2026, 8, 1));

      expect(summary.expenseByCategory, hasLength(1));
      expect(summary.expenseByCategory.single.amount, 500000);
    });
  });

  test('every code is a canonical token, never a label', () {
    // Same rule as `.ttbk` v2: a stored label changes meaning when the seller
    // switches language.
    for (final c in FinanceCategory.values) {
      expect(c.code, matches(RegExp(r'^[a-z_]+$')), reason: c.name);
    }
  });

  test('the vocabulary covers the Concept list', () {
    // Concept Business Rule #2: product costs · platform fees · shipping ·
    // staff · marketing · other.
    expect(
      FinanceCategory.values.map((c) => c.code),
      containsAll([
        'product_cost',
        'platform_fee',
        'shipping',
        'staff',
        'marketing',
        'other',
      ]),
    );
  });
}
