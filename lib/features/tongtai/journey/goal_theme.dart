import 'package:flutter/material.dart';

import '../../../core/design/tt.dart';
import '../navigation/tongtai_design_tokens.dart';
import 'business_goal.dart';

/// Color for a [GoalPace] badge. Pure function — unit-testable without a
/// widget, and shared by the goals list (WTM-87) and detail (WTM-88) screens
/// so they never drift apart.
Color tongtaiGoalPaceColor(GoalPace pace) => switch (pace) {
  GoalPace.ahead => TongtaiDesignTokens.success,
  GoalPace.onTrack => TongtaiDesignTokens.info,
  GoalPace.behind => TongtaiDesignTokens.error,
  GoalPace.completed => TongtaiDesignTokens.success,
  GoalPace.notStarted => TongtaiDesignTokens.neutral,
};

/// **Vai ngữ nghĩa** của một [GoalPace] — cùng thang với [tongtaiGoalPaceColor],
/// nhưng trả `TtStatus` để component không phải nhận `Color` thô (WTM-425).
///
/// ⭐ `notStarted` là **`neutral`, không phải `unknown`**: chưa bắt đầu thì ta
/// biết rất rõ, chỉ là không có gì để khen chê. Bảng token **cũ** đã ánh xạ nó
/// sang `TongtaiDesignTokens.neutral` từ lâu — tức vai trung tính vẫn tồn tại
/// trong sản phẩm suốt thời gian `TtStatus` thiếu nó, và đó chính là lý do bốn
/// chỗ khác phải mượn tạm `unknown`.
TtStatus tongtaiGoalPaceTone(GoalPace pace) => switch (pace) {
  GoalPace.ahead => TtStatus.success,
  GoalPace.onTrack => TtStatus.info,
  GoalPace.behind => TtStatus.danger,
  GoalPace.completed => TtStatus.success,
  GoalPace.notStarted => TtStatus.neutral,
};
