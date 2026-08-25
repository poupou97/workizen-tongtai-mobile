import 'package:flutter/foundation.dart';

import '../finance/finance_category.dart';

/// Loại nguồn đầu vào (ADR-TON-023).
///
/// Producer **không phải** danh bạ nhà cung cấp — nó là capability quản lý
/// toàn bộ **đầu vào** của doanh nghiệp, và nhà cung cấp chỉ là một loại.
/// Dogfood Workizen làm rõ điều này: đầu vào của một doanh nghiệp AI-first là
/// provider, hạ tầng, công cụ và thời gian — không có nhà cung cấp hàng hoá
/// nào cả, và cả bốn thứ đó hôm nay rơi hết vào `FinanceCategory.other`.
enum BusinessInputKind {
  /// Nhà cung cấp hàng hoá — loại duy nhất mô hình cũ biết.
  supplier('supplier'),

  /// Dịch vụ/API trả tiền theo mức dùng: AI provider, cổng thanh toán.
  provider('provider'),

  /// Hạ tầng chạy nền: máy chủ, lưu trữ, tên miền.
  infrastructure('infrastructure'),

  /// Phần mềm dùng để làm việc: thuê bao theo chỗ ngồi.
  tooling('tooling'),

  /// Người: nhân viên, cộng tác viên, agent.
  people('people');

  const BusinessInputKind(this.code);

  /// Mã lưu xuống DB và `.ttbk`. **Không bao giờ là nhãn hiển thị.**
  final String code;

  static BusinessInputKind? fromCode(String? code) {
    for (final k in BusinessInputKind.values) {
      if (k.code == code) return k;
    }
    return null;
  }

  /// Nhóm chi phí một khoản tiền trả cho nguồn này thuộc về (WTM-236).
  ///
  /// Một nguồn đầu vào và khoản tiền trả cho nó là **hai mặt của cùng một sự
  /// việc**, nên ánh xạ này phải tồn tại ở đúng một chỗ. Ba loại dùng chung mã
  /// với `FinanceCategory`; hai loại còn lại đã có nhóm sẵn từ trước — nhà
  /// cung cấp hàng hoá là tiền nhập hàng, và người là chi phí nhân sự.
  ///
  /// Hàm này **toàn phần**: không loại nào rơi vào "Khác", vì rơi vào "Khác"
  /// chính là vấn đề dogfood tìm ra.
  FinanceCategory get financeCategory => switch (this) {
    BusinessInputKind.supplier => FinanceCategory.productCost,
    BusinessInputKind.provider => FinanceCategory.provider,
    BusinessInputKind.infrastructure => FinanceCategory.infrastructure,
    BusinessInputKind.tooling => FinanceCategory.tooling,
    BusinessInputKind.people => FinanceCategory.staff,
  };
}

/// Nhịp trả tiền của một nguồn đầu vào.
enum InputCadence {
  /// Trả một lần: mua máy, phí đăng ký năm đầu.
  oneOff('one_off'),
  monthly('monthly'),
  yearly('yearly'),

  /// Trả theo mức dùng — token AI, băng thông. **Không phải một cam kết.**
  usageBased('usage_based');

  const InputCadence(this.code);

  final String code;

  /// Nhịp này có tạo ra một khoản **cam kết** hằng tháng không.
  ///
  /// `usageBased` trả `false` một cách cố ý: chi phí theo mức dùng có thể bằng
  /// 0 vào tháng người bán không dùng gì. Gộp nó vào con số cam kết là **bịa
  /// một sự chắc chắn không tồn tại** — đúng thứ kỷ luật `null ≠ 0` của repo
  /// này bảo vệ, áp cho một phép cộng thay vì một trường.
  bool get isCommitment =>
      this == InputCadence.monthly || this == InputCadence.yearly;

  static InputCadence? fromCode(String? code) {
    for (final c in InputCadence.values) {
      if (c.code == code) return c;
    }
    return null;
  }
}

/// Một nguồn đầu vào của doanh nghiệp (WTM-229).
@immutable
class BusinessInput {
  const BusinessInput({
    required this.id,
    required this.name,
    required this.kind,
    this.cadence,
    this.expectedAmount,
    this.note = '',
    this.updatedAt,
  });

  final String id;
  final String name;
  final BusinessInputKind kind;

  /// `null` = người bán chưa nói nhịp trả tiền.
  final InputCadence? cadence;

  /// Số tiền mỗi nhịp — `null` = **chưa nhập**, không phải miễn phí. Cùng kỷ
  /// luật `costPrice` (WTM-204) và `quantity` (WTM-227).
  final double? expectedAmount;

  final String note;
  final DateTime? updatedAt;

  /// Phần đóng góp vào **cam kết hằng tháng**, hoặc `null` khi không trả lời
  /// được — chưa biết nhịp, chưa nhập tiền, hoặc trả theo mức dùng.
  ///
  /// `null` chứ không phải 0: 0 nói *"nguồn này không tốn gì"*, null nói
  /// *"chưa đủ dữ liệu để cộng nó vào"*. Người bán nhìn tổng cam kết phải biết
  /// mình đang nhìn một con số đầy đủ hay một con số thiếu.
  double? get monthlyCommitment {
    final amount = expectedAmount;
    final cadence = this.cadence;
    if (amount == null || cadence == null || !cadence.isCommitment) return null;
    return cadence == InputCadence.yearly ? amount / 12 : amount;
  }

  BusinessInput copyWith({
    String? name,
    BusinessInputKind? kind,
    InputCadence? cadence,
    double? expectedAmount,
    String? note,
    DateTime? updatedAt,
  }) => BusinessInput(
    id: id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    cadence: cadence ?? this.cadence,
    expectedAmount: expectedAmount ?? this.expectedAmount,
    note: note ?? this.note,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// The same record under a different id — the sample-seeding remap hook
  /// (WTM-144/ADR-TON-014), so `kSampleBusinessInputs` fixtures pick up the
  /// `sample-` prefix at seed time exactly like every other sample domain.
  BusinessInput withId(String newId) => BusinessInput(
    id: newId,
    name: name,
    kind: kind,
    cadence: cadence,
    expectedAmount: expectedAmount,
    note: note,
    updatedAt: updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is BusinessInput && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Điều Producer trả lời được về tiền, suy từ danh sách nguồn (WTM-229).
///
/// Suy tại chỗ đọc, **không lưu** — một cột "tổng cam kết" sẽ là bản sao thứ
/// hai của thứ các nguồn đã nói, và hai bên sẽ lệch ngay lần đầu ai đó sửa một
/// nguồn mà quên cập nhật tổng (họ lỗi WTM-196/200/201/205).
@immutable
class BusinessInputSummary {
  const BusinessInputSummary({
    required this.total,
    required this.monthlyCommitment,
    required this.unknownCount,
  });

  factory BusinessInputSummary.from(Iterable<BusinessInput> inputs) {
    var commitment = 0.0;
    var unknown = 0;
    var total = 0;
    for (final input in inputs) {
      total += 1;
      final monthly = input.monthlyCommitment;
      if (monthly == null) {
        unknown += 1;
      } else {
        commitment += monthly;
      }
    }
    return BusinessInputSummary(
      total: total,
      monthlyCommitment: commitment,
      unknownCount: unknown,
    );
  }

  final int total;

  /// Tổng tiền **cam kết** mỗi tháng. Chỉ gồm nguồn đã đủ dữ liệu.
  final double monthlyCommitment;

  /// Bao nhiêu nguồn **không** góp vào con số trên vì chưa đủ dữ liệu hoặc trả
  /// theo mức dùng. Hiện con số này cạnh tổng là bắt buộc: một tổng không nói
  /// mình còn thiếu gì sẽ được đọc như một tổng đầy đủ.
  final int unknownCount;

  bool get isComplete => unknownCount == 0;
}

/// Bộ **nguồn đầu vào mẫu** cho doanh nghiệp demo (WTM-461 / ADR-TON-014).
///
/// Dogfood máy thật (2026-08-15) hiện Home *"Nguồn hàng: 0 đầu vào"* cạnh Kho
/// 114 sản phẩm: bộ dữ liệu mẫu chưa gieo miền Business Input nào, nên demo kể
/// chuyện cụt — một AI Business OS mà không có lấy một đầu vào để nói về chi
/// phí. Bộ này lấp đúng miền đó, **nối logic với chi phí mẫu đã gieo**:
///
/// * `supplier` — nhà cung cấp hàng hoá, tiền nhập hàng (`productCost`, biến
///   đổi theo doanh thu ⇒ `usageBased`, không phải cam kết cố định).
/// * `provider` — AI trả theo token (`usageBased` ⇒ cam kết `null`, đúng kỷ
///   luật *"chưa đủ dữ liệu để cộng"* của màn Nguồn hàng).
/// * `infrastructure` — VPS hằng tháng + tên miền hằng năm.
/// * `tooling` — Workspace hằng tháng + Canva hằng năm.
/// * `people` — cộng tác viên đóng gói, ứng với chi phí nhân sự (`staff`).
///
/// Đủ **cả năm loại** [BusinessInputKind] và cả bốn nhịp [InputCadence], nên màn
/// Nguồn hàng có một tổng cam kết thật **kèm** hai nguồn theo mức dùng chưa cộng
/// vào — chính câu chuyện màn ấy được dựng để kể.
///
/// Id để **trần** (`input-…`); [SampleDataSeeder] gắn tiền tố `sample-` lúc gieo
/// qua [BusinessInput.withId], y như mọi miền mẫu khác — một vòng đời, một
/// đường xoá.
const List<BusinessInput> kSampleBusinessInputs = [
  BusinessInput(
    id: 'input-supplier-xuong-may',
    name: 'Xưởng may Thành Phát',
    kind: BusinessInputKind.supplier,
    cadence: InputCadence.usageBased,
    note: 'Nhập hàng theo đơn — chi phí đổi theo lượng đặt, không cố định.',
  ),
  BusinessInput(
    id: 'input-provider-workizen-ai',
    name: 'Workizen AI (token)',
    kind: BusinessInputKind.provider,
    cadence: InputCadence.usageBased,
    note: 'Trả theo lượng token dùng mỗi tháng.',
  ),
  BusinessInput(
    id: 'input-infra-vps',
    name: 'Máy chủ VPS',
    kind: BusinessInputKind.infrastructure,
    cadence: InputCadence.monthly,
    expectedAmount: 250000,
    note: 'Hạ tầng chạy nền cho cửa hàng online.',
  ),
  BusinessInput(
    id: 'input-infra-domain',
    name: 'Tên miền cửa hàng (.vn)',
    kind: BusinessInputKind.infrastructure,
    cadence: InputCadence.yearly,
    expectedAmount: 850000,
    note: 'Gia hạn tên miền hằng năm.',
  ),
  BusinessInput(
    id: 'input-tooling-workspace',
    name: 'Google Workspace',
    kind: BusinessInputKind.tooling,
    cadence: InputCadence.monthly,
    expectedAmount: 150000,
    note: 'Email và lưu trữ theo chỗ ngồi.',
  ),
  BusinessInput(
    id: 'input-tooling-canva',
    name: 'Canva Pro',
    kind: BusinessInputKind.tooling,
    cadence: InputCadence.yearly,
    expectedAmount: 1200000,
    note: 'Thiết kế ảnh sản phẩm, trả theo năm.',
  ),
  BusinessInput(
    id: 'input-people-dong-goi',
    name: 'Cộng tác viên đóng gói',
    kind: BusinessInputKind.people,
    cadence: InputCadence.monthly,
    expectedAmount: 3000000,
    note: 'Đóng gói và giao hàng cuối tuần.',
  ),
];
