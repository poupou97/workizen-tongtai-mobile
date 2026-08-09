import 'package:flutter/foundation.dart';

/// OAuth cho Google **trên máy** — WTM-317 (C1 · Epic WTM-315).
///
/// ## Vì sao có seam này thay vì gọi thẳng thư viện
///
/// Hai lý do, và lý do thứ hai mới là lý do thật:
///
/// 1. Test chạy được không cần trình duyệt.
/// 2. ⭐ **Chưa có OAuth client ID thì phần còn lại vẫn phải dựng xong.** Client
///    ID do Founder tạo trên Google Cloud Console (§30 — thứ tôi không tự làm
///    được). Nếu toàn bộ đường Drive chờ nó thì lúc có khoá mới bắt đầu viết,
///    và lúc đó không ai biết chỗ nào hỏng.
///
/// Nên: dựng hết, để kết nối ở `SETUP_REQUIRED`, và **không giả vờ đã kết
/// nối** (§8).
///
/// ## Không có client secret — có chủ ý
///
/// Google phát client loại **Android/iOS không kèm secret**, và AppAuth bật
/// PKCE sẵn (`AuthorizationRequest.java:648`, WTM-309). Đó là điều kiện để
/// luồng này chạy hoàn toàn trên máy.
///
/// Nếu một ngày phải nhét `clientSecret` vào đây thì theo luật của WTM-309 nó
/// **thôi là mobile-direct** — lúc đó đổi sang HYBRID, đừng nhét secret vào
/// app.
@immutable
class GoogleOAuthConfig {
  const GoogleOAuthConfig({required this.clientId, required this.redirectUrl});

  /// Client ID loại Android/iOS. **Không** phải web client.
  final String clientId;

  /// Custom URI scheme đảo ngược từ client ID, ví dụ
  /// `com.googleusercontent.apps.123-abc:/oauth2redirect`.
  final String redirectUrl;

  /// Chưa cấu hình ⇒ kết nối phải ở `SETUP_REQUIRED`.
  bool get isConfigured => clientId.trim().isNotEmpty;

  /// Cấu hình rỗng — trạng thái mặc định cho tới khi Founder tạo client.
  static const GoogleOAuthConfig none = GoogleOAuthConfig(
    clientId: '',
    redirectUrl: '',
  );

  static const String authorizationEndpoint =
      'https://accounts.google.com/o/oauth2/v2/auth';
  static const String tokenEndpoint = 'https://oauth2.googleapis.com/token';
}

/// Kết quả một lần cho phép.
@immutable
class GoogleTokens {
  const GoogleTokens({
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
  });

  final String accessToken;

  /// `null` = Google không trả refresh token lần này. **Không** phải lỗi: nó
  /// chỉ cấp refresh token ở lần cho phép đầu, nên chỗ gọi phải **giữ lại**
  /// refresh token cũ thay vì ghi đè bằng `null`.
  final String? refreshToken;

  final DateTime expiresAt;

  /// Còn dùng được không, có trừ hao.
  ///
  /// Trừ 60 giây vì một token hết hạn *giữa lúc* đang gọi API sẽ hỏng đúng
  /// kiểu khó hiểu nhất: request đầu thành công, request sau 401.
  bool isValidAt(DateTime now) =>
      accessToken.isNotEmpty &&
      expiresAt.subtract(const Duration(seconds: 60)).isAfter(now);
}

/// Vì sao một lần cho phép không thành.
enum GoogleAuthFailure {
  /// Chưa có client ID — Founder chưa tạo.
  notConfigured,

  /// Người bán bấm huỷ. **Không phải lỗi**, và giao diện không được báo đỏ.
  cancelled,

  /// Mạng hỏng.
  network,

  /// Google từ chối (scope sai, client sai, quyền bị thu hồi).
  rejected,
}

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.failure, [this.detail]);

  final GoogleAuthFailure failure;

  /// Chỉ hiện trên máy người dùng; telemetry chỉ nhận `failure` (ADR-TON-017).
  final String? detail;

  @override
  String toString() => 'GoogleAuthException(${failure.name})';
}

/// Cửa duy nhất để lấy token Google.
abstract interface class GoogleAuthenticator {
  /// Mở trình duyệt, xin **đúng** [scopes] đang cần — không hơn.
  ///
  /// Incremental Permission (§D-2): bật thêm capability thì gọi lại hàm này
  /// với tập scope rộng hơn, **không** xin sẵn từ đầu.
  Future<GoogleTokens> authorize(List<String> scopes);

  /// Đổi refresh token lấy access token mới.
  Future<GoogleTokens> refresh(String refreshToken, List<String> scopes);

  /// Thu hồi quyền phía Google — khác với xoá credential trên máy.
  Future<void> revoke(String token);
}

/// Bản dùng khi **chưa** có client ID.
///
/// Nó không im lặng trả về rỗng — nó **ném** `notConfigured`. Một
/// authenticator im lặng sẽ khiến giao diện hiện "chưa kết nối" mà không ai
/// biết vì sao, và Founder sẽ đi tìm lỗi ở chỗ khác.
class UnconfiguredGoogleAuthenticator implements GoogleAuthenticator {
  const UnconfiguredGoogleAuthenticator();

  @override
  Future<GoogleTokens> authorize(List<String> scopes) async =>
      throw const GoogleAuthException(
        GoogleAuthFailure.notConfigured,
        'Chưa có OAuth client ID cho Google. Xem docs/08-PLATFORM/'
        '22-GOOGLE-DRIVE-CONNECTOR.md để tạo.',
      );

  @override
  Future<GoogleTokens> refresh(String refreshToken, List<String> scopes) =>
      authorize(scopes);

  @override
  Future<void> revoke(String token) async {}
}
