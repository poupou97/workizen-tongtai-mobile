import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Jira + Confluence Cloud — WTM-319 (C3 · Epic WTM-315).
///
/// ## Một token, hai sản phẩm
///
/// Cùng một API token của Atlassian dùng được cho cả Jira lẫn Confluence
/// (`activepieces/jira-cloud/src/auth.ts:12` · `confluence/src/lib/auth.ts:3`).
/// Nên **một** connection, hai capability — không nhân đôi credential, không
/// bắt người dùng dán cùng một chuỗi hai lần.
///
/// ## Basic auth, không OAuth — và đó là lựa chọn đúng ở đây
///
/// Atlassian có OAuth 3LO, nhưng nó cần một app đăng ký và một `client_secret`
/// ⇒ theo luật WTM-309 thì **không phải mobile-direct**. API token là
/// `email:token` mã hoá base64 trong header — chạy thẳng từ máy, không backend.
///
/// Cái giá: token có **toàn quyền của người dùng đó**, không giới hạn scope
/// được. Nên Tổng Tài chỉ **đọc**, và chỉ đọc đúng project/space người dùng
/// chọn — ghi để phase sau, và khi làm thì qua `ProposedChange`/`BusinessAction`
/// chứ không gọi thẳng.
class AtlassianClient {
  AtlassianClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// ⭐ Gọi API **thật** lúc nhập khoá.
  ///
  /// Học thẳng từ Activepieces: sai khoá phải biết **lúc dán**, không phải lúc
  /// agent chạy rồi thất bại im lặng ba ngày sau.
  Future<AtlassianAccount> validate({
    required String instanceUrl,
    required String email,
    required String token,
  }) async {
    final body = await _get(
      instanceUrl: instanceUrl,
      email: email,
      token: token,
      path: '/rest/api/3/myself',
    );
    final name = body['displayName'];
    if (name is! String) {
      throw const AtlassianException(
        AtlassianFailure.unexpected,
        'Atlassian trả lời nhưng không có tài khoản nào',
      );
    }
    return AtlassianAccount(
      accountId: '${body['accountId']}',
      displayName: name,
      email: body['emailAddress'] as String?,
    );
  }

  /// Các project **người dùng chọn được**. Không import toàn Jira vô điều kiện.
  Future<List<AtlassianProject>> projects({
    required String instanceUrl,
    required String email,
    required String token,
  }) async {
    final body = await _get(
      instanceUrl: instanceUrl,
      email: email,
      token: token,
      path: '/rest/api/3/project/search?maxResults=50',
    );
    final values = body['values'];
    if (values is! List) return const [];
    return [
      for (final v in values)
        if (v is Map && v['key'] is String)
          AtlassianProject(
            key: v['key'] as String,
            name: v['name'] as String? ?? v['key'] as String,
          ),
    ];
  }

  /// Issue đang mở của một project — **đọc tối thiểu**, không phải Jira mobile.
  ///
  /// Cố ý không lấy description, không lấy comment, không phân trang quá 100:
  /// mục tiêu là dựng được **một câu tóm tắt**, không phải dựng lại cái board.
  Future<List<AtlassianIssue>> openIssues({
    required String instanceUrl,
    required String email,
    required String token,
    required String projectKey,
  }) async {
    final jql = Uri.encodeQueryComponent(
      'project = "$projectKey" ORDER BY updated DESC',
    );
    final body = await _get(
      instanceUrl: instanceUrl,
      email: email,
      token: token,
      path:
          '/rest/api/3/search/jql?jql=$jql&maxResults=100'
          '&fields=summary,status,priority,assignee,updated',
    );
    final issues = body['issues'];
    if (issues is! List) return const [];
    return [
      for (final raw in issues)
        if (raw is Map && raw['key'] is String)
          AtlassianIssue(
            key: raw['key'] as String,
            summary: _string(raw, ['fields', 'summary']) ?? '',
            status: _string(raw, ['fields', 'status', 'name']) ?? '',
            statusCategory:
                _string(raw, ['fields', 'status', 'statusCategory', 'key']) ??
                '',
            priority: _string(raw, ['fields', 'priority', 'name']),
            assignee: _string(raw, ['fields', 'assignee', 'displayName']),
            updatedAt: DateTime.tryParse(
              _string(raw, ['fields', 'updated']) ?? '',
            ),
          ),
    ];
  }

  /// Space người dùng chọn được. **Không crawl toàn workspace.**
  Future<List<AtlassianSpace>> spaces({
    required String instanceUrl,
    required String email,
    required String token,
  }) async {
    final body = await _get(
      instanceUrl: instanceUrl,
      email: email,
      token: token,
      path: '/wiki/api/v2/spaces?limit=50',
    );
    final results = body['results'];
    if (results is! List) return const [];
    return [
      for (final v in results)
        if (v is Map && v['key'] is String)
          AtlassianSpace(
            id: '${v['id']}',
            key: v['key'] as String,
            name: v['name'] as String? ?? v['key'] as String,
          ),
    ];
  }

  /// Trang trong một space — **tiêu đề và đường dẫn**, không phải nội dung.
  ///
  /// ⛔ Cố ý không tải body. Biến mọi đoạn văn Confluence thành "sự thật kinh
  /// doanh" là cách nhanh nhất để một bản nháp từ năm ngoái trở thành căn cứ
  /// cho một đề xuất hôm nay. Trang là **tham chiếu tri thức**, và người đọc
  /// nó là con người.
  Future<List<AtlassianPage>> pages({
    required String instanceUrl,
    required String email,
    required String token,
    required String spaceId,
  }) async {
    final body = await _get(
      instanceUrl: instanceUrl,
      email: email,
      token: token,
      path: '/wiki/api/v2/pages?space-id=$spaceId&limit=50&sort=-modified-date',
    );
    final results = body['results'];
    if (results is! List) return const [];
    return [
      for (final v in results)
        if (v is Map && v['title'] is String)
          AtlassianPage(
            id: '${v['id']}',
            title: v['title'] as String,
            updatedAt: DateTime.tryParse(
              _string(v, ['version', 'createdAt']) ?? '',
            ),
          ),
    ];
  }

  Future<Map<String, dynamic>> _get({
    required String instanceUrl,
    required String email,
    required String token,
    required String path,
  }) async {
    final base = instanceUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final auth = base64Encode(utf8.encode('$email:$token'));

    final http.Response res;
    try {
      res = await _client.get(
        Uri.parse('$base$path'),
        headers: {'Authorization': 'Basic $auth', 'Accept': 'application/json'},
      );
    } on http.ClientException catch (e) {
      throw AtlassianException(AtlassianFailure.network, e.message);
    } on FormatException catch (e) {
      // URL người dùng gõ sai (thiếu `https://`, có khoảng trắng) — lỗi của
      // ô nhập, không phải của mạng, nên nói khác đi.
      throw AtlassianException(AtlassianFailure.badInstanceUrl, e.message);
    }

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const AtlassianException(
        AtlassianFailure.unexpected,
        'phản hồi không phải một đối tượng JSON',
      );
    }

    throw AtlassianException(switch (res.statusCode) {
      401 => AtlassianFailure.unauthorized,
      403 => AtlassianFailure.forbidden,
      404 => AtlassianFailure.notFound,
      429 => AtlassianFailure.rateLimited,
      >= 500 => AtlassianFailure.temporary,
      _ => AtlassianFailure.unexpected,
    }, 'HTTP ${res.statusCode}');
  }

  /// Đọc một chuỗi lồng sâu, `null` khi thiếu bất kỳ tầng nào.
  ///
  /// Jira trả `assignee: null` cho issue chưa giao và `priority: null` cho
  /// project không bật priority — cả hai đều **bình thường**, nên đường đọc
  /// phải chịu được `null` ở giữa thay vì nổ.
  static String? _string(Map<dynamic, dynamic> root, List<String> path) {
    Object? current = root;
    for (final key in path) {
      if (current is! Map) return null;
      current = current[key];
    }
    return current is String ? current : null;
  }
}

@immutable
class AtlassianAccount {
  const AtlassianAccount({
    required this.accountId,
    required this.displayName,
    this.email,
  });

  final String accountId;
  final String displayName;
  final String? email;
}

@immutable
class AtlassianProject {
  const AtlassianProject({required this.key, required this.name});

  final String key;
  final String name;
}

@immutable
class AtlassianSpace {
  const AtlassianSpace({
    required this.id,
    required this.key,
    required this.name,
  });

  final String id;
  final String key;
  final String name;
}

@immutable
class AtlassianPage {
  const AtlassianPage({required this.id, required this.title, this.updatedAt});

  final String id;
  final String title;

  /// `null` = Atlassian không trả về, **không phải** "chưa bao giờ sửa".
  final DateTime? updatedAt;
}

@immutable
class AtlassianIssue {
  const AtlassianIssue({
    required this.key,
    required this.summary,
    required this.status,
    required this.statusCategory,
    this.priority,
    this.assignee,
    this.updatedAt,
  });

  final String key;
  final String summary;

  /// Tên cột người dùng thấy — `In Progress`, `Code Review`, `ANALYSIS`…
  final String status;

  /// `new` · `indeterminate` · `done` — **cái này** mới ổn định giữa các
  /// project. Tên cột thì mỗi project một kiểu, nên đếm theo tên cột là đếm
  /// theo một thứ ai cũng đổi được.
  final String statusCategory;

  /// `null` = project không bật priority, **không phải** "ưu tiên thấp nhất".
  final String? priority;

  /// `null` = chưa giao cho ai.
  final String? assignee;

  final DateTime? updatedAt;

  bool get isDone => statusCategory == 'done';

  bool get isInProgress => statusCategory == 'indeterminate';
}

enum AtlassianFailure {
  /// 401 — email hoặc token sai.
  unauthorized,

  /// 403 — token đúng nhưng tài khoản không có quyền vào chỗ đó.
  forbidden,

  /// 404 — sai instance URL, hoặc project/space không tồn tại.
  notFound,

  /// URL gõ sai ngay từ đầu (thiếu `https://`…).
  badInstanceUrl,

  rateLimited,
  temporary,
  network,
  unexpected,
}

class AtlassianException implements Exception {
  const AtlassianException(this.failure, [this.detail]);

  final AtlassianFailure failure;

  /// Chỉ hiện trên máy người dùng (ADR-TON-017).
  final String? detail;

  @override
  String toString() => 'AtlassianException(${failure.name})';
}
