import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/action/business_action.dart';
import 'package:tongtai/features/tongtai/action/business_action_executor.dart';
import 'package:tongtai/features/tongtai/agent/agent_task.dart';
import 'package:tongtai/features/tongtai/agent/agent_task_queue.dart';
import 'package:tongtai/features/tongtai/consumer/external_identity.dart';
import 'package:tongtai/features/tongtai/consumer/identity_evidence.dart';
import 'package:tongtai/features/tongtai/proposal/proposal_gate.dart';
import 'package:tongtai/features/tongtai/proposal/proposed_change.dart';
import 'package:tongtai/features/tongtai/proposal/proposed_change_repository.dart';

/// **Audit Epic WTM-297** — năm tầng chạy CÙNG NHAU.
///
/// Bốn phase mỗi phase có suite riêng, và cả bốn đều xanh. Nhưng bốn suite xanh
/// **không chứng minh** chúng ráp lại được: mỗi suite dựng dữ liệu của riêng nó
/// và không bao giờ thấy hàng xóm.
///
/// Suite này chạy đúng chuỗi Founder đặt ra, một lần, trên một cơ sở dữ liệu:
///
/// ```
/// Evidence → Derived Confidence → ProposedChange → BusinessAction → Durable Agent
/// ```
///
/// Và thứ nối chúng lại là **`correlationId`** — một trường, không phải một
/// bảng `BusinessConversation` (kết luận WTM-296 §10).
void main() {
  late AppDatabase db;
  late DriftProposedChangeRepository proposals;
  late BusinessActionExecutor actions;
  late AgentTaskQueue tasks;
  var clock = DateTime(2026, 8, 8, 9);
  var seq = 0;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    clock = DateTime(2026, 8, 8, 9);
    seq = 0;
    proposals = DriftProposedChangeRepository(db, now: () => clock);
    tasks = AgentTaskQueue(db, now: () => clock, newId: () => 'task-${++seq}');
    actions = BusinessActionExecutor(
      db,
      now: () => clock,
      handlers: {
        // Hành động `internal`: áp dụng đề xuất vào bản ghi nghiệp vụ.
        //
        // Đây là chỗ COMP AI hụt — ghi vào DB của chính mình cũng phải đi qua
        // cửa, nếu không sẽ sinh đường ghi thứ ba.
        BusinessActionType.applyProposedChange: (database, action) async {
          final proposalId = action.parameters['proposalId']! as String;
          await database.customStatement(
            "UPDATE products_table SET cost_per_unit = 45000 "
            "WHERE id = '${action.subjectId}'",
          );
          return 'proposal:$proposalId';
        },
      },
    );
  });
  tearDown(() => db.close());

  test(
    '⭐ chuỗi đầy đủ: Evidence → Confidence → Proposal → Action → Task',
    () async {
      const chain = 'cost-review-prod-1';

      // ── Tầng 0 · dữ liệu nghiệp vụ có sẵn ───────────────────────────────
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
        "('prod-1', 'tongtai-local-business', 'SKU-1', 'Nồi chiên', 1890000, "
        "38000, 1, 1)",
      );

      // ── Tầng 1+2 · Evidence, và confidence được TÍNH ────────────────────
      const evidence = [
        IdentityEvidence(
          kind: IdentityEvidenceKind.orderHistoryMatch,
          source: 'orders:last-12',
        ),
        IdentityEvidence(
          kind: IdentityEvidenceKind.emailExactMatch,
          source: 'supplier:invoice-77',
        ),
      ];
      final proposal = ProposedChange(
        id: 'prop-1',
        correlationId: chain,
        domain: ProposalDomain.pricing,
        subjectKind: 'product',
        subjectId: 'prod-1',
        subjectLabel: 'Nồi chiên',
        field: 'costPrice',
        currentValue: '38000',
        proposedValue: '45000',
        evidence: evidence,
        proposedBy: ProposalAuthor.rule('cost-from-orders'),
        summary: 'Giá vốn nên là 45.000 — tính từ 12 đơn gần nhất',
        createdAt: clock,
      );

      // Không chỗ nào khai confidence; nó đến từ hàm thuần.
      expect(proposal.confidence, IdentityConfidence.strong);
      expect(proposal.scored.countedSources, 2);

      // ── Tầng 3 · ProposedChange đi qua bốn cổng ─────────────────────────
      final outcome = await proposals.propose(proposal, humanOwnsField: false);
      expect(outcome, isA<ProposalAccepted>());
      expect(
        (outcome as ProposalAccepted).status,
        ProposalStatus.proposed,
        reason: 'không bao giờ tự áp dụng, dù bằng chứng mạnh',
      );
      expect(await proposals.loadVisible(), hasLength(1));

      // Người bán duyệt.
      clock = clock.add(const Duration(minutes: 5));
      expect(await proposals.apply('prop-1'), isTrue);

      // ── Tầng 4 · BusinessAction là cửa ghi duy nhất ─────────────────────
      const params = {'proposalId': 'prop-1'};
      final action = BusinessAction(
        id: 'act-1',
        correlationId: chain,
        type: BusinessActionType.applyProposedChange,
        vendor: ActionVendor.internal,
        subjectKind: 'product',
        subjectId: 'prod-1',
        subjectLabel: 'Nồi chiên',
        summary: 'Cập nhật giá vốn thành 45.000',
        parameters: params,
        proposedBy: 'rule:cost-from-orders',
        idempotencyKey: 'apply:prop-1',
        requestHash: BusinessActionExecutor.hashRequest(params),
        plannedAt: clock,
      );
      await actions.plan(action);
      await actions.approve('act-1', requestedBy: 'seller');
      final ran = await actions.run('act-1');
      expect(ran, isA<ActionSucceeded>());

      // Bản ghi nghiệp vụ đã đổi — và nó đổi QUA cửa, không đi vòng.
      final product = (await db.select(db.productsTable).get()).single;
      expect(product.costPerUnit, 45000);

      // Chạy lại KHÔNG ghi lần hai.
      final replay = await actions.run('act-1');
      expect((replay as ActionSucceeded).replayed, isTrue);

      // ── Tầng 5 · Durable Agent tiếp tục vòng lặp ────────────────────────
      await tasks.scheduleRecheck(
        reason: 'Xem lại giá vốn Nồi chiên sau một tháng',
        days: 30,
        subjectKind: 'product',
        subjectId: 'prod-1',
        correlationId: chain,
      );

      // ── Câu chuyện ráp lại bằng correlationId, KHÔNG bằng một bảng ──────
      final storyProposals = await proposals.loadByCorrelation(chain);
      final storyActions = await actions.loadByCorrelation(chain);
      final storyTasks = await tasks.loadByCorrelation(chain);

      expect(storyProposals, hasLength(1));
      expect(storyProposals.single.status, ProposalStatus.applied);
      expect(storyActions, hasLength(1));
      expect(storyActions.single.status, ActionStatus.succeeded);
      expect(storyTasks, hasLength(1));
      expect(storyTasks.single.dueAt, clock.add(const Duration(days: 30)));

      // Và mỗi bước đều có một câu người bán đọc được.
      expect(storyProposals.single.summary, contains('12 đơn gần nhất'));
      expect(storyActions.single.summary, contains('45.000'));
      expect(storyTasks.single.reason, contains('sau một tháng'));
    },
  );

  test('người bán BỎ QUA ⇒ không hành động nào được dựng', () async {
    const chain = 'dismissed-chain';
    await proposals.propose(
      ProposedChange(
        id: 'prop-2',
        correlationId: chain,
        domain: ProposalDomain.pricing,
        subjectKind: 'product',
        subjectId: 'prod-1',
        field: 'costPrice',
        proposedValue: '52000',
        evidence: const [
          IdentityEvidence(
            kind: IdentityEvidenceKind.orderHistoryMatch,
            source: 'orders',
          ),
        ],
        proposedBy: ProposalAuthor.agent,
        summary: 'Giá vốn nên là 52.000',
        createdAt: clock,
      ),
      humanOwnsField: false,
    );
    await proposals.dismiss('prop-2');

    expect(await actions.loadByCorrelation(chain), isEmpty);
    expect(await proposals.loadVisible(), isEmpty);
  });

  test('người bán đã tự nhập ⇒ chuỗi dừng ngay ở tầng đề xuất', () async {
    // Nguyên tắc 3 xuyên suốt: human-owned truth thắng agent evidence, và nó
    // chặn ở cổng ĐẦU TIÊN — không có đề xuất thì không có hành động.
    final outcome = await proposals.propose(
      ProposedChange(
        id: 'prop-3',
        domain: ProposalDomain.pricing,
        subjectKind: 'product',
        subjectId: 'prod-1',
        field: 'costPrice',
        proposedValue: '99000',
        evidence: const [
          IdentityEvidence(
            kind: IdentityEvidenceKind.platformAccountId,
            source: 'shopee',
          ),
        ],
        proposedBy: ProposalAuthor.agent,
        summary: 'Giá vốn nên là 99.000',
        createdAt: clock,
      ),
      humanOwnsField: true,
    );

    expect((outcome as ProposalRejected).reason, ProposalRejection.humanOwns);
    expect(await db.select(db.proposedChangesTable).get(), isEmpty);
    expect(await db.select(db.businessActionsTable).get(), isEmpty);
  });

  test('hành động cấm auto KHÔNG chạy được dù chuỗi hợp lệ', () async {
    // Bảy hành động cấm là hằng số, và nó chặn ở tầng BusinessAction — kể cả
    // khi mọi tầng trước đã hợp lệ.
    const params = {'amount': 20000000};
    await actions.plan(
      BusinessAction(
        id: 'act-pay',
        type: BusinessActionType.financeTransferMoney,
        vendor: ActionVendor.internal,
        subjectKind: 'supplier',
        subjectId: 'sup-1',
        summary: 'Chuyển 20 triệu cho nhà cung cấp',
        parameters: params,
        proposedBy: 'rule:auto-pay',
        idempotencyKey: 'pay:1',
        requestHash: BusinessActionExecutor.hashRequest(params),
        plannedAt: clock,
      ),
    );
    final refused = await actions.approve(
      'act-pay',
      requestedBy: 'rule:auto-pay',
      mode: AutonomyMode.auto,
    );
    expect((refused as ActionRefused).reason, ActionRejection.autoForbidden);
  });

  test('vòng lặp durable tiếp tục sau khi hành động xong', () async {
    // Đây là tính chất "agent tự tiếp tục công việc theo thời gian" — thứ
    // WTM-296 đặt làm ưu tiên P0 khi đọc source.
    const chain = 'delivery-pulse';
    await tasks.schedule(
      kind: AgentTaskKind.deliveryPulse,
      reason: 'Xem nhịp giao hàng tuần này',
      dueAt: clock.subtract(const Duration(minutes: 1)),
      correlationId: chain,
    );

    final claimed = await tasks.claimDue();
    expect(claimed, hasLength(1));
    await tasks.finish(claimed.single.id, AgentTaskOutcome.completed);

    await tasks.scheduleRecheck(
      reason: 'Xem nhịp giao hàng tuần tới',
      days: 7,
      correlationId: chain,
    );

    final open = await tasks.loadOpen();
    expect(open, hasLength(1), reason: 'vòng lặp không dừng');
    expect(open.single.dueAt, clock.add(const Duration(days: 7)));
  });
}
