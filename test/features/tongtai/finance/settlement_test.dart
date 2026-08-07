import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/core/provenance.dart';
import 'package:tongtai/features/tongtai/finance/settlement.dart';
import 'package:tongtai/features/tongtai/finance/settlement_allocation.dart';
import 'package:tongtai/features/tongtai/finance/settlement_repository.dart';
import 'package:tongtai/features/tongtai/finance/true_profit.dart';

/// WTM-292 · N0.4 — Settlement Domain (ADR-TON-024 luật 2).
///
/// Phí sàn hiện là giao dịch rời trong Finance, không gắn đơn nào. Import đơn
/// từ sàn sẽ cho **doanh thu đúng và lợi nhuận sai** — sai theo hướng *tâng
/// bốc*, tức hướng người bán không nghi ngờ. Suite này khoá ba luật giữ cho
/// điều đó không xảy ra.
void main() {
  late AppDatabase db;
  late DriftSettlementRepository repo;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    repo = DriftSettlementRepository(db);
  });
  tearDown(() => db.close());

  SettlementLine line({
    String id = 'sl-1',
    String orderId = 'ord-1',
    String? orderItemId,
    SettlementKind kind = SettlementKind.platformFee,
    SettlementDirection direction = SettlementDirection.outbound,
    double amount = 50000,
    FundingSource fundedBy = FundingSource.seller,
    double? sellerShare,
    String? payoutId,
    Provenance provenance = Provenance.manual,
  }) => SettlementLine(
    id: id,
    orderId: orderId,
    orderItemId: orderItemId,
    kind: kind,
    direction: direction,
    amount: amount,
    currency: 'VND',
    occurredAt: DateTime(2026, 8, 7),
    fundedBy: fundedBy,
    sellerShare: sellerShare,
    payoutId: payoutId,
    provenance: provenance,
  );

  // ────────────────────────────────────────────────────────────────────────
  group('Luật 1 · amount luôn dương, chiều nằm ở direction', () {
    test('số âm bị chặn ngay tại constructor', () {
      expect(() => line(amount: -50000), throwsA(isA<AssertionError>()));
    });

    test('cùng kind, hai chiều ⇒ hai dấu — không đổi dấu của amount', () {
      // Phí sàn và hoàn lại phí sàn đều là `platformFee`. Nếu chiều nằm ở dấu
      // của số thì connector A viết -50000 và connector B viết 50000 cho cùng
      // một sự việc, và không ai phát hiện tới khi báo cáo lệch.
      final phi = line(direction: SettlementDirection.outbound);
      final hoanPhi = line(id: 'sl-2', direction: SettlementDirection.inbound);
      expect(phi.amount, hoanPhi.amount, reason: 'cùng một con số tiền');
      expect(phi.signedImpact, -50000);
      expect(hoanPhi.signedImpact, 50000);
    });

    test(
      'amount âm trên đĩa ⇒ dòng bị BỎ QUA, không đọc thành chiều ngược',
      () async {
        await repo.upsert(line());
        await db.customStatement(
          "UPDATE settlement_lines_table SET amount = -50000 WHERE id = 'sl-1'",
        );
        expect(await repo.loadForOrder('ord-1'), isEmpty);
      },
    );
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Luật 2 · fundedBy bắt buộc, không có mặc định', () {
    test('voucher/discount là hai loại BẮT BUỘC khai ai trả', () {
      for (final k in SettlementKind.values) {
        final expected =
            k == SettlementKind.voucher || k == SettlementKind.discount;
        expect(k.requiresFundingSource, expected, reason: k.code);
      }
    });

    test('sàn tài trợ ⇒ KHÔNG phải chi phí của người bán', () {
      final v = line(
        kind: SettlementKind.voucher,
        fundedBy: FundingSource.platform,
        amount: 30000,
      );
      expect(v.sellerBorneAmount, 0);
      expect(v.signedImpact, 0);
    });

    test('người bán chịu ⇒ trừ thẳng vào lợi nhuận', () {
      final v = line(
        kind: SettlementKind.voucher,
        fundedBy: FundingSource.seller,
        amount: 30000,
      );
      expect(v.signedImpact, -30000);
    });

    test('shared KHÔNG có tỷ lệ = unknown mặc áo khác', () {
      final v = line(fundedBy: FundingSource.shared);
      expect(v.fundingIsKnown, isFalse);
      // Và đọc số ra thì NÉM, không trả 0 — trả 0 là đúng cách một con số bịa
      // lọt vào báo cáo.
      expect(() => v.sellerBorneAmount, throwsA(isA<StateError>()));
    });

    test('shared có tỷ lệ ⇒ chia đúng phần người bán', () {
      final v = line(
        fundedBy: FundingSource.shared,
        sellerShare: 0.4,
        amount: 100000,
      );
      expect(v.fundingIsKnown, isTrue);
      expect(v.sellerBorneAmount, closeTo(40000, 0.001));
    });

    test('unknown ⇒ chưa biết, KHÔNG "coi như sàn trả"', () {
      final v = line(fundedBy: FundingSource.unknown);
      expect(v.fundingIsKnown, isFalse);
      expect(() => v.sellerBorneAmount, throwsA(isA<StateError>()));
    });

    test('tỷ lệ ngoài 0..1 bị chặn tại constructor', () {
      expect(
        () => line(fundedBy: FundingSource.shared, sellerShare: 1.5),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Luật 3 · cấm tự động phân bổ', () {
    test('phân bổ chia theo doanh thu, không chia đều', () {
      // Một đơn có món 5 triệu và ba món 50 nghìn thì chia đều là bịa.
      final result = allocateByRevenue(line(amount: 30000), {
        'item-lon': 5000000,
        'item-nho': 50000,
      });
      final lon = result.firstWhere((a) => a.orderItemId == 'item-lon');
      final nho = result.firstWhere((a) => a.orderItemId == 'item-nho');
      expect(lon.amount, greaterThan(nho.amount * 90));
      expect(lon.amount + nho.amount, closeTo(30000, 0.001));
    });

    test('kết quả phân bổ KHÔNG phải SettlementLine — không có gì để lưu', () {
      final result = allocateByRevenue(line(), {'i1': 100});
      expect(result.single, isA<AllocatedSettlement>());
      expect(result.single, isNot(isA<SettlementLine>()));
      // Không có `id` ⇒ không có khoá để ghi vào bảng.
      expect(result.single.sourceLineId, 'sl-1');
    });

    test('khoản đã gắn món ⇒ không chia nữa', () {
      expect(allocateByRevenue(line(orderItemId: 'i1'), {'i1': 100}), isEmpty);
    });

    test('không có món, hoặc doanh thu bằng 0 ⇒ rỗng, không chia cho 0', () {
      expect(allocateByRevenue(line(), const {}), isEmpty);
      expect(allocateByRevenue(line(), {'i1': 0, 'i2': 0}), isEmpty);
    });

    test('ghi rồi đọc lại ⇒ ĐÚNG một dòng, không sinh thêm dòng nào', () async {
      // Luật 3 nhìn từ đường ghi: `upsert` một khoản cấp đơn phải cho đúng một
      // dòng trong bảng — không có bước phân bổ ngầm nào chạy kèm.
      await repo.upsert(line());
      final stored = await db.select(db.settlementLinesTable).get();
      expect(stored, hasLength(1));
      expect(stored.single.orderItemId, isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Rule Twin lợi nhuận thật — từ chối khi thiếu', () {
    const rule = TrueProfitRule();

    test('đủ dữ liệu ⇒ trả số, và số đó trừ đúng phần người bán chịu', () {
      final result = rule.compute(
        revenue: 1000000,
        itemCosts: {'i1': 600000},
        lines: [
          line(amount: 120000), // phí, người bán chịu
          line(
            id: 'sl-2',
            kind: SettlementKind.voucher,
            fundedBy: FundingSource.platform,
            amount: 50000,
          ), // sàn tài trợ ⇒ không tính
        ],
      );
      expect(result, isA<ProfitKnown>());
      expect((result as ProfitKnown).amount, closeTo(280000, 0.001));
    });

    test('thiếu giá vốn ⇒ insufficient, KHÔNG coi giá vốn bằng 0', () {
      final result = rule.compute(
        revenue: 1000000,
        itemCosts: {'i1': null},
        lines: const [],
      );
      expect(result, isA<ProfitInsufficient>());
      expect(
        (result as ProfitInsufficient).blockers,
        contains(ProfitBlocker.missingCost),
      );
    });

    test('có khoản chưa biết ai trả ⇒ insufficient', () {
      final result = rule.compute(
        revenue: 1000000,
        itemCosts: {'i1': 600000},
        lines: [line(fundedBy: FundingSource.unknown)],
      );
      expect(
        (result as ProfitInsufficient).blockers,
        contains(ProfitBlocker.unknownFunding),
      );
    });

    test('lô lệch quá ngưỡng ⇒ insufficient; lệch lẻ đồng thì không', () {
      Payout payout(double? delta) => Payout(
        id: 'po-1',
        connectionId: 'conn-1',
        amount: 900000,
        currency: 'VND',
        settledAt: DateTime(2026, 8, 7),
        reconciledDelta: delta,
      );

      expect(
        rule.compute(
          revenue: 1000000,
          itemCosts: {'i1': 600000},
          lines: const [],
          payouts: [payout(47000)],
        ),
        isA<ProfitInsufficient>(),
      );
      expect(
        rule.compute(
          revenue: 1000000,
          itemCosts: {'i1': 600000},
          lines: const [],
          payouts: [payout(-500)],
        ),
        isA<ProfitKnown>(),
      );
    });

    test('nhiều thứ thiếu ⇒ liệt kê ĐỦ, không dừng ở cái đầu tiên', () {
      final result =
          rule.compute(
                revenue: 1000000,
                itemCosts: {'i1': null},
                lines: [line(fundedBy: FundingSource.unknown)],
              )
              as ProfitInsufficient;
      expect(result.blockers, hasLength(2));
    });

    test('insufficient rỗng không dựng được', () {
      expect(
        () => ProfitInsufficient(const []),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Bền vững trên máy (schema v20)', () {
    test('round-trip đủ mọi trường', () async {
      await repo.upsert(
        line(
          orderItemId: 'item-9',
          kind: SettlementKind.commission,
          fundedBy: FundingSource.shared,
          sellerShare: 0.3,
          payoutId: 'po-1',
        ),
      );
      final loaded = (await repo.loadForOrder('ord-1')).single;
      expect(loaded.orderItemId, 'item-9');
      expect(loaded.kind, SettlementKind.commission);
      expect(loaded.fundedBy, FundingSource.shared);
      expect(loaded.sellerShare, closeTo(0.3, 0.001));
      expect(loaded.payoutId, 'po-1');
    });

    test('mã fundedBy lạ ⇒ dòng bị BỎ QUA, không rơi về platform', () async {
      // Rơi về `platform` sẽ khiến app khai rằng sàn tài trợ khoản này, và lợi
      // nhuận hiện lên cao hơn thực tế — sai theo hướng không ai nghi ngờ.
      await repo.upsert(line());
      await db.customStatement(
        "UPDATE settlement_lines_table SET funded_by = 'ai-do-tra' "
        "WHERE id = 'sl-1'",
      );
      expect(await repo.loadForOrder('ord-1'), isEmpty);
      expect(FundingSource.fromCode('ai-do-tra'), isNull);
    });

    test('mã kind lạ ⇒ dòng bị BỎ QUA, không ánh xạ về mã gần giống', () async {
      await repo.upsert(line());
      await db.customStatement(
        "UPDATE settlement_lines_table SET kind = 'platform_fee_v2' "
        "WHERE id = 'sl-1'",
      );
      expect(await repo.loadForOrder('ord-1'), isEmpty);
    });

    test(
      'payout: null delta = CHƯA đối soát, 0 = đã đối soát và khớp',
      () async {
        await repo.upsertPayout(
          Payout(
            id: 'po-1',
            connectionId: 'conn-1',
            amount: 900000,
            currency: 'VND',
            settledAt: DateTime(2026, 8, 7),
          ),
        );
        expect((await repo.loadPayouts()).single.isReconciled, isFalse);

        await repo.recordReconciliation('po-1', 0);
        final after = (await repo.loadPayouts()).single;
        expect(after.isReconciled, isTrue);
        expect(after.reconciledDelta, 0);
      },
    );

    test('lệch được GIỮ NGUYÊN, không san bằng', () async {
      await repo.upsertPayout(
        Payout(
          id: 'po-1',
          connectionId: 'conn-1',
          amount: 900000,
          currency: 'VND',
          settledAt: DateTime(2026, 8, 7),
        ),
      );
      await repo.recordReconciliation('po-1', -47000);
      expect((await repo.loadPayouts()).single.reconciledDelta, -47000);
      // Và KHÔNG có dòng "điều chỉnh" nào được bịa ra để ép cho khớp.
      expect(await db.select(db.settlementLinesTable).get(), isEmpty);
    });

    test('provenance suy đoán KHÔNG được ghi thành lời khai', () async {
      // Một dòng chưa ai khai nguồn gốc: `storedCode` là null, nên trên đĩa
      // không có gì. Đọc lại thì suy từ tiền tố id và **vẫn đánh dấu là suy
      // đoán** — kỷ luật v17: ghi một phỏng đoán xuống đĩa sẽ biến nó thành
      // lời khai, và lần đọc sau không còn ai biết đó từng là phỏng đoán.
      await repo.upsert(
        line(id: 'sample-sl-1', provenance: Provenance.inferFromId('sample-')),
      );
      final stored = await db.select(db.settlementLinesTable).get();
      expect(
        stored.single.provenanceCode,
        isNull,
        reason: 'không ghi suy đoán',
      );

      final loaded = (await repo.loadForOrder('ord-1')).single;
      expect(loaded.provenance.source, ProvenanceSource.sample);
      expect(loaded.provenance.inferred, isTrue);
    });

    test('provenance đã khai thì được ghi và đọc lại nguyên vẹn', () async {
      await repo.upsert(
        line(
          id: 'sl-conn',
          provenance: const Provenance.declared(ProvenanceSource.connector),
        ),
      );
      final loaded = (await repo.loadForOrder('ord-1')).single;
      expect(loaded.provenance.source, ProvenanceSource.connector);
      expect(loaded.provenance.inferred, isFalse);
    });

    test('deleteByIdPrefix gỡ đúng dữ liệu mẫu (ADR-TON-014)', () async {
      await repo.upsert(line(id: 'sample-sl-1'));
      await repo.upsert(line(id: 'sl-2'));
      await repo.deleteByIdPrefix('sample-');
      expect((await repo.loadForOrder('ord-1')).map((l) => l.id), ['sl-2']);
    });

    test('deleteAll dọn cả hai bảng (WTM-164 restore Replace)', () async {
      await repo.upsert(line());
      await repo.upsertPayout(
        Payout(
          id: 'po-1',
          connectionId: 'conn-1',
          amount: 1,
          currency: 'VND',
          settledAt: DateTime(2026, 8, 7),
        ),
      );
      await repo.deleteAll();
      expect(await repo.loadForOrder('ord-1'), isEmpty);
      expect(await repo.loadPayouts(), isEmpty);
    });
  });
}
