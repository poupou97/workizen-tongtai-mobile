import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/l10n/app_strings.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_key_store.dart';
import 'package:tongtai/features/tongtai/capability/revenue_capability.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_ai_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/sample/historical_data_generator.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_risk_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_forecast_screen.dart';

/// WTM-280 — the **estimate disclaimer**, and where it is allowed to live.
///
/// The app publishes four kinds of judgement: a revenue forecast, a customer
/// risk ranking, a weekly plan and health scoring. Until this story, none of
/// them said anywhere that the number is an estimate. The risk is not a store
/// rejection — it is a seller reading *"next month: 20,769,724 ₫"*, buying
/// stock against it, and losing money.
///
/// What this suite locks is not "a string exists somewhere". It is the
/// **placement rule**, which is the part that decays silently:
///
/// * the line sits **inside the card that carries the number**, so it is read
///   at the moment the number is read — a page of terms nobody opens is not a
///   disclaimer, it is paperwork;
/// * when the twin **refuses** (insufficient data) there is no number, so there
///   must be **no disclaimer either** — asserted as an ABSENCE. A disclaimer on
///   an empty screen is noise, and noise is what teaches people to stop reading
///   the line when it finally matters.
///
/// Both properties are asserted **by Key**, never by displayed text: repo
/// convention, and the wording of a legal-adjacent sentence is exactly the kind
/// of thing that gets reworded.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();
  final lastCompleteMonth = DateTime(now.year, now.month - 1);

  /// A real trading history so the twin can actually answer — the disclaimer
  /// only has meaning next to a number the rule was willing to produce.
  final history = const HistoricalDataGenerator().generate(
    HistoricalDataSpec(
      months: kRevenueCapabilityWindowMonths,
      seed: 20260805,
      growth: GrowthPattern.moderateGrowth,
      seasonality: SeasonalityPattern.vietnamRetail,
      endMonth: lastCompleteMonth,
    ),
  );

  Widget host(
    Widget screen, {
    List<CustomerOrder> orders = const [],
  }) => ProviderScope(
    overrides: [
      orderRepositoryProvider.overrideWithValue(
        InMemoryOrderRepository(orders),
      ),
      customerRepositoryProvider.overrideWithValue(
        InMemoryCustomerRepository(history.customers),
      ),
      // Empty key store → the AI path takes its no-key branch. Nothing in
      // this suite may depend on a network call.
      tongtaiAiKeyStoreProvider.overrideWithValue(InMemoryTongtaiAiKeyStore()),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('vi')],
      home: screen,
    ),
  );

  Future<void> pump(WidgetTester tester, Widget app) async {
    // Tall surface: the disclaimer sits at the bottom of its card, and an
    // unbuilt section would make an absence check pass for the wrong reason.
    tester.view.physicalSize = const Size(400 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  group('forecast screen', () {
    testWidgets('a produced forecast carries the disclaimer in its card', (
      tester,
    ) async {
      await pump(
        tester,
        host(const TongtaiForecastScreen(), orders: history.orders),
      );

      // Precondition: there really is a number on screen. Without this the
      // disclaimer assertion below could pass on an empty screen.
      expect(find.byKey(const Key('forecast-headline')), findsOneWidget);

      final disclaimer = find.byKey(const Key('forecast-estimate-disclaimer'));
      expect(disclaimer, findsOneWidget);

      // Placement, not mere presence: the line must be INSIDE the headline
      // card. Anywhere else and it stops being read together with the number.
      expect(
        find.descendant(
          of: find.byKey(const Key('forecast-headline')),
          matching: disclaimer,
        ),
        findsOneWidget,
      );
    });

    testWidgets('no data → no number, and therefore NO disclaimer', (
      tester,
    ) async {
      await pump(tester, host(const TongtaiForecastScreen()));

      // The twin refused: this is the insufficient state, not a load failure.
      expect(find.byKey(const Key('forecast-insufficient')), findsOneWidget);
      expect(find.byKey(const Key('forecast-headline')), findsNothing);

      // The disclaimer travels with the number. No number ⇒ nothing to qualify.
      expect(
        find.byKey(const Key('forecast-estimate-disclaimer')),
        findsNothing,
      );
    });
  });

  group('customer risk screen', () {
    testWidgets('a produced ranking carries the disclaimer', (tester) async {
      await pump(
        tester,
        host(const TongtaiCustomerRiskScreen(), orders: history.orders),
      );

      // Precondition: the twin answered — the provenance chip only renders
      // alongside a real assessment.
      expect(find.byKey(const Key('risk-confidence')), findsOneWidget);
      expect(find.byKey(const Key('risk-estimate-disclaimer')), findsOneWidget);
    });

    testWidgets('empty book → no ranking, and therefore NO disclaimer', (
      tester,
    ) async {
      await pump(
        tester,
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(
              InMemoryOrderRepository(const []),
            ),
            customerRepositoryProvider.overrideWithValue(
              InMemoryCustomerRepository(const []),
            ),
            tongtaiAiKeyStoreProvider.overrideWithValue(
              InMemoryTongtaiAiKeyStore(),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('en'), Locale('vi')],
            home: TongtaiCustomerRiskScreen(),
          ),
        ),
      );

      expect(find.byKey(const Key('risk-estimate-disclaimer')), findsNothing);
    });
  });

  group('wording', () {
    // The sentence is legal-adjacent, so it is easy to "improve" it into
    // something untrue. Both shipped locales must keep two commitments:
    // say it is an estimate, and leave the decision with the seller.
    for (final strings in <AppStrings>[
      const AppStringsVi(),
      const AppStringsEn(),
    ]) {
      test(
        '${strings.languageCode}: admits estimate and defers the decision',
        () {
          final text = strings.estimateDisclaimer.toLowerCase();

          expect(
            text.contains('ước tính') || text.contains('estimate'),
            isTrue,
            reason: 'the line must say the figure is an estimate',
          );
          expect(
            text.contains('của bạn') || text.contains('yours'),
            isTrue,
            reason: 'the decision must be left with the seller',
          );

          // ADR-TON-016: the number comes from arithmetic over the seller's own
          // data (Rule Twin). Claiming the AI produced it would be false, and
          // would also undercut the offline guarantee the twin exists to give.
          expect(
            text.contains(' ai '),
            isFalse,
            reason: 'must not imply the AI computed the figure',
          );
        },
      );
    }
  });
}
