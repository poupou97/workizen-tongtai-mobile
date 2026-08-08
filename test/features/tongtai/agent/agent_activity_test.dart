import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/action/business_action.dart';
import 'package:tongtai/features/tongtai/action/business_action_executor.dart';
import 'package:tongtai/features/tongtai/agent/agent_activity.dart';
import 'package:tongtai/features/tongtai/agent/agent_task.dart';
import 'package:tongtai/features/tongtai/consumer/identity_evidence.dart';
import 'package:tongtai/features/tongtai/proposal/proposed_change.dart';

/// WTM-305 · **"Tổng Tài đã làm gì"** — trải nghiệm #5.
///
/// > *"Không phải developer log."* — Task Order §10
void main() {
  final now = DateTime(2026, 8, 8, 15);
  const service = AgentActivityService();

  ProposedChange proposal({
    ProposalStatus status = ProposalStatus.proposed,
    DateTime? decidedAt,
    String? label = 'Nồi chiên',
  }) => ProposedChange(
    id: 'p1',
    correlationId: 'chain-1',
    domain: ProposalDomain.pricing,
    subjectKind: 'product',
    subjectId: 'prod-1',
    subjectLabel: label,
    field: 'pricePerUnit',
    proposedValue: '112000',
    evidence: const [
      IdentityEvidence(
        kind: IdentityEvidenceKind.businessRecordObservation,
        source: 'rule:margin',
        detail: 'Giá bán 100.000 ₫',
      ),
    ],
    proposedBy: ProposalAuthor.rule('margin_too_thin'),
    summary: 'Cân nhắc nâng giá bán lên 112.000 ₫',
    createdAt: DateTime(2026, 8, 1),
    status: status,
    decidedAt: decidedAt,
  );

  BusinessAction action({
    ActionStatus status = ActionStatus.succeeded,
    ActionVendor vendor = ActionVendor.demo,
    String? externalId = 'demo:message:cust-1',
    DateTime? completedAt,
  }) {
    const params = <String, Object?>{};
    return BusinessAction(
      id: 'a1',
      correlationId: 'chain-2',
      type: BusinessActionType.customerSendMessage,
      vendor: vendor,
      subjectKind: 'customer',
      subjectId: 'cust-1',
      subjectLabel: 'Chị Phương',
      summary: 'Nhắn hỏi thăm Chị Phương',
      parameters: params,
      proposedBy: 'rule:customer_at_risk',
      requestedBy: status == ActionStatus.planned ? null : 'seller',
      idempotencyKey: 'k1',
      requestHash: BusinessActionExecutor.hashRequest(params),
      plannedAt: DateTime(2026, 8, 8, 9),
      status: status,
      completedAt: completedAt ?? DateTime(2026, 8, 8, 10),
      externalId: externalId,
    );
  }

  AgentTask task({
    DateTime? finishedAt,
    AgentTaskOutcome? outcome,
    DateTime? dueAt,
  }) => AgentTask(
    id: 't1',
    correlationId: 'chain-2',
    kind: AgentTaskKind.recheck,
    reason: 'Xem lại: Chị Phương đã 45 ngày chưa quay lại',
    dueAt: dueAt ?? DateTime(2026, 8, 15),
    createdAt: DateTime(2026, 8, 8, 10),
    finishedAt: finishedAt,
    outcome: outcome,
  );

  // ────────────────────────────────────────────────────────────────────────
  group('⭐ Mỗi dòng là một câu NGHIỆP VỤ, truy được về một bản ghi', () {
    test('đã quét bao nhiêu ⇒ đúng con số đã đọc', () {
      final entries = service.build(
        now: now,
        customersScanned: 26,
        productsScanned: 18,
      );
      expect(entries.map((e) => e.text), [
        'Đã xem 26 khách hàng',
        'Đã kiểm 18 mặt hàng',
      ]);
    });

    test('chưa quét gì ⇒ KHÔNG nói "đã xem 0 khách"', () {
      // "Đã xem 0 khách hàng" là một dòng vô nghĩa mà người bán sẽ đọc thành
      // "app không làm gì" — trong khi sự thật là chưa chạy lượt nào.
      expect(service.build(now: now), isEmpty);
    });

    test('đề xuất đang chờ ⇒ dòng CHỜ, mang chính câu đề nghị', () {
      final entry = service.build(now: now, proposals: [proposal()]).single;
      expect(entry.tone, ActivityTone.waiting);
      expect(entry.text, 'Đang chờ bạn: Cân nhắc nâng giá bán lên 112.000 ₫');
      expect(entry.correlationId, 'chain-1');
    });

    test('đã duyệt ⇒ nói tên đối tượng người bán nhận ra', () {
      final entry = service
          .build(
            now: now,
            proposals: [
              proposal(
                status: ProposalStatus.applied,
                decidedAt: DateTime(2026, 8, 8, 11),
              ),
            ],
          )
          .single;
      expect(entry.tone, ActivityTone.done);
      expect(entry.text, 'Bạn đã duyệt thay đổi cho Nồi chiên');
    });

    test('không tra được tên ⇒ dùng chính câu đề nghị, không đọc id', () {
      final entry = service
          .build(
            now: now,
            proposals: [
              proposal(
                status: ProposalStatus.applied,
                decidedAt: DateTime(2026, 8, 8, 11),
                label: null,
              ),
            ],
          )
          .single;
      expect(entry.text, contains('112.000'));
      expect(entry.text, isNot(contains('prod-1')));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('⭐ Diễn tập phải NHÌN RA ĐƯỢC, không lẫn với việc đã làm thật', () {
    test('hành động demo ⇒ nói "đã diễn tập" và mang cờ', () {
      final entry = service.build(now: now, actions: [action()]).single;
      expect(entry.text, 'Đã diễn tập: Nhắn hỏi thăm Chị Phương');
      expect(entry.isDemo, isTrue);
    });

    test('hành động thật ⇒ nói "đã làm", KHÔNG mang cờ', () {
      final entry = service
          .build(
            now: now,
            actions: [
              action(vendor: ActionVendor.internal, externalId: 'product:x'),
            ],
          )
          .single;
      expect(entry.text, 'Đã làm: Nhắn hỏi thăm Chị Phương');
      expect(entry.isDemo, isFalse);
    });

    test('cờ demo đọc từ CẢ vendor lẫn kết quả', () {
      // Hai đường độc lập cùng khai một sự thật. Một trong hai bị quên thì
      // đường kia vẫn bắt được — và ở đây quên nghĩa là nói dối người bán rằng
      // tin đã gửi đi.
      final entry = service
          .build(
            now: now,
            actions: [action(vendor: ActionVendor.internal)],
          )
          .single;
      expect(entry.isDemo, isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Dòng nào KHÔNG được kể', () {
    test('hành động mới dựng chưa kể — brief đã nói rồi', () {
      expect(
        service.build(
          now: now,
          actions: [action(status: ActionStatus.planned)],
        ),
        isEmpty,
      );
    });

    test('đề xuất bị thay thế không thuộc câu chuyện của người bán', () {
      expect(
        service.build(
          now: now,
          proposals: [proposal(status: ProposalStatus.superseded)],
        ),
        isEmpty,
      );
    });

    test('lời hẹn mất đối tượng không kể', () {
      expect(
        service.build(
          now: now,
          tasks: [
            task(
              finishedAt: DateTime(2026, 8, 8, 12),
              outcome: AgentTaskOutcome.obsolete,
            ),
          ],
        ),
        isEmpty,
      );
    });

    test('nhưng "thử mấy lần chưa xong" thì PHẢI kể', () {
      final entry = service
          .build(
            now: now,
            tasks: [
              task(
                finishedAt: DateTime(2026, 8, 8, 12),
                outcome: AgentTaskOutcome.retired,
              ),
            ],
          )
          .single;
      expect(entry.tone, ActivityTone.attention);
      expect(entry.text, startsWith('Tôi thử mấy lần nhưng chưa xong'));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Việc hẹn lại nói KHOẢNG, không nói mốc', () {
    test('bảy ngày nữa', () {
      final entry = service
          .build(
            now: now,
            tasks: [task(dueAt: DateTime(2026, 8, 15, 15))],
          )
          .single;
      expect(entry.text, contains('trong 7 ngày'));
      expect(entry.tone, ActivityTone.waiting);
    });

    test('đến hạn hôm nay', () {
      final entry = service
          .build(
            now: now,
            tasks: [task(dueAt: DateTime(2026, 8, 8, 16))],
          )
          .single;
      expect(entry.text, contains('hôm nay'));
    });

    test('quá hạn cũng là "hôm nay", không phải "trong -3 ngày"', () {
      final entry = service
          .build(
            now: now,
            tasks: [task(dueAt: DateTime(2026, 8, 5))],
          )
          .single;
      expect(entry.text, contains('hôm nay'));
      expect(entry.text, isNot(contains('-')));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Thứ tự và ngôn ngữ', () {
    test('mới nhất trước, và ngày là ngày VIỆC ĐÓ xảy ra', () {
      // Đề xuất tạo 1/8 nhưng duyệt hôm nay ⇒ phải nằm trên hành động lúc 10h.
      final entries = service.build(
        now: now,
        proposals: [
          proposal(
            status: ProposalStatus.applied,
            decidedAt: DateTime(2026, 8, 8, 14),
          ),
        ],
        actions: [action(completedAt: DateTime(2026, 8, 8, 10))],
      );
      expect(entries.first.text, startsWith('Bạn đã duyệt'));
    });

    test('⭐ KHÔNG dòng nào chứa từ vựng của hệ thống', () {
      final entries = service.build(
        now: now,
        customersScanned: 26,
        productsScanned: 18,
        proposals: [proposal()],
        actions: [action()],
        tasks: [task()],
      );
      for (final e in entries) {
        for (final banned in [
          'correlationId',
          'AgentTask',
          'BusinessAction',
          'ProposedChange',
          '_table',
          'rule:',
          'demo:',
          'idempotency',
        ]) {
          expect(
            e.text.contains(banned),
            isFalse,
            reason: '"${e.text}" lộ từ vựng hệ thống "$banned"',
          );
        }
      }
    });
  });
}
