import 'package:flutter/foundation.dart';

/// Trạng thái một kết nối tới nền tảng ngoài — **mã canonical** (ADR-TON-018).
enum ConnectionStatus {
  /// **Chưa có credential.** Người bán đã chọn nền tảng nhưng chưa nhập khoá,
  /// hoặc chưa đăng nhập xong.
  ///
  /// Trạng thái này tồn tại vì luật của Founder (WTM-318 §8): *chưa nhập token
  /// ⇒ `SETUP_REQUIRED`, **không fake connected***. Không có nó thì chỗ duy
  /// nhất để đặt một kết nối dở dang là `error` — và `error` nói sai chuyện:
  /// không có gì hỏng cả, chỉ là chưa xong.
  setupRequired('setup_required'),

  /// Đang hoạt động: có credential, lần đồng bộ gần nhất không lỗi.
  active('active'),

  /// Người bán tạm dừng. Khác `error` ở chỗ **có chủ ý** — không nhắc sửa.
  paused('paused'),

  /// Lần đồng bộ gần nhất hỏng (khoá hết hạn, nền tảng đổi API…).
  error('error');

  const ConnectionStatus(this.code);

  final String code;

  /// Mã lạ ⇒ `null`, **không** rơi về `active`.
  ///
  /// Rơi về `active` sẽ khiến một kết nối hỏng trông như đang chạy — người bán
  /// tưởng dữ liệu đang về trong khi nó đã dừng từ lâu. Cùng kỷ luật
  /// `ProvenanceSource.fromCode`.
  static ConnectionStatus? fromCode(String? code) {
    for (final s in ConnectionStatus.values) {
      if (s.code == code) return s;
    }
    return null;
  }
}

/// Con trỏ tới bí mật — **không phải bí mật**.
///
/// ## Vì sao lớp này không có constructor nhận chuỗi
///
/// Luật credential của Founder: *"Không lưu token trong SQLite nghiệp vụ.
/// Mobile credential dùng Keychain/Keystore. Database chỉ giữ credential
/// reference và connection metadata."*
///
/// Một lớp `CredentialReference(String value)` **tuân thủ luật đó trên giấy**
/// và vi phạm nó trong thực tế ngay lần đầu ai đó viết
/// `CredentialReference(token)` — trình biên dịch không phân biệt được một
/// khoá tra và một token, cả hai đều là `String`.
///
/// Nên khoá tra ở đây **được suy ra**, không được truyền vào. Không có đường
/// nào để một bí mật lọt vào kiểu này, kể cả do nhầm.
///
/// Hệ quả kèm theo, và nó tốt: vì suy ra được từ `connectionId`, khoá tra
/// **không cần lưu xuống DB** — nên nó cũng không thể lọt vào `.ttbk`. Backup
/// mang metadata kết nối, không mang đường đi tới bí mật.
@immutable
class CredentialReference {
  const CredentialReference._(this.key);

  /// Khoá tra vào Keychain (iOS) / Keystore (Android) cho một kết nối.
  factory CredentialReference.forConnection(String connectionId) =>
      CredentialReference._('$kCredentialKeyPrefix$connectionId');

  /// Tiền tố dùng chung, để việc quét/dọn khoá không phải đoán.
  static const String kCredentialKeyPrefix = 'tongtai.connection.';

  /// Tên khoá — **không bao giờ là giá trị khoá**.
  final String key;

  @override
  bool operator ==(Object other) =>
      other is CredentialReference && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'CredentialReference($key)';
}

/// Một kết nối tới nền tảng ngoài (WTM-283 · N0.2).
///
/// Kết nối là **một thực thể**, không phải một cột trên bản ghi khác. Không có
/// nó thì `Provenance.connector` (WTM-282) không trỏ được vào đâu — đó là lý
/// do WTM-282 cố ý chưa lưu `connectorId`: một tham chiếu tới thực thể chưa
/// tồn tại là tham chiếu treo, đúng lỗi `integrations_table` đã dạy.
@immutable
class Connection {
  const Connection({
    required this.id,
    required this.connectorId,
    required this.label,
    required this.status,
    required this.createdAt,
    this.lastSyncAt,
  });

  /// Định danh ổn định của kết nối này.
  final String id;

  /// Nền tảng nào — `github` · `revenuecat` · … Mã canonical, khớp
  /// `provenance.connector` trong canonical event envelope.
  final String connectorId;

  /// Tên người bán tự đặt ("Shop chính", "Kho Hà Nội"). Một người có thể nối
  /// **nhiều** tài khoản trên cùng một nền tảng, nên `connectorId` không đủ
  /// làm định danh.
  final String label;

  final ConnectionStatus status;
  final DateTime createdAt;

  /// Lần dữ liệu về gần nhất. `null` = **chưa đồng bộ lần nào**, không phải
  /// "đồng bộ lúc 0" — kỷ luật `null` ≠ `0`.
  final DateTime? lastSyncAt;

  /// Khoá tra credential của kết nối này. **Suy ra, không lưu.**
  ///
  /// Không có trường nào trong DB giữ giá trị này, nên không có gì để rò rỉ
  /// qua `.ttbk`. Việc credential có tồn tại hay không do Keychain/Keystore
  /// trả lời, không do một cột trong cơ sở dữ liệu nghiệp vụ.
  CredentialReference get credential => CredentialReference.forConnection(id);

  Connection copyWith({
    ConnectionStatus? status,
    String? label,
    DateTime? lastSyncAt,
  }) => Connection(
    id: id,
    connectorId: connectorId,
    label: label ?? this.label,
    status: status ?? this.status,
    createdAt: createdAt,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
  );

  @override
  bool operator ==(Object other) => other is Connection && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Connection($id, $connectorId, ${status.code})';
}
