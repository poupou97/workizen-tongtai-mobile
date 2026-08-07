import 'package:flutter/foundation.dart';

import '../core/provenance.dart';

/// Loại khoản đối soát — **từ vựng đóng** (WTM-292 · N0.4 · ADR-TON-024).
///
/// Mã lạ ⇒ `null`, **không** ánh xạ về mã gần giống nhất (ADR-TON-018). Ánh xạ
/// gần đúng ở đây có nghĩa là một khoản phí lạ bị tính vào một loại quen, và
/// người bán sẽ đọc một con số lợi nhuận không ai truy ngược được.
enum SettlementKind {
  /// Phí sàn cố định.
  platformFee('platform_fee'),

  /// Hoa hồng theo doanh số — thường gắn ở **món**.
  commission('commission'),

  /// Phí vận chuyển.
  shippingFee('shipping_fee'),

  /// Mã giảm giá. **Bắt buộc khai `fundedBy`.**
  voucher('voucher'),

  /// Người bán tự giảm. **Bắt buộc khai `fundedBy`.**
  discount('discount'),

  /// Hoàn tiền cho khách.
  refund('refund'),

  /// Sàn điều chỉnh — bồi thường, phạt.
  adjustment('adjustment'),

  /// Khách khiếu nại qua ngân hàng.
  chargeback('chargeback'),

  /// Thuế khấu trừ tại nguồn.
  tax('tax'),

  /// Sàn trả về một loại app chưa biết.
  ///
  /// Là một mã **thật**, không phải chỗ chứa rác: nó nói *"có tiền chuyển động
  /// mà chưa phân loại được"*, và Rule Twin đọc nó để biết mình chưa đủ dữ
  /// liệu — khác hẳn việc im lặng gán vào `adjustment`.
  unknown('unknown');

  const SettlementKind(this.code);

  final String code;

  static SettlementKind? fromCode(String? code) {
    for (final k in SettlementKind.values) {
      if (k.code == code) return k;
    }
    return null;
  }

  /// Loại này có ai đó tài trợ, nên **phải** khai `fundedBy`.
  bool get requiresFundingSource =>
      this == SettlementKind.voucher || this == SettlementKind.discount;
}

/// Tiền đi vào hay đi ra — **tường minh, không suy từ dấu của số**.
enum SettlementDirection {
  /// Người bán nhận thêm — bồi thường, hoàn phí.
  inbound('inbound'),

  /// Người bán mất đi — phí, hoa hồng, thuế.
  outbound('outbound');

  const SettlementDirection(this.code);

  final String code;

  static SettlementDirection? fromCode(String? code) {
    for (final d in SettlementDirection.values) {
      if (d.code == code) return d;
    }
    return null;
  }
}

/// Ai trả khoản giảm giá này.
///
/// **Không có giá trị mặc định**, và đó là điểm quan trọng nhất của enum này:
/// nhầm ở đây làm lợi nhuận sai đúng theo hướng dễ chịu — người bán tưởng sàn
/// tài trợ trong khi chính mình chịu.
enum FundingSource {
  /// Sàn tài trợ ⇒ **không phải chi phí của người bán**.
  platform('platform'),

  /// Người bán chịu ⇒ trừ thẳng vào lợi nhuận.
  seller('seller'),

  /// Chia theo tỷ lệ. Không có tỷ lệ kèm theo thì đây là [unknown] trá hình —
  /// xem `SettlementLine.sellerShare`.
  shared('shared'),

  /// Chưa biết ⇒ **lợi nhuận là chưa biết**, không phải "coi như sàn trả".
  unknown('unknown');

  const FundingSource(this.code);

  final String code;

  static FundingSource? fromCode(String? code) {
    for (final f in FundingSource.values) {
      if (f.code == code) return f;
    }
    return null;
  }
}

/// Một khoản tiền sàn giữ lại hoặc trả thêm, **gắn với một đơn**.
///
/// ## Vì sao `amount` luôn dương
///
/// *Hoàn lại một khoản phí* đảo chiều so với *khoản phí* — mà cả hai đều mang
/// `kind: platformFee`. Nếu chiều nằm ở dấu của số, thì connector A viết
/// `-50000` và connector B viết `50000` cho **cùng một sự việc**, và không ai
/// phát hiện cho tới khi báo cáo lệch.
///
/// Cùng họ lỗi với "mã lạ rơi về default": để ngữ nghĩa nằm ngầm trong biểu
/// diễn thay vì nói ra.
@immutable
class SettlementLine {
  const SettlementLine({
    required this.id,
    required this.orderId,
    required this.kind,
    required this.direction,
    required this.amount,
    required this.currency,
    required this.occurredAt,
    required this.fundedBy,
    this.orderItemId,
    this.payoutId,
    this.sellerShare,
    this.provenance = Provenance.manual,
  }) : assert(amount >= 0, 'amount luôn dương — chiều nằm ở `direction`'),
       assert(
         sellerShare == null || (sellerShare >= 0 && sellerShare <= 1),
         'sellerShare là tỷ lệ 0..1',
       );

  final String id;

  /// **Luôn có.** Một khoản đối soát không gắn đơn nào là một giao dịch Finance
  /// bình thường, không phải khoản đối soát.
  final String orderId;

  /// Có khi khoản này thuộc về một món cụ thể (hoa hồng theo món).
  ///
  /// `null` = khoản **cấp đơn**, không phải "chưa biết món nào". Xem
  /// `SettlementAllocation` về việc vì sao app không tự chia nó xuống món.
  final String? orderItemId;

  final SettlementKind kind;
  final SettlementDirection direction;

  /// **Luôn dương.** Xem doc của lớp.
  final double amount;

  /// Mã ISO.
  final String currency;

  final DateTime occurredAt;

  /// Ai trả. Bắt buộc — kể cả khi câu trả lời là [FundingSource.unknown].
  ///
  /// Không có mặc định: một mặc định ở đây là một lời khai app tự bịa ra thay
  /// cho sàn, và nó rơi đúng vào hướng làm lợi nhuận đẹp lên.
  final FundingSource fundedBy;

  /// Phần người bán chịu khi [fundedBy] là [FundingSource.shared], 0..1.
  ///
  /// `null` với `shared` ⇒ thực chất là chưa biết; xem [fundingIsKnown].
  final double? sellerShare;

  /// Lô đối soát đã trả khoản này. `null` = **chưa về tài khoản**.
  final String? payoutId;

  final Provenance provenance;

  /// Khoản này có đủ thông tin để tính vào lợi nhuận chưa.
  ///
  /// `shared` mà không có tỷ lệ thì **không** đủ — nó là `unknown` mặc áo khác.
  bool get fundingIsKnown => switch (fundedBy) {
    FundingSource.platform || FundingSource.seller => true,
    FundingSource.shared => sellerShare != null,
    FundingSource.unknown => false,
  };

  /// Phần **người bán thật sự chịu**, luôn dương.
  ///
  /// Ném [StateError] khi chưa biết ai trả — cố ý: trả về `0` ở đây là đúng
  /// cách một con số bịa lọt vào báo cáo. Chỗ gọi phải hỏi [fundingIsKnown]
  /// trước, và Rule Twin dùng nó để trả `insufficient` thay vì trả một số.
  double get sellerBorneAmount {
    if (!fundingIsKnown) {
      throw StateError(
        'chưa biết ai trả khoản $id (${kind.code}) — hỏi fundingIsKnown trước',
      );
    }
    return switch (fundedBy) {
      FundingSource.platform => 0,
      FundingSource.seller => amount,
      FundingSource.shared => amount * sellerShare!,
      FundingSource.unknown => 0, // không tới được: fundingIsKnown đã chặn
    };
  }

  /// Đóng góp có dấu vào lợi nhuận: chi là âm, thu là dương.
  ///
  /// Đây là **chỗ duy nhất** dấu được sinh ra, và nó sinh từ [direction] chứ
  /// không từ [amount].
  double get signedImpact => switch (direction) {
    SettlementDirection.inbound => sellerBorneAmount,
    SettlementDirection.outbound => -sellerBorneAmount,
  };

  @override
  bool operator ==(Object other) => other is SettlementLine && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SettlementLine(${kind.code} ${direction.code} $amount $currency)';
}

/// Một lô tiền thực về tài khoản người bán.
///
/// ## `reconciledDelta` là **tính năng**, không phải lỗi
///
/// Sàn thường có khoản chưa giải thích được — phí lẻ, làm tròn, khoản treo từ
/// kỳ trước. Một hệ thống ép cho khớp bằng cách bịa một dòng "điều chỉnh" là
/// hệ thống nói dối. Một hệ thống nói *"lệch 47.000 đ, chưa rõ vì sao"* là hệ
/// thống dùng được.
@immutable
class Payout {
  const Payout({
    required this.id,
    required this.connectionId,
    required this.amount,
    required this.currency,
    required this.settledAt,
    this.reconciledDelta,
    this.provenance = Provenance.manual,
  }) : assert(amount >= 0, 'amount luôn dương');

  final String id;
  final String connectionId;

  /// Số tiền sàn báo đã trả. **Luôn dương.**
  final double amount;

  final String currency;
  final DateTime settledAt;

  /// Chênh lệch **chưa giải thích được**, có dấu.
  ///
  /// `null` = **chưa đối soát**, không phải "khớp hoàn hảo". Hai điều đó khác
  /// nhau, và gộp chúng là cách một lô chưa ai kiểm trông như đã kiểm xong.
  final double? reconciledDelta;

  final Provenance provenance;

  /// Đã đối soát hay chưa — tách khỏi việc lệch bao nhiêu.
  bool get isReconciled => reconciledDelta != null;

  @override
  bool operator ==(Object other) => other is Payout && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Payout($id $amount $currency delta=${reconciledDelta ?? "chưa đối soát"})';
}
