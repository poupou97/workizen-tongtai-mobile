import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/external_identity.dart';
import 'package:tongtai/features/tongtai/consumer/identity_evidence.dart';

/// WTM-298 · D-1 — Derived Confidence.
///
/// Chỗ gọi khai **cái nó thấy**; mức tin cậy do một hàm thuần tính ra. Suite
/// này khoá đúng những cách một chỗ gọi có thể **khai confidence bằng cửa
/// sau** — tách một quan sát thành nhiều dòng, hoặc gộp nhiều cách nhìn cùng
/// một thuộc tính.
void main() {
  IdentityEvidence ev(IdentityEvidenceKind kind, {String source = 'src-1'}) =>
      IdentityEvidence(kind: kind, source: source);

  // ────────────────────────────────────────────────────────────────────────
  group('Hàm thuần và tất định', () {
    test('cùng đầu vào ⇒ cùng đầu ra, mọi lần gọi', () {
      final input = [
        ev(IdentityEvidenceKind.phoneExactMatch),
        ev(IdentityEvidenceKind.nameExactMatch, source: 'src-2'),
      ];
      final a = scoreIdentity(input);
      final b = scoreIdentity(input);
      expect(a.score, b.score);
      expect(a.confidence, b.confidence);
    });

    test('thứ tự bằng chứng KHÔNG đổi kết quả', () {
      final forward = scoreIdentity([
        ev(IdentityEvidenceKind.phoneExactMatch, source: 'a'),
        ev(IdentityEvidenceKind.emailExactMatch, source: 'b'),
      ]);
      final backward = scoreIdentity([
        ev(IdentityEvidenceKind.emailExactMatch, source: 'b'),
        ev(IdentityEvidenceKind.phoneExactMatch, source: 'a'),
      ]);
      expect(forward.score, backward.score);
    });

    test('không bằng chứng ⇒ none, không phải mặc định nào khác', () {
      final scored = scoreIdentity([]);
      expect(scored.confidence, IdentityConfidence.none);
      expect(scored.score, 0);
      expect(scored.countedSources, 0);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('⭐ Chống cộng dồn giả — cùng NGUỒN là MỘT quan sát', () {
    test('một thẻ liên hệ cho 3 trường ⇒ đếm MỘT lần', () {
      // Đây là cửa sau rõ nhất: nhập một thẻ liên hệ rồi tách thành ba dòng
      // bằng chứng. Không chặn thì chỗ gọi đẩy điểm lên bao nhiêu tuỳ ý.
      const card = 'contact_import:2026-08-08';
      final split = scoreIdentity([
        ev(IdentityEvidenceKind.phoneExactMatch, source: card),
        ev(IdentityEvidenceKind.emailExactMatch, source: card),
        ev(IdentityEvidenceKind.nameExactMatch, source: card),
      ]);
      final single = scoreIdentity([
        ev(IdentityEvidenceKind.emailExactMatch, source: card),
      ]);

      expect(split.countedSources, 1, reason: 'ba dòng, một quan sát');
      expect(split.score, single.score);
    });

    test('cùng nguồn ⇒ giữ bằng chứng MẠNH NHẤT, không phải cái đầu tiên', () {
      const card = 'card';
      final weakFirst = scoreIdentity([
        ev(IdentityEvidenceKind.nameSimilar, source: card),
        ev(IdentityEvidenceKind.emailExactMatch, source: card),
      ]);
      expect(
        weakFirst.score,
        scoreIdentity([
          ev(IdentityEvidenceKind.emailExactMatch, source: card),
        ]).score,
      );
    });

    test('nguồn KHÁC nhau vẫn cộng dồn bình thường', () {
      final two = scoreIdentity([
        ev(IdentityEvidenceKind.phoneExactMatch, source: 'shopee:order:1'),
        ev(IdentityEvidenceKind.emailExactMatch, source: 'seller_typed'),
      ]);
      expect(two.countedSources, 2);
      expect(two.score, greaterThan(0.8));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('⭐ Chống cộng dồn giả — cùng NHÓM là MỘT tín hiệu', () {
    test('"tên khớp" + "tên gần giống" từ hai nguồn ⇒ vẫn một tín hiệu', () {
      // Hai cách nhìn CÙNG một thuộc tính không phải hai bằng chứng độc lập,
      // kể cả khi chúng đến từ hai nguồn khác nhau.
      final both = scoreIdentity([
        ev(IdentityEvidenceKind.nameExactMatch, source: 'a'),
        ev(IdentityEvidenceKind.nameSimilar, source: 'b'),
      ]);
      final one = scoreIdentity([
        ev(IdentityEvidenceKind.nameExactMatch, source: 'a'),
      ]);
      expect(both.countedSources, 1, reason: 'cùng nhóm `name`');
      expect(both.score, one.score);
    });

    test('nhóm khác nhau thì độc lập thật', () {
      final scored = scoreIdentity([
        ev(IdentityEvidenceKind.phoneExactMatch, source: 'a'),
        ev(IdentityEvidenceKind.nameExactMatch, source: 'b'),
        ev(IdentityEvidenceKind.addressSimilar, source: 'c'),
      ]);
      expect(scored.countedSources, 3);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Thiếu dữ liệu KHÔNG phải bằng chứng ngược', () {
    test('từ vựng không có cách nào diễn đạt "thiếu"', () {
      // Cấu trúc, không phải nội quy: không enum nào mang nghĩa phủ định
      // ngoài `contradiction`, và `contradiction` đòi một quan sát mâu thuẫn
      // THẬT, không phải một ô trống.
      final negativeSounding = IdentityEvidenceKind.values.where(
        (k) =>
            k.code.contains('missing') ||
            k.code.contains('no_') ||
            k.code.contains('absent') ||
            k.code.contains('unknown'),
      );
      expect(negativeSounding, isEmpty);
    });

    test('ít bằng chứng chỉ làm điểm THẤP, không làm điểm ÂM', () {
      final scored = scoreIdentity([ev(IdentityEvidenceKind.addressSimilar)]);
      expect(scored.score, greaterThan(0));
      expect(scored.confidence, IdentityConfidence.none);
    });

    test('một khách không email KHÔNG bị phạt so với khách có email', () {
      // Ở bán lẻ Việt Nam, không có email là chuyện bình thường.
      final noEmail = scoreIdentity([
        ev(IdentityEvidenceKind.phoneExactMatch, source: 'a'),
      ]);
      expect(noEmail.confidence, IdentityConfidence.strong);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Mâu thuẫn được biểu diễn rõ', () {
    test('mâu thuẫn KẸP điểm, không trừ dần', () {
      final clean = scoreIdentity([
        ev(IdentityEvidenceKind.phoneExactMatch, source: 'a'),
        ev(IdentityEvidenceKind.emailExactMatch, source: 'b'),
      ]);
      final clashed = scoreIdentity([
        ev(IdentityEvidenceKind.phoneExactMatch, source: 'a'),
        ev(IdentityEvidenceKind.emailExactMatch, source: 'b'),
        ev(IdentityEvidenceKind.contradiction, source: 'c'),
      ]);
      expect(clean.confidence, IdentityConfidence.strong);
      expect(clashed.score, kContradictionCeiling);
      expect(
        clashed.confidence,
        IdentityConfidence.weak,
        reason: 'mâu thuẫn ⇒ KHÔNG đề xuất, nhưng vẫn giữ lại',
      );
      expect(clashed.contradicted, isTrue);
    });

    test('mâu thuẫn chặn được cả khoá nền tảng', () {
      // Nếu nền tảng nói một đằng và dữ liệu nói một nẻo, `exact` là lời khai
      // sai — không phải "vẫn exact nhưng hơi lo".
      final scored = scoreIdentity([
        ev(IdentityEvidenceKind.platformAccountId, source: 'a'),
        ev(IdentityEvidenceKind.contradiction, source: 'b'),
      ]);
      expect(scored.confidence, isNot(IdentityConfidence.exact));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('⭐ `exact` KHÔNG đạt được bằng cộng dồn', () {
    test('khoá nền tảng ⇒ exact', () {
      expect(
        scoreIdentity([ev(IdentityEvidenceKind.platformAccountId)]).confidence,
        IdentityConfidence.exact,
      );
    });

    test('gộp MỌI bằng chứng khác vẫn KHÔNG tới exact', () {
      // Đây là luật quan trọng nhất: `exact` nghĩa là "nền tảng bảo đảm đây là
      // một người duy nhất", không phải "tôi rất chắc".
      final everything = scoreIdentity([
        ev(IdentityEvidenceKind.orderHistoryMatch, source: 'a'),
        ev(IdentityEvidenceKind.emailExactMatch, source: 'b'),
        ev(IdentityEvidenceKind.phoneExactMatch, source: 'c'),
        ev(IdentityEvidenceKind.nameExactMatch, source: 'd'),
        ev(IdentityEvidenceKind.addressSimilar, source: 'e'),
      ]);
      expect(everything.score, greaterThan(0.95));
      expect(everything.confidence, IdentityConfidence.strong);
      expect(everything.confidence, isNot(IdentityConfidence.exact));
    });

    test('điểm không bao giờ đạt 1.0', () {
      final maxed = scoreIdentity([
        for (var i = 0; i < 6; i++)
          ev(IdentityEvidenceKind.platformAccountId, source: 's$i'),
      ]);
      expect(maxed.score, lessThanOrEqualTo(kIdentityScoreCeiling));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Trọng số phản ánh thực tế bán lẻ Việt Nam', () {
    test('số điện thoại KHÔNG đủ mạnh bằng khoá nền tảng', () {
      // Hai người thật dùng chung một số là chuyện phổ biến — vợ chồng, mẹ
      // con, số cửa hàng.
      expect(
        IdentityEvidenceKind.phoneExactMatch.weight,
        lessThan(IdentityEvidenceKind.platformAccountId.weight),
      );
      expect(IdentityEvidenceKind.phoneExactMatch.primary, isFalse);
    });

    test('email nặng HƠN số điện thoại — ngược trực giác, và có lý do', () {
      // Email ít dùng hơn trong bán lẻ VN, nhưng khi có thì riêng tư hơn.
      expect(
        IdentityEvidenceKind.emailExactMatch.weight,
        greaterThan(IdentityEvidenceKind.phoneExactMatch.weight),
      );
    });

    test('tên rất yếu — trùng tên ở VN là chuyện thường', () {
      expect(IdentityEvidenceKind.nameExactMatch.weight, lessThan(0.25));
    });

    test('tên + địa chỉ gộp lại vẫn KHÔNG đủ để đề xuất', () {
      // Nhiều khách chung một địa chỉ (chung cư, toà nhà). Nếu hai tín hiệu
      // yếu này đề xuất được thì người bán sẽ thấy đề xuất rác.
      final weakOnly = scoreIdentity([
        ev(IdentityEvidenceKind.nameExactMatch, source: 'a'),
        ev(IdentityEvidenceKind.addressSimilar, source: 'b'),
      ]);
      expect(weakOnly.confidence.canSuggest, isFalse);
    });

    test('chỉ khoá nền tảng và lịch sử mua là primary', () {
      final primaries = IdentityEvidenceKind.values
          .where((k) => k.primary)
          .toSet();
      expect(primaries, {
        IdentityEvidenceKind.platformAccountId,
        IdentityEvidenceKind.orderHistoryMatch,
      });
    });

    test('mã lạ ⇒ null, không rơi về loại nào', () {
      expect(IdentityEvidenceKind.fromCode('probably_them'), isNull);
      expect(IdentityEvidenceKind.fromCode(null), isNull);
    });
  });
}
