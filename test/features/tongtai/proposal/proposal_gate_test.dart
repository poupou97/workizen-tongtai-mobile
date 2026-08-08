import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/external_identity.dart';
import 'package:tongtai/features/tongtai/consumer/identity_evidence.dart';
import 'package:tongtai/features/tongtai/proposal/proposal_gate.dart';
import 'package:tongtai/features/tongtai/proposal/proposed_change.dart';

/// WTM-299 · D-2 — bốn cổng, và luật xét lại theo MIỀN.
///
/// Cổng là hàm thuần: suite này chạy **không cần cơ sở dữ liệu**. Đó không phải
/// tiện lợi mà là bằng chứng — luật nghiệp vụ tách được khỏi chỗ lưu trữ, nên
/// không có đường vòng nào bỏ qua nó.
void main() {
  const gate = ProposalGate();
  final now = DateTime(2026, 8, 8, 12);

  ProposedChange proposal({
    String id = 'p1',
    ProposalDomain domain = ProposalDomain.pricing,
    String field = 'costPrice',
    String value = '45000',
    List<IdentityEvidenceKind> kinds = const [
      IdentityEvidenceKind.orderHistoryMatch,
    ],
    ProposalStatus status = ProposalStatus.proposed,
    DateTime? decidedAt,
  }) => ProposedChange(
    id: id,
    domain: domain,
    subjectKind: 'product',
    subjectId: 'prod-1',
    field: field,
    proposedValue: value,
    evidence: [
      for (var i = 0; i < kinds.length; i++)
        IdentityEvidence(kind: kinds[i], source: 'src-$i'),
    ],
    proposedBy: ProposalAuthor.rule('cost-from-orders'),
    summary: 'Giá vốn nên là 45.000',
    createdAt: DateTime(2026, 8, 1),
    status: status,
    decidedAt: decidedAt,
  );

  // ────────────────────────────────────────────────────────────────────────
  group('Cổng 1 · quá yếu ⇒ KHÔNG lưu gì', () {
    test('bằng chứng dưới sàn ⇒ từ chối, không phải lưu rồi ẩn', () {
      final outcome = gate.evaluate(
        proposal: proposal(kinds: const [IdentityEvidenceKind.addressSimilar]),
        existingForField: const [],
        humanOwns: false,
        now: now,
      );
      expect(outcome, isA<ProposalRejected>());
      expect(
        (outcome as ProposalRejected).reason,
        ProposalRejection.belowFloor,
      );
    });

    test('đủ mạnh ⇒ lưu ở trạng thái proposed', () {
      final outcome = gate.evaluate(
        proposal: proposal(),
        existingForField: const [],
        humanOwns: false,
        now: now,
      );
      expect(outcome, isA<ProposalAccepted>());
      expect((outcome as ProposalAccepted).status, ProposalStatus.proposed);
    });

    test('KHÔNG bao giờ tự chuyển applied, dù bằng chứng rất mạnh', () {
      // Tự áp dụng là bước sang L3, và L3 cần AutonomyRule (WTM-300), không
      // phải một ngưỡng điểm.
      final outcome =
          gate.evaluate(
                proposal: proposal(
                  kinds: const [
                    IdentityEvidenceKind.platformAccountId,
                    IdentityEvidenceKind.orderHistoryMatch,
                    IdentityEvidenceKind.emailExactMatch,
                  ],
                ),
                existingForField: const [],
                humanOwns: false,
                now: now,
              )
              as ProposalAccepted;
      expect(outcome.status, ProposalStatus.proposed);
      expect(outcome.status, isNot(ProposalStatus.applied));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Cổng 3 · người bán đã tự điền ⇒ THẮNG mọi bằng chứng', () {
    test('bằng chứng mạnh nhất cũng không ghi đè người', () {
      final outcome = gate.evaluate(
        proposal: proposal(
          kinds: const [IdentityEvidenceKind.platformAccountId],
        ),
        existingForField: const [],
        humanOwns: true,
        now: now,
      );
      expect((outcome as ProposalRejected).reason, ProposalRejection.humanOwns);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Cổng 4 · đã áp dụng đúng giá trị này rồi', () {
    test('không đề nghị lại thứ đã nằm trên bản ghi', () {
      final outcome = gate.evaluate(
        proposal: proposal(id: 'p2'),
        existingForField: [proposal(id: 'p1', status: ProposalStatus.applied)],
        humanOwns: false,
        now: now,
      );
      expect(
        (outcome as ProposalRejected).reason,
        ProposalRejection.alreadyApplied,
      );
    });

    test('giá trị KHÁC thì vẫn đề nghị được', () {
      final outcome = gate.evaluate(
        proposal: proposal(id: 'p2', value: '52000'),
        existingForField: [
          proposal(id: 'p1', value: '45000', status: ProposalStatus.applied),
        ],
        humanOwns: false,
        now: now,
      );
      expect(outcome, isA<ProposalAccepted>());
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('⭐ Cổng 2 · DISMISSED không vĩnh viễn cho mọi miền', () {
    test('danh tính ⇒ bỏ qua là VĨNH VIỄN', () {
      // Tên một người không đổi. Hỏi lại là làm phiền — đây là chỗ luật của
      // COMP AI đúng và ta giữ nguyên.
      final dismissed = proposal(
        domain: ProposalDomain.identity,
        field: 'name',
        status: ProposalStatus.dismissed,
        decidedAt: DateTime(2020, 1, 1),
      );
      final outcome = gate.evaluate(
        proposal: proposal(
          id: 'p2',
          domain: ProposalDomain.identity,
          field: 'name',
        ),
        existingForField: [dismissed],
        humanOwns: false,
        now: DateTime(2030, 1, 1), // mười năm sau
      );
      expect(
        (outcome as ProposalRejected).reason,
        ProposalRejection.dismissedAndNotDue,
      );
    });

    test('giá ⇒ được đề nghị lại sau 30 ngày', () {
      // Người bán bỏ qua "giá vốn nên là 45.000" hôm nay không có nghĩa là sáu
      // tháng sau vẫn vậy.
      final dismissed = proposal(
        status: ProposalStatus.dismissed,
        decidedAt: DateTime(2026, 7, 1),
      );

      final tooSoon = gate.evaluate(
        proposal: proposal(id: 'p2'),
        existingForField: [dismissed],
        humanOwns: false,
        now: DateTime(2026, 7, 20),
      );
      expect(tooSoon, isA<ProposalRejected>());

      final due = gate.evaluate(
        proposal: proposal(id: 'p2'),
        existingForField: [dismissed],
        humanOwns: false,
        now: DateTime(2026, 8, 5),
      );
      expect(due, isA<ProposalAccepted>());
    });

    test('bằng chứng MẠNH HƠN mở lại được ngay, kể cả danh tính', () {
      // Đường thứ hai Founder chỉ đạo: hết hạn HOẶC bằng chứng mạnh hơn.
      final dismissed = proposal(
        domain: ProposalDomain.identity,
        field: 'name',
        kinds: const [IdentityEvidenceKind.phoneExactMatch],
        status: ProposalStatus.dismissed,
        decidedAt: DateTime(2026, 8, 1),
      );
      final outcome = gate.evaluate(
        proposal: proposal(
          id: 'p2',
          domain: ProposalDomain.identity,
          field: 'name',
          kinds: const [IdentityEvidenceKind.platformAccountId],
        ),
        existingForField: [dismissed],
        humanOwns: false,
        now: DateTime(2026, 8, 2), // hôm sau
      );
      expect(
        outcome,
        isA<ProposalAccepted>(),
        reason: 'khoá nền tảng mạnh hơn số điện thoại ⇒ đáng hỏi lại',
      );
    });

    test('bằng chứng NGANG hoặc yếu hơn KHÔNG mở lại được', () {
      final dismissed = proposal(
        domain: ProposalDomain.identity,
        field: 'name',
        kinds: const [IdentityEvidenceKind.platformAccountId],
        status: ProposalStatus.dismissed,
        decidedAt: DateTime(2026, 8, 1),
      );
      final outcome = gate.evaluate(
        proposal: proposal(
          id: 'p2',
          domain: ProposalDomain.identity,
          field: 'name',
          kinds: const [IdentityEvidenceKind.phoneExactMatch],
        ),
        existingForField: [dismissed],
        humanOwns: false,
        now: DateTime(2026, 12, 1),
      );
      expect(outcome, isA<ProposalRejected>());
    });

    test('mỗi miền có luật riêng, và luật nằm TRÊN miền', () {
      expect(ProposalDomain.identity.reconsiderAfter, isNull);
      expect(ProposalDomain.pricing.reconsiderAfter, const Duration(days: 30));
      expect(
        ProposalDomain.customerProfile.reconsiderAfter,
        const Duration(days: 90),
      );
      // Mọi miền phải có câu trả lời — không miền nào rơi vào mặc định ngầm.
      for (final d in ProposalDomain.values) {
        expect(() => d.reconsiderAfter, returnsNormally, reason: d.code);
      }
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Hiện cho người bán ≠ giữ lại', () {
    test('weak được giữ nhưng KHÔNG hiện', () {
      final weak = proposal(
        kinds: const [
          IdentityEvidenceKind.nameExactMatch,
          IdentityEvidenceKind.addressSimilar,
        ],
      );
      expect(weak.confidence, IdentityConfidence.weak);
      expect(gate.shouldShow(weak), isFalse);
    });

    test('strong thì hiện', () {
      expect(gate.shouldShow(proposal()), isTrue);
    });

    test('đã quyết rồi thì không hiện nữa', () {
      expect(
        gate.shouldShow(proposal(status: ProposalStatus.applied)),
        isFalse,
      );
      expect(
        gate.shouldShow(proposal(status: ProposalStatus.dismissed)),
        isFalse,
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Đề xuất không dựng được nếu thiếu thứ bắt buộc', () {
    test('không bằng chứng ⇒ chặn tại constructor', () {
      expect(
        () => ProposedChange(
          id: 'x',
          domain: ProposalDomain.pricing,
          subjectKind: 'product',
          subjectId: 'p',
          field: 'costPrice',
          proposedValue: '1',
          evidence: const [],
          proposedBy: ProposalAuthor.agent,
          summary: 'x',
          createdAt: DateTime(2026),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('không có câu mô tả ⇒ chặn tại constructor', () {
      expect(
        () => ProposedChange(
          id: 'x',
          domain: ProposalDomain.pricing,
          subjectKind: 'product',
          subjectId: 'p',
          field: 'costPrice',
          proposedValue: '1',
          evidence: const [
            IdentityEvidence(
              kind: IdentityEvidenceKind.orderHistoryMatch,
              source: 's',
            ),
          ],
          proposedBy: ProposalAuthor.agent,
          summary: '',
          createdAt: DateTime(2026),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('confidence là TÍNH, không khai (WTM-298 giữ nguyên)', () {
      final p = proposal(kinds: const [IdentityEvidenceKind.platformAccountId]);
      expect(p.confidence, IdentityConfidence.exact);
      expect(p.scored.countedSources, 1);
    });
  });
}
