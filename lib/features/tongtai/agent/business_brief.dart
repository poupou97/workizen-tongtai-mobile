import 'package:flutter/foundation.dart';

import '../action/business_action.dart';
import '../consumer/external_identity.dart';
import '../consumer/identity_evidence.dart';
import '../core/provenance.dart';
import '../proposal/proposed_change.dart';

/// **Một việc đáng chú ý hôm nay** — WTM-303 · Founder Task Order 2026-08-08.
///
/// ## Vì sao có lớp này, khi đã có `BusinessAlert` và `Opportunity`
///
/// `BusinessAlert` nói *"doanh thu giảm 18%"*. `Opportunity` nói *"có thể bán
/// thêm nhóm này"*. Cả hai đều dừng ở **nhận xét** — người bán đọc xong vẫn
/// phải tự nghĩ ra phải làm gì, và không có gì ghi lại việc họ đã quyết.
///
/// [BriefItem] là mắt xích còn thiếu: nó mang **cả bốn** thứ mà một câu chuyện
/// nghiệp vụ cần, trong một đối tượng:
///
/// | | Trường |
/// |---|---|
/// | Chuyện gì xảy ra | [headline] |
/// | Vì sao nghĩ vậy | [evidence] — mỗi cái có `detail` người đọc được |
/// | Nên làm gì | [suggestion] + [move] |
/// | Chắc tới đâu | [confidence] — **tính từ** [evidence], không khai |
///
/// ## Không phải bảng thứ sáu
///
/// [BriefItem] **không được lưu**. Nó là kết quả tất định của Rule Twin trên
/// dữ liệu hiện tại, dựng lại được bất cứ lúc nào. Thứ *được* lưu là **quyết
/// định** của người bán — và quyết định đã có chỗ ở: `ProposedChange` (đổi một
/// sự thật) hoặc `BusinessAction` (làm một việc ra ngoài).
///
/// Thêm một bảng "brief" sẽ tạo ra đúng thứ ADR-TON-015 cấm: một bản sao của
/// dữ liệu dẫn xuất, lệch dần khỏi nguồn.

/// Loại việc — quyết định biểu tượng, màu, và **luật dựng câu**.
enum BriefKind {
  /// Một khách quen đã im lặng quá lâu so với nhịp của chính họ.
  customerAtRisk('customer_at_risk'),

  /// Một mặt hàng sắp hết hoặc đã hết.
  stockRunningOut('stock_running_out'),

  /// Một mặt hàng bán ra gần bằng giá vốn.
  marginTooThin('margin_too_thin'),

  /// Cảnh báo toàn doanh nghiệp — doanh thu, số đơn, dòng tiền.
  businessSignal('business_signal');

  const BriefKind(this.code);

  final String code;

  static BriefKind? fromCode(String? code) {
    for (final k in BriefKind.values) {
      if (k.code == code) return k;
    }
    return null;
  }
}

/// Mức khẩn — cùng thang với `BusinessAlertSeverity`, cố ý **không** dùng lại
/// enum đó: brief xếp hạng *việc cần làm*, cảnh báo xếp hạng *tình trạng*.
/// Chỉ số enum tăng dần theo mức, nên nó dùng làm khoá sắp xếp được.
enum BriefSeverity {
  info('info'),
  warning('warning'),
  critical('critical');

  const BriefSeverity(this.code);

  final String code;
}

/// **Nên làm gì** — và đây là chỗ hai vòng đời của nền tách nhau.
///
/// WTM-299/300 cố ý không gộp `ProposedChange` với `BusinessAction`. Cái tách
/// đó nổi lên ngay tại đây: *"giá vốn nên là 45.000"* là **đổi một sự thật**;
/// *"nhắn cho khách"* là **một việc làm ra ngoài**. Gộp lại sẽ ép việc nhắn
/// tin phải mang `evidence[]` và ép giá vốn phải mang `idempotencyKey`.
@immutable
sealed class SuggestedMove {
  const SuggestedMove();
}

/// Đề nghị **đổi một sự thật** trên bản ghi ⇒ trở thành `ProposedChange`, đi
/// qua bốn cổng của `ProposalGate`.
@immutable
class ChangeAFact extends SuggestedMove {
  const ChangeAFact({
    required this.domain,
    required this.field,
    required this.proposedValue,
    this.currentValue,
  });

  final ProposalDomain domain;
  final String field;

  /// `null` = **ô đang trống**, không phải "bằng không".
  final String? currentValue;

  final String proposedValue;
}

/// Đề nghị **làm một việc** ⇒ trở thành `BusinessAction` ở trạng thái
/// `planned`, chờ người bấm.
///
/// `planned` không phải trạng thái chờ tạm bợ — nó đúng nghĩa
/// `AutonomyMode.confirm`: *đã dựng, chưa được phép chạy*.
@immutable
class DoSomething extends SuggestedMove {
  const DoSomething({
    required this.actionType,
    required this.vendor,
    this.parameters = const {},
  });

  final BusinessActionType actionType;
  final ActionVendor vendor;
  final Map<String, Object?> parameters;

  ActionRisk get risk => actionType.risk;
}

/// Một việc đáng chú ý, đã kèm sẵn đề nghị và bằng chứng.
@immutable
class BriefItem {
  BriefItem({
    required this.kind,
    required this.severity,
    required this.subjectKind,
    required this.subjectId,
    required this.headline,
    required this.suggestion,
    required this.evidence,
    required this.observedAt,
    this.move,
    this.subjectLabel,
  }) : assert(headline != '', 'một việc không nói được nó là gì thì vô dụng'),
       assert(
         evidence.isNotEmpty,
         'một nhận định không bằng chứng là một phỏng đoán',
       ),
       scored = scoreIdentity(evidence);

  /// **Tất định** — cùng dữ liệu ⇒ cùng id, nên dựng lại brief không sinh ra
  /// một việc thứ hai cho cùng một chuyện.
  ///
  /// Nó cũng là `correlationId` của cả chuỗi: đề xuất, hành động và việc hẹn
  /// lại của cùng một câu chuyện đều mang chuỗi này. Đó là thứ thay cho một
  /// entity `BusinessConversation` (WTM-296 §10).
  String get id => '${kind.code}:$subjectId';

  String get correlationId => id;

  final BriefKind kind;
  final BriefSeverity severity;

  /// `customer` · `product` · `business`.
  final String subjectKind;
  final String subjectId;

  /// Tên người bán nhận ra. `null` khi chưa tra được — **không** thay bằng id.
  final String? subjectLabel;

  /// Chuyện gì xảy ra, một câu, có số. Dữ liệu chứ không phải nhãn giao diện:
  /// nó chứa tên và con số của chính doanh nghiệp này.
  final String headline;

  /// Nên làm gì, một câu.
  final String suggestion;

  /// Vì sao nghĩ vậy. Mỗi bằng chứng mang `detail` — **câu người bán đọc**.
  ///
  /// Đây là chỗ duy nhất chứa "vì sao": màn hình đọc `detail` ra thẳng, không
  /// dựng một danh sách lý do thứ hai. Hai danh sách lý do sẽ lệch nhau đúng
  /// vào ngày ai đó sửa một bên (P-27).
  final List<IdentityEvidence> evidence;

  /// Nên làm gì — `null` = **không có một việc đúng duy nhất**.
  ///
  /// Đúng cho cảnh báo vĩ mô: *"doanh thu giảm"* không có một nút bấm nào giải
  /// quyết được. Bịa ra một nút ở đó là hứa hão, và người bán sẽ bấm đúng một
  /// lần trước khi thôi tin cả màn hình.
  final SuggestedMove? move;

  /// Việc này bấm được hay chỉ để biết.
  bool get isActionable => move != null;

  /// **Tính ra**, không khai (WTM-298).
  final ScoredIdentity scored;

  IdentityConfidence get confidence => scored.confidence;

  final DateTime observedAt;

  /// Việc này nói về dữ liệu mẫu hay dữ liệu thật.
  ///
  /// Suy từ id của đối tượng — `Provenance.inferFromId` là **chỗ duy nhất**
  /// biết tiền tố `sample-`, nên không nơi nào tự chế lại quy tắc. Rồi khai
  /// tường minh: bản ghi sinh ra từ đây *biết* nó nói về cái gì, thay vì để
  /// người sau đoán lại từ id (§3 Task Order: `provenance = DEMO/SAMPLE`).
  Provenance get provenance =>
      Provenance.declared(Provenance.inferFromId(subjectId).source);

  /// Dữ liệu mẫu ⇒ **phải** thấy được trên màn hình. Founder đã một lần nhầm
  /// màn demo với dashboard thật (WTM-143).
  bool get isDemo => provenance.source == ProvenanceSource.sample;

  @override
  bool operator ==(Object other) => other is BriefItem && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BriefItem(${kind.code} $subjectId ${confidence.code})';
}

/// Thứ tự hiện: khẩn trước, rồi chắc chắn hơn trước, rồi id — **tổng và lặp
/// lại được**, nên hai lần mở app thấy cùng một thứ tự.
int compareBriefItems(BriefItem a, BriefItem b) {
  final bySeverity = b.severity.index.compareTo(a.severity.index);
  if (bySeverity != 0) return bySeverity;
  final byConfidence = b.confidence.rank.compareTo(a.confidence.rank);
  if (byConfidence != 0) return byConfidence;
  return a.id.compareTo(b.id);
}
