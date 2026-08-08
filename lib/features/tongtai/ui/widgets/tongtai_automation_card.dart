import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../agent/automation_card.dart';
import '../../navigation/tongtai_design_tokens.dart';

/// **Trải nghiệm #3 · Orchestration Card** — WTM-306.
///
/// Sáu nhãn `WHEN · IF · THINK · APPROVAL · DO · OBSERVE` giữ **nguyên tiếng
/// Anh**, có chủ ý: chúng là *cấu trúc*, không phải *nội dung*. Người bán đọc
/// nội dung ở cột phải — và cột phải luôn là tiếng Việt, luôn là chuyện của
/// chính doanh nghiệp họ.
///
/// Dịch sáu nhãn ra tiếng Việt sẽ biến chúng thành sáu câu nữa để đọc, và mất
/// đúng cái tác dụng của một khung: nhận ra hình dạng mà không phải đọc.
class TongtaiAutomationCard extends StatelessWidget {
  const TongtaiAutomationCard({
    super.key,
    required this.card,
    this.keyPrefix = 'automation',
  });

  final AutomationCard card;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      key: Key('$keyPrefix-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      decoration: BoxDecoration(
        color: TongtaiDesignTokens.lightHover,
        borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusXl),
        border: Border.all(color: TongtaiDesignTokens.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.automationTitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          for (final (label, text) in card.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 76,
                    child: Text(
                      label,
                      key: Key('$keyPrefix-${label.toLowerCase()}'),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        height: 1.5,
                        color: TongtaiDesignTokens.neutralText,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: TongtaiDesignTokens.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
