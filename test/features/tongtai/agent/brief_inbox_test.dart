import 'package:drift/native.dart';
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

/// WTM-303 · **hộp việc** — nơi brief thành bản ghi có vòng đời.
///
/// Suite này chạy trên cơ sở dữ liệu thật vì cả điểm của lớp này là *quyết
/// định sống qua một lần tắt app*.
void main() {
  late AppDatabase db;
  late BriefInbox inbox;
  var clock = DateTime(2026, 8, 8, 9);
  var seq = 0;

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    clock = DateTime(2026, 8, 8, 9);
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

  BriefItem factItem() => BriefItem(
    kind: BriefKind.marginTooThin,
    severity: BriefSeverity.warning,
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
    observedAt: clock,
  );

  BriefItem actionItem() => BriefItem(
    kind: BriefKind.customerAtRisk,
    severity: BriefSeverity.warning,
    subjectKind: 'customer',
    subjectId: 'cust-1',
    subjectLabel: 'Chị Phương',
    headline: 'Chị Phương đã 45 ngày chưa quay lại',
    suggestion: 'Nhắn hỏi thăm',
    evidence: const [
      IdentityEvidence(
        kind: IdentityEvidenceKind.orderHistoryMatch,
        source: 'rule:customer-risk',
        detail: 'Đã mua 8 lần',
      ),
    ],
    move: const DoSomething(
      actionType: BusinessActionType.customerSendMessage,
      vendor: ActionVendor.demo,
    ),
    observedAt: clock,
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
        detail: '8 triệu so với 12 triệu',
      ),
    ],
    observedAt: clock,
  );

  // ────────────────────────────────────────────────────────────────────────
  group('Ghi xuống máy — mỗi việc vào ĐÚNG vòng đời của nó', () {
    test('đổi sự thật ⇒ đề xuất; làm một việc ⇒ hành động chờ', () async {
      final report = await inbox.publish([factItem(), actionItem()]);

      expect(report.proposals, 1);
      expect(report.actions, 1);

      final proposal = (await db.select(db.proposedChangesTable).get()).single;
      expect(proposal.status, 'proposed', reason: 'không bao giờ tự áp dụng');

      final action = (await db.select(db.businessActionsTable).get()).single;
      expect(action.status, 'planned', reason: 'đã dựng, chưa được phép chạy');
    });

    test('việc chỉ để BIẾT không ghi gì cả', () async {
      final report = await inbox.publish([infoItem()]);
      expect(report.total, 0);
      expect(await db.select(db.proposedChangesTable).get(), isEmpty);
      expect(await db.select(db.businessActionsTable).get(), isEmpty);
    });

    test('⭐ ghi năm lần vẫn chỉ một bản ghi mỗi việc', () async {
      for (var i = 0; i < 5; i++) {
        await inbox.publish([factItem(), actionItem()]);
      }
      expect(await db.select(db.proposedChangesTable).get(), hasLength(1));
      expect(await db.select(db.businessActionsTable).get(), hasLength(1));
    });

    test('nguồn gốc mẫu đi theo xuống bản ghi', () async {
      await db.customStatement(
        "INSERT INTO products_table (id, business_id, sku, name, list_price, "
        "cost_per_unit, updated_at, created_at) VALUES "
        "('sample-p', 'tongtai-local-business', 'S', 'Mẫu', 100000, 95000, 1, 1)",
      );
      final sample = BriefItem(
        kind: BriefKind.marginTooThin,
        severity: BriefSeverity.warning,
        subjectKind: 'product',
        subjectId: 'sample-p',
        headline: 'Mẫu chỉ còn 5% lãi',
        suggestion: 'Nâng giá',
        evidence: factItem().evidence,
        move: const ChangeAFact(
          domain: ProposalDomain.pricing,
          field: 'pricePerUnit',
          proposedValue: '112000',
        ),
        observedAt: clock,
      );
      await inbox.publish([sample]);

      final row = (await db.select(db.proposedChangesTable).get()).single;
      expect(
        row.provenanceCode,
        'sample',
        reason: 'dữ liệu mẫu phải KHAI ra, không để người sau đoán từ id',
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('⭐ Đồng ý — và giá trị vào bản ghi QUA CỬA', () {
    test('đề xuất được duyệt ⇒ giá sản phẩm thật sự đổi', () async {
      await inbox.publish([factItem()]);
      final result = await inbox.accept(factItem());

      expect(result, isA<ActionSucceeded>());

      final product = (await db.select(db.productsTable).get()).single;
      expect(product.listPrice, 112000);

      // Và nó đổi qua một hành động có vòng đời, không phải một câu UPDATE lẻ.
      final action = (await db.select(db.businessActionsTable).get()).single;
      expect(action.type, 'proposal.apply');
      expect(action.vendor, 'internal');
      expect(action.status, 'succeeded');
    });

    test('duyệt hai lần KHÔNG ghi lần hai', () async {
      await inbox.publish([factItem()]);
      await inbox.accept(factItem());
      final again = await inbox.accept(factItem());
      expect(again, isNull, reason: 'đề xuất đã rời trạng thái chờ');

      final product = (await db.select(db.productsTable).get()).single;
      expect(product.listPrice, 112000);
    });

    test('hành động ra ngoài chạy xong nhưng KHAI RÕ là diễn tập', () async {
      await inbox.publish([actionItem()]);
      final result = await inbox.accept(actionItem()) as ActionSucceeded;

      expect(isDemoResult(result.externalId), isTrue);

      final action = (await db.select(db.businessActionsTable).get()).single;
      expect(action.status, 'succeeded');
      expect(action.vendor, 'demo', reason: 'chưa gửi đi đâu cả');
      expect(isDemoResult(action.externalId), isTrue);
    });

    test('⭐ đồng ý xong thì tự hẹn xem lại — vòng lặp không dừng', () async {
      await inbox.publish([actionItem()]);
      await inbox.accept(actionItem());

      final tasks = await db.select(db.agentTasksTable).get();
      expect(tasks, hasLength(1));
      expect(tasks.single.reason, contains('Chị Phương'));
      expect(tasks.single.dueAt, clock.add(const Duration(days: 7)));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Bỏ qua — và việc KHÔNG quay lại sáng mai', () {
    test('đề xuất bị bỏ qua ⇒ ghi lại, giá không đổi', () async {
      await inbox.publish([factItem()]);
      await inbox.dismiss(factItem());

      final product = (await db.select(db.productsTable).get()).single;
      expect(product.listPrice, 100000);
      expect(await inbox.statusOf(factItem()), BriefDecision.dismissed);
    });

    test('⭐ dựng lại brief KHÔNG hỏi lại việc đã bỏ qua', () async {
      await inbox.publish([factItem()]);
      await inbox.dismiss(factItem());

      final report = await inbox.publish([factItem()]);
      expect(report.proposals, 0);
      expect(report.skipped, 1, reason: 'cổng 2 chặn — chưa tới hạn hỏi lại');
      expect(await inbox.statusOf(factItem()), BriefDecision.dismissed);
    });

    test('hành động bị bỏ qua ⇒ huỷ, không có gì chạy', () async {
      await inbox.publish([actionItem()]);
      await inbox.dismiss(actionItem());

      final action = (await db.select(db.businessActionsTable).get()).single;
      expect(action.status, 'cancelled');
      expect(action.externalId, isNull, reason: 'không có gì được gửi đi');
    });

    test('bỏ qua sau khi đã hẹn ⇒ lời hẹn thành `obsolete`', () async {
      await inbox.publish([actionItem()]);
      await inbox.postpone(actionItem());
      await inbox.dismiss(actionItem());

      final task = (await db.select(db.agentTasksTable).get()).single;
      expect(
        task.outcome,
        'obsolete',
        reason: '"không còn gì để làm" khác "đã làm xong"',
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Để sau — người bán không phải nhớ', () {
    test('hẹn bảy ngày, việc vẫn ở trạng thái chờ', () async {
      await inbox.publish([actionItem()]);
      final task = await inbox.postpone(actionItem());

      expect(task.dueAt, clock.add(const Duration(days: 7)));
      expect(await inbox.statusOf(actionItem()), BriefDecision.postponed);

      final action = (await db.select(db.businessActionsTable).get()).single;
      expect(action.status, 'planned');
    });

    test('để sau hai lần chỉ một lời hẹn', () async {
      await inbox.publish([actionItem()]);
      await inbox.postpone(actionItem());
      await inbox.postpone(actionItem());
      expect(await db.select(db.agentTasksTable).get(), hasLength(1));
    });

    test('⭐ đã đồng ý thì KHÔNG bị đọc nhầm thành "để sau"', () async {
      // Đồng ý cũng sinh ra lời hẹn xem lại. Nếu hỏi lời hẹn trước khi hỏi
      // trạng thái bản ghi, mọi việc vừa làm xong sẽ hiện thành "để sau".
      await inbox.publish([actionItem()]);
      await inbox.accept(actionItem());
      expect(await inbox.statusOf(actionItem()), BriefDecision.accepted);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Trạng thái sống qua một lần tắt app', () {
    test('chưa quyết gì ⇒ `null`, khác hẳn "đã bỏ qua"', () async {
      expect(await inbox.statusOf(actionItem()), isNull);
      await inbox.publish([actionItem()]);
      expect(await inbox.statusOf(actionItem()), BriefDecision.pending);
    });

    test('mở lại hộp việc trên cùng cơ sở dữ liệu thấy nguyên trạng', () async {
      await inbox.publish([factItem(), actionItem()]);
      await inbox.dismiss(actionItem());

      final reopened = BriefInbox(
        proposals: DriftProposedChangeRepository(db, now: () => clock),
        actions: BusinessActionExecutor(
          db,
          now: () => clock,
          handlers: demoActionHandlers,
        ),
        tasks: AgentTaskQueue(db, now: () => clock, newId: () => 'x'),
      );

      expect(await reopened.statusOf(factItem()), BriefDecision.pending);
      expect(await reopened.statusOf(actionItem()), BriefDecision.dismissed);
    });

    test('cả chuỗi ráp lại bằng correlationId', () async {
      await inbox.publish([actionItem()]);
      await inbox.accept(actionItem());

      final chain = actionItem().correlationId;
      final actions = await db.select(db.businessActionsTable).get();
      final tasks = await db.select(db.agentTasksTable).get();

      expect(actions.single.correlationId, chain);
      expect(tasks.single.correlationId, chain);
    });
  });
}
