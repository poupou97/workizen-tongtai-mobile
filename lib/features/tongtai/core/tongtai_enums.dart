// Domain enums + bilingual (EN/VI) label mappers for Tổng Tài (WTM-60).
//
// Statuses are stored as plain strings in the SQLite schema (WTM-51). These
// mappers turn those strings into type-safe enums and localized labels so
// screens never hard-code status text.

/// Sales order lifecycle.
enum OrderStatus {
  pending,
  confirmed,
  shipped,
  delivered,
  cancelled;

  /// Parse a stored string; unknown/absent values map to [pending].
  static OrderStatus fromStorage(String? value) {
    return OrderStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => OrderStatus.pending,
    );
  }

  String get labelEn => switch (this) {
    OrderStatus.pending => 'Pending',
    OrderStatus.confirmed => 'Confirmed',
    OrderStatus.shipped => 'Shipped',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.cancelled => 'Cancelled',
  };

  String get labelVi => switch (this) {
    OrderStatus.pending => 'Chờ xử lý',
    OrderStatus.confirmed => 'Đã xác nhận',
    OrderStatus.shipped => 'Đang giao',
    OrderStatus.delivered => 'Đã giao',
    OrderStatus.cancelled => 'Đã hủy',
  };

  /// Label for a language code ('vi' -> Vietnamese, otherwise English).
  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// Business Journey progress state.
enum JourneyStatus {
  notStarted,
  inProgress,
  blocked,
  done;

  static JourneyStatus fromStorage(String? value) {
    return JourneyStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => JourneyStatus.notStarted,
    );
  }

  String get labelEn => switch (this) {
    JourneyStatus.notStarted => 'Not started',
    JourneyStatus.inProgress => 'In progress',
    JourneyStatus.blocked => 'Blocked',
    JourneyStatus.done => 'Done',
  };

  String get labelVi => switch (this) {
    JourneyStatus.notStarted => 'Chưa bắt đầu',
    JourneyStatus.inProgress => 'Đang thực hiện',
    JourneyStatus.blocked => 'Bị chặn',
    JourneyStatus.done => 'Hoàn thành',
  };

  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// AI-discovered opportunity category.
enum OpportunityType {
  arbitrage,
  seasonal,
  crossBorder,
  trend;

  static OpportunityType fromStorage(String? value) {
    return OpportunityType.values.firstWhere(
      (s) => s.name == value,
      orElse: () => OpportunityType.trend,
    );
  }

  String get labelEn => switch (this) {
    OpportunityType.arbitrage => 'Arbitrage',
    OpportunityType.seasonal => 'Seasonal',
    OpportunityType.crossBorder => 'Cross-border',
    OpportunityType.trend => 'Trend',
  };

  String get labelVi => switch (this) {
    OpportunityType.arbitrage => 'Chênh lệch giá',
    OpportunityType.seasonal => 'Theo mùa',
    OpportunityType.crossBorder => 'Xuyên biên giới',
    OpportunityType.trend => 'Xu hướng',
  };

  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// Financial transaction direction (WTM-27) — money in vs. money out. Stored as
/// a plain string in the `transactions` table `type` column.
enum TransactionType {
  income,
  expense;

  /// Parse a stored string; unknown/absent values map to [expense] (the
  /// conservative default — an unclassified outflow rather than phantom income).
  static TransactionType fromStorage(String? value) {
    return TransactionType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => TransactionType.expense,
    );
  }

  String get labelEn => switch (this) {
    TransactionType.income => 'Income',
    TransactionType.expense => 'Expense',
  };

  String get labelVi => switch (this) {
    TransactionType.income => 'Thu',
    TransactionType.expense => 'Chi',
  };

  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}
