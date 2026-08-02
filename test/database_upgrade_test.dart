import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/database/migrations/tongtai_migrations.dart';

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
}
