import '../../core/connection.dart';
import '../connection_capability.dart';
import '../connection_credential_store.dart';
import '../connection_service.dart';
import 'google_oauth.dart';

/// Vòng đời **token** Google — WTM-317.
///
/// `ConnectionService` lo phần chung (bản ghi, trạng thái, xoá hai nửa). Lớp
/// này lo đúng phần Google khác mọi người: access token hết hạn sau một giờ,
/// nên giữa hai lần sao lưu gần như chắc chắn phải làm mới.
///
/// ## Refresh token là thứ dễ mất nhất trong cả luồng
///
/// Google chỉ cấp refresh token ở **lần cho phép đầu tiên**. Lần refresh sau đó
/// trả về access token mới và `refresh_token: null` — không phải lỗi.
///
/// Viết thẳng `tokens.refreshToken` vào store lúc đó sẽ **xoá mất** refresh
/// token duy nhất ta có, và người bán phải đăng nhập lại sau mỗi giờ mà không
/// hiểu vì sao. Nên [_store] hợp nhất chứ không ghi đè.
class GoogleConnection {
  GoogleConnection({
    required this._connections,
    required GoogleAuthenticator authenticator,
    this._now = DateTime.now,
  }) : _auth = authenticator;

  final ConnectionService _connections;
  final GoogleAuthenticator _auth;
  final DateTime Function() _now;

  /// Bản ghi kết nối Google, tạo ở `SETUP_REQUIRED` nếu chưa có.
  Future<Connection> ensure({String label = 'Google'}) =>
      _connections.ensure(kGoogleConnectorId, label: label);

  /// Bật một khả năng: xin **đúng** scope của nó, rồi lưu token.
  ///
  /// Incremental Permission (§D-2). Bật *Sao lưu Drive* xin `drive.file`; ngày
  /// nào bật *Đọc thư khách* thì gọi lại hàm này với `{driveBackup, gmail…}` và
  /// Google sẽ hỏi thêm — **không** xin sẵn từ đầu.
  Future<Connection> connect(Set<ConnectionCapability> capabilities) async {
    final connection = await ensure();
    final scopes = ConnectionCapability.scopesFor(capabilities);
    if (scopes.isEmpty) {
      throw ArgumentError.value(
        capabilities,
        'capabilities',
        'không khả năng nào cần scope — sẽ mở trình duyệt xin quyền rỗng',
      );
    }
    final tokens = await _auth.authorize(scopes);
    return _store(connection, tokens);
  }

  /// Kết nối và **phân loại kết quả**, không ném.
  ///
  /// `ui/` không được catch thủ công (ADR-TON-017), nên chỗ phân loại phải nằm
  /// ở đây. Hai kết quả dễ bị đọc nhầm thành lỗi mà không phải:
  ///
  /// - `notConfigured` — app chưa có khoá. Lỗi của bản cài, không của người bán.
  /// - `cancelled` — họ đổi ý. Không phải lỗi của ai cả.
  Future<GoogleConnectOutcome> connectQuietly(
    Set<ConnectionCapability> capabilities,
  ) async {
    try {
      await connect(capabilities);
      return GoogleConnectOutcome.connected;
    } on GoogleAuthException catch (e) {
      return switch (e.failure) {
        GoogleAuthFailure.notConfigured => GoogleConnectOutcome.notConfigured,
        GoogleAuthFailure.cancelled => GoogleConnectOutcome.cancelled,
        GoogleAuthFailure.network => GoogleConnectOutcome.network,
        GoogleAuthFailure.rejected => GoogleConnectOutcome.rejected,
      };
    }
  }

  /// Access token dùng được **ngay bây giờ**, tự làm mới khi cần.
  ///
  /// Trả `null` khi chưa kết nối — chỗ gọi phải mời người bán kết nối, không
  /// phải báo lỗi.
  ///
  /// [force] dùng cho đúng một trường hợp: Drive trả 401 dù token trông còn
  /// hạn (quyền bị thu hồi phía Google). Thử lại **một** lần với token mới; vẫn
  /// 401 thì đó là mất quyền thật, không phải hết hạn.
  Future<String?> accessToken({bool force = false}) async {
    final connection = await _connections.ensure(
      kGoogleConnectorId,
      label: 'Google',
    );
    final stored = await _connections.credentials.read(connection);
    if (stored == null) return null;

    final access = stored[CredentialField.token];
    final expiresAt = DateTime.tryParse(
      stored[CredentialField.expiresAt] ?? '',
    );
    final refreshToken = stored[CredentialField.refreshToken];

    if (!force && access != null && expiresAt != null) {
      final current = GoogleTokens(accessToken: access, expiresAt: expiresAt);
      if (current.isValidAt(_now())) return access;
    }

    // Hết hạn mà không có refresh token ⇒ kết nối **hỏng thật**: không có
    // đường nào lấy lại token mà không mở trình duyệt.
    if (refreshToken == null || refreshToken.isEmpty) {
      await _connections.markError(connection);
      return null;
    }

    try {
      final fresh = await _auth.refresh(refreshToken, const []);
      await _store(connection, fresh);
      return fresh.accessToken;
    } on GoogleAuthException {
      await _connections.markError(connection);
      return null;
    }
  }

  /// Ngắt kết nối: thu hồi phía Google **trước**, rồi xoá tại chỗ.
  ///
  /// Thu hồi hỏng (mất mạng) **không** chặn việc xoá. Người bán bấm "ngắt" là
  /// muốn khoá biến khỏi máy họ; giữ nó lại vì Google không trả lời là đặt sai
  /// thứ tự ưu tiên. Token còn hiệu lực phía Google sẽ hết hạn sau một giờ.
  Future<void> disconnect() async {
    final connection = await _connections.ensure(
      kGoogleConnectorId,
      label: 'Google',
    );
    final stored = await _connections.credentials.read(connection);
    final refresh = stored?[CredentialField.refreshToken];
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _auth.revoke(refresh);
      } on GoogleAuthException {
        // Xem doc ở trên — xoá tại chỗ vẫn phải xảy ra.
      }
    }
    await _connections.disconnect(connection);
  }

  /// Ghi token, **giữ lại** refresh token cũ khi lần này Google không trả về.
  Future<Connection> _store(Connection connection, GoogleTokens tokens) async {
    final previous =
        await _connections.credentials.read(connection) ?? const {};
    final refresh =
        tokens.refreshToken ?? previous[CredentialField.refreshToken];
    return _connections.attachCredentials(connection, {
      CredentialField.token: tokens.accessToken,
      CredentialField.expiresAt: tokens.expiresAt.toIso8601String(),
      if (refresh != null && refresh.isNotEmpty)
        CredentialField.refreshToken: refresh,
    });
  }
}

/// Kết quả một lần bấm "Kết nối" — đủ để giao diện chọn câu nói, không cần
/// biết gì về ngoại lệ.
enum GoogleConnectOutcome {
  connected,

  /// Bản cài chưa có OAuth client ID (§30 — Founder tạo).
  notConfigured,

  /// Người bán đóng trình duyệt. **Không** báo đỏ.
  cancelled,

  network,
  rejected,
}
