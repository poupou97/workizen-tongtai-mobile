import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/journey/journey.dart';
import 'package:tongtai/features/tongtai/journey/journey_node.dart';
import 'package:tongtai/features/tongtai/producer/business_input.dart';
import 'package:tongtai/features/tongtai/producer/business_input_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_business_inputs_screen.dart';

import '../../../support/pump_until.dart';

/// WTM-234 / ADR-TON-023 — người bán GHI được nguồn đầu vào.
///
/// WTM-229/230 dựng model + repository + `.ttbk`, nhưng không màn nào ghi được
/// một nguồn: capability tồn tại trong code mà không tồn tại với người bán —
/// hình dạng WTM-218 (màn mồ côi) lật ngược.
void main() {
  BusinessInput input({
    required String id,
    required String name,
    BusinessInputKind kind = BusinessInputKind.provider,
    InputCadence? cadence,
    double? amount,
  }) => BusinessInput(
    id: id,
    name: name,
    kind: kind,
    cadence: cadence,
    expectedAmount: amount,
  );

  Future<void> pumpScreen(
    WidgetTester tester,
    BusinessInputRepository repository, {
    Journey? journey,
  }) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(500, 2400);
    await tester.pumpWidget(
      ProviderScope(
        // Hành trình là một nguồn thật của màn này (WTM-235), nên test khai nó
        // ra chứ không để màn tự rẽ nhánh "đang test thì bỏ qua".
        overrides: [activeJourneyProvider.overrideWith((ref) async => journey)],
        child: MaterialApp(
          home: TongtaiBusinessInputsScreen(
            repository: repository,
            clock: () => DateTime(2026, 8, 2),
            idFactory: () => 'new-input',
          ),
        ),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('inputs-header')));
  }

  testWidgets('tổng cam kết đi CÙNG phần nó chưa biết', (tester) async {
    // Một tổng không tự khai mình thiếu gì sẽ được đọc như một tổng đầy đủ —
    // cùng kỷ luật `null ≠ 0`, áp cho một phép cộng thay vì một trường.
    final repository = InMemoryBusinessInputRepository([
      input(
        id: 'firebase',
        name: 'Firebase',
        kind: BusinessInputKind.infrastructure,
        cadence: InputCadence.monthly,
        amount: 500000,
      ),
      // Có tiền nhưng KHÔNG phải cam kết: token AI có thể bằng 0 vào tháng
      // người bán không dùng gì.
      input(
        id: 'grok',
        name: 'xAI / Grok',
        cadence: InputCadence.usageBased,
        amount: 2000000,
      ),
      // Chưa khai nhịp lẫn tiền.
      input(id: 'domain', name: 'Tên miền'),
    ]);

    await pumpScreen(tester, repository);
    await pumpUntilFound(
      tester,
      find.byKey(const Key('inputs-summary-commitment')),
    );

    final unknown = tester.widget<Text>(
      find.byKey(const Key('inputs-summary-unknown')),
    );
    expect(unknown.data, contains('2'));

    // Nguồn không góp vào tổng phải nói "chưa tính", KHÔNG phải "0 ₫" — 0 nói
    // nguồn đó miễn phí.
    final grok = tester.widget<Text>(
      find.byKey(const Key('inputs-item-grok-monthly')),
    );
    expect(grok.data, isNot(contains('0')));
  });

  testWidgets('thêm một nguồn qua form thì nó được LƯU và hiện ra', (
    tester,
  ) async {
    final repository = InMemoryBusinessInputRepository();
    await pumpScreen(tester, repository);
    await pumpUntilFound(tester, find.byKey(const Key('inputs-empty')));

    await tester.tap(find.byKey(const Key('inputs-action-add')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('input-name-field')),
      'Firebase',
    );
    await tester.tap(find.byKey(const Key('input-kind-infrastructure')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('input-cadence-monthly')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('input-amount-field')),
      '500000',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('input-save-button')));
    await tester.pumpAndSettle();

    final saved = await repository.loadAll();
    expect(saved, hasLength(1));
    expect(saved.single.name, 'Firebase');
    expect(saved.single.kind, BusinessInputKind.infrastructure);
    expect(saved.single.monthlyCommitment, 500000);
    await pumpUntilFound(
      tester,
      find.byKey(const Key('inputs-item-new-input')),
    );
  });

  testWidgets('bỏ trống số tiền ⇒ "chưa nhập", KHÔNG phải 0 đồng', (
    tester,
  ) async {
    // Người bán vừa nhớ ra mình trả tiền Firebase thường chưa biết chính xác
    // bao nhiêu. Ghi 0 sẽ nói nguồn đó miễn phí và làm tổng cam kết trông đủ.
    final repository = InMemoryBusinessInputRepository();
    await pumpScreen(tester, repository);
    await pumpUntilFound(tester, find.byKey(const Key('inputs-empty')));

    await tester.tap(find.byKey(const Key('inputs-action-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('input-name-field')),
      'Tên miền',
    );
    await tester.tap(find.byKey(const Key('input-save-button')));
    await tester.pumpAndSettle();

    final saved = (await repository.loadAll()).single;
    expect(saved.expectedAmount, isNull);
    expect(saved.cadence, isNull);
    expect(saved.monthlyCommitment, isNull);
  });

  testWidgets('không có tên thì không lưu — và nói vì sao', (tester) async {
    final repository = InMemoryBusinessInputRepository();
    await pumpScreen(tester, repository);
    await pumpUntilFound(tester, find.byKey(const Key('inputs-empty')));

    await tester.tap(find.byKey(const Key('inputs-action-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('input-save-button')));
    await tester.pumpAndSettle();

    expect(await repository.loadAll(), isEmpty);
    expect(
      find.byKey(const Key('input-name-field')),
      findsOneWidget,
      reason: 'form phải ở lại để người bán sửa, không im lặng đóng',
    );
  });

  testWidgets('bấm lại nhịp đang chọn = quay về "chưa biết"', (tester) async {
    // Không quay lại được thì một lần bấm nhầm sẽ khoá người bán vào một con
    // số cam kết họ không đứng sau.
    final repository = InMemoryBusinessInputRepository();
    await pumpScreen(tester, repository);
    await pumpUntilFound(tester, find.byKey(const Key('inputs-empty')));

    await tester.tap(find.byKey(const Key('inputs-action-add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('input-name-field')), 'Vercel');
    await tester.tap(find.byKey(const Key('input-cadence-monthly')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('input-cadence-monthly')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('input-save-button')));
    await tester.pumpAndSettle();

    expect((await repository.loadAll()).single.cadence, isNull);
  });

  testWidgets('sửa một nguồn không tạo ra nguồn thứ hai', (tester) async {
    final repository = InMemoryBusinessInputRepository([
      input(
        id: 'firebase',
        name: 'Firebase',
        cadence: InputCadence.monthly,
        amount: 500000,
      ),
    ]);
    await pumpScreen(tester, repository);
    await pumpUntilFound(tester, find.byKey(const Key('inputs-item-firebase')));

    await tester.tap(find.byKey(const Key('inputs-item-firebase')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('input-name-field')),
      'Firebase Blaze',
    );
    await tester.tap(find.byKey(const Key('input-save-button')));
    await tester.pumpAndSettle();

    final saved = await repository.loadAll();
    expect(saved, hasLength(1), reason: 'sửa phải ghi đè, không thêm dòng mới');
    expect(saved.single.name, 'Firebase Blaze');
    expect(saved.single.id, 'firebase');
  });

  testWidgets('xoá một nguồn thì nó biến mất khỏi cả kho lẫn màn hình', (
    tester,
  ) async {
    final repository = InMemoryBusinessInputRepository([
      input(id: 'firebase', name: 'Firebase'),
    ]);
    await pumpScreen(tester, repository);
    await pumpUntilFound(tester, find.byKey(const Key('inputs-item-firebase')));

    await tester.tap(find.byKey(const Key('inputs-item-firebase-delete')));
    await tester.pumpAndSettle();

    expect(await repository.loadAll(), isEmpty);
    await pumpUntilFound(tester, find.byKey(const Key('inputs-empty')));
  });

  Journey journeyWith(JourneyNode node) => Journey(
    id: 'j1',
    goalId: 'g1',
    state: JourneyState.active,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
    nodes: [node],
  );

  JourneyNode inputStep({
    JourneyNodeState state = JourneyNodeState.pending,
    String metric = 'inputs',
  }) => JourneyNode(
    id: 'n1',
    journeyId: 'j1',
    kind: JourneyNodeKind.step,
    title: 'Khai 3 khoản bạn trả đều đặn',
    origin: JourneyNodeOrigin.ruleTwin,
    state: state,
    derivedMetric: metric,
  );

  group('nhịp 5 — biết việc tiếp theo NGAY TẠI CHỖ vừa làm việc', () {
    testWidgets('bước hành trình về đầu vào hiện thường trực trên màn', (
      tester,
    ) async {
      // Đọc từ Journey (SSoT), không phải một trạng thái thứ hai màn tự giữ;
      // và là khối thường trực, không phải Snackbar (luật Founder).
      await pumpScreen(
        tester,
        InMemoryBusinessInputRepository(),
        journey: journeyWith(inputStep()),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const Key('inputs-journey-step')),
      );

      expect(find.text('Khai 3 khoản bạn trả đều đặn'), findsOneWidget);
      expect(find.byKey(const Key('inputs-open-journey')), findsOneWidget);
    });

    testWidgets('bước đã xong thì KHÔNG nhắc nữa', (tester) async {
      await pumpScreen(
        tester,
        InMemoryBusinessInputRepository(),
        journey: journeyWith(inputStep(state: JourneyNodeState.done)),
      );
      await pumpUntilFound(tester, find.byKey(const Key('inputs-empty')));

      expect(find.byKey(const Key('inputs-journey-step')), findsNothing);
    });

    testWidgets('bước của capability KHÁC không lạc sang đây', (tester) async {
      // Hành trình luôn có bước về khách hàng/tồn kho; hiện chúng ở màn này
      // là mời người bán làm sai việc.
      await pumpScreen(
        tester,
        InMemoryBusinessInputRepository(),
        journey: journeyWith(inputStep(metric: 'customers')),
      );
      await pumpUntilFound(tester, find.byKey(const Key('inputs-empty')));

      expect(find.byKey(const Key('inputs-journey-step')), findsNothing);
    });
  });
}
