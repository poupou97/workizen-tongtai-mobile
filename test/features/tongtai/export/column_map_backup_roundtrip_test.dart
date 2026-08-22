import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/attribute_repository.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_repository.dart';
import 'package:tongtai/features/tongtai/commerce/import/import_column_map.dart';
import 'package:tongtai/features/tongtai/commerce/import/import_column_map_repository.dart';
import 'package:tongtai/features/tongtai/commerce/import/marketplace_profile.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/export/backup_crypto.dart';
import 'package:tongtai/features/tongtai/export/backup_service.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/journey/journey_repository.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_reaction_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/producer/business_input_repository.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorites_store.dart';
import 'package:tongtai/features/tongtai/profile/business_profile_repository.dart';

/// WTM-445 — bản đồ cột người bán tự chỉ đi qua `.ttbk` v2 (ADR-TON-018).
///
/// Hai vế, đúng khuôn `attribute_backup_roundtrip_test`:
///
/// 1. sao lưu rồi khôi phục **không được mất** bản đồ;
/// 2. một `.ttbk` viết **trước v28** (không có dataset này) **vẫn phải
///    restore** — nó là OPTIONAL, không nằm trong `all`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppDatabase db;
  late ImportColumnMapRepository maps;
  late TongtaiBackupService service;

  const fastCrypto = BackupCrypto(iterations: 100);

  TongtaiBackupRepositories reposFor(AppDatabase database) =>
      TongtaiBackupRepositories(
        database: database,
        customers: DriftCustomerRepository(database),
        products: DriftProductRepository(database),
        orders: DriftOrderRepository(database),
        goals: DriftBusinessGoalRepository(database),
        finance: DriftFinanceRepository(database),
        favourites: DriftSupplierFavoritesStore(database),
        businessProfile: BusinessProfileRepository(database),
        journeys: JourneyRepository(database),
        opportunityReactions: OpportunityReactionRepository(database),
        businessInputs: DriftBusinessInputRepository(database),
        commerce: CommerceRepository(database),
        attributes: AttributeRepository(database),
        importColumnMaps: DriftImportColumnMapRepository(database),
      );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tongtai-colmap-backup-');
    db = AppDatabase.forExecutor(NativeDatabase(File('${tempDir.path}/t.db')));
    maps = DriftImportColumnMapRepository(db);
    service = TongtaiBackupService(
      repositories: reposFor(db),
      crypto: fastCrypto,
      vault: _MemoryVault(),
      clock: () => DateTime(2026, 8, 22, 20, 0),
      randomId: () => 'colmap-backup-id',
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  const shopeeOrders = ImportColumnMap(
    vendor: 'shopee',
    kind: MarketplaceFileKind.orders,
    columns: {
      MarketplaceField.orderId: 'Ma_Don',
      MarketplaceField.sku: 'Ma_Hang',
      MarketplaceField.quantity: 'SL',
      MarketplaceField.unitPrice: 'Don_Gia',
    },
  );

  const otherIncome = ImportColumnMap(
    vendor: ImportColumnMap.kOtherMarketplaceVendor,
    kind: MarketplaceFileKind.income,
    columns: {
      MarketplaceField.orderId: 'Order No',
      MarketplaceField.commission: 'Hoa hong',
    },
  );

  Future<void> seed() async {
    await maps.upsert(shopeeOrders);
    await maps.upsert(otherIncome);
  }

  test('⭐ sao lưu rồi khôi phục giữ nguyên bản đồ cột', () async {
    await seed();

    final armored = await service.createBackup();

    await maps.deleteAll();
    expect(await maps.loadAll(), isEmpty);

    final validation = await service.validate(armored);
    expect(validation.isRestorable, isTrue, reason: validation.issues.join());
    await service.restore(validation);

    final restored = await maps.loadAll();
    expect(restored, hasLength(2));

    final shopee = restored.firstWhere((m) => m.vendor == 'shopee');
    expect(shopee.kind, MarketplaceFileKind.orders);
    expect(shopee.columns[MarketplaceField.orderId], 'Ma_Don');
    expect(shopee.columns[MarketplaceField.unitPrice], 'Don_Gia');
    expect(
      shopee.isUsable,
      isTrue,
      reason: 'bản đồ khôi phục phải dùng được ngay, không phải ghép lại',
    );

    // ⭐ Hai loại file của HAI sàn không được lẫn vào nhau: một bản đồ `income`
    // đọc nhầm thành `orders` sẽ ghép cột phí vào vai trò đơn hàng.
    final other = restored.firstWhere(
      (m) => m.vendor == ImportColumnMap.kOtherMarketplaceVendor,
    );
    expect(other.kind, MarketplaceFileKind.income);
    expect(other.columns[MarketplaceField.commission], 'Hoa hong');
  });

  test('`.ttbk` trước v28 (không có dataset này) VẪN khôi phục được', () async {
    // Hình dạng của mọi file đã phát hành trước hôm nay: không dataset bản đồ.
    // Nó phải validate và restore được, và Replace phải để bảng RỖNG chứ
    // không từ chối file vì "thiếu dataset" (bài học WTM-177/ADR-TON-021).
    final legacyArmored = await service.createBackup();

    await seed();
    expect(await maps.loadAll(), isNotEmpty);

    final validation = await service.validate(legacyArmored);
    expect(
      validation.isRestorable,
      isTrue,
      reason:
          'dataset OPTIONAL vắng mặt không được làm file cũ mất khả năng '
          'khôi phục: ${validation.issues.join()}',
    );
    await service.restore(validation);

    expect(await maps.loadAll(), isEmpty);
  });

  test('⭐ Restore = Replace: bản đồ CŨ không được sót lại', () async {
    await maps.upsert(shopeeOrders);
    final armored = await service.createBackup();

    // Người bán ghép thêm một bản đồ nữa SAU khi sao lưu.
    await maps.upsert(otherIncome);
    expect(await maps.loadAll(), hasLength(2));

    final validation = await service.validate(armored);
    await service.restore(validation);

    // Bản đồ sót lại sau khôi phục sẽ khớp nhầm một file của bản sao lưu khác
    // — đúng loại lỗi im lặng mà Replace sinh ra để chặn.
    final restored = await maps.loadAll();
    expect(restored, hasLength(1));
    expect(restored.single.vendor, 'shopee');
  });
}

class _MemoryVault implements BackupVault {
  final Map<String, String> files = {};

  @override
  Future<String> write(String label, String armored) async {
    files['/vault/$label'] = armored;
    return '/vault/$label';
  }

  @override
  Future<String> read(String path) async => files[path]!;
}
