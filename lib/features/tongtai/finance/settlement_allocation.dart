import 'package:flutter/foundation.dart';

import 'settlement.dart';

/// Chia một khoản **cấp đơn** xuống từng món — **chỉ để hiển thị**
/// (WTM-292 · N0.4 · ADR-TON-024 luật 2).
///
/// ## ⭐ Vì sao file này không có đường ghi nào
///
/// Phí vận chuyển gắn ở đơn; hoa hồng gắn ở món. Người bán vẫn muốn thấy
/// *"món này thật ra lãi bao nhiêu"*, nên phải chia phí đơn xuống món.
///
/// Nhưng phân bổ là một **luật dẫn xuất**. Chạy ngầm lúc ghi thì sẽ có hai
/// nguồn sự thật cho cùng một con số: dòng cấp đơn đã lưu, và các dòng cấp món
/// nó sinh ra. Đúng lỗi P-27/P-28 đã lặp **bốn lần** trong repo này — mỗi lần
/// một trường được vừa lưu vừa tính lại.
///
/// Nên luật *"cấm tự động phân bổ"* được cài bằng **hình dạng của module**:
/// đây là các **hàm thuần**, không import repository, không chạm cơ sở dữ liệu,
/// và trả về [AllocatedSettlement] — một **khung nhìn**, không phải
/// [SettlementLine] mới. Kết quả không có `id`, nên không có gì để lưu.
/// `settlement_no_derived_write_governance_test` canh đúng tính chất đó.
///
/// ## Vì sao kết quả cố tình KHÔNG phải SettlementLine
///
/// Nếu hàm này trả về `List<SettlementLine>`, thì bước tiếp theo tự nhiên nhất
/// của bất kỳ ai đọc code là đem chúng đi `upsertAll`. Trả về một kiểu khác —
/// không có `id`, không có `provenance` — làm việc đó không viết ra được.
@immutable
class AllocatedSettlement {
  const AllocatedSettlement({
    required this.orderItemId,
    required this.sourceLineId,
    required this.kind,
    required this.direction,
    required this.amount,
  });

  final String orderItemId;

  /// Dòng cấp đơn đã sinh ra khung nhìn này — để người bán truy ngược *"con số
  /// này từ đâu ra"*.
  final String sourceLineId;

  final SettlementKind kind;
  final SettlementDirection direction;

  /// Phần được chia cho món này. Luôn dương, như [SettlementLine.amount].
  final double amount;

  @override
  String toString() =>
      'AllocatedSettlement($orderItemId ← $sourceLineId: $amount)';
}

/// Trọng số để chia — doanh thu của từng món trong đơn.
///
/// Chia theo doanh thu chứ không chia đều: một đơn có một món 5 triệu và ba
/// món 50 nghìn thì chia đều là bịa. Chỗ gọi truyền vào vì Settlement không sở
/// hữu giá món — Orders sở hữu (một nguồn sự thật cho một con số).
typedef ItemRevenues = Map<String, double>;

/// Chia [line] cho các món theo tỷ trọng doanh thu.
///
/// Trả về danh sách **rỗng** khi:
/// - [line] đã gắn món rồi (`orderItemId != null`) — không có gì để chia;
/// - không có món nào, hoặc tổng doanh thu bằng 0 — chia cho 0 là bịa.
///
/// Rỗng ở đây nghĩa là *"không chia được"*, và chỗ gọi phải hiện khoản đó ở
/// **cấp đơn** thay vì rải một con số bịa xuống từng món.
List<AllocatedSettlement> allocateByRevenue(
  SettlementLine line,
  ItemRevenues itemRevenues,
) {
  if (line.orderItemId != null) return const [];
  if (itemRevenues.isEmpty) return const [];

  final total = itemRevenues.values.fold<double>(0, (a, b) => a + b);
  if (total <= 0) return const [];

  return [
    for (final entry in itemRevenues.entries)
      AllocatedSettlement(
        orderItemId: entry.key,
        sourceLineId: line.id,
        kind: line.kind,
        direction: line.direction,
        amount: line.amount * (entry.value / total),
      ),
  ];
}
