import 'package:flutter/foundation.dart';

import 'external_identity.dart';

/// Nhóm tín hiệu mà một bằng chứng thuộc về (WTM-298 · D-1).
///
/// ## Vì sao cần nhóm, không chỉ cần loại
///
/// Hai khẳng định về **cùng một thuộc tính** không phải hai bằng chứng độc
/// lập. "Tên khớp chính xác" và "tên gần giống" là **một** tín hiệu nhìn hai
/// lần; cộng dồn chúng là tự tạo ra sự chắc chắn không có thật.
///
/// Nên trước khi cộng dồn, mỗi nhóm chỉ giữ **bằng chứng mạnh nhất**.
enum EvidenceFamily {
  /// Khoá do chính nền tảng cấp.
  identityKey('identity_key'),

  /// Hành vi mua đã ghi nhận.
  behaviour('behaviour'),

  email('email'),
  phone('phone'),
  name('name'),
  address('address');

  const EvidenceFamily(this.code);

  final String code;
}

/// Loại bằng chứng danh tính — **từ vựng đóng**.
///
/// ## ⭐ Trọng số rút từ lỗi thật của bán lẻ Việt Nam, KHÔNG chép ở đâu
///
/// Bảng trọng số của một CRM phương Tây (LinkedIn, chữ ký email) **không**
/// dùng được ở đây. Bốn thực tế quyết định các con số dưới:
///
/// 1. **Hai người thật dùng chung một số điện thoại là chuyện phổ biến** —
///    vợ chồng, mẹ con, số cửa hàng. Nên `phoneExactMatch` **không** phải bằng
///    chứng quyết định, dù nghe rất chắc.
/// 2. **Trùng tên ở Việt Nam là chuyện thường** — "Nguyễn Văn A" có thể là
///    hàng nghìn người. Tên yếu hơn nhiều so với một CRM phương Tây.
/// 3. **Nhiều khách chung một địa chỉ** — chung cư, toà nhà, điểm nhận hàng.
///    Địa chỉ gần như vô giá trị khi đứng một mình.
/// 4. **Một người có nhiều số** — số Zalo, số nhận hàng, số người nhà. Nên
///    *thiếu* trùng khớp không nói lên điều gì (xem [IdentityEvidence]).
///
/// Đó là lý do `emailExactMatch` **nặng hơn** `phoneExactMatch` ở đây, ngược
/// với trực giác thường thấy: email ít dùng hơn trong bán lẻ Việt Nam, nhưng
/// khi có thì nó riêng tư hơn số điện thoại.
enum IdentityEvidenceKind {
  /// Mã người mua do nền tảng cấp, **trong phạm vi một kết nối**.
  ///
  /// Bằng chứng duy nhất đạt tới [IdentityConfidence.exact] — xem
  /// [scoreIdentity].
  platformAccountId(
    'platform_account_id',
    EvidenceFamily.identityKey,
    0.95,
    primary: true,
  ),

  /// Đã từng mua bằng chính danh tính này.
  orderHistoryMatch(
    'order_history_match',
    EvidenceFamily.behaviour,
    0.80,
    primary: true,
  ),

  /// Quan sát trực tiếp từ **bản ghi nghiệp vụ của chính người bán** — đơn
  /// hàng, tồn kho, sổ thu chi (WTM-303).
  ///
  /// Cùng nhóm [EvidenceFamily.behaviour] với [orderHistoryMatch], và đó là
  /// chủ ý: cả hai đều là *"dữ liệu người bán đã ghi"*, nên hai quan sát như
  /// vậy về cùng một chuyện là **một** tín hiệu, không phải hai. Một đề xuất
  /// đọc cả lịch sử đơn lẫn tồn kho không được vì thế mà chắc chắn hơn.
  /// **Không** `primary`: nó nói *"chuyện này có thật"*, không nói *"đây đúng
  /// là người này"*. Một dòng tồn kho không định danh ai cả — và `primary` là
  /// một khái niệm của bài toán danh tính, không phải của bằng chứng nói chung.
  businessRecordObservation(
    'business_record_observation',
    EvidenceFamily.behaviour,
    0.80,
  ),

  /// Trùng email **chính xác**.
  emailExactMatch('email_exact_match', EvidenceFamily.email, 0.65),

  /// Trùng số điện thoại **chính xác**.
  ///
  /// Nặng 0.55 chứ không hơn, và đó là con số quan trọng nhất bảng này: đủ để
  /// **đề xuất**, không bao giờ đủ để **tự liên kết**.
  phoneExactMatch('phone_exact_match', EvidenceFamily.phone, 0.55),

  /// Trùng tên chính xác.
  nameExactMatch('name_exact_match', EvidenceFamily.name, 0.20),

  /// Tên gần giống.
  nameSimilar('name_similar', EvidenceFamily.name, 0.10),

  /// Địa chỉ gần giống.
  addressSimilar('address_similar', EvidenceFamily.address, 0.08),

  /// Hai nguồn **nói ngược nhau**.
  ///
  /// Không phải "bằng chứng âm" — nó là *chưa ngã ngũ*. Xem [scoreIdentity].
  contradiction('contradiction', EvidenceFamily.identityKey, 0);

  const IdentityEvidenceKind(
    this.code,
    this.family,
    this.weight, {
    this.primary = false,
  });

  final String code;
  final EvidenceFamily family;

  /// Trọng số 0..1. Chỉ có nghĩa bên trong [scoreIdentity].
  final double weight;

  /// Bằng chứng **định danh trực tiếp người này**, không chỉ nhất quán với họ.
  final bool primary;

  static IdentityEvidenceKind? fromCode(String? code) {
    for (final k in IdentityEvidenceKind.values) {
      if (k.code == code) return k;
    }
    return null;
  }
}

/// Một quan sát — **cái đã nhìn thấy**, không phải mức tin tưởng.
///
/// ## Không có "bằng chứng âm"
///
/// Từ vựng này **không có** cách nào diễn đạt *"thiếu số điện thoại"* hay
/// *"không tìm thấy tên"*. Đó là cố ý: **thiếu dữ liệu không phải bằng chứng
/// ngược**. Ở bán lẻ Việt Nam, một khách không có email là chuyện bình thường,
/// không phải dấu hiệu họ là người khác.
///
/// Thứ duy nhất kéo điểm xuống là [IdentityEvidenceKind.contradiction], và nó
/// đòi một **quan sát thật sự mâu thuẫn**, không phải một ô trống.
@immutable
class IdentityEvidence {
  const IdentityEvidence({
    required this.kind,
    required this.source,
    this.detail,
  });

  final IdentityEvidenceKind kind;

  /// **Nơi đã nhìn thấy điều này** — bắt buộc, và đây là trường quan trọng
  /// nhất của lớp.
  ///
  /// Hai bằng chứng cùng `source` là **một lần quan sát**, không phải hai.
  /// Một thẻ liên hệ nhập vào cho cả tên, số điện thoại và email cùng lúc; đếm
  /// nó ba lần là tự tạo ra sự chắc chắn không có thật. Xem [scoreIdentity].
  ///
  /// Ví dụ: `'shopee:order:12345'` · `'contact_import:2026-08-08'` ·
  /// `'seller_typed'`.
  final String source;

  /// Câu người bán đọc được. Không dùng để tính điểm.
  final String? detail;

  @override
  String toString() => 'IdentityEvidence(${kind.code} @ $source)';
}

/// Kết quả chấm điểm — mang cả **vì sao**, không chỉ mức.
@immutable
class ScoredIdentity {
  const ScoredIdentity({
    required this.confidence,
    required this.score,
    required this.hasPrimary,
    required this.contradicted,
    required this.countedSources,
  });

  final IdentityConfidence confidence;

  /// 0..1. Chỉ để chẩn đoán và test — **không** hiển thị cho người bán.
  final double score;

  final bool hasPrimary;
  final bool contradicted;

  /// Số quan sát **thật sự được tính** sau khi gộp trùng. Nhỏ hơn số bằng
  /// chứng đưa vào nghĩa là đã có thứ bị gộp.
  final int countedSources;

  @override
  String toString() =>
      'ScoredIdentity(${confidence.code} score=${score.toStringAsFixed(2)} '
      'sources=$countedSources${contradicted ? " CONTRADICTED" : ""})';
}

/// Trần điểm — không bao giờ đạt 1.0.
const double kIdentityScoreCeiling = 0.99;

/// Mâu thuẫn **kẹp** điểm xuống đây.
///
/// Kẹp chứ không trừ dần: hai nguồn nói ngược nhau **không phải "đúng 60%"**,
/// mà là *chưa ngã ngũ*. Giá trị nằm dưới [kStrongFloor] nên một khẳng định bị
/// mâu thuẫn không bao giờ được đề xuất cho người bán.
const double kContradictionCeiling = 0.40;

/// Sàn để **đề xuất** cho người bán bấm.
const double kStrongFloor = 0.50;

/// Sàn để **giữ lại** — dưới mức này coi như không có gì.
const double kWeakFloor = 0.25;

/// Tính mức tin cậy **từ bằng chứng** — hàm thuần, tất định.
///
/// ## ⭐ Ba luật, và cả ba là luật CHỐNG CỘNG DỒN GIẢ
///
/// **1. Cùng `source` ⇒ một lần quan sát.** Một thẻ liên hệ cho tên + số điện
/// thoại + email là **một** quan sát, không phải ba. Gộp về bằng chứng mạnh
/// nhất trong cùng nguồn.
///
/// **2. Cùng [EvidenceFamily] ⇒ một tín hiệu.** "Tên khớp chính xác" và "tên
/// gần giống" là cùng một thứ nhìn hai lần. Gộp về mạnh nhất trong nhóm.
///
/// **3. Chỉ sau hai bước gộp mới cộng dồn** (noisy-OR):
/// `score = 1 − Π(1 − wᵢ)`.
///
/// Không có ba luật này, một connector chỉ cần tách một quan sát thành nhiều
/// dòng là đẩy được điểm lên bao nhiêu tuỳ ý — tức là **khai confidence bằng
/// cửa sau**, đúng thứ D-1 sinh ra để chặn.
///
/// ## `exact` KHÔNG đạt được bằng cộng dồn
///
/// [IdentityConfidence.exact] chỉ đến từ [IdentityEvidenceKind.platformAccountId]
/// — khoá do chính nền tảng cấp. Gộp bao nhiêu số điện thoại, email và tên
/// cũng **không bao giờ** tới `exact`, vì `exact` có nghĩa *"nền tảng bảo đảm
/// đây là một người duy nhất"*, không phải *"tôi rất chắc"*.
ScoredIdentity scoreIdentity(List<IdentityEvidence> evidence) {
  if (evidence.isEmpty) {
    return const ScoredIdentity(
      confidence: IdentityConfidence.none,
      score: 0,
      hasPrimary: false,
      contradicted: false,
      countedSources: 0,
    );
  }

  final contradicted = evidence.any(
    (e) => e.kind == IdentityEvidenceKind.contradiction,
  );

  final real = evidence
      .where((e) => e.kind != IdentityEvidenceKind.contradiction)
      .toList();

  // Luật 1 — gộp theo nguồn quan sát.
  final strongestPerSource = <String, IdentityEvidence>{};
  for (final e in real) {
    final current = strongestPerSource[e.source];
    if (current == null || e.kind.weight > current.kind.weight) {
      strongestPerSource[e.source] = e;
    }
  }

  // Luật 2 — gộp theo nhóm tín hiệu.
  final strongestPerFamily = <EvidenceFamily, IdentityEvidence>{};
  for (final e in strongestPerSource.values) {
    final current = strongestPerFamily[e.kind.family];
    if (current == null || e.kind.weight > current.kind.weight) {
      strongestPerFamily[e.kind.family] = e;
    }
  }

  final counted = strongestPerFamily.values.toList();

  // Luật 3 — cộng dồn noisy-OR trên phần còn lại.
  final remaining = counted.fold<double>(
    1,
    (acc, e) => acc * (1 - e.kind.weight),
  );
  var score = 1 - remaining;
  if (score > kIdentityScoreCeiling) score = kIdentityScoreCeiling;
  if (contradicted && score > kContradictionCeiling) {
    score = kContradictionCeiling;
  }

  final hasPlatformKey =
      !contradicted &&
      counted.any((e) => e.kind == IdentityEvidenceKind.platformAccountId);
  final hasPrimary = counted.any((e) => e.kind.primary);

  return ScoredIdentity(
    confidence: _confidenceFor(score, hasPlatformKey),
    score: score,
    hasPrimary: hasPrimary,
    contradicted: contradicted,
    countedSources: counted.length,
  );
}

IdentityConfidence _confidenceFor(double score, bool hasPlatformKey) {
  if (hasPlatformKey) return IdentityConfidence.exact;
  if (score >= kStrongFloor) return IdentityConfidence.strong;
  if (score >= kWeakFloor) return IdentityConfidence.weak;
  return IdentityConfidence.none;
}
