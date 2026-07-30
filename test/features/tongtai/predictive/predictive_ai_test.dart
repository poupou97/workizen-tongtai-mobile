import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/ai/ai_runtime_boundary.dart';
import 'package:tongtai/features/tongtai/ai/business_summary.dart'
    show BusinessSummarySource;
import 'package:tongtai/features/tongtai/ai/predictive_ai.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_client.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_errors.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_key_store.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_models.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_provider_kind.dart';
import 'package:tongtai/features/tongtai/ai/tongtai_ai_service.dart';
import 'package:tongtai/features/tongtai/analytics/month_bucket.dart';
import 'package:tongtai/features/tongtai/analytics/revenue_series.dart';
import 'package:tongtai/features/tongtai/capability/capability_context.dart';
import 'package:tongtai/features/tongtai/capability/customer_capability.dart';
import 'package:tongtai/features/tongtai/capability/revenue_capability.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/core/tongtai_formatters.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_context.dart';
import 'package:tongtai/features/tongtai/predictive/business_alerts_rule.dart';
import 'package:tongtai/features/tongtai/predictive/customer_risk_rule.dart';
import 'package:tongtai/features/tongtai/predictive/revenue_forecast_rule.dart';
import 'package:tongtai/features/tongtai/predictive/rule_twin.dart';

/// WTM-158 / WTM-159 — the **AI Explanation layer** and the **AI Runtime
/// Boundary** of the Predictive Foundation (ADR-TON-016 Decisions 4 & 5).
///
/// The four things proven here are the four the ADR actually cares about:
///
/// 1. **Zero provider spend** when there is nothing to explain — no key, or a
///    twin that refused to answer (`sufficiency == insufficient`).
/// 2. **The twin owns the numbers.** A hostile provider answer is passed through
///    as prose, but `ruleVersion` and `reasonCodes` come from the twin and the
///    figure a screen renders is still the twin's — the service never parses a
///    number out of model text.
/// 3. **No PII leaves the device.** The customer-risk prompt carries ids, counts
///    and bands only; the fixture's name/phone/email must be absent verbatim.
/// 4. **No tool runtime is wired.** Nothing under `lib/` references
///    `AiToolRuntime` except the boundary file that defines it, and the only
///    shipped implementation throws.
void main() {
  // July 2026 is the running month: a 12-month window is Jul 2025 … Jun 2026
  // and the forecast target is Jul 2026.
  final now = DateTime(2026, 7, 15, 9, 30);
  DateTime clock() => now;

  // ── Hostile PII fixture ───────────────────────────────────────────────────
  //
  // Every customer carries the SAME real-looking name/phone/email. If a single
  // one of those strings ever reaches a prompt, the privacy test fails loudly
  // (D-7 / ADR-TON-005 red line).
  const fixtureName = 'Nguyễn Thị Mai';
  const fixturePhone = '+84912345678';
  const fixtureEmail = 'mai@example.com';
  const fixtureLocation = 'Hà Nội';

  Customer customer(String id) => Customer(
    id: id,
    name: fixtureName,
    phone: fixturePhone,
    location: fixtureLocation,
    orderCount: 0,
    totalSpent: 0,
    lastPurchaseDate: null,
    email: fixtureEmail,
  );

  var nextOrderId = 0;
  CustomerOrder order(String customerId, DateTime date, double total) {
    nextOrderId += 1;
    return CustomerOrder(
      id: 'o$nextOrderId',
      customerId: customerId,
      orderNumber: 'DH-$nextOrderId',
      date: date,
      status: OrderStatus.delivered,
      items: [
        OrderItem(
          productName: 'Khăn lụa',
          category: 'Fashion',
          quantity: 1,
          unitPrice: total,
        ),
      ],
    );
  }

  /// A revenue context built straight from monthly revenues (oldest → newest) —
  /// the twin's contract is over the context, and the orders → context step is
  /// already covered by `revenue_capability_test.dart`.
  RevenueCapabilityContext revenueContext(List<double> revenues) {
    const start = MonthKey(2025, 7);
    final points = <MonthlyRevenuePoint>[
      for (var i = 0; i < revenues.length; i++)
        MonthlyRevenuePoint(
          year: start.addMonths(i).year,
          month: start.addMonths(i).month,
          revenue: revenues[i],
          orderCount: revenues[i] > 0 ? 1 : 0,
          customerCount: revenues[i] > 0 ? 1 : 0,
        ),
    ];
    final earning = points.where((p) => p.orderCount > 0).length;
    return RevenueCapabilityContext(
      generatedAt: now,
      series: RevenueSeries(
        points: List.unmodifiable(points),
        currentMonthExcluded: true,
      ),
      orderHistory: OrderSummary(
        total: earning,
        byStatus: {OrderStatus.delivered: earning},
      ),
      windowMonths: revenues.isEmpty ? 12 : revenues.length,
      comparisonMonths: 3,
    );
  }

  /// A steady +100k/month ramp over a full year — `sufficient`, `high`
  /// confidence, `revenueGrowing`, and no seasonal factor (the whole-window
  /// drift guard refuses a 12-point index on a trending business).
  final growingRevenue = revenueContext(
    List.generate(12, (i) => 1000000 + i * 100000),
  );

  /// Two months of history — below the rule's three-month minimum, so the twin
  /// refuses: `insufficient`, `result == null`.
  final thinRevenue = revenueContext(const [1000000, 1200000]);

  /// Two customers: one churned whale (silent since January), one active.
  CustomerCapabilityContext customerContext() {
    nextOrderId = 0;
    return CustomerCapabilityContext.from(
      customers: [customer('cust-lapsed'), customer('cust-active')],
      orders: [
        order('cust-lapsed', DateTime(2026, 1, 10), 8000000),
        order('cust-active', DateTime(2026, 7, 1), 400000),
      ],
      now: now,
    );
  }

  /// An empty directory — the customer twin's refusal case.
  final emptyCustomers = CustomerCapabilityContext.from(
    customers: const [],
    orders: const [],
    now: now,
  );

  const forecastRule = RevenueForecastRule();
  const riskRule = CustomerRiskRule();
  const alertsRule = BusinessAlertsRule();

  // ── AI spy ────────────────────────────────────────────────────────────────
  //
  // Records every provider call so a test can assert on the ABSENCE of one —
  // "no key means no spend" is only proven by counting.

  /// One recorded provider call.
  final calls = <({TongtaiAiProviderKind provider, String prompt})>[];

  /// Builds a [PredictiveAiService] over a fake provider chain.
  ///
  /// [keys] are the providers the user has enabled; [reply] is what a provider
  /// answers, or `null` to make every provider fail (chain-failure path).
  PredictiveAiService service({
    List<TongtaiAiProviderKind> keys = const [],
    String? reply,
    List<TongtaiAiProviderKind> preference = const [TongtaiAiProviderKind.xai],
  }) {
    final store = InMemoryTongtaiAiKeyStore();
    for (final provider in keys) {
      store.write(provider, 'xai-test-key');
    }
    return PredictiveAiService(
      TongtaiAiService(
        store,
        clientFactory: (provider, _) =>
            _SpyClient(provider, calls, reply: reply),
      ),
      preference: preference,
      clock: clock,
    );
  }

  setUp(calls.clear);

  // ── 1 · no key → the deterministic twin explanation, zero spend ───────────
  group('no BYOK key → rule-based explanation', () {
    test('forecast: source is rule, quotes the twin codes, no call', () async {
      final twin = forecastRule.forecast(growingRevenue);
      expect(twin.sufficiency, DataSufficiency.sufficient);

      final explanation = await service().explainForecast(
        context: growingRevenue,
        forecast: twin,
      );

      expect(explanation.source, BusinessSummarySource.rule);
      expect(explanation.isAi, isFalse);
      expect(explanation.provider, isNull);
      expect(explanation.topic, PredictiveTopic.revenueForecast);
      expect(explanation.generatedAt, now);
      // The twin's identity travels with the answer on the rule path too.
      expect(explanation.ruleVersion, RevenueForecastRule.version);
      expect(explanation.reasonCodes, twin.reasonCodes);
      // …and the prose quotes the SAME reason codes, by machine code and by
      // label, so rule ↔ UI ↔ AI cannot drift apart.
      expect(twin.reasonCodes, contains(ReasonCode.revenueGrowing));
      for (final code in twin.reasonCodes) {
        expect(explanation.text, contains(code.code));
        expect(explanation.text, contains(code.labelVi));
      }
      // The rule's own number is what the seller reads.
      expect(
        explanation.text,
        contains(TongtaiFormatters.vnd(twin.result!.nextMonthRevenue)),
      );
      // Zero provider spend: no key was set, so nothing was attempted.
      expect(calls, isEmpty);
    });

    test('risk: rule explanation, ids only, no call', () async {
      final customers = customerContext();
      final twin = riskRule.assess(customers);

      final explanation = await service().explainRisk(
        context: customers,
        risk: twin,
      );

      expect(explanation.source, BusinessSummarySource.rule);
      expect(explanation.ruleVersion, CustomerRiskRule.version);
      expect(explanation.reasonCodes, twin.reasonCodes);
      expect(explanation.text, contains('cust-lapsed'));
      // Never the person behind the id.
      expect(explanation.text, isNot(contains(fixtureName)));
      expect(explanation.text, isNot(contains(fixturePhone)));
      expect(explanation.text, isNot(contains(fixtureEmail)));
      expect(calls, isEmpty);
    });

    test('alerts: every raised alert is explained, none invented', () async {
      final customers = customerContext();
      final twin = alertsRule.evaluate(
        revenue: growingRevenue,
        customers: customers,
      );
      // Half the (two-customer) directory has lapsed, so the customer-risk
      // alert fires; revenue is growing, so no drop alert does.
      expect(twin.result!.map((a) => a.kind), [BusinessAlertKind.customerRisk]);

      final explanation = await service().explainAlerts(
        revenue: growingRevenue,
        customers: customers,
        alerts: twin,
      );

      expect(explanation.source, BusinessSummarySource.rule);
      expect(explanation.ruleVersion, BusinessAlertsRule.version);
      expect(explanation.reasonCodes, twin.reasonCodes);
      expect(
        explanation.text,
        contains(BusinessAlertKind.customerRisk.labelVi),
      );
      expect(explanation.text, isNot(contains(fixtureName)));
      expect(calls, isEmpty);
    });

    test('alerts: "nothing wrong" never reads as "no data"', () {
      // An empty alert list is a real, sufficient answer (BusinessAlertsRule
      // reserves `insufficient` for "I cannot judge at all").
      final quiet = RuleTwinResult<List<BusinessAlert>>(
        result: const [],
        confidence: ForecastConfidence.high,
        sufficiency: DataSufficiency.sufficient,
        reasonCodes: const [ReasonCode.revenueGrowing],
        version: BusinessAlertsRule.version,
        generatedAt: now,
      );
      final text = ruleBasedAlertsExplanation(quiet);

      expect(text, contains('Không có cảnh báo nào'));
      expect(text, isNot(contains('Chưa đủ dữ liệu')));
      expect(text, contains(ReasonCode.revenueGrowing.labelVi));
      expect(text, contains(ReasonCode.revenueGrowing.code));
    });
  });

  // ── 2 · insufficient twin → zero spend even WITH a key ────────────────────
  group('insufficient twin → the provider is never called', () {
    test('forecast: refuses, says so, and spends nothing', () async {
      final twin = forecastRule.forecast(thinRevenue);
      expect(twin.sufficiency, DataSufficiency.insufficient);
      expect(twin.result, isNull);

      final explanation = await service(
        keys: const [TongtaiAiProviderKind.xai],
        reply: 'Doanh thu tháng tới sẽ là 999.999.999 ₫.',
      ).explainForecast(context: thinRevenue, forecast: twin);

      // A key IS configured — the guard, not the absence of a key, is what
      // stops the spend (the twin has nothing to explain).
      expect(calls, isEmpty);
      expect(explanation.source, BusinessSummarySource.rule);
      expect(explanation.text, contains('Chưa đủ dữ liệu'));
      expect(explanation.text, isNot(contains('999.999.999')));
      expect(explanation.reasonCodes, contains(ReasonCode.notEnoughHistory));
      expect(explanation.ruleVersion, RevenueForecastRule.version);
    });

    test('risk: an empty directory refuses without spending', () async {
      final twin = riskRule.assess(emptyCustomers);
      expect(twin.sufficiency, DataSufficiency.insufficient);

      final explanation = await service(
        keys: const [TongtaiAiProviderKind.xai],
        reply: 'Mọi khách đều an toàn.',
      ).explainRisk(context: emptyCustomers, risk: twin);

      expect(calls, isEmpty);
      expect(explanation.source, BusinessSummarySource.rule);
      expect(explanation.text, contains('Chưa đủ dữ liệu'));
      expect(explanation.reasonCodes, contains(ReasonCode.noCustomers));
    });
  });

  // ── 3 · hostile AI → the twin still owns every number ─────────────────────
  group('hostile AI cannot change the numbers', () {
    const hostile =
        'Doanh thu tháng tới sẽ là 999.999.999 ₫ và mọi khách đều an toàn';

    test('forecast: version + reason codes are the twin\'s', () async {
      final twin = forecastRule.forecast(growingRevenue);
      final explanation = await service(
        keys: const [TongtaiAiProviderKind.xai],
        reply: hostile,
      ).explainForecast(context: growingRevenue, forecast: twin);

      expect(calls, hasLength(1));
      // What was actually sent is exactly the audited pure function's output —
      // the prompt-contract tests below therefore describe the real call.
      expect(
        calls.single.prompt,
        predictiveAiPromptText(
          context: growingRevenue,
          ruleBlock: revenueForecastRuleBlock(twin),
          topic: PredictiveTopic.revenueForecast,
        ),
      );
      expect(explanation.source, BusinessSummarySource.ai);
      expect(explanation.provider, TongtaiAiProviderKind.xai);
      // The prose is passed through verbatim — that is the AI's whole job…
      expect(explanation.text, hostile);
      // …but the contract fields are copied from the twin, not parsed from it.
      expect(explanation.ruleVersion, twin.version);
      expect(explanation.ruleVersion, RevenueForecastRule.version);
      expect(explanation.reasonCodes, twin.reasonCodes);
      expect(explanation.reasonCodes, contains(ReasonCode.revenueGrowing));

      // The numeric authority: the rule twin is unchanged by the AI run, and
      // recomputing it gives the identical forecast. What a screen renders is
      // `twin.result`, and there is NO number on PredictiveExplanation for an
      // AI answer to have influenced.
      final recomputed = forecastRule.forecast(growingRevenue);
      expect(recomputed.result, twin.result);
      expect(twin.result!.nextMonthRevenue, isNot(999999999));
      expect(
        TongtaiFormatters.vnd(twin.result!.nextMonthRevenue),
        isNot(contains('999.999.999')),
      );
    });

    test(
      'risk: "mọi khách đều an toàn" does not move a single count',
      () async {
        final customers = customerContext();
        final twin = riskRule.assess(customers);
        final lapsedBefore = twin.result!.lapsedCount;
        expect(lapsedBefore, greaterThan(0));

        final explanation = await service(
          keys: const [TongtaiAiProviderKind.xai],
          reply: hostile,
        ).explainRisk(context: customers, risk: twin);

        expect(explanation.source, BusinessSummarySource.ai);
        expect(explanation.ruleVersion, CustomerRiskRule.version);
        expect(explanation.reasonCodes, twin.reasonCodes);
        expect(
          explanation.reasonCodes,
          contains(ReasonCode.inactiveBeyondChurnWindow),
        );
        // The rule's counts are what the Risk screen renders.
        expect(riskRule.assess(customers).result!.lapsedCount, lapsedBefore);
      },
    );
  });

  // ── 4 · prompt contract ───────────────────────────────────────────────────
  group('predictiveAiPromptText (what actually leaves the device)', () {
    test('carries the capability block AND the rule block', () {
      final twin = forecastRule.forecast(growingRevenue);
      final ruleBlock = revenueForecastRuleBlock(twin);
      final prompt = predictiveAiPromptText(
        context: growingRevenue,
        ruleBlock: ruleBlock,
        topic: PredictiveTopic.revenueForecast,
      );

      // Both halves of the AI's world, verbatim.
      expect(prompt, contains(growingRevenue.promptBlock()));
      expect(prompt, contains(capabilityPromptHeader(growingRevenue)));
      expect(prompt, contains(ruleBlock));
      // The twin's own numbers, confidence, sufficiency, codes and version.
      expect(
        prompt,
        contains(TongtaiFormatters.vnd(twin.result!.nextMonthRevenue)),
      );
      expect(prompt, contains(twin.provenance));
      expect(prompt, contains(RevenueForecastRule.version));
      expect(prompt, contains(ReasonCode.revenueGrowing.code));
      // The instruction that makes this an explanation, not a second forecast.
      expect(prompt, contains('GIẢI THÍCH'));
      expect(prompt, contains('TUYỆT ĐỐI KHÔNG đưa ra con số khác'));
      expect(prompt, contains('bằng LỜI VĂN'));
      // Pure: same inputs, byte-identical text.
      expect(
        prompt,
        predictiveAiPromptText(
          context: growingRevenue,
          ruleBlock: ruleBlock,
          topic: PredictiveTopic.revenueForecast,
        ),
      );
    });

    test('customer risk: ids, counts and bands — never a person', () {
      final customers = customerContext();
      final twin = riskRule.assess(customers);
      final prompt = predictiveAiPromptText(
        context: customers,
        ruleBlock: customerRiskRuleBlock(twin),
        topic: PredictiveTopic.customerRisk,
      );

      // The exact PII strings the fixture is stuffed with must be absent.
      expect(prompt, isNot(contains(fixtureName)));
      expect(prompt, isNot(contains(fixturePhone)));
      expect(prompt, isNot(contains(fixtureEmail)));
      expect(prompt, isNot(contains(fixtureLocation)));
      expect(prompt, isNot(contains('Mai')));
      expect(prompt, isNot(contains('@')));
      // What it DOES carry: ids, counts, stages, scores, reason codes.
      expect(prompt, contains('cust-lapsed'));
      expect(prompt, contains(CustomerRiskRule.version));
      expect(prompt, contains(ReasonCode.inactiveBeyondChurnWindow.code));
      expect(prompt, contains('Khách hàng: 2'));
    });

    test('insufficient twin renders a refusal, never a number', () {
      final twin = forecastRule.forecast(thinRevenue);
      final block = revenueForecastRuleBlock(twin);

      expect(block, contains('KHÔNG CÓ CON SỐ'));
      expect(block, contains(ReasonCode.notEnoughHistory.code));
      expect(block, contains('insufficient'));
      expect(block, isNot(contains('₫')));
    });

    test('alerts prompt carries both capability blocks', () {
      final customers = customerContext();
      final twin = alertsRule.evaluate(
        revenue: growingRevenue,
        customers: customers,
      );
      final prompt = predictiveAiPromptTextFor(
        contexts: [growingRevenue, customers],
        ruleBlock: businessAlertsRuleBlock(twin),
        topic: PredictiveTopic.businessAlerts,
      );

      expect(prompt, contains(capabilityPromptHeader(growingRevenue)));
      expect(prompt, contains(capabilityPromptHeader(customers)));
      expect(prompt, contains(BusinessAlertsRule.version));
      expect(prompt, isNot(contains(fixtureName)));
      expect(prompt, isNot(contains(fixturePhone)));
    });
  });

  // ── 5 · provider chain failure → rule fallback ────────────────────────────
  test(
    'every provider fails → the deterministic explanation answers',
    () async {
      final twin = forecastRule.forecast(growingRevenue);
      final explanation = await service(
        keys: const [TongtaiAiProviderKind.xai, TongtaiAiProviderKind.gemini],
        // null reply = every provider throws.
        preference: const [
          TongtaiAiProviderKind.xai,
          TongtaiAiProviderKind.gemini,
        ],
      ).explainForecast(context: growingRevenue, forecast: twin);

      // The whole chain was tried, in order, before giving up.
      expect(calls.map((c) => c.provider), [
        TongtaiAiProviderKind.xai,
        TongtaiAiProviderKind.gemini,
      ]);
      expect(explanation.source, BusinessSummarySource.rule);
      expect(explanation.provider, isNull);
      expect(explanation.ruleVersion, twin.version);
      expect(explanation.reasonCodes, twin.reasonCodes);
      expect(
        explanation.text,
        contains(TongtaiFormatters.vnd(twin.result!.nextMonthRevenue)),
      );
    },
  );

  // ── WTM-159 · the AI Runtime Boundary is designed, not enabled ────────────
  group('AI Runtime Boundary (WTM-159, ADR-TON-016 Decision 5)', () {
    test('DisabledAiToolRuntime.invoke throws, pointing at the ADR', () {
      const runtime = DisabledAiToolRuntime();

      expect(
        () => runtime.invoke('readCustomers', const {'limit': 10}),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('ADR-TON-016'),
              contains('G-3'),
              contains('readCustomers'),
            ),
          ),
        ),
      );
      expect(kAiToolRuntimeDisabledMessage, contains('no tool calling'));
      expect(kAiToolRuntimeDisabledMessage, contains('no ReAct'));
      expect(kAiToolRuntimeDisabledMessage, contains('no autonomous agent'));
    });

    test('a full AI run never invokes a tool runtime', () async {
      // A spy that fails the test the instant anything reaches it. It is
      // deliberately impossible to inject — PredictiveAiService takes no
      // runtime — so this documents the intent while the structural test below
      // is what actually enforces it.
      final spy = _SpyToolRuntime();
      final customers = customerContext();

      await service(
        keys: const [TongtaiAiProviderKind.xai],
        reply: 'Giải thích ngắn gọn.',
      ).explainRisk(context: customers, risk: riskRule.assess(customers));

      expect(calls, hasLength(1)); // the AI path really did run
      expect(spy.invocations, isEmpty);
      // The prompt that left the device tells the model the same thing.
      expect(calls.single.prompt, contains('không có công cụ'));
    });

    test('structural: nothing under lib/ wires an AiToolRuntime', () {
      final offenders = <String>[];
      for (final file
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        // The boundary file itself is where the seam is DEFINED.
        if (file.path.endsWith('ai/ai_runtime_boundary.dart')) continue;
        // Comments may (and should) point at the boundary; only CODE that
        // imports or references it is a violation.
        final source = file
            .readAsLinesSync()
            .where((line) => !line.trimLeft().startsWith('//'))
            .join('\n');
        if (source.contains('AiToolRuntime') ||
            source.contains('ai_runtime_boundary.dart')) {
          offenders.add(file.path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'Tool calling is disabled (ADR-TON-016 Decision 5). Wiring an '
            'AiToolRuntime crosses the G-3 red line and is a Founder decision:\n'
            '${offenders.join('\n')}',
      );
    });

    test('the predictive prompt tells the model it has no tools', () {
      final twin = forecastRule.forecast(growingRevenue);
      final prompt = predictiveAiPromptText(
        context: growingRevenue,
        ruleBlock: revenueForecastRuleBlock(twin),
        topic: PredictiveTopic.revenueForecast,
      );
      expect(prompt, contains('không có công cụ'));
      expect(prompt, contains('không thực'));
    });
  });
}

/// Records every provider call, and either answers [reply] or fails the whole
/// chain when it is null.
class _SpyClient implements TongtaiAiClient {
  _SpyClient(this.provider, this._calls, {this.reply});

  @override
  final TongtaiAiProviderKind provider;

  final List<({TongtaiAiProviderKind provider, String prompt})> _calls;

  /// The provider's answer; `null` makes it throw (chain-failure path).
  final String? reply;

  @override
  Future<String?> Function() get apiKey =>
      () async => 'unused';

  @override
  Future<TongtaiAiResponse> chat({
    required List<TongtaiAiMessage> messages,
    String? systemPrompt,
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    _calls.add((provider: provider, prompt: messages.last.content));
    if (reply == null) throw TongtaiAiException.network;
    return TongtaiAiResponse(
      text: reply!,
      provider: provider,
      model: model ?? provider.defaultModel,
    );
  }

  @override
  Future<TongtaiAiResponse> testConnection() =>
      chat(messages: const [TongtaiAiMessage.user('ping')]);
}

/// A tool runtime that must never be reached (WTM-159).
class _SpyToolRuntime implements AiToolRuntime {
  final List<String> invocations = <String>[];

  @override
  Future<String> invoke(String tool, Map<String, Object?> args) async {
    invocations.add(tool);
    fail('The predictive AI pipeline invoked a tool runtime: $tool');
  }
}
