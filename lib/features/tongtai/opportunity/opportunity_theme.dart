import 'package:flutter/material.dart';

import '../core/tongtai_enums.dart';
import '../navigation/tongtai_design_tokens.dart';
import 'opportunity_signals.dart';

/// Color for an [OpportunityType] chip/badge. Pure function — unit-testable
/// without a widget, and shared by the feed (WTM-91) and detail (WTM-92)
/// screens so they never drift apart.
Color tongtaiOpportunityTypeColor(OpportunityType type) => switch (type) {
  OpportunityType.arbitrage => TongtaiDesignTokens.inventoryOrange,
  OpportunityType.seasonal => TongtaiDesignTokens.producerGreen,
  OpportunityType.crossBorder => TongtaiDesignTokens.consumerBlue,
  OpportunityType.trend => TongtaiDesignTokens.financePurple,
};

/// Color for a rule-based [OpportunitySignal] badge (WTM-130). Semantic colors —
/// value = success, risk = error, urgent = warning, stale = neutral.
Color tongtaiOpportunitySignalColor(OpportunitySignal signal) =>
    switch (signal) {
      OpportunitySignal.highValue => TongtaiDesignTokens.success,
      OpportunitySignal.highRisk => TongtaiDesignTokens.error,
      OpportunitySignal.urgent => TongtaiDesignTokens.warning,
      OpportunitySignal.stale => TongtaiDesignTokens.neutral,
    };
