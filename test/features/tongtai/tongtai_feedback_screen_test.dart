import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/feedback/feedback_delivery.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_feedback_screen.dart';

/// Records what the screen tried to send instead of opening a share sheet.
class _RecordingDelivery implements FeedbackDelivery {
  String? report;
  String? subject;
  int calls = 0;

  @override
  Future<void> send({required String report, required String subject}) async {
    calls++;
    this.report = report;
    this.subject = subject;
  }
}

class _FailingDelivery implements FeedbackDelivery {
  @override
  Future<void> send({required String report, required String subject}) async {
    throw StateError('no share target');
  }
}

/// WTM-175 — the in-app feedback channel. Shipping without it means shipping
/// without a way to hear from the sellers we ship to.
void main() {
  Widget host(String locale, FeedbackDelivery delivery) => MaterialApp(
    locale: Locale(locale),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('vi')],
    home: TongtaiFeedbackScreen(delivery: delivery),
  );

  for (final locale in ['vi', 'en']) {
    testWidgets('[$locale] refuses to send an empty message', (tester) async {
      final delivery = _RecordingDelivery();
      await tester.pumpWidget(host(locale, delivery));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('feedback-send')));
      await tester.pumpAndSettle();

      expect(
        delivery.calls,
        0,
        reason:
            'an empty report wastes the seller\'s send and tells us nothing',
      );
    });

    testWidgets('[$locale] sends what the seller typed', (tester) async {
      final delivery = _RecordingDelivery();
      await tester.pumpWidget(host(locale, delivery));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('feedback-input')),
        'Không lưu được đơn hàng',
      );
      await tester.tap(find.byKey(const Key('feedback-send')));
      await tester.pumpAndSettle();

      expect(delivery.calls, 1);
      expect(delivery.report, contains('Không lưu được đơn hàng'));
      expect(delivery.subject, isNotEmpty);
    });

    testWidgets('[$locale] shows the diagnostics before sending', (
      tester,
    ) async {
      // Privacy by Default is only real if the seller can see what leaves the
      // device *before* it leaves.
      await tester.pumpWidget(host(locale, _RecordingDelivery()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('feedback-disclosure')), findsOneWidget);
      expect(
        find.byKey(const Key('feedback-no-business-data')),
        findsOneWidget,
      );
    });
  }

  testWidgets('a failed share surfaces an error instead of pretending', (
    tester,
  ) async {
    await tester.pumpWidget(host('vi', _FailingDelivery()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('feedback-input')), 'thử');
    await tester.tap(find.byKey(const Key('feedback-send')));
    await tester.pumpAndSettle();

    // ADR-TON-017: a write that fails must not fail silently.
    expect(find.byKey(const Key('failure-snack')), findsOneWidget);
  });

  testWidgets('the send button re-enables after a failure', (tester) async {
    await tester.pumpWidget(host('vi', _FailingDelivery()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('feedback-input')), 'thử');
    await tester.tap(find.byKey(const Key('feedback-send')));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('feedback-send')),
    );
    expect(
      button.onPressed,
      isNotNull,
      reason: 'a permanently disabled button after one failure is a dead end',
    );
  });
}
