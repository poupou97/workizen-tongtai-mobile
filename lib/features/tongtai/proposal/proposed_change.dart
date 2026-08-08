import 'package:flutter/foundation.dart';

import '../consumer/external_identity.dart';
import '../consumer/identity_evidence.dart';
import '../core/provenance.dart';

/// Miền nghiệp vụ của một đề xuất — quyết định **luật xét lại** khi bị bỏ qua
/// (WTM-299 · D-2).
///
/// ## Vì sao miền quyết định luật, không phải một luật chung
///
/// COMP AI cấm **vĩnh viễn**: người bỏ qua một giá trị là không bao giờ đề nghị
/// lại. Đúng cho *tên một người* — tên không đổi, và hỏi lại là làm phiền.
///
/// **Sai cho giá nhà cung cấp.** Người bán bỏ qua đề nghị "giá vốn nên là
/// 45.000" hôm nay không có nghĩa là sáu tháng sau vẫn vậy. Cấm vĩnh viễn ở
/// đó biến một lần bấm thành một quyết định trọn đời.
enum ProposalDomain {
  /// Danh tính khách — **bỏ qua là vĩnh viễn**.
  identity('identity'),

  /// Giá vốn, giá bán, giá nhà cung cấp.
  pricing('pricing'),

  /// Nhà cung cấp.
  supplier('supplier'),

  /// Dự báo cầu.
  forecast('forecast'),

  /// Mức tồn kho, ngưỡng cảnh báo.
  inventory('inventory'),

  /// Hồ sơ khách (tên hiển thị, địa chỉ giao).
  customerProfile('customer_profile');

  const ProposalDomain(this.code);

  final String code;

  static ProposalDomain? fromCode(String? code) {
    for (final d in ProposalDomain.values) {
      if (d.code == code) return d;
    }
    return null;
  }

  /// Sau bao lâu thì một đề xuất bị bỏ qua được phép đề nghị lại.
  ///
  /// `null` = **không bao giờ** — chỉ đúng cho [identity].
  Duration? get reconsiderAfter => switch (this) {
    ProposalDomain.identity => null,
    ProposalDomain.pricing ||
    ProposalDomain.supplier ||
    ProposalDomain.forecast ||
    ProposalDomain.inventory => const Duration(days: 30),
    ProposalDomain.customerProfile => const Duration(days: 90),
  };
}

/// Vòng đời của một đề nghị đổi **sự thật nghiệp vụ**.
///
/// Bốn trạng thái, và mỗi trạng thái là một câu trả lời khác nhau:
///
/// | | Nghĩa |
/// |---|---|
/// | [proposed] | *"tôi nghĩ vậy, bạn xem"* — treo chờ người |
/// | [applied] | người đã duyệt, giá trị đã vào bản ghi |
/// | [dismissed] | người đã bỏ qua — xem luật xét lại |
/// | [superseded] | có đề xuất mới hơn thay thế |
enum ProposalStatus {
  proposed('proposed'),
  applied('applied'),
  dismissed('dismissed'),
  superseded('superseded');

  const ProposalStatus(this.code);

  final String code;

  static ProposalStatus? fromCode(String? code) {
    for (final s in ProposalStatus.values) {
      if (s.code == code) return s;
    }
    return null;
  }

  /// Đề xuất còn đang chờ người quyết.
  bool get isOpen => this == ProposalStatus.proposed;
}

/// Ai đề nghị.
///
/// Dùng `rule:<tên>` để khi một luật hoá ra sai, gỡ được **tất cả** thứ nó đã
/// đề nghị — cùng kỷ luật với `IdentityLinkEvent.actor` (WTM-291).
@immutable
class ProposalAuthor {
  const ProposalAuthor._(this.code);

  /// Người bán tự đề nghị (hiếm — nhưng có, khi họ sửa tay rồi muốn ghi nhận).
  static const ProposalAuthor seller = ProposalAuthor._('seller');

  /// AI đề nghị.
  static const ProposalAuthor agent = ProposalAuthor._('agent');

  /// Một luật dẫn xuất đề nghị.
  factory ProposalAuthor.rule(String name) => ProposalAuthor._('rule:$name');

  static ProposalAuthor? fromCode(String? code) =>
      code == null || code.isEmpty ? null : ProposalAuthor._(code);

  final String code;

  bool get isHuman => code == 'seller';

  @override
  bool operator ==(Object other) =>
      other is ProposalAuthor && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}

/// Một đề nghị đổi sự thật nghiệp vụ — **chưa phải sự thật**.
///
/// ## ⭐ Khác `BusinessAction` ở chỗ nào
///
/// | | `ProposedChange` | `BusinessAction` (WTM-300) |
/// |---|---|---|
/// | Là gì | đề nghị đổi **một sự thật** | **một việc làm ra ngoài** |
/// | Ví dụ | "giá vốn nên là 45.000" | "gửi tin cho khách" |
/// | Hoàn tác | đổi trạng thái | **có thể không hoàn tác được** |
/// | Cần | evidence + mức tin cậy | idempotency + duyệt + kết quả |
///
/// Gộp hai thứ này sẽ ép *"gửi tin nhắn"* phải mang `evidence[]`, và ép *"giá
/// vốn nên là 45.000"* phải mang `idempotencyKey`. Cả hai đều vô nghĩa.
///
/// ## Mức tin cậy được TÍNH, không khai (WTM-298)
///
/// Constructor nhận `evidence`, không nhận `confidence`. Cùng kỷ luật đã áp
/// cho `IdentityCandidate`.
@immutable
class ProposedChange {
  ProposedChange({
    required this.id,
    required this.domain,
    required this.subjectKind,
    required this.subjectId,
    required this.field,
    required this.proposedValue,
    required this.evidence,
    required this.proposedBy,
    required this.summary,
    required this.createdAt,
    this.subjectLabel,
    this.currentValue,
    this.correlationId,
    this.status = ProposalStatus.proposed,
    this.decidedAt,
    this.provenance = Provenance.manual,
  }) : assert(
         evidence.isNotEmpty,
         'một đề xuất không bằng chứng là một phỏng đoán',
       ),
       assert(summary != '', 'đề xuất phải nói được nó là gì'),
       scored = scoreIdentity(evidence);

  final String id;

  /// Nối các bản ghi của **cùng một chuỗi việc** — Evidence · AgentTask ·
  /// ProposedChange · BusinessAction · Result.
  ///
  /// Đây là thứ thay cho một entity `BusinessConversation`: "câu chuyện" là
  /// một **truy vấn** theo trường này, không phải một bảng (WTM-296 §10).
  final String? correlationId;

  final ProposalDomain domain;

  /// Loại đối tượng — `customer` · `product` · `order` · …
  final String subjectKind;
  final String subjectId;

  /// Nhãn người bán nhận ra. `null` khi chưa tra được.
  final String? subjectLabel;

  /// Trường nghiệp vụ được đề nghị đổi.
  final String field;

  /// Giá trị hiện tại — để hiện đối chiếu. `null` = **ô đang trống**, không
  /// phải "bằng không".
  final String? currentValue;

  final String proposedValue;

  final List<IdentityEvidence> evidence;

  /// **Tính ra**, không khai (WTM-298).
  final ScoredIdentity scored;

  IdentityConfidence get confidence => scored.confidence;

  final ProposalAuthor proposedBy;

  /// Câu tiếng Việt người bán đọc được.
  ///
  /// Lưu cùng bản ghi chứ không dựng lúc hiển thị: cấu hình và lời giải thích
  /// của nó phải đi cùng nhau, nếu không bản dịch sẽ lệch khỏi dữ liệu
  /// (bài học từ `sandboxPolicy.summary` của COMP AI).
  final String summary;

  final ProposalStatus status;
  final DateTime createdAt;

  /// Khi người quyết. `null` = **chưa ai quyết**, không phải "quyết lúc 0".
  final DateTime? decidedAt;

  final Provenance provenance;

  /// Đề xuất này có được phép đề nghị lại không, tính tại [now].
  ///
  /// Hai đường mở, theo chỉ đạo Founder 2026-08-08:
  ///
  /// 1. **Hết thời hạn** của miền ([ProposalDomain.reconsiderAfter])
  /// 2. **Có bằng chứng mạnh hơn** lần bị bỏ qua — [strongerEvidence]
  ///
  /// [ProposalDomain.identity] không có đường 1: `reconsiderAfter` là `null`,
  /// nên chỉ bằng chứng mạnh hơn mới mở lại được. Đó là chỗ luật của COMP AI
  /// đúng và ta giữ.
  bool canReconsiderAt(DateTime now, {ScoredIdentity? strongerEvidence}) {
    if (status != ProposalStatus.dismissed) return false;

    if (strongerEvidence != null &&
        strongerEvidence.score > scored.score &&
        strongerEvidence.confidence.rank > scored.confidence.rank) {
      return true;
    }

    final window = domain.reconsiderAfter;
    if (window == null) return false;

    final decided = decidedAt;
    if (decided == null) return false;
    return !now.isBefore(decided.add(window));
  }

  ProposedChange copyWith({
    ProposalStatus? status,
    DateTime? decidedAt,
    String? correlationId,
  }) => ProposedChange(
    id: id,
    correlationId: correlationId ?? this.correlationId,
    domain: domain,
    subjectKind: subjectKind,
    subjectId: subjectId,
    subjectLabel: subjectLabel,
    field: field,
    currentValue: currentValue,
    proposedValue: proposedValue,
    evidence: evidence,
    proposedBy: proposedBy,
    summary: summary,
    status: status ?? this.status,
    createdAt: createdAt,
    decidedAt: decidedAt ?? this.decidedAt,
    provenance: provenance,
  );

  @override
  bool operator ==(Object other) => other is ProposedChange && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ProposedChange(${domain.code}/$field → $proposedValue [${status.code}])';
}
