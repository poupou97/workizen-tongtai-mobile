import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/agent/agent_task.dart';
import 'package:tongtai/features/tongtai/agent/agent_task_queue.dart';

/// WTM-301 · D-4 — hàng đợi bền vững trên máy (schema v23).
void main() {
  late AppDatabase db;
  late AgentTaskQueue queue;
  var clock = DateTime(2026, 8, 8, 9);
  var seq = 0;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    clock = DateTime(2026, 8, 8, 9);
    seq = 0;
    queue = AgentTaskQueue(
      db,
      now: () => clock,
      newId: () => 't${++seq}',
      lease: const Duration(minutes: 10),
    );
  });
  tearDown(() => db.close());

  Future<AgentTask> scheduleDue({
    AgentTaskKind kind = AgentTaskKind.recheck,
    String reason = 'Khách 45 ngày chưa mua',
    String? subjectId = 'cust-1',
    int priority = 0,
    String? correlationId,
  }) => queue.schedule(
    kind: kind,
    reason: reason,
    dueAt: clock.subtract(const Duration(minutes: 1)),
    subjectKind: subjectId == null ? null : 'customer',
    subjectId: subjectId,
    priority: priority,
    correlationId: correlationId,
  );

  // ────────────────────────────────────────────────────────────────────────
  group('⭐ Chống trùng ngay lúc ĐẶT LỊCH', () {
    test('gọi năm mươi lần vẫn chỉ một việc', () async {
      for (var i = 0; i < 50; i++) {
        await scheduleDue(reason: 'lần $i');
      }
      final open = await queue.loadOpen();
      expect(open, hasLength(1));
      expect(open.single.reason, 'lần 49', reason: 'lý do được cập nhật');
    });

    test('đặt lại cập nhật `dueAt`, không tạo thẻ mới', () async {
      final first = await scheduleDue();
      final again = await queue.schedule(
        kind: AgentTaskKind.recheck,
        reason: 'dời lịch',
        dueAt: DateTime(2026, 9, 1),
        subjectKind: 'customer',
        subjectId: 'cust-1',
      );
      expect(again.id, first.id);
      expect(again.dueAt, DateTime(2026, 9, 1));
    });

    test('subject khác ⇒ việc khác', () async {
      await scheduleDue(subjectId: 'cust-1');
      await scheduleDue(subjectId: 'cust-2');
      expect(await queue.loadOpen(), hasLength(2));
    });

    test('việc đã xong không chặn việc mới', () async {
      final t = await scheduleDue();
      await queue.finish(t.id, AgentTaskOutcome.completed);
      await scheduleDue();
      expect(await queue.loadOpen(), hasLength(1));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Nhận việc — lease, thứ tự, số lượt thử', () {
    test('nhận việc thì tăng attempts và đặt lease', () async {
      await scheduleDue();
      final claimed = await queue.claimDue();
      expect(claimed, hasLength(1));
      expect(claimed.single.attempts, 1);
      expect(
        claimed.single.leasedUntil,
        clock.add(const Duration(minutes: 10)),
      );
    });

    test('đang giữ lease ⇒ lần nhận sau không thấy', () async {
      await scheduleDue();
      await queue.claimDue();
      expect(await queue.claimDue(), isEmpty);
    });

    test('lease hết hạn ⇒ nhận lại được, attempts tiếp tục tăng', () async {
      await scheduleDue();
      await queue.claimDue();
      clock = clock.add(const Duration(minutes: 11));
      final again = await queue.claimDue();
      expect(again, hasLength(1));
      expect(again.single.attempts, 2);
    });

    test('chưa đến hạn ⇒ không nhận', () async {
      await queue.schedule(
        kind: AgentTaskKind.recheck,
        reason: 'sau này',
        dueAt: clock.add(const Duration(days: 7)),
      );
      expect(await queue.claimDue(), isEmpty);
    });

    test('ưu tiên cao chạy trước', () async {
      await scheduleDue(subjectId: 'a');
      await scheduleDue(subjectId: 'b', priority: 10);
      final claimed = await queue.claimDue();
      expect(claimed.first.subjectId, 'b');
    });

    test('hết lượt thử ⇒ không nhận nữa', () async {
      await scheduleDue();
      for (var i = 0; i < kMaxAgentTaskAttempts; i++) {
        await queue.claimDue();
        clock = clock.add(const Duration(minutes: 11));
      }
      expect(await queue.claimDue(), isEmpty);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Nghỉ hưu là một QUYẾT ĐỊNH, không phải hiệu ứng phụ', () {
    test('hết lượt ⇒ đóng với outcome `retired`', () async {
      await scheduleDue();
      for (var i = 0; i < kMaxAgentTaskAttempts; i++) {
        await queue.claimDue();
        clock = clock.add(const Duration(minutes: 11));
      }

      final retired = await queue.retireExhausted();
      expect(retired, 1);

      final row = (await db.select(db.agentTasksTable).get()).single;
      expect(row.outcome, 'retired');
      expect(
        row.finishedAt,
        isNotNull,
        reason: '"đã thử bốn lần và không xong" phải nhìn thấy được',
      );
    });

    test('việc chưa hết lượt KHÔNG bị nghỉ hưu oan', () async {
      await scheduleDue();
      await queue.claimDue();
      clock = clock.add(const Duration(minutes: 11));
      expect(await queue.retireExhausted(), 0);
    });

    test('đóng hai lần chỉ ăn một lần', () async {
      final t = await scheduleDue();
      expect(await queue.finish(t.id, AgentTaskOutcome.completed), isTrue);
      expect(await queue.finish(t.id, AgentTaskOutcome.obsolete), isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('scheduleRecheck — agent tự chọn khoảng, kèm lý do người đọc', () {
    test('đặt đúng ngày và giữ nguyên lý do', () async {
      final t = await queue.scheduleRecheck(
        reason: 'Khách này mua nồi chiên tháng 6, sắp hết hàng dùng',
        days: 30,
        subjectKind: 'customer',
        subjectId: 'cust-1',
      );
      expect(t.dueAt, clock.add(const Duration(days: 30)));
      expect(t.reason, contains('sắp hết hàng dùng'));
      expect(t.kind, AgentTaskKind.recheck);
    });

    test('khoảng ngoài 1..730 ngày bị chặn', () async {
      expect(
        () => queue.scheduleRecheck(reason: 'x', days: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => queue.scheduleRecheck(reason: 'x', days: 1000),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Bền vững và bản ghi hỏng', () {
    test('việc sống qua một lần đóng/mở lại', () async {
      await scheduleDue();
      final reopened = AgentTaskQueue(db, now: () => clock, newId: () => 'x');
      expect(await reopened.loadOpen(), hasLength(1));
    });

    test('mã kind lạ ⇒ bỏ qua dòng, không rơi về loại nào', () async {
      await scheduleDue();
      await db.customStatement(
        "UPDATE agent_tasks_table SET kind = 'probably_recheck'",
      );
      expect(await queue.loadOpen(), isEmpty);
    });

    test('mã outcome lạ ⇒ bỏ qua dòng', () async {
      final t = await scheduleDue();
      await db.customStatement(
        "UPDATE agent_tasks_table SET outcome = 'sort_of' WHERE id = '${t.id}'",
      );
      expect(await queue.byId(t.id), isNull);
    });

    test('correlationId gom được chuỗi việc', () async {
      await scheduleDue(subjectId: 'a', correlationId: 'chain-1');
      await scheduleDue(subjectId: 'b', correlationId: 'chain-1');
      await scheduleDue(subjectId: 'c');
      expect(await queue.loadByCorrelation('chain-1'), hasLength(2));
    });

    test('deleteAll dọn sạch (WTM-164 restore Replace)', () async {
      await scheduleDue();
      await queue.deleteAll();
      expect(await queue.loadOpen(), isEmpty);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Dogfood — vòng lặp delivery-pulse của Workizen', () {
    test('một vòng đầy đủ: đặt → nhận → xong → đặt lại', () async {
      // Connector GitHub đã chạy thật (WTM-268/274). Đây là vòng lặp mà một
      // runner — trong app hôm nay, trên worker sau này — sẽ chạy.
      const chain = 'delivery-pulse-2026-w32';

      await queue.schedule(
        kind: AgentTaskKind.deliveryPulse,
        reason: 'Xem nhịp giao hàng tuần này',
        dueAt: clock.subtract(const Duration(minutes: 1)),
        correlationId: chain,
      );

      final claimed = await queue.claimDue();
      expect(claimed.single.kind, AgentTaskKind.deliveryPulse);
      expect(claimed.single.briefFor(1), 'Xem nhịp giao hàng tuần này');

      await queue.finish(claimed.single.id, AgentTaskOutcome.completed);

      await queue.scheduleRecheck(
        reason: 'Xem nhịp giao hàng tuần tới',
        days: 7,
        correlationId: chain,
      );

      final story = await queue.loadByCorrelation(chain);
      expect(story, hasLength(2), reason: 'vòng lặp tiếp tục, không dừng');
      expect(story.first.outcome, AgentTaskOutcome.completed);
      expect(story.last.dueAt, clock.add(const Duration(days: 7)));
    });
  });
}
