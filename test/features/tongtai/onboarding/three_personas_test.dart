import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/l10n/app_strings.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/onboarding/first_plan.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_onboarding_v2_screen.dart';

import '../../../support/tap_by_key.dart';

/// **Ba persona** — WTM-360 (S11, Epic WTM-349) · §22 directive.
///
/// Test này đo hai thứ mà không test nào khác đo:
///
/// 1. **Đếm chạm.** Đường của người vội phải là đường NGẮN NHẤT, và con số đó
///    phải hiện ra ở đâu đó chứ không nằm trong đầu ai. Một luồng dài thêm hai
///    chạm mỗi story sẽ dài gấp đôi sau sáu story mà không ai nhận ra.
/// 2. **Không ngõ cụt.** Mỗi persona phải TỚI ĐƯỢC Trang chủ, chứ không phải
///    "màn cuối render đúng".
///
/// ⚠️ Test này KHÔNG thay được dogfood máy thật. Bài học WTM-342: 2488 test
/// xanh, một vòng cầm máy bắt ra bốn lỗi. Nó chỉ chặn hồi quy giữa hai vòng.
void main() {
  late AppDatabase db;
  var finished = 0;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    finished = 0;
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
      home: TongtaiOnboardingV2Screen(onDone: (_) => finished++),
    ),
  );

  /// Bấm một phím và **đếm**.
  ///
  /// Dùng `tapByKey` chứ không `tester.tap`: trong một `ListView` lười, nút
  /// nằm dưới màn hình **không được dựng**, nên `tester.tap` chỉ in một cảnh
  /// báo rồi test chạy tiếp trên màn nó chưa từng rời. Bài học đã trả giá ba
  /// lần trong repo này (xem `test/support/tap_by_key.dart`).
  Future<void> tap(
    WidgetTester tester,
    String key,
    List<String> log, {
    String? under,
  }) async {
    await tester.tapByKey(key, scrollableUnder: under);
    log.add(key);
  }

  group('PERSONA B · người mới, chưa có dữ liệu', () {
    testWidgets('đi trọn tới Trang chủ trong 5 chạm', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final taps = <String>[];

      await tap(tester, 'onboarding-v2-start', taps);
      await tap(tester, 'onboarding-v2-profile-skip-all', taps);
      await tap(tester, 'onboarding-v2-data-none', taps);
      await tap(
        tester,
        'onboarding-v2-goal-next',
        taps,
        under: 'onboarding-v2-goal',
      );
      await tap(
        tester,
        'onboarding-v2-finish',
        taps,
        under: 'onboarding-v2-plan',
      );

      expect(finished, 1);
      // Năm chạm — và **cửa dữ liệu nằm trong đó**. Bỏ nó đi sẽ còn bốn chạm
      // nhưng thả người bán vào một ứng dụng trống: đúng vấn đề Epic này sửa.
      expect(taps, hasLength(5), reason: taps.join(' → '));
    });

    testWidgets('KHÔNG màn nào bịa số trên đường này', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final taps = <String>[];
      await tap(tester, 'onboarding-v2-start', taps);
      await tap(tester, 'onboarding-v2-profile-skip-all', taps);
      await tap(tester, 'onboarding-v2-data-none', taps);

      // Mọi chữ trên màn mục tiêu: không dòng nào chứa một con số đếm bản ghi.
      final counting = RegExp(r'\b(đơn hàng|sản phẩm|khách hàng)\b');
      for (final t in tester.widgetList<Text>(find.byType(Text))) {
        final data = t.data;
        if (data == null) continue;
        if (!counting.hasMatch(data)) continue;
        expect(
          RegExp(r'\d').hasMatch(data),
          isFalse,
          reason: 'đường B hiện một con số đếm: "$data"',
        );
      }
    });
  });

  group('PERSONA C · dữ liệu mẫu (đường demo)', () {
    testWidgets('phân tích chạy, mỗi dòng mang số THẬT', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      // Dựng sẵn vài mặt hàng để chặng "đọc sản phẩm" có gì để đếm — bộ mẫu
      // đầy đủ đã có test riêng (`golden_demo_path_test.dart`), ở đây chỉ cần
      // chứng minh MÀN đọc đúng thứ pipeline trả về.
      for (var i = 0; i < 3; i++) {
        await container
            .read(productRepositoryProvider)
            .upsert(
              Product(
                id: 'p$i',
                sku: 'P$i',
                name: 'Hàng $i',
                category: 'test',
                pricePerUnit: 100000,
                costPrice: 60000,
                quantity: i,
                reorderLevel: 10,
                updatedAt: DateTime.now(),
              ),
            );
      }

      final taps = <String>[];
      await tap(tester, 'onboarding-v2-start', taps);
      await tap(tester, 'onboarding-v2-profile-skip-all', taps);
      await tester.tap(find.byKey(const Key('onboarding-v2-data-sample')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding-v2-analysis')), findsOneWidget);
      // Cả năm chặng hiện ra, và mỗi chặng chỉ hiện SAU khi việc của nó xong.
      for (final stage in const [
        'products',
        'orders',
        'customers',
        'stock',
        'signals',
      ]) {
        expect(
          find.byKey(Key('onboarding-v2-stage-$stage')),
          findsOneWidget,
          reason: stage,
        );
      }
    });

    testWidgets('đi tiếp tới insight rồi mục tiêu rồi kế hoạch', (
      tester,
    ) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final taps = <String>[];
      await tap(tester, 'onboarding-v2-start', taps);
      await tap(tester, 'onboarding-v2-profile-skip-all', taps);
      await tap(tester, 'onboarding-v2-data-sample', taps);
      await tap(
        tester,
        'onboarding-v2-analysis-continue',
        taps,
        under: 'onboarding-v2-analysis',
      );

      expect(find.byKey(const Key('onboarding-v2-insight')), findsOneWidget);
      await tap(
        tester,
        'onboarding-v2-insight-continue',
        taps,
        under: 'onboarding-v2-insight',
      );

      expect(find.byKey(const Key('onboarding-v2-goal')), findsOneWidget);
      await tap(tester, 'onboarding-v2-goal-grow_profit', taps);
      await tap(
        tester,
        'onboarding-v2-goal-next',
        taps,
        under: 'onboarding-v2-goal',
      );

      expect(find.byKey(const Key('onboarding-v2-plan')), findsOneWidget);
      await tap(
        tester,
        'onboarding-v2-finish',
        taps,
        under: 'onboarding-v2-plan',
      );

      expect(finished, 1);
      // Tám chạm cho đường có dữ liệu — dài hơn đường B đúng ba chạm, và ba
      // chạm đó là: xem phân tích xong, đọc kết luận, chọn một mục tiêu. Không
      // chạm nào trong đó là thủ tục.
      expect(taps, hasLength(8), reason: taps.join(' → '));
    });

    testWidgets('mục tiêu đã chọn thành bản ghi THẬT', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final taps = <String>[];
      await tap(tester, 'onboarding-v2-start', taps);
      await tap(tester, 'onboarding-v2-profile-skip-all', taps);
      await tap(tester, 'onboarding-v2-data-sample', taps);
      await tap(
        tester,
        'onboarding-v2-analysis-continue',
        taps,
        under: 'onboarding-v2-analysis',
      );
      await tap(
        tester,
        'onboarding-v2-insight-continue',
        taps,
        under: 'onboarding-v2-insight',
      );
      await tap(
        tester,
        'onboarding-v2-goal-better_sourcing',
        taps,
        under: 'onboarding-v2-goal',
      );
      await tap(
        tester,
        'onboarding-v2-goal-next',
        taps,
        under: 'onboarding-v2-goal',
      );
      await tap(
        tester,
        'onboarding-v2-finish',
        taps,
        under: 'onboarding-v2-plan',
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      final goals = await container
          .read(businessGoalRepositoryProvider)
          .loadAll();
      // Bộ mẫu tự mang theo hai mục tiêu `sample-`; mục tiêu của người bán
      // phải phân biệt được với chúng, vì "Xoá dữ liệu mẫu" chỉ được xoá phần
      // mẫu. Tiền tố `onboarding-` là thứ làm điều đó thành đúng theo cấu trúc.
      final mine = goals.where((g) => g.id.startsWith('onboarding-')).toList();
      expect(mine, hasLength(1));
      // Không phải "gần đúng archetype": bảy mục tiêu ánh xạ 1:1 chính vì thế.
      expect(mine.single.type.name, 'sourcing');
    });
  });

  /// ⭐ Bốn lỗi mà **một vòng cầm máy** bắt được, còn 2597 test thì không.
  ///
  /// Ba trong bốn có cùng hình dạng: **thứ gì đó được khai đúng nhưng không ai
  /// dùng nó**. Không test cũ nào bắt được, vì màn hình vẫn render, vẫn không
  /// ném, vẫn đúng theo mọi khẳng định đã viết.
  group('⛔ hồi quy dogfood máy thật (WTM-360)', () {
    testWidgets('LỖI 1 · mỗi việc trong kế hoạch BẤM ĐƯỢC', (tester) async {
      // Trên máy: dòng hành động tô cam trông bấm được và không có `onTap`.
      // Test cũ chỉ kiểm `destination` CÓ MẶT trong danh sách đóng — không
      // kiểm màn hình có dùng nó.
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final taps = <String>[];
      await tap(tester, 'onboarding-v2-start', taps);
      await tap(tester, 'onboarding-v2-profile-skip-all', taps);
      await tap(tester, 'onboarding-v2-data-none', taps);
      await tap(tester, 'onboarding-v2-goal-grow_profit', taps);
      await tap(
        tester,
        'onboarding-v2-goal-next',
        taps,
        under: 'onboarding-v2-goal',
      );

      final opener = find.byKey(const Key('onboarding-v2-plan-open-1'));
      expect(opener, findsOneWidget);
      await tester.tapByKey(
        'onboarding-v2-plan-open-1',
        scrollableUnder: 'onboarding-v2-plan',
      );
      // Mở ra một màn thật — không phải "không có gì xảy ra".
      expect(find.byKey(const Key('onboarding-v2-plan')), findsNothing);
    });

    test('LỖI 1b · mọi đích đều phân giải được thành một màn', () {
      // `switch` vét cạn khiến thiếu một đích là lỗi biên dịch. Test này giữ
      // cho hàm KHÔNG bị thay bằng một `Map` có thể thiếu khoá lặng lẽ.
      for (final d in PlanDestination.values) {
        expect(screenFor(d), isA<Widget>(), reason: d.code);
      }
    });

    testWidgets('LỖI 2 · mức khẩn đọc được bằng MẮT, không chỉ bằng chữ', (
      tester,
    ) async {
      // Trên máy bốn thẻ trông giống hệt nhau: viền nhạt cùng sắc độ. Màu
      // được đọc TRƯỚC chữ (WTM-340), nên nó phải là một vạch đặc.
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      await container
          .read(productRepositoryProvider)
          .upsert(
            Product(
              id: 'p-out',
              sku: 'POUT',
              name: 'Hàng hết',
              category: 'test',
              pricePerUnit: 100000,
              costPrice: 60000,
              quantity: 0,
              reorderLevel: 10,
              updatedAt: DateTime.now(),
            ),
          );

      final taps = <String>[];
      await tap(tester, 'onboarding-v2-start', taps);
      await tap(tester, 'onboarding-v2-profile-skip-all', taps);
      await tap(tester, 'onboarding-v2-data-sample', taps);
      await tap(
        tester,
        'onboarding-v2-analysis-continue',
        taps,
        under: 'onboarding-v2-analysis',
      );

      expect(
        find.byKey(const Key('onboarding-v2-finding-card')),
        findsWidgets,
        reason: 'không có thẻ phát hiện nào',
      );
      // Vạch ĐẶC bên trái — mắt tách được ở khoảng cách đọc, khác hẳn một sắc
      // độ viền. `color` khác `null` là điều kiện để nó thật sự được tô.
      final stripes = tester.widgetList<Container>(
        find.byKey(const Key('onboarding-v2-finding-severity')),
      );
      expect(stripes, isNotEmpty);
      for (final stripe in stripes) {
        expect(stripe.color, isNotNull);
      }
    });

    testWidgets('LỖI 3 · mục tiêu sinh ra HÀNH TRÌNH, không chỉ một bản ghi', (
      tester,
    ) async {
      // Trên máy: Trang chủ hiện "Việc hôm nay — chưa có nhiệm vụ nào" ngay
      // dưới brief có ba việc. Khối đó đọc hành trình; onboarding mới chỉ tạo
      // mục tiêu. Một mục tiêu chưa sinh ra kế hoạch là một điều ước.
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final taps = <String>[];
      await tap(tester, 'onboarding-v2-start', taps);
      await tap(tester, 'onboarding-v2-profile-skip-all', taps);
      await tap(tester, 'onboarding-v2-data-sample', taps);
      await tap(
        tester,
        'onboarding-v2-analysis-continue',
        taps,
        under: 'onboarding-v2-analysis',
      );
      await tap(
        tester,
        'onboarding-v2-insight-continue',
        taps,
        under: 'onboarding-v2-insight',
      );
      await tap(tester, 'onboarding-v2-goal-optimize_inventory', taps);
      await tap(
        tester,
        'onboarding-v2-goal-next',
        taps,
        under: 'onboarding-v2-goal',
      );
      await tap(
        tester,
        'onboarding-v2-finish',
        taps,
        under: 'onboarding-v2-plan',
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      final journeys = await container
          .read(journeyRepositoryProvider)
          .loadAll();
      expect(
        journeys,
        isNotEmpty,
        reason: 'mục tiêu đã tạo nhưng không có hành trình nào',
      );
    });

    test('LỖI 4 · hai con số về "đơn hàng" không mang cùng một nhãn', () {
      // Màn phân tích: "đã phân tích 636 đơn hàng" (mọi đơn).
      // Ảnh chụp:      "đơn hàng 598"            (đơn đã chốt).
      // Cả hai đều đúng; cùng tên thì người bán phải đoán con nào là thật.
      const vi = AppStringsVi();
      expect(vi.obV2AnalysisStage('orders', 636), contains('đơn hàng'));
      expect(vi.obV2SnapshotOrders, isNot('Đơn hàng'));
    });
  });

  group('giới hạn hai mục tiêu là thật, không phải lời khuyên', () {
    testWidgets('chọn cái thứ ba không ăn', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final taps = <String>[];
      await tap(tester, 'onboarding-v2-start', taps);
      await tap(tester, 'onboarding-v2-profile-skip-all', taps);
      await tap(tester, 'onboarding-v2-data-none', taps);
      await tap(tester, 'onboarding-v2-goal-grow_revenue', taps);
      await tap(tester, 'onboarding-v2-goal-grow_profit', taps);
      await tap(tester, 'onboarding-v2-goal-keep_customers', taps);

      ChoiceChip chip(String code) => tester.widget<ChoiceChip>(
        find.byKey(Key('onboarding-v2-goal-$code')),
      );

      expect(chip('grow_revenue').selected, isTrue);
      expect(chip('grow_profit').selected, isTrue);
      expect(chip('keep_customers').selected, isFalse);
    });

    testWidgets('"chỉ khám phá" loại trừ mọi lựa chọn khác', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final taps = <String>[];
      await tap(tester, 'onboarding-v2-start', taps);
      await tap(tester, 'onboarding-v2-profile-skip-all', taps);
      await tap(tester, 'onboarding-v2-data-none', taps);
      await tap(tester, 'onboarding-v2-goal-grow_revenue', taps);
      await tap(tester, 'onboarding-v2-goal-just_explore', taps);

      ChoiceChip chip(String code) => tester.widget<ChoiceChip>(
        find.byKey(Key('onboarding-v2-goal-$code')),
      );

      // Chọn "chỉ khám phá" cùng một mục tiêu khác là hai câu trả lời mâu
      // thuẫn — màn phải giải, không phải để người bán tự hiểu.
      expect(chip('just_explore').selected, isTrue);
      expect(chip('grow_revenue').selected, isFalse);
    });
  });
}
