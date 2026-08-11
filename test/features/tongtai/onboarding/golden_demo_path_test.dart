import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/analytics/customer_rfm.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_repository.dart';
import 'package:tongtai/features/tongtai/commerce/import/commerce_importer.dart';
import 'package:tongtai/features/tongtai/commerce/import/xlsx_commerce_source.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/finance/settlement_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/logistics/shipment_repository.dart';
import 'package:tongtai/features/tongtai/onboarding/analysis_pipeline.dart';
import 'package:tongtai/features/tongtai/onboarding/first_insight.dart';
import 'package:tongtai/features/tongtai/onboarding/first_insight_input.dart';
import 'package:tongtai/features/tongtai/onboarding/first_plan.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/sample/historical_data_generator.dart';
import 'package:tongtai/features/tongtai/sample/sample_business_seeder.dart';
import 'package:tongtai/features/tongtai/sample/sample_data_seeder.dart';

/// **Golden Demo Path** — WTM-359 (S10, Epic WTM-349).
///
/// Đây là đường Founder và đối tác sẽ xem. Luật của nó chỉ có một câu:
///
/// > Bộ dữ liệu mẫu **được phép chọn lọc kỹ**. Kết quả **không được hardcode**.
///
/// Nên mọi khẳng định dưới đây khoá **phạm vi và hình dạng**, không khoá con số
/// cụ thể: dữ liệu sinh theo mốc thời gian hiện tại, nên một con số cứng ở đây
/// sẽ hoặc đỏ vào tháng sau, hoặc — tệ hơn — được ai đó "sửa" bằng cách làm
/// engine trả về đúng nó.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SampleBusinessSeeder seeder;
  late DriftProductRepository products;
  late DriftOrderRepository orders;
  late DriftCustomerRepository customers;
  late DriftSettlementRepository settlements;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    products = DriftProductRepository(db);
    orders = DriftOrderRepository(db);
    customers = DriftCustomerRepository(db);
    settlements = DriftSettlementRepository(db);
    final samples = SampleDataSeeder(
      customers: customers,
      products: products,
      orders: orders,
      goals: DriftBusinessGoalRepository(db),
      finance: DriftFinanceRepository(db),
    );
    seeder = SampleBusinessSeeder(
      history: HistoricalDataSeeder(sampleSeeder: samples),
      importer: CommerceImporter(
        database: db,
        products: products,
        customers: customers,
        orders: orders,
        settlements: settlements,
        commerce: CommerceRepository(db),
        shipments: ShipmentRepository(db),
        now: DateTime.now,
        newId: () => 'bundled',
      ),
      commerce: CommerceRepository(db),
      samples: samples,
      customers: customers,
      orders: orders,
      settlements: settlements,
      bundledSource: () async => XlsxCommerceSource(
        bytes: File(
          'assets/demo/TongTai-Commerce-Demo-100-Products.xlsx',
        ).readAsBytesSync(),
        fileName: 'TongTai-Commerce-Demo-100-Products.xlsx',
        now: DateTime.now(),
      ),
    );
  });

  tearDown(() => db.close());

  Future<AnalysisRun> runPath() async {
    await seeder.seed();
    AnalysisRun? run;
    await AnalysisPipeline(
      source: _RepoSource(products, orders, customers),
    ).run(now: DateTime.now(), onDone: (r) => run = r).toList();
    return run!;
  }

  test(
    '⭐ engine tính THẬT trên bộ mẫu — không kết quả nào là hằng số',
    () async {
      final run = await runPath();

      // Số đếm phải khớp đúng những gì seeder vừa ghi. Nếu pipeline trả về một
      // con số đẹp cố định thì nó lệch ngay khi bộ mẫu đổi.
      expect(
        run.countOf(AnalysisStage.products),
        (await products.loadAll()).length,
      );
      expect(
        run.countOf(AnalysisStage.orders),
        (await orders.loadAll()).length,
      );
      expect(
        run.countOf(AnalysisStage.customers),
        (await customers.loadAll()).length,
      );
      expect(run.countOf(AnalysisStage.products), greaterThan(50));
    },
  );

  test(
    '⭐ bộ mẫu cho ra findings MẠNH — có kết luận, không phải im lặng',
    () async {
      final run = await runPath();
      final insight = run.insight;

      // Không được là "chưa đủ dữ liệu": bản demo mà từ chối kết luận thì không
      // chứng minh được gì.
      expect(insight.isInsufficient, isFalse);
      expect(insight.isQuiet, isFalse, reason: 'bộ mẫu phải có việc để nói');
      expect(insight.findings, isNotEmpty);
      expect(insight.findings.length, lessThanOrEqualTo(kMaxFirstFindings));

      for (final f in insight.findings) {
        expect(isDeclaredRuleSource(f.ruleCode), isTrue, reason: f.ruleCode);
        expect(f.headline, isNotEmpty);
        expect(f.reason, isNotEmpty);
      }
    },
  );

  test(
    'ảnh chụp doanh nghiệp có số THẬT, và từ chối chỗ nào chưa biết',
    () async {
      final run = await runPath();
      final snap = run.insight.snapshot;

      expect(snap.orders, greaterThan(0));
      expect(snap.revenue, isNotNull);
      expect(snap.revenue, greaterThan(0));

      // Lời: hoặc tính được, hoặc `null` KÈM lý do. Không có trạng thái thứ ba,
      // và đặc biệt không có "0" đội lốt "chưa biết" (ADR-TON-023).
      if (snap.profit == null) {
        expect(snap.profitBlockers, isNotEmpty);
      } else {
        expect(snap.profitBlockers, isEmpty);
      }
    },
  );

  test('⭐ tất định — chạy hai lần trên cùng máy cho cùng kết luận', () async {
    final first = await runPath();
    // Nạp lại (idempotent) rồi chạy lại engine.
    final second = await runPath();

    expect(
      second.insight.findings.map((f) => '${f.ruleCode}|${f.subjectId}'),
      first.insight.findings.map((f) => '${f.ruleCode}|${f.subjectId}'),
      reason: 'ảnh chụp demo phải đối chiếu được với test',
    );
  });

  test('chạy đường C hai lần KHÔNG nhân đôi dữ liệu', () async {
    await seeder.seed();
    final after1 = (await products.loadAll()).length;
    await seeder.seed();

    expect((await products.loadAll()).length, after1);
  });

  test('⛔ không sự kiện lịch sử nào mang mốc sau HÔM NAY (WTM-344)', () async {
    await seeder.seed();
    final now = DateTime.now();

    for (final o in await orders.loadAll()) {
      expect(
        o.date.isAfter(now),
        isFalse,
        reason: 'đơn ${o.id} nằm ở tương lai: ${o.date}',
      );
    }
  });

  test('kế hoạch dựng trên bộ mẫu không có việc nào ngõ cụt', () async {
    final run = await runPath();
    final plan = const FirstPlanBuilder().build(
      goals: const [OnboardingGoal.growProfit],
      insight: run.insight,
    );

    expect(plan.actions, isNotEmpty);
    for (final a in plan.actions) {
      expect(PlanDestination.values, contains(a.destination));
      expect(a.problem, isNotEmpty);
      expect(a.evidence, isNotEmpty);
      expect(a.action, isNotEmpty);
    }
  });

  test('⛔ governance · không giá trị finding nào là hằng số trong mã', () {
    // Bộ quét đọc chính engine: một chuỗi headline viết cứng ở đó là cách bản
    // demo trở thành sân khấu mà mọi test hành vi vẫn xanh.
    final code = File(
      'lib/features/tongtai/onboarding/first_insight.dart',
    ).readAsLinesSync().where((l) => !l.trimLeft().startsWith('//')).join('\n');

    expect(code, contains('class FirstInsightEngine'));
    // Con số của concept, nếu xuất hiện, chỉ có thể là số bịa chép từ ảnh.
    for (final fromConcept in const ['1.246', '328', '184', '12,4', '8,4']) {
      expect(code.contains(fromConcept), isFalse, reason: fromConcept);
    }
  });
}

/// Nguồn đọc thẳng từ repository — bản test của `RiverpodAnalysisSource`.
class _RepoSource implements AnalysisSource {
  const _RepoSource(this.products, this.orders, this.customers);

  final ProductRepository products;
  final OrderRepository orders;
  final CustomerRepository customers;

  @override
  Future<List<Product>> loadProducts() => products.loadAll();

  @override
  Future<List<CustomerOrder>> loadOrders() => orders.loadAll();

  @override
  Future<List<Customer>> loadCustomers() => customers.loadAll();

  @override
  Future<FirstInsightInput> assemble({
    required DateTime now,
    required List<Product> products,
    required List<CustomerOrder> orders,
    required List<Customer> customers,
  }) async => FirstInsightInput(
    now: now,
    products: products,
    orders: orders,
    customers: customers,
    profiles: CustomerRfmService.compute(customers, orders, now: now),
    marketplaceOrdersWithoutFees: 0,
  );
}
