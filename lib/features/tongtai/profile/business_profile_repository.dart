import 'package:drift/drift.dart';

import '../../../database/database.dart';
import 'business_profile.dart';

/// Reads and writes the single [BusinessProfile] row (WTM-177).
///
/// One device, one business (ADR-TON-008), so this repository never takes an
/// id: [load] returns the profile or [BusinessProfile.empty], and [save]
/// upserts row `1`. There is no "create" and no "delete profile" — clearing
/// every answer is just a save of an empty profile, which keeps the write path
/// single.
class BusinessProfileRepository {
  BusinessProfileRepository(this._db);

  final AppDatabase _db;

  /// The pinned row id. See [BusinessProfilesTable].
  static const int _rowId = 1;

  /// Returns the stored profile, or [BusinessProfile.empty] when the seller has
  /// never answered. **Never throws on unknown codes** — an unrecognised code
  /// reads as `null` for that field (see [BusinessTrade.fromCode]), so a row
  /// written by a newer build degrades to partial information instead of
  /// failing the whole load.
  Future<BusinessProfile> load() async {
    final row = await (_db.select(
      _db.businessProfilesTable,
    )..where((t) => t.id.equals(_rowId))).getSingleOrNull();
    if (row == null) return BusinessProfile.empty;
    return BusinessProfile(
      type: BusinessType.fromCode(row.typeCode),
      trade: BusinessTrade.fromCode(row.tradeCode),
      size: BusinessSize.fromCode(row.sizeCode),
      channels: BusinessProfile.channelsFromCodes(row.channelCodes),
      seasonality: BusinessSeasonality.fromCode(row.seasonalityCode),
      updatedAt: row.updatedAt,
    );
  }

  /// Upserts the profile. [now] is injected so tests are deterministic.
  Future<void> save(BusinessProfile profile, {DateTime? now}) async {
    await _db
        .into(_db.businessProfilesTable)
        .insertOnConflictUpdate(
          BusinessProfilesTableCompanion.insert(
            id: const Value(_rowId),
            typeCode: Value(profile.type?.code),
            tradeCode: Value(profile.trade?.code),
            sizeCode: Value(profile.size?.code),
            channelCodes: Value(profile.channelCodes),
            seasonalityCode: Value(profile.seasonality?.code),
            updatedAt: now ?? DateTime.now(),
          ),
        );
  }

  /// Removes the profile row entirely. Used by restore (Replace semantics,
  /// ADR-TON-018) — **not** exposed as a user action, because "clear my
  /// answers" is a [save] of an empty profile.
  Future<void> deleteAll() async {
    await _db.delete(_db.businessProfilesTable).go();
  }
}
