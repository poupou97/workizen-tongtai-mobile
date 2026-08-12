import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/database/migrations/tongtai_migrations.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/consumer/external_identity_repository.dart';
import 'package:tongtai/features/tongtai/core/local_workspace.dart';
import 'package:tongtai/features/tongtai/finance/settlement_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';

/// Đi THẬT đường nâng cấp schema trên một cơ sở dữ liệu CÓ DỮ LIỆU.
///
/// Vì sao suite này tồn tại: WTM-227 ship một migration hỏng qua 1744 test
/// xanh và CI xanh, rồi **chết ngay trên máy Founder ở lần mở đầu tiên** —
/// `no such column: "kind"`, và mọi màn hình hiện *"Could not read your data"*.
///
/// Nguyên nhân là một chỗ mù có hệ thống: **mọi test đều tạo DB mới bằng
/// `createAll`**, nên `onUpgrade` chưa từng chạy trong bất kỳ test nào. Test
/// đo *schema đích* trông thế nào; không test nào đo *đường đi tới đó*.
///
/// Lỗi cụ thể đáng nhớ: `TableMigration` sao chép **mọi cột của schema MỚI**
/// ra khỏi bảng CŨ, nên nó không được chạy khi một cột mới còn chưa tồn tại.
/// v13 thoát vì nó chỉ **xoá** cột; **thêm** cột mới mới là chỗ vỡ.
/// ⚠️ Còn thiếu: một test tái hiện được lỗi *thứ hai* máy thật đưa ra
/// (`duplicate column name: source_opportunity_id` khi chuỗi migration chạy
/// lại sau một lần hỏng). Tôi đã thử dựng DB nửa vời ở v10 nhưng chuỗi không
/// ném lỗi trong test, nên **chưa** hiểu đủ để viết một test trung thực. Một
/// test xanh ở cả hai phía không bảo vệ gì cả (P-24), nên nó bị gỡ thay vì
/// giữ lại làm màu xanh giả. Bằng chứng hiện tại cho bản sửa idempotent là
/// **thiết bị thật**, không phải suite này.
void main() {
  test('v13 có dữ liệu → v14: không mất dòng nào, đọc được ngay', () async {
    final dir = await Directory.systemTemp.createTemp('tongtai_upgrade');
    final file = File('${dir.path}/t.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    // ── Dựng một cơ sở dữ liệu ở ĐÚNG hình dạng v13 ──────────────────────
    // Chỉ những cột v13 thực sự có: KHÔNG có `kind`, và `total_stock` NOT NULL
    // với default 0 — chính con số 0 đó là thứ ADR-TON-023 gỡ bỏ.
    var raw = NativeDatabase(file);
    var db = AppDatabase.forExecutor(raw);
    await db.customStatement('DROP TABLE IF EXISTS products_table');
    await db.customStatement('''
      CREATE TABLE products_table (
        id TEXT NOT NULL,
        business_id TEXT NOT NULL,
        sku TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT NULL,
        category TEXT NULL,
        cost_per_unit REAL NULL,
        list_price REAL NOT NULL,
        total_stock REAL NOT NULL DEFAULT 0,
        stock_alert_level REAL NULL,
        supplier_id TEXT NULL,
        sales_channels TEXT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        domain_snapshot TEXT NULL,
        created_at INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (business_id, id)
      )''');
    await db.customStatement(
      "INSERT INTO products_table (id, business_id, sku, name, list_price, "
      "total_stock, stock_alert_level, updated_at) "
      "VALUES ('p1', 'b1', 'SKU-1', 'Quạt mini', 150000, 12, 3, 1)",
    );
    await db.customStatement('PRAGMA user_version = 13');
    await db.close();

    // ── Mở lại bằng schema hiện tại ⇒ onUpgrade chạy thật ────────────────
    raw = NativeDatabase(file);
    db = AppDatabase.forExecutor(raw);
    final rows = await db
        .customSelect('SELECT id, name, total_stock, kind FROM products_table')
        .get();
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    await db.close();

    expect(
      rows,
      hasLength(1),
      reason: 'nâng cấp không được làm mất dữ liệu người bán',
    );
    expect(rows.single.read<String>('name'), 'Quạt mini');
    expect(
      rows.single.read<double?>('total_stock'),
      12,
      reason: 'số lượng cũ giữ nguyên — không ép về null',
    );
    expect(
      rows.single.read<String?>('kind'),
      isNull,
      reason:
          'dòng cũ chưa có kind; đọc ra sẽ là physical (ProductKind.fromCode)',
    );
    expect(version.read<int>('user_version'), kTongtaiSchemaVersion);
  });

  test('v16 có đơn hàng → v17: đơn cũ KHÔNG bị gán nguồn gốc', () async {
    final dir = await Directory.systemTemp.createTemp('tongtai_upgrade17');
    final file = File('${dir.path}/t.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    // ── Dựng orders_table ở đúng hình dạng v16: KHÔNG có provenance_code ──
    var raw = NativeDatabase(file);
    var db = AppDatabase.forExecutor(raw);
    await db.customStatement('DROP TABLE IF EXISTS orders_table');
    await db.customStatement('''
      CREATE TABLE orders_table (
        id TEXT NOT NULL,
        business_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        channel_id TEXT NULL,
        order_number TEXT NULL,
        order_date INTEGER NOT NULL,
        total_quantity INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        shipping_cost REAL NULL,
        total_amount REAL NOT NULL,
        status TEXT NOT NULL,
        payment_status TEXT NULL,
        items TEXT NOT NULL,
        external_id TEXT NULL,
        created_at INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (business_id, id)
      )''');
    // Một đơn người bán tự nhập, và một đơn mẫu — hai nguồn gốc khác nhau mà
    // v16 chỉ phân biệt được bằng tiền tố id.
    for (final id in ['9f1c2b7a-uuid', 'sample-order-1']) {
      await db.customStatement(
        "INSERT INTO orders_table (id, business_id, customer_id, order_date, "
        "total_quantity, subtotal, total_amount, status, items, updated_at) "
        "VALUES ('$id', 'b1', 'c1', 1, 1, 1000, 1000, 'completed', '[]', 1)",
      );
    }
    await db.customStatement('PRAGMA user_version = 16');
    await db.close();

    // ── Mở lại bằng schema hiện tại ⇒ onUpgrade chạy thật ────────────────
    raw = NativeDatabase(file);
    db = AppDatabase.forExecutor(raw);
    final rows = await db
        .customSelect(
          'SELECT id, provenance_code FROM orders_table ORDER BY id',
        )
        .get();
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    await db.close();

    expect(rows, hasLength(2), reason: 'nâng cấp không được làm mất đơn nào');

    // ⭐ Tính chất chính của v17: KHÔNG backfill.
    //
    // Ta *đoán được* nguồn gốc từ tiền tố id, và cám dỗ là ghi luôn suy đoán
    // đó xuống cột. Nhưng ghi xuống là biến phỏng đoán thành lời khai — lần
    // đọc sau không còn ai biết đó từng là phỏng đoán, kể cả khi nó sai (một
    // người bán từng tự đặt id bắt đầu bằng `sample-`).
    //
    // Nên cột phải RỖNG sau nâng cấp, và việc suy đoán xảy ra lúc đọc.
    for (final row in rows) {
      expect(
        row.read<String?>('provenance_code'),
        isNull,
        reason:
            'đơn ${row.read<String>('id')} có trước v17 nên không khai nguồn '
            'gốc; migration KHÔNG được ghi suy đoán xuống đĩa',
      );
    }

    expect(version.read<int>('user_version'), kTongtaiSchemaVersion);
  });
  test('v16 CÓ DỮ LIỆU → phiên bản hiện tại: cả chuỗi, không mất gì', () async {
    // ⭐ Đây là chuỗi máy Founder sắp chạy. Dogfood lần cuối 2026-08-02 ở
    // **v16**; từ đó thêm v17 (Provenance) · v18 (Connection) · v19 (Identity)
    // · v20 (Settlement) · v21 (ProposedChange). Chuỗi đó chưa bao giờ chạy
    // liền nhau trên một cơ sở dữ liệu có dòng thật.
    //
    // Test này KHÔNG khoá một con số phiên bản: nó khẳng định chuỗi chạy tới
    // **hiện tại**, bất kể hiện tại là bao nhiêu. Mỗi phase mới chỉ cần thêm
    // tên bảng vào hai danh sách dưới.
    //
    // WTM-227 đã dạy đúng bài này một lần: 1744 test xanh + CI xanh, rồi chết
    // ở lần mở app đầu tiên trên máy Founder.
    final dir = await Directory.systemTemp.createTemp('tongtai_upgrade20');
    final file = File('${dir.path}/t.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    var raw = NativeDatabase(file);
    var db = AppDatabase.forExecutor(raw);
    await const LocalWorkspace().ensureBusinessId(db);
    const businessId = LocalWorkspace.localBusinessId;

    // ── Hạ cơ sở dữ liệu về ĐÚNG hình dạng v16 ───────────────────────────
    //
    // Bắt buộc, và đây là chỗ một test nâng cấp dễ tự lừa nhất: mở file mới
    // thì `onCreate` đã dựng sẵn schema v20: năm bảng mới **đã có**. Nếu để
    // nguyên, migration chạy vào `CREATE TABLE IF NOT EXISTS` và không làm gì
    // — test vẫn xanh mà chẳng chứng minh được gì.
    //
    // Nên xoá đúng những bảng v16 KHÔNG có, và dựng lại bảng v16 CÓ.
    for (final t in [
      'connections_table',
      'external_identities_table',
      'identity_link_events_table',
      'settlement_lines_table',
      'payouts_table',
      'proposed_changes_table',
      'business_actions_table',
      'agent_tasks_table',
    ]) {
      await db.customStatement('DROP TABLE IF EXISTS $t');
    }
    // `integrations_table` — bảng chết từ bootstrap v1, mang bốn cột token.
    // v18 phải xoá nó, nên nó phải CÓ mặt lúc bắt đầu.
    await db.customStatement('''
      CREATE TABLE integrations_table (
        id TEXT NOT NULL PRIMARY KEY,
        business_id TEXT NOT NULL,
        provider TEXT NOT NULL,
        status TEXT NULL,
        api_key_encrypted TEXT NULL,
        api_secret_encrypted TEXT NULL,
        access_token_encrypted TEXT NULL,
        refresh_token_encrypted TEXT NULL,
        config TEXT NULL,
        last_sync_at INTEGER NULL,
        created_at INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL DEFAULT 0
      )''');
    // orders_table v16: KHÔNG có `provenance_code`.
    await db.customStatement('DROP TABLE IF EXISTS orders_table');
    await db.customStatement('''
      CREATE TABLE orders_table (
        id TEXT NOT NULL,
        business_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        channel_id TEXT NULL,
        order_number TEXT NULL,
        order_date INTEGER NOT NULL,
        total_quantity INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        shipping_cost REAL NULL,
        total_amount REAL NOT NULL,
        status TEXT NOT NULL,
        payment_status TEXT NULL,
        items TEXT NOT NULL,
        external_id TEXT NULL,
        created_at INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (business_id, id)
      )''');

    // ── Dữ liệu người bán: một khách, một sản phẩm, hai đơn ───────────────
    await db.customStatement(
      "INSERT INTO customers_table (id, business_id, name, phone, updated_at, "
      "created_at) VALUES ('c1', '$businessId', 'Chị Hoa', '+84912345678', 1, 1)",
    );
    await db.customStatement(
      "INSERT INTO products_table (id, business_id, sku, name, list_price, "
      "updated_at, created_at) "
      "VALUES ('p1', '$businessId', 'SKU-1', 'Nồi chiên không dầu', 1890000, 1, 1)",
    );
    const items =
        '[{"productId":"p1","productName":"Nồi chiên không dầu",'
        '"quantity":1,"unitPrice":1890000}]';
    for (final id in ['9f1c2b7a-uuid', 'sample-order-1']) {
      await db.customStatement(
        "INSERT INTO orders_table (id, business_id, customer_id, order_date, "
        "total_quantity, subtotal, total_amount, status, items, updated_at) "
        "VALUES ('$id', '$businessId', 'c1', 1, 1, 1890000, 1890000, "
        "'completed', '$items', 1)",
      );
    }
    // Một dòng trong bảng token chết — để chứng minh v18 xoá cả bảng lẫn dòng.
    await db.customStatement(
      "INSERT INTO integrations_table (id, business_id, provider, "
      "access_token_encrypted) VALUES ('i1', '$businessId', 'shopee', 'xxx')",
    );

    await db.customStatement('PRAGMA user_version = 16');

    // ⭐ Chống PASS GIẢ: chứng minh điểm XUẤT PHÁT đúng là v16 trước khi tin
    // bất kỳ kết luận nào về đích. Không có bước này, một test dựng nhầm
    // schema v20 rồi tự khen sẽ trông y hệt.
    final before = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
        )
        .get();
    final beforeTables = before.map((r) => r.read<String>('name')).toSet();
    expect(
      beforeTables,
      contains('integrations_table'),
      reason: 'v16 CÓ bảng token chết — nó là thứ v18 phải xoá',
    );
    for (final t in [
      'connections_table',
      'external_identities_table',
      'identity_link_events_table',
      'settlement_lines_table',
      'payouts_table',
      'proposed_changes_table',
      'business_actions_table',
      'agent_tasks_table',
    ]) {
      expect(
        beforeTables,
        isNot(contains(t)),
        reason: '$t không tồn tại ở v16 — migration phải là thứ tạo ra nó',
      );
    }
    await db.close();

    // ── Mở lại bằng schema hiện tại ⇒ v17→v18→v19→v20 chạy thật ──────────
    raw = NativeDatabase(file);
    db = AppDatabase.forExecutor(raw);

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    final after = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
        )
        .get();
    final afterTables = after.map((r) => r.read<String>('name')).toSet();
    final orders = await db
        .customSelect(
          'SELECT id, provenance_code FROM orders_table ORDER BY id',
        )
        .get();
    final indexRows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name NOT LIKE 'sqlite_autoindex%'",
        )
        .get();

    // Đọc lại qua REPOSITORY THẬT, không chỉ SQL thô: schema đúng mà tầng
    // domain đọc không ra thì vẫn là hỏng, và đó đúng là thứ người bán thấy.
    final loadedOrders = await DriftOrderRepository(db).loadAll();
    final loadedCustomers = await DriftCustomerRepository(db).loadAll();
    final identities = await DriftExternalIdentityRepository(
      db,
      now: () => DateTime(2026, 8, 8),
      newId: () => 'e1',
    ).loadForCustomer('c1');
    final settlements = await DriftSettlementRepository(
      db,
    ).loadForOrder('9f1c2b7a-uuid');
    final payouts = await DriftSettlementRepository(db).loadPayouts();

    await db.close();

    // 1 · chuỗi chạy tới cuối
    expect(
      version.read<int>('user_version'),
      kTongtaiSchemaVersion,
      reason: 'dừng giữa chừng là kịch bản tệ nhất — DB kẹt ở phiên bản lai',
    );

    // 2 · không mất dòng nào
    expect(orders, hasLength(2), reason: 'nâng cấp không được làm mất đơn');
    expect(loadedOrders.map((o) => o.id), containsAll(['9f1c2b7a-uuid']));
    expect(loadedCustomers.single.name, 'Chị Hoa');
    expect(loadedOrders.first.totalAmount, 1890000);

    // 3 · v17 KHÔNG backfill nguồn gốc
    for (final row in orders) {
      expect(
        row.read<String?>('provenance_code'),
        isNull,
        reason:
            'đơn có trước v17 không khai nguồn gốc; ghi suy đoán xuống đĩa là '
            'biến phỏng đoán thành lời khai',
      );
    }

    // 4 · v18 xoá bảng token
    expect(
      afterTables,
      isNot(contains('integrations_table')),
      reason: 'bảng mang 4 cột token phải biến mất cùng mọi dòng trong nó',
    );

    // 4b · ⭐ CHỈ MỤC UNIQUE phải có mặt — không chỉ bảng.
    //
    // Lỗi thật phát hiện 2026-08-08: `Migrator.createTable()` chỉ tạo BẢNG.
    // Chỉ mục khai bằng `@TableIndex` là thực thể riêng, và `createTable`
    // không đụng tới. Máy cài mới có đủ (onCreate gọi `createAll`), máy NÂNG
    // CẤP thì thiếu — và với chỉ mục UNIQUE thì đó là mất một ràng buộc đúng
    // đắn, không phải mất tốc độ:
    //
    // • `external_identities_lookup` giữ luật "cùng kết nối + nền tảng +
    //   externalId là DUY NHẤT" — mất nó là hai bản ghi cho một người mua.
    // • `business_actions_idempotency` giữ luật chống lặp — mất nó là hai lần
    //   `plan()` song song sinh hai hành động THẬT.
    //
    // Test hỏi "bảng có tồn tại không" sẽ không bao giờ thấy lỗi này.
    final indexes = indexRows.map((r) => r.read<String>('name')).toSet();
    for (final required in [
      'external_identities_lookup',
      'business_actions_idempotency',
      'proposed_changes_subject',
      'settlement_lines_order_id',
      'connections_connector',
      'agent_tasks_open_subject',
    ]) {
      expect(
        indexes,
        contains(required),
        reason:
            '$required thiếu sau nâng cấp — `createTable` không tạo chỉ mục; '
            'dùng `_createTableWithIndexes`',
      );
    }

    // 5 · v18/v19/v20 tạo đủ năm bảng mới, và chúng RỖNG
    for (final t in [
      'connections_table',
      'external_identities_table',
      'identity_link_events_table',
      'settlement_lines_table',
      'payouts_table',
      'proposed_changes_table',
      'business_actions_table',
      'agent_tasks_table',
    ]) {
      expect(afterTables, contains(t), reason: '$t phải được migration tạo ra');
    }
    expect(identities, isEmpty, reason: 'chưa connector nào ghi vào');
    expect(settlements, isEmpty);
    expect(payouts, isEmpty);
  });
  test('v20 CÓ DỮ LIỆU → v21: thêm bảng đề xuất, không mất gì', () async {
    // Mỗi phase của Epic WTM-297 thêm một bảng. Bài học WTM-295: chuỗi nâng
    // cấp phải được chạy trên DB CÓ DÒNG, không chỉ trên DB mới tạo.
    final dir = await Directory.systemTemp.createTemp('tongtai_upgrade21');
    final file = File('${dir.path}/t.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    var raw = NativeDatabase(file);
    var db = AppDatabase.forExecutor(raw);
    await const LocalWorkspace().ensureBusinessId(db);
    const businessId = LocalWorkspace.localBusinessId;

    // Hạ về hình dạng v21-trừ-một: xoá đúng bảng v21 thêm vào.
    await db.customStatement('DROP TABLE IF EXISTS proposed_changes_table');
    await db.customStatement(
      "INSERT INTO customers_table (id, business_id, name, updated_at, "
      "created_at) VALUES ('c1', '$businessId', 'Chị Hoa', 1, 1)",
    );
    await db.customStatement('PRAGMA user_version = 20');

    // Chống PASS GIẢ: chứng minh điểm xuất phát đúng là v20.
    final before = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'proposed_changes_table'",
        )
        .get();
    expect(
      before,
      isEmpty,
      reason: 'bảng đề xuất không tồn tại ở v20 — migration phải tạo ra nó',
    );
    await db.close();

    // Mở lại ⇒ v21 chạy thật.
    raw = NativeDatabase(file);
    db = AppDatabase.forExecutor(raw);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    final proposals = await db.select(db.proposedChangesTable).get();
    final customers = await db.select(db.customersTable).get();
    await db.close();

    expect(version.read<int>('user_version'), kTongtaiSchemaVersion);
    expect(customers, hasLength(1), reason: 'không mất dòng nào');
    expect(customers.single.name, 'Chị Hoa');
    expect(proposals, isEmpty, reason: 'bảng mới, chưa ai đề xuất gì');
  });
  test('v21 CÓ DỮ LIỆU → v22: thêm cửa ghi, không mất gì', () async {
    final dir = await Directory.systemTemp.createTemp('tongtai_upgrade22');
    final file = File('${dir.path}/t.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    var raw = NativeDatabase(file);
    var db = AppDatabase.forExecutor(raw);
    await const LocalWorkspace().ensureBusinessId(db);
    const businessId = LocalWorkspace.localBusinessId;

    await db.customStatement('DROP TABLE IF EXISTS business_actions_table');
    await db.customStatement(
      "INSERT INTO customers_table (id, business_id, name, updated_at, "
      "created_at) VALUES ('c1', '$businessId', 'Chị Hoa', 1, 1)",
    );
    await db.customStatement('PRAGMA user_version = 21');

    final before = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'business_actions_table'",
        )
        .get();
    expect(before, isEmpty, reason: 'bảng hành động không tồn tại ở v21');
    await db.close();

    raw = NativeDatabase(file);
    db = AppDatabase.forExecutor(raw);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    final actions = await db.select(db.businessActionsTable).get();
    final customers = await db.select(db.customersTable).get();
    // Ràng buộc duy nhất phải tồn tại thật, không chỉ nằm trong khai báo Dart.
    final indexes = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND tbl_name = 'business_actions_table'",
        )
        .get();
    await db.close();

    expect(version.read<int>('user_version'), kTongtaiSchemaVersion);
    expect(customers, hasLength(1), reason: 'không mất dòng nào');
    expect(actions, isEmpty);
    expect(
      indexes.map((r) => r.read<String>('name')),
      contains('business_actions_idempotency'),
      reason: 'khoá chống lặp phải là ràng buộc CỦA CƠ SỞ DỮ LIỆU',
    );
  });
  test('v22 CÓ DỮ LIỆU → v23: thêm hàng đợi việc, không mất gì', () async {
    final dir = await Directory.systemTemp.createTemp('tongtai_upgrade23');
    final file = File('${dir.path}/t.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    var raw = NativeDatabase(file);
    var db = AppDatabase.forExecutor(raw);
    await const LocalWorkspace().ensureBusinessId(db);
    const businessId = LocalWorkspace.localBusinessId;

    await db.customStatement('DROP TABLE IF EXISTS agent_tasks_table');
    await db.customStatement(
      "INSERT INTO customers_table (id, business_id, name, updated_at, "
      "created_at) VALUES ('c1', '$businessId', 'Chị Hoa', 1, 1)",
    );
    await db.customStatement('PRAGMA user_version = 22');

    final before = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'agent_tasks_table'",
        )
        .get();
    expect(before, isEmpty, reason: 'hàng đợi không tồn tại ở v22');
    await db.close();

    raw = NativeDatabase(file);
    db = AppDatabase.forExecutor(raw);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    final tasks = await db.select(db.agentTasksTable).get();
    final customers = await db.select(db.customersTable).get();
    await db.close();

    expect(version.read<int>('user_version'), kTongtaiSchemaVersion);
    expect(customers, hasLength(1), reason: 'không mất dòng nào');
    expect(tasks, isEmpty);
  });
  test(
    'v26 CÓ DỮ LIỆU → v27: bốn bảng thuộc tính + chỉ mục UNIQUE, không mất gì',
    () async {
      // WTM-334 — tầng thuộc tính động, thuần thêm bốn bảng. Bài học WTM-227:
      // chuỗi nâng cấp phải chạy trên DB CÓ DÒNG, không chỉ trên DB mới tạo.
      final dir = await Directory.systemTemp.createTemp('tongtai_upgrade27');
      final file = File('${dir.path}/t.sqlite');
      addTearDown(() => dir.delete(recursive: true));

      var raw = NativeDatabase(file);
      var db = AppDatabase.forExecutor(raw);
      await const LocalWorkspace().ensureBusinessId(db);
      const businessId = LocalWorkspace.localBusinessId;

      // Hạ về hình dạng v26-trừ-bốn: xoá đúng bốn bảng v27 thêm vào. `PRAGMA
      // foreign_keys` đang BẬT (beforeOpen), nên xoá bảng CHA trước khi xoá con
      // để lại tham chiếu khoá ngoại treo — xoá con trước.
      for (final t in [
        'attribute_group_items_table',
        'attribute_values_table',
        'attribute_definitions_table',
        'attribute_groups_table',
      ]) {
        await db.customStatement('DROP TABLE IF EXISTS $t');
      }
      await db.customStatement(
        "INSERT INTO products_table (id, business_id, sku, name, list_price, "
        "updated_at, created_at) "
        "VALUES ('p1', '$businessId', 'SKU-1', 'Loa bluetooth', 450000, 1, 1)",
      );
      await db.customStatement('PRAGMA user_version = 26');

      // Chống PASS GIẢ: chứng minh điểm xuất phát đúng là v26.
      final before = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name LIKE 'attribute_%'",
          )
          .get();
      expect(
        before,
        isEmpty,
        reason:
            'bốn bảng thuộc tính không tồn tại ở v26 — migration phải tạo ra',
      );
      await db.close();

      // Mở lại ⇒ v27 chạy thật.
      raw = NativeDatabase(file);
      db = AppDatabase.forExecutor(raw);
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      final tables =
          (await db
                  .customSelect(
                    "SELECT name FROM sqlite_master WHERE type = 'table' "
                    "AND name LIKE 'attribute_%' ORDER BY name",
                  )
                  .get())
              .map((r) => r.read<String>('name'))
              .toSet();
      final indexes =
          (await db
                  .customSelect(
                    "SELECT name FROM sqlite_master WHERE type = 'index' "
                    "AND name NOT LIKE 'sqlite_autoindex%'",
                  )
                  .get())
              .map((r) => r.read<String>('name'))
              .toSet();
      final products = await db.select(db.productsTable).get();
      final definitions = await db.select(db.attributeDefinitionsTable).get();
      await db.close();

      expect(version.read<int>('user_version'), kTongtaiSchemaVersion);
      expect(
        tables,
        containsAll([
          'attribute_definitions_table',
          'attribute_groups_table',
          'attribute_values_table',
          'attribute_group_items_table',
        ]),
      );
      // ⭐ Chỉ mục UNIQUE phải có mặt — không chỉ bảng. `createTable` không tạo
      // chỉ mục (P-32); mất `attribute_definitions_code` là mất luật "trùng code
      // trong cùng scope ⇒ chặn" trên máy nâng cấp.
      expect(
        indexes,
        containsAll([
          'attribute_definitions_code',
          'attribute_groups_code',
          'attribute_values_unique',
          'attribute_group_items_unique',
        ]),
      );
      expect(
        products,
        hasLength(1),
        reason: 'nâng cấp không được làm mất sản phẩm',
      );
      expect(products.single.name, 'Loa bluetooth');
      expect(definitions, isEmpty, reason: 'bảng mới, chưa ai tạo thuộc tính');
    },
  );
}
