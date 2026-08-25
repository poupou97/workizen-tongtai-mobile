// Domain enums + bilingual (EN/VI) label mappers for Tổng Tài (WTM-60).
//
// Statuses are stored as plain strings in the SQLite schema (WTM-51). These
// mappers turn those strings into type-safe enums and localized labels so
// screens never hard-code status text.
//
// ## Decode discipline (WTM-457 · ADR-TON-018)
//
// An unrecognised stored code is a **corrupt/unknown record**, never a business
// default. The v1 enums here used to decode garbage to a real value
// (`OrderStatus.pending`, `TransactionType.expense`, `JourneyStatus.notStarted`,
// `OpportunityType.trend`) — a delivered order silently read as "pending", an
// income row as "expense". That is the exact lie the new enums
// (`ProvenanceSource`, `SalesChannel`, `SettlementKind`, …) were built to
// forbid. Two honest shapes, chosen **per enum**:
//
//   * a nullable `fromStorage` returning `null` — where nothing forces a
//     non-null value and there is no production decode path (`JourneyStatus`,
//     `OpportunityType`); and
//   * an explicit `unknown` value — where the field is non-nullable and read in
//     dozens of places, so a nullable return would ripple everywhere and a
//     dropped record would vanish silently (`OrderStatus`, `TransactionType`).
//     Same pattern as `SettlementKind.unknown`/`FundingSource.unknown`.
//
// The `enum_decode_no_business_default_gate_test` locks this so a future edit
// cannot quietly point an `orElse` back at a real business value.

/// Sales order lifecycle.
enum OrderStatus {
  pending,
  confirmed,
  shipped,
  delivered,
  cancelled,

  /// A stored status this build does not recognise — a **corrupt/unknown
  /// record**, surfaced rather than disguised (WTM-457 · ADR-TON-018).
  ///
  /// `fromStorage` decodes here instead of to [pending] because [status] on
  /// [CustomerOrder] is non-nullable and read across dozens of screens,
  /// filters, reports and the `.ttbk` codec: a nullable return would ripple
  /// everywhere, and dropping the row would erase an order the seller has with
  /// no trace. Keeping it as [unknown] leaves the order **visible and honestly
  /// labelled** ("Unrecognized") instead of masquerading as an actionable
  /// `pending` the seller might try to fulfil. It is never a value a seller can
  /// pick — see [selectable].
  unknown;

  /// The statuses a seller may actually choose for an order.
  ///
  /// [unknown] is a decode marker, not a lifecycle state, so it must never
  /// appear in a picker — mirrors `OpportunityType.visible`.
  static const List<OrderStatus> selectable = [
    pending,
    confirmed,
    shipped,
    delivered,
    cancelled,
  ];

  /// Parse a stored string; an unrecognised or absent code decodes to
  /// [unknown], never to a real lifecycle state (WTM-457 · ADR-TON-018).
  static OrderStatus fromStorage(String? value) {
    return OrderStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => OrderStatus.unknown,
    );
  }

  String get labelEn => switch (this) {
    OrderStatus.pending => 'Pending',
    OrderStatus.confirmed => 'Confirmed',
    OrderStatus.shipped => 'Shipped',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.cancelled => 'Cancelled',
    OrderStatus.unknown => 'Unrecognized',
  };

  String get labelVi => switch (this) {
    OrderStatus.pending => 'Chờ xử lý',
    OrderStatus.confirmed => 'Đã xác nhận',
    OrderStatus.shipped => 'Đang giao',
    OrderStatus.delivered => 'Đã giao',
    OrderStatus.cancelled => 'Đã hủy',
    OrderStatus.unknown => 'Không nhận ra',
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

  /// Parse a stored string; an unrecognised or absent code returns `null`
  /// (WTM-457 · ADR-TON-018).
  ///
  /// Nullable rather than an explicit `unknown` value because there is **no
  /// production decode path** — nothing in `lib/` reads a journey status back
  /// from storage today (progress is derived, not persisted as this enum), so
  /// no non-nullable field forces a value. `null` is the honest result, and any
  /// caller that ever does decode must then handle the corrupt code explicitly
  /// instead of inheriting a silent `notStarted`.
  static JourneyStatus? fromStorage(String? value) {
    for (final s in JourneyStatus.values) {
      if (s.name == value) return s;
    }
    return null;
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

  /// Types the rule engine can actually produce from on-device data today
  /// (WTM-182, Founder Decision 2026-08-01: *"Giữ Domain. Ẩn Capability chưa
  /// có dữ liệu."*).
  ///
  /// `arbitrage` compares prices across two marketplaces and `crossBorder`
  /// needs foreign pricing — both require data that does not exist on the
  /// device (they arrive with File Bridge, WTM-181). The rule engine emits
  /// only `trend` and `seasonal`, so showing the other two gives the seller a
  /// filter that returns nothing, for ever.
  ///
  /// **The enum keeps all four on purpose.** Theme, action plans, `.ttbk`
  /// codec and sample data all stay intact — only presentation filters. When
  /// the data source arrives, turning them back on is editing this one list.
  static const List<OpportunityType> visible = [seasonal, trend];

  /// Whether this type is shown to the seller today. See [visible].
  bool get isVisible => visible.contains(this);

  /// Parse a stored string; an unrecognised or absent code returns `null`
  /// (WTM-457 · ADR-TON-018).
  ///
  /// Nullable rather than an explicit `unknown` value because opportunities are
  /// **generated by the rule engine, never decoded from storage** in production
  /// (only the seller's [OpportunityReaction] is persisted, WTM-190) — so no
  /// non-nullable field forces a value here. Defaulting garbage to `trend` used
  /// to invent a category the seller was told an AI had "discovered".
  static OpportunityType? fromStorage(String? value) {
    for (final t in OpportunityType.values) {
      if (t.name == value) return t;
    }
    return null;
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
  expense,

  /// A stored type this build does not recognise — a **corrupt/unknown
  /// record**, surfaced rather than counted (WTM-457 · ADR-TON-018).
  ///
  /// `fromStorage` decodes here instead of to [expense] because [type] on
  /// `FinanceTransaction` is non-nullable and drives the money math: the old
  /// "conservative" default silently turned a corrupt income row into an
  /// expense, understating the seller's own revenue. An [unknown] transaction
  /// stays **visible in the ledger** ("Unrecognized") but is counted as neither
  /// income nor expense — you cannot total money you cannot classify
  /// (`isIncome`/`isExpense` are both false; the summary's `_sum` filters by an
  /// exact type, so it is excluded from both). Same pattern as
  /// `SettlementKind.unknown`/`FundingSource.unknown`.
  unknown;

  /// Parse a stored string; an unrecognised or absent code decodes to
  /// [unknown], never to a real direction (WTM-457 · ADR-TON-018).
  static TransactionType fromStorage(String? value) {
    return TransactionType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => TransactionType.unknown,
    );
  }

  String get labelEn => switch (this) {
    TransactionType.income => 'Income',
    TransactionType.expense => 'Expense',
    TransactionType.unknown => 'Unrecognized',
  };

  String get labelVi => switch (this) {
    TransactionType.income => 'Thu',
    TransactionType.expense => 'Chi',
    TransactionType.unknown => 'Không nhận ra',
  };

  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}
