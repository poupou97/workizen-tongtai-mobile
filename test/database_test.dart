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
    // v7 (WTM-124): added journeys.domain_snapshot (ADR-TON-009).
    // v8 (WTM-177): added business_profiles_table (AI Business Profile).
    // v9 (WTM-185): added the Business Journey tree — business_journeys_table,
    //               business_journey_nodes_table, business_journey_plans_table
    //               (ADR-TON-021). Note journeys_table is NOT one of these; it
    //               stores BusinessGoal and has since WTM-124.
    // v10 (WTM-190): added opportunity_reactions_table and DROPPED the unused
    //                opportunities_table — nothing had ever written a row to
    //                it, and its presence made the app look like it stored
    //                opportunities, which are derived data.
    // v11 (WTM-191): opportunity → journey. Additive: one nullable column on
    //                the node table, so every existing node reads as "not from
    //                an opportunity" — which is what it is.
    // v12 (WTM-209): orders_table rebuilt without the channel_id FK — it
    //                pointed at channels_table, a dead v1 table nothing ever
    //                wrote, so every real channel code failed the constraint.
    //                channels_table dropped (WTM-190 precedent).
    // v13 (WTM-212): DTV eliminated — mọi cột dẫn xuất chết bị xoá trong một
    //                lần quét; an toàn cho mọi .ttbk vì codec mã hoá domain
    //                object, không mã hoá cột thô.
    // v14 (WTM-227 / ADR-TON-023): Product Type — `kind` + `total_stock`
    // nullable, để "không có tồn kho" khác hẳn "hết hàng".
    // v15 (WTM-228 / ADR-TON-023): Business Type — một cột nullable trên
    //                businesses_table.
    // v16 (WTM-229 / ADR-TON-023): business_inputs_table (Business Input).
    // v17 (WTM-282 / N0.1): orders_table.provenance_code — bản ghi này từ đâu
    //                tới. KHÔNG backfill: ghi một suy đoán xuống đĩa sẽ biến
    //                nó thành lời khai.
    // v18 (WTM-283 / N0.2): connections_table (metadata kết nối, KHÔNG token)
    //                và DROP integrations_table — bảng chết từ v1 mang bốn cột
    //                `*Encrypted`, tức giả định "token nằm trong SQLite".
    // v19 (WTM-291 / N0.3): external_identities_table +
    //                identity_link_events_table (ADR-TON-024). Thuần thêm mới;
    //                customers_table.external_id/external_source để NGUYÊN,
    //                không migrate — chúng đang rỗng, và chép một suy đoán
    //                sang bảng mới là lặp lại sai lầm v17 đã tránh.
    // v20 (WTM-292 / N0.4): settlement_lines_table + payouts_table
    //                (ADR-TON-024 luật 2). Thuần thêm mới. Hai cột cố ý KHÔNG
    //                có DEFAULT: `funded_by` (mặc định = app tự khai thay sàn
    //                rằng "sàn tài trợ", sai theo hướng tâng bốc lợi nhuận) và
    //                `reconciled_delta` nullable (null = CHƯA đối soát, 0 = đã
    //                đối soát và khớp).
    expect(db.schemaVersion, 20);
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
    // `channelsTable` was dropped in v12 (WTM-209) — dead since v1; the
    // channel now lives as a canonical code on the order itself.
    // `opportunitiesTable` was dropped in schema v10 (WTM-190) — it never held
    // a row; opportunities are derived data. See opportunity_reactions.dart.
    expect(await db.select(db.opportunityReactionsTable).get(), isEmpty);
    expect(await db.select(db.journeysTable).get(), isEmpty);
    expect(await db.select(db.journeyStepsTable).get(), isEmpty);
    expect(await db.select(db.transactionsTable).get(), isEmpty);
    expect(await db.select(db.documentsTable).get(), isEmpty);
    expect(await db.select(db.alertsTable).get(), isEmpty);
    expect(await db.select(db.aIChatTable).get(), isEmpty);
    expect(await db.select(db.connectionsTable).get(), isEmpty);
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
