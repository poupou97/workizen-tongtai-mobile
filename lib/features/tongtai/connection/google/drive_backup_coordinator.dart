import 'dart:convert';
import 'dart:typed_data';

import '../../action/business_action.dart';
import '../../action/business_action_executor.dart';
import '../../export/backup_service.dart';
import 'drive_backup_service.dart';
import 'google_connection.dart';

/// Sao lưu lên Drive **đi qua cửa ghi duy nhất** — WTM-317.
///
/// ## Vì sao một việc "chỉ là upload" lại phải là `BusinessAction`
///
/// Founder §15 đặt điều kiện: *"Tất cả action ra ngoài đều đi qua
/// BusinessAction."* Cụ thể ở đây nó mua được ba thứ, và cả ba đều là thứ một
/// lời gọi `drive.upload()` trần không có:
///
/// - **Chống lặp.** Bấm hai lần trong một phút ⇒ một file, không phải hai.
/// - **Nhìn thấy được.** Bản sao lưu hiện ở màn Hoạt động cạnh mọi việc khác
///   agent làm — không phải một thứ xảy ra ở góc nào đó.
/// - **Đường chạy thật.** `plan → approve → run` là đường đã chạy hàng nghìn
///   lần trong test từ WTM-297. Đây là hành động **đầu tiên** đi hết đường đó
///   ra tới một nền tảng thật.
///
/// ## `externalId` không có tiền tố `demo:` — và đó là điểm
///
/// Mọi hành động cho tới hôm nay trả về `demo:…` (WTM-303). Đây là cái đầu
/// tiên trả về `drive:<fileId>` — một mã **tra được**: mở Drive ra sẽ thấy
/// đúng file đó. Sự khác biệt giữa diễn tập và thật nằm ở chính trường hiển
/// thị, không ở một cờ bên cạnh.
///
/// ## Xuất và tải nằm trong CÙNG transaction
///
/// `BusinessActionExecutor` chạy effect bên trong một transaction, nên `.ttbk`
/// được dựng và đẩy đi trong khi không ghi nào khác chen vào. Cái giá là các
/// ghi khác phải chờ hết lượt tải; đổi lại, **file trên Drive khớp đúng trạng
/// thái cơ sở dữ liệu tại thời điểm tải** thay vì khớp một trạng thái đã trôi
/// mất giữa lúc xuất và lúc gửi.
class DriveBackupCoordinator {
  DriveBackupCoordinator({
    required this._executor,
    required this._connection,
    required this._drive,
    this._now = DateTime.now,
  });

  final BusinessActionExecutor _executor;
  final GoogleConnection _connection;
  final DriveBackupService _drive;
  final DateTime Function() _now;

  /// Tiền tố `externalId` cho một file **thật** trên Drive.
  static const String externalIdPrefix = 'drive:';

  /// Effect đăng ký vào `BusinessActionExecutor` cho
  /// [BusinessActionType.storageBackupUpload].
  ///
  /// Tách khỏi [backupNow] để bộ handler dựng được mà không cần coordinator —
  /// đó là điều kiện để provider không vòng tròn.
  static ActionEffect effect({
    required GoogleConnection connection,
    required DriveBackupService drive,
    required TongtaiBackupService backup,
  }) => (db, action) async {
    var token = await connection.accessToken();
    if (token == null) {
      throw StateError(
        'chưa kết nối Google — không có token để tải bản sao lưu lên',
      );
    }

    final armored = await backup.createBackup();
    final bytes = Uint8List.fromList(utf8.encode(armored));
    final fileName = action.parameters['fileName'] as String?;

    try {
      final id = await drive.upload(
        accessToken: token,
        bytes: bytes,
        fileName: fileName,
      );
      return '$externalIdPrefix$id';
    } on DriveException catch (e) {
      // 401 dù token còn hạn ⇒ quyền bị thu hồi phía Google. Thử lại **một**
      // lần với token mới; vẫn hỏng thì đó là mất quyền thật, và ném ra để
      // hành động chuyển `failed` — thử lại được, không mất dấu.
      if (e.failure != DriveFailure.unauthorized) rethrow;
      token = await connection.accessToken(force: true);
      if (token == null) {
        throw StateError('Google từ chối và không làm mới được quyền');
      }
      final id = await drive.upload(
        accessToken: token,
        bytes: bytes,
        fileName: fileName,
      );
      return '$externalIdPrefix$id';
    }
  };

  /// **Sao lưu ngay** — dựng hành động, duyệt, chạy.
  ///
  /// Khoá chống lặp gộp theo **phút**: bấm hai lần liền nhau là một tai nạn
  /// ngón tay, không phải hai ý định. Sang phút sau thì đúng là hai ý định, và
  /// hai file là đúng.
  Future<ActionRunResult> backupNow({String requestedBy = 'seller'}) async {
    final at = _now();
    final minute = DriveBackupService.backupKeyFor(at);
    final fileName = DriveBackupService.fileNameFor(at);

    final parameters = <String, Object?>{'fileName': fileName};
    final action = BusinessAction(
      id: 'act-drive-$minute',
      correlationId: 'backup:$minute',
      type: BusinessActionType.storageBackupUpload,
      vendor: ActionVendor.google,
      subjectKind: 'backup',
      subjectId: minute,
      subjectLabel: fileName,
      summary: 'Sao lưu toàn bộ dữ liệu lên Google Drive',
      parameters: parameters,
      proposedBy: 'system',
      requestedBy: requestedBy,
      idempotencyKey: 'drive-backup:$minute',
      requestHash: BusinessActionExecutor.hashRequest(parameters),
      status: ActionStatus.planned,
      plannedAt: at,
    );

    final planned = await _executor.plan(action);
    // Lần bấm thứ hai trong cùng một phút nhận lại **đúng** hành động cũ, và
    // nó không còn ở `planned`. Duyệt lại sẽ bị từ chối `not_approved` — đúng
    // luật nhưng sai câu chuyện: người bán sẽ thấy "chưa được duyệt" cho một
    // việc đã xong. Nên bỏ qua bước duyệt và để `run` trả `replayed`.
    if (planned.status == ActionStatus.planned) {
      final refused = await _executor.approve(
        planned.id,
        requestedBy: requestedBy,
      );
      if (refused != null) return refused;
    }
    return _executor.run(planned.id);
  }

  /// Các bản sao lưu đang nằm trên Drive.
  ///
  /// Đọc, nên **không** đi qua `BusinessAction`: cửa ghi duy nhất là cửa của
  /// *ghi*. Bắt mọi lần đọc đi qua đó sẽ sinh ra một dòng lịch sử cho mỗi lần
  /// mở màn hình, và lịch sử đầy tiếng ồn là lịch sử không ai đọc.
  Future<List<DriveBackupFile>> list() async {
    final token = await _connection.accessToken();
    if (token == null) return const [];
    try {
      return await _drive.list(accessToken: token);
    } on DriveException catch (e) {
      if (e.failure != DriveFailure.unauthorized) rethrow;
      final fresh = await _connection.accessToken(force: true);
      if (fresh == null) return const [];
      return _drive.list(accessToken: fresh);
    }
  }

  /// Tải một bản về để **xem trước rồi khôi phục** (ADR-TON-018).
  ///
  /// Trả về nội dung armored — chính thứ `TongtaiBackupService.validate` nhận.
  /// Đường khôi phục **không đổi**: Drive chỉ thay chỗ lấy file, không thay
  /// luật "Restore = Replace, có bản an toàn verify được mới xoá".
  Future<String> download(String fileId) async {
    final token = await _connection.accessToken();
    if (token == null) {
      throw StateError('chưa kết nối Google — không tải bản sao lưu về được');
    }
    final bytes = await _drive.download(accessToken: token, fileId: fileId);
    return utf8.decode(bytes);
  }

  /// Bản sao lưu này có thật sự nằm trên Drive không.
  static bool isRealDriveResult(String? externalId) =>
      externalId != null && externalId.startsWith(externalIdPrefix);
}
