import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/l10n/app_strings.dart';
import 'package:tongtai/features/tongtai/finance/finance_category.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/finance/transaction_form.dart';
import 'package:tongtai/features/tongtai/producer/business_input.dart';

/// WTM-236 — sổ thu chi có chỗ cho chi phí đầu vào.
///
/// Dogfood lần 1: chi phí AI provider, hạ tầng, công cụ — **toàn bộ** đầu vào
/// của một doanh nghiệp AI-first — rơi hết vào `other`, nên "lãi lỗ theo nhóm"
/// gộp mọi thứ vào một ô "Khác" và không nói được tiền đi đâu.
void main() {
  group('vựng từ chi phí đủ chỗ cho đầu vào', () {
    test('ba mã mới đọc được, và là MÃ chứ không phải nhãn', () {
      expect(
        FinanceCategory.fromStorage('infrastructure'),
        FinanceCategory.infrastructure,
      );
      expect(FinanceCategory.fromStorage('tooling'), FinanceCategory.tooling);
      expect(FinanceCategory.fromStorage('provider'), FinanceCategory.provider);
    });

    test('mã cũ KHÔNG đổi — sổ đã ghi không được mất nhóm', () {
      // Đổi một mã là mọi khoản đã ghi mất nhóm khi khôi phục (ADR-TON-018).
      for (final pair in const [
        ('product_cost', FinanceCategory.productCost),
        ('platform_fee', FinanceCategory.platformFee),
        ('shipping', FinanceCategory.shipping),
        ('staff', FinanceCategory.staff),
        ('marketing', FinanceCategory.marketing),
        ('rent', FinanceCategory.rent),
        ('sales', FinanceCategory.sales),
        ('other', FinanceCategory.other),
      ]) {
        expect(FinanceCategory.fromStorage(pair.$1), pair.$2);
      }
    });

    test('nhãn tiếng Việt của bản cũ vẫn đọc được', () {
      // Sổ của người bán từ trước WTM-197 vẫn là sổ của họ.
      expect(
        FinanceCategory.fromStorage('Nhập hàng'),
        FinanceCategory.productCost,
      );
      expect(
        FinanceCategory.fromStorage('Thuê mặt bằng'),
        FinanceCategory.rent,
      );
    });

    test('mỗi nhóm có một nhãn RIÊNG ở cả hai ngôn ngữ', () {
      // Một mã mới quên nhãn sẽ mượn nhãn của nhóm khác mà không gì báo —
      // đúng lỗi `_ => 'Bán sỉ'` của WTM-232.
      for (final strings in [AppStringsVi(), AppStringsEn()]) {
        final labels = {
          for (final c in FinanceCategory.values)
            financeCategoryCodeLabel(c.code, strings),
        };
        expect(
          labels.length,
          FinanceCategory.values.length,
          reason: 'thiếu nhãn cho một nhóm: ${strings.languageCode}',
        );
      }
    });
  });

  group('mỗi loại nguồn đầu vào có một nhóm chi phí', () {
    test('ánh xạ TOÀN PHẦN — không loại nào rơi vào "Khác"', () {
      // Rơi vào "Khác" chính là vấn đề dogfood tìm ra.
      for (final kind in BusinessInputKind.values) {
        expect(
          kind.financeCategory,
          isNot(FinanceCategory.other),
          reason: 'loại ${kind.code} chưa có nhóm chi phí',
        );
      }
    });

    test('hai loại đã có nhóm từ trước dùng lại nhóm cũ', () {
      // Nhà cung cấp hàng hoá là tiền nhập hàng; người là chi phí nhân sự.
      // Tạo nhóm mới cho chúng sẽ chia đôi cùng một khoản chi.
      expect(
        BusinessInputKind.supplier.financeCategory,
        FinanceCategory.productCost,
      );
      expect(BusinessInputKind.people.financeCategory, FinanceCategory.staff);
    });

    test('ba loại còn lại dùng CHUNG MÃ với nhóm chi phí', () {
      // Hai vựng từ song song sẽ lệch ngay lần đầu ai đó thêm loại ở một bên
      // (P-27). Dùng chung mã thì không có gì để lệch.
      for (final kind in const [
        BusinessInputKind.provider,
        BusinessInputKind.infrastructure,
        BusinessInputKind.tooling,
      ]) {
        expect(kind.financeCategory.code, kind.code);
      }
    });
  });

  group('chip chọn nhóm suy từ vựng từ, không chép tay', () {
    test('chi phí nhân sự nay CHỌN ĐƯỢC', () {
      // Danh sách chép tay cũ bỏ sót `staff`: enum có, người bán không bao giờ
      // chọn được — một nhóm tồn tại trong code mà không tồn tại với họ.
      expect(
        transactionCategories(TransactionType.expense),
        contains(FinanceCategory.staff),
      );
    });

    test('mọi nhóm chi đều có mặt, và "Khác" nằm cuối', () {
      final expense = transactionCategories(TransactionType.expense);

      expect(
        expense.toSet(),
        FinanceCategory.values.where((c) => !c.isIncome).toSet(),
      );
      expect(expense.last, FinanceCategory.other);
    });

    test('nhóm THU không lẫn nhóm chi', () {
      final income = transactionCategories(TransactionType.income);

      expect(income, contains(FinanceCategory.sales));
      expect(income, isNot(contains(FinanceCategory.productCost)));
    });

    test('chip lưu MÃ, nên đổi ngôn ngữ không đổi thứ ghi xuống sổ', () {
      // Trước đây chip lưu đúng chuỗi tiếng Việt đang hiện, nên bản tiếng Anh
      // ghi nhãn tiếng Việt xuống sổ của người dùng.
      const form = TransactionFormData(
        type: TransactionType.expense,
        amountText: '500000',
        category: 'infrastructure',
      );

      final txn = form.toTransaction(
        id: 't1',
        fallbackDate: DateTime(2026, 8, 2),
      );

      expect(txn.category, FinanceCategory.infrastructure);
      expect(
        txn.categoryNote,
        isEmpty,
        reason: 'mã hiểu được thì không có chữ nào của người bán để giữ',
      );
    });

    test('người bán tự gõ nhóm riêng thì lời họ được giữ', () {
      const form = TransactionFormData(
        type: TransactionType.expense,
        amountText: '500000',
        category: 'Tiền điện tháng 7',
      );

      final txn = form.toTransaction(
        id: 't1',
        fallbackDate: DateTime(2026, 8, 2),
      );

      expect(txn.category, FinanceCategory.other);
      expect(txn.categoryNote, 'Tiền điện tháng 7');
    });
  });
}
