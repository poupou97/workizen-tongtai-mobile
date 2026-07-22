/// Failure categories for a BYOK AI call (WTM-61 AC: "error handling for
/// invalid keys, network errors, and API rate limits; user sees friendly error
/// messages"). Each kind carries a bilingual, non-technical message the UI can
/// show verbatim.
enum TongtaiAiErrorKind {
  /// No API key is stored yet — the user has to add one first.
  missingKey,

  /// The key was rejected by the provider (401/403, or xAI's 400 bad-key).
  invalidKey,

  /// The device could not reach the provider (offline, DNS, TLS…).
  network,

  /// The request was sent but the provider did not answer in time.
  timeout,

  /// Too many requests — the provider is rate-limiting this key.
  rateLimit,

  /// The key is valid but out of credit / quota.
  quota,

  /// The provider is up but erroring (5xx) — transient, retry later.
  serverError,

  /// A 200 arrived but the body was empty or unparseable.
  badResponse,

  /// Anything not covered above.
  unknown;
}

/// A friendly, user-facing AI failure. The message never echoes the raw
/// provider body (defense in depth against leaking a key back to the screen)
/// and is available in both English and Vietnamese.
class TongtaiAiException implements Exception {
  const TongtaiAiException(this.kind, this.messageEn, this.messageVi);

  final TongtaiAiErrorKind kind;
  final String messageEn;
  final String messageVi;

  /// Message for a language code ('vi' → Vietnamese, otherwise English).
  String message(String languageCode) =>
      languageCode == 'vi' ? messageVi : messageEn;

  static const TongtaiAiException missingKey = TongtaiAiException(
    TongtaiAiErrorKind.missingKey,
    'No API key set yet. Add your Grok (xAI) key to start using the AI assistant.',
    'Chưa có khóa API. Thêm khóa Grok (xAI) của bạn để bắt đầu dùng trợ lý AI.',
  );

  static const TongtaiAiException invalidKey = TongtaiAiException(
    TongtaiAiErrorKind.invalidKey,
    'The API key seems invalid. Please double-check the key you pasted.',
    'Khóa API có vẻ không hợp lệ. Vui lòng kiểm tra lại khóa bạn đã dán.',
  );

  static const TongtaiAiException network = TongtaiAiException(
    TongtaiAiErrorKind.network,
    'Could not reach the AI service. Check your internet connection and try again.',
    'Không thể kết nối dịch vụ AI. Kiểm tra kết nối mạng và thử lại.',
  );

  static const TongtaiAiException timeout = TongtaiAiException(
    TongtaiAiErrorKind.timeout,
    'The AI service took too long to respond. Please try again.',
    'Dịch vụ AI phản hồi quá lâu. Vui lòng thử lại.',
  );

  static const TongtaiAiException rateLimit = TongtaiAiException(
    TongtaiAiErrorKind.rateLimit,
    'Too many requests right now. Please wait a moment and try again.',
    'Có quá nhiều yêu cầu lúc này. Vui lòng đợi một lát rồi thử lại.',
  );

  static const TongtaiAiException quota = TongtaiAiException(
    TongtaiAiErrorKind.quota,
    'Your API credit or quota may be exhausted. Check your provider account.',
    'Hạn mức hoặc tín dụng API của bạn có thể đã hết. Kiểm tra tài khoản nhà cung cấp.',
  );

  static const TongtaiAiException serverError = TongtaiAiException(
    TongtaiAiErrorKind.serverError,
    'The AI service is temporarily unavailable. Please try again shortly.',
    'Dịch vụ AI tạm thời không khả dụng. Vui lòng thử lại sau ít phút.',
  );

  static const TongtaiAiException badResponse = TongtaiAiException(
    TongtaiAiErrorKind.badResponse,
    'The AI service returned an unexpected response. Please try again.',
    'Dịch vụ AI trả về phản hồi không mong đợi. Vui lòng thử lại.',
  );

  static const TongtaiAiException unknown = TongtaiAiException(
    TongtaiAiErrorKind.unknown,
    'Something went wrong talking to the AI service. Please try again.',
    'Đã xảy ra lỗi khi kết nối dịch vụ AI. Vui lòng thử lại.',
  );

  @override
  String toString() => 'TongtaiAiException(${kind.name}): $messageEn';
}
