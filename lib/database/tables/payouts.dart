import 'package:drift/drift.dart';

import 'businesses.dart';

/// Một lô tiền thực về tài khoản người bán (WTM-292 · N0.4).
///
/// ## `reconciled_delta` nullable là một quyết định, không phải tiện tay
///
/// `null` = **chưa đối soát**. `0` = **đã đối soát và khớp**. Hai điều đó khác
/// nhau, và gộp chúng bằng một `DEFAULT 0` là cách một lô chưa ai kiểm trông
/// như đã kiểm xong — cùng họ với `null` ≠ `0` đã áp cho `total_stock` ở v14.
///
/// Lệch thì **hiện ra cho người bán**, không san bằng, không giấu vào "khác".
/// Sàn thường có khoản chưa giải thích được; một hệ thống ép cho khớp bằng
/// cách bịa một dòng "điều chỉnh" là hệ thống nói dối.
@TableIndex(name: 'payouts_business_id', columns: {#businessId})
@TableIndex(name: 'payouts_connection_id', columns: {#connectionId})
class PayoutsTable extends Table {
  TextColumn get id => text()();

  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();

  /// Kết nối nào trả lô này (WTM-283). Không khoá ngoại: gỡ kết nối không được
  /// xoá lịch sử tiền đã về.
  TextColumn get connectionId => text()();

  /// Số sàn báo đã trả. **Luôn dương.**
  RealColumn get amount => real()();

  TextColumn get currency => text()();

  DateTimeColumn get settledAt => dateTime()();

  /// Chênh lệch **chưa giải thích được**, có dấu. `null` = chưa đối soát.
  RealColumn get reconciledDelta => real().nullable()();

  TextColumn get provenanceCode => text().nullable()();

  @override
  Set<Column> get primaryKey => {businessId, id};
}
