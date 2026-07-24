import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';

/// Real integration tests for the Tổng Tài SQLite/Drift schema (WTM-51).
///
/// These run against an in-memory SQLite database — they actually create the
/// schema, insert rows, query them back, and exercise foreign-key cascade
/// behaviour. (The original pilot tests asserted nothing — they were tautological
/// placebos that never touched the database; the schema did not even compile.)
void main() {
  late AppDatabase db;

  // A User must exist before a Business (Business.ownerId -> User.id).
  Future<void> seedOwner(String userId) => db
      .into(db.usersTable)
      .insert(
        UsersTableCompanion.insert(
          id: userId,
          email: '$userId@example.com',
          name: 'Owner $userId',
        ),
      );

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('schema opens and reports the current version', () async {
    // v3 (WTM-72): added products.description + the FTS5 search index.
    // v4 (WTM-81): added the per-message chat_messages_table.
    // v5 (WTM-121): added products.domain_snapshot (ADR-TON-009).
    // v6 (WTM-123): added customers.domain_snapshot (ADR-TON-009).
    expect(db.schemaVersion, 6);
    final businesses = await db.select(db.businessesTable).get();
    expect(businesses, isEmpty);
  });

  test('all 15 entity tables are created and queryable', () async {
    // If any table were missing, these selects would throw.
    expect(await db.select(db.usersTable).get(), isEmpty);
    expect(await db.select(db.businessesTable).get(), isEmpty);
    expect(await db.select(db.producersTable).get(), isEmpty);
    expect(await db.select(db.productsTable).get(), isEmpty);
    expect(await db.select(db.customersTable).get(), isEmpty);
    expect(await db.select(db.ordersTable).get(), isEmpty);
    expect(await db.select(db.channelsTable).get(), isEmpty);
    expect(await db.select(db.opportunitiesTable).get(), isEmpty);
    expect(await db.select(db.journeysTable).get(), isEmpty);
    expect(await db.select(db.journeyStepsTable).get(), isEmpty);
    expect(await db.select(db.transactionsTable).get(), isEmpty);
    expect(await db.select(db.documentsTable).get(), isEmpty);
    expect(await db.select(db.alertsTable).get(), isEmpty);
    expect(await db.select(db.aIChatTable).get(), isEmpty);
    expect(await db.select(db.integrationsTable).get(), isEmpty);
  });

  test('insert + read round-trips a Business and a Product', () async {
    await seedOwner('user-1');
    await db
        .into(db.businessesTable)
        .insert(
          BusinessesTableCompanion.insert(
            id: 'biz-1',
            ownerId: 'user-1',
            name: 'Shop Tổng Tài',
          ),
        );
    await db
        .into(db.productsTable)
        .insert(
          ProductsTableCompanion.insert(
            id: 'prod-1',
            businessId: 'biz-1',
            sku: 'SKU-001',
            name: 'Áo thun',
            listPrice: 120000,
          ),
        );

    final products = await db.select(db.productsTable).get();
    expect(products, hasLength(1));
    expect(products.single.name, 'Áo thun');
    expect(products.single.businessId, 'biz-1');
    expect(products.single.listPrice, 120000);
  });

  test(
    'foreign key is enforced: product with unknown business is rejected',
    () async {
      // PRAGMA foreign_keys = ON is set in AppDatabase.migration.beforeOpen.
      expect(
        () => db
            .into(db.productsTable)
            .insert(
              ProductsTableCompanion.insert(
                id: 'prod-x',
                businessId: 'does-not-exist',
                sku: 'SKU-X',
                name: 'Orphan',
                listPrice: 1,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    },
  );

  test('cascade delete: deleting a Business removes its Products', () async {
    await seedOwner('user-2');
    await db
        .into(db.businessesTable)
        .insert(
          BusinessesTableCompanion.insert(
            id: 'biz-2',
            ownerId: 'user-2',
            name: 'B2',
          ),
        );
    await db
        .into(db.productsTable)
        .insert(
          ProductsTableCompanion.insert(
            id: 'prod-2',
            businessId: 'biz-2',
            sku: 'SKU-2',
            name: 'P2',
            listPrice: 5000,
          ),
        );
    expect(await db.select(db.productsTable).get(), hasLength(1));

    await (db.delete(
      db.businessesTable,
    )..where((b) => b.id.equals('biz-2'))).go();

    // Product should be gone via ON DELETE CASCADE.
    expect(await db.select(db.productsTable).get(), isEmpty);
  });

  test('cascade delete: deleting a Journey removes its JourneySteps', () async {
    await seedOwner('user-3');
    await db
        .into(db.businessesTable)
        .insert(
          BusinessesTableCompanion.insert(
            id: 'biz-3',
            ownerId: 'user-3',
            name: 'B3',
          ),
        );
    await db
        .into(db.journeysTable)
        .insert(
          JourneysTableCompanion.insert(
            id: 'jny-1',
            businessId: 'biz-3',
            goal: 'Enter US market',
            status: 'in_progress',
          ),
        );
    await db
        .into(db.journeyStepsTable)
        .insert(
          JourneyStepsTableCompanion.insert(
            id: 'step-1',
            journeyId: 'jny-1',
            stepNumber: 1,
            title: 'Research',
            status: 'done',
          ),
        );
    expect(await db.select(db.journeyStepsTable).get(), hasLength(1));

    await (db.delete(
      db.journeysTable,
    )..where((j) => j.id.equals('jny-1'))).go();

    expect(await db.select(db.journeyStepsTable).get(), isEmpty);
  });
}
