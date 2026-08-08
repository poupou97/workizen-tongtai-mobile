@TestOn('vm')
library;

import 'package:test/test.dart';
import 'package:tongtai/features/tongtai/agent/agent_task.dart';

/// WTM-301 · D-4 — **bằng chứng execution-location independence.**
///
/// ## Vì sao suite này dùng `package:test`, không dùng `flutter_test`
///
/// Điều kiện của Founder cho D-4:
///
/// > *"domain/task model **không được phụ thuộc vòng đời mobile**. Cùng một
/// > task về sau phải chạy được trên Workizen Managed Worker / Oracle VM 24/7
/// > mà **không đổi business model**."*
///
/// Một câu như vậy rất dễ thành lời hứa không ai chứng minh được. Suite này là
/// phép chứng minh: nó import `package:test` — **không có Flutter binding nào
/// tồn tại khi nó chạy**. Nếu logic nhận việc chạy được ở đây, nó chạy được
/// trên một worker.
///
/// Suite dùng `flutter_test` sẽ **không** chứng minh được điều đó, vì
/// `flutter_test` tự dựng binding.
void main() {
  AgentTask task({
    String id = 't1',
    AgentTaskKind kind = AgentTaskKind.recheck,
    DateTime? dueAt,
    int attempts = 0,
    DateTime? leasedUntil,
    DateTime? finishedAt,
    int priority = 0,
  }) => AgentTask(
    id: id,
    kind: kind,
    reason: 'Khách này 45 ngày chưa mua',
    dueAt: dueAt ?? DateTime(2026, 8, 8, 9),
    createdAt: DateTime(2026, 8, 1),
    attempts: attempts,
    leasedUntil: leasedUntil,
    finishedAt: finishedAt,
    priority: priority,
  );

  final now = DateTime(2026, 8, 8, 12);

  group('⭐ Giao thức nhận việc chạy được KHÔNG cần Flutter', () {
    test('đến hạn và không ai giữ ⇒ nhận được', () {
      expect(task().isClaimableAt(now), isTrue);
    });

    test('chưa đến hạn ⇒ không nhận', () {
      expect(task(dueAt: DateTime(2026, 9, 1)).isClaimableAt(now), isFalse);
    });

    test('đang có người giữ ⇒ không nhận', () {
      expect(
        task(leasedUntil: DateTime(2026, 8, 8, 13)).isClaimableAt(now),
        isFalse,
      );
    });

    test('lease hết hạn ⇒ nhận lại được', () {
      // Đây là chỗ "app bị kill" và "worker chết" thành CÙNG một tình huống:
      // cả hai đều là giữ việc rồi biến mất. Một cơ chế xử lý cả hai.
      expect(
        task(leasedUntil: DateTime(2026, 8, 8, 11)).isClaimableAt(now),
        isTrue,
      );
    });

    test('đã xong ⇒ không nhận nữa', () {
      expect(task(finishedAt: now).isClaimableAt(now), isFalse);
    });

    test('hết lượt thử ⇒ không nhận nữa', () {
      expect(task(attempts: kMaxAgentTaskAttempts).isClaimableAt(now), isFalse);
      expect(
        task(attempts: kMaxAgentTaskAttempts - 1).isClaimableAt(now),
        isTrue,
      );
    });
  });

  group('Thứ tự chạy là hàm thuần, không phải mệnh đề SQL', () {
    test('ưu tiên cao trước', () {
      final high = task(id: 'a', priority: 10);
      final low = task(id: 'b');
      expect(compareAgentTaskPriority(high, low), lessThan(0));
    });

    test('cùng ưu tiên ⇒ đến hạn sớm trước', () {
      final early = task(id: 'a', dueAt: DateTime(2026, 8, 1));
      final late_ = task(id: 'b', dueAt: DateTime(2026, 8, 5));
      expect(compareAgentTaskPriority(early, late_), lessThan(0));
    });

    test('sắp xếp cho kết quả giống nhau ở mọi runner', () {
      // Tách thứ tự khỏi SQL để một runner không dùng SQL vẫn chạy đúng luật.
      final tasks = [
        task(id: 'c', dueAt: DateTime(2026, 8, 3)),
        task(id: 'a', priority: 5, dueAt: DateTime(2026, 8, 9)),
        task(id: 'b', dueAt: DateTime(2026, 8, 1)),
      ]..sort(compareAgentTaskPriority);
      expect(tasks.map((t) => t.id), ['a', 'b', 'c']);
    });
  });

  group('Lần thử lại là TIẾP TỤC, không LÀM LẠI', () {
    test('lần đầu chỉ có lý do', () {
      expect(task().briefFor(1), 'Khách này 45 ngày chưa mua');
    });

    test('lần sau được dặn tiếp tục', () {
      final brief = task().briefFor(2);
      expect(brief, contains('lần thử thứ 2'));
      expect(brief, contains('Tiếp tục từ những gì đã có'));
      expect(brief, contains('Khách này 45 ngày chưa mua'));
    });
  });

  group('Từ vựng đóng, mã lạ ⇒ null', () {
    test('mã kind lạ không rơi về loại nào', () {
      expect(AgentTaskKind.fromCode('probably_recheck'), isNull);
      expect(AgentTaskKind.fromCode(null), isNull);
    });

    test('mã outcome lạ không rơi về completed', () {
      expect(AgentTaskOutcome.fromCode('sort_of_done'), isNull);
    });
  });

  group('Việc không lý do không dựng được', () {
    test('lý do rỗng ⇒ chặn tại constructor', () {
      expect(
        () => AgentTask(
          id: 'x',
          kind: AgentTaskKind.recheck,
          reason: '',
          dueAt: DateTime(2026),
          createdAt: DateTime(2026),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
