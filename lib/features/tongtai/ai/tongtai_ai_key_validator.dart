import 'package:flutter/foundation.dart';

import 'tongtai_ai_provider_kind.dart';

/// Why an API key was rejected (WTM-61 AC: "validated — non-empty, correct
/// format — before storing"). [none] means the key is well-formed.
enum TongtaiAiKeyIssue {
  none,
  empty,
  containsWhitespace,
  tooShort,
  wrongPrefix;

  /// Friendly, actionable English message for this issue ([none] → empty string).
  String get messageEn => switch (this) {
        TongtaiAiKeyIssue.none => '',
        TongtaiAiKeyIssue.empty => 'Please paste your API key.',
        TongtaiAiKeyIssue.containsWhitespace =>
          'The key should not contain spaces or line breaks.',
        TongtaiAiKeyIssue.tooShort =>
          'That key looks too short to be valid. Please check and paste the full key.',
        TongtaiAiKeyIssue.wrongPrefix =>
          'This does not look like a valid key for the selected provider.',
      };

  /// Friendly Vietnamese message ([none] → empty string).
  String get messageVi => switch (this) {
        TongtaiAiKeyIssue.none => '',
        TongtaiAiKeyIssue.empty => 'Vui lòng dán khóa API của bạn.',
        TongtaiAiKeyIssue.containsWhitespace =>
          'Khóa không được chứa khoảng trắng hoặc xuống dòng.',
        TongtaiAiKeyIssue.tooShort =>
          'Khóa này có vẻ quá ngắn. Vui lòng kiểm tra và dán đầy đủ khóa.',
        TongtaiAiKeyIssue.wrongPrefix =>
          'Đây không giống khóa hợp lệ cho nhà cung cấp đã chọn.',
      };

  /// Message for a language code ('vi' → Vietnamese, otherwise English).
  String message(String languageCode) =>
      languageCode == 'vi' ? messageVi : messageEn;
}

/// Result of validating a pasted API key. [ok] keys carry the trimmed value
/// ready to store; rejected keys carry the reason in [issue].
@immutable
class TongtaiAiKeyValidation {
  const TongtaiAiKeyValidation._(this.issue, this.normalizedKey);

  /// The validation verdict; [TongtaiAiKeyIssue.none] means valid.
  final TongtaiAiKeyIssue issue;

  /// The whitespace-trimmed key, present only when [ok]. Store THIS value, not
  /// the raw input, so a stray leading/trailing space never breaks auth.
  final String? normalizedKey;

  bool get ok => issue == TongtaiAiKeyIssue.none;

  @override
  bool operator ==(Object other) =>
      other is TongtaiAiKeyValidation &&
      other.issue == issue &&
      other.normalizedKey == normalizedKey;

  @override
  int get hashCode => Object.hash(issue, normalizedKey);
}

/// Pure, side-effect-free validation of a BYOK API key before it is stored
/// (WTM-61). Format-only: it cannot know whether the key actually authenticates
/// — that is what the live connectivity test (`testConnection`) is for.
abstract final class TongtaiAiKeyValidator {
  /// Shortest plausible key length. Real provider keys are far longer (xAI keys
  /// are ~80 chars after the prefix); this only rejects obvious fragments while
  /// never rejecting a genuine key.
  static const int minKeyLength = 20;

  /// Validate [raw] for [provider]. Trims surrounding whitespace first, then
  /// checks: non-empty, no internal whitespace, long enough, and — when the
  /// provider defines one — the expected key prefix.
  static TongtaiAiKeyValidation validate(
    String raw, {
    TongtaiAiProviderKind provider = TongtaiAiProviderKind.xai,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const TongtaiAiKeyValidation._(TongtaiAiKeyIssue.empty, null);
    }
    // Any internal whitespace means a copy-paste picked up a newline or the
    // user typed two tokens — reject rather than silently send a broken key.
    if (RegExp(r'\s').hasMatch(trimmed)) {
      return const TongtaiAiKeyValidation._(
          TongtaiAiKeyIssue.containsWhitespace, null);
    }
    if (trimmed.length < minKeyLength) {
      return const TongtaiAiKeyValidation._(TongtaiAiKeyIssue.tooShort, null);
    }
    final prefix = provider.keyPrefix;
    if (prefix.isNotEmpty && !trimmed.startsWith(prefix)) {
      return const TongtaiAiKeyValidation._(TongtaiAiKeyIssue.wrongPrefix, null);
    }
    return TongtaiAiKeyValidation._(TongtaiAiKeyIssue.none, trimmed);
  }
}
