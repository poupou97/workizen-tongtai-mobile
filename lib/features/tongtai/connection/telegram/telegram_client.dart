import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Bot API của Telegram — WTM-318 (C2 · Epic WTM-315).
///
/// ## Vì sao Telegram là connector mobile **rẻ nhất** trong cả danh sách
///
/// Không OAuth, không client ID, không đăng ký ứng dụng, không xét duyệt. Một
/// bot token dán vào là chạy, và mọi lời gọi là HTTPS thuần — nên nó chạy
/// **thẳng từ máy**, không cần một mẩu backend nào (WTM-309: DIRECT MOBILE).
///
/// ## ⭐ Điều quan trọng nhất phải biết về Telegram bot
///
/// **Bot KHÔNG nhắn trước được cho ai cả.** Người ta phải mở chat với bot và
/// bấm `/start` thì bot mới có `chat_id` để trả lời.
///
/// Đây không phải hạn chế kỹ thuật tạm thời — đó là thiết kế chống spam của
/// Telegram, và nó quyết định **Telegram dùng được vào việc gì**:
///
/// | Việc | Được không |
/// |---|---|
/// | Tổng Tài nhắn cho **chủ shop** | ✅ chủ shop tự bấm `/start` một lần |
/// | Tổng Tài nhắn cho **khách đã chat với bot** | ✅ |
/// | Tổng Tài nhắn cho một khách bất kỳ trong danh bạ | ❌ **không bao giờ** |
///
/// Nên hàng "gửi tin nhắn chăm sóc khách" **không** chạy bằng Telegram bot; nó
/// vẫn ở diễn tập cho tới khi có một kênh thật sự nhắn trước được (Zalo OA,
/// SMS). Viết điều này ra ở đây vì nếu không, ai đó sẽ dựng xong đường gửi
/// khách rồi mới phát hiện — vào đúng ngày demo.
class TelegramClient {
  TelegramClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _base = 'https://api.telegram.org/bot';

  /// Kiểm tra token có thật không, và bot tên gì.
  ///
  /// Đây là thứ biến luật "không fake connected" (§8) thành **cơ chế**: dán
  /// một chuỗi bậy vào thì `getMe` hỏng, nên kết nối không bao giờ lên
  /// `ACTIVE`. Không có bước này thì trạng thái chỉ phản ánh việc *có ai đó
  /// bấm nút*, chứ không phản ánh việc *có gọi được API hay không*.
  Future<TelegramBot> getMe(String token) async {
    final result = await _call(token, 'getMe');
    final username = result['username'];
    if (username is! String) {
      throw const TelegramException(
        TelegramFailure.unexpected,
        'Telegram trả lời nhưng không có tên bot',
      );
    }
    return TelegramBot(
      id: '${result['id']}',
      username: username,
      firstName: result['first_name'] as String? ?? username,
    );
  }

  /// Gửi một tin nhắn. Trả về `message_id` — mã **tra được** trên Telegram.
  Future<String> sendMessage({
    required String token,
    required String chatId,
    required String text,
  }) async {
    final result = await _call(token, 'sendMessage', {
      'chat_id': chatId,
      'text': text,
      // `disable_web_page_preview`: bản tin sáng có thể chứa link; ảnh xem
      // trước sẽ đẩy chính nội dung xuống dưới màn hình điện thoại.
      'disable_web_page_preview': true,
    });
    final id = result['message_id'];
    if (id == null) {
      throw const TelegramException(
        TelegramFailure.unexpected,
        'Telegram nhận tin nhưng không trả về mã tin nhắn',
      );
    }
    return '$id';
  }

  /// Các cuộc trò chuyện đã nhắn cho bot — để **tìm ra** `chat_id`.
  ///
  /// Bắt người bán tự gõ `chat_id` là bắt họ đi tìm một con số họ không có
  /// cách nào biết. Ở đây họ chỉ cần bấm `/start` trong Telegram rồi bấm
  /// "Tìm cuộc trò chuyện" — con số do máy đọc, không do người gõ.
  ///
  /// ⚠️ Telegram chỉ giữ update **24 giờ**. Bấm `/start` từ hôm qua rồi hôm
  /// nay mới tìm thì danh sách rỗng — và rỗng ở đây nghĩa là *"chưa thấy ai
  /// nhắn"*, không phải *"hỏng"*.
  Future<List<TelegramChat>> discoverChats(String token) async {
    final res = await _client.post(
      Uri.parse('$_base$token/getUpdates'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'limit': 100,
        'allowed_updates': ['message'],
      }),
    );
    final body = _decode(res);
    final updates = body['result'];
    if (updates is! List) return const [];

    // Gộp theo chat: một người nhắn mười câu vẫn là một cuộc trò chuyện.
    final seen = <String, TelegramChat>{};
    for (final update in updates) {
      if (update is! Map) continue;
      final message = update['message'];
      if (message is! Map) continue;
      final chat = message['chat'];
      if (chat is! Map || chat['id'] == null) continue;
      final id = '${chat['id']}';
      seen[id] = TelegramChat(
        id: id,
        title: [
          chat['title'],
          chat['first_name'],
          chat['last_name'],
        ].whereType<String>().join(' ').trim(),
        username: chat['username'] as String?,
      );
    }
    return seen.values.toList();
  }

  Future<Map<String, dynamic>> _call(
    String token,
    String method, [
    Map<String, Object?>? params,
  ]) async {
    final http.Response res;
    try {
      res = await _client.post(
        Uri.parse('$_base$token/$method'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(params ?? const {}),
      );
    } on http.ClientException catch (e) {
      throw TelegramException(TelegramFailure.network, e.message);
    }
    final body = _decode(res);
    final result = body['result'];
    if (result is Map<String, dynamic>) return result;
    throw const TelegramException(
      TelegramFailure.unexpected,
      'phản hồi không có phần result',
    );
  }

  /// Telegram trả **200 kèm `ok: false`** cho nhiều lỗi, nên chỉ nhìn mã HTTP
  /// là bỏ sót. Đọc cả hai.
  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(res.body);
      body = decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      throw TelegramException(
        TelegramFailure.unexpected,
        'phản hồi không phải JSON (HTTP ${res.statusCode})',
      );
    }

    if (body['ok'] == true) return body;

    final description = body['description'] as String?;
    final code = body['error_code'] as int? ?? res.statusCode;
    throw TelegramException(switch (code) {
      401 => TelegramFailure.unauthorized,
      403 => TelegramFailure.blocked,
      400 => TelegramFailure.badRequest,
      429 => TelegramFailure.rateLimited,
      >= 500 => TelegramFailure.temporary,
      _ => TelegramFailure.unexpected,
    }, description);
  }
}

/// Bot đứng sau token.
@immutable
class TelegramBot {
  const TelegramBot({
    required this.id,
    required this.username,
    required this.firstName,
  });

  final String id;

  /// `@tongtai_bot` — thứ người bán nhận ra trong Telegram.
  final String username;

  final String firstName;
}

/// Một cuộc trò chuyện đã nhắn cho bot.
@immutable
class TelegramChat {
  const TelegramChat({required this.id, required this.title, this.username});

  final String id;

  /// Tên hiển thị. Có thể rỗng — Telegram không bắt buộc.
  final String title;

  final String? username;

  /// Nhãn cho người bán chọn: ưu tiên tên, rồi `@username`, cuối cùng là mã.
  String get label =>
      title.isNotEmpty ? title : (username != null ? '@$username' : id);
}

/// Vì sao một lời gọi Telegram không thành.
enum TelegramFailure {
  /// 401 — token sai hoặc đã bị BotFather thu hồi.
  unauthorized,

  /// 403 — người dùng **chặn bot**, hoặc chưa bao giờ `/start`.
  ///
  /// Đây là lỗi hay gặp nhất trong thực tế và cũng là lỗi dễ hiểu nhầm nhất:
  /// nó **không** có nghĩa là token hỏng.
  blocked,

  /// 400 — `chat_id` không tồn tại, nội dung rỗng…
  badRequest,

  /// 429 — gửi quá nhanh.
  rateLimited,

  temporary,
  network,
  unexpected,
}

class TelegramException implements Exception {
  const TelegramException(this.failure, [this.detail]);

  final TelegramFailure failure;

  /// Chỉ hiện trên máy người dùng; telemetry chỉ nhận `failure` (ADR-TON-017).
  final String? detail;

  @override
  String toString() => 'TelegramException(${failure.name})';
}
