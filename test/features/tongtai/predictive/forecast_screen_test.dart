import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/l10n/app_strings.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_key_store.dart';
import 'package:tongtai/features/tongtai/capability/revenue_capability.dart';
import 'package:tongtai/features/tongtai/core/tongtai_formatters.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/predictive/revenue_forecast_rule.dart';
import 'package:tongtai/features/tongtai/predictive/rule_twin.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_ai_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_capability_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_predictive_provider.dart';
import 'package:tongtai/features/tongtai/sample/historical_data_generator.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_forecast_screen.dart';

/// WTM-160 — the **Revenue Forecast screen**, through PRODUCTION wiring.
///
/// No screen-level mocks and no hand-built twin: the real
/// [revenueForecastProvider] runs the real [RevenueForecastRule] over the real
/// [RevenueCapabilityContext], itself built from the production
/// `orderRepositoryProvider` (an in-memory implementation of the same interface
/// Drift implements). What this suite locks:
///
/// - **Anti-fabrication** (ADR-TON-016, Testing Bible P-03): with no orders the
///   screen shows the refusal and *no headline at all* — asserted as an
///   ABSENCE, because a zero forecast is the failure mode that matters;
/// - **One data path** (ADR-TON-015): the rendered headline, band and basis are
///   the twin's own values, not a second computation that happens to be close;
/// - **Every month is visible**: one row per month in the analysis window,
///   empty months included — a gap the chart closes up is a month the seller
///   loses sight of;
/// - reason codes render as localized text, in both shipped locales.
///
/// The capability context reads `DateTime.now()` (production has no clock seam
/// on the Riverpod provider), so the fixture history is generated **relative to
/// today**: 12 months ending on the last complete month, which is exactly the
/// window the context analyses. Same seed ⇒ same business, any day it runs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();

  /// The last COMPLETE month — the capability window ends here (the running
  /// month is excluded as partial), so a history generated up to it lines up
  /// month-for-month with the window the rule analyses.
  final lastCompleteMonth = DateTime(now.year, now.month - 1);

  final history = const HistoricalDataGenerator().generate(
    HistoricalDataSpec(
      months: kRevenueCapabilityWindowMonths,
      seed: 20260730,
      growth: GrowthPattern.moderateGrowth,
      seasonality: SeasonalityPattern.vietnamRetail,
      endMonth: lastCompleteMonth,
    ),
  );

  /// The production graph over an in-memory order book.
  ///
  /// The BYOK key store is in-memory and **empty**: no platform channel, no
  /// network, and the AI path therefore takes its no-key branch — which is the
  /// branch that must still answer.
  Widget host(List<CustomerOrder> orders, {String locale = 'en'}) =>
      ProviderScope(
        overrides: [
          orderRepositoryProvider.overrideWithValue(
            InMemoryOrderRepository(orders),
          ),
          tongtaiAiKeyStoreProvider.overrideWithValue(
            InMemoryTongtaiAiKeyStore(),
          ),
        ],
        child: MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('vi')],
          home: const TongtaiForecastScreen(),
        ),
      );

  Future<void> pump(WidgetTester tester, Widget app) async {
    // Tall surface so the whole page is laid out — the contract is about what
    // the seller can see, and an unbuilt section would make a count check pass
    // for the wrong reason.
    tester.view.physicalSize = const Size(400 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  /// Every rendered month row, found by its stable `forecast-item-<y>-<m>` key.
  Finder monthRows() => find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith('forecast-item-');
  });

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(
        tester.element(find.byType(TongtaiForecastScreen)),
      );

  Future<RuleTwinResult<RevenueForecast>> twinOf(WidgetTester tester) =>
      containerOf(tester).read(revenueForecastProvider.future);

  Future<RevenueCapabilityContext> contextOf(WidgetTester tester) =>
      containerOf(tester).read(revenueCapabilityProvider.future);

  testWidgets('no orders → the honest refusal, and NO headline at all', (
    tester,
  ) async {
    await pump(tester, host(const []));

    // The twin really did refuse — the screen is rendering a refusal, not
    // failing to find data it should have had.
    final twin = await twinOf(tester);
    expect(twin.sufficiency, DataSufficiency.insufficient);
    expect(twin.result, isNull);
    expect(twin.confidence, ForecastConfidence.none);

    expect(find.byKey(const Key('forecast-insufficient')), findsOneWidget);
    expect(
      find.text(const AppStringsEn().forecastInsufficient),
      findsOneWidget,
    );
    expect(
      find.text(const AppStringsEn().forecastInsufficientBody),
      findsOneWidget,
    );

    // ── The anti-fabrication guarantee, asserted as an ABSENCE ────────────
    // A zero headline, an empty band or a chart of zero bars would all read as
    // "you will earn nothing next month", which is NOT what the rule said.
    expect(find.byKey(const Key('forecast-headline')), findsNothing);
    expect(find.byKey(const Key('forecast-range')), findsNothing);
    expect(find.byKey(const Key('forecast-confidence')), findsNothing);
    expect(find.byKey(const Key('forecast-history')), findsNothing);
    expect(find.byKey(const Key('forecast-comparison')), findsNothing);
    expect(monthRows(), findsNothing);
    expect(find.text(TongtaiFormatters.vnd(0)), findsNothing);

    // Nothing for AI to explain, so the action is not offered (ADR-TON-016 —
    // AI may never be the only "forecast" on screen).
    expect(find.byKey(const Key('forecast-action-ai')), findsNothing);

    // The user is told WHY, in their language.
    for (final code in twin.reasonCodes) {
      expect(
        find.text(code.label('en')),
        findsOneWidget,
        reason: 'refusal must quote ${code.code}',
      );
    }
    expect(twin.reasonCodes, contains(ReasonCode.noRevenueYet));
    expect(twin.reasonCodes, contains(ReasonCode.notEnoughHistory));
  });

  testWidgets('12 months of history → a forecast, and EVERY month as a row', (
    tester,
  ) async {
    await pump(tester, host(history.orders));

    final twin = await twinOf(tester);
    final context = await contextOf(tester);
    expect(
      twin.result,
      isNotNull,
      reason: 'a full year of generated history must be forecastable',
    );
    expect(context.series.length, kRevenueCapabilityWindowMonths);

    expect(find.byKey(const Key('forecast-headline')), findsOneWidget);
    expect(find.byKey(const Key('forecast-range')), findsOneWidget);
    expect(find.byKey(const Key('forecast-confidence')), findsOneWidget);
    expect(find.byKey(const Key('forecast-history')), findsOneWidget);
    expect(find.byKey(const Key('forecast-comparison')), findsOneWidget);
    expect(find.byKey(const Key('forecast-why')), findsOneWidget);
    expect(find.byKey(const Key('forecast-insufficient')), findsNothing);

    // Summary window == visible records: one row per month IN THE WINDOW,
    // empty months included (a skipped month is a month the seller cannot see).
    expect(monthRows(), findsNWidgets(context.series.length));
    for (final point in context.series.points) {
      expect(
        find.byKey(Key('forecast-item-${point.year}-${point.month}')),
        findsOneWidget,
        reason: 'no row for ${point.key}',
      );
    }

    // The confidence chip quotes the twin's own band, and the provenance chip
    // says the number is arithmetic — no AI, no key, no network.
    expect(
      find.descendant(
        of: find.byKey(const Key('forecast-confidence')),
        matching: find.textContaining(twin.confidence.label('en')),
      ),
      findsOneWidget,
    );
    expect(twin.confidence, isNot(ForecastConfidence.none));
    expect(find.text(const AppStringsEn().forecastRuleBased), findsOneWidget);

    // The twin answered, so AI has something to explain and the action shows.
    expect(find.byKey(const Key('forecast-action-ai')), findsOneWidget);
    expect(find.text(const AppStringsEn().aiExplain), findsOneWidget);
  });

  testWidgets('the rendered headline IS the twin number — no second '
      'computation, no friendlier rounding', (tester) async {
    await pump(tester, host(history.orders));

    final twin = await twinOf(tester);
    final forecast = twin.result!;

    expect(
      find.descendant(
        of: find.byKey(const Key('forecast-headline')),
        matching: find.text(TongtaiFormatters.vnd(forecast.nextMonthRevenue)),
      ),
      findsOneWidget,
      reason:
          'the headline must be the rule twin\'s own number, formatted — '
          'anything else means the screen re-derived it',
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('forecast-range')),
        matching: find.text(
          '${TongtaiFormatters.vnd(forecast.lowerBound)} – '
          '${TongtaiFormatters.vnd(forecast.upperBound)}',
        ),
      ),
      findsOneWidget,
      reason: 'the band must be the twin\'s own bounds',
    );

    // The basis is the twin's, not "the whole window": the rule drops leading
    // months before the first sale, and the screen must say what it used.
    expect(forecast.basis, isNotEmpty);
    for (final point in forecast.basis) {
      expect(
        find.descendant(
          of: find.byKey(const Key('forecast-why')),
          matching: find.text('${point.month}/${point.year}'),
        ),
        findsOneWidget,
        reason: 'basis month ${point.key} must be listed under forecastBasis',
      );
    }
    expect(find.text(const AppStringsEn().forecastBasis), findsOneWidget);

    // A neighbouring value is NOT on screen — proves the assertion above is
    // pinned to the exact double, not to any plausible-looking figure.
    expect(
      find.text(TongtaiFormatters.vnd(forecast.nextMonthRevenue + 1000)),
      findsNothing,
    );
  });

  testWidgets('the AI action EXPLAINS the twin — it never replaces the '
      'number, and with no BYOK key it still answers', (tester) async {
    await pump(tester, host(history.orders));
    final twin = await twinOf(tester);
    final headline = TongtaiFormatters.vnd(twin.result!.nextMonthRevenue);

    // Nothing before the seller asks: the explanation is on demand, so an idle
    // screen costs no provider call and no BYOK quota.
    expect(find.byKey(const Key('forecast-ai-answer')), findsNothing);

    await tester.tap(find.byKey(const Key('forecast-action-ai')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('forecast-ai-answer')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('forecast-ai-text'))).data,
      isNotEmpty,
      reason:
          'the no-key path must fall back to the twin explanation, not '
          'leave the seller with an empty card',
    );
    // Provenance: no key is set, so the deterministic explanation answered —
    // and it says so rather than passing itself off as AI.
    expect(
      tester.widget<Text>(find.byKey(const Key('forecast-ai-source'))).data,
      const AppStringsEn().forecastRuleBased,
    );

    // The ADR-TON-016 invariant: after the explanation, the headline is STILL
    // the twin's number. AI explains; it never replaces the figure.
    expect(
      find.descendant(
        of: find.byKey(const Key('forecast-headline')),
        matching: find.text(headline),
      ),
      findsOneWidget,
    );
  });

  testWidgets('reason codes render as localized text — both locales', (
    tester,
  ) async {
    await pump(tester, host(history.orders));
    final twin = await twinOf(tester);
    expect(twin.reasonCodes, isNotEmpty);
    // The verdict the rule actually reached is among the codes it reports.
    expect(twin.reasonCodes, contains(twin.result!.direction.reasonCode));

    for (final code in twin.reasonCodes) {
      expect(
        find.descendant(
          of: find.byKey(const Key('forecast-why')),
          matching: find.text(code.label('en')),
        ),
        findsOneWidget,
        reason:
            'the screen must quote the SAME code the rule emitted: '
            '${code.code}',
      );
      // …and the English wording only — a mixed-language screen is a P0 §2
      // violation.
      expect(find.text(code.labelVi), findsNothing);
    }

    // Vietnamese renders the other wording from the same codes: the screen
    // never hard-wires a language (ADR-TON-007).
    await pump(tester, host(history.orders, locale: 'vi'));
    final viTwin = await twinOf(tester);
    for (final code in viTwin.reasonCodes) {
      expect(
        find.descendant(
          of: find.byKey(const Key('forecast-why')),
          matching: find.text(code.label('vi')),
        ),
        findsOneWidget,
        reason: 'VI wording for ${code.code}',
      );
      expect(find.text(code.labelEn), findsNothing);
    }
  });
}
