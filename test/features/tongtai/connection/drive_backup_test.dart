import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/action/business_action.dart';
import 'package:tongtai/features/tongtai/action/business_action_executor.dart';
import 'package:tongtai/features/tongtai/action/demo_action_handlers.dart';
import 'package:tongtai/features/tongtai/connection/connection_capability.dart';
import 'package:tongtai/features/tongtai/connection/connection_credential_store.dart';
import 'package:tongtai/features/tongtai/connection/connection_repository.dart';
import 'package:tongtai/features/tongtai/connection/connection_service.dart';
import 'package:tongtai/features/tongtai/connection/google/drive_backup_coordinator.dart';
import 'package:tongtai/features/tongtai/connection/google/drive_backup_service.dart';
import 'package:tongtai/features/tongtai/connection/google/google_connection.dart';
import 'package:tongtai/features/tongtai/connection/google/google_oauth.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/connection.dart';
import 'package:tongtai/features/tongtai/export/backup_service.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/journey_repository.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_reaction_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/producer/business_input_repository.dart';
import 'package:tongtai/features/tongtai/profile/business_profile_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorites_store.dart';

/// WTM-317 · C1 — sao lưu lên Google Drive.
///
/// Đây là hành động **đầu tiên** trong lịch sử repo này đi hết `plan → approve
/// → run` ra một nền tảng thật. Mọi thứ trước nó dừng ở `demo:`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late InMemoryConnectionCredentialStore credentials;
  late ConnectionService connections;
  var clock = DateTime(2026, 8, 9, 14, 30, 12);

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

  // ── DriveBackupService: nói chuyện với Drive ─────────────────────────────

  group('DriveBackupService', () {
    test('upload gửi cả metadata lẫn nội dung, trả về fileId', () async {
      late http.Request captured;
      final drive = DriveBackupService(
        client: MockClient((request) async {
          captured = request;
          return http.Response('{"id":"1AbC","name":"x.ttbk"}', 200);
        }),
      );

      final id = await drive.upload(
        accessToken: 'tok-123',
        bytes: Uint8List.fromList(utf8.encode('TTBK-PAYLOAD')),
        fileName: 'tongtai-backup-20260809-1430.ttbk',
      );

      expect(id, '1AbC');
      expect(captured.headers['Authorization'], 'Bearer tok-123');
      final body = utf8.decode(captured.bodyBytes);
      expect(body, contains('tongtai-backup-20260809-1430.ttbk'));
      expect(body, contains('TTBK-PAYLOAD'));
      expect(captured.url.queryParameters['uploadType'], 'multipart');
    });

    test('Drive nhận nhưng không trả mã ⇒ ném, không báo thành công', () async {
      final drive = DriveBackupService(
        client: MockClient((_) async => http.Response('{"kind":"file"}', 200)),
      );

      expect(
        () => drive.upload(accessToken: 't', bytes: Uint8List(0)),
        throwsA(
          isA<DriveException>().having(
            (e) => e.failure,
            'failure',
            DriveFailure.unexpected,
          ),
        ),
      );
    });

    test('mã HTTP dịch thành lý do phân biệt được', () async {
      Future<DriveFailure> failureFor(int status) async {
        final drive = DriveBackupService(
          client: MockClient((_) async => http.Response('{}', status)),
        );
        try {
          await drive.upload(accessToken: 't', bytes: Uint8List(0));
          fail('phải ném');
        } on DriveException catch (e) {
          return e.failure;
        }
      }

      expect(await failureFor(401), DriveFailure.unauthorized);
      expect(await failureFor(403), DriveFailure.forbidden);
      expect(await failureFor(429), DriveFailure.temporary);
      expect(await failureFor(503), DriveFailure.temporary);
    });

    test('list chỉ hỏi file của app, đọc được size null', () async {
      late Uri asked;
      final drive = DriveBackupService(
        client: MockClient((request) async {
          asked = request.url;
          return http.Response(
            jsonEncode({
              'files': [
                {
                  'id': 'f1',
                  'name': 'tongtai-backup-20260809-1430.ttbk',
                  'size': '2048',
                  'createdTime': '2026-08-09T07:30:12.000Z',
                },
                // Drive có thể không trả `size` — `null` ≠ `0`.
                {'id': 'f2', 'name': 'tongtai-backup-20260808-0900.ttbk'},
              ],
            }),
            200,
          );
        }),
      );

      final files = await drive.list(accessToken: 'tok');

      expect(asked.queryParameters['q'], contains('tongtai-backup-'));
      expect(files, hasLength(2));
      expect(files.first.sizeBytes, 2048);
      expect(files.last.sizeBytes, isNull);
    });

    test('tên file tất định, và CHÍNH XÁC TỚI PHÚT như khoá chống lặp', () {
      // Hai thời điểm cách nhau vài giây phải cho cùng một tên: tên file và
      // khoá chống lặp là **một** mốc, không phải hai độ phân giải.
      expect(
        DriveBackupService.fileNameFor(DateTime(2026, 8, 9, 14, 30, 12)),
        'tongtai-backup-20260809-1430.ttbk',
      );
      expect(
        DriveBackupService.fileNameFor(DateTime(2026, 8, 9, 14, 30, 51)),
        DriveBackupService.fileNameFor(DateTime(2026, 8, 9, 14, 30, 12)),
      );
    });
  });

  // ── GoogleConnection: vòng đời token ─────────────────────────────────────

  group('GoogleConnection', () {
    test('chưa có client ID ⇒ ném notConfigured, không im lặng', () async {
      final google = GoogleConnection(
        connections: connections,
        authenticator: const UnconfiguredGoogleAuthenticator(),
        now: () => clock,
      );

      expect(
        () => google.connect({ConnectionCapability.driveBackup}),
        throwsA(
          isA<GoogleAuthException>().having(
            (e) => e.failure,
            'failure',
            GoogleAuthFailure.notConfigured,
          ),
        ),
      );
      // Và kết nối **không** thành ACTIVE.
      expect((await google.ensure()).status, ConnectionStatus.setupRequired);
    });

    test(
      'refresh trả về null refresh_token KHÔNG xoá mất cái đang có',
      () async {
        final auth = _FakeAuthenticator(
          onAuthorize: (_) => GoogleTokens(
            accessToken: 'access-1',
            refreshToken: 'refresh-1',
            expiresAt: clock.add(const Duration(hours: 1)),
          ),
          // Google chỉ cấp refresh token ở lần cho phép đầu.
          onRefresh: (_) => GoogleTokens(
            accessToken: 'access-2',
            expiresAt: clock.add(const Duration(hours: 2)),
          ),
        );
        final google = GoogleConnection(
          connections: connections,
          authenticator: auth,
          now: () => clock,
        );

        await google.connect({ConnectionCapability.driveBackup});
        clock = clock.add(const Duration(hours: 2)); // access-1 hết hạn
        final token = await google.accessToken();

        expect(token, 'access-2');
        final connection = await google.ensure();
        final stored = await credentials.read(connection);
        expect(stored![CredentialField.refreshToken], 'refresh-1');
      },
    );

    test('token còn hạn ⇒ không gọi refresh', () async {
      var refreshes = 0;
      final google = GoogleConnection(
        connections: connections,
        authenticator: _FakeAuthenticator(
          onAuthorize: (_) => GoogleTokens(
            accessToken: 'access-1',
            refreshToken: 'refresh-1',
            expiresAt: clock.add(const Duration(hours: 1)),
          ),
          onRefresh: (_) {
            refreshes++;
            return GoogleTokens(accessToken: 'x', expiresAt: clock);
          },
        ),
        now: () => clock,
      );

      await google.connect({ConnectionCapability.driveBackup});
      expect(await google.accessToken(), 'access-1');
      expect(refreshes, 0);
    });

    test('hết hạn mà không có refresh token ⇒ ERROR, trả null', () async {
      final connection = await connections.ensure(
        kGoogleConnectorId,
        label: 'Google',
      );
      await connections.attachCredentials(connection, {
        CredentialField.token: 'access-cũ',
        CredentialField.expiresAt: clock
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
      });
      final google = GoogleConnection(
        connections: connections,
        authenticator: const UnconfiguredGoogleAuthenticator(),
        now: () => clock,
      );

      expect(await google.accessToken(), isNull);
      final after = await google.ensure();
      expect(after.status, ConnectionStatus.error);
    });

    test('ngắt kết nối xoá khoá kể cả khi revoke hỏng', () async {
      final google = GoogleConnection(
        connections: connections,
        authenticator: _FakeAuthenticator(
          onAuthorize: (_) => GoogleTokens(
            accessToken: 'a',
            refreshToken: 'r',
            expiresAt: clock.add(const Duration(hours: 1)),
          ),
          onRevoke: () =>
              throw const GoogleAuthException(GoogleAuthFailure.network),
        ),
        now: () => clock,
      );
      await google.connect({ConnectionCapability.driveBackup});

      await google.disconnect();

      expect(credentials.debugAll, isEmpty);
    });

    test('chưa kết nối ⇒ accessToken trả null, không ném', () async {
      final google = GoogleConnection(
        connections: connections,
        authenticator: const UnconfiguredGoogleAuthenticator(),
        now: () => clock,
      );

      expect(await google.accessToken(), isNull);
    });
  });

  // ── Coordinator: qua cửa ghi duy nhất ────────────────────────────────────

  group('DriveBackupCoordinator', () {
    late GoogleConnection google;

    TongtaiBackupService backupService() => TongtaiBackupService(
      repositories: TongtaiBackupRepositories(
        database: db,
        customers: DriftCustomerRepository(db),
        products: DriftProductRepository(db),
        orders: DriftOrderRepository(db),
        goals: DriftBusinessGoalRepository(db),
        finance: DriftFinanceRepository(db),
        favourites: DriftSupplierFavoritesStore(db),
        businessProfile: BusinessProfileRepository(db),
        journeys: JourneyRepository(db),
        opportunityReactions: OpportunityReactionRepository(db),
        businessInputs: DriftBusinessInputRepository(db),
      ),
      clock: () => clock,
      randomId: () => 'test-backup-id',
    );

    Future<void> connectGoogle() async {
      google = GoogleConnection(
        connections: connections,
        authenticator: _FakeAuthenticator(
          onAuthorize: (_) => GoogleTokens(
            accessToken: 'access-1',
            refreshToken: 'refresh-1',
            expiresAt: clock.add(const Duration(hours: 1)),
          ),
          onRefresh: (_) => GoogleTokens(
            accessToken: 'access-2',
            expiresAt: clock.add(const Duration(hours: 1)),
          ),
        ),
        now: () => clock,
      );
      await google.connect({ConnectionCapability.driveBackup});
    }

    DriveBackupCoordinator coordinatorWith(DriveBackupService drive) =>
        DriveBackupCoordinator(
          executor: BusinessActionExecutor(
            db,
            now: () => clock,
            handlers: {
              ...demoActionHandlers,
              BusinessActionType.storageBackupUpload:
                  DriveBackupCoordinator.effect(
                    connection: google,
                    drive: drive,
                    backup: backupService(),
                  ),
            },
          ),
          connection: google,
          drive: drive,
          now: () => clock,
        );

    test(
      'sao lưu chạy THẬT — externalId là drive:, không phải demo:',
      () async {
        await connectGoogle();
        var uploads = 0;
        final coordinator = coordinatorWith(
          DriveBackupService(
            client: MockClient((_) async {
              uploads++;
              return http.Response('{"id":"drive-file-1"}', 200);
            }),
          ),
        );

        final result = await coordinator.backupNow();

        expect(result, isA<ActionSucceeded>());
        final external = (result as ActionSucceeded).externalId;
        expect(external, 'drive:drive-file-1');
        expect(isDemoResult(external), isFalse);
        expect(DriveBackupCoordinator.isRealDriveResult(external), isTrue);
        expect(uploads, 1);
      },
    );

    test('bấm hai lần trong một phút ⇒ MỘT file', () async {
      await connectGoogle();
      var uploads = 0;
      final coordinator = coordinatorWith(
        DriveBackupService(
          client: MockClient((_) async {
            uploads++;
            return http.Response('{"id":"drive-file-1"}', 200);
          }),
        ),
      );

      await coordinator.backupNow();
      clock = clock.add(const Duration(seconds: 20));
      final second = await coordinator.backupNow();

      expect(uploads, 1);
      expect((second as ActionSucceeded).replayed, isTrue);
    });

    test('sang phút sau là một ý định khác ⇒ file thứ hai', () async {
      await connectGoogle();
      var uploads = 0;
      final coordinator = coordinatorWith(
        DriveBackupService(
          client: MockClient((_) async {
            uploads++;
            return http.Response('{"id":"drive-file-$uploads"}', 200);
          }),
        ),
      );

      await coordinator.backupNow();
      clock = clock.add(const Duration(minutes: 1));
      await coordinator.backupNow();

      expect(uploads, 2);
    });

    test('401 giữa chừng ⇒ làm mới quyền và thử lại MỘT lần', () async {
      await connectGoogle();
      final seen = <String>[];
      final coordinator = coordinatorWith(
        DriveBackupService(
          client: MockClient((request) async {
            final token = request.headers['Authorization'] ?? '';
            seen.add(token);
            if (token == 'Bearer access-1') {
              return http.Response('{"error":"invalid"}', 401);
            }
            return http.Response('{"id":"drive-file-retry"}', 200);
          }),
        ),
      );

      final result = await coordinator.backupNow();

      expect((result as ActionSucceeded).externalId, 'drive:drive-file-retry');
      expect(seen, ['Bearer access-1', 'Bearer access-2']);
    });

    test('chưa kết nối ⇒ hành động FAILED, thử lại được', () async {
      google = GoogleConnection(
        connections: connections,
        authenticator: const UnconfiguredGoogleAuthenticator(),
        now: () => clock,
      );
      final coordinator = coordinatorWith(
        DriveBackupService(
          client: MockClient(
            (_) async => fail('không được gọi Drive khi chưa kết nối'),
          ),
        ),
      );

      final result = await coordinator.backupNow();

      expect(result, isA<ActionFailed>());
      expect((result as ActionFailed).errorCode, 'effect_failed');
    });

    test('mất mạng ⇒ FAILED chứ không im lặng báo xong', () async {
      await connectGoogle();
      final coordinator = coordinatorWith(
        DriveBackupService(
          client: MockClient(
            (_) async => throw http.ClientException('mất mạng'),
          ),
        ),
      );

      final result = await coordinator.backupNow();

      expect(result, isA<ActionFailed>());
    });

    test('tải về trả lại đúng nội dung đã đẩy lên', () async {
      await connectGoogle();
      String? payload;
      final drive = DriveBackupService(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            payload = _payloadOf(utf8.decode(request.bodyBytes));
            return http.Response('{"id":"f9"}', 200);
          }
          return http.Response(payload!, 200);
        }),
      );
      final coordinator = coordinatorWith(drive);

      await coordinator.backupNow();
      final armored = await coordinator.download('f9');

      // Đúng thứ `TongtaiBackupService.validate` nhận — Drive không đụng vào
      // định dạng, nó chỉ là chỗ cất.
      expect(armored, startsWith('TONGTAI-BACKUP-V2:'));
      expect(armored, payload);
    });

    test('bản sao lưu tải lên KHÔNG chứa token', () async {
      await connectGoogle();
      String? uploaded;
      final coordinator = coordinatorWith(
        DriveBackupService(
          client: MockClient((request) async {
            uploaded = utf8.decode(request.bodyBytes);
            return http.Response('{"id":"f1"}', 200);
          }),
        ),
      );

      await coordinator.backupNow();

      // `.ttbk` chép metadata kết nối; khoá thì nằm ở Keystore. Nếu một ngày
      // ai đó "tiện tay" ghi token vào một cột, test này đỏ trước khi bản sao
      // lưu chứa bí mật đi ra khỏi máy người bán.
      expect(uploaded, isNotNull);
      expect(uploaded, isNot(contains('access-1')));
      expect(uploaded, isNot(contains('refresh-1')));
    });

    test('chưa kết nối ⇒ list trả rỗng, không ném ra UI', () async {
      google = GoogleConnection(
        connections: connections,
        authenticator: const UnconfiguredGoogleAuthenticator(),
        now: () => clock,
      );
      final coordinator = coordinatorWith(
        DriveBackupService(client: MockClient((_) async => fail('không gọi'))),
      );

      expect(await coordinator.list(), isEmpty);
    });
  });
}

/// Authenticator giả — không mở trình duyệt, không cần client ID.
class _FakeAuthenticator implements GoogleAuthenticator {
  _FakeAuthenticator({
    required this.onAuthorize,
    GoogleTokens Function(String refreshToken)? onRefresh,
    void Function()? onRevoke,
  }) : onRefresh = onRefresh ?? ((_) => throw StateError('không mong đợi')),
       onRevoke = onRevoke ?? (() {});

  final GoogleTokens Function(List<String> scopes) onAuthorize;
  final GoogleTokens Function(String refreshToken) onRefresh;
  final void Function() onRevoke;

  @override
  Future<GoogleTokens> authorize(List<String> scopes) async =>
      onAuthorize(scopes);

  @override
  Future<GoogleTokens> refresh(
    String refreshToken,
    List<String> scopes,
  ) async => onRefresh(refreshToken);

  @override
  Future<void> revoke(String token) async => onRevoke();
}

/// Cắt phần nội dung file ra khỏi khung multipart.
String _payloadOf(String multipart) {
  final marker = 'Content-Type: application/octet-stream\r\n\r\n';
  final start = multipart.indexOf(marker) + marker.length;
  final end = multipart.lastIndexOf('\r\n--');
  return multipart.substring(start, end);
}
