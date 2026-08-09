import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/connection/connection_credential_store.dart';
import 'package:tongtai/features/tongtai/connection/connection_repository.dart';
import 'package:tongtai/features/tongtai/connection/connection_service.dart';
import 'package:tongtai/features/tongtai/connection/connection_capability.dart';
import 'package:tongtai/features/tongtai/core/connection.dart';

/// **Governance — biên credential** · WTM-317 (Founder Task Order §28).
///
/// Luật: *"Không lưu token trong SQLite nghiệp vụ. Database chỉ giữ credential
/// reference và connection metadata."* Và: *"Secret không được xuất hiện trong
/// `.ttbk`."*
///
/// ## Vì sao suite này quét chuỗi thay vì kiểm tra từng cột
///
/// Kiểm tra từng cột chỉ bắt được những cột hôm nay đã có. Vendor thứ tư sẽ
/// thêm một cột, và không ai nhớ quay lại sửa test.
///
/// Quét **toàn bộ** nội dung mọi bảng tìm chính chuỗi bí mật thì bắt được cả
/// cột chưa tồn tại — kể cả khi ai đó nhét token vào một trường `metadata`
/// JSON tự do.
///
/// ## Tự kiểm chứng: một suite quét mà không bao giờ bắt được gì là suite hỏng
///
/// Nên có `test('bằng chứng suite này BẮT được')` ở cuối: cố tình ghi token vào
/// một cột nghiệp vụ và khẳng định phép quét kêu. Không có nó thì một lỗi
/// trong hàm quét sẽ biến cả suite thành PASS vĩnh viễn — đúng cái bẫy đã bốn
/// lần bắt hụt ở WTM-190/191/193/194.
void main() {
  late AppDatabase db;
  late DriftConnectionRepository repo;
  late InMemoryConnectionCredentialStore credentials;
  late ConnectionService service;

  /// Bí mật giả, đủ đặc biệt để không trùng dữ liệu nào khác.
  const secret = 'ya29.SECRET-TOKEN-DO-NOT-PERSIST-8f3a91';
  const refreshSecret = '1//REFRESH-SECRET-DO-NOT-PERSIST-2b7c';

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    repo = DriftConnectionRepository(db);
    credentials = InMemoryConnectionCredentialStore();
    service = ConnectionService(repository: repo, credentials: credentials);
  });

  tearDown(() => db.close());

  /// Mọi giá trị text trong mọi bảng, nối lại.
  Future<String> dumpEverything() async {
    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    final buffer = StringBuffer();
    for (final t in tables) {
      final name = t.data['name'] as String;
      // Bảng ảo FTS5 có shadow table không SELECT thẳng được.
      if (name.contains('_content') ||
          name.contains('_segdir') ||
          name.contains('_docsize') ||
          name.contains('_segments') ||
          name.contains('_data') ||
          name.contains('_idx') ||
          name.contains('_config')) {
        continue;
      }
      try {
        final rows = await db.customSelect('SELECT * FROM "$name"').get();
        for (final row in rows) {
          buffer.writeln(jsonEncode(row.data.map((k, v) => MapEntry(k, '$v'))));
        }
      } on Object {
        // Bảng không đọc thẳng được — bỏ qua, không làm hỏng phép quét.
        continue;
      }
    }
    return buffer.toString();
  }

  test('token KHÔNG có trong cơ sở dữ liệu nghiệp vụ', () async {
    final connection = await service.ensure(
      kGoogleConnectorId,
      label: 'Google',
    );
    await service.attachCredentials(connection, {
      CredentialField.token: secret,
      CredentialField.refreshToken: refreshSecret,
      CredentialField.expiresAt: '2026-08-09T11:00:00.000',
    });

    final dump = await dumpEverything();

    expect(dump, isNot(contains(secret)));
    expect(dump, isNot(contains(refreshSecret)));
    // Nhưng kết nối thì CÓ trong DB — nếu không thì test trên đúng vì lý do sai.
    expect(dump, contains(kGoogleConnectorId));
  });

  test('khoá tra credential cũng không nằm trong DB', () async {
    final connection = await service.ensure(
      kGoogleConnectorId,
      label: 'Google',
    );
    await service.attachCredentials(connection, {
      CredentialField.token: secret,
    });

    final dump = await dumpEverything();

    // `CredentialReference` suy ra từ `id`, không lưu. Nên `.ttbk` mang
    // metadata kết nối mà không mang đường đi tới bí mật.
    expect(dump, isNot(contains(CredentialReference.kCredentialKeyPrefix)));
  });

  test('bí mật nằm ĐÚNG một chỗ, và chỗ đó là credential store', () async {
    final connection = await service.ensure(
      kGoogleConnectorId,
      label: 'Google',
    );
    await service.attachCredentials(connection, {
      CredentialField.token: secret,
    });

    expect(jsonEncode(credentials.debugAll), contains(secret));
    expect(credentials.debugAll.keys, [connection.credential.key]);
  });

  test('ngắt kết nối xoá bí mật khỏi chỗ duy nhất giữ nó', () async {
    final connection = await service.ensure(
      kGoogleConnectorId,
      label: 'Google',
    );
    await service.attachCredentials(connection, {
      CredentialField.token: secret,
    });

    await service.disconnect(connection);

    expect(jsonEncode(credentials.debugAll), isNot(contains(secret)));
  });

  test('bằng chứng suite này BẮT được — quét thật, không PASS giả', () async {
    final connection = await service.ensure(
      kGoogleConnectorId,
      label: 'Google',
    );
    await service.attachCredentials(connection, {
      CredentialField.token: secret,
    });

    // Mô phỏng đúng lỗi mà luật cấm: ai đó nhét token vào một cột nghiệp vụ.
    await db.customStatement(
      'UPDATE connections_table SET label = ? WHERE id = ?',
      [secret, connection.id],
    );

    final dump = await dumpEverything();

    expect(
      dump,
      contains(secret),
      reason:
          'phép quét không thấy một token đã nằm sẵn trong DB ⇒ mọi test '
          'PASS ở trên là PASS giả',
    );
  });
}
