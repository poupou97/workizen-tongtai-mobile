import '../../action/business_action.dart';
import '../../action/business_action_executor.dart';
import '../../agent/business_brief.dart';
import 'telegram_connection.dart';

/// **Tổng Tài nhắn cho chính chủ shop** — WTM-318 (C2 · Epic WTM-315).
///
/// ## Vì sao đây mới là việc Telegram làm được, chứ không phải nhắn khách
///
/// Bot Telegram **không nhắn trước được cho ai** (xem `TelegramClient`). Nên
/// hàng "gửi tin chăm sóc khách" vẫn ở diễn tập, và cái chạy thật là chiều
/// ngược lại: bản tin sáng đi từ Tổng Tài **tới người bán**.
///
/// Và đó không phải giải thưởng an ủi. Nó là thứ biến app từ *"mở ra thì
/// thấy"* thành *"nó tìm mình"* — đúng câu Founder viết ở Epic WTM-302: **"Tổng
/// Tài đang quan sát doanh nghiệp… và làm việc cùng tôi."** Một trợ lý chỉ nói
/// khi được mở ra không phải trợ lý; đó là một cái báo cáo.
///
/// ## Một bản tin một ngày, và luật đó là cấu trúc chứ không phải ý chí
///
/// Khoá chống lặp gộp theo **ngày**. Bấm lại lần thứ hai trong ngày nhận lại
/// đúng tin cũ (`replayed`), không gửi thêm. Nếu để nó gộp theo phút như sao
/// lưu thì một cái vòng lặp lỗi sẽ bắn hàng chục tin — và người bán sẽ chặn
/// bot, mất luôn kênh.
class OwnerNotifier {
  OwnerNotifier({
    required this._executor,
    required this._telegram,
    this._now = DateTime.now,
  });

  final BusinessActionExecutor _executor;
  final TelegramConnection _telegram;
  final DateTime Function() _now;

  /// Tiền tố `externalId` cho một tin **thật** đã tới Telegram.
  static const String externalIdPrefix = 'telegram:';

  /// Effect đăng ký vào `BusinessActionExecutor` cho
  /// [BusinessActionType.ownerNotify].
  static ActionEffect effect(TelegramConnection telegram) =>
      (db, action) async {
        final text = action.parameters['text'] as String?;
        if (text == null || text.trim().isEmpty) {
          throw StateError('không có nội dung để gửi');
        }
        final id = await telegram.send(text);
        return '$externalIdPrefix$id';
      };

  /// Gửi bản tin sáng. Trả `null` khi **không có gì đáng gửi**.
  ///
  /// `null` chứ không phải một tin "hôm nay không có gì": im lặng đúng lúc là
  /// một tính năng. Một trợ lý nhắn mỗi sáng để nói "không có gì" sẽ bị tắt
  /// thông báo trong tuần đầu, và lúc đó những tin **thật sự** quan trọng
  /// cũng chết theo.
  Future<ActionRunResult?> sendMorningBrief(
    List<BriefItem> items, {
    String requestedBy = 'seller',
  }) async {
    if (items.isEmpty) return null;
    // Chưa nối Telegram ⇒ **không** dựng hành động. Người bán chưa bật thông
    // báo thì không có gì để ghi là "đã thử và hỏng"; ghi vào sẽ đổ đầy màn
    // Hoạt động bằng những lần không ai yêu cầu.
    if (!await _telegram.isReady) return null;
    final at = _now();
    final day = _dayKey(at);
    final text = composeMorningBrief(items, at: at);

    final parameters = <String, Object?>{'text': text, 'count': items.length};
    return _run(
      BusinessAction(
        id: 'act-brief-$day',
        // Bản tin nói về **nhiều** việc nên không mượn `correlationId` của
        // việc nào cả — nó có chuỗi riêng, và từng việc vẫn giữ chuỗi của nó.
        correlationId: 'morning-brief:$day',
        type: BusinessActionType.ownerNotify,
        vendor: ActionVendor.telegram,
        subjectKind: 'business',
        subjectId: day,
        subjectLabel: null,
        summary: 'Gửi bản tin sáng qua Telegram',
        parameters: parameters,
        proposedBy: 'system',
        requestedBy: requestedBy,
        idempotencyKey: 'morning-brief:$day',
        requestHash: BusinessActionExecutor.hashRequest(parameters),
        status: ActionStatus.planned,
        plannedAt: at,
      ),
      requestedBy,
    );
  }

  /// Tin thử lúc thiết lập — để người bán **nhìn thấy** nó tới nơi.
  ///
  /// Đi qua cùng một cửa ghi như mọi hành động khác, nên nếu nó tới được thì
  /// bản tin sáng cũng sẽ tới: không có đường nào "chỉ đúng cho tin thử".
  Future<ActionRunResult> sendTest({String requestedBy = 'seller'}) async {
    final at = _now();
    final stamp = '${_dayKey(at)}-${at.hour}${at.minute}';
    const text = 'Tổng Tài đã kết nối. Từ giờ bản tin sáng sẽ tới đây.';
    final parameters = <String, Object?>{'text': text};

    final result = await _run(
      BusinessAction(
        id: 'act-tg-test-$stamp',
        correlationId: 'telegram-test:$stamp',
        type: BusinessActionType.ownerNotify,
        vendor: ActionVendor.telegram,
        subjectKind: 'business',
        subjectId: stamp,
        subjectLabel: null,
        summary: 'Gửi tin thử qua Telegram',
        parameters: parameters,
        proposedBy: 'system',
        requestedBy: requestedBy,
        idempotencyKey: 'telegram-test:$stamp',
        requestHash: BusinessActionExecutor.hashRequest(parameters),
        status: ActionStatus.planned,
        plannedAt: at,
      ),
      requestedBy,
    );
    return result!;
  }

  Future<ActionRunResult?> _run(
    BusinessAction action,
    String requestedBy,
  ) async {
    final planned = await _executor.plan(action);
    // Đã chạy rồi thì không duyệt lại — xem `DriveBackupCoordinator.backupNow`.
    if (planned.status == ActionStatus.planned) {
      final refused = await _executor.approve(
        planned.id,
        requestedBy: requestedBy,
      );
      if (refused != null) return refused;
    }
    return _executor.run(planned.id);
  }

  static String _dayKey(DateTime at) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${at.year}${two(at.month)}${two(at.day)}';
  }

  /// Tin này có thật sự tới Telegram không.
  static bool isRealTelegramResult(String? externalId) =>
      externalId != null && externalId.startsWith(externalIdPrefix);
}

/// Dựng nội dung bản tin sáng từ các việc Rule Twin tìm ra.
///
/// ## Không có mã, không có tên bảng, không có id
///
/// Người bán đọc tin này lúc 7 giờ sáng trên điện thoại, giữa lúc mở cửa hàng.
/// Mỗi dòng phải là một câu tiếng Việt về việc kinh doanh của họ — cùng luật
/// với màn Hoạt động (WTM-305).
///
/// ## Cắt ở năm việc
///
/// Rule Twin có thể tìm ra ba mươi việc trong một buổi sáng dữ liệu xấu. Một
/// tin nhắn ba mươi dòng không được đọc; nó được vuốt qua. Năm việc nặng nhất
/// cộng một dòng "còn N việc nữa" nói đúng sự thật mà vẫn đọc hết được.
String composeMorningBrief(List<BriefItem> items, {required DateTime at}) {
  final sorted = [...items]
    ..sort((a, b) => b.severity.index.compareTo(a.severity.index));
  final shown = sorted.take(5).toList();
  final rest = sorted.length - shown.length;

  final buffer = StringBuffer()
    ..writeln('Tổng Tài · bản tin sáng ${at.day}/${at.month}')
    ..writeln();
  for (final item in shown) {
    buffer
      ..writeln('• ${item.headline}')
      ..writeln('  → ${item.suggestion}');
  }
  if (rest > 0) {
    buffer
      ..writeln()
      ..writeln('Còn $rest việc nữa trong app.');
  }
  return buffer.toString().trimRight();
}
