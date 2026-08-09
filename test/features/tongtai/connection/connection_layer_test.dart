import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/connection/connection_capability.dart';
import 'package:tongtai/features/tongtai/connection/connection_credential_store.dart';
import 'package:tongtai/features/tongtai/connection/connection_repository.dart';
import 'package:tongtai/features/tongtai/connection/connection_service.dart';
import 'package:tongtai/features/tongtai/core/connection.dart';

/// WTM-317 · C1 — tầng Connection dùng chung.
///
/// Suite này khoá những tính chất mà cả ba connector sắp tới (Google ·
/// Telegram · Atlassian) đều dựa vào. Sai ở đây thì sai ba lần.
void main() {
  late AppDatabase db;
  late DriftConnectionRepository repo;
  late InMemoryConnectionCredentialStore credentials;
  late ConnectionService service;
  var clock = DateTime(2026, 8, 9, 10);

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    repo = DriftConnectionRepository(db);
    credentials = InMemoryConnectionCredentialStore();
    service = ConnectionService(
      repository: repo,
      credentials: credentials,
      now: () => clock,
    );
  });

  tearDown(() => db.close());

  group('vòng đời', () {
    test('kết nối mới bắt đầu ở SETUP_REQUIRED, không phải ACTIVE', () async {
      final c = await service.ensure(kGoogleConnectorId, label: 'Google');

      expect(c.status, ConnectionStatus.setupRequired);
      expect(await service.isUsable(c), isFalse);
    });

    test('ensure hai lần cho MỘT kết nối', () async {
      final first = await service.ensure(kGoogleConnectorId, label: 'Google');
      final second = await service.ensure(kGoogleConnectorId, label: 'Khác');

      expect(second.id, first.id);
      expect(await repo.loadAll(), hasLength(1));
      // Nhãn giữ nguyên: `ensure` không phải `rename`.
      expect(second.label, 'Google');
    });

    test('có credential mới thành ACTIVE', () async {
      final c = await service.ensure(kTelegramConnectorId, label: 'Bot bán');
      final active = await service.attachCredentials(c, {
        CredentialField.token: '123:ABC',
      });

      expect(active.status, ConnectionStatus.active);
      expect((await repo.byId(c.id))!.status, ConnectionStatus.active);
      expect(await service.isUsable(active), isTrue);
    });

    test('cụm credential rỗng bị từ chối — sẽ tạo ACTIVE không khoá', () async {
      final c = await service.ensure(kTelegramConnectorId, label: 'Bot');

      expect(
        () => service.attachCredentials(c, const {}),
        throwsA(isA<ArgumentError>()),
      );
      expect((await repo.byId(c.id))!.status, ConnectionStatus.setupRequired);
    });

    test('ngắt kết nối xoá CẢ HAI nửa', () async {
      final c = await service.ensure(kTelegramConnectorId, label: 'Bot');
      await service.attachCredentials(c, {CredentialField.token: '123:ABC'});

      await service.disconnect(c);

      expect(await repo.byId(c.id), isNull);
      expect(credentials.debugAll, isEmpty);
    });

    test('markError giữ credential — mất mạng không phải mất quyền', () async {
      final c = await service.ensure(kGoogleConnectorId, label: 'Google');
      await service.attachCredentials(c, {CredentialField.token: 'tok'});

      final failed = await service.markError(c);

      expect(failed.status, ConnectionStatus.error);
      expect(await credentials.has(c), isTrue);
    });
  });

  group('trạng thái hiển thị nói SỰ THẬT', () {
    test('bản ghi ACTIVE nhưng mất credential ⇒ SETUP_REQUIRED', () async {
      final c = await service.ensure(kGoogleConnectorId, label: 'Google');
      await service.attachCredentials(c, {CredentialField.token: 'tok'});
      // Người dùng xoá dữ liệu app / khôi phục sang máy mới: bảng còn, Keystore
      // mất. Bản ghi vẫn nói `active` — và nó sai.
      await credentials.delete(c);

      final states = await service.catalogState();
      final google = states.firstWhere(
        (s) => s.descriptor.id == kGoogleConnectorId,
      );

      expect(google.connection!.status, ConnectionStatus.active);
      expect(google.status, ConnectionStatus.setupRequired);
    });

    test('mã trạng thái lạ ⇒ bỏ dòng, KHÔNG rơi về active', () async {
      final c = await service.ensure(kGoogleConnectorId, label: 'Google');
      await db.customStatement(
        "UPDATE connections_table SET status = 'totally_unknown' WHERE id = ?",
        [c.id],
      );

      expect(await repo.byId(c.id), isNull);
      expect(await repo.loadAll(), isEmpty);
    });
  });

  group('capability — quyền đi theo khả năng, không theo nền tảng', () {
    test('bật sao lưu Drive chỉ xin drive.file', () {
      final scopes = ConnectionCapability.scopesFor({
        ConnectionCapability.driveBackup,
      });

      expect(scopes, ['https://www.googleapis.com/auth/drive.file']);
    });

    test('khả năng CHƯA bật không đóng góp scope nào', () {
      final scopes = ConnectionCapability.scopesFor(const []);

      expect(scopes, isEmpty);
    });

    test('drive.file không phải restricted scope `auth/drive`', () {
      // Chốt bằng test vì đây là khác biệt mua được cả một vòng đánh giá bảo
      // mật bên thứ ba. Ai đó "sửa cho tiện" thành `auth/drive` sẽ đỏ ở đây
      // chứ không đỏ ở Google sáu tuần sau.
      for (final scope in ConnectionCapability.driveBackup.scopes) {
        expect(scope, isNot('https://www.googleapis.com/auth/drive'));
      }
    });

    test('catalog và capability dùng CHUNG một từ vựng nền tảng', () {
      for (final capability in ConnectionCapability.values) {
        expect(
          ConnectorDescriptor.byId(capability.connectorId),
          isNotNull,
          reason:
              'khả năng "${capability.code}" trỏ tới nền tảng '
              '"${capability.connectorId}" không có trong catalog',
        );
      }
    });
  });
}
