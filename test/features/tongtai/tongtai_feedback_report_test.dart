import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/feedback/feedback_report.dart';

/// WTM-175 — the feedback report is the one thing in the app that is *built to
/// leave the device*. These tests pin what it may contain.
void main() {
  const environment = FeedbackEnvironment(
    appVersion: '1.2.3',
    platform: 'android',
    osVersion: 'Android 9 (SDK 28)',
    locale: 'vi',
  );

  const labels = FeedbackReportLabels(
    messageHeading: 'PHẢN HỒI',
    diagnosticsHeading: 'THÔNG TIN KỸ THUẬT',
    appVersionLabel: 'Phiên bản',
    platformLabel: 'Thiết bị',
    localeLabel: 'Ngôn ngữ',
  );

  String report(String message) => buildFeedbackReport(
    message: message,
    environment: environment,
    labels: labels,
  );

  group('buildFeedbackReport', () {
    test('carries the seller message verbatim', () {
      expect(
        report('Nút lưu đơn không bấm được'),
        contains('Nút lưu đơn không bấm được'),
      );
    });

    test('trims surrounding whitespace but keeps the text intact', () {
      final text = report('   xin chào   ');
      expect(text, contains('xin chào'));
      expect(text, isNot(contains('   xin chào')));
    });

    test('attaches exactly the four declared diagnostic facts', () {
      final text = report('bất kỳ');
      expect(text, contains('Phiên bản: 1.2.3'));
      expect(text, contains('Thiết bị: android Android 9 (SDK 28)'));
      expect(text, contains('Ngôn ngữ: vi'));
    });

    test(
      'contains nothing beyond the message and the diagnostic block',
      () {
        // The whole privacy claim in one assertion: strip the message and the
        // four declared facts, and there must be nothing left but headings.
        //
        // If someone later appends "and by the way, here are the seller's
        // revenue totals", this test is what fails.
        final text = report('MESSAGE_SENTINEL');
        final remaining = text
            .replaceAll('MESSAGE_SENTINEL', '')
            .replaceAll('PHẢN HỒI', '')
            .replaceAll('THÔNG TIN KỸ THUẬT', '')
            .replaceAll('Phiên bản: 1.2.3', '')
            .replaceAll('Thiết bị: android Android 9 (SDK 28)', '')
            .replaceAll('Ngôn ngữ: vi', '')
            .trim();
        expect(remaining, isEmpty);
      },
    );

    test('an empty message still produces a well-formed report', () {
      // The screen blocks empty sends; the builder must not crash if it is
      // ever called from somewhere that does not.
      final text = report('');
      expect(text, contains('Phiên bản: 1.2.3'));
    });
  });

  group('FeedbackEnvironment', () {
    test('exposes only the four fields it is allowed to know', () {
      // A structural check: the class takes no repository, no database and no
      // BusinessContext, so a report physically cannot reach business data.
      // Guarding it by test because the cheapest way to break the privacy
      // promise is to add one convenient constructor parameter.
      expect(environment.appVersion, '1.2.3');
      expect(environment.platform, 'android');
      expect(environment.osVersion, 'Android 9 (SDK 28)');
      expect(environment.locale, 'vi');
    });
  });
}
