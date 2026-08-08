import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/prefs.dart';
import 'package:tongtai/features/tongtai/action/business_action.dart';
import 'package:tongtai/features/tongtai/agent/automation_card.dart';
import 'package:tongtai/features/tongtai/agent/autonomy_settings.dart';
import 'package:tongtai/features/tongtai/agent/business_brief.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_agentic_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_autonomy_screen.dart';

import '../../../support/pump_until.dart';

/// WTM-306 · **mức tự động** (trải nghiệm #4) + **orchestration card** (#3).
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<ProviderContainer> pumpAutonomy(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('vi'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: [Locale('vi'), Locale('en')],
          home: TongtaiAutonomyScreen(),
        ),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('autonomy-list')));
    return container;
  }

  /// Cuộn tới khi thấy — `ListView` chỉ dựng element cho phần đang hiển thị,
  /// nên một widget nằm dưới màn hình là "không tìm thấy" chứ không phải
  /// "không tồn tại". Bẫy này làm một test đỏ oan và người ta sẽ sửa màn hình
  /// cho khớp thay vì sửa test.
  Future<void> reveal(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(finder, 250);

  // ────────────────────────────────────────────────────────────────────────
  group('Ba vùng, ba mức — bằng ngôn ngữ nghiệp vụ', () {
    testWidgets('đủ ba vùng', (tester) async {
      await pumpAutonomy(tester);
      for (final area in AutonomyArea.values) {
        final finder = find.byKey(Key('autonomy-area-${area.code}'));
        await reveal(tester, finder);
        expect(finder, findsOneWidget, reason: 'thiếu vùng ${area.code}');
      }
    });

    testWidgets('mặc định là Gợi ý — trợ lý mới thì NÓI, không xin làm', (
      tester,
    ) async {
      final container = await pumpAutonomy(tester);
      final settings = container.read(autonomySettingsProvider);
      for (final area in AutonomyArea.values) {
        expect(settings.modeOf(area), AutonomyMode.suggest);
      }
    });

    testWidgets('chọn mức và mức được ghi lại', (tester) async {
      final container = await pumpAutonomy(tester);
      await tester.tap(find.byKey(const Key('autonomy-customer_care-confirm')));
      await tester.pumpAndSettle();

      expect(
        container
            .read(autonomySettingsProvider)
            .modeOf(AutonomyArea.customerCare),
        AutonomyMode.confirm,
      );
      // Ghi xuống đĩa, không chỉ vào bộ nhớ — mức tự chủ phải sống qua một
      // lần tắt app.
      expect(prefs.getString('tongtai.autonomy.v1'), contains('confirm'));
    });

    testWidgets('mở lại app thấy đúng mức đã chọn', (tester) async {
      await prefs.setString('tongtai.autonomy.v1', '{"inventory":"confirm"}');
      final container = await pumpAutonomy(tester);
      expect(
        container.read(autonomySettingsProvider).modeOf(AutonomyArea.inventory),
        AutonomyMode.confirm,
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('⛔ Việc luôn-hỏi hiện ra, và Tự động KHÔNG chọn được ở đâu cấm', () {
    testWidgets('khối "Luôn hỏi bạn" liệt kê đúng việc bị cấm', (tester) async {
      await pumpAutonomy(tester);
      expect(
        find.byKey(const Key('autonomy-always-ask-customer_care')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('autonomy-locked-customer.send_cold_message')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('autonomy-locked-product.update_price')),
        findsOneWidget,
      );
    });

    testWidgets('⭐ bấm Tự động ở vùng không có gì tự chạy ⇒ KHÔNG đổi', (
      tester,
    ) async {
      // Kho: mọi việc auto được đều... không có. Cả `orderAboveLimit` lẫn
      // `updatePrice` đều bị cấm, chỉ còn `createPurchaseOrder`.
      final blocked = AutonomyArea.values.where((a) => !a.offersAuto).toList();
      if (blocked.isEmpty) return; // không có vùng nào như vậy hôm nay

      final container = await pumpAutonomy(tester);
      final area = blocked.first;
      await reveal(tester, find.byKey(Key('autonomy-${area.code}-auto')));
      await tester.tap(find.byKey(Key('autonomy-${area.code}-auto')));
      await tester.pumpAndSettle();

      expect(
        container.read(autonomySettingsProvider).modeOf(area),
        isNot(AutonomyMode.auto),
      );
      final note = find.byKey(Key('autonomy-no-auto-${area.code}'));
      await reveal(tester, note);
      expect(note, findsOneWidget);
    });

    testWidgets('Tự động mang nhãn XEM TRƯỚC ở mọi vùng mời chọn nó', (
      tester,
    ) async {
      await pumpAutonomy(tester);
      for (final area in AutonomyArea.values) {
        if (!area.offersAuto) continue;
        final finder = find.byKey(Key('autonomy-preview-${area.code}'));
        await reveal(tester, finder);
        expect(
          finder,
          findsOneWidget,
          reason: '${area.code}: Tự động chưa chạy thật, phải nói ra',
        );
      }
    });

    testWidgets('bật Tự động ⇒ hiện lời giải thích chưa chạy thật', (
      tester,
    ) async {
      final auto = AutonomyArea.values.where((a) => a.offersAuto).first;
      await pumpAutonomy(tester);
      await reveal(tester, find.byKey(Key('autonomy-${auto.code}-auto')));
      await tester.tap(find.byKey(Key('autonomy-${auto.code}-auto')));
      await tester.pumpAndSettle();

      final notice = find.byKey(Key('autonomy-preview-notice-${auto.code}'));
      await reveal(tester, notice);
      expect(notice, findsOneWidget);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('⭐ Trải nghiệm #3 — sáu dòng, và một dòng ĐỔI theo công tắc', () {
    testWidgets('thẻ orchestration có đủ sáu dòng', (tester) async {
      await pumpAutonomy(tester);
      for (final label in [
        'when',
        'if',
        'think',
        'approval',
        'do',
        'observe',
      ]) {
        final finder = find.byKey(Key('autonomy-example-$label'));
        await reveal(tester, finder);
        expect(finder, findsOneWidget, reason: 'thiếu dòng $label');
      }
    });

    testWidgets('⭐ gạt công tắc ⇒ dòng APPROVAL đổi ngay', (tester) async {
      // Đây là chỗ chứng minh cho người bán rằng công tắc thật sự nối vào cái
      // gì — thay vì phải tin rằng có gì đó đã đổi ở đâu đó.
      await pumpAutonomy(tester);
      await reveal(tester, find.byKey(const Key('autonomy-example-approval')));
      expect(find.text('Tôi chỉ gợi ý, bạn tự làm'), findsOneWidget);

      // Cuộn NGƯỢC về đầu: `scrollUntilVisible` chỉ kéo một chiều, nên sau
      // khi xuống tới thẻ orchestration thì công tắc đã nằm trên viewport.
      await tester.drag(
        find.byKey(const Key('autonomy-list')),
        const Offset(0, 2000),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('autonomy-customer_care-confirm')));
      await tester.pumpAndSettle();

      await reveal(tester, find.byKey(const Key('autonomy-example-approval')));
      expect(find.text('Hỏi bạn trước khi làm'), findsOneWidget);
      expect(find.text('Tôi chỉ gợi ý, bạn tự làm'), findsNothing);
    });

    testWidgets('KHÔNG lộ hạ tầng ra thẻ (Task Order §8)', (tester) async {
      await pumpAutonomy(tester);
      for (final banned in [
        'n8n',
        'webhook',
        'JSON',
        'correlationId',
        'AgentTask',
        'BusinessAction',
        '_table',
        'scheduleRecheck',
      ]) {
        expect(
          find.textContaining(banned),
          findsNothing,
          reason: 'thẻ lộ "$banned"',
        );
      }
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Thẻ orchestration là hàm thuần trên loại việc', () {
    test('mỗi loại việc có đủ sáu dòng, không dòng nào rỗng', () {
      for (final kind in BriefKind.values) {
        final card = AutomationCard.forKind(kind);
        expect(card.lines, hasLength(6), reason: kind.code);
        for (final (label, text) in card.lines) {
          expect(text, isNotEmpty, reason: '${kind.code}/$label rỗng');
        }
      }
    });

    test('việc chỉ để biết KHÔNG hứa sẽ làm gì', () {
      final card = AutomationCard.forKind(BriefKind.businessSignal);
      expect(card.approval, 'Bạn xem rồi tự quyết');
      expect(card.act, 'Chỉ báo cho bạn biết');
    });

    test('⭐ mức tự chủ đổi ĐÚNG dòng APPROVAL, không đổi dòng nào khác', () {
      final quiet = AutomationCard.forKind(BriefKind.customerAtRisk);
      final loud = AutomationCard.forKind(
        BriefKind.customerAtRisk,
        settings: const AutonomySettings().withMode(
          AutonomyArea.customerCare,
          AutonomyMode.confirm,
        ),
      );
      expect(quiet.approval, isNot(loud.approval));
      expect(quiet.when, loud.when);
      expect(quiet.act, loud.act);
      expect(quiet.observe, loud.observe);
    });

    test('việc bị cấm auto KHÔNG bao giờ nói "tôi tự làm"', () {
      // `productUpdatePrice` nằm trong danh sách cấm. Dù người bán bật Tự động
      // cho cả vùng Kho, câu trên thẻ vẫn phải nói đúng thứ sẽ xảy ra.
      final card = AutomationCard.forKind(
        BriefKind.marginTooThin,
        settings: AutonomySettings(
          modes: {AutonomyArea.inventory: AutonomyMode.auto},
        ),
      );
      expect(card.approval, 'Hỏi bạn trước khi làm');
    });
  });
}
