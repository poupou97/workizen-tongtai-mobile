import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/action/business_action.dart';
import 'package:tongtai/features/tongtai/action/business_action_executor.dart';

/// WTM-300 · D-3 — `BusinessAction` là cửa ghi duy nhất.
///
/// COMP AI có ba kỷ luật ghi song song và bề mặt mới nhất rơi vào đường yếu
/// nhất. Suite này khoá đúng bốn tính chất giữ cho điều đó không lặp lại:
/// idempotency · replay an toàn · lease · một transaction.
void main() {
  late AppDatabase db;
  var clock = DateTime(2026, 8, 8, 9);
  var effectRuns = 0;

  BusinessAction action({
    String id = 'a1',
    BusinessActionType type = BusinessActionType.applyProposedChange,
    ActionVendor vendor = ActionVendor.internal,
    Map<String, Object?> params = const {'proposalId': 'p1'},
    String key = 'apply:p1',
    String? correlationId,
    ActionStatus status = ActionStatus.planned,
    String? requestedBy,
  }) => BusinessAction(
    id: id,
    correlationId: correlationId,
    type: type,
    vendor: vendor,
    subjectKind: 'product',
    subjectId: 'prod-1',
    subjectLabel: 'Nồi chiên không dầu',
    summary: 'Cập nhật giá vốn thành 45.000',
    parameters: params,
    proposedBy: 'rule:cost-from-orders',
    requestedBy: requestedBy,
    idempotencyKey: key,
    requestHash: BusinessActionExecutor.hashRequest(params),
    plannedAt: clock,
    status: status,
  );

  BusinessActionExecutor executor({
    Map<BusinessActionType, ActionEffect>? handlers,
    Duration lease = const Duration(minutes: 5),
  }) => BusinessActionExecutor(
    db,
    now: () => clock,
    leaseDuration: lease,
    handlers:
        handlers ??
        {
          BusinessActionType.applyProposedChange: (_, a) async {
            effectRuns++;
            return 'internal-${a.id}';
          },
        },
  );

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    clock = DateTime(2026, 8, 8, 9);
    effectRuns = 0;
  });
  tearDown(() => db.close());

  // ────────────────────────────────────────────────────────────────────────
  group('⭐ Idempotency — cùng khoá + cùng payload ⇒ replay an toàn', () {
    test('plan hai lần chỉ sinh MỘT hành động', () async {
      final ex = executor();
      await ex.plan(action());
      await ex.plan(action(id: 'a2')); // cùng khoá, cùng payload

      final all = await db.select(db.businessActionsTable).get();
      expect(all, hasLength(1), reason: 'gọi lại không được sinh việc thứ hai');
      expect(all.single.id, 'a1');
    });

    test('cùng khoá + payload KHÁC ⇒ NÉM, không ghi đè im lặng', () async {
      // Đây là thứ `requestHash` tồn tại để chặn: hai việc khác nhau lỡ trùng
      // khoá sẽ lặng lẽ nuốt nhau nếu chỉ có khoá.
      final ex = executor();
      await ex.plan(action(params: const {'proposalId': 'p1'}));
      await expectLater(
        ex.plan(action(id: 'a2', params: const {'proposalId': 'p999'})),
        throwsA(isA<StateError>()),
      );
    });

    test('đã succeeded ⇒ chạy lại trả replayed, KHÔNG làm lại', () async {
      final ex = executor();
      await ex.plan(action());
      await ex.approve('a1', requestedBy: 'seller');
      await ex.run('a1');
      expect(effectRuns, 1);

      final again = await ex.run('a1');
      expect(again, isA<ActionSucceeded>());
      expect((again as ActionSucceeded).replayed, isTrue);
      expect(effectRuns, 1, reason: 'side effect KHÔNG được chạy lần hai');
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Duyệt trước, chạy sau', () {
    test('chưa duyệt ⇒ KHÔNG chạy, và side effect không xảy ra', () async {
      final ex = executor();
      await ex.plan(action());
      final result = await ex.run('a1');
      expect((result as ActionRefused).reason, ActionRejection.notApproved);
      expect(effectRuns, 0);
    });

    test('duyệt rồi thì chạy được, và ghi lại ai duyệt', () async {
      final ex = executor();
      await ex.plan(action());
      await ex.approve('a1', requestedBy: 'seller');
      final result = await ex.run('a1');

      expect(result, isA<ActionSucceeded>());
      final stored = (await db.select(db.businessActionsTable).get()).single;
      expect(stored.status, 'succeeded');
      expect(stored.requestedBy, 'seller');
      expect(stored.externalId, 'internal-a1');
    });

    test('duyệt hai lần chỉ ăn một lần', () async {
      final ex = executor();
      await ex.plan(action());
      expect(await ex.approve('a1', requestedBy: 'seller'), isNull);
      expect(
        await ex.approve('a1', requestedBy: 'seller'),
        isA<ActionRefused>(),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('⛔ Danh sách TUYỆT ĐỐI không auto (Founder duyệt 2026-08-08)', () {
    test('bảy loại được đánh dấu, và đủ bảy', () {
      final forbidden = BusinessActionType.values
          .where((t) => t.neverAutoByDefault)
          .map((t) => t.code)
          .toSet();
      expect(forbidden, {
        'finance.transfer_money',
        'customer.merge_records',
        'customer.send_cold_message',
        'product.update_price',
        'inventory.order_above_limit',
        'customer.contact_outside_book',
        'data.overwrite_seller_entered',
      });
    });

    test('AUTO KHÔNG duyệt được loại nằm trong danh sách', () async {
      final ex = executor(
        handlers: {
          BusinessActionType.financeTransferMoney: (_, _) async => 'x',
        },
      );
      await ex.plan(
        action(type: BusinessActionType.financeTransferMoney, key: 'pay:1'),
      );
      final result = await ex.approve(
        'a1',
        requestedBy: 'rule:auto-pay',
        mode: AutonomyMode.auto,
      );
      expect((result as ActionRefused).reason, ActionRejection.autoForbidden);
    });

    test('người bấm thì vẫn duyệt được — cấm AUTO, không cấm hẳn', () async {
      final ex = executor(
        handlers: {
          BusinessActionType.financeTransferMoney: (_, _) async => 'x',
        },
      );
      await ex.plan(
        action(type: BusinessActionType.financeTransferMoney, key: 'pay:1'),
      );
      expect(
        await ex.approve('a1', requestedBy: 'seller'),
        isNull,
        reason: 'duyệt tay vẫn được',
      );
    });

    test('AutonomyRule cấm dựng AUTO cho loại trong danh sách', () {
      expect(
        () => AutonomyRule(
          actionType: BusinessActionType.financeTransferMoney,
          mode: AutonomyMode.auto,
          limits: const AutonomyLimits(maxAmount: 1000),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('AUTO không có giới hạn ⇒ chặn tại constructor', () {
      expect(
        () => AutonomyRule(
          actionType: BusinessActionType.customerSendMessage,
          mode: AutonomyMode.auto,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('mọi loại rủi ro cao mặc định KHÔNG suy ra tự cho phép', () {
      // Rủi ro là thuộc tính của VIỆC, không phải lựa chọn cấu hình.
      for (final t in BusinessActionType.values) {
        if (t.neverAutoByDefault) {
          expect(t.risk, ActionRisk.high, reason: t.code);
        }
      }
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Lease — tiến trình chết không khoá vĩnh viễn', () {
    test('đang chạy thì người khác không nhận được', () async {
      final ex = executor();
      await ex.plan(action());
      await ex.approve('a1', requestedBy: 'seller');
      await db.customStatement(
        "UPDATE business_actions_table SET status = 'running', "
        "leased_until = ${clock.add(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000} "
        "WHERE id = 'a1'",
      );
      final result = await ex.run('a1');
      expect((result as ActionRefused).reason, ActionRejection.alreadyRunning);
      expect(effectRuns, 0);
    });

    test('lease hết hạn ⇒ nhận lại được', () async {
      final ex = executor(lease: const Duration(minutes: 5));
      await ex.plan(action());
      await ex.approve('a1', requestedBy: 'seller');
      await db.customStatement(
        "UPDATE business_actions_table SET status = 'running', "
        "leased_until = ${clock.subtract(const Duration(minutes: 1)).millisecondsSinceEpoch ~/ 1000} "
        "WHERE id = 'a1'",
      );
      final result = await ex.run('a1');
      expect(result, isA<ActionSucceeded>());
      expect(effectRuns, 1);
    });

    test('thất bại ⇒ failed, và thử lại được', () async {
      var attempts = 0;
      final ex = executor(
        handlers: {
          BusinessActionType.applyProposedChange: (_, _) async {
            attempts++;
            if (attempts == 1) throw StateError('mạng lỗi');
            return 'ok';
          },
        },
      );
      await ex.plan(action());
      await ex.approve('a1', requestedBy: 'seller');

      final first = await ex.run('a1');
      expect(first, isA<ActionFailed>());
      expect((first as ActionFailed).errorCode, 'effect_failed');

      final second = await ex.run('a1');
      expect(second, isA<ActionSucceeded>());
      expect(attempts, 2);

      final stored = (await db.select(db.businessActionsTable).get()).single;
      expect(stored.attemptCount, 2);
      expect(stored.errorCode, isNull, reason: 'lần chạy lại xoá lỗi cũ');
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('⭐ Side effect và trạng thái trong MỘT transaction', () {
    test('effect ném ⇒ KHÔNG có gì được ghi bởi effect đó', () async {
      // Effect ghi một dòng rồi ném. Transaction phải cuốn cả hai lại.
      final ex = executor(
        handlers: {
          BusinessActionType.applyProposedChange: (database, _) async {
            await database.customStatement(
              "INSERT INTO customers_table (id, business_id, name, updated_at, "
              "created_at) VALUES ('ghost', 'tongtai-local-business', 'Ma', 1, 1)",
            );
            throw StateError('lỗi sau khi ghi');
          },
        },
      );
      await ex.plan(action());
      await ex.approve('a1', requestedBy: 'seller');
      final result = await ex.run('a1');

      expect(result, isA<ActionFailed>());
      final customers = await db.select(db.customersTable).get();
      expect(
        customers.where((c) => c.id == 'ghost'),
        isEmpty,
        reason: 'không thể "làm rồi mà ghi failed"',
      );
    });

    test('effect thành công ⇒ cả hai cùng ghi', () async {
      final ex = executor(
        handlers: {
          BusinessActionType.applyProposedChange: (database, a) async {
            await database.customStatement(
              "INSERT INTO customers_table (id, business_id, name, updated_at, "
              "created_at) VALUES ('c-new', 'tongtai-local-business', 'Chị Hoa', 1, 1)",
            );
            return 'customer:c-new';
          },
        },
      );
      await ex.plan(action());
      await ex.approve('a1', requestedBy: 'seller');
      await ex.run('a1');

      final customers = await db.select(db.customersTable).get();
      expect(customers.where((c) => c.id == 'c-new'), hasLength(1));
      final stored = (await db.select(db.businessActionsTable).get()).single;
      expect(stored.status, 'succeeded');
      expect(stored.externalId, 'customer:c-new');
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Bản ghi hỏng và câu chuyện', () {
    test('mã status lạ ⇒ bỏ qua, KHÔNG rơi về approved', () async {
      final ex = executor();
      await ex.plan(action());
      await db.customStatement(
        "UPDATE business_actions_table SET status = 'probably_fine' "
        "WHERE id = 'a1'",
      );
      expect(await ex.byId('a1'), isNull);
      expect(ActionStatus.fromCode('probably_fine'), isNull);
    });

    test('correlationId gom được chuỗi hành động', () async {
      final ex = executor();
      await ex.plan(action(id: 'a1', key: 'k1', correlationId: 'chain-1'));
      await ex.plan(action(id: 'a2', key: 'k2', correlationId: 'chain-1'));
      await ex.plan(action(id: 'a3', key: 'k3'));

      final story = await ex.loadByCorrelation('chain-1');
      expect(story.map((a) => a.id), ['a1', 'a2']);
    });

    test('vendor internal là công dân hạng nhất', () async {
      // Đúng chỗ COMP AI hụt: ghi vào DB của chính mình cũng phải qua cửa.
      final ex = executor();
      await ex.plan(action());
      final stored = (await db.select(db.businessActionsTable).get()).single;
      expect(stored.vendor, 'internal');
      expect(ActionVendor.internal.code, 'internal');
    });
  });
}
