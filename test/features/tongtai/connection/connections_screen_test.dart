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
import 'package:tongtai/features/tongtai/providers/tongtai_agentic_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
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

  Future<void> reveal(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(finder, 250);

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
