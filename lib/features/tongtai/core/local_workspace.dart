import 'package:drift/drift.dart';

import '../../../database/database.dart';

/// Bootstraps the local-first "root aggregate" (WTM-120) — the single local
/// User + Business that owns everything persisted on-device.
///
/// Every domain row (transactions, orders, products…) hangs off a Business,
/// which hangs off a User (FK chain). For a no-account local user (D-4) we seed
/// one fixed local User + Business, distinct from the WTM-73 demo owner/business
/// so real data never mixes with demo data (Founder "User Data First", 2026-07-24).
///
/// Fixed ids + insert-or-ignore keep it idempotent. The design intentionally
/// leaves room to grow — multiple businesses, cloud sync, account login — by
/// making the business a real row (not a hardcoded constant everywhere):
/// callers depend on [ensureBusinessId], not on the literal id.
class LocalWorkspace {
  const LocalWorkspace();

  /// Fixed id of the local owner (FK parent of the local business).
  static const String localOwnerId = 'tongtai-local-owner';

  /// Fixed id of the local business (FK parent of every local domain row).
  static const String localBusinessId = 'tongtai-local-business';

  /// Ensures the local User + Business exist and returns the business id.
  /// Idempotent — re-running converges to the same single local workspace.
  Future<String> ensureBusinessId(AppDatabase db) async {
    await db
        .into(db.usersTable)
        .insert(
          UsersTableCompanion.insert(
            id: localOwnerId,
            email: 'local@tongtai.app',
            name: 'Tôi',
            language: const Value('vi'),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    await db
        .into(db.businessesTable)
        .insert(
          BusinessesTableCompanion.insert(
            id: localBusinessId,
            ownerId: localOwnerId,
            name: 'Doanh nghiệp của tôi',
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return localBusinessId;
  }
}
