import 'package:flutter/foundation.dart';

/// **Một kết nối, nhiều khả năng** — WTM-317 (C1 · Epic WTM-315).
///
/// ## Vì sao capability tách khỏi connection
///
/// Founder §5: *"Google Connection → Drive Backup · Gmail · Calendar ·
/// Contacts"* — **một** tài khoản, nhiều thứ làm được, và mỗi thứ bật riêng.
///
/// Gộp chúng lại thành `connectorId: 'google_drive'` sẽ ép người bán đăng nhập
/// Google **lần nữa** khi họ muốn đọc Gmail. Tệ hơn: nó khuyến khích xin sẵn
/// mọi quyền ngay lần đầu, đúng thứ Incremental Permission cấm.
///
/// ## ⭐ Quyền đi theo CAPABILITY, không đi theo connection
///
/// Người bán bật *Sao lưu Drive* ⇒ xin `drive.file`, **không** xin Gmail.
/// Sau này họ bật *Đọc thư khách* ⇒ **lúc đó** mới xin `gmail.readonly`.
///
/// Đây là chỗ dễ sai nhất và cũng là chỗ Google soi gắt nhất: `auth/drive` là
/// *restricted scope*, cần đánh giá bảo mật bên thứ ba. `drive.file` thì không.
enum ConnectionCapability {
  /// Sao lưu `.ttbk` lên Drive.
  ///
  /// Scope `drive.file` — **chỉ file do chính app tạo**. Không đọc được gì
  /// khác trong Drive của người dùng, và đó là điểm: quyền hẹp nhất làm xong
  /// được việc.
  driveBackup(
    'drive_backup',
    connectorId: kGoogleConnectorId,
    scopes: ['https://www.googleapis.com/auth/drive.file'],
  ),

  /// Nhắn cho khách qua Telegram.
  telegramMessaging('telegram_messaging', connectorId: kTelegramConnectorId),

  /// Đọc issue để hiểu công việc đang thế nào.
  jiraWork('jira_work', connectorId: kAtlassianConnectorId),

  /// Đọc trang tài liệu làm bối cảnh cho AI.
  confluenceKnowledge(
    'confluence_knowledge',
    connectorId: kAtlassianConnectorId,
  );

  const ConnectionCapability(
    this.code, {
    required this.connectorId,
    this.scopes = const [],
  });

  final String code;

  /// Nền tảng nào cung cấp khả năng này.
  final String connectorId;

  /// Quyền OAuth cần xin **khi bật khả năng này** — rỗng với vendor dùng token.
  final List<String> scopes;

  static ConnectionCapability? fromCode(String? code) {
    for (final c in ConnectionCapability.values) {
      if (c.code == code) return c;
    }
    return null;
  }

  /// Các khả năng của một nền tảng.
  static List<ConnectionCapability> forConnector(String connectorId) => [
    for (final c in ConnectionCapability.values)
      if (c.connectorId == connectorId) c,
  ];

  /// Quyền cần xin cho **đúng** tập khả năng đang bật — không hơn.
  ///
  /// Trả về tập hợp đã gộp: hai khả năng cùng cần một scope thì chỉ xin một
  /// lần. Và quan trọng hơn: khả năng **chưa bật** không đóng góp scope nào.
  static List<String> scopesFor(Iterable<ConnectionCapability> enabled) {
    final out = <String>{};
    for (final c in enabled) {
      out.addAll(c.scopes);
    }
    return out.toList()..sort();
  }
}

/// Mã canonical của nền tảng. Dùng chung giữa `connections.connectorId`,
/// `provenance.connector` và `ActionVendor` — **một từ vựng, không ba**.
const String kGoogleConnectorId = 'google';
const String kTelegramConnectorId = 'telegram';
const String kAtlassianConnectorId = 'atlassian';

/// Một nền tảng nhìn từ phía người bán.
///
/// Bảng này là **dữ liệu**, không phải `switch` rải trong UI — cùng kỷ luật
/// Vendor Catalog (WTM-287): AI và giao diện **đọc** catalog, không hardcode.
@immutable
class ConnectorDescriptor {
  const ConnectorDescriptor({
    required this.id,
    required this.setupKind,
    required this.setupUrl,
  });

  final String id;

  /// Người bán phải làm gì để có credential.
  final ConnectorSetupKind setupKind;

  /// Chỗ lấy khoá — hiện trong hướng dẫn, không phải chỗ chứa khoá.
  final String setupUrl;

  List<ConnectionCapability> get capabilities =>
      ConnectionCapability.forConnector(id);

  static const Map<String, ConnectorDescriptor> catalog = {
    kGoogleConnectorId: ConnectorDescriptor(
      id: kGoogleConnectorId,
      setupKind: ConnectorSetupKind.oauth,
      setupUrl: 'https://console.cloud.google.com/',
    ),
    kTelegramConnectorId: ConnectorDescriptor(
      id: kTelegramConnectorId,
      setupKind: ConnectorSetupKind.token,
      setupUrl: 'https://t.me/BotFather',
    ),
    kAtlassianConnectorId: ConnectorDescriptor(
      id: kAtlassianConnectorId,
      setupKind: ConnectorSetupKind.tokenWithFields,
      setupUrl: 'https://id.atlassian.com/manage-profile/security/api-tokens',
    ),
  };

  static ConnectorDescriptor? byId(String id) => catalog[id];
}

/// Cách lấy credential — quyết định màn hình nào được hiện.
enum ConnectorSetupKind {
  /// Đăng nhập qua trình duyệt, PKCE, không có client secret.
  oauth,

  /// Dán một chuỗi (bot token, PAT).
  token,

  /// Dán một chuỗi **cộng** vài trường phi bí mật (domain, email).
  tokenWithFields,
}
