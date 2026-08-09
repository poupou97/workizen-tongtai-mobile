import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/connection/connection_capability.dart';
import 'package:tongtai/features/tongtai/connection/connection_credential_store.dart';
import 'package:tongtai/features/tongtai/connection/google/drive_backup_service.dart';
import 'package:tongtai/features/tongtai/connection/google/google_oauth.dart';
import 'package:tongtai/features/tongtai/core/connection.dart';
import 'package:tongtai/features/tongtai/action/business_action.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_agentic_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/connection/telegram/telegram_client.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_connection_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_connections_screen.dart';

import '../../../support/pump_until.dart';

/// WTM-317 · C1 — màn **Kết nối** (`IMPLEMENTATION_LEVEL=L3`).
///
/// Test hành vi tìm bằng `Key`, không bằng chữ hiển thị (luật test ID ổn định).
void main() {
  late AppDatabase db;
  late InMemoryConnectionCredentialStore credentials;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    credentials = InMemoryConnectionCredentialStore();
  });

  tearDown(() => db.close());

  Future<ProviderContainer> pumpConnections(
    WidgetTester tester, {
    GoogleAuthenticator authenticator = const UnconfiguredGoogleAuthenticator(),
    MockClient? driveClient,
    MockClient? telegramClient,
  }) async {
    final container = ProviderContainer(
      overrides: [
        tongtaiDatabaseProvider.overrideWithValue(db),
        connectionCredentialStoreProvider.overrideWithValue(credentials),
        googleAuthenticatorProvider.overrideWithValue(authenticator),
        if (driveClient != null)
          driveBackupServiceProvider.overrideWithValue(
            DriveBackupService(client: driveClient),
          ),
        if (telegramClient != null)
          telegramClientProvider.overrideWithValue(
            TelegramClient(client: telegramClient),
          ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('vi'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: [Locale('vi'), Locale('en')],
          home: TongtaiConnectionsScreen(),
        ),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('connections-list')));
    return container;
  }

  /// Cuộn tới khi thấy — chỉ định **rõ** cuộn cái nào.
  ///
  /// Mặc định `scrollUntilVisible` tìm `Scrollable` duy nhất trên cây; ô nhập
  /// bot token cũng là một `Scrollable` (`EditableText`), nên mặc định nổ
  /// "Too many elements" chứ không nổ vì màn hình sai.
  /// Chờ SnackBar tự tắt.
  ///
  /// Nó phủ đáy màn hình, và các nút chọn cuộc trò chuyện nằm ở dưới — bấm vào
  /// lúc snack còn hiện thì cú chạm rơi vào snack. Người dùng thật chỉ việc
  /// đợi bốn giây; test phải nói ra là mình đang đợi cái gì.
  Future<void> waitForSnackToGo(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    // `scrollUntilVisible` dừng ngay khi finder **tồn tại**, và mọi thứ trong
    // một thẻ đã dựng đều tồn tại kể cả khi nằm dưới mép màn hình. Nên phải
    // kéo thêm cho nó thật sự nhìn thấy được, nếu không cú chạm rơi vào chỗ
    // khác và test đỏ vì một lý do không liên quan gì tới màn hình.
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  group('trạng thái nói sự thật', () {
    testWidgets('mọi nền tảng trong catalog đều có thẻ', (tester) async {
      await pumpConnections(tester);

      for (final id in ConnectorDescriptor.catalog.keys) {
        final finder = find.byKey(Key('connections-connector-$id'));
        await reveal(tester, finder);
        expect(finder, findsOneWidget, reason: 'thiếu nền tảng $id');
      }
    });

    testWidgets('chưa kết nối ⇒ CHƯA THIẾT LẬP, không phải lỗi', (
      tester,
    ) async {
      await pumpConnections(tester);

      final chip = find.byKey(
        Key('connections-status-${ConnectionStatus.setupRequired.code}'),
      );
      // `.first`: cả ba nền tảng đều chưa thiết lập nên có ba chip — cuộn tới
      // một cái là đủ, và `scrollUntilVisible` chỉ nhận một mục tiêu.
      await reveal(tester, chip.first);
      expect(chip, findsWidgets);
      expect(
        find.byKey(Key('connections-status-${ConnectionStatus.error.code}')),
        findsNothing,
      );
    });

    testWidgets('chưa có khoá ⇒ KHÔNG hiện nút ngắt kết nối', (tester) async {
      await pumpConnections(tester);

      expect(
        find.byKey(const Key('connections-disconnect-$kGoogleConnectorId')),
        findsNothing,
      );
    });
  });

  group('chưa có OAuth client ID', () {
    testWidgets('bấm Kết nối ⇒ nói RÕ vì sao, không im lặng', (tester) async {
      await pumpConnections(tester);

      final button = find.byKey(
        const Key('connections-connect-$kGoogleConnectorId'),
      );
      await reveal(tester, button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      // Và **không** giả vờ đã kết nối (§8).
      expect(
        find.byKey(Key('connections-status-${ConnectionStatus.active.code}')),
        findsNothing,
      );
    });

    testWidgets('danh sách bản sao lưu rỗng — không phải lỗi', (tester) async {
      await pumpConnections(tester);

      final empty = find.byKey(const Key('connections-drive-empty'));
      await reveal(tester, empty);
      expect(empty, findsOneWidget);
    });
  });

  group('đã kết nối', () {
    testWidgets('sao lưu ngay chạy THẬT và nói lúc nào xong', (tester) async {
      final connected = _FakeAuthenticator(
        () => GoogleTokens(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );
      var uploads = 0;
      final container = await pumpConnections(
        tester,
        authenticator: connected,
        driveClient: MockClient((request) async {
          if (request.method == 'POST') {
            uploads++;
            return http.Response('{"id":"drive-file-1"}', 200);
          }
          return http.Response('{"files":[]}', 200);
        }),
      );

      // Kết nối trước — nút sao lưu chỉ có nghĩa sau khi có khoá.
      final connect = find.byKey(
        const Key('connections-connect-$kGoogleConnectorId'),
      );
      await reveal(tester, connect);
      await tester.tap(connect);
      await tester.pumpAndSettle();

      final backup = find.byKey(const Key('connections-drive-backup-now'));
      await reveal(tester, backup);
      await tester.tap(backup);
      await tester.pumpAndSettle();

      expect(uploads, 1);
      final last = find.byKey(const Key('connections-drive-last'));
      await reveal(tester, last);
      expect(last, findsOneWidget);

      // Và hành động nằm trong lịch sử, mang mã THẬT.
      final actions = await container
          .read(businessActionExecutorProvider)
          .loadRecent();
      expect(actions, hasLength(1));
      expect(actions.single.externalId, 'drive:drive-file-1');
    });

    testWidgets('có khoá ⇒ hiện nút ngắt kết nối, bấm thì khoá biến mất', (
      tester,
    ) async {
      await pumpConnections(
        tester,
        authenticator: _FakeAuthenticator(
          () => GoogleTokens(
            accessToken: 'access-1',
            refreshToken: 'refresh-1',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        ),
        driveClient: MockClient(
          (_) async => http.Response('{"files":[]}', 200),
        ),
      );

      final connect = find.byKey(
        const Key('connections-connect-$kGoogleConnectorId'),
      );
      await reveal(tester, connect);
      await tester.tap(connect);
      await tester.pumpAndSettle();

      final disconnect = find.byKey(
        const Key('connections-disconnect-$kGoogleConnectorId'),
      );
      await reveal(tester, disconnect);
      expect(disconnect, findsOneWidget);

      await tester.tap(disconnect);
      await tester.pumpAndSettle();

      expect(credentials.debugAll, isEmpty);
    });
  });

  group('Telegram — ba bước, và bước khó là bước thứ hai', () {
    /// Phản hồi giả dựng bằng bytes: `http.Response(String, …)` mặc định
    /// latin-1 nên tên tiếng Việt sẽ nổ trong test dù production chạy tốt.
    http.Response tgJson(Map<String, Object?> body) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      200,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

    MockClient telegram({
      bool tokenValid = true,
      List<Object> chats = const [],
      void Function(String text)? onSend,
    }) => MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('getMe')) {
        return tokenValid
            ? tgJson({
                'ok': true,
                'result': {
                  'id': 1,
                  'username': 'tongtai_bot',
                  'first_name': 'Tổng Tài',
                },
              })
            : tgJson({
                'ok': false,
                'error_code': 401,
                'description': 'Unauthorized',
              });
      }
      if (path.endsWith('sendMessage')) {
        onSend?.call((jsonDecode(request.body) as Map)['text'] as String);
        return tgJson({
          'ok': true,
          'result': {'message_id': 42},
        });
      }
      return tgJson({'ok': true, 'result': chats});
    });

    testWidgets('token sai ⇒ nói ra, KHÔNG hiện nút gửi thử', (tester) async {
      await pumpConnections(
        tester,
        telegramClient: telegram(tokenValid: false),
      );

      final field = find.byKey(const Key('connections-telegram-token'));
      await reveal(tester, field);
      await tester.enterText(field, 'bậy');
      final save = find.byKey(const Key('connections-telegram-save'));
      await reveal(tester, save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(credentials.debugAll, isEmpty);
      expect(
        find.byKey(const Key('connections-telegram-test')),
        findsNothing,
        reason: 'token sai mà vẫn mời gửi thử là mời bấm vào một thứ chắc hỏng',
      );
    });

    testWidgets('chưa ai /start ⇒ nói rõ, không phải danh sách trống câm', (
      tester,
    ) async {
      await pumpConnections(tester, telegramClient: telegram());

      final field = find.byKey(const Key('connections-telegram-token'));
      await reveal(tester, field);
      await tester.enterText(field, '123:ABC');
      final save = find.byKey(const Key('connections-telegram-save'));
      await reveal(tester, save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      final findChats = find.byKey(const Key('connections-telegram-find'));
      await reveal(tester, findChats);
      await tester.tap(findChats);
      await tester.pumpAndSettle();

      final empty = find.byKey(const Key('connections-telegram-no-chats'));
      await reveal(tester, empty);
      expect(empty, findsOneWidget);
    });

    testWidgets('trọn chuỗi: token → chọn cuộc trò chuyện → gửi tin THẬT', (
      tester,
    ) async {
      final sent = <String>[];
      final container = await pumpConnections(
        tester,
        telegramClient: telegram(
          chats: const [
            {
              'message': {
                'chat': {'id': 555, 'first_name': 'Alex'},
              },
            },
          ],
          onSend: sent.add,
        ),
      );

      final field = find.byKey(const Key('connections-telegram-token'));
      await reveal(tester, field);
      await tester.enterText(field, '123:ABC');
      final save = find.byKey(const Key('connections-telegram-save'));
      await reveal(tester, save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      await waitForSnackToGo(tester);

      final findChats = find.byKey(const Key('connections-telegram-find'));
      await reveal(tester, findChats);
      await tester.tap(findChats);
      await tester.pumpAndSettle();

      final chat = find.byKey(const Key('connections-telegram-chat-555'));
      await reveal(tester, chat);
      await tester.tap(chat);
      await tester.pumpAndSettle();

      // Chọn xong nơi nhận thì mới có nút gửi thử — trước đó thì không.
      // `pumpUntilFound`: `telegramReadyProvider` là một `FutureProvider`, nên
      // nút xuất hiện ở khung hình SAU khi future xong, không phải ngay.
      final test = find.byKey(const Key('connections-telegram-test'));
      await pumpUntilFound(tester, test);
      await reveal(tester, test);
      await tester.tap(test);
      await tester.pumpAndSettle();

      expect(sent, hasLength(1));
      final actions = await container
          .read(businessActionExecutorProvider)
          .loadRecent();
      expect(actions.single.externalId, 'telegram:42');
      expect(actions.single.vendor, ActionVendor.telegram);
    });
  });
}

class _FakeAuthenticator implements GoogleAuthenticator {
  _FakeAuthenticator(this.tokens);

  final GoogleTokens Function() tokens;

  @override
  Future<GoogleTokens> authorize(List<String> scopes) async => tokens();

  @override
  Future<GoogleTokens> refresh(
    String refreshToken,
    List<String> scopes,
  ) async => tokens();

  @override
  Future<void> revoke(String token) async {}
}
