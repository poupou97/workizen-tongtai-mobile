import 'package:flutter/foundation.dart';

import 'external_identity.dart';

/// Dấu hiệu khiến một khách trở thành ứng viên.
///
/// Enum, không phải chuỗi mô tả: chuỗi mô tả sẽ là tiếng Việt nằm trong tầng
/// domain (trái ADR-TON-007 — mọi chuỗi hiển thị đi qua `AppStrings`), và
/// không so sánh được. Tầng UI dịch mã này ra câu người bán đọc.
enum IdentityMatchSignal {
  phone('phone'),
  email('email');

  const IdentityMatchSignal(this.code);

  final String code;

  static IdentityMatchSignal? fromCode(String? code) {
    for (final s in IdentityMatchSignal.values) {
      if (s.code == code) return s;
    }
    return null;
  }
}

/// Một khách **có thể** là người này, kèm lý do và mức tin cậy.
///
/// Gói lại thành một kiểu thay vì rải thành nhiều tham số `…CustomerId` là có
/// chủ ý: nhờ đó `IdentityResolver.resolve` **không có tham số customerId
/// nào**, và luật 4 của ADR-TON-024 kiểm được bằng máy mà không cần ngoại lệ
/// (`identity_no_auto_merge_governance_test`).
@immutable
class IdentityCandidate {
  const IdentityCandidate({
    required this.customerId,
    required this.signal,
    required this.confidence,
  });

  final String customerId;
  final IdentityMatchSignal signal;
  final IdentityConfidence confidence;
}

/// Kết quả của việc đối chiếu một danh tính ngoài với danh bạ khách.
///
/// **Đây là một QUYẾT ĐỊNH, không phải một hành động.** Resolver không ghi gì
/// cả — nó trả lời *"nên làm gì"*, và chỗ gọi mới thực hiện. Tách ra vì hai
/// việc có mức rủi ro khác nhau: tính toán thì chạy lại được, còn ghi vào danh
/// bạ khách thì phải hoàn tác được.
@immutable
sealed class IdentityDecision {
  const IdentityDecision();
}

/// Đủ chắc để gắn ngay, không hỏi. **Chỉ xảy ra với `exact`.**
@immutable
class AutoLink extends IdentityDecision {
  const AutoLink({required this.customerId, required this.confidence})
    : assert(
        confidence == IdentityConfidence.exact,
        'chỉ exact mới được tự động liên kết — xem ADR-TON-024',
      );

  final String customerId;
  final IdentityConfidence confidence;
}

/// Có khả năng, nhưng **người bán phải bấm**.
@immutable
class SuggestLink extends IdentityDecision {
  /// Không `const`: assert phải đọc `candidate.confidence`, và một hằng số
  /// biên dịch không đọc được trường của đối tượng khác. Giữ assert quan trọng
  /// hơn giữ `const` — luật 3 phải chặn được ngay tại nơi dựng.
  SuggestLink({required this.candidate})
    : assert(
        candidate.confidence != IdentityConfidence.weak &&
            candidate.confidence != IdentityConfidence.none,
        'weak/none không được đề xuất — xem ADR-TON-024 luật 3',
      );

  final IdentityCandidate candidate;

  String get customerId => candidate.customerId;

  IdentityConfidence get confidence => candidate.confidence;

  /// Vì sao nghi là cùng một người. Tầng UI dịch ra câu người bán đọc.
  IdentityMatchSignal get signal => candidate.signal;
}

/// Không đủ cơ sở. **Không đề xuất gì**, kể cả dưới dạng gợi ý mờ.
@immutable
class NoMatch extends IdentityDecision {
  const NoMatch();
}

/// Đối chiếu một danh tính ngoài với danh bạ khách của người bán.
///
/// ## ⭐ Vì sao ở đây KHÔNG có hàm gộp khách
///
/// ADR-TON-024: *"gộp bản ghi khách: không bao giờ tự động, ở mọi mức tin
/// cậy"*. Một nội quy viết trong tài liệu sẽ bị vi phạm ngày ai đó thấy tiện.
///
/// Nên luật này được cài bằng **hình dạng của API**: không hàm nào trong seam
/// này nhận **hai** `customerId` và trả về **một**. Cái không tồn tại thì không
/// gọi nhầm được, và `identity_no_auto_merge_governance_test` canh đúng tính
/// chất đó trên mã nguồn.
///
/// Gộp hai bản ghi khách trùng là bài toán **khác** — nó không sinh ra từ
/// connector mà từ việc chính người bán lỡ tạo hai bản ghi, và nó cần luồng UI
/// riêng có xem trước và hoàn tác.
///
/// ## Liên kết ≠ gộp
///
/// | | Liên kết | Gộp |
/// |---|---|---|
/// | Việc gì | thêm danh tính ngoài trỏ vào khách đã có | nhập hai bản ghi khách |
/// | Gỡ ra | được, xoá một dòng | rất khó — đơn hàng đã đổi chủ |
/// | Sai thì sao | sửa 5 giây | hai người thật bị nhập một |
class IdentityResolver {
  const IdentityResolver();

  /// Quyết định nên làm gì với một danh tính vừa thấy.
  ///
  /// [existing] là các danh tính đã gắn; [candidates] là những khách **có thể**
  /// là người này, do chỗ gọi tra ra (theo số điện thoại, email…).
  ///
  /// Hàm này **không nhận `customerId` nào** — mọi ứng viên đi qua
  /// [IdentityCandidate]. Xem doc của lớp.
  IdentityDecision resolve({
    required String platform,
    required String externalId,
    required String connectionId,
    required List<ExternalIdentity> existing,
    List<IdentityCandidate> candidates = const [],
  }) {
    // 1. Đã gắn rồi ⇒ giữ nguyên, không quyết định lại.
    //
    // So khớp cả `connectionId`: cùng `externalId` ở hai tài khoản Shopee khác
    // nhau là hai người khác nhau — nền tảng chỉ bảo đảm duy nhất trong phạm
    // vi một shop.
    for (final e in existing) {
      if (e.platform == platform &&
          e.externalId == externalId &&
          e.connectionId == connectionId) {
        return AutoLink(
          customerId: e.customerId,
          confidence: IdentityConfidence.exact,
        );
      }
    }

    // 2. Ứng viên đủ mạnh ⇒ CHỈ đề xuất, không tự gắn.
    //
    // Kể cả khi nghe rất chắc: hai người thật **có thể** dùng chung một số
    // điện thoại — vợ chồng, mẹ con, số cửa hàng. Ở Việt Nam đó là chuyện phổ
    // biến, không phải trường hợp biên.
    //
    // ⚠️ `exact` từ một ứng viên KHÔNG được tự gắn ở đây. Tự động chỉ dành cho
    // khoá do chính nền tảng cấp (nhánh 1); một luật khớp tự nhận là `exact`
    // vẫn phải qua mắt người bán.
    for (final c in candidates) {
      if (c.confidence.canSuggest) {
        return SuggestLink(
          candidate: c.confidence == IdentityConfidence.exact
              // Hạ về `strong`: đề xuất thì mức cao nhất là `strong`, để
              // không có đường nào biến một đề xuất thành `AutoLink` về sau.
              ? IdentityCandidate(
                  customerId: c.customerId,
                  signal: c.signal,
                  confidence: IdentityConfidence.strong,
                )
              : c,
        );
      }
    }

    // 3. Không có gì chắc ⇒ không đoán.
    return const NoMatch();
  }
}
