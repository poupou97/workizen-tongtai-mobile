import 'package:flutter/foundation.dart';

import '../consumer/external_identity.dart';
import 'proposed_change.dart';

/// Vì sao một đề xuất **không** được lưu — mã cố định, không phải câu tiếng
/// Việt (ADR-TON-007: chuỗi hiển thị đi qua `AppStrings`).
enum ProposalRejection {
  /// Bằng chứng quá yếu — không lưu gì cả.
  belowFloor('below_floor'),

  /// Người bán đã bỏ qua đúng giá trị này, và chưa tới lúc được hỏi lại.
  dismissedAndNotDue('dismissed_and_not_due'),

  /// Người bán đã tự điền trường này.
  humanOwns('human_owns'),

  /// Đúng giá trị này đã nằm trên bản ghi rồi.
  alreadyApplied('already_applied');

  const ProposalRejection(this.code);

  final String code;
}

/// Kết quả của bốn cổng.
@immutable
sealed class ProposalOutcome {
  const ProposalOutcome();
}

/// Được lưu, ở trạng thái nào.
@immutable
class ProposalAccepted extends ProposalOutcome {
  const ProposalAccepted(this.status);

  /// Luôn là [ProposalStatus.proposed] ở phase này.
  ///
  /// **Cố ý:** một đề xuất **không bao giờ** tự chuyển `applied`. Ngay cả khi
  /// bằng chứng rất mạnh, người bán vẫn là người bấm. Tự áp dụng là bước sang
  /// **L3 · Policy Automation**, và L3 cần `AutonomyRule` (WTM-300) chứ không
  /// phải một ngưỡng điểm.
  final ProposalStatus status;
}

/// Không lưu, và **nói rõ vì sao**.
@immutable
class ProposalRejected extends ProposalOutcome {
  const ProposalRejected(this.reason);

  final ProposalRejection reason;
}

/// Bốn cổng, theo thứ tự — **hàm thuần, không chạm cơ sở dữ liệu**.
///
/// ## Vì sao là hàm thuần
///
/// Cổng là **luật nghiệp vụ**, không phải chi tiết lưu trữ. Tách ra thì:
/// - test được không cần DB, không cần Flutter;
/// - repository mỏng, không quyết định gì;
/// - và quan trọng nhất: **chỉ có một chỗ** quyết định, nên không có đường
///   vòng nào bỏ qua cổng (xem `proposed_change_lifecycle_governance_test`).
///
/// Thứ tự bốn cổng học từ `lib/facts.ts` của COMP AI, nhưng cổng 2 khác: họ
/// cấm **vĩnh viễn**, ta cho xét lại theo miền (Founder chỉ đạo 2026-08-08).
class ProposalGate {
  const ProposalGate();

  /// Mức tối thiểu để **giữ lại** một đề xuất.
  ///
  /// Dưới mức này thì không lưu gì cả — không phải lưu rồi ẩn. Một đề xuất
  /// yếu nằm trong bảng là rác sẽ được ai đó nhìn thấy vào ngày xấu trời.
  static const IdentityConfidence keepFloor = IdentityConfidence.weak;

  /// Mức tối thiểu để **hiện cho người bán**.
  static const IdentityConfidence showFloor = IdentityConfidence.strong;

  /// [existingForField] là mọi đề xuất đã có cho **cùng subject + cùng field**.
  ///
  /// [humanOwns] do chỗ gọi trả lời — nó biết miền, cổng thì không. Đây là
  /// nguyên tắc 3 của Founder Directive: *human-owned truth thắng agent/web
  /// evidence*.
  ProposalOutcome evaluate({
    required ProposedChange proposal,
    required List<ProposedChange> existingForField,
    required bool humanOwns,
    required DateTime now,
  }) {
    // Cổng 1 — quá yếu thì không lưu gì.
    if (proposal.confidence.rank < keepFloor.rank) {
      return const ProposalRejected(ProposalRejection.belowFloor);
    }

    final sameValue = existingForField.where(
      (e) => _sameValue(e.proposedValue, proposal.proposedValue),
    );

    // Cổng 2 — đã bỏ qua đúng giá trị này.
    //
    // KHÁC COMP AI: họ cấm vĩnh viễn. Ở đây `canReconsiderAt` mở lại theo
    // MIỀN (hết hạn) hoặc theo BẰNG CHỨNG (mạnh hơn lần trước). Danh tính vẫn
    // vĩnh viễn — đó là chỗ luật của họ đúng.
    for (final dismissed in sameValue.where(
      (e) => e.status == ProposalStatus.dismissed,
    )) {
      if (!dismissed.canReconsiderAt(now, strongerEvidence: proposal.scored)) {
        return const ProposalRejected(ProposalRejection.dismissedAndNotDue);
      }
    }

    // Cổng 3 — người bán đã tự điền. Thắng mọi bằng chứng.
    if (humanOwns) {
      return const ProposalRejected(ProposalRejection.humanOwns);
    }

    // Cổng 4 — đúng giá trị này đã áp dụng rồi, không có gì đổi.
    if (sameValue.any((e) => e.status == ProposalStatus.applied)) {
      return const ProposalRejected(ProposalRejection.alreadyApplied);
    }

    return const ProposalAccepted(ProposalStatus.proposed);
  }

  /// Đề xuất này có nên **hiện** cho người bán không.
  ///
  /// Tách khỏi *"có lưu không"*: một đề xuất `weak` được giữ lại để về sau có
  /// thêm bằng chứng thì cộng vào, nhưng **không** làm phiền người bán hôm nay.
  bool shouldShow(ProposedChange proposal) =>
      proposal.status.isOpen && proposal.confidence.rank >= showFloor.rank;

  static bool _sameValue(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();
}
