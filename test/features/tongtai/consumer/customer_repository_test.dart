import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/domain_snapshot.dart';
import 'package:tongtai/features/tongtai/core/local_workspace.dart';

/// WTM-123 — customer persistence over Drift with the structured-columns +
/// versioned-snapshot convention (ADR-TON-009). Covers the full Founder-required
/// set: round-trip, backward compatibility, corrupt-JSON fallback, version
/// tolerance, structured precedence and business isolation.
void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forExecutor(NativeDatabase.memory()));
  tearDown(() => db.close());

  Customer customer(
    String id, {
    String name = 'Phương Nguyễn',
    String phone = '+84912345678',
    String location = 'Hà Nội',
    int orderCount = 4,
    double totalSpent = 12000000,
    DateTime? lastPurchase,
    String email = 'p@example.com',
    List<String> addresses = const [],
    List<String> segments = const [],
    List<String> tags = const [],
    String notes = '',
  }) => Customer(
    id: id,
    name: name,
    phone: phone,
    location: location,
    orderCount: orderCount,
    totalSpent: totalSpent,
    lastPurchaseDate: lastPurchase ?? DateTime(2026, 7, 10),
    email: email,
    addresses: addresses,
    segments: segments,
    tags: tags,
    notes: notes,
  );

  /// Inserts a raw customer row (bypassing the repository's mapping) so tests can
  /// stage legacy / corrupt / stale-snapshot data. The local business is
  /// bootstrapped first so the FK holds.
  Future<void> insertRawCustomer({
    required String id,
    required String name,
    String? businessId,
    String? phone,
    String? city,
    String? email,
    String? segments,
    int? orderCount,
    double? totalSpent,
    DateTime? lastOrderDate,
    String? domainSnapshot,
  }) async {
    final localBusiness = await const LocalWorkspace().ensureBusinessId(db);
    await db
        .into(db.customersTable)
        .insert(
          CustomersTableCompanion.insert(
            id: id,
            businessId: businessId ?? localBusiness,
            name: name,
            phone: Value(phone),
            city: Value(city),
            email: Value(email),
            segments: Value(segments),
            orderCount: Value(orderCount),
            totalSpent: Value(totalSpent),
            lastOrderDate: Value(lastOrderDate),
            domainSnapshot: Value(domainSnapshot),
          ),
        );
  }

  test('a new directory starts EMPTY (no sample seeded)', () async {
    expect(await DriftCustomerRepository(db).loadAll(), isEmpty);
  });

  test('round-trip: every promoted + extended field survives', () async {
    final repo = DriftCustomerRepository(db);
    await repo.upsert(
      customer(
        'c1',
        name: 'Minh Trần',
        phone: '+84908111222',
        location: 'Đà Nẵng',
        orderCount: 9,
        totalSpent: 8200000,
        lastPurchase: DateTime(2026, 6, 25),
        email: 'minh@example.com',
        addresses: ['12 Lê Lợi', '7 Trần Phú'],
        segments: ['Loyal', 'Wholesale'],
        tags: ['vip-referrer'],
        notes: 'Gọi buổi sáng',
      ),
    );

    final reloaded = await DriftCustomerRepository(db).loadAll();
    expect(reloaded, hasLength(1));
    final c = reloaded.single;
    expect(c.id, 'c1');
    expect(c.name, 'Minh Trần');
    expect(c.phone, '+84908111222');
    expect(c.location, 'Đà Nẵng'); // ← city column
    expect(c.orderCount, 9);
    expect(c.totalSpent, 8200000);
    expect(c.lastPurchaseDate, DateTime(2026, 6, 25));
    expect(c.email, 'minh@example.com');
    // Structured JSON-array column.
    expect(c.segments, ['Loyal', 'Wholesale']);
    // Extended fields via the versioned snapshot.
    expect(c.addresses, ['12 Lê Lợi', '7 Trần Phú']);
    expect(c.tags, ['vip-referrer']);
    expect(c.notes, 'Gọi buổi sáng');
  });

  test('upsert replaces the customer with the same id (edit)', () async {
    final repo = DriftCustomerRepository(db);
    await repo.upsert(customer('c1', name: 'Old', totalSpent: 1000000));
    await repo.upsert(customer('c1', name: 'New', totalSpent: 9000000));

    final all = await repo.loadAll();
    expect(all, hasLength(1));
    expect(all.single.name, 'New');
    expect(all.single.totalSpent, 9000000);
  });

  test(
    'backward compatibility: a legacy row with a NULL snapshot loads',
    () async {
      // Simulates a row written before schema v6 — structured columns intact, no
      // domain_snapshot. The extended fields default to empty; nothing throws.
      await insertRawCustomer(
        id: 'legacy',
        name: 'Legacy Khách',
        phone: '+84900000000',
        city: 'Huế',
        email: 'legacy@example.com',
        segments: null,
        orderCount: 2,
        totalSpent: 500000,
        lastOrderDate: DateTime(2026, 1, 1),
        domainSnapshot: null,
      );

      final c = (await DriftCustomerRepository(db).loadAll()).single;
      expect(c.name, 'Legacy Khách');
      expect(c.location, 'Huế');
      expect(c.totalSpent, 500000);
      // No snapshot / no segments → extended fields empty, not null-crashing.
      expect(c.addresses, isEmpty);
      expect(c.tags, isEmpty);
      expect(c.notes, '');
      expect(c.segments, isEmpty);
    },
  );

  test(
    'corrupt-JSON fallback: a garbage snapshot never breaks a load',
    () async {
      await insertRawCustomer(
        id: 'corrupt',
        name: 'Hỏng JSON',
        city: 'Cần Thơ',
        totalSpent: 3000000,
        segments: 'not-an-array{',
        domainSnapshot: '}{ this is not json',
      );

      final c = (await DriftCustomerRepository(db).loadAll()).single;
      // Structured columns still read; corrupt blobs degrade to empty.
      expect(c.name, 'Hỏng JSON');
      expect(c.location, 'Cần Thơ');
      expect(c.totalSpent, 3000000);
      expect(c.addresses, isEmpty);
      expect(c.tags, isEmpty);
      expect(c.notes, '');
      expect(c.segments, isEmpty);
    },
  );

  test(
    'version tolerance: an unknown snapshot version still reads its fields',
    () async {
      // A future writer bumps the version; today's reader must not choke on it.
      await insertRawCustomer(
        id: 'future',
        name: 'Tương Lai',
        domainSnapshot: encodeDomainSnapshot({
          'tags': ['early-adopter'],
          'addresses': ['99 Nguyễn Huệ'],
          'notes': 'from v99',
        }, version: 99),
      );
      // A legacy snapshot missing the version key (v:0) also reads.
      await insertRawCustomer(
        id: 'noversion',
        name: 'Không Version',
        domainSnapshot: '{"tags":["legacy-tag"]}',
      );

      final all = await DriftCustomerRepository(db).loadAll();
      final future = all.firstWhere((c) => c.id == 'future');
      final noVersion = all.firstWhere((c) => c.id == 'noversion');
      expect(future.tags, ['early-adopter']);
      expect(future.addresses, ['99 Nguyễn Huệ']);
      expect(future.notes, 'from v99');
      expect(noVersion.tags, ['legacy-tag']);
    },
  );

  test(
    'structured precedence: the column wins over a stale snapshot copy',
    () async {
      // The snapshot carries a stale copy of promoted fields; the reader must take
      // the structured columns as the source of truth and ignore the snapshot's
      // copies (ADR-TON-009).
      await insertRawCustomer(
        id: 'stale',
        name: 'Tên Cột', // ← structured truth
        city: 'Hà Nội', // ← structured truth
        totalSpent: 30000000, // ← structured truth (VIP)
        segments: encodeJsonStringList(['Loyal']),
        domainSnapshot: encodeDomainSnapshot({
          'name': 'Tên Cũ Trong Snapshot', // stale — must be ignored
          'city': 'Sài Gòn cũ', // stale — must be ignored
          'totalSpent': 1, // stale — must be ignored
          'segments': ['stale-seg'], // stale — must be ignored
          'tags': ['real-tag'], // extended — must be used
        }, version: 1),
      );

      final c = (await DriftCustomerRepository(db).loadAll()).single;
      expect(c.name, 'Tên Cột');
      expect(c.location, 'Hà Nội');
      expect(c.totalSpent, 30000000);
      expect(c.tier, CustomerTier.vip);
      expect(c.segments, ['Loyal']); // structured column, not the snapshot copy
      expect(c.tags, ['real-tag']); // genuinely extended field
    },
  );

  test(
    'business isolation: loadAll only returns the local business rows',
    () async {
      // Bootstrap the local business, then plant a customer under a DIFFERENT
      // business (its own user + business rows) and confirm it is invisible.
      final localBusiness = await const LocalWorkspace().ensureBusinessId(db);
      await db
          .into(db.usersTable)
          .insert(
            UsersTableCompanion.insert(
              id: 'other-owner',
              email: 'other@x.app',
              name: 'Khác',
            ),
          );
      await db
          .into(db.businessesTable)
          .insert(
            BusinessesTableCompanion.insert(
              id: 'other-business',
              ownerId: 'other-owner',
              name: 'Doanh nghiệp khác',
            ),
          );

      await insertRawCustomer(
        id: 'mine',
        name: 'Của tôi',
        businessId: localBusiness,
      );
      await insertRawCustomer(
        id: 'theirs',
        name: 'Của họ',
        businessId: 'other-business',
      );

      final mine = await DriftCustomerRepository(db).loadAll();
      expect(mine.map((c) => c.id), ['mine']);
    },
  );

  test('rows are ordered by name ascending', () async {
    final repo = DriftCustomerRepository(db);
    await repo.upsert(customer('c1', name: 'Zét'));
    await repo.upsert(customer('c2', name: 'An'));
    await repo.upsert(customer('c3', name: 'Minh'));
    expect((await repo.loadAll()).map((c) => c.name), ['An', 'Minh', 'Zét']);
  });

  group('SampleCustomerRepository (demo, read-only)', () {
    test('returns the sample directory and never persists', () async {
      const repo = SampleCustomerRepository();
      final before = (await repo.loadAll()).length;
      expect(before, greaterThan(0));
      await repo.upsert(customer('c1'));
      expect((await repo.loadAll()).length, before);
    });

    test('the Drift directory is NOT seeded with the sample data', () async {
      // User Data First: a real repo stays empty even though a sample exists.
      expect(await DriftCustomerRepository(db).loadAll(), isEmpty);
      expect(
        (await const SampleCustomerRepository().loadAll()).length,
        greaterThan(0),
      );
    });
  });

  group('InMemoryCustomerRepository (tests)', () {
    test('upserts and replaces in memory', () async {
      final repo = InMemoryCustomerRepository([customer('c1', name: 'A')]);
      expect((await repo.loadAll()).single.name, 'A');
      await repo.upsert(customer('c1', name: 'B'));
      await repo.upsert(customer('c2', name: 'C'));
      final all = await repo.loadAll();
      expect(all, hasLength(2));
      expect(all.firstWhere((c) => c.id == 'c1').name, 'B');
    });
  });
}
