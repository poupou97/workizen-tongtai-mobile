import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/action/business_action_executor.dart';
import 'package:tongtai/features/tongtai/action/demo_action_handlers.dart';
import 'package:tongtai/features/tongtai/agent/agent_runner.dart';
import 'package:tongtai/features/tongtai/agent/agent_task.dart';
import 'package:tongtai/features/tongtai/agent/agent_task_queue.dart';
import 'package:tongtai/features/tongtai/agent/demo_reset.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/proposal/proposed_change_repository.dart';
import 'package:tongtai/features/tongtai/sample/historical_data_generator.dart';
import 'package:tongtai/features/tongtai/sample/sample_data_seeder.dart';

/// WTM-307 · **Runner V1** và **đặt lại dữ liệu mẫu**.
void main() {
  late AppDatabase db;
  late AgentTaskQueue queue;
  late AgentRunner runner;
  var clock = DateTime(2026, 8, 8, 9);
  var seq = 0;

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    clock = DateTime(2026, 8, 8, 9);
    seq = 0;
    queue = AgentTaskQueue(db, now: () => clock, newId: () => 't${++seq}');
    runner = AgentRunner(queue);
    await db.customStatement(
      "INSERT INTO users_table (id, email, name, language, created_at, "
      "updated_at) VALUES ('u', 'a@b.c', 'Tôi', 'vi', 1, 1)",
    );
    await db.customStatement(
      "INSERT INTO businesses_table (id, owner_id, name, created_at, "
      "updated_at) VALUES ('tongtai-local-business', 'u', 'Shop', 1, 1)",
    );
  });
  tearDown(() => db.close());

  Future<AgentTask> due({
    AgentTaskKind kind = AgentTaskKind.recheck,
    String? subjectId = 'cust-1',
  }) => queue.schedule(
    kind: kind,
    reason: 'Xem lại khách này',
    dueAt: clock.subtract(const Duration(minutes: 1)),
    subjectKind: subjectId == null ? null : 'customer',
    subjectId: subjectId,
    correlationId: 'chain-1',
  );

  // ────────────────────────────────────────────────────────────────────────
  group('⭐ Vòng lặp Founder phải NHÌN THẤY', () {
    test('scheduled → claimed → processed', () async {
      await due();
      final report = await runner.runOnce();

      expect(report.claimed, 1);
      expect(report.completed, 1);

      final row = (await db.select(db.agentTasksTable).get()).single;
      expect(row.outcome, 'completed');
      expect(row.finishedAt, isNotNull);
      expect(row.attempts, 1, reason: 'nhận việc là một lần thử');
    });

    test('chưa đến hạn ⇒ runner không đụng vào', () async {
      await queue.schedule(
        kind: AgentTaskKind.recheck,
        reason: 'sau này',
        dueAt: clock.add(const Duration(days: 7)),
      );
      final report = await runner.runOnce();
      expect(report.didSomething, isFalse);
      expect((await queue.loadOpen()).single.isFinished, isFalse);
    });

    test('chạy hai lượt liền không làm lại việc đã xong', () async {
      await due();
      await runner.runOnce();
      final second = await runner.runOnce();
      expect(second.claimed, 0);
    });

    test('mỗi lượt lấy nhiều nhất `batch` việc', () async {
      for (var i = 0; i < 5; i++) {
        await due(subjectId: 'cust-$i');
      }
      final small = AgentRunner(queue, batch: 2);
      expect((await small.runOnce()).claimed, 2);
      expect((await small.runOnce()).claimed, 2);
      expect((await small.runOnce()).claimed, 1);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Runner KHÔNG đóng việc nó chưa biết làm', () {
    test('loại cần connector ⇒ để nguyên cho lượt sau', () async {
      await due(kind: AgentTaskKind.deliveryPulse, subjectId: null);
      final report = await runner.runOnce();

      expect(report.claimed, 1, reason: 'vẫn nhận — để đếm lượt thử');
      expect(report.completed, 0);

      final row = (await db.select(db.agentTasksTable).get()).single;
      expect(
        row.finishedAt,
        isNull,
        reason: 'đóng nhầm thì việc biến mất khỏi câu chuyện vĩnh viễn',
      );
    });

    test('⭐ hết lượt thử ⇒ nghỉ hưu, và nghỉ hưu XẢY RA TRƯỚC', () async {
      // Thứ tự quan trọng: nghỉ hưu sau khi nhận thì một việc đã hết lượt còn
      // bị nhận thêm một lần nữa ở chính lượt này, và con số báo cáo nói dối.
      await due(kind: AgentTaskKind.deliveryPulse, subjectId: null);
      for (var i = 0; i < kMaxAgentTaskAttempts; i++) {
        await runner.runOnce();
        clock = clock.add(const Duration(minutes: 11));
      }

      final report = await runner.runOnce();
      expect(report.retired, 1);
      expect(report.claimed, 0, reason: 'đã nghỉ hưu thì không nhận nữa');

      final row = (await db.select(db.agentTasksTable).get()).single;
      expect(row.outcome, 'retired');
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group(
    '⭐ Đặt lại dữ liệu mẫu — dọn CẢ quyết định, và CHỈ của dữ liệu mẫu',
    () {
      late DemoResetService reset;
      late DriftProposedChangeRepository proposals;
      late BusinessActionExecutor actions;

      setUp(() {
        proposals = DriftProposedChangeRepository(db, now: () => clock);
        actions = BusinessActionExecutor(
          db,
          now: () => clock,
          handlers: demoActionHandlers,
        );
        reset = DemoResetService(
          // Kho THẬT trên cơ sở dữ liệu trong bộ nhớ: đặt lại phải thật sự
          // gieo được, không chỉ xoá được.
          history: HistoricalDataSeeder(
            sampleSeeder: SampleDataSeeder(
              customers: DriftCustomerRepository(db),
              products: DriftProductRepository(db),
              orders: DriftOrderRepository(db),
              goals: DriftBusinessGoalRepository(db),
              finance: DriftFinanceRepository(db),
            ),
          ),
          proposals: proposals,
          actions: actions,
          tasks: queue,
        );
      });

      Future<void> seedRows() async {
        await db.customStatement(
          "INSERT INTO proposed_changes_table (id, business_id, domain, "
          "subject_kind, subject_id, field, proposed_value, evidence, "
          "proposed_by, summary, status, created_at) VALUES "
          "('p-sample', 'tongtai-local-business', 'pricing', 'product', "
          "'sample-prod-1', 'pricePerUnit', '1', '[]', 'agent', 's', "
          "'proposed', 1), "
          "('p-real', 'tongtai-local-business', 'pricing', 'product', "
          "'real-prod-1', 'pricePerUnit', '1', '[]', 'agent', 's', "
          "'proposed', 1)",
        );
        await db.customStatement(
          "INSERT INTO business_actions_table (id, business_id, type, vendor, "
          "subject_kind, subject_id, summary, parameters, proposed_by, "
          "idempotency_key, request_hash, status, planned_at) VALUES "
          "('a-sample', 'tongtai-local-business', 'customer.send_message', "
          "'demo', 'customer', 'sample-c1', 's', '{}', 'r', 'k1', 'h', "
          "'planned', 1), "
          "('a-real', 'tongtai-local-business', 'customer.send_message', "
          "'demo', 'customer', 'real-c1', 's', '{}', 'r', 'k2', 'h', "
          "'planned', 1)",
        );
        await queue.schedule(
          kind: AgentTaskKind.recheck,
          reason: 'mẫu',
          dueAt: clock,
          subjectKind: 'customer',
          subjectId: 'sample-c1',
        );
        await queue.schedule(
          kind: AgentTaskKind.recheck,
          reason: 'thật',
          dueAt: clock,
          subjectKind: 'customer',
          subjectId: 'real-c1',
        );
      }

      test('xoá đúng quyết định thuộc dữ liệu mẫu', () async {
        await seedRows();
        final report = await reset.reset();

        expect(report.proposals, 1);
        expect(report.actions, 1);
        expect(report.tasks, 1);
        expect(report.decisions, 3);
      });

      test('⭐ quyết định cho dữ liệu THẬT không bị đụng tới', () async {
        await seedRows();
        await reset.reset();

        final proposalIds = (await db.select(db.proposedChangesTable).get())
            .map((r) => r.id);
        final actionIds = (await db.select(db.businessActionsTable).get()).map(
          (r) => r.id,
        );
        final taskSubjects = (await db.select(db.agentTasksTable).get()).map(
          (r) => r.subjectId,
        );

        expect(proposalIds, ['p-real']);
        expect(actionIds, ['a-real']);
        expect(taskSubjects, ['real-c1']);
      });

      test('việc toàn doanh nghiệp (không subject) KHÔNG bị xoá', () async {
        // `subjectId == null` nghĩa là việc không nói về bản ghi nào cả — nó
        // không thuộc dữ liệu mẫu, nên đặt lại demo không được cuốn nó theo.
        await queue.schedule(
          kind: AgentTaskKind.recheck,
          reason: 'toàn doanh nghiệp',
          dueAt: clock,
        );
        final report = await reset.reset();
        expect(report.tasks, 0);
        expect(await db.select(db.agentTasksTable).get(), hasLength(1));
      });

      test('không có gì để dọn ⇒ vẫn gieo lại được, báo 0', () async {
        final report = await reset.reset();
        expect(report.decisions, 0);
      });
    },
  );
}
