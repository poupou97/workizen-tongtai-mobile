/// Idempotent demo-catalogue seeder for the Tổng Tài Unified Search screen
/// (WTM-73).
///
/// The FTS5 index (WTM-72) is built over `producers_table` / `products_table`,
/// but on a fresh install those tables are empty, so unified search would have
/// nothing to return. This seeder populates a small, realistic Vietnamese SMB
/// sourcing catalogue **only when the catalogue is empty**, so the search screen
/// is demoable out of the box without clobbering any real data the user (or a
/// later import) may have added.
///
/// The rows are written through the normal Drift inserts, so the WTM-72 FTS
/// triggers index them automatically — nothing here touches the index directly.
/// Everything hangs off one demo [User] + [Business] (the FK parents) with
/// fixed ids, so re-running only ever converges to the same single demo set.
library;

import 'package:drift/drift.dart';

import '../../../database/database.dart';

class TongtaiCatalogSeeder {
  const TongtaiCatalogSeeder();

  /// Fixed id of the demo owner (FK parent of the demo business).
  static const String demoOwnerId = 'tongtai-demo-owner';

  /// Fixed id of the demo business (FK parent of every seeded producer/product).
  static const String demoBusinessId = 'tongtai-demo-business';

  /// Seeds the demo catalogue if — and only if — both catalogue tables are
  /// empty. Returns `true` if it seeded, `false` if data already existed.
  Future<bool> ensureSeeded(AppDatabase db) async {
    final counts = await db
        .customSelect(
          'SELECT '
          '(SELECT count(*) FROM producers_table) AS producers, '
          '(SELECT count(*) FROM products_table) AS products',
        )
        .getSingle();
    final hasData =
        counts.read<int>('producers') > 0 || counts.read<int>('products') > 0;
    if (hasData) return false;

    await _seed(db);
    return true;
  }

  Future<void> _seed(AppDatabase db) async {
    await db.transaction(() async {
      await db
          .into(db.usersTable)
          .insertOnConflictUpdate(
            UsersTableCompanion.insert(
              id: demoOwnerId,
              email: 'demo@tongtai.local',
              name: 'Chủ tiệm demo',
              language: const Value('vi'),
            ),
          );
      await db
          .into(db.businessesTable)
          .insertOnConflictUpdate(
            BusinessesTableCompanion.insert(
              id: demoBusinessId,
              ownerId: demoOwnerId,
              name: 'Cửa hàng Tổng Tài (demo)',
              country: const Value('VN'),
            ),
          );
      for (final supplier in _suppliers) {
        await db.into(db.producersTable).insertOnConflictUpdate(supplier);
      }
      for (final product in _products) {
        await db.into(db.productsTable).insertOnConflictUpdate(product);
      }
    });
  }

  /// Demo suppliers — a spread of categories and countries so the advanced
  /// filters (category / country) have something to bite on, and với dấu tiếng
  /// Việt (incl. đ) to exercise the diacritic-folding FTS tokenizer.
  static final List<ProducersTableCompanion> _suppliers = [
    _producer(
      'sup-caphe',
      'Cà Phê Đắk Lắk Trading',
      'Nông sản',
      'Vietnam',
      4.8,
    ),
    _producer('sup-saigon', 'Saigon Textile Works', 'Dệt may', 'Vietnam', 4.5),
    _producer('sup-techpro', 'TechPro Wholesale', 'Điện tử', 'China', 4.2),
    _producer(
      'sup-danang',
      'Đà Nẵng Seafood Export',
      'Hải sản',
      'Vietnam',
      4.6,
    ),
    _producer('sup-hanoi', 'Hanoi Handicraft Co.', 'Thủ công', 'Vietnam', 4.3),
    _producer(
      'sup-guangzhou',
      'Guangzhou Fashion Hub',
      'Thời trang',
      'China',
      3.9,
    ),
  ];

  /// Demo products across the same categories.
  static final List<ProductsTableCompanion> _products = [
    _product(
      'prod-robusta',
      'Cà phê Robusta rang xay',
      'Nông sản',
      'Cà phê Robusta nguyên chất từ Đắk Lắk, rang mộc.',
      120000,
      320,
    ),
    _product(
      'prod-aothun',
      'Áo thun cotton',
      'Thời trang',
      'Áo thun cotton 100%, form rộng, nhiều màu.',
      85000,
      540,
    ),
    _product(
      'prod-quat',
      'Quạt mini cầm tay',
      'Điện tử',
      'Quạt mini sạc USB, pin 2000mAh, gió mạnh.',
      150000,
      210,
    ),
    _product(
      'prod-nuocmam',
      'Nước mắm Phú Quốc',
      'Nông sản',
      'Nước mắm cốt nhĩ 40 độ đạm, đóng chai thủy tinh.',
      95000,
      180,
    ),
    _product(
      'prod-khanlua',
      'Khăn lụa Hà Đông',
      'Thủ công',
      'Khăn lụa tơ tằm dệt thủ công, hoa văn truyền thống.',
      320000,
      60,
    ),
    _product(
      'prod-denled',
      'Đèn LED năng lượng mặt trời',
      'Điện tử',
      'Đèn LED sân vườn, sạc pin mặt trời, chống nước IP65.',
      240000,
      95,
    ),
    _product(
      'prod-gao',
      'Gạo ST25',
      'Nông sản',
      'Gạo ST25 thơm dẻo, túi 5kg, đạt giải gạo ngon nhất thế giới.',
      165000,
      400,
    ),
    _product(
      'prod-balo',
      'Balo du lịch chống nước',
      'Thời trang',
      'Balo 30L vải Oxford chống thấm, ngăn laptop 15 inch.',
      350000,
      130,
    ),
  ];

  static ProducersTableCompanion _producer(
    String id,
    String name,
    String category,
    String country,
    double rating,
  ) {
    return ProducersTableCompanion.insert(
      id: id,
      businessId: demoBusinessId,
      name: name,
      category: Value(category),
      country: Value(country),
      rating: Value(rating),
    );
  }

  static ProductsTableCompanion _product(
    String id,
    String name,
    String category,
    String description,
    double listPrice,
    double stock,
  ) {
    return ProductsTableCompanion.insert(
      id: id,
      businessId: demoBusinessId,
      sku: 'SKU-${id.toUpperCase()}',
      name: name,
      listPrice: listPrice,
      description: Value(description),
      category: Value(category),
      totalStock: Value(stock),
    );
  }
}
