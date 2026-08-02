import 'package:flutter/foundation.dart';

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
