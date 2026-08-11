import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/l10n/app_strings.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/agent/business_brief.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/onboarding/analysis_pipeline.dart';
import 'package:tongtai/features/tongtai/onboarding/first_plan.dart';
import 'package:tongtai/features/tongtai/onboarding/onboarding_conversation.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_agentic_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_onboarding_v2_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_profile_provider.dart';
import 'package:tongtai/features/tongtai/profile/business_profile.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_onboarding_v2_screen.dart';

import '../../../support/tap_by_key.dart';

/// Onboarding V2 — ba đường đi, trên máy thật của một test.
///
/// Ba thứ được khoá:
///
/// 1. **Đường B không bao giờ thấy màn phân tích.** Người bán chưa có đơn nào
///    không được đọc *"đang phân tích 1.246 đơn hàng"*.
/// 2. **Không nút nào mang tên một sàn.** Chưa có connector thì không có CTA.
/// 3. **One Data Path** (WTM-357): kết luận onboarding == kết luận Trang chủ
///    trên cùng dữ liệu, vì cả hai chạy cùng luật — không phải vì ai đó chép.
void main() {
  late AppDatabase db;
  OnboardingOutcome? outcome;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    outcome = null;
  });

  tearDown(() => db.close());

  Widget host() => ProviderScope(
    overrides: [tongtaiDatabaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: TongtaiOnboardingV2Screen(onDone: (o) => outcome = o),
    ),
  );

  Future<void> answerProfile(WidgetTester tester) async {
    await tester.tapByKey(
      'onboarding-v2-start',
      scrollableUnder: 'onboarding-v2-welcome',
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < kOnboardingSteps.length; i++) {
      await tester.tapByKey(
        'onboarding-v2-option-0',
        scrollableUnder: 'onboarding-v2-profile',
      );
      await tester.pumpAndSettle();
      await tester.tapByKey(
        'onboarding-v2-profile-next',
        scrollableUnder: 'onboarding-v2-profile',
      );
      await tester.pumpAndSettle();
    }
  }

  group('⛔ đường B — chưa có dữ liệu', () {
    testWidgets('không bao giờ thấy màn phân tích', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      await answerProfile(tester);

      expect(find.byKey(const Key('onboarding-v2-data')), findsOneWidget);
      await tester.tapByKey(
        'onboarding-v2-data-none',
        scrollableUnder: 'onboarding-v2-data',
      );
      await tester.pumpAndSettle();

      // Nhảy thẳng tới mục tiêu. Không phải "màn phân tích hiện rồi biến mất".
      expect(find.byKey(const Key('onboarding-v2-analysis')), findsNothing);
      expect(find.byKey(const Key('onboarding-v2-insight')), findsNothing);
      expect(find.byKey(const Key('onboarding-v2-goal')), findsOneWidget);
    });

    testWidgets('đi trọn tới kế hoạch, kế hoạch không rỗng', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      await answerProfile(tester);
      await tester.tapByKey(
        'onboarding-v2-data-none',
        scrollableUnder: 'onboarding-v2-data',
      );
      await tester.pumpAndSettle();

      await tester.tapByKey(
        'onboarding-v2-goal-grow_profit',
        scrollableUnder: 'onboarding-v2-goal',
      );
      await tester.pumpAndSettle();
      await tester.tapByKey(
        'onboarding-v2-goal-next',
        scrollableUnder: 'onboarding-v2-goal',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding-v2-plan')), findsOneWidget);
      // Giá trị của đường B đến từ LẬP KẾ HOẠCH — một màn kế hoạch rỗng ở đây
      // nghĩa là người chưa có dữ liệu nhận được đúng không gì cả.
      expect(find.byKey(const Key('onboarding-v2-plan-1')), findsOneWidget);
    });

    testWidgets('kết thúc lưu hồ sơ và mục tiêu thật', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      await answerProfile(tester);
      await tester.tapByKey(
        'onboarding-v2-data-none',
        scrollableUnder: 'onboarding-v2-data',
      );
      await tester.pumpAndSettle();
      await tester.tapByKey(
        'onboarding-v2-goal-optimize_inventory',
        scrollableUnder: 'onboarding-v2-goal',
      );
      await tester.pumpAndSettle();
      await tester.tapByKey(
        'onboarding-v2-goal-next',
        scrollableUnder: 'onboarding-v2-goal',
      );
      await tester.pumpAndSettle();
      await tester.tapByKey(
        'onboarding-v2-finish',
        scrollableUnder: 'onboarding-v2-plan',
      );
      await tester.pumpAndSettle();

      expect(outcome, isNotNull);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      final profile = await container
          .read(businessProfileRepositoryProvider)
          .load();
      expect(profile.type, BusinessType.physical);
      // ⭐ Mùa vụ vẫn được hỏi và vẫn được lưu — `SeasonalRule` ăn tín hiệu này.
      expect(profile.seasonality, isNotNull);

      final goals = await container
          .read(businessGoalRepositoryProvider)
          .loadAll();
      expect(goals, hasLength(1));
      expect(goals.single.type, GoalType.inventory);
    });

    testWidgets('"chỉ khám phá" KHÔNG tạo mục tiêu rác', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      await answerProfile(tester);
      await tester.tapByKey(
        'onboarding-v2-data-none',
        scrollableUnder: 'onboarding-v2-data',
      );
      await tester.pumpAndSettle();
      await tester.tapByKey(
        'onboarding-v2-goal-just_explore',
        scrollableUnder: 'onboarding-v2-goal',
      );
      await tester.pumpAndSettle();
      await tester.tapByKey(
        'onboarding-v2-goal-next',
        scrollableUnder: 'onboarding-v2-goal',
      );
      await tester.pumpAndSettle();
      await tester.tapByKey(
        'onboarding-v2-finish',
        scrollableUnder: 'onboarding-v2-plan',
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      // Một bản ghi mục tiêu không tên là rác người bán phải tự dọn, và nó nói
      // dối rằng họ đã cam kết điều gì đó.
      expect(
        await container.read(businessGoalRepositoryProvider).loadAll(),
        isEmpty,
      );
    });
  });

  group('⛔ không cửa nào mang tên một sàn', () {
    testWidgets('đúng ba cửa bấm được', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      await answerProfile(tester);

      for (final key in const ['csv', 'sample', 'none']) {
        expect(
          find.byKey(Key('onboarding-v2-data-$key')),
          findsOneWidget,
          reason: key,
        );
      }
      // Sàn chỉ được nhắc bằng một dòng chữ tĩnh, không nút, không logo.
      expect(
        find.byKey(const Key('onboarding-v2-data-connectors-note')),
        findsOneWidget,
      );
      for (final vendor in const ['Shopee', 'TikTok', 'Lazada', 'Shopify']) {
        expect(find.textContaining(vendor), findsNothing, reason: vendor);
      }
    });
  });

  group('⛔ không màn nào nói "hoàn tất thiết lập"', () {
    testWidgets('nút cuối mời điều hành, không mời đóng cửa sổ', (
      tester,
    ) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      await answerProfile(tester);
      await tester.tapByKey(
        'onboarding-v2-data-none',
        scrollableUnder: 'onboarding-v2-data',
      );
      await tester.pumpAndSettle();
      await tester.tapByKey(
        'onboarding-v2-goal-next',
        scrollableUnder: 'onboarding-v2-goal',
      );
      await tester.pumpAndSettle();

      // Khẳng định CHỮ HIỆN RA, không chọc vào `FilledButton.child`: nút nay
      // là `TtPrimaryButton` của Design System, và test đo cách một component
      // được dựng bên trong sẽ đỏ mỗi lần component ấy đổi mà nghĩa không đổi.
      expect(
        find.descendant(
          of: find.byKey(const Key('onboarding-v2-finish')),
          matching: find.text(const AppStringsVi().obV2PlanCta),
        ),
        findsOneWidget,
      );
    });

    testWidgets('màn đầu KHÔNG có lối đăng nhập (§16 Founder Gate)', (
      tester,
    ) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Tài khoản mâu thuẫn D-4 / Local First. Một dòng chữ dưới cái nút không
      // phải chỗ để đưa ra quyết định kiến trúc đó.
      for (final word in const ['Đăng nhập', 'đăng nhập', 'tài khoản']) {
        expect(find.textContaining(word), findsNothing, reason: word);
      }
    });
  });

  group('⭐ One Data Path — onboarding và Trang chủ cùng một luật', () {
    testWidgets('cùng dữ liệu ⇒ cùng kết luận', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );

      // Dựng một doanh nghiệp bé nhưng thật: một mặt hàng sắp hết.
      await container
          .read(productRepositoryProvider)
          .upsert(
            Product(
              id: 'p1',
              sku: 'P1',
              name: 'Áo thun',
              category: 'thời trang',
              pricePerUnit: 150000,
              costPrice: 90000,
              quantity: 1,
              reorderLevel: 10,
              updatedAt: DateTime.now(),
            ),
          );

      final pipeline = container.read(onboardingAnalysisPipelineProvider);
      AnalysisRun? run;
      await pipeline.run(now: DateTime.now(), onDone: (r) => run = r).toList();
      final fromOnboarding = run!.insight.findings
          .map((f) => f.headline)
          .toSet();

      final fromHome = (await container.read(
        businessBriefProvider.future,
      )).map((BriefItem i) => i.headline).toSet();

      expect(fromOnboarding, isNotEmpty);
      // Không phải "gần giống": onboarding phải là **tập con** của brief, vì
      // cả hai gọi đúng những luật ấy. Lệch nghĩa là một bên đã tự tính.
      expect(
        fromOnboarding.difference(fromHome),
        isEmpty,
        reason: 'onboarding kết luận thứ Trang chủ không kết luận',
      );
    });
  });

  group('kế hoạch không có lời hứa lợi nhuận', () {
    testWidgets('không dòng nào trên màn mang dấu + trước số tiền', (
      tester,
    ) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      await answerProfile(tester);
      await tester.tapByKey(
        'onboarding-v2-data-none',
        scrollableUnder: 'onboarding-v2-data',
      );
      await tester.pumpAndSettle();
      await tester.tapByKey(
        'onboarding-v2-goal-grow_revenue',
        scrollableUnder: 'onboarding-v2-goal',
      );
      await tester.pumpAndSettle();
      await tester.tapByKey(
        'onboarding-v2-goal-next',
        scrollableUnder: 'onboarding-v2-goal',
      );
      await tester.pumpAndSettle();

      final promise = RegExp(r'\+\s*[\d.,]+\s*(triệu|tr|nghìn|k|đ)');
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        final data = text.data;
        if (data == null) continue;
        expect(promise.hasMatch(data), isFalse, reason: data);
      }
    });

    test('bảng đích không có mục nào trỏ ra ngoài app', () {
      // Danh sách đóng nghĩa là một đích lạ thành lỗi biên dịch, không phải
      // một nút hỏng lúc người bán bấm.
      expect(PlanDestination.values, isNotEmpty);
      for (final d in PlanDestination.values) {
        expect(d.code, isNot(contains('http')));
      }
    });
  });
}
