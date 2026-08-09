import 'package:drift/drift.dart';

import 'businesses.dart';

/// Một lần nhập dữ liệu từ nguồn ngoài — WTM-327 (§14 provenance).
///
/// ## Vì sao một lần nhập phải là một BẢN GHI
///
/// Founder §14 đòi mỗi bản ghi nhập vào mang `importJobId`. Điều đó chỉ có
/// nghĩa nếu `importJobId` **trỏ tới một cái gì đó** — nếu không nó chỉ là một
/// chuỗi trang trí.
///
/// Có bảng này thì ba câu hỏi trả lời được, và cả ba đều là câu người bán sẽ
/// hỏi:
///
/// 1. *"Mấy con số này ở đâu ra?"* → tên file, lúc nào, từ đâu.
/// 2. *"Nhập nhầm file rồi, bỏ đi được không?"* → xoá theo `importJobId`, đúng
///    phạm vi, không đụng dữ liệu tự nhập (§22).
/// 3. *"Nhập lại có bị nhân đôi không?"* → cùng file, cùng checksum ⇒ nhận ra.
///
/// ## Không có cột `status = success`
///
/// Một lần nhập hoặc đã ghi xong (có bản ghi trỏ tới), hoặc đã bị cuộn lại
/// (không còn bản ghi nào). Thêm một cột trạng thái là thêm một chỗ để nói dối
/// khi transaction hỏng giữa chừng — cùng bài học `BusinessAction` (WTM-300).
@TableIndex(name: 'import_jobs_business_id', columns: {#businessId})
@TableIndex(name: 'import_jobs_checksum', columns: {#sourceChecksum})
class ImportJobsTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId =>
      text().references(BusinessesTable, #id, onDelete: KeyAction.cascade)();

  /// `file_bridge` hôm nay; `connector` khi có vendor API. Mã canonical
  /// `ProvenanceSource` — **một từ vựng, không hai**.
  TextColumn get sourceCode => text()();

  /// Nền tảng cụ thể: `google_drive` · `local_file` · sau này `shopify`…
  TextColumn get sourceVendor => text().nullable()();

  /// Tên file người bán nhìn thấy. Đây là câu trả lời cho *"số này ở đâu ra"*,
  /// nên nó là tên thật chứ không phải đường dẫn kỹ thuật.
  TextColumn get sourceFile => text().nullable()();

  /// Tài khoản nguồn nếu có (email Drive). **Không** phải credential.
  TextColumn get sourceAccount => text().nullable()();

  /// SHA-256 nội dung file. Cùng file nhập hai lần thì nhận ra được —
  /// chống nhân đôi bằng **nội dung**, không bằng tên file (tên đổi được).
  TextColumn get sourceChecksum => text().nullable()();

  /// Số bản ghi đã ghi, theo loại — JSON `{"products": 100, "orders": 96}`.
  ///
  /// Nằm **trong** bản ghi chứ không tính lại lúc đọc: đếm lại sau khi người
  /// bán đã sửa vài dòng sẽ ra một con số khác, và con số đó không còn mô tả
  /// lần nhập nữa.
  TextColumn get recordCounts => text().nullable()();

  /// Cảnh báo đã hiện cho người bán lúc nhập — JSON. Giữ lại để sau này còn
  /// giải thích được vì sao một sản phẩm thiếu giá vốn.
  TextColumn get warnings => text().nullable()();

  /// ⭐ Dữ liệu demo hay dữ liệu thật của người bán.
  ///
  /// §14: *"Demo rows phải có `isDemo = true`… Không trình bày chúng như dữ
  /// liệu vendor synced thật."* Cờ nằm ở **lần nhập**, không ở từng dòng: một
  /// file demo không thể có vài dòng thật, và ngược lại.
  BoolColumn get isDemo => boolean().withDefault(const Constant(false))();

  DateTimeColumn get importedAt =>
      dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}
