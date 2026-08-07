import 'package:drift/drift.dart';

import 'businesses.dart';

/// Lịch sử liên kết danh tính — **chỉ ghi thêm, không bao giờ sửa hay xoá**
/// (WTM-291 · ADR-TON-024).
///
/// ## Vì sao một bảng riêng, không phải cột `updatedAt` trên bản ghi
///
/// Câu hỏi thật của người bán không phải *"liên kết này đổi lần cuối lúc
/// nào"* mà *"vì sao khách này lại có đơn từ TikTok?"*. Cột `updatedAt` trả
/// lời câu đầu và **xoá mất** câu sau: mỗi lần ghi đè là một lần mất bằng
/// chứng.
///
/// Và [actor] là thứ làm cho tự động hoá **hoàn tác được**: khi một luật khớp
/// hoá ra sai, `actor = 'rule:<tên>'` tìm được **tất cả** thứ nó đã gắn, gỡ
/// hàng loạt, không đụng vào thứ người bán tự gắn tay. Không có cột này thì
/// một luật sai chỉ còn cách sửa từng dòng — mà người bán thì không biết dòng
/// nào là do luật.
///
/// **Không** khoá ngoại tới `external_identities_table`: gỡ liên kết là xoá
/// dòng danh tính, và lịch sử *phải sống sót qua chính việc nó ghi lại*. Một
/// FK cascade ở đây sẽ xoá đúng bằng chứng cần giữ.
@TableIndex(name: 'identity_link_events_business_id', columns: {#businessId})
@TableIndex(name: 'identity_link_events_identity_id', columns: {#identityId})
@TableIndex(name: 'identity_link_events_actor', columns: {#actor})
class IdentityLinkEventsTable extends Table {
  TextColumn get id => text()();

  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get identityId => text()();

  /// Mã canonical `IdentityLinkAction` — `linked` · `unlinked` · `moved`.
  TextColumn get action => text()();

  DateTimeColumn get at => dateTime()();

  /// `seller` hoặc `rule:<tên luật>`. Xem doc của lớp.
  TextColumn get actor => text()();

  /// Trạng thái **trước**. `null` ở `linked` — không phải "khách rỗng".
  TextColumn get fromCustomerId => text().nullable()();

  /// Trạng thái **sau**. `null` ở `unlinked`.
  TextColumn get toCustomerId => text().nullable()();

  /// Mức tin cậy lúc quyết định — để về sau soi lại *luật nào đã tin quá mức*.
  TextColumn get confidence => text().nullable()();

  @override
  Set<Column> get primaryKey => {businessId, id};
}
