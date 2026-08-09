import '../../core/connection.dart';
import '../connection_capability.dart';
import '../connection_credential_store.dart';
import '../connection_service.dart';
import 'atlassian_client.dart';
import 'work_context.dart';

/// Vòng đời kết nối Atlassian — WTM-319.
///
/// **Một** connection, **hai** capability (`jiraWork` · `confluenceKnowledge`),
/// vì cùng một API token dùng được cho cả hai. Tách ra thành hai connection sẽ
/// bắt người dùng dán cùng một chuỗi hai lần và tạo ra hai chỗ để quên thu hồi.
///
/// ## Ba trường, và chỉ một trong ba là bí mật
///
/// `instanceUrl` và `email` không phải bí mật. Chúng vẫn nằm trong cùng cụm
/// credential — xem `ConnectionCredentialStore`: gom một chỗ để **xoá kết nối
/// là xoá một khoá**, không phải nhớ có bao nhiêu mảnh rải đâu.
class AtlassianConnection {
  AtlassianConnection({required this._connections, required this._client});

  final ConnectionService _connections;
  final AtlassianClient _client;

  Future<Connection> ensure({String label = 'Jira & Confluence'}) =>
      _connections.ensure(kAtlassianConnectorId, label: label);

  /// Nhập khoá — **gọi API thật ngay tại chỗ** (Founder §, học Activepieces).
  ///
  /// Sai khoá phải biết **lúc dán**. Lưu trước rồi để agent phát hiện sau là
  /// đổi một thông báo lỗi rõ ràng lấy một sự im lặng ba ngày.
  Future<AtlassianSetup> attachCredentials({
    required String instanceUrl,
    required String email,
    required String token,
  }) async {
    final url = instanceUrl.trim();
    final mail = email.trim();
    final key = token.trim();
    if (url.isEmpty || mail.isEmpty || key.isEmpty) {
      return const AtlassianSetup.failed(AtlassianFailure.unauthorized);
    }

    final connection = await ensure();
    final AtlassianAccount account;
    try {
      account = await _client.validate(
        instanceUrl: url,
        email: mail,
        token: key,
      );
    } on AtlassianException catch (e) {
      // Khoá hỏng ⇒ **không ghi gì**. Cùng luật Telegram: lưu một bí mật vô
      // dụng rồi đánh dấu `error` chỉ để lại rác trong Keystore.
      return AtlassianSetup.failed(e.failure);
    }

    final previous =
        await _connections.credentials.read(connection) ?? const {};
    await _connections.credentials.write(connection, {
      ...previous,
      CredentialField.instanceUrl: url,
      CredentialField.email: mail,
      CredentialField.token: key,
    });

    // Có khoá nhưng **chưa chọn project** ⇒ vẫn chưa đọc được gì có nghĩa.
    final project = previous[CredentialField.projectKey];
    await _connections.repository.upsert(
      connection.copyWith(
        label: account.displayName,
        status: project == null || project.isEmpty
            ? ConnectionStatus.setupRequired
            : ConnectionStatus.active,
      ),
    );
    return AtlassianSetup.ok(account);
  }

  Future<List<AtlassianProject>> projects() async {
    final c = await _credentials();
    if (c == null) return const [];
    return _client.projects(
      instanceUrl: c.instanceUrl,
      email: c.email,
      token: c.token,
    );
  }

  Future<List<AtlassianSpace>> spaces() async {
    final c = await _credentials();
    if (c == null) return const [];
    return _client.spaces(
      instanceUrl: c.instanceUrl,
      email: c.email,
      token: c.token,
    );
  }

  /// **Founder chọn project.** Không import toàn Jira vô điều kiện.
  Future<Connection?> selectProject(String projectKey) async {
    final connection = await ensure();
    final stored = await _connections.credentials.read(connection);
    if (stored == null || (stored[CredentialField.token] ?? '').isEmpty) {
      return null;
    }
    return _connections.attachCredentials(connection, {
      ...stored,
      CredentialField.projectKey: projectKey,
    });
  }

  /// Người dùng chọn space. Không crawl toàn workspace.
  Future<Connection?> selectSpace(AtlassianSpace space) async {
    final connection = await ensure();
    final stored = await _connections.credentials.read(connection);
    if (stored == null || (stored[CredentialField.token] ?? '').isEmpty) {
      return null;
    }
    return _connections.attachCredentials(connection, {
      ...stored,
      CredentialField.spaceId: space.id,
      CredentialField.spaceKey: space.key,
    });
  }

  /// Công việc đang thế nào. `null` = chưa nối hoặc chưa chọn project.
  ///
  /// `null` **khác** một `WorkContext` rỗng: cái đầu là *chưa hỏi được*, cái
  /// sau là *đã hỏi và không có việc nào*. Giao diện phải nói hai câu khác
  /// nhau (ADR-TON-017: `insufficient` ≠ `empty`).
  Future<WorkContext?> workContext({required DateTime now}) async {
    final c = await _credentials();
    final project = c?.projectKey;
    if (c == null || project == null || project.isEmpty) return null;

    final issues = await _client.openIssues(
      instanceUrl: c.instanceUrl,
      email: c.email,
      token: c.token,
      projectKey: project,
    );
    return WorkContext.derive(projectKey: project, issues: issues, now: now);
  }

  /// Tham chiếu tri thức — **tiêu đề trang**, không phải nội dung trang.
  Future<List<AtlassianPage>> knowledgeReferences() async {
    final c = await _credentials();
    final spaceId = c?.spaceId;
    if (c == null || spaceId == null || spaceId.isEmpty) return const [];
    return _client.pages(
      instanceUrl: c.instanceUrl,
      email: c.email,
      token: c.token,
      spaceId: spaceId,
    );
  }

  Future<bool> get isReady async => (await _credentials())?.projectKey != null;

  Future<void> disconnect() async => _connections.disconnect(await ensure());

  Future<_AtlassianCredentials?> _credentials() async {
    final stored = await _connections.credentials.read(await ensure());
    if (stored == null) return null;
    final url = stored[CredentialField.instanceUrl];
    final email = stored[CredentialField.email];
    final token = stored[CredentialField.token];
    if (url == null || email == null || token == null) return null;
    if (url.isEmpty || email.isEmpty || token.isEmpty) return null;
    return _AtlassianCredentials(
      instanceUrl: url,
      email: email,
      token: token,
      projectKey: _blankToNull(stored[CredentialField.projectKey]),
      spaceId: _blankToNull(stored[CredentialField.spaceId]),
    );
  }

  static String? _blankToNull(String? value) =>
      value == null || value.isEmpty ? null : value;
}

class _AtlassianCredentials {
  const _AtlassianCredentials({
    required this.instanceUrl,
    required this.email,
    required this.token,
    this.projectKey,
    this.spaceId,
  });

  final String instanceUrl;
  final String email;
  final String token;
  final String? projectKey;
  final String? spaceId;
}

/// Kết quả nhập khoá — phân loại ở đây để `ui/` không catch (ADR-TON-017).
class AtlassianSetup {
  const AtlassianSetup.ok(this.account) : failure = null;

  const AtlassianSetup.failed(this.failure) : account = null;

  final AtlassianAccount? account;
  final AtlassianFailure? failure;

  bool get succeeded => account != null;
}
