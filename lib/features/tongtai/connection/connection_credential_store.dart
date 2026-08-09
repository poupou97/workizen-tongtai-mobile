import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/connection.dart';

/// Nơi bí mật của kết nối **thật sự** nằm — WTM-317.
///
/// ## Luật, và cách lớp này làm luật thành cấu trúc
///
/// Founder: *"Không lưu token trong SQLite nghiệp vụ. Database chỉ giữ
/// credential reference."*
///
/// `CredentialReference` (WTM-283) đã lo nửa đầu: khoá tra **suy ra** từ
/// `connectionId`, không nhận chuỗi, nên không có đường nào để một bí mật lọt
/// vào kiểu đó — kể cả do nhầm.
///
/// Lớp này lo nửa sau: giá trị đi **thẳng** vào Keychain/Keystore, không đi
/// qua một lớp trung gian nào có thể vô tình ghi xuống đĩa.
///
/// ## Vì sao giá trị là một Map, không phải một String
///
/// Telegram cần một chuỗi (bot token). Atlassian cần **ba** (instance URL,
/// email, API token) — và hai trong ba **không phải bí mật**.
///
/// Nếu kiểu ở đây là `String`, mỗi vendor sẽ tự nghĩ ra một cách nhồi ba giá
/// trị vào một chuỗi, và cách nào cũng sẽ khác nhau. Nên nó là `Map`, mã hoá
/// JSON, **toàn bộ** nằm trong secure storage — kể cả phần không bí mật.
///
/// Đặt cả cụm vào một chỗ có một lợi ích thật: xoá kết nối là xoá **một** khoá,
/// không phải nhớ có bao nhiêu mảnh rải đâu.
abstract interface class ConnectionCredentialStore {
  /// Giá trị đã lưu, hoặc `null` khi kết nối chưa được thiết lập.
  Future<Map<String, String>?> read(Connection connection);

  /// Ghi đè toàn bộ cụm giá trị.
  Future<void> write(Connection connection, Map<String, String> value);

  /// Xoá — dùng khi người bán ngắt kết nối.
  Future<void> delete(Connection connection);

  /// Có credential không. **Đây là câu trả lời cho "đã kết nối chưa"** —
  /// không phải một cột trong cơ sở dữ liệu.
  Future<bool> has(Connection connection);
}

/// Bản production trên Keychain (iOS) / Keystore (Android).
class SecureConnectionCredentialStore implements ConnectionCredentialStore {
  SecureConnectionCredentialStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<Map<String, String>?> read(Connection connection) async {
    final raw = await _storage.read(key: connection.credential.key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return {
        for (final e in decoded.entries)
          if (e.key is String && e.value is String)
            e.key as String: e.value as String,
      };
    } on FormatException {
      // Bản ghi hỏng ⇒ coi như **chưa có**, không đoán.
      // Đoán ở đây là đoán về một bí mật.
      return null;
    }
  }

  @override
  Future<void> write(Connection connection, Map<String, String> value) =>
      _storage.write(key: connection.credential.key, value: jsonEncode(value));

  @override
  Future<void> delete(Connection connection) =>
      _storage.delete(key: connection.credential.key);

  @override
  Future<bool> has(Connection connection) async {
    final v = await read(connection);
    return v != null && v.isNotEmpty;
  }
}

/// Bản trong bộ nhớ cho test — **không** ghi ra đĩa.
class InMemoryConnectionCredentialStore implements ConnectionCredentialStore {
  final Map<String, Map<String, String>> _values = {};

  @override
  Future<Map<String, String>?> read(Connection connection) async =>
      _values[connection.credential.key];

  @override
  Future<void> write(Connection connection, Map<String, String> value) async {
    _values[connection.credential.key] = Map.of(value);
  }

  @override
  Future<void> delete(Connection connection) async {
    _values.remove(connection.credential.key);
  }

  @override
  Future<bool> has(Connection connection) async =>
      _values[connection.credential.key]?.isNotEmpty ?? false;

  /// Chỉ dùng trong test — để khẳng định **cái gì** đã được lưu ở đâu.
  Map<String, Map<String, String>> get debugAll => Map.unmodifiable(_values);
}

/// Tên trường trong cụm credential. Từ vựng đóng để hai vendor không tự đặt
/// hai cái tên cho cùng một thứ.
abstract final class CredentialField {
  /// Bot token · PAT · API token · access token.
  static const String token = 'token';

  /// Refresh token OAuth.
  static const String refreshToken = 'refresh_token';

  /// Hạn của access token, ISO-8601.
  static const String expiresAt = 'expires_at';

  /// Không bí mật, nhưng đi cùng cụm: URL instance (Atlassian).
  static const String instanceUrl = 'instance_url';

  /// Không bí mật: email tài khoản (Atlassian dùng Basic auth).
  static const String email = 'email';

  /// Không bí mật: chat id mặc định (Telegram).
  static const String chatId = 'chat_id';
}
