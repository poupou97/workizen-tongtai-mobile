import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/action/business_action.dart';
import 'package:tongtai/features/tongtai/action/business_action_executor.dart';
import 'package:tongtai/features/tongtai/action/demo_action_handlers.dart';
import 'package:tongtai/features/tongtai/agent/business_brief.dart';
import 'package:tongtai/features/tongtai/connection/connection_credential_store.dart';
import 'package:tongtai/features/tongtai/connection/connection_repository.dart';
import 'package:tongtai/features/tongtai/connection/connection_service.dart';
import 'package:tongtai/features/tongtai/connection/telegram/owner_notifier.dart';
import 'package:tongtai/features/tongtai/connection/telegram/telegram_client.dart';
import 'package:tongtai/features/tongtai/connection/telegram/telegram_connection.dart';
import 'package:tongtai/features/tongtai/consumer/identity_evidence.dart';
import 'package:tongtai/features/tongtai/core/connection.dart';
import 'package:tongtai/features/tongtai/core/provenance.dart';

/// WTM-318 · C2 — Telegram: connector thật **chạy được ngay**, không chờ ai.
///
/// Khác Drive ở đúng một chỗ và đó là chỗ quyết định: không OAuth, không client
/// ID, không xét duyệt. Nên đây là hành động đầu tiên đi trọn vòng ra một nền
/// tảng thật **mà không cần Founder tạo gì trên console**.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late InMemoryConnectionCredentialStore credentials;
  late ConnectionService connections;
  var clock = DateTime(2026, 8, 9, 7, 15);

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    credentials = InMemoryConnectionCredentialStore();
    connections = ConnectionService(
      repository: DriftConnectionRepository(db),
      credentials: credentials,
      now: () => clock,
    );
  });

  tearDown(() => db.close());

  TelegramConnection telegramWith(MockClient client) => TelegramConnection(
    connections: connections,
    client: TelegramClient(client: client),
  );

  /// `http.Response(String, …)` mặc định latin-1, nên tên tiếng Việt trong
  /// phản hồi giả sẽ nổ ngay trong test dù production chạy tốt (Telegram gửi
  /// `charset=utf-8` thật). Dựng bằng bytes để phản hồi giả giống thật.
  http.Response json(Map<String, Object?> body) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    200,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );

  /// Telegram trả **200 kèm `ok:false`** cho hầu hết lỗi.
  http.Response err(int code, String description) =>
      json({'ok': false, 'error_code': code, 'description': description});

  http.Response ok(Object result) => json({'ok': true, 'result': result});

  // ── client ───────────────────────────────────────────────────────────────

  group('TelegramClient', () {
    test('lỗi 200 + ok:false vẫn là LỖI', () async {
      // Chỉ nhìn mã HTTP là bỏ sót toàn bộ họ lỗi này — và bỏ sót nghĩa là
      // báo "đã gửi" cho một tin không bao giờ tới.
      final client = TelegramClient(
        client: MockClient((_) async => err(401, 'Unauthorized')),
      );

      expect(
        () => client.getMe('sai'),
        throwsA(
          isA<TelegramException>().having(
            (e) => e.failure,
            'failure',
            TelegramFailure.unauthorized,
          ),
        ),
      );
    });

    test('403 = bị chặn / chưa /start, KHÁC token hỏng', () async {
      final client = TelegramClient(
        client: MockClient(
          (_) async => err(403, 'Forbidden: bot was blocked by the user'),
        ),
      );

      try {
        await client.sendMessage(token: 't', chatId: '1', text: 'x');
        fail('phải ném');
      } on TelegramException catch (e) {
        expect(e.failure, TelegramFailure.blocked);
        expect(e.failure, isNot(TelegramFailure.unauthorized));
      }
    });

    test('token nằm trong URL, KHÔNG nằm trong body', () async {
      // Telegram đặt token trong đường dẫn. Nhớ điều này vì nó quyết định chỗ
      // token có thể rò: một log ghi lại URL là một log ghi lại bí mật.
      late Uri asked;
      final client = TelegramClient(
        client: MockClient((request) async {
          asked = request.url;
          return ok({
            'id': 1,
            'username': 'tongtai_bot',
            'first_name': 'Tổng Tài',
          });
        }),
      );

      await client.getMe('123:ABC');

      expect(asked.path, contains('123:ABC'));
    });

    test(
      'gộp nhiều tin của cùng một người thành MỘT cuộc trò chuyện',
      () async {
        final client = TelegramClient(
          client: MockClient(
            (_) async => ok([
              {
                'message': {
                  'chat': {
                    'id': 555,
                    'first_name': 'Alex',
                    'username': 'alexng',
                  },
                },
              },
              {
                'message': {
                  'chat': {'id': 555, 'first_name': 'Alex'},
                },
              },
              {
                'message': {
                  'chat': {'id': 777, 'title': 'Nhóm shop'},
                },
              },
            ]),
          ),
        );

        final chats = await client.discoverChats('t');

        expect(chats.map((c) => c.id).toList(), ['555', '777']);
        expect(chats.first.label, 'Alex');
        expect(chats.last.label, 'Nhóm shop');
      },
    );

    test('update không có chat ⇒ bỏ qua, không nổ', () async {
      final client = TelegramClient(
        client: MockClient(
          (_) async => ok([
            {'edited_message': {}},
            {'message': {}},
            {
              'message': {
                'chat': {'id': 9},
              },
            },
          ]),
        ),
      );

      final chats = await client.discoverChats('t');

      expect(chats.map((c) => c.id).toList(), ['9']);
      // Không có tên ⇒ nhãn rơi về mã, **không** rơi về chuỗi rỗng.
      expect(chats.single.label, '9');
    });
  });

  // ── vòng đời kết nối ─────────────────────────────────────────────────────

  group('TelegramConnection', () {
    test('token sai ⇒ KHÔNG lưu gì cả, không ACTIVE', () async {
      final telegram = telegramWith(
        MockClient((_) async => err(401, 'Unauthorized')),
      );

      final setup = await telegram.attachToken('bậy');

      expect(setup.succeeded, isFalse);
      expect(setup.failure, TelegramFailure.unauthorized);
      expect(credentials.debugAll, isEmpty);
      expect((await telegram.ensure()).status, ConnectionStatus.setupRequired);
    });

    test('token đúng nhưng CHƯA có nơi nhận ⇒ vẫn SETUP_REQUIRED', () async {
      final telegram = telegramWith(
        MockClient(
          (_) async =>
              ok({'id': 1, 'username': 'tongtai_bot', 'first_name': 'TT'}),
        ),
      );

      final setup = await telegram.attachToken('123:ABC');

      expect(setup.succeeded, isTrue);
      // Biết token thật mà chưa biết gửi cho ai thì chưa gửi được gì — nói
      // "đã kết nối" lúc này là nói một nửa sự thật.
      expect((await telegram.ensure()).status, ConnectionStatus.setupRequired);
      expect(await telegram.isReady, isFalse);
    });

    test('tên kết nối đổi thành tên bot — thứ người bán nhận ra', () async {
      final telegram = telegramWith(
        MockClient(
          (_) async =>
              ok({'id': 1, 'username': 'tongtai_bot', 'first_name': 'TT'}),
        ),
      );

      await telegram.attachToken('123:ABC');

      expect((await telegram.ensure()).label, '@tongtai_bot');
    });

    test('chọn nơi nhận xong mới ACTIVE', () async {
      final telegram = telegramWith(
        MockClient((request) async {
          if (request.url.path.endsWith('getMe')) {
            return ok({'id': 1, 'username': 'tongtai_bot', 'first_name': 'TT'});
          }
          return ok([
            {
              'message': {
                'chat': {'id': 555, 'first_name': 'Alex'},
              },
            },
          ]);
        }),
      );

      await telegram.attachToken('123:ABC');
      final chats = await telegram.discoverChats();
      final connection = await telegram.attachChat(chats.single.id);

      expect(connection!.status, ConnectionStatus.active);
      expect(await telegram.isReady, isTrue);
    });

    test('chọn nơi nhận khi CHƯA có token ⇒ từ chối', () async {
      final telegram = telegramWith(MockClient((_) async => ok({})));

      expect(await telegram.attachChat('555'), isNull);
      expect(credentials.debugAll, isEmpty);
    });

    test('lưu token lần hai KHÔNG xoá mất nơi nhận đã chọn', () async {
      final telegram = telegramWith(
        MockClient((request) async {
          if (request.url.path.endsWith('getMe')) {
            return ok({'id': 1, 'username': 'tongtai_bot', 'first_name': 'TT'});
          }
          return ok([
            {
              'message': {
                'chat': {'id': 555, 'first_name': 'Alex'},
              },
            },
          ]);
        }),
      );

      await telegram.attachToken('123:ABC');
      await telegram.attachChat('555');
      // Đổi bot (token mới) — cùng người nhận.
      await telegram.attachToken('999:XYZ');

      expect(await telegram.isReady, isTrue);
      expect((await telegram.ensure()).status, ConnectionStatus.active);
    });
  });

  // ── qua cửa ghi duy nhất ─────────────────────────────────────────────────

  group('OwnerNotifier', () {
    late TelegramConnection telegram;
    var sent = <String>[];

    Future<void> connect() async {
      telegram = telegramWith(
        MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('getMe')) {
            return ok({'id': 1, 'username': 'tongtai_bot', 'first_name': 'TT'});
          }
          if (path.endsWith('sendMessage')) {
            final body = jsonDecode(request.body) as Map;
            sent.add(body['text'] as String);
            return ok({'message_id': 100 + sent.length});
          }
          return ok([
            {
              'message': {
                'chat': {'id': 555, 'first_name': 'Alex'},
              },
            },
          ]);
        }),
      );
      await telegram.attachToken('123:ABC');
      await telegram.attachChat('555');
    }

    OwnerNotifier notifier() => OwnerNotifier(
      executor: BusinessActionExecutor(
        db,
        now: () => clock,
        handlers: {
          ...demoActionHandlers,
          BusinessActionType.ownerNotify: OwnerNotifier.effect(telegram),
        },
      ),
      telegram: telegram,
      now: () => clock,
    );

    setUp(() => sent = <String>[]);

    BriefItem item(String headline, {BriefSeverity? severity, String? id}) =>
        BriefItem(
          kind: BriefKind.customerAtRisk,
          severity: severity ?? BriefSeverity.warning,
          subjectKind: 'customer',
          subjectId: id ?? '${kSampleIdPrefix}c1',
          subjectLabel: 'Duy Trần',
          headline: headline,
          suggestion: 'Nhắn hỏi thăm',
          evidence: const [
            IdentityEvidence(
              kind: IdentityEvidenceKind.businessRecordObservation,
              source: 'rule:customer-risk',
              detail: '77 ngày chưa quay lại',
            ),
          ],
          observedAt: DateTime(2026, 8, 9),
        );

    test(
      'tin thử chạy THẬT — externalId là telegram:, không phải demo:',
      () async {
        await connect();

        final result = await notifier().sendTest();

        expect(result, isA<ActionSucceeded>());
        final external = (result as ActionSucceeded).externalId;
        expect(external, 'telegram:101');
        expect(isDemoResult(external), isFalse);
        expect(OwnerNotifier.isRealTelegramResult(external), isTrue);
        expect(sent, hasLength(1));
      },
    );

    test('bản tin sáng gửi MỘT lần một ngày', () async {
      await connect();
      final n = notifier();

      await n.sendMorningBrief([item('Duy Trần đã 77 ngày chưa quay lại')]);
      clock = clock.add(const Duration(hours: 3));
      final second = await n.sendMorningBrief([
        item('Duy Trần đã 77 ngày chưa quay lại'),
      ]);

      expect(sent, hasLength(1));
      expect((second as ActionSucceeded).replayed, isTrue);
    });

    test('không có việc nào ⇒ KHÔNG nhắn gì cả', () async {
      await connect();

      expect(await notifier().sendMorningBrief(const []), isNull);
      expect(sent, isEmpty);
    });

    test('chưa nối Telegram ⇒ không dựng hành động nào', () async {
      telegram = telegramWith(MockClient((_) async => fail('không được gọi')));
      final n = notifier();

      expect(await n.sendMorningBrief([item('x')]), isNull);

      final actions = await BusinessActionExecutor(
        db,
        now: () => clock,
        handlers: const {},
      ).loadRecent();
      expect(actions, isEmpty);
    });

    test('bị chặn ⇒ hành động FAILED, thử lại được, không im lặng', () async {
      telegram = telegramWith(
        MockClient((request) async {
          if (request.url.path.endsWith('getMe')) {
            return ok({'id': 1, 'username': 'tongtai_bot', 'first_name': 'TT'});
          }
          if (request.url.path.endsWith('sendMessage')) {
            return err(403, 'Forbidden: bot was blocked by the user');
          }
          return ok(const []);
        }),
      );
      await telegram.attachToken('123:ABC');
      await telegram.attachChat('555');

      final result = await notifier().sendTest();

      expect(result, isA<ActionFailed>());
      expect((result as ActionFailed).errorCode, 'effect_failed');
    });
  });

  // ── nội dung bản tin ─────────────────────────────────────────────────────

  group('composeMorningBrief', () {
    BriefItem item(String headline, BriefSeverity severity, String id) =>
        BriefItem(
          kind: BriefKind.customerAtRisk,
          severity: severity,
          subjectKind: 'customer',
          subjectId: id,
          headline: headline,
          suggestion: 'Làm gì đó',
          evidence: const [
            IdentityEvidence(
              kind: IdentityEvidenceKind.businessRecordObservation,
              source: 'rule:customer-risk',
              detail: 'x',
            ),
          ],
          observedAt: DateTime(2026, 8, 9),
        );

    test('việc nặng lên trước', () {
      final text = composeMorningBrief([
        item('Nhẹ', BriefSeverity.info, 'a'),
        item('Nặng', BriefSeverity.critical, 'b'),
      ], at: DateTime(2026, 8, 9));

      expect(text.indexOf('Nặng'), lessThan(text.indexOf('Nhẹ')));
    });

    test('cắt ở năm việc và NÓI RA còn bao nhiêu', () {
      final text = composeMorningBrief([
        for (var i = 0; i < 8; i++)
          item('Việc $i', BriefSeverity.warning, 'c$i'),
      ], at: DateTime(2026, 8, 9));

      expect('•'.allMatches(text), hasLength(5));
      expect(text, contains('Còn 3 việc nữa'));
    });

    test('đúng năm việc thì KHÔNG nói "còn 0 việc nữa"', () {
      final text = composeMorningBrief([
        for (var i = 0; i < 5; i++)
          item('Việc $i', BriefSeverity.warning, 'c$i'),
      ], at: DateTime(2026, 8, 9));

      expect(text, isNot(contains('Còn')));
    });

    test('không có mã, không có tên bảng, không có id kỹ thuật', () {
      final text = composeMorningBrief([
        item(
          'Duy Trần đã 77 ngày chưa quay lại',
          BriefSeverity.warning,
          '${kSampleIdPrefix}customer-1',
        ),
      ], at: DateTime(2026, 8, 9));

      expect(text, isNot(contains(kSampleIdPrefix)));
      expect(text, isNot(contains('customer-1')));
      expect(text, contains('Duy Trần'));
    });
  });
}
