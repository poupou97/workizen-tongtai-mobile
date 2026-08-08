import 'package:drift/drift.dart';

import '../../../database/database.dart';
import 'business_action.dart';
import 'business_action_executor.dart';

/// Tiền tố của mọi mã kết quả **chưa ra khỏi máy này**.
///
/// Nó nằm trong `externalId` — trường mà mọi màn hình đọc để nói *"đã chạy
/// xong, kết quả là gì"*. Nên một hành động diễn tập **không thể** hiện ra như
/// một hành động thật: chỗ hiển thị kết quả và chỗ khai nó là demo là **cùng
/// một trường**, không phải hai.
///
/// Cùng kỷ luật với `ActionVendor.demo`: một cờ `isDemo` riêng thì có đường
/// quên; một tiền tố trong chính kết quả thì không.
const String kDemoExecutionPrefix = 'demo:';

/// Hành động này có thật sự chạm ra ngoài không.
bool isDemoResult(String? externalId) =>
    externalId != null && externalId.startsWith(kDemoExecutionPrefix);

/// Bộ thực thi hôm nay — WTM-303 (Founder Task Order §7).
///
/// ## Diễn tập thật, không phải bỏ qua
///
/// Chưa connector nào chạy thật. Nhưng mọi hành động vẫn đi **trọn** vòng đời
/// `plan → approve → run`, trong một transaction, có lease và chống lặp. Chỉ
/// bước cuối — gửi ra ngoài — là chưa xảy ra, và nó **khai điều đó ra** bằng
/// `externalId` mang tiền tố [kDemoExecutionPrefix].
///
/// Cách khác — thêm một nhánh `if (demo) return;` trước `run` — sẽ để đường
/// chạy thật thành đường **chưa ai từng chạy**, và nó sẽ hỏng đúng vào ngày
/// đầu tiên có người dùng thật.
///
/// ## Một ngoại lệ: `applyProposedChange` chạy THẬT
///
/// Áp dụng một đề xuất là ghi vào cơ sở dữ liệu của chính Tổng Tài — không có
/// nền tảng ngoài nào tham gia, nên không có gì để giả lập. Nó là chỗ duy nhất
/// ở đây thay đổi dữ liệu nghiệp vụ, và nó làm điều đó **qua cửa**
/// (`vendor: internal`), đúng chỗ COMP AI hụt.
final Map<BusinessActionType, ActionEffect> demoActionHandlers = {
  BusinessActionType.applyProposedChange: _applyProposedChange,
  BusinessActionType.customerSendMessage: _demo('message'),
  BusinessActionType.inventoryCreatePurchaseOrder: _demo('purchase-order'),
};

/// Ghi giá trị đã duyệt vào bản ghi nghiệp vụ.
///
/// Từ vựng đóng: trường không nhận ra ⇒ **ném**, không im lặng bỏ qua. Một
/// hành động báo `succeeded` mà không đổi gì là lời nói dối tệ nhất mà lớp này
/// có thể kể.
Future<String> _applyProposedChange(
  AppDatabase db,
  BusinessAction action,
) async {
  final field = action.parameters['field'] as String?;
  final value = action.parameters['value'] as String?;
  if (field == null || value == null) {
    throw StateError('thiếu `field`/`value` — không biết phải ghi gì');
  }

  switch ((action.subjectKind, field)) {
    case ('product', 'pricePerUnit'):
      final price = double.tryParse(value);
      if (price == null) {
        throw StateError('giá không phải một con số: "$value"');
      }
      final changed =
          await (db.update(
            db.productsTable,
          )..where((t) => t.id.equals(action.subjectId))).write(
            ProductsTableCompanion(
              listPrice: Value(price),
              updatedAt: Value(DateTime.now()),
            ),
          );
      if (changed == 0) {
        throw StateError('không tìm thấy sản phẩm "${action.subjectId}"');
      }
      return 'product:${action.subjectId}:$field';

    case ('product', 'costPrice'):
      final cost = double.tryParse(value);
      if (cost == null) throw StateError('chi phí không phải số: "$value"');
      final changed =
          await (db.update(
            db.productsTable,
          )..where((t) => t.id.equals(action.subjectId))).write(
            ProductsTableCompanion(
              costPerUnit: Value(cost),
              updatedAt: Value(DateTime.now()),
            ),
          );
      if (changed == 0) {
        throw StateError('không tìm thấy sản phẩm "${action.subjectId}"');
      }
      return 'product:${action.subjectId}:$field';

    default:
      throw StateError(
        'chưa biết cách ghi "${action.subjectKind}.$field". Thêm nhánh ở đây '
        'thay vì ghi thẳng ở chỗ khác — đó là cả điểm của cửa ghi duy nhất.',
      );
  }
}

/// Diễn tập: không gửi đi đâu, và **nói ra điều đó**.
ActionEffect _demo(String what) =>
    (db, action) async => '$kDemoExecutionPrefix$what:${action.subjectId}';
