import 'package:drift/drift.dart';

/// AI Business Profile — what kind of business this is (WTM-177).
///
/// The AI already sees *the seller's numbers*; it has never known *who the
/// seller is*. Advice stayed generic because a boutique with 40 SKUs and a
/// wholesale importer with 4,000 got the same prompt.
///
/// ## One row, always
/// A device runs one business (ADR-TON-008: Local Business is the root
/// aggregate), so this table holds **at most one row**, pinned to [id] = `1`.
/// That is deliberate: no "which profile" question can ever arise, and an
/// upsert cannot silently create a second one.
///
/// ## Why every column is nullable
/// The profile is optional and skippable. A seller who taps past it must get a
/// working app, so "not answered" has to be representable — and it must be
/// distinguishable from "answered with nothing". `null` is the former.
///
/// ## The privacy rule that shapes this table
/// The profile is injected into **every AI prompt**, which means in BYOK mode
/// it leaves the device on every question. So it may only ever hold
/// **categorical facts about the business** — trade, size, seasonality,
/// channels.
///
/// **It must never hold personal data**: no owner name, no phone, no address,
/// no email, no customer names, no revenue figures. There is a negative-control
/// test that fails if a column capable of carrying those appears here
/// (`tongtai_business_profile_privacy_test.dart`).
///
/// That is why there is no free-text "notes" column, which is the obvious thing
/// to add and the exact thing that would break the promise: a notes field is
/// where a seller writes "chị Lan 0909…" and it would be shipped to an AI
/// provider on every question thereafter.
class BusinessProfilesTable extends Table {
  /// Always `1`. See the class doc — one device, one business, one row.
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// What the business sells, as a canonical code (e.g. `fashion`, `food`).
  /// Stored as a **code**, never a display label — same rule as `.ttbk` v2
  /// (ADR-TON-018): labels are localized and would break the moment the seller
  /// switches language.
  /// Loại hình vận hành bằng **mã canonical** `BusinessType` (v15,
  /// ADR-TON-023). `NULL` = **chưa khai** — cố ý không mặc định `physical`:
  /// người bán có sẵn chưa từng được hỏi câu này.
  TextColumn get typeCode => text().nullable()();

  TextColumn get tradeCode => text().nullable()();

  /// Rough size band, canonical code (e.g. `solo`, `small`, `growing`).
  TextColumn get sizeCode => text().nullable()();

  /// Where they sell, canonical codes joined by `,` (e.g. `shop,shopee`).
  /// A joined list rather than a child table because it is a short fixed
  /// vocabulary read as a whole — promote it per ADR-TON-009 only if a real
  /// query needs it.
  TextColumn get channelCodes => text().nullable()();

  /// Whether the trade is seasonal, canonical code (e.g. `none`, `tet`).
  TextColumn get seasonalityCode => text().nullable()();

  /// When the seller last edited the profile. Drives "your profile is stale"
  /// prompts later; also lets a restore keep the newer of two profiles.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
