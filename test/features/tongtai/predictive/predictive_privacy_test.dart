import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/ai/predictive_ai.dart';
import 'package:tongtai/features/tongtai/analytics/cashflow_series.dart';
import 'package:tongtai/features/tongtai/capability/customer_capability.dart';
import 'package:tongtai/features/tongtai/capability/revenue_capability.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/core/tongtai_formatters.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/predictive/business_alerts_rule.dart';
import 'package:tongtai/features/tongtai/predictive/customer_risk_rule.dart';
import 'package:tongtai/features/tongtai/predictive/revenue_forecast_rule.dart';
import 'package:tongtai/features/tongtai/predictive/rule_twin.dart';

/// **WTM-163 — Privacy audit of the Predictive Foundation** (D-7 / ADR-TON-005
/// red-line, ADR-TON-016).
///
/// The Founder's red line, stated as testable claims:
///
/// 1. **Nothing personal leaves the device.** The only predictive text that can
///    reach a BYOK provider is `CapabilityContext.promptBlock()` + a
///    `*RuleBlock(...)`. Neither may contain a customer name, phone, email,
///    address, note, tag, product name, SKU, order number or a single order's
///    amount.
/// 2. **The risk twin is PII-free by construction**, not by a filter someone
///    could forget: `CustomerRiskEntry` has no name/phone/email field at all.
/// 3. **The predictive path logs nothing.** No file under `predictive/`,
///    `capability/` or `analytics/` touches the telemetry seam, so no forecast,
///    risk score, revenue figure or AI prompt can be shipped to Firebase — not
///    even by accident.
/// 4. **The approved telemetry catalogue carries no business values.**
///
/// The fixture is deliberately hostile: every string below is planted in the
/// customer directory, the catalog, the ledger and the order lines. If any of
/// them can be found in a prompt, this suite fails loudly.
void main() {
  // ── The hostile PII fixture ───────────────────────────────────────────────
  const fixtureName = 'Nguyễn Thị Mai';
  const fixturePhone = '+84912345678';
  const fixtureEmail = 'mai@example.com';
  const fixtureAddress = '12 Ngõ Bí Mật, Cầu Giấy, Hà Nội';
  const fixtureNote = 'Ghi chú riêng: còn nợ 2 triệu';
  const fixtureTag = 'khách VIP bí mật';
  const fixtureSegment = 'Nhóm khách bí mật';
  const fixtureLocation = 'Quận Bí Mật';
  const fixtureProduct = 'Máy lọc nước Kangaroo KG10A3';
  const fixtureSku = 'SKU-BI-MAT-001';
  const fixtureCategory = 'Đồ gia dụng bí mật';
  const fixtureOrderNumber = 'DH-2026-BIMAT-0042';
  const fixtureLedgerNote = 'Chi tiền mặt cho chị Mai, chợ Bí Mật';

  // Two per-order amounts that never coincide with any published aggregate:
  // they share Sep 2025 with two ordinary orders, so the month total
  // (15 309 873 ₫) and the window total (117 159 873 ₫) differ from both — a
  // leak of either figure can only have come from an individual order.
  const secretOrderAmountA = 3141592.0;
  const secretOrderAmountB = 2718281.0;

  /// Every string that must never leave the device, in the exact form a leak
  /// would take (raw, and — for money — Vietnamese-formatted).
  const forbidden = <String>[
    fixtureName,
    'Nguyễn',
    'Thị Mai',
    fixturePhone,
    '912345678',
    fixtureEmail,
    fixtureAddress,
    'Bí Mật',
    fixtureNote,
    fixtureTag,
    fixtureSegment,
    fixtureLocation,
    fixtureProduct,
    'Kangaroo',
    fixtureSku,
    fixtureCategory,
    fixtureOrderNumber,
    fixtureLedgerNote,
    // Per-order money, raw and formatted.
    '3141592',
    '3.141.592',
    '2718281',
    '2.718.281',
  ];

  /// Asserts [text] contains none of [forbidden]. Reports *which* string leaked
  /// and where, so a failure is actionable rather than a bare `false`.
  void expectPiiFree(String text, {required String surface}) {
    final leaks = <String>[
      for (final needle in forbidden)
        if (text.contains(needle)) needle,
    ];
    expect(
      leaks,
      isEmpty,
      reason:
          'PRIVACY RED-LINE (D-7 / ADR-TON-005): $surface leaked $leaks. '
          'Only aggregates, ids, bands and reason codes may leave the device.',
    );
  }

  // ── Fixture construction ──────────────────────────────────────────────────
  // Jul 2025 … Jun 2026 are the completed months; Jul 2026 is running.
  final now = DateTime(2026, 7, 15, 9, 30);

  final mai = Customer(
    id: 'c1a3f0e2-1111-4a2b-8c3d-000000000001',
    name: fixtureName,
    phone: fixturePhone,
    location: fixtureLocation,
    orderCount: 2,
    totalSpent: secretOrderAmountA + secretOrderAmountB,
    lastPurchaseDate: DateTime(2025, 9, 12),
    email: fixtureEmail,
    addresses: const [fixtureAddress],
    segments: const [fixtureSegment],
    tags: const [fixtureTag],
    notes: fixtureNote,
  );
  final binh = Customer(
    id: 'c1a3f0e2-1111-4a2b-8c3d-000000000002',
    name: 'Trần Văn Bình',
    phone: '+84987654321',
    location: 'Hải Phòng',
    orderCount: 12,
    totalSpent: 0,
    lastPurchaseDate: DateTime(2026, 6, 20),
    email: 'binh@example.com',
  );
  final cuong = Customer(
    id: 'c1a3f0e2-1111-4a2b-8c3d-000000000003',
    name: 'Lê Quốc Cường',
    phone: '+84911222333',
    location: 'Cần Thơ',
    orderCount: 12,
    totalSpent: 0,
    lastPurchaseDate: DateTime(2026, 6, 25),
  );

  CustomerOrder order({
    required String id,
    required Customer customer,
    required DateTime date,
    required double amount,
    String productName = 'Hàng hoá thường',
    String sku = 'SKU-OK-001',
    String category = 'Chung',
    String orderNumber = 'DH-2026-OK',
  }) => CustomerOrder(
    id: id,
    customerId: customer.id,
    orderNumber: orderNumber,
    date: date,
    status: OrderStatus.delivered,
    items: [
      OrderItem(
        productId: 'p-$id',
        productName: productName,
        sku: sku,
        category: category,
        unit: 'cái',
        quantity: 1,
        unitPrice: amount,
      ),
    ],
  );

  final orders = <CustomerOrder>[
    // Mai's two orders — the PII-stuffed lines — share Sep 2025, so the month
    // total (5 859 873 ₫) equals neither amount.
    order(
      id: 'secret-a',
      customer: mai,
      date: DateTime(2025, 9, 10, 10),
      amount: secretOrderAmountA,
      productName: fixtureProduct,
      sku: fixtureSku,
      category: fixtureCategory,
      orderNumber: fixtureOrderNumber,
    ),
    order(
      id: 'secret-b',
      customer: mai,
      date: DateTime(2025, 9, 12, 16),
      amount: secretOrderAmountB,
      productName: fixtureProduct,
      sku: fixtureSku,
      category: fixtureCategory,
      orderNumber: fixtureOrderNumber,
    ),
    // Twelve completed months of ordinary trade from two other customers, so
    // every twin is `sufficient` and emits its richest block.
    for (var back = 0; back < 12; back++) ...[
      order(
        id: 'binh-$back',
        customer: binh,
        date: DateTime(2026, 6 - back, 8, 9),
        amount: 5000000 + back * 100000,
      ),
      order(
        id: 'cuong-$back',
        customer: cuong,
        date: DateTime(2026, 6 - back, 22, 9),
        amount: 4000000 - back * 50000,
      ),
    ],
  ];

  final products = <Product>[
    Product(
      id: 'prod-secret',
      sku: fixtureSku,
      name: fixtureProduct,
      category: fixtureCategory,
      quantity: 1,
      pricePerUnit: 1500000,
      reorderLevel: 20,
      updatedAt: DateTime(2026, 6, 30),
      description: 'Giao cho $fixtureName tại $fixtureAddress',
    ),
  ];

  final transactions = <FinanceTransaction>[
    for (var back = 0; back < 12; back++) ...[
      FinanceTransaction(
        id: 'in-$back',
        type: TransactionType.income,
        category: 'Bán hàng',
        amount: 9000000,
        date: DateTime(2026, 6 - back, 28),
      ),
      FinanceTransaction(
        id: 'out-$back',
        type: TransactionType.expense,
        category: 'Nhập hàng',
        amount: 11000000,
        date: DateTime(2026, 6 - back, 29),
        description: fixtureLedgerNote,
      ),
    ],
  ];

  final revenueContext = RevenueCapabilityContext.from(
    orders: orders,
    now: now,
  );
  final customerContext = CustomerCapabilityContext.from(
    customers: [mai, binh, cuong],
    orders: orders,
    now: now,
  );
  final forecastTwin = const RevenueForecastRule().forecast(revenueContext);
  final riskTwin = const CustomerRiskRule().assess(customerContext);
  final alertsTwin = const BusinessAlertsRule().evaluate(
    revenue: revenueContext,
    customers: customerContext,
    cashflow: CashflowSeries.fromTransactions(transactions, now: now),
    products: products,
  );

  // ══ 0 · The fixture is worth testing ═══════════════════════════════════════

  test('the fixture makes every twin answer (a refusal would prove '
      'nothing)', () {
    expect(revenueContext.hasData, isTrue);
    expect(customerContext.hasData, isTrue);
    expect(forecastTwin.hasAnswer, isTrue);
    expect(forecastTwin.sufficiency, DataSufficiency.sufficient);
    expect(riskTwin.hasAnswer, isTrue);
    expect(riskTwin.result!.entries, hasLength(3));
    expect(alertsTwin.hasAnswer, isTrue);
    // Mai is the churned one, so she ranks into the top entries the AI sees.
    expect(riskTwin.result!.top(3).map((e) => e.customerId), contains(mai.id));
  });

  test('the leak detector is armed (negative control)', () {
    // What a leak would actually look like: the naive "just print the row"
    // block someone might add in a hurry. Every guarded string must be caught
    // in exactly the form it would take, otherwise the suite above is theatre.
    final naiveLeak = [
      mai.name,
      mai.phone,
      mai.email,
      mai.location,
      ...mai.addresses,
      ...mai.tags,
      ...mai.segments,
      mai.notes,
      orders.first.orderNumber,
      orders.first.items.single.productName,
      orders.first.items.single.sku,
      orders.first.items.single.category,
      TongtaiFormatters.vnd(secretOrderAmountA),
      TongtaiFormatters.vnd(secretOrderAmountB),
      secretOrderAmountA.toInt().toString(),
      secretOrderAmountB.toInt().toString(),
      transactions[1].description,
      products.single.name,
    ].join(' · ');

    final caught = <String>[
      for (final needle in forbidden)
        if (naiveLeak.contains(needle)) needle,
    ];
    expect(caught, containsAll(forbidden));
  });

  // ══ 1 · Capability prompt blocks ═══════════════════════════════════════════

  group('capability prompt blocks are PII-free', () {
    test('RevenueCapabilityContext.promptBlock()', () {
      final block = revenueContext.promptBlock();
      expectPiiFree(block, surface: 'RevenueCapabilityContext.promptBlock()');
      // …and it is not empty boilerplate: it really did describe the business.
      expect(block, contains('# Capability: revenue'));
      expect(block, contains('Doanh thu billable'));
    });

    test('CustomerCapabilityContext.promptBlock()', () {
      final block = customerContext.promptBlock();
      expectPiiFree(block, surface: 'CustomerCapabilityContext.promptBlock()');
      expect(block, contains('# Capability: customer'));
      expect(block, contains('Khách hàng: 3'));
      // The consumer block reasons about segments, so not even ids appear.
      for (final customer in [mai, binh, cuong]) {
        expect(
          block,
          isNot(contains(customer.id)),
          reason: 'the consumer block speaks in counts, never in individuals',
        );
      }
    });
  });

  // ══ 2 · Rule Twin provenance + rule blocks ═════════════════════════════════

  group('Rule Twin output is PII-free', () {
    test('RuleTwinResult.provenance carries codes and bands only', () {
      for (final entry in {
        'revenue forecast': forecastTwin.provenance,
        'customer risk': riskTwin.provenance,
        'business alerts': alertsTwin.provenance,
      }.entries) {
        expectPiiFree(entry.value, surface: '${entry.key} provenance');
        expect(entry.value, contains('sufficiency='));
        expect(entry.value, contains('confidence='));
        expect(entry.value, contains('reasons='));
        // No money at all: provenance is the one string blessed for telemetry.
        expect(
          entry.value,
          isNot(contains('₫')),
          reason: 'provenance must stay money-free — it is telemetry-shaped',
        );
      }
    });

    test('revenueForecastRuleBlock()', () {
      final block = revenueForecastRuleBlock(forecastTwin);
      expectPiiFree(block, surface: 'revenueForecastRuleBlock()');
      expect(block, contains('# Rule Twin:'));
      expect(block, contains('Dự báo tháng'));
    });

    test('customerRiskRuleBlock() carries ids, never identities', () {
      final block = customerRiskRuleBlock(riskTwin);
      expectPiiFree(block, surface: 'customerRiskRuleBlock()');
      expect(block, contains('# Rule Twin:'));
      // Ids ARE allowed — and are what the block actually uses.
      expect(block, contains(mai.id));
      // Per-customer money never leaves, even for the top-ranked customer.
      expect(
        block,
        isNot(contains('₫')),
        reason: 'the risk block reports scores and counts, never spend',
      );
    });

    test('businessAlertsRuleBlock()', () {
      final block = businessAlertsRuleBlock(alertsTwin);
      expectPiiFree(block, surface: 'businessAlertsRuleBlock()');
      expect(block, contains('# Rule Twin:'));
    });

    test('the deterministic (AI-off) explanations are PII-free too', () {
      expectPiiFree(
        ruleBasedForecastExplanation(forecastTwin),
        surface: 'ruleBasedForecastExplanation()',
      );
      expectPiiFree(
        ruleBasedRiskExplanation(riskTwin),
        surface: 'ruleBasedRiskExplanation()',
      );
      expectPiiFree(
        ruleBasedAlertsExplanation(alertsTwin),
        surface: 'ruleBasedAlertsExplanation()',
      );
    });
  });

  // ══ 3 · The full prompt — what actually leaves the device ══════════════════

  test('the assembled predictive prompts leak nothing', () {
    final prompts = <String, String>{
      'revenue forecast prompt': predictiveAiPromptText(
        context: revenueContext,
        ruleBlock: revenueForecastRuleBlock(forecastTwin),
        topic: PredictiveTopic.revenueForecast,
      ),
      'customer risk prompt': predictiveAiPromptText(
        context: customerContext,
        ruleBlock: customerRiskRuleBlock(riskTwin),
        topic: PredictiveTopic.customerRisk,
      ),
      'business alerts prompt': predictiveAiPromptTextFor(
        contexts: [revenueContext, customerContext],
        ruleBlock: businessAlertsRuleBlock(alertsTwin),
        topic: PredictiveTopic.businessAlerts,
      ),
    };
    for (final entry in prompts.entries) {
      expectPiiFree(entry.value, surface: entry.key);
      expect(entry.value, contains('# Rule Twin'));
    }
    expectPiiFree(kPredictiveAiSystemPrompt, surface: 'the system prompt');
  });

  // ══ 4 · The risk assessment carries ids only — structurally ════════════════

  group('CustomerRiskAssessment carries ids only', () {
    test('CustomerRiskEntry declares no identity field (source scan)', () {
      const expectedFields = <String>{
        'customerId',
        'stage',
        'recencyDays',
        'lifetimeOrders',
        'lifetimeValue',
        'riskScore',
        'reasonCodes',
        'winBackCandidate',
      };
      const bannedFields = <String>{
        'name',
        'customerName',
        'phone',
        'email',
        'address',
        'addresses',
        'location',
        'notes',
        'tags',
        'segments',
      };

      final source = File(
        'lib/features/tongtai/predictive/customer_risk_rule.dart',
      ).readAsStringSync();
      final start = source.indexOf('class CustomerRiskEntry {');
      expect(start, greaterThan(-1), reason: 'CustomerRiskEntry not found');
      final end = source.indexOf('class CustomerRiskAssessment {', start);
      expect(end, greaterThan(start));
      final body = source.substring(start, end);

      final declared = <String>{
        for (final match in RegExp(
          r'^\s*final\s+[\w<>,?\s]+\s+(\w+);',
          multiLine: true,
        ).allMatches(body))
          match.group(1)!,
      };

      expect(
        declared,
        unorderedEquals(expectedFields),
        reason:
            'CustomerRiskEntry\'s field set is a PRIVACY contract (D-7): the '
            'twin travels to the AI layer, so it must carry ids and numbers '
            'only. Adding a field here needs a privacy review.',
      );
      expect(declared.intersection(bannedFields), isEmpty);
    });

    test('entry and assessment toString() leak nothing', () {
      for (final entry in riskTwin.result!.entries) {
        expectPiiFree(
          entry.toString(),
          surface: 'CustomerRiskEntry.toString()',
        );
      }
      expectPiiFree(
        riskTwin.result!.toString(),
        surface: 'CustomerRiskAssessment.toString()',
      );
      // The entries do identify customers — by id, which is the whole point.
      expect(
        riskTwin.result!.entries.map((e) => e.customerId),
        containsAll([mai.id, binh.id, cuong.id]),
      );
    });
  });

  // ══ 5 · Telemetry: the predictive path logs NOTHING ════════════════════════

  test('no predictive/capability/analytics source touches the telemetry '
      'seam', () {
    const telemetryApi = <String>[
      'TongtaiTelemetry',
      'tongtaiTelemetryProvider',
      'logEvent(',
      'recordError(',
      'FirebaseAnalytics',
      'FirebaseCrashlytics',
    ];
    final offenders = <String>[];
    for (final dir in const [
      'lib/features/tongtai/predictive',
      'lib/features/tongtai/capability',
      'lib/features/tongtai/analytics',
    ]) {
      final directory = Directory(dir);
      expect(directory.existsSync(), isTrue, reason: '$dir must exist');
      for (final file
          in directory
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final trimmed = lines[i].trimLeft();
          if (trimmed.startsWith('//')) continue; // doc/comment mentions are ok
          for (final api in telemetryApi) {
            if (lines[i].contains(api)) {
              offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
            }
          }
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'PRIVACY RED-LINE (D-7 / ADR-TON-005): the predictive path must not '
          'log at all. A forecast number, a risk score, a revenue figure or an '
          'AI prompt shipped to Firebase is exactly what the red-line forbids. '
          'If predictive telemetry is ever genuinely needed it MUST go through '
          'a REVIEWED event: add it to docs/05-OPERATIONS/TELEMETRY-EVENTS.md '
          'FIRST (counts/flags only, "operational-only review" noted in the '
          'PR), then wire it through the tongtaiTelemetryProvider seam — never '
          'inline in a rule or a capability context.\n${offenders.join('\n')}',
    );
  });

  // ══ 6 · The approved telemetry catalogue carries no business values ════════

  test('TELEMETRY-EVENTS.md lists no event carrying business values', () {
    // The exact tokens the Founder red-line names: an event parameter that
    // carries any of these is business content, not an operational counter.
    const bannedParams = <String>[
      'revenue',
      'forecast',
      'customer_name',
      'phone',
      'email',
    ];

    final doc = File('docs/05-OPERATIONS/TELEMETRY-EVENTS.md');
    expect(doc.existsSync(), isTrue);
    final lines = doc.readAsLinesSync();

    // Event rows look like: `| \`app_open\` | — | … |`
    final rows = [
      for (final line in lines)
        if (line.trimLeft().startsWith('| `')) line,
    ];
    expect(
      rows,
      isNotEmpty,
      reason: 'the event catalogue table must be parseable',
    );

    final offenders = <String>[];
    for (final row in rows) {
      final cells = row.split('|').map((c) => c.trim()).toList();
      // ['', event, params, when, ''] — params is the privacy-critical column.
      final event = cells.length > 1 ? cells[1] : row;
      final params = cells.length > 2 ? cells[2].toLowerCase() : '';
      for (final banned in bannedParams) {
        if (params.contains(banned)) offenders.add('$event → $banned');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'PRIVACY RED-LINE (D-7 / ADR-TON-005): telemetry events carry '
          'counts/flags only. These approved events would ship business '
          'content: ${offenders.join(', ')}',
    );

    // The catalogue also has to keep saying so.
    final text = lines.join('\n');
    expect(text, contains('never business content'));
    expect(text, contains('không bao giờ chứa dữ liệu kinh doanh'));
  });
}
