import '../core/connection.dart';
import 'connection_capability.dart';
import 'connection_credential_store.dart';

/// Vòng đời một kết nối — **dùng chung cho mọi nền tảng** (WTM-317).
///
/// ## Vì sao có lớp này thay vì mỗi vendor tự lo
///
/// Google, Telegram và Atlassian khác nhau ở **một** chỗ: cách lấy được cụm
/// credential. Mọi thứ còn lại — tạo bản ghi, đặt `SETUP_REQUIRED`, chuyển sang
/// `ACTIVE` khi đã có khoá, xoá cả hai nửa khi ngắt — giống hệt nhau.
///
/// Nếu ba vendor tự làm ba lần thì đến vendor thứ ba sẽ có một chỗ quên xoá
/// credential lúc ngắt kết nối, và không ai phát hiện ra: giao diện vẫn báo
/// "đã ngắt".
///
/// ## Ngắt kết nối là HAI việc, và lớp này làm đủ cả hai
///
/// Xoá metadata trong DB, **và** xoá bí mật trong Keychain/Keystore.
/// `ConnectionRepository.delete` cố ý chỉ làm nửa đầu (xoá bí mật đáng là một
/// hành động nhìn thấy được) — nên nửa sau phải có một chỗ *bắt buộc* làm, và
/// đó là đây.
class ConnectionService {
  ConnectionService({
    required ConnectionRepositoryLike repository,
    required this.credentials,
    this.now = DateTime.now,
  }) : _repo = repository;

  final ConnectionRepositoryLike _repo;
  final ConnectionCredentialStore credentials;
  final DateTime Function() now;

  /// Mã kết nối suy ra từ nền tảng.
  ///
  /// Một tài khoản mỗi nền tảng ở giai đoạn này — nên mã tất định, và gọi
  /// `ensure` hai lần **không** sinh hai kết nối. Ngày có người bán nối hai
  /// shop, chỗ này đổi thành mã ngẫu nhiên và không chỗ nào khác phải đổi.
  static String connectionIdFor(String connectorId) => 'conn-$connectorId';

  /// Kết nối tới nền tảng, tạo mới ở [ConnectionStatus.setupRequired] nếu chưa
  /// có. **Không** đụng tới credential — đó là bước sau.
  Future<Connection> ensure(String connectorId, {required String label}) async {
    final id = connectionIdFor(connectorId);
    final existing = await _repo.byId(id);
    if (existing != null) return existing;

    final created = Connection(
      id: id,
      connectorId: connectorId,
      label: label,
      status: ConnectionStatus.setupRequired,
      createdAt: now(),
    );
    await _repo.upsert(created);
    return created;
  }

  /// Lưu cụm credential và chuyển kết nối sang `ACTIVE`.
  ///
  /// Trạng thái đi theo **credential có thật**, không theo một lần bấm nút —
  /// đó là điều kiện của luật "không fake connected" (§8).
  Future<Connection> attachCredentials(
    Connection connection,
    Map<String, String> value,
  ) async {
    if (value.isEmpty) {
      throw ArgumentError.value(
        value,
        'value',
        'cụm credential rỗng — sẽ tạo ra một kết nối ACTIVE không có khoá',
      );
    }
    await credentials.write(connection, value);
    final active = connection.copyWith(status: ConnectionStatus.active);
    await _repo.upsert(active);
    return active;
  }

  /// Đánh dấu kết nối hỏng — khoá bị thu hồi, nền tảng từ chối.
  ///
  /// Credential **được giữ lại**: người bán có thể đang mất mạng, và xoá khoá
  /// vì một lần gọi hỏng sẽ bắt họ đăng nhập lại vô cớ.
  Future<Connection> markError(Connection connection) async {
    final failed = connection.copyWith(status: ConnectionStatus.error);
    await _repo.upsert(failed);
    return failed;
  }

  Future<Connection> markSynced(Connection connection) async {
    final synced = connection.copyWith(
      status: ConnectionStatus.active,
      lastSyncAt: now(),
    );
    await _repo.upsert(synced);
    return synced;
  }

  /// Ngắt: xoá **bí mật trước**, metadata sau.
  ///
  /// Thứ tự có lý do. Hỏng giữa chừng ở thứ tự này để lại một kết nối
  /// `SETUP_REQUIRED` không khoá — nhìn thấy được, sửa được. Thứ tự ngược lại
  /// để lại một bí mật **mồ côi** trong Keystore mà không bản ghi nào trỏ tới,
  /// nên không màn hình nào xoá được nữa.
  Future<void> disconnect(Connection connection) async {
    await credentials.delete(connection);
    await _repo.delete(connection.id);
  }

  /// **Đã kết nối chưa** — hỏi Keychain/Keystore, không hỏi cột `status`.
  ///
  /// Cột `status` là thứ *ta* ghi; credential là thứ *thật sự* quyết định gọi
  /// được API hay không. Khi hai bên lệch nhau, tin bên thứ hai.
  Future<bool> isUsable(Connection connection) => credentials.has(connection);

  /// Nền tảng nào đã nối, cùng trạng thái — nguồn cho màn Kết nối.
  Future<List<ConnectorState>> catalogState() async {
    final out = <ConnectorState>[];
    for (final descriptor in ConnectorDescriptor.catalog.values) {
      final connection = await _repo.byConnector(descriptor.id);
      out.add(
        ConnectorState(
          descriptor: descriptor,
          connection: connection,
          hasCredentials: connection == null
              ? false
              : await credentials.has(connection),
        ),
      );
    }
    return out;
  }
}

/// Phần `ConnectionService` cần từ kho — hẹp hơn `ConnectionRepository` để test
/// không phải dựng cả cơ sở dữ liệu.
abstract interface class ConnectionRepositoryLike {
  Future<Connection?> byId(String id);

  Future<Connection?> byConnector(String connectorId);

  Future<void> upsert(Connection connection);

  Future<void> delete(String id);
}

/// Một nền tảng nhìn từ màn Kết nối.
class ConnectorState {
  const ConnectorState({
    required this.descriptor,
    required this.connection,
    required this.hasCredentials,
  });

  final ConnectorDescriptor descriptor;

  /// `null` = người bán chưa từng mở nền tảng này.
  final Connection? connection;

  final bool hasCredentials;

  /// Trạng thái **hiển thị** — hợp nhất bản ghi và credential thật.
  ///
  /// Có bản ghi `ACTIVE` mà mất credential (người dùng xoá dữ liệu app, khôi
  /// phục máy mới) ⇒ nói `SETUP_REQUIRED`, vì đó là sự thật.
  ConnectionStatus get status {
    final c = connection;
    if (c == null) return ConnectionStatus.setupRequired;
    if (!hasCredentials) return ConnectionStatus.setupRequired;
    return c.status;
  }
}
