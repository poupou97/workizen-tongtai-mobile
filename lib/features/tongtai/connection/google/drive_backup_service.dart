import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Sao lưu `.ttbk` lên Google Drive — WTM-317 (C1 · Epic WTM-315).
///
/// ## Backup phải mang NGỮ NGHĨA backup, không phải "upload một file"
///
/// Founder §6 nói thẳng điều đó. Nên lớp này làm đủ **cả sáu** bước, và mỗi
/// bước là một hàm gọi được riêng để test được riêng:
///
/// ```
/// Export → Upload → List/Locate → Download → Preview → Restore
/// ```
///
/// Ba bước giữa là việc của lớp này; `Export` và `Restore` đã có từ WTM-164
/// (`.ttbk` v2) và **không đổi** — Drive chỉ thêm chỗ *cất* và chỗ *lấy về*.
///
/// ## Vì sao `drive.file`, không phải `drive`
///
/// `drive.file` cho app thấy **đúng những file chính nó tạo**. Không đọc được
/// gì khác trong Drive của người bán.
///
/// Đó vừa là quyền hẹp nhất làm xong được việc, vừa là **scope không bị
/// Google xếp vào restricted** — nên không cần đánh giá bảo mật bên thứ ba.
/// Activepieces xin `auth/drive` (`google-drive/src/lib/auth.ts:5`) vì nó là
/// automation đa năng; Tổng Tài chỉ cất một file của chính mình.
///
/// Hệ quả phải biết: app **không** thấy được bản `.ttbk` người bán tự tải lên
/// Drive từ máy khác. Với luồng sao lưu/khôi phục trong app thì không ảnh
/// hưởng, và đó là đánh đổi có chủ ý.
class DriveBackupService {
  DriveBackupService({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _now = now ?? DateTime.now;

  final http.Client _client;
  final DateTime Function() _now;

  static const String _uploadUrl =
      'https://www.googleapis.com/upload/drive/v3/files';
  static const String _filesUrl = 'https://www.googleapis.com/drive/v3/files';

  /// Mọi bản sao lưu mang tiền tố này để `list` tìm được mà không cần thư mục
  /// riêng — `drive.file` chỉ thấy file của chính app nên không sợ lẫn.
  static const String backupPrefix = 'tongtai-backup-';

  /// Mốc của một bản sao lưu — **chính xác tới phút**, tất định.
  ///
  /// Phút chứ không phải giây, và đó không phải chuyện thẩm mỹ: mốc này vừa là
  /// tên file vừa là khoá chống lặp. Nếu tên có giây còn khoá chỉ tới phút thì
  /// hai lần bấm trong một phút sẽ **cùng khoá, khác payload** — đúng thứ
  /// `BusinessActionExecutor` từ chối, và từ chối đúng.
  static String backupKeyFor(DateTime at) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${at.year}${two(at.month)}${two(at.day)}'
        '-${two(at.hour)}${two(at.minute)}';
  }

  /// Tên file cho một thời điểm — tất định, không dùng đồng hồ ngầm.
  static String fileNameFor(DateTime at) =>
      '$backupPrefix${backupKeyFor(at)}.ttbk';

  /// **Upload** — multipart: metadata + nội dung trong một request.
  ///
  /// Trả về `fileId` của Drive. Đó là thứ đi vào `BusinessAction.externalId`,
  /// nên nó **không** mang tiền tố `demo:` — người bán nhìn màn Hoạt động sẽ
  /// thấy đây là việc thật, tự động, không cần cờ nào thêm.
  Future<String> upload({
    required String accessToken,
    required Uint8List bytes,
    String? fileName,
  }) async {
    final name = fileName ?? fileNameFor(_now());
    const boundary = 'tongtai-ttbk-boundary';
    final metadata = jsonEncode({
      'name': name,
      // `appProperties` chỉ app này đọc được — dùng để nhận ra bản sao lưu của
      // chính mình mà không phải đoán từ tên file.
      'appProperties': {'tongtai': 'ttbk', 'schema': 'v2'},
    });

    final body = BytesBuilder()
      ..add(utf8.encode('--$boundary\r\n'))
      ..add(
        utf8.encode('Content-Type: application/json; charset=UTF-8\r\n\r\n'),
      )
      ..add(utf8.encode('$metadata\r\n'))
      ..add(utf8.encode('--$boundary\r\n'))
      ..add(utf8.encode('Content-Type: application/octet-stream\r\n\r\n'))
      ..add(bytes)
      ..add(utf8.encode('\r\n--$boundary--\r\n'));

    final res = await _client.post(
      Uri.parse('$_uploadUrl?uploadType=multipart&fields=id,name,size'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'multipart/related; boundary=$boundary',
      },
      body: body.takeBytes(),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw DriveException.fromResponse(res.statusCode, res.body);
    }
    final decoded = jsonDecode(res.body);
    final id = decoded is Map ? decoded['id'] : null;
    if (id is! String || id.isEmpty) {
      throw const DriveException(
        DriveFailure.unexpected,
        'Drive nhận file nhưng không trả về mã file',
      );
    }
    return id;
  }

  /// **List/Locate** — các bản sao lưu app này đã tạo, mới nhất trước.
  Future<List<DriveBackupFile>> list({required String accessToken}) async {
    final uri = Uri.parse(_filesUrl).replace(
      queryParameters: {
        'q': "name contains '$backupPrefix' and trashed = false",
        'orderBy': 'createdTime desc',
        'pageSize': '50',
        'fields': 'files(id,name,size,createdTime)',
      },
    );
    final res = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (res.statusCode != 200) {
      throw DriveException.fromResponse(res.statusCode, res.body);
    }
    final decoded = jsonDecode(res.body);
    final files = decoded is Map ? decoded['files'] : null;
    if (files is! List) return const [];
    return [
      for (final f in files)
        if (f is Map && f['id'] is String && f['name'] is String)
          DriveBackupFile(
            id: f['id'] as String,
            name: f['name'] as String,
            sizeBytes: int.tryParse('${f['size']}'),
            createdAt: DateTime.tryParse('${f['createdTime']}'),
          ),
    ];
  }

  /// **Download** — lấy nội dung về để xem trước rồi khôi phục.
  Future<Uint8List> download({
    required String accessToken,
    required String fileId,
  }) async {
    final res = await _client.get(
      Uri.parse('$_filesUrl/$fileId?alt=media'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (res.statusCode != 200) {
      throw DriveException.fromResponse(res.statusCode, res.body);
    }
    return res.bodyBytes;
  }
}

/// Một bản sao lưu nhìn thấy trên Drive.
@immutable
class DriveBackupFile {
  const DriveBackupFile({
    required this.id,
    required this.name,
    this.sizeBytes,
    this.createdAt,
  });

  final String id;
  final String name;

  /// `null` = Drive không trả về, **không phải** "0 byte".
  final int? sizeBytes;
  final DateTime? createdAt;
}

/// Vì sao một thao tác Drive không thành — mã, không phải câu tiếng Việt
/// (ADR-TON-017: chuỗi hiển thị đi qua `AppStrings`).
enum DriveFailure {
  /// 401 — token hết hạn hoặc bị thu hồi. Chỗ gọi nên thử refresh **một** lần.
  unauthorized,

  /// 403 — thiếu scope, hoặc vượt hạn mức.
  forbidden,

  /// 404 — file đã bị xoá khỏi Drive.
  notFound,

  /// 429 / 5xx — thử lại được.
  temporary,

  /// Mạng.
  network,

  unexpected,
}

class DriveException implements Exception {
  const DriveException(this.failure, [this.detail]);

  factory DriveException.fromResponse(int status, String body) =>
      switch (status) {
        401 => DriveException(DriveFailure.unauthorized, _short(body)),
        403 => DriveException(DriveFailure.forbidden, _short(body)),
        404 => DriveException(DriveFailure.notFound, _short(body)),
        429 => DriveException(DriveFailure.temporary, _short(body)),
        >= 500 => DriveException(DriveFailure.temporary, _short(body)),
        _ => DriveException(
          DriveFailure.unexpected,
          'HTTP $status ${_short(body)}',
        ),
      };

  final DriveFailure failure;

  /// Chỉ hiện trên máy người dùng. Telemetry nhận `failure`, không nhận `detail`
  /// — thân phản hồi của Google có thể chứa email tài khoản.
  final String? detail;

  static String _short(String body) =>
      body.length <= 200 ? body : '${body.substring(0, 200)}…';

  @override
  String toString() => 'DriveException(${failure.name})';
}
