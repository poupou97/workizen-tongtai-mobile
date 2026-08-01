import 'dart:io' show Platform;

import '../export/backup_format.dart' show kTongtaiAppVersion;

/// Everything the app is allowed to attach to a feedback message.
///
/// The list is deliberately short and **closed**: app version, platform, OS
/// version, UI language. Nothing else. This class takes no repository, no
/// database and no [BusinessContext] — a feedback report physically cannot
/// carry business data, because the code that builds it has no way to reach
/// any (WTM-175).
///
/// That is the point. "Privacy by Default" is not a promise in a policy
/// screen; it is a shape the code has to have.
class FeedbackEnvironment {
  const FeedbackEnvironment({
    required this.appVersion,
    required this.platform,
    required this.osVersion,
    required this.locale,
  });

  /// Reads the real environment. [locale] comes from the caller because the UI
  /// language is a user choice, not a platform fact.
  factory FeedbackEnvironment.current({required String locale}) =>
      FeedbackEnvironment(
        appVersion: kTongtaiAppVersion,
        platform: Platform.operatingSystem,
        osVersion: Platform.operatingSystemVersion,
        locale: locale,
      );

  final String appVersion;
  final String platform;
  final String osVersion;
  final String locale;
}

/// Localized headings for the report, so the seller can **read what they are
/// about to send** before they send it.
///
/// Passed in rather than read from `AppStrings` so this file stays a pure
/// function with no Flutter dependency — it is the part that must be provable
/// by test.
class FeedbackReportLabels {
  const FeedbackReportLabels({
    required this.messageHeading,
    required this.diagnosticsHeading,
    required this.appVersionLabel,
    required this.platformLabel,
    required this.localeLabel,
  });

  final String messageHeading;
  final String diagnosticsHeading;
  final String appVersionLabel;
  final String platformLabel;
  final String localeLabel;
}

/// Builds the plain-text feedback report.
///
/// [message] is whatever the seller typed, verbatim. Everything after it is
/// the fixed diagnostic block from [environment].
String buildFeedbackReport({
  required String message,
  required FeedbackEnvironment environment,
  required FeedbackReportLabels labels,
}) {
  final buffer = StringBuffer()
    ..writeln(labels.messageHeading)
    ..writeln(message.trim())
    ..writeln()
    ..writeln(labels.diagnosticsHeading)
    ..writeln('${labels.appVersionLabel}: ${environment.appVersion}')
    ..writeln(
      '${labels.platformLabel}: ${environment.platform} ${environment.osVersion}',
    )
    ..writeln('${labels.localeLabel}: ${environment.locale}');
  return buffer.toString();
}
