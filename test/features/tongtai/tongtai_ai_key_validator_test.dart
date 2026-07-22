import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_key_validator.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_provider_kind.dart';

/// Unit tests for the key format validator (WTM-61 AC: "validated — non-empty,
/// correct format — before storing"). Covers each rejection reason, the happy
/// path (with trimming), and the bilingual messages.
void main() {
  // A realistic-length xAI key (prefix + 80 chars) that must always pass.
  final validXaiKey = 'xai-${'a1B2c3D4' * 10}';

  group('TongtaiAiKeyValidator.validate (xai)', () {
    test('accepts a well-formed key and returns the trimmed value', () {
      final r = TongtaiAiKeyValidator.validate(validXaiKey);
      expect(r.ok, isTrue);
      expect(r.issue, TongtaiAiKeyIssue.none);
      expect(r.normalizedKey, validXaiKey);
    });

    test('trims surrounding whitespace before storing', () {
      final r = TongtaiAiKeyValidator.validate('  $validXaiKey \n');
      expect(r.ok, isTrue);
      expect(r.normalizedKey, validXaiKey);
    });

    test('rejects an empty / whitespace-only key', () {
      expect(
        TongtaiAiKeyValidator.validate('').issue,
        TongtaiAiKeyIssue.empty,
      );
      expect(
        TongtaiAiKeyValidator.validate('    ').issue,
        TongtaiAiKeyIssue.empty,
      );
    });

    test('rejects internal whitespace (e.g. a pasted two-token blob)', () {
      final r = TongtaiAiKeyValidator.validate('xai-abc def${'x' * 20}');
      expect(r.issue, TongtaiAiKeyIssue.containsWhitespace);
      expect(r.ok, isFalse);
      expect(r.normalizedKey, isNull);
    });

    test('rejects a too-short key', () {
      final r = TongtaiAiKeyValidator.validate('xai-short');
      expect(r.issue, TongtaiAiKeyIssue.tooShort);
    });

    test('rejects the wrong prefix for the provider', () {
      final r = TongtaiAiKeyValidator.validate('sk-${'a' * 40}');
      expect(r.issue, TongtaiAiKeyIssue.wrongPrefix);
    });
  });

  group('per-provider prefix', () {
    test('an openAI key is valid for openAI but not for xai', () {
      final openAiKey = 'sk-${'a' * 40}';
      expect(
        TongtaiAiKeyValidator.validate(
          openAiKey,
          provider: TongtaiAiProviderKind.openAI,
        ).ok,
        isTrue,
      );
      expect(
        TongtaiAiKeyValidator.validate(
          openAiKey,
          provider: TongtaiAiProviderKind.xai,
        ).issue,
        TongtaiAiKeyIssue.wrongPrefix,
      );
    });
  });

  group('messages', () {
    test('valid issue has empty messages', () {
      expect(TongtaiAiKeyIssue.none.messageEn, isEmpty);
      expect(TongtaiAiKeyIssue.none.messageVi, isEmpty);
    });

    test('each rejection carries a non-empty bilingual message', () {
      for (final issue in TongtaiAiKeyIssue.values) {
        if (issue == TongtaiAiKeyIssue.none) continue;
        expect(issue.messageEn, isNotEmpty);
        expect(issue.messageVi, isNotEmpty);
        expect(issue.message('vi'), issue.messageVi);
        expect(issue.message('en'), issue.messageEn);
        expect(issue.message('fr'), issue.messageEn); // fallback to English
      }
    });
  });

  test('value-equality of TongtaiAiKeyValidation', () {
    final a = TongtaiAiKeyValidator.validate(validXaiKey);
    final b = TongtaiAiKeyValidator.validate(validXaiKey);
    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);
  });
}
