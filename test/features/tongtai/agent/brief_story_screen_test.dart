import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/action/business_action.dart';
import 'package:tongtai/features/tongtai/action/business_action_executor.dart';
import 'package:tongtai/features/tongtai/action/demo_action_handlers.dart';
import 'package:tongtai/features/tongtai/agent/agent_task_queue.dart';
import 'package:tongtai/features/tongtai/agent/brief_inbox.dart';
import 'package:tongtai/features/tongtai/agent/business_brief.dart';
import 'package:tongtai/features/tongtai/consumer/identity_evidence.dart';
import 'package:tongtai/features/tongtai/proposal/proposed_change.dart';
import 'package:tongtai/features/tongtai/proposal/proposed_change_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_agentic_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_brief_story_screen.dart';

import '../../../support/pump_until.dart';

/// WTM-305 · **Business Story** — trải nghiệm #2.
///
/// Chạy trên cơ sở dữ liệu **thật** (bộ nhớ): cả điểm của màn này là ba nút
/// bấm ra bản ghi thật, nên một hộp việc giả sẽ chứng minh đúng con số không.
void main() {
  late AppDatabase db;
  late BriefInbox inbox;
  var seq = 0;
  final clock = DateTime(2026, 8, 8, 9);

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    seq = 0;
    inbox = BriefInbox(
      proposals: DriftProposedChangeRepository(db, now: () => clock),
      actions: BusinessActionExecutor(
        db,
        now: () => clock,
        handlers: demoActionHandlers,
      ),
      tasks: AgentTaskQueue(db, now: () => clock, newId: () => 't${++seq}'),
    );
    await db.customStatement(
      "INSERT INTO users_table (id, email, name, language, created_at, "
      "updated_at) VALUES ('u', 'a@b.c', 'Tôi', 'vi', 1, 1)",
    );
    await db.customStatement(
      "INSERT INTO businesses_table (id, owner_id, name, created_at, "
      "updated_at) VALUES ('tongtai-local-business', 'u', 'Shop', 1, 1)",
    );
    await db.customStatement(
      "INSERT INTO products_table (id, business_id, sku, name, list_price, "
      "cost_per_unit, updated_at, created_at) VALUES "
      "('prod-1', 'tongtai-local-business', 'SKU-1', 'Nồi chiên', 100000, "
      "95000, 1, 1)",
    );
  });
  tearDown(() => db.close());

  BriefItem messageItem() => BriefItem(
    kind: BriefKind.customerAtRisk,
    severity: BriefSeverity.warning,
    subjectKind: 'customer',
    subjectId: 'cust-1',
    subjectLabel: 'Chị Phương',
    headline: 'Chị Phương đã 45 ngày chưa quay lại',
    suggestion: 'Nhắn hỏi thăm và gợi ý mặt hàng họ hay mua',
    evidence: const [
      IdentityEvidence(
        kind: IdentityEvidenceKind.orderHistoryMatch,
        source: 'rule:customer-risk',
        detail: 'Đã mua 8 lần',
      ),
      IdentityEvidence(
        kind: IdentityEvidenceKind.orderHistoryMatch,
        source: 'rule:customer-risk',
        detail: 'Lần mua gần nhất cách đây 45 ngày',
      ),
    ],
    move: const DoSomething(
      actionType: BusinessActionType.customerSendMessage,
      vendor: ActionVendor.demo,
    ),
    observedAt: DateTime(2026, 8, 8, 9),
  );

  BriefItem priceItem() => BriefItem(
    kind: BriefKind.marginTooThin,
    severity: BriefSeverity.critical,
    subjectKind: 'product',
    subjectId: 'prod-1',
    subjectLabel: 'Nồi chiên',
    headline: 'Nồi chiên chỉ còn 5% lãi',
    suggestion: 'Cân nhắc nâng giá bán lên 112.000 ₫',
    evidence: const [
      IdentityEvidence(
        kind: IdentityEvidenceKind.businessRecordObservation,
        source: 'rule:margin',
        detail: 'Giá bán 100.000 ₫',
      ),
    ],
    move: const ChangeAFact(
      domain: ProposalDomain.pricing,
      field: 'pricePerUnit',
      currentValue: '100000',
      proposedValue: '112000',
    ),
    observedAt: DateTime(2026, 8, 8, 9),
  );

  BriefItem infoItem() => BriefItem(
    kind: BriefKind.businessSignal,
    severity: BriefSeverity.info,
    subjectKind: 'business',
    subjectId: 'revenueDrop',
    headline: 'Doanh thu kỳ này thấp hơn kỳ trước',
    suggestion: 'Mở Báo cáo để xem điều gì đã đổi',
    evidence: const [
      IdentityEvidence(
        kind: IdentityEvidenceKind.businessRecordObservation,
        source: 'rule:business-alerts/revenueDrop',
        detail: '8 triệu so với 12 triệu kỳ trước',
      ),
    ],
    observedAt: DateTime(2026, 8, 8, 9),
  );

  Future<void> pumpStory(WidgetTester tester, BriefItem item) async {
    await inbox.publish([item]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [briefInboxProvider.overrideWithValue(inbox)],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('vi'), Locale('en')],
          home: TongtaiBriefStoryScreen(item: item),
        ),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('story-body')));
  }

  Future<void> tapAndSettle(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  group('⭐ Chuỗi WHAT → WHY → SUGGEST hiện đủ trên một màn', () {
    testWidgets('ba phần đều có, đúng thứ tự người bán cần', (tester) async {
      await pumpStory(tester, messageItem());

      expect(find.byKey(const Key('story-headline')), findsOneWidget);
      expect(find.byKey(const Key('story-why')), findsOneWidget);
      expect(find.byKey(const Key('story-suggest')), findsOneWidget);
      expect(find.text('Đã mua 8 lần'), findsOneWidget);
      expect(find.text('Lần mua gần nhất cách đây 45 ngày'), findsOneWidget);
    });

    testWidgets('ba nút, không phải hai', (tester) async {
      await pumpStory(tester, messageItem());
      expect(find.byKey(const Key('story-accept')), findsOneWidget);
      expect(find.byKey(const Key('story-later')), findsOneWidget);
      expect(find.byKey(const Key('story-dismiss')), findsOneWidget);
    });

    testWidgets('việc chỉ để BIẾT không có nút nào', (tester) async {
      await pumpStory(tester, infoItem());
      expect(find.byKey(const Key('story-accept')), findsNothing);
      expect(find.byKey(const Key('story-why')), findsOneWidget);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('⭐ Bấm ra BẢN GHI THẬT, không phải một trạng thái trên màn', () {
    testWidgets('Làm ngay ⇒ hành động chạy và ghi nhận', (tester) async {
      await pumpStory(tester, messageItem());
      await tapAndSettle(tester, const Key('story-accept'));

      final action = (await db.select(db.businessActionsTable).get()).single;
      expect(action.status, 'succeeded');
      expect(action.requestedBy, 'seller');
      expect(isDemoResult(action.externalId), isTrue);
    });

    testWidgets('⭐ duyệt đề xuất giá ⇒ GIÁ SẢN PHẨM THẬT SỰ ĐỔI', (
      tester,
    ) async {
      await pumpStory(tester, priceItem());
      await tapAndSettle(tester, const Key('story-accept'));

      final product = (await db.select(db.productsTable).get()).single;
      expect(product.listPrice, 112000);

      // Và nó đổi QUA CỬA — một câu UPDATE lẻ sẽ không để lại hành động nào.
      final action = (await db.select(db.businessActionsTable).get()).single;
      expect(action.type, 'proposal.apply');
      expect(action.vendor, 'internal');
    });

    testWidgets('Bỏ qua ⇒ KHÔNG hành động nào chạy', (tester) async {
      await pumpStory(tester, messageItem());
      await tapAndSettle(tester, const Key('story-dismiss'));

      final action = (await db.select(db.businessActionsTable).get()).single;
      expect(action.status, 'cancelled');
      expect(action.externalId, isNull);
    });

    testWidgets('Để sau ⇒ có lời hẹn, việc vẫn ở trạng thái chờ', (
      tester,
    ) async {
      await pumpStory(tester, messageItem());
      await tapAndSettle(tester, const Key('story-later'));

      final task = (await db.select(db.agentTasksTable).get()).single;
      expect(task.dueAt, clock.add(const Duration(days: 7)));

      final action = (await db.select(db.businessActionsTable).get()).single;
      expect(action.status, 'planned');
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('⭐ Trung thực về chỗ chưa thật (Task Order §7)', () {
    testWidgets('việc demo chạy xong ⇒ nhãn DIỄN TẬP hiện ngay', (
      tester,
    ) async {
      await pumpStory(tester, messageItem());
      await tapAndSettle(tester, const Key('story-accept'));
      await pumpUntilFound(
        tester,
        find.byKey(const Key('story-demo-execution')),
      );
      expect(find.text('Diễn tập — chưa gửi đi đâu'), findsOneWidget);
    });

    testWidgets('ghi vào chính máy mình ⇒ KHÔNG gắn nhãn diễn tập', (
      tester,
    ) async {
      // Đổi giá là việc thật, xảy ra thật. Gắn nhãn "diễn tập" ở đây sẽ làm
      // người bán không tin một thay đổi đã thực sự có hiệu lực.
      await pumpStory(tester, priceItem());
      await tapAndSettle(tester, const Key('story-accept'));
      expect(find.byKey(const Key('story-demo-execution')), findsNothing);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Sau khi quyết — WHAT HAPPENED NEXT', () {
    testWidgets('nút biến mất, trạng thái hiện ra', (tester) async {
      await pumpStory(tester, messageItem());
      await tapAndSettle(tester, const Key('story-accept'));

      expect(find.byKey(const Key('story-accept')), findsNothing);
      expect(find.byKey(const Key('story-decision-accepted')), findsOneWidget);
      expect(find.byKey(const Key('story-next')), findsOneWidget);
    });

    testWidgets('để sau ⇒ nói rõ bao giờ nhắc lại', (tester) async {
      await pumpStory(tester, messageItem());
      await tapAndSettle(tester, const Key('story-later'));

      expect(find.byKey(const Key('story-decision-postponed')), findsOneWidget);
      expect(find.textContaining('7 ngày'), findsWidgets);
    });

    testWidgets('bỏ qua ⇒ KHÔNG hứa hẹn gì thêm', (tester) async {
      await pumpStory(tester, messageItem());
      await tapAndSettle(tester, const Key('story-dismiss'));

      expect(find.byKey(const Key('story-decision-dismissed')), findsOneWidget);
      expect(find.byKey(const Key('story-next')), findsNothing);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Không lộ từ vựng hệ thống', () {
    testWidgets('màn KHÔNG chứa n8n · JSON · tên bảng · correlationId', (
      tester,
    ) async {
      await pumpStory(tester, messageItem());
      for (final banned in [
        'n8n',
        'webhook',
        'correlationId',
        'AgentTask',
        'BusinessAction',
        '_table',
        'idempotency',
      ]) {
        expect(
          find.textContaining(banned),
          findsNothing,
          reason: 'màn lộ "$banned" — người bán không đọc từ vựng hệ thống',
        );
      }
    });
  });
}
