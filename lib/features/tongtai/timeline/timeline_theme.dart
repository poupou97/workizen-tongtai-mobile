import 'package:flutter/material.dart';

import '../navigation/tongtai_design_tokens.dart';
import 'business_event.dart';

/// Icon for a [BusinessEventType] on the timeline (WTM-114).
IconData businessEventIcon(BusinessEventType type) => switch (type) {
  BusinessEventType.order => Icons.receipt_long_outlined,
  BusinessEventType.finance => Icons.account_balance_wallet_outlined,
  BusinessEventType.inventory => Icons.inventory_2_outlined,
  BusinessEventType.customer => Icons.person_outline,
  BusinessEventType.opportunity => Icons.lightbulb_outline,
  BusinessEventType.recommendation => Icons.auto_awesome,
  BusinessEventType.journey => Icons.flag_outlined,
};

/// Accent color for a [BusinessEventType] — reuses the domain palette so the
/// timeline reads consistently with each module's screens.
Color businessEventColor(BusinessEventType type) => switch (type) {
  BusinessEventType.order => TongtaiDesignTokens.consumerBlue,
  BusinessEventType.finance => TongtaiDesignTokens.financePurple,
  BusinessEventType.inventory => TongtaiDesignTokens.inventoryOrange,
  BusinessEventType.customer => TongtaiDesignTokens.consumerBlue,
  BusinessEventType.opportunity => TongtaiDesignTokens.copilotViolet,
  BusinessEventType.recommendation => TongtaiDesignTokens.copilotViolet,
  BusinessEventType.journey => TongtaiDesignTokens.producerGreen,
};
