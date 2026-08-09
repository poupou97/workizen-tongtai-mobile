import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/connection/atlassian/atlassian_client.dart';
import 'package:tongtai/features/tongtai/connection/atlassian/atlassian_connection.dart';
import 'package:tongtai/features/tongtai/connection/atlassian/work_context.dart';
import 'package:tongtai/features/tongtai/connection/connection_credential_store.dart';
import 'package:tongtai/features/tongtai/connection/connection_repository.dart';
import 'package:tongtai/features/tongtai/connection/connection_service.dart';
import 'package:tongtai/features/tongtai/core/connection.dart';

/// WTM-319 · C3 — Jira + Confluence.
///
/// Ý định: *"Tổng Tài, cho tôi biết công việc Workizen đang thế nào."*
/// ⛔ **Không** phải Jira mobile client.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late InMemoryConnectionCredentialStore credentials;
  late ConnectionService connections;
  late DriftConnectionRepository repo;
  final now = DateTime(2026, 8, 9, 12);

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    credentials = InMemoryConnectionCredentialStore();
    repo = DriftConnectionRepository(db);
    connections = ConnectionService(
      repository: repo,
      credentials: credentials,
      now: () => now,
    );
  });

  tearDown(() => db.close());

  http.Response json(Object body) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    200,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );

  AtlassianConnection atlassianWith(MockClient client) => AtlassianConnection(
    connections: connections,
    client: AtlassianClient(client: client),
  );

  // ── client ───────────────────────────────────────────────────────────────

  group('AtlassianClient', () {
    test('Basic auth = base64(email:token), gửi trong header', () async {
      late http.BaseRequest captured;
      final client = AtlassianClient(
        client: MockClient((request) async {
          captured = request;
          return json({'accountId': 'a1', 'displayName': 'Alex'});
        }),
      );

      await client.validate(
        instanceUrl: 'https://x.atlassian.net',
        email: 'alex@example.com',
        token: 'TOKEN123',
      );

      final header = captured.headers['Authorization']!;
      expect(header, startsWith('Basic '));
      expect(
        utf8.decode(base64Decode(header.substring(6))),
        'alex@example.com:TOKEN123',
      );
      // Bí mật **không** nằm trong URL — khác Telegram, nên một log ghi URL ở
      // đây không rò gì.
      expect(captured.url.toString(), isNot(contains('TOKEN123')));
    });

    test('URL có dấu / thừa vẫn gọi đúng chỗ', () async {
      late Uri asked;
      final client = AtlassianClient(
        client: MockClient((request) async {
          asked = request.url;
          return json({'accountId': 'a1', 'displayName': 'Alex'});
        }),
      );

      await client.validate(
        instanceUrl: 'https://x.atlassian.net///',
        email: 'a@b.c',
        token: 't',
      );

      expect(asked.toString(), 'https://x.atlassian.net/rest/api/3/myself');
    });

    test('401 khác 404 — sai khoá khác sai địa chỉ', () async {
      Future<AtlassianFailure> failureFor(int status) async {
        final client = AtlassianClient(
          client: MockClient((_) async => http.Response('{}', status)),
        );
        try {
          await client.validate(
            instanceUrl: 'https://x.atlassian.net',
            email: 'a@b.c',
            token: 't',
          );
          fail('phải ném');
        } on AtlassianException catch (e) {
          return e.failure;
        }
      }

      expect(await failureFor(401), AtlassianFailure.unauthorized);
      expect(await failureFor(403), AtlassianFailure.forbidden);
      expect(await failureFor(404), AtlassianFailure.notFound);
      expect(await failureFor(503), AtlassianFailure.temporary);
    });

    test(
      'issue chưa giao / không có priority vẫn đọc được, KHÔNG nổ',
      () async {
        final client = AtlassianClient(
          client: MockClient(
            (_) async => json({
              'issues': [
                {
                  'key': 'WTM-1',
                  'fields': {
                    'summary': 'Việc chưa giao',
                    'status': {
                      'name': 'Ready',
                      'statusCategory': {'key': 'new'},
                    },
                    // Jira trả `null` cho cả hai — bình thường, không phải lỗi.
                    'priority': null,
                    'assignee': null,
                    'updated': '2026-08-08T10:00:00.000+0700',
                  },
                },
              ],
            }),
          ),
        );

        final issues = await client.openIssues(
          instanceUrl: 'https://x.atlassian.net',
          email: 'a@b.c',
          token: 't',
          projectKey: 'WTM',
        );

        expect(issues.single.priority, isNull);
        expect(issues.single.assignee, isNull);
        expect(issues.single.statusCategory, 'new');
      },
    );
  });

  // ── vòng đời ─────────────────────────────────────────────────────────────

  group('AtlassianConnection', () {
    test('khoá sai ⇒ KHÔNG lưu gì, không ACTIVE', () async {
      final atlassian = atlassianWith(
        MockClient((_) async => http.Response('{}', 401)),
      );

      final setup = await atlassian.attachCredentials(
        instanceUrl: 'https://x.atlassian.net',
        email: 'a@b.c',
        token: 'sai',
      );

      expect(setup.succeeded, isFalse);
      expect(setup.failure, AtlassianFailure.unauthorized);
      expect(credentials.debugAll, isEmpty);
      expect((await atlassian.ensure()).status, ConnectionStatus.setupRequired);
    });

    test('khoá đúng nhưng CHƯA chọn dự án ⇒ vẫn SETUP_REQUIRED', () async {
      final atlassian = atlassianWith(
        MockClient(
          (_) async => json({'accountId': 'a1', 'displayName': 'Alex'}),
        ),
      );

      final setup = await atlassian.attachCredentials(
        instanceUrl: 'https://x.atlassian.net',
        email: 'a@b.c',
        token: 'ok',
      );

      expect(setup.succeeded, isTrue);
      expect((await atlassian.ensure()).status, ConnectionStatus.setupRequired);
      expect(await atlassian.isReady, isFalse);
    });

    test('MỘT connection cho cả Jira lẫn Confluence', () async {
      final atlassian = atlassianWith(
        MockClient((request) async {
          if (request.url.path.contains('myself')) {
            return json({'accountId': 'a1', 'displayName': 'Alex'});
          }
          if (request.url.path.contains('/wiki/')) {
            return json({
              'results': [
                {'id': 42, 'key': 'workizento', 'name': 'Tổng Tài'},
              ],
            });
          }
          return json({
            'values': [
              {'key': 'WTM', 'name': 'Tổng Tài Mobile'},
            ],
          });
        }),
      );

      await atlassian.attachCredentials(
        instanceUrl: 'https://x.atlassian.net',
        email: 'a@b.c',
        token: 'ok',
      );
      await atlassian.selectProject('WTM');
      final spaces = await atlassian.spaces();
      await atlassian.selectSpace(spaces.single);

      // Một khoá, một bản ghi — không nhân đôi credential.
      expect(credentials.debugAll, hasLength(1));
      final stored = credentials.debugAll.values.single;
      expect(stored[CredentialField.projectKey], 'WTM');
      expect(stored[CredentialField.spaceKey], 'workizento');
      expect(await repo.loadAll(), hasLength(1));
    });

    test('chọn dự án khi CHƯA có khoá ⇒ từ chối', () async {
      final atlassian = atlassianWith(MockClient((_) async => json({})));

      expect(await atlassian.selectProject('WTM'), isNull);
      expect(credentials.debugAll, isEmpty);
    });

    test('chưa chọn dự án ⇒ workContext là null, KHÔNG gọi Jira', () async {
      final atlassian = atlassianWith(
        MockClient((request) async {
          if (request.url.path.contains('myself')) {
            return json({'accountId': 'a1', 'displayName': 'Alex'});
          }
          return fail('không được hỏi Jira khi chưa chọn dự án');
        }),
      );
      await atlassian.attachCredentials(
        instanceUrl: 'https://x.atlassian.net',
        email: 'a@b.c',
        token: 'ok',
      );

      expect(await atlassian.workContext(now: now), isNull);
    });

    test('chọn dự án xong ⇒ ACTIVE và trả về tóm tắt', () async {
      final atlassian = atlassianWith(
        MockClient((request) async {
          if (request.url.path.contains('myself')) {
            return json({'accountId': 'a1', 'displayName': 'Alex'});
          }
          return json({
            'issues': [
              {
                'key': 'WTM-1',
                'fields': {
                  'summary': 'Đang làm',
                  'status': {
                    'name': 'In Progress',
                    'statusCategory': {'key': 'indeterminate'},
                  },
                  'priority': {'name': 'High'},
                  'updated': '2026-08-08T10:00:00.000+0700',
                },
              },
            ],
          });
        }),
      );
      await atlassian.attachCredentials(
        instanceUrl: 'https://x.atlassian.net',
        email: 'a@b.c',
        token: 'ok',
      );
      await atlassian.selectProject('WTM');

      final context = await atlassian.workContext(now: now);

      expect((await atlassian.ensure()).status, ConnectionStatus.active);
      expect(context!.open, 1);
      expect(context.headline, contains('WTM'));
    });
  });

  // ── projection ───────────────────────────────────────────────────────────

  group('WorkContext', () {
    AtlassianIssue issue({
      required String category,
      String? priority,
      DateTime? updated,
    }) => AtlassianIssue(
      key: 'WTM-1',
      summary: 'x',
      status: 'y',
      statusCategory: category,
      priority: priority,
      updatedAt: updated,
    );

    test('đếm theo statusCategory, không theo tên cột', () {
      // Ba issue cùng `indeterminate` nhưng ba tên cột khác nhau — chúng phải
      // đếm như nhau, vì tên cột là thứ ai cũng đổi được từ giao diện Jira.
      final context = WorkContext.derive(
        projectKey: 'WTM',
        now: now,
        issues: [
          AtlassianIssue(
            key: 'a',
            summary: '',
            status: 'ANALYSIS',
            statusCategory: 'indeterminate',
          ),
          AtlassianIssue(
            key: 'b',
            summary: '',
            status: 'Code Review',
            statusCategory: 'indeterminate',
          ),
          AtlassianIssue(
            key: 'c',
            summary: '',
            status: 'QA',
            statusCategory: 'indeterminate',
          ),
        ],
      );

      expect(context.inProgress, 3);
      expect(context.open, 3);
    });

    test('xong mà KHÔNG biết lúc nào ⇒ không đếm vào "xong tuần này"', () {
      final context = WorkContext.derive(
        projectKey: 'WTM',
        now: now,
        issues: [issue(category: 'done')],
      );

      // Đoán ở đây là bịa một con số cho Founder đọc.
      expect(context.doneThisWeek, 0);
    });

    test('xong tuần trước không tính là xong tuần này', () {
      final context = WorkContext.derive(
        projectKey: 'WTM',
        now: now,
        issues: [
          issue(
            category: 'done',
            updated: now.subtract(const Duration(days: 2)),
          ),
          issue(
            category: 'done',
            updated: now.subtract(const Duration(days: 20)),
          ),
        ],
      );

      expect(context.doneThisWeek, 1);
    });

    test('bỏ quên trên hai tuần được đếm riêng', () {
      final context = WorkContext.derive(
        projectKey: 'WTM',
        now: now,
        issues: [
          issue(
            category: 'new',
            updated: now.subtract(const Duration(days: 30)),
          ),
          issue(
            category: 'new',
            updated: now.subtract(const Duration(days: 1)),
          ),
        ],
      );

      expect(context.stale, 1);
      expect(context.open, 2);
    });

    test('không có issue nào ⇒ CHƯA KẾT LUẬN, không phải "mọi thứ ổn"', () {
      final context = WorkContext.derive(
        projectKey: 'WTM',
        now: now,
        issues: const [],
      );

      expect(context.hasData, isFalse);
      expect(context.headline, isNull);
    });

    test('câu tóm tắt không có mã issue, không có tên cột', () {
      final context = WorkContext.derive(
        projectKey: 'WTM',
        now: now,
        issues: [
          AtlassianIssue(
            key: 'WTM-999',
            summary: 'Bí mật nội bộ',
            status: 'Code Review',
            statusCategory: 'indeterminate',
            priority: 'High',
          ),
        ],
      );

      expect(context.headline, isNot(contains('WTM-999')));
      expect(context.headline, isNot(contains('Code Review')));
      expect(context.headline, isNot(contains('Bí mật nội bộ')));
      expect(context.headline, contains('1 ưu tiên cao'));
    });
  });

  // ── biên credential ──────────────────────────────────────────────────────

  test('API token KHÔNG vào cơ sở dữ liệu nghiệp vụ', () async {
    const secret = 'ATATT-SECRET-DO-NOT-PERSIST-9f2b';
    final atlassian = atlassianWith(
      MockClient((_) async => json({'accountId': 'a1', 'displayName': 'Alex'})),
    );

    await atlassian.attachCredentials(
      instanceUrl: 'https://x.atlassian.net',
      email: 'alex@example.com',
      token: secret,
    );

    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    final dump = StringBuffer();
    for (final t in tables) {
      final name = t.data['name'] as String;
      try {
        for (final row
            in await db.customSelect('SELECT * FROM "$name"').get()) {
          dump.writeln(jsonEncode(row.data.map((k, v) => MapEntry(k, '$v'))));
        }
      } on Object {
        continue;
      }
    }

    expect(dump.toString(), isNot(contains(secret)));
    // Nhưng bí mật CÓ ở đúng một chỗ — nếu không thì test trên đúng vì lý do sai.
    expect(jsonEncode(credentials.debugAll), contains(secret));
  });
}
