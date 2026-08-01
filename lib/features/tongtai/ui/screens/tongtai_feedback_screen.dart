import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../core/screen_data_controller.dart';
import '../../feedback/feedback_delivery.dart';
import '../../feedback/feedback_report.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../widgets/tongtai_screen_data.dart' show showTongtaiFailure;

/// "Send feedback" (WTM-175 · Release Readiness).
///
/// The row existed in Settings marked *coming soon*. Shipping without it means
/// shipping without a way to hear from the sellers we ship to — the Product
/// Reset called that "phát hành mà không nghe được người dùng là đi mù".
///
/// **No backend, no account** (D-4, D-5), so there is nothing to POST to. The
/// report goes out through the OS share sheet: the seller picks Zalo, email or
/// whatever they already use, and *they* press send.
///
/// The screen shows the exact diagnostic block before it is sent. That is not
/// decoration — a privacy promise the user cannot inspect is just a claim.
class TongtaiFeedbackScreen extends StatefulWidget {
  const TongtaiFeedbackScreen({super.key, this.delivery});

  /// Injected in tests so no real share sheet ever opens.
  final FeedbackDelivery? delivery;

  @override
  State<TongtaiFeedbackScreen> createState() => _TongtaiFeedbackScreenState();
}

class _TongtaiFeedbackScreenState extends State<TongtaiFeedbackScreen> {
  final TextEditingController _message = TextEditingController();
  bool _sending = false;
  bool _showEmptyError = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  FeedbackEnvironment _environment(String locale) =>
      FeedbackEnvironment.current(locale: locale);

  Future<void> _send() async {
    final l10n = context.l10n;
    if (_message.text.trim().isEmpty) {
      setState(() => _showEmptyError = true);
      return;
    }
    setState(() {
      _showEmptyError = false;
      _sending = true;
    });
    final report = buildFeedbackReport(
      message: _message.text,
      environment: _environment(l10n.languageCode),
      labels: _labels(l10n),
    );
    final delivery = widget.delivery ?? const ShareSheetFeedbackDelivery();
    final failure = await runTongtaiAction(
      () => delivery.send(report: report, subject: l10n.feedbackSubject),
      screen: 'feedback',
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (failure != null) {
      showTongtaiFailure(context, failure, onRetry: _send);
    }
  }

  static FeedbackReportLabels _labels(AppStrings l10n) => FeedbackReportLabels(
    messageHeading: l10n.feedbackMessageHeading,
    diagnosticsHeading: l10n.feedbackDiagnosticsHeading,
    appVersionLabel: l10n.feedbackAppVersionLabel,
    platformLabel: l10n.feedbackPlatformLabel,
    localeLabel: l10n.feedbackLocaleLabel,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final environment = _environment(l10n.languageCode);
    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(title: Text(l10n.moreSendFeedback)),
      body: SafeArea(
        child: ListView(
          key: const Key('feedback-list'),
          padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
          children: [
            Text(
              l10n.feedbackIntro,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing4),
            TextField(
              key: const Key('feedback-input'),
              controller: _message,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.feedbackHint,
                border: const OutlineInputBorder(),
                errorText: _showEmptyError ? l10n.feedbackEmpty : null,
              ),
            ),
            const SizedBox(height: TongtaiDesignTokens.spacing5),
            _WhatIsSent(environment: environment),
            const SizedBox(height: TongtaiDesignTokens.spacing6),
            SizedBox(
              height: TongtaiDesignTokens.buttonHeight,
              child: FilledButton.icon(
                key: const Key('feedback-send'),
                onPressed: _sending ? null : _send,
                icon: const Icon(Icons.ios_share),
                label: Text(l10n.feedbackSend),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the diagnostic block verbatim, plus the one line that matters most:
/// no business data is attached.
class _WhatIsSent extends StatelessWidget {
  const _WhatIsSent({required this.environment});

  final FeedbackEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      key: const Key('feedback-disclosure'),
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
      decoration: BoxDecoration(
        border: Border.all(color: TongtaiDesignTokens.lightBorder),
        borderRadius: BorderRadius.circular(TongtaiDesignTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.feedbackWhatIsSent,
            style: TongtaiDesignTokens.bodyStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: TongtaiDesignTokens.spacing2),
          _Line('${l10n.feedbackAppVersionLabel}: ${environment.appVersion}'),
          _Line(
            '${l10n.feedbackPlatformLabel}: ${environment.platform} '
            '${environment.osVersion}',
          ),
          _Line('${l10n.feedbackLocaleLabel}: ${environment.locale}'),
          const SizedBox(height: TongtaiDesignTokens.spacing3),
          Text(
            l10n.feedbackNoBusinessData,
            key: const Key('feedback-no-business-data'),
            style: TongtaiDesignTokens.captionStyle.copyWith(
              color: TongtaiDesignTokens.producerGreenText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: TongtaiDesignTokens.spacing1),
      child: Text(
        text,
        style: TongtaiDesignTokens.captionStyle.copyWith(
          color: TongtaiDesignTokens.lightTextSecondary,
        ),
      ),
    );
  }
}
