/// What a transaction was for, as a **canonical code** (WTM-197).
///
/// ## The defect this replaces
/// `FinanceTransaction.category` was a free-text `String`, and the values were
/// **Vietnamese display labels** — `'Nhập hàng'`, `'Phí sàn'`, `'Thuê mặt
/// bằng'`. `BackupCodec` wrote them into `.ttbk` verbatim.
///
/// That is exactly the defect WTM-164 fixed for enums in backup v1 — *an enum
/// stored as its display label* — and it **survived into v2** because category
/// was not an enum, so it never came under ADR-TON-018's review.
///
/// What it cost:
/// - switch language and the old rows stay Vietnamese while new ones do not,
///   so one idea becomes two groups;
/// - a typo or different capitalisation makes a new group, because
///   `expenseByCategory` grouped **by string**: `'Nhập hàng'` and `'nhập hàng'`
///   were two rows in the expense breakdown;
/// - no reliable expense analysis across devices or across a restore.
///
/// ## The vocabulary
/// Concept Business Rule #2 asks for a closed list: *product costs · platform
/// fees · shipping · staff · marketing · other*. [rent] is added because it is
/// what the seed data and Vietnamese SMEs actually use, and folding rent into
/// "other" would hide the second-largest cost most shops have.
///
/// ## Migration without touching stored rows
/// Legacy labels are mapped **at read time** by [FinanceCategory.fromStorage],
/// not rewritten by a migration. Rewriting rows would be a data mutation on the
/// seller's own ledger for no benefit they can see, and it would break any
/// `.ttbk` written before the change. Reading is where the ambiguity actually
/// has to be resolved, so that is where it is resolved.
library;

import '../../../core/l10n/app_strings.dart';
import 'finance_transaction.dart';

enum FinanceCategory {
  /// Buying stock. The biggest expense line for most sellers.
  productCost('product_cost'),

  /// Marketplace commission and payment fees.
  platformFee('platform_fee'),

  shipping('shipping'),

  staff('staff'),

  marketing('marketing'),

  /// Rent and utilities — not in the Concept's list, but it is what the data
  /// shows, and burying it in [other] would hide a major cost.
  rent('rent'),

  /// Hạ tầng chạy nền: máy chủ, lưu trữ, tên miền (WTM-236).
  ///
  /// Ba mã dưới đây dùng **đúng mã của `BusinessInputKind`** (ADR-TON-023) chứ
  /// không đặt tên riêng: một nguồn đầu vào và khoản tiền trả cho nó là hai
  /// mặt của cùng một sự việc, và hai vựng từ song song sẽ lệch ngay lần đầu
  /// ai đó thêm loại ở một bên — đúng họ lỗi P-27.
  infrastructure('infrastructure'),

  /// Phần mềm dùng để làm việc: thuê bao theo chỗ ngồi.
  tooling('tooling'),

  /// Dịch vụ trả theo mức dùng: token AI, cổng thanh toán, băng thông.
  provider('provider'),

  /// Income the seller entered by hand. Sales revenue itself is **derived from
  /// orders** (WTM-196) and never stored as a transaction.
  sales('sales'),

  /// Anything outside the list. Carries the seller's own words in
  /// `FinanceTransaction.categoryNote` rather than throwing them away.
  other('other');

  const FinanceCategory(this.code);

  /// Canonical code — never a display label (ADR-TON-018), safe for telemetry.
  final String code;

  /// Vietnamese labels written by older builds, mapped to their code.
  ///
  /// Kept forever: a seller's ledger from before WTM-197 is still their ledger,
  /// and a `.ttbk` from that build must restore with its categories intact.
  static const Map<String, FinanceCategory> _legacyLabels = {
    'Nhập hàng': FinanceCategory.productCost,
    'Phí sàn': FinanceCategory.platformFee,
    'Vận chuyển': FinanceCategory.shipping,
    'Quảng cáo': FinanceCategory.marketing,
    'Thuê mặt bằng': FinanceCategory.rent,
    'Bán hàng': FinanceCategory.sales,
  };

  /// Reads a stored value: a code, a legacy Vietnamese label, or something
  /// nobody recognises.
  ///
  /// Unknown text becomes [other] — **never dropped**. Losing a category would
  /// silently move money between groups in the expense breakdown, and unlike a
  /// forgotten opportunity reaction (WTM-190, where dropping was right) this is
  /// the seller's own accounting.
  static FinanceCategory fromStorage(String? raw) {
    if (raw == null || raw.trim().isEmpty) return FinanceCategory.other;
    final value = raw.trim();
    for (final c in FinanceCategory.values) {
      if (c.code == value) return c;
    }
    return _legacyLabels[value] ?? FinanceCategory.other;
  }

  /// The seller's own words to keep when [fromStorage] could not place [raw].
  ///
  /// Empty when the value was understood — there is nothing to preserve then.
  static String noteFor(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final value = raw.trim();
    return fromStorage(value) == FinanceCategory.other &&
            value != FinanceCategory.other.code
        ? value
        : '';
  }

  bool get isIncome => this == FinanceCategory.sales;
}

/// The label a seller reads for a stored category **code**.
///
/// The breakdown card groups by code (WTM-197), so without this it would print
/// `product_cost` at the seller — codes are for storage, never for eyes.
String financeCategoryCodeLabel(String code, AppStrings l10n) =>
    _labelFor(FinanceCategory.fromStorage(code), l10n);

String _labelFor(FinanceCategory category, AppStrings l10n) =>
    switch (category) {
      FinanceCategory.productCost => l10n.finCatProductCost,
      FinanceCategory.platformFee => l10n.finCatPlatformFee,
      FinanceCategory.shipping => l10n.finCatShipping,
      FinanceCategory.staff => l10n.finCatStaff,
      FinanceCategory.marketing => l10n.finCatMarketing,
      FinanceCategory.rent => l10n.finCatRent,
      FinanceCategory.infrastructure => l10n.finCatInfrastructure,
      FinanceCategory.tooling => l10n.finCatTooling,
      FinanceCategory.provider => l10n.finCatProvider,
      FinanceCategory.sales => l10n.finCatSales,
      FinanceCategory.other => l10n.finCatOther,
    };

/// The label a seller reads for [transaction]'s category.
///
/// Codes are stored, labels are looked up — the split ADR-TON-018 asks for. When
/// the category is [FinanceCategory.other] and the seller wrote their own words,
/// **their words win**: "Tiền điện tháng 7" tells them more than "Khác".
String financeCategoryLabel(FinanceTransaction transaction, AppStrings l10n) {
  if (transaction.categoryNote.isNotEmpty) return transaction.categoryNote;
  return _labelFor(transaction.category, l10n);
}
