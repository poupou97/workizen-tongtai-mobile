import 'package:drift/drift.dart' show InsertMode, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/consumer/external_identity.dart';
import 'package:tongtai/features/tongtai/consumer/external_identity_repository.dart';
import 'package:tongtai/features/tongtai/consumer/identity_resolver.dart';
import 'package:tongtai/features/tongtai/core/local_workspace.dart';

/// WTM-291 · N0.3 — Identity Resolution (ADR-TON-024).
///
/// Bốn luật của ADR, và **cả bốn đều là TỪ CHỐI**: chúng nói app *không* được
/// làm gì. Một luật từ chối không tự chứng minh bằng ảnh chụp màn hình — nó chỉ
/// chứng minh được bằng test cố tình đẩy hệ thống tới chỗ vi phạm rồi kiểm tra
/// hệ thống không đi.
void main() {
  late AppDatabase db;
  late DriftExternalIdentityRepository repo;
  var idCounter = 0;
  var clock = DateTime(2026, 8, 7, 9);

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    idCounter = 0;
    clock = DateTime(2026, 8, 7, 9);
    repo = DriftExternalIdentityRepository(
      db,
      now: () => clock = clock.add(const Duration(minutes: 1)),
      newId: () => 'evt-${++idCounter}',
    );
  });
  tearDown(() => db.close());

  Future<void> seedCustomer(String id, String name) async {
    final businessId = await const LocalWorkspace().ensureBusinessId(db);
    await db
        .into(db.customersTable)
        .insert(
          CustomersTableCompanion.insert(
            id: id,
            businessId: businessId,
            name: name,
            phone: const Value('+84912345678'),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  ExternalIdentity identity({
    String id = 'ident-1',
    String platform = 'shopee',
    String externalId = 'buyer-9001',
    String connectionId = 'conn-shop-a',
    String customerId = 'cust-1',
    IdentityConfidence confidence = IdentityConfidence.exact,
    IdentityLinkKind linkKind = IdentityLinkKind.automatic,
    String? displayName,
  }) => ExternalIdentity(
    id: id,
    platform: platform,
    externalId: externalId,
    connectionId: connectionId,
    customerId: customerId,
    confidence: confidence,
    linkKind: linkKind,
    linkedAt: DateTime(2026, 8, 7),
    displayName: displayName,
  );

  // ────────────────────────────────────────────────────────────────────────
  group('Luật 1 · exact ⇒ được tự động liên kết', () {
    test('exact là mức DUY NHẤT cho phép tự động', () {
      for (final c in IdentityConfidence.values) {
        expect(
          c.canAutoLink,
          c == IdentityConfidence.exact,
          reason:
              '${c.code}.canAutoLink phải là ${c == IdentityConfidence.exact}',
        );
      }
    });

    test('danh tính đã gắn ⇒ resolver trả AutoLink về đúng khách cũ', () {
      final decision = const IdentityResolver().resolve(
        platform: 'shopee',
        externalId: 'buyer-9001',
        connectionId: 'conn-shop-a',
        existing: [identity(customerId: 'cust-1')],
      );
      expect(decision, isA<AutoLink>());
      expect((decision as AutoLink).customerId, 'cust-1');
    });

    test('cùng externalId nhưng KHÁC kết nối ⇒ không phải người đó', () {
      // Shopee chỉ bảo đảm buyer_id duy nhất TRONG một shop. Bỏ connectionId
      // khỏi phép so là tự tay gộp khách của hai shop làm một.
      final decision = const IdentityResolver().resolve(
        platform: 'shopee',
        externalId: 'buyer-9001',
        connectionId: 'conn-shop-B',
        existing: [identity(connectionId: 'conn-shop-a')],
      );
      expect(decision, isA<NoMatch>());
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Luật 2 · strong ⇒ CHỈ đề xuất, không tự liên kết', () {
    test('strong đề xuất được nhưng không tự động được', () {
      expect(IdentityConfidence.strong.canSuggest, isTrue);
      expect(IdentityConfidence.strong.canAutoLink, isFalse);
    });

    test('trùng số điện thoại ⇒ SuggestLink, KHÔNG phải AutoLink', () {
      // Hai người thật dùng chung một số là chuyện phổ biến ở Việt Nam —
      // vợ chồng, mẹ con, số cửa hàng.
      final decision = const IdentityResolver().resolve(
        platform: 'messenger',
        externalId: 'psid-77',
        connectionId: 'conn-fb',
        existing: const [],
        candidates: const [
          IdentityCandidate(
            customerId: 'cust-1',
            signal: IdentityMatchSignal.phone,
            confidence: IdentityConfidence.strong,
          ),
        ],
      );
      expect(decision, isA<SuggestLink>());
      expect(decision, isNot(isA<AutoLink>()));
      expect((decision as SuggestLink).confidence, IdentityConfidence.strong);
      expect(decision.signal, IdentityMatchSignal.phone);
    });

    test('trùng email cũng chỉ là đề xuất', () {
      final decision = const IdentityResolver().resolve(
        platform: 'email',
        externalId: 'a@example.com',
        connectionId: 'conn-mail',
        existing: const [],
        candidates: const [
          IdentityCandidate(
            customerId: 'cust-2',
            signal: IdentityMatchSignal.email,
            confidence: IdentityConfidence.strong,
          ),
        ],
      );
      expect(decision, isA<SuggestLink>());
    });

    test('AutoLink không dựng được với mức thấp hơn exact', () {
      // Luật 2 không chỉ nằm ở nhánh if — kiểu dữ liệu tự bảo vệ nó. Ai đó
      // gọi thẳng AutoLink với `strong` vẫn phải vấp.
      for (final c in IdentityConfidence.values.where(
        (c) => c != IdentityConfidence.exact,
      )) {
        expect(
          () => AutoLink(customerId: 'cust-1', confidence: c),
          throwsA(isA<AssertionError>()),
          reason: 'AutoLink(${c.code}) phải bị chặn ngay tại constructor',
        );
      }
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Luật 3 · weak/none ⇒ không đề xuất gì', () {
    test('weak và none đều không đề xuất được', () {
      expect(IdentityConfidence.weak.canSuggest, isFalse);
      expect(IdentityConfidence.none.canSuggest, isFalse);
    });

    test('tên gần giống KHÔNG sinh ra đề xuất', () {
      // displayName có trong model nhưng resolve() không nhận nó — khớp theo
      // tên là nguồn của `weak`, và `weak` không tự động hoá gì cả.
      final decision = const IdentityResolver().resolve(
        platform: 'shopee',
        externalId: 'buyer-new',
        connectionId: 'conn-shop-a',
        existing: [identity(displayName: 'Nguyễn Văn A')],
      );
      expect(decision, isA<NoMatch>());
    });

    test('ứng viên mức weak KHÔNG sinh ra đề xuất', () {
      final decision = const IdentityResolver().resolve(
        platform: 'shopee',
        externalId: 'buyer-new',
        connectionId: 'conn-shop-a',
        existing: const [],
        candidates: const [
          IdentityCandidate(
            customerId: 'cust-1',
            signal: IdentityMatchSignal.phone,
            confidence: IdentityConfidence.weak,
          ),
        ],
      );
      expect(decision, isA<NoMatch>());
    });

    test('SuggestLink không dựng được với weak/none', () {
      for (final c in [IdentityConfidence.weak, IdentityConfidence.none]) {
        expect(
          () => SuggestLink(
            candidate: IdentityCandidate(
              customerId: 'cust-1',
              signal: IdentityMatchSignal.phone,
              confidence: c,
            ),
          ),
          throwsA(isA<AssertionError>()),
          reason: 'SuggestLink(${c.code}) phải bị chặn tại constructor',
        );
      }
    });

    test('ứng viên tự nhận exact vẫn CHỈ là đề xuất, và bị hạ về strong', () {
      // Tự động chỉ dành cho khoá do chính nền tảng cấp. Một luật khớp tự
      // gán cho mình mức `exact` không được mở đường tắt — nếu không thì luật
      // 2 vô hiệu chỉ bằng cách đổi một hằng số trong luật khớp.
      final decision = const IdentityResolver().resolve(
        platform: 'shopee',
        externalId: 'buyer-new',
        connectionId: 'conn-shop-a',
        existing: const [],
        candidates: const [
          IdentityCandidate(
            customerId: 'cust-1',
            signal: IdentityMatchSignal.phone,
            confidence: IdentityConfidence.exact,
          ),
        ],
      );
      expect(decision, isA<SuggestLink>());
      expect((decision as SuggestLink).confidence, IdentityConfidence.strong);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Luật 4 · không có API nào tự động gộp bản ghi khách', () {
    test('moveToCustomer đổi chủ MỘT danh tính, không xoá khách nào', () async {
      await seedCustomer('cust-1', 'Chị Hoa');
      await seedCustomer('cust-2', 'Chị Hoà');
      await repo.link(identity(), actor: IdentityLinkEvent.actorSeller);

      await repo.moveToCustomer(
        'ident-1',
        toCustomerId: 'cust-2',
        actor: IdentityLinkEvent.actorSeller,
      );

      // Danh tính đổi chủ…
      expect(await repo.loadForCustomer('cust-1'), isEmpty);
      expect(await repo.loadForCustomer('cust-2'), hasLength(1));
      // …nhưng CẢ HAI bản ghi khách vẫn còn nguyên. Đó là khác biệt giữa
      // "liên kết" và "gộp".
      final customers = await db.select(db.customersTable).get();
      expect(customers.map((c) => c.id), containsAll(['cust-1', 'cust-2']));
    });

    test(
      'người bán sửa tay ⇒ liên kết thành manual, thắng luật tự động',
      () async {
        await seedCustomer('cust-1', 'Chị Hoa');
        await seedCustomer('cust-2', 'Chị Hoà');
        await repo.link(
          identity(linkKind: IdentityLinkKind.automatic),
          actor: IdentityLinkEvent.actorRule('phone-match'),
        );

        await repo.moveToCustomer(
          'ident-1',
          toCustomerId: 'cust-2',
          actor: IdentityLinkEvent.actorSeller,
        );

        final moved = (await repo.loadForCustomer('cust-2')).single;
        expect(moved.linkKind, IdentityLinkKind.manual);
        expect(moved.outranksAutomation, isTrue);
      },
    );
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Lịch sử — điều kiện để tự động hoá được phép tồn tại', () {
    test(
      'link · move · unlink đều để lại một dòng, và không dòng nào mất',
      () async {
        await seedCustomer('cust-1', 'Chị Hoa');
        await seedCustomer('cust-2', 'Chị Hoà');

        await repo.link(
          identity(),
          actor: IdentityLinkEvent.actorRule('shopee'),
        );
        await repo.moveToCustomer(
          'ident-1',
          toCustomerId: 'cust-2',
          actor: IdentityLinkEvent.actorSeller,
        );
        await repo.unlink('ident-1', actor: IdentityLinkEvent.actorSeller);

        final history = await repo.historyFor('ident-1');
        expect(
          history.map((e) => e.action),
          // mới nhất trước
          [
            IdentityLinkAction.unlinked,
            IdentityLinkAction.moved,
            IdentityLinkAction.linked,
          ],
        );
        // Gỡ liên kết xoá dòng danh tính nhưng KHÔNG xoá bằng chứng — đó là lý
        // do bảng lịch sử không có khoá ngoại tới bảng danh tính.
        expect(await repo.loadForCustomer('cust-2'), isEmpty);
        expect(history, hasLength(3));
      },
    );

    test('một luật sai ⇒ tìm được TẤT CẢ thứ nó đã gắn', () async {
      await seedCustomer('cust-1', 'Chị Hoa');
      await seedCustomer('cust-2', 'Chị Hoà');
      const badRule = 'name-similarity';
      await repo.link(
        identity(id: 'i1', externalId: 'b1'),
        actor: IdentityLinkEvent.actorRule(badRule),
      );
      await repo.link(
        identity(id: 'i2', externalId: 'b2', customerId: 'cust-2'),
        actor: IdentityLinkEvent.actorRule(badRule),
      );
      await repo.link(
        identity(id: 'i3', externalId: 'b3'),
        actor: IdentityLinkEvent.actorSeller,
      );

      final byRule = await repo.eventsByActor(
        IdentityLinkEvent.actorRule(badRule),
      );
      expect(byRule.map((e) => e.identityId), containsAll(['i1', 'i2']));
      // Thứ người bán tự gắn KHÔNG nằm trong danh sách gỡ hàng loạt.
      expect(byRule.map((e) => e.identityId), isNot(contains('i3')));
    });

    test('lịch sử ghi lại mức tin cậy đã tin lúc đó', () async {
      await seedCustomer('cust-1', 'Chị Hoa');
      await repo.link(identity(), actor: IdentityLinkEvent.actorSeller);
      final event = (await repo.historyFor('ident-1')).single;
      expect(event.confidence, IdentityConfidence.exact);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Bền vững trên máy (schema v19)', () {
    test('round-trip đủ mọi trường', () async {
      await seedCustomer('cust-1', 'Chị Hoa');
      await repo.link(
        identity(displayName: 'Hoa Shop'),
        actor: IdentityLinkEvent.actorSeller,
      );

      final loaded = (await repo.loadForCustomer('cust-1')).single;
      expect(loaded.platform, 'shopee');
      expect(loaded.externalId, 'buyer-9001');
      expect(loaded.connectionId, 'conn-shop-a');
      expect(loaded.confidence, IdentityConfidence.exact);
      expect(loaded.displayName, 'Hoa Shop');
      // null = CHƯA xác nhận, không phải "xác nhận lúc 0".
      expect(loaded.verifiedAt, isNull);
    });

    test('cùng (kết nối, nền tảng, externalId) là DUY NHẤT', () async {
      await seedCustomer('cust-1', 'Chị Hoa');
      await seedCustomer('cust-2', 'Chị Hoà');
      await repo.link(identity(id: 'i1'), actor: IdentityLinkEvent.actorSeller);

      // Cùng khoá, id khác, khách khác ⇒ phải vấp chỉ mục duy nhất, không
      // được lặng lẽ tạo ra hai bản ghi cho cùng một người.
      await expectLater(
        repo.link(
          identity(id: 'i2', customerId: 'cust-2'),
          actor: IdentityLinkEvent.actorSeller,
        ),
        throwsA(anything),
      );
    });

    test('hai kết nối khác nhau giữ được cùng externalId', () async {
      await seedCustomer('cust-1', 'Chị Hoa');
      await seedCustomer('cust-2', 'Chị Hoà');
      await repo.link(
        identity(id: 'i1', connectionId: 'conn-shop-a'),
        actor: IdentityLinkEvent.actorSeller,
      );
      await repo.link(
        identity(id: 'i2', connectionId: 'conn-shop-b', customerId: 'cust-2'),
        actor: IdentityLinkEvent.actorSeller,
      );

      expect(await repo.loadForConnection('conn-shop-a'), hasLength(1));
      expect(await repo.loadForConnection('conn-shop-b'), hasLength(1));
    });

    test('mã confidence lạ ⇒ dòng bị BỎ QUA, không rơi về exact', () async {
      await seedCustomer('cust-1', 'Chị Hoa');
      final businessId = await const LocalWorkspace().ensureBusinessId(db);
      await db
          .into(db.externalIdentitiesTable)
          .insert(
            ExternalIdentitiesTableCompanion.insert(
              id: 'corrupt',
              businessId: businessId,
              platform: 'shopee',
              externalId: 'buyer-x',
              connectionId: 'conn-shop-a',
              customerId: 'cust-1',
              confidence: 'very-sure', // không thuộc từ vựng canonical
              linkKind: IdentityLinkKind.automatic.code,
              linkedAt: DateTime(2026, 8, 7),
            ),
          );

      expect(await repo.loadForCustomer('cust-1'), isEmpty);
      expect(IdentityConfidence.fromCode('very-sure'), isNull);
    });

    test('xoá khách ⇒ danh tính mồ côi biến mất theo', () async {
      await seedCustomer('cust-1', 'Chị Hoa');
      await repo.link(identity(), actor: IdentityLinkEvent.actorSeller);
      await (db.delete(
        db.customersTable,
      )..where((t) => t.id.equals('cust-1'))).go();
      expect(await repo.loadForCustomer('cust-1'), isEmpty);
      // …nhưng lịch sử vẫn còn: bằng chứng sống lâu hơn thứ nó ghi lại.
      expect(await repo.historyFor('ident-1'), isNotEmpty);
    });

    test('deleteAll dọn cả hai bảng (WTM-164 restore Replace)', () async {
      await seedCustomer('cust-1', 'Chị Hoa');
      await repo.link(identity(), actor: IdentityLinkEvent.actorSeller);
      await repo.deleteAll();
      expect(await repo.loadForCustomer('cust-1'), isEmpty);
      expect(await repo.historyFor('ident-1'), isEmpty);
    });
  });
}
