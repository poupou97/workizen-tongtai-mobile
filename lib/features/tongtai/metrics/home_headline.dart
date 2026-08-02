/// What Home's opening line says (WTM-221).
///
/// The Concept opens Home with the app talking to the seller — *"Hôm nay tôi
/// tìm được 12 cơ hội cho bạn"* — instead of a row of numbers they must read
/// for themselves. That sentence is only worth anything if it is **true**, so
/// the choice of which sentence to say is a rule, not a string in a widget.
enum HomeHeadlineKind {
  /// The rule engine found work worth surfacing. Carries the real count.
  opportunities,

  /// The business has data and the rules looked — nothing stands out today.
  /// A real answer, not a failure (ADR-TON-017's `empty`).
  noneToday,

  /// There is not enough business here to look at yet. Saying "0 cơ hội" would
  /// read as a verdict on the seller's business instead of on their data —
  /// the `insufficient` state, and the difference matters on the very first
  /// screen a new user sees.
  notEnoughData,
}

/// Picks Home's opening line from two truths the app already owns: how many
/// opportunities the **rule engine** produced (never an AI call — Home must
/// render with no key and no network, ADR-TON-016) and whether the business
/// has any data at all (`BusinessContext.hasData`, the owner).
HomeHeadlineKind homeHeadlineKind({
  required int opportunityCount,
  required bool hasData,
}) {
  if (opportunityCount > 0) return HomeHeadlineKind.opportunities;
  return hasData ? HomeHeadlineKind.noneToday : HomeHeadlineKind.notEnoughData;
}
