import 'package:flutter/material.dart';

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
