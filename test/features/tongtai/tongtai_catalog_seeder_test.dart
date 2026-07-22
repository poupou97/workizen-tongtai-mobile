import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/database/search/tongtai_search_service.dart';
import 'package:tongtai/features/tongtai/search/tongtai_catalog_seeder.dart';

/// Tests for the WTM-73 demo-catalogue seeder against a real in-memory SQLite
/// database (so the WTM-72 FTS triggers index the seeded rows for real).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late TongtaiSearchService search;
  const seeder = TongtaiCatalogSeeder();

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    search = TongtaiSearchService(db);
  });

  tearDown(() => db.close());

  Future<int> count(String table) async {
    final row = await db
        .customSelect('SELECT count(*) AS c FROM $table')
        .getSingle();
    return row.read<int>('c');
  }

  test('seeds suppliers + products into an empty catalogue', () async {
    final seeded = await seeder.ensureSeeded(db);
    expect(seeded, isTrue);
    expect(await count('producers_table'), greaterThan(0));
    expect(await count('products_table'), greaterThan(0));
  });

  test('seeded rows are searchable via FTS (incl. đ / diacritics)', () async {
    await seeder.ensureSeeded(db);

    // Product name/description folds diacritics + đ.
    final robusta = await search.searchProducts('robusta');
    expect(robusta.map((p) => p.name), contains('Cà phê Robusta rang xay'));

    // Supplier "Đà Nẵng…" is found by an ASCII query (index-side đ fold).
    final danang = await search.searchSuppliers('da nang');
    expect(danang, isNotEmpty);
    expect(danang.first.name, contains('Đà Nẵng'));
  });

  test('is idempotent: a second call is a no-op', () async {
    expect(await seeder.ensureSeeded(db), isTrue);
    final producers = await count('producers_table');
    final products = await count('products_table');

    expect(await seeder.ensureSeeded(db), isFalse);
    expect(await count('producers_table'), producers); // unchanged
    expect(await count('products_table'), products);
  });

  test('does not seed when the catalogue already has data', () async {
    await db
        .into(db.usersTable)
        .insert(
          UsersTableCompanion.insert(
            id: 'u1',
            email: 'real@shop.test',
            name: 'Real owner',
          ),
        );
    await db
        .into(db.businessesTable)
        .insert(
          BusinessesTableCompanion.insert(
            id: 'b1',
            ownerId: 'u1',
            name: 'Real shop',
          ),
        );
    await db
        .into(db.producersTable)
        .insert(
          ProducersTableCompanion.insert(
            id: 'real-sup',
            businessId: 'b1',
            name: 'Real Supplier',
          ),
        );

    final seeded = await seeder.ensureSeeded(db);
    expect(seeded, isFalse);
    expect(await count('producers_table'), 1); // only the real one
  });
}
