import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/consumer/external_identity.dart';
import 'package:tongtai/features/tongtai/consumer/identity_evidence.dart';
import 'package:tongtai/features/tongtai/proposal/proposal_gate.dart';
import 'package:tongtai/features/tongtai/proposal/proposed_change.dart';
import 'package:tongtai/features/tongtai/proposal/proposed_change_repository.dart';

/// WTM-299 · D-2 — vòng đề xuất bền vững trên máy (schema v21).
///
/// Điểm của phase này: một đề xuất phải **sống qua một lần đóng app**. Trước
/// đó `SuggestLink` chỉ là giá trị trong bộ nhớ, nên Tổng Tài không thể lên
/// mức **L2 · Prepare**.
void main() {
  late AppDatabase db;
  late DriftProposedChangeRepository repo;
  var clock = DateTime(2026, 8, 8, 9);

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    clock = DateTime(2026, 8, 8, 9);
    repo = DriftProposedChangeRepository(db, now: () => clock);
  });
  tearDown(() => db.close());

  ProposedChange proposal({
    String id = 'p1',
    ProposalDomain domain = ProposalDomain.pricing,
    String field = 'costPrice',
    String value = '45000',
    String? correlationId,
    List<IdentityEvidenceKind> kinds = const [
      IdentityEvidenceKind.orderHistoryMatch,
    ],
  }) => ProposedChange(
    id: id,
    correlationId: correlationId,
    domain: domain,
    subjectKind: 'product',
    subjectId: 'prod-1',
    subjectLabel: 'Nồi chiên không dầu',
    field: field,
    currentValue: '38000',
    proposedValue: value,
    evidence: [
      for (var i = 0; i < kinds.length; i++)
        IdentityEvidence(kind: kinds[i], source: 'src-$i'),
    ],
    proposedBy: ProposalAuthor.rule('cost-from-orders'),
    summary: 'Giá vốn nên là 45.000 — tính từ 12 đơn gần nhất',
    createdAt: clock,
  );

  // ────────────────────────────────────────────────────────────────────────
  group('Sống qua một lần đóng app', () {
    test('đề xuất ghi rồi đọc lại đủ mọi trường', () async {
      await repo.propose(proposal(), humanOwnsField: false);
      final loaded = (await repo.loadOpen()).single;

      expect(loaded.id, 'p1');
      expect(loaded.domain, ProposalDomain.pricing);
      expect(loaded.subjectLabel, 'Nồi chiên không dầu');
      expect(loaded.currentValue, '38000');
      expect(loaded.proposedValue, '45000');
      expect(loaded.summary, contains('12 đơn gần nhất'));
      expect(loaded.proposedBy.code, 'rule:cost-from-orders');
      // `null` = CHƯA ai quyết, không phải "quyết lúc 0".
      expect(loaded.decidedAt, isNull);
    });

    test('mức tin cậy TÍNH lại lúc đọc, không lưu điểm', () async {
      await repo.propose(
        proposal(kinds: const [IdentityEvidenceKind.platformAccountId]),
        humanOwnsField: false,
      );
      final loaded = (await repo.loadOpen()).single;
      expect(loaded.confidence, IdentityConfidence.exact);
      expect(loaded.scored.countedSources, 1);
    });

    test('bằng chứng round-trip qua JSON, giữ cả `source`', () async {
      await repo.propose(
        proposal(
          kinds: const [
            IdentityEvidenceKind.orderHistoryMatch,
            IdentityEvidenceKind.emailExactMatch,
          ],
        ),
        humanOwnsField: false,
      );
      final loaded = (await repo.loadOpen()).single;
      expect(loaded.evidence, hasLength(2));
      expect(loaded.evidence.map((e) => e.source), ['src-0', 'src-1']);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Bốn cổng chạy thật qua repository', () {
    test('dưới sàn ⇒ KHÔNG có dòng nào được ghi', () async {
      final outcome = await repo.propose(
        proposal(kinds: const [IdentityEvidenceKind.addressSimilar]),
        humanOwnsField: false,
      );
      expect(outcome, isA<ProposalRejected>());
      expect(await db.select(db.proposedChangesTable).get(), isEmpty);
    });

    test('người bán đã điền ⇒ KHÔNG ghi', () async {
      final outcome = await repo.propose(proposal(), humanOwnsField: true);
      expect((outcome as ProposalRejected).reason, ProposalRejection.humanOwns);
      expect(await db.select(db.proposedChangesTable).get(), isEmpty);
    });

    test('đã bỏ qua và chưa tới hạn ⇒ KHÔNG đề nghị lại', () async {
      await repo.propose(proposal(), humanOwnsField: false);
      await repo.dismiss('p1');

      clock = DateTime(2026, 8, 20); // 12 ngày sau, chưa đủ 30
      final outcome = await repo.propose(
        proposal(id: 'p2'),
        humanOwnsField: false,
      );
      expect(
        (outcome as ProposalRejected).reason,
        ProposalRejection.dismissedAndNotDue,
      );
    });

    test('hết hạn ⇒ đề nghị lại được', () async {
      await repo.propose(proposal(), humanOwnsField: false);
      await repo.dismiss('p1');

      clock = DateTime(2026, 9, 20); // hơn 30 ngày
      final outcome = await repo.propose(
        proposal(id: 'p2'),
        humanOwnsField: false,
      );
      expect(outcome, isA<ProposalAccepted>());
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Quyết định là một chiều', () {
    test('duyệt rồi thì không duyệt lại được', () async {
      await repo.propose(proposal(), humanOwnsField: false);
      expect(await repo.apply('p1'), isTrue);
      expect(
        await repo.apply('p1'),
        isFalse,
        reason: 'hai lần bấm chỉ một lần đổi được',
      );
    });

    test('đã duyệt thì không bỏ qua được nữa', () async {
      await repo.propose(proposal(), humanOwnsField: false);
      await repo.apply('p1');
      expect(await repo.dismiss('p1'), isFalse);
    });

    test('quyết định ghi lại thời điểm', () async {
      await repo.propose(proposal(), humanOwnsField: false);
      clock = DateTime(2026, 8, 8, 14, 32);
      await repo.apply('p1');

      final row = (await db.select(db.proposedChangesTable).get()).single;
      expect(row.status, 'applied');
      expect(row.decidedAt, DateTime(2026, 8, 8, 14, 32));
    });

    test('đã quyết thì rời khỏi danh sách chờ', () async {
      await repo.propose(proposal(), humanOwnsField: false);
      await repo.apply('p1');
      expect(await repo.loadOpen(), isEmpty);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Thay thế KHÔNG xoá — phát hiện thay đổi là hệ quả', () {
    test('đề xuất cũ chuyển superseded, vẫn còn dòng', () async {
      await repo.propose(
        proposal(id: 'p1', value: '45000'),
        humanOwnsField: false,
      );
      await repo.propose(
        proposal(id: 'p2', value: '52000'),
        humanOwnsField: false,
      );

      final count = await repo.supersedeOlder(
        subjectKind: 'product',
        subjectId: 'prod-1',
        field: 'costPrice',
        keepId: 'p2',
      );

      expect(count, 1);
      final all = await db.select(db.proposedChangesTable).get();
      expect(all, hasLength(2), reason: 'không dòng nào bị xoá');
      expect(all.firstWhere((r) => r.id == 'p1').status, 'superseded');
      expect((await repo.loadOpen()).single.id, 'p2');
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Hiện ≠ giữ, và correlationId dựng được câu chuyện', () {
    test('weak được giữ nhưng không nằm trong danh sách hiện', () async {
      await repo.propose(
        proposal(
          kinds: const [
            IdentityEvidenceKind.nameExactMatch,
            IdentityEvidenceKind.addressSimilar,
          ],
        ),
        humanOwnsField: false,
      );
      expect(await repo.loadOpen(), hasLength(1));
      expect(await repo.loadVisible(), isEmpty);
    });

    test('correlationId gom được một chuỗi việc', () async {
      // Đây là thứ thay cho entity BusinessConversation: câu chuyện là một
      // TRUY VẤN, không phải một bảng.
      const chain = 'winback-2026-08-08';
      await repo.propose(
        proposal(id: 'p1', field: 'costPrice', correlationId: chain),
        humanOwnsField: false,
      );
      await repo.propose(
        proposal(id: 'p2', field: 'listPrice', correlationId: chain),
        humanOwnsField: false,
      );
      await repo.propose(
        proposal(id: 'p3', field: 'sku'),
        humanOwnsField: false,
      );

      final story = await repo.loadByCorrelation(chain);
      expect(story.map((p) => p.id), containsAll(['p1', 'p2']));
      expect(story.map((p) => p.id), isNot(contains('p3')));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Bản ghi hỏng bị BỎ QUA, không rơi về mặc định', () {
    test('mã status lạ ⇒ bỏ qua dòng', () async {
      await repo.propose(proposal(), humanOwnsField: false);
      await db.customStatement(
        "UPDATE proposed_changes_table SET status = 'maybe' WHERE id = 'p1'",
      );
      expect(await repo.loadOpen(), isEmpty);
      expect(ProposalStatus.fromCode('maybe'), isNull);
    });

    test('evidence JSON hỏng ⇒ bỏ qua dòng, không ném', () async {
      await repo.propose(proposal(), humanOwnsField: false);
      await db.customStatement(
        "UPDATE proposed_changes_table SET evidence = 'không-phải-json' "
        "WHERE id = 'p1'",
      );
      expect(await repo.loadOpen(), isEmpty);
    });

    test('deleteAll dọn sạch (WTM-164 restore Replace)', () async {
      await repo.propose(proposal(), humanOwnsField: false);
      await repo.deleteAll();
      expect(await repo.loadOpen(), isEmpty);
    });
  });
}
