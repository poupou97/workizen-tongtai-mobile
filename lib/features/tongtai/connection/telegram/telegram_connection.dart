import '../../core/connection.dart';
import '../connection_capability.dart';
import '../connection_credential_store.dart';
import '../connection_service.dart';
import 'telegram_client.dart';

/// Vòng đời kết nối Telegram — WTM-318.
///
/// ## Hai bước, và bước thứ hai mới là bước khó
///
/// 1. **Dán bot token** — dễ, BotFather đưa sẵn.
/// 2. **Biết gửi cho ai** — Telegram bot không nhắn trước được, nên phải có
///    `chat_id` của một cuộc trò chuyện *đã tồn tại*.
///
/// Bước 2 là chỗ mọi hướng dẫn trên mạng bảo người dùng "mở
/// `api.telegram.org/bot<token>/getUpdates` trên trình duyệt rồi tự tìm con
/// số". Ở đây máy làm việc đó: người bán bấm `/start` trong Telegram, rồi bấm
/// một nút, và chọn cuộc trò chuyện theo **tên**.
///
/// Một con số người dùng phải tự chép là một con số sẽ bị chép sai.
class TelegramConnection {
  TelegramConnection({required this._connections, required this._client});

  final ConnectionService _connections;
  final TelegramClient _client;

  Future<Connection> ensure({String label = 'Telegram'}) =>
      _connections.ensure(kTelegramConnectorId, label: label);

  /// Lưu bot token — **sau khi Telegram xác nhận nó thật**.
  ///
  /// Kết nối chỉ lên `ACTIVE` khi `getMe` chạy được. Đó là luật §8 làm thành
  /// cơ chế: trạng thái phản ánh *gọi được API hay không*, không phản ánh
  /// *có ai bấm nút hay không*.
  ///
  /// Chưa có `chat_id` thì vẫn giữ ở `SETUP_REQUIRED`: token đúng nhưng chưa
  /// biết gửi cho ai thì chưa gửi được gì — nói "đã kết nối" lúc này là nói
  /// một nửa sự thật, và nửa còn lại sẽ hiện ra dưới dạng một tin nhắn không
  /// bao giờ tới.
  Future<TelegramSetup> attachToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      return const TelegramSetup.failed(TelegramFailure.unauthorized);
    }

    final connection = await ensure();
    final TelegramBot bot;
    try {
      bot = await _client.getMe(trimmed);
    } on TelegramException catch (e) {
      // Token hỏng ⇒ **không** ghi gì cả. Lưu một token sai rồi đánh dấu
      // `error` sẽ để một bí mật vô dụng nằm lại trong Keystore.
      return TelegramSetup.failed(e.failure);
    }

    final previous =
        await _connections.credentials.read(connection) ?? const {};
    await _connections.credentials.write(connection, {
      ...previous,
      CredentialField.token: trimmed,
    });
    // Đổi tên kết nối thành tên bot — người bán nhận ra `@tongtai_bot` chứ
    // không nhận ra chữ "Telegram".
    final chatId = previous[CredentialField.chatId];
    final updated = connection.copyWith(
      label: '@${bot.username}',
      status: chatId == null || chatId.isEmpty
          ? ConnectionStatus.setupRequired
          : ConnectionStatus.active,
    );
    await _connections.repository.upsert(updated);
    return TelegramSetup.ok(bot);
  }

  /// Các cuộc trò chuyện đã nhắn cho bot — để người bán **chọn**, không gõ.
  Future<List<TelegramChat>> discoverChats() async {
    final token = await _token();
    if (token == null) return const [];
    return _client.discoverChats(token);
  }

  /// Chốt nơi nhận. Đây là bước cuối biến kết nối thành `ACTIVE`.
  Future<Connection?> attachChat(String chatId) async {
    final connection = await ensure();
    final stored = await _connections.credentials.read(connection);
    if (stored == null || (stored[CredentialField.token] ?? '').isEmpty) {
      return null;
    }
    return _connections.attachCredentials(connection, {
      ...stored,
      CredentialField.chatId: chatId,
    });
  }

  /// Gửi một tin. Trả về `message_id`.
  ///
  /// Ném khi chưa thiết lập xong — chỗ gọi là một `ActionEffect`, nên ném
  /// đúng nghĩa là "hành động `failed`, thử lại được", không phải "mất dấu".
  Future<String> send(String text) async {
    final token = await _token();
    final chatId = await _chatId();
    if (token == null || chatId == null) {
      throw StateError(
        'Telegram chưa thiết lập xong — thiếu ${token == null ? 'bot token' : 'nơi nhận'}',
      );
    }
    return _client.sendMessage(token: token, chatId: chatId, text: text);
  }

  /// Đã đủ để gửi chưa — token **và** nơi nhận.
  Future<bool> get isReady async =>
      await _token() != null && await _chatId() != null;

  Future<void> disconnect() async => _connections.disconnect(await ensure());

  Future<String?> _token() async => _field(CredentialField.token);

  Future<String?> _chatId() async => _field(CredentialField.chatId);

  Future<String?> _field(String name) async {
    final stored = await _connections.credentials.read(await ensure());
    final value = stored?[name];
    return value == null || value.isEmpty ? null : value;
  }
}

/// Kết quả dán token — phân loại ở đây để `ui/` không phải catch (ADR-TON-017).
class TelegramSetup {
  const TelegramSetup.ok(this.bot) : failure = null;

  const TelegramSetup.failed(this.failure) : bot = null;

  /// `null` khi hỏng.
  final TelegramBot? bot;

  /// `null` khi thành công.
  final TelegramFailure? failure;

  bool get succeeded => bot != null;
}
