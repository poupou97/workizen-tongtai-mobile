import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/database/migrations/tongtai_migrations.dart';
import 'package:tongtai/features/tongtai/core/connection.dart';

/// WTM-283 (N0.2) — **Connection**, và cái bảng nó thay thế.
///
/// Phần đáng khoá không phải "có bảng mới". Là hai lời hứa về bí mật:
///
/// * `CredentialReference` **không nhận được** một bí mật, kể cả do nhầm —
///   khoá tra được *suy ra*, không được truyền vào. Một lớp
///   `CredentialReference(String)` tuân thủ luật credential trên giấy rồi vi
///   phạm nó ngay lần đầu ai đó viết `CredentialReference(token)`, vì trình
///   biên dịch không phân biệt được khoá tra với token — cả hai là `String`;
/// * `connections_table` **không có cột nào** cho token, và cũng không có cột
///   cho khoá tra — nên không có gì để rò rỉ qua `.ttbk` (mặc định *không*
///   mã hoá).
///
/// Và `integrations_table` phải thật sự biến mất khỏi cơ sở dữ liệu của người
/// bán, không chỉ khỏi mã nguồn.
void main() {
  group('CredentialReference — con trỏ, không phải bí mật', () {
    test('khoá tra suy ra từ id, có tiền tố chung', () {
      final ref = CredentialReference.forConnection('conn-1');
      expect(ref.key, 'tongtai.connection.conn-1');
      expect(ref.key, startsWith(CredentialReference.kCredentialKeyPrefix));
    });

    test('cùng một kết nối ⇒ cùng một khoá (suy ra, nên ổn định)', () {
      expect(
        CredentialReference.forConnection('c'),
        CredentialReference.forConnection('c'),
      );
    });

    test('Connection tự suy ra khoá của mình — không lưu ở đâu cả', () {
      final c = Connection(
        id: 'gh-1',
        connectorId: 'github',
        label: 'Shop chính',
        status: ConnectionStatus.active,
        createdAt: DateTime(2026, 8, 7),
      );
      expect(c.credential.key, 'tongtai.connection.gh-1');
    });

    test('toString KHÔNG bao giờ lộ gì hơn tên khoá', () {
      // Crash reporter ghi lại toString(); bài học WTM-148 (`detail` bị bỏ
      // khỏi TongtaiFailure.toString vì đúng lý do này).
      final s = CredentialReference.forConnection('x').toString();
      expect(s, 'CredentialReference(tongtai.connection.x)');
    });
  });

  group('ConnectionStatus', () {
    test('mã lạ ⇒ null, KHÔNG rơi về active', () {
      for (final bad in [null, '', 'Active', 'đang chạy', 'ok']) {
        expect(
          ConnectionStatus.fromCode(bad),
          isNull,
          reason:
              'một kết nối hỏng trông như đang chạy khiến người bán tưởng dữ '
              'liệu vẫn về, trong khi nó đã dừng từ lâu',
        );
      }
    });

    test('bốn mã canonical — SETUP_REQUIRED đứng đầu', () {
      expect(ConnectionStatus.values.map((s) => s.code).toList(), [
        'setup_required',
        'active',
        'paused',
        'error',
      ]);
    });

    test('SETUP_REQUIRED khác ERROR — chưa xong không phải là hỏng', () {
      // WTM-317: không có mã này thì chỗ duy nhất để đặt một kết nối dở dang
      // là `error`, và `error` nói sai chuyện — giao diện sẽ giục người bán
      // "sửa" một thứ chưa bao giờ hỏng.
      expect(ConnectionStatus.setupRequired, isNot(ConnectionStatus.error));
      expect(
        ConnectionStatus.fromCode('setup_required'),
        ConnectionStatus.setupRequired,
      );
    });
  });

  group('lược đồ — bảng token phải thật sự biến mất', () {
    test('connections_table KHÔNG có cột nào chứa hoặc trỏ tới bí mật', () async {
      final db = AppDatabase.forExecutor(NativeDatabase.memory());
      addTearDown(db.close);

      final info = await db
          .customSelect("PRAGMA table_info('connections_table')")
          .get();
      final columns = info.map((r) => r.read<String>('name')).toSet();

      expect(columns, isNotEmpty, reason: 'bảng phải tồn tại');
      for (final c in columns) {
        expect(
          RegExp(
            r'token|secret|key|credential|password',
            caseSensitive: false,
          ).hasMatch(c),
          isFalse,
          reason:
              'cột "$c" mang tên gợi ý bí mật; luật credential của Founder cấm '
              'cả token LẪN đường đi tới token nằm trong DB nghiệp vụ',
        );
      }
    });

    test('integrations_table không còn trong lược đồ mới', () async {
      final db = AppDatabase.forExecutor(NativeDatabase.memory());
      addTearDown(db.close);
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' "
            "AND name='integrations_table'",
          )
          .get();
      expect(rows, isEmpty);
    });
  });

  test(
    'v17 có integrations_table → v18: bảng token bị XOÁ khỏi máy người bán',
    () async {
      final dir = await Directory.systemTemp.createTemp('tongtai_upgrade18');
      final file = File('${dir.path}/t.sqlite');
      addTearDown(() => dir.delete(recursive: true));

      // ── Dựng đúng hình dạng v17: có integrations_table với 4 cột token ────
      var raw = NativeDatabase(file);
      var db = AppDatabase.forExecutor(raw);
      await db.customStatement('DROP TABLE IF EXISTS connections_table');
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
      await db.customStatement('PRAGMA user_version = 17');
      await db.close();

      // ── Mở lại bằng schema hiện tại ⇒ onUpgrade chạy thật ────────────────
      raw = NativeDatabase(file);
      db = AppDatabase.forExecutor(raw);
      final gone = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' "
            "AND name='integrations_table'",
          )
          .get();
      final created = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' "
            "AND name='connections_table'",
          )
          .get();
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      await db.close();

      expect(
        gone,
        isEmpty,
        reason:
            'bảng mang 4 cột token phải biến mất khỏi máy người bán, không chỉ '
            'khỏi mã nguồn — nó chưa từng có dòng nào nên không có gì để mất',
      );
      expect(created, hasLength(1), reason: 'connections_table phải được tạo');
      expect(version.read<int>('user_version'), kTongtaiSchemaVersion);
    },
  );
}
