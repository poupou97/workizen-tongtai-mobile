import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/producer/business_input_repository.dart';
import 'package:tongtai/features/tongtai/producer/business_input.dart';

/// WTM-229 / ADR-TON-023 — Producer là **Business Input**, không phải danh bạ
/// nhà cung cấp.
///
/// Dogfood Workizen: đầu vào của một doanh nghiệp AI-first là provider, hạ
/// tầng, công cụ và thời gian — không có nhà cung cấp hàng hoá nào, và cả bốn
/// hôm nay rơi hết vào `FinanceCategory.other`. Không capability nào trả lời
/// được câu cơ bản nhất: *"tháng này tôi cam kết trả bao nhiêu?"*
void main() {
  test('nguồn đầu vào sống sót qua lần đóng app', () async {
    // "Chưa khai" phải sống sót y như một giá trị đã khai: nếu `cadence` hay
    // `expectedAmount` quy về 0 trên đường xuống đĩa thì mở lại app người bán
    // sẽ thấy một cam kết họ chưa từng nói.
    final dir = await Directory.systemTemp.createTemp('tongtai_input');
    final file = File('${dir.path}/t.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    var db = AppDatabase.forExecutor(NativeDatabase(file));
    await DriftBusinessInputRepository(db).upsertAll([
      BusinessInput(
        id: 'grok',
        name: 'xAI / Grok',
        kind: BusinessInputKind.provider,
        cadence: InputCadence.usageBased,
        expectedAmount: 2000000,
      ),
      const BusinessInput(
        id: 'chua-khai',
        name: 'Tên miền',
        kind: BusinessInputKind.infrastructure,
      ),
    ]);
    await db.close();

    db = AppDatabase.forExecutor(NativeDatabase(file));
    final loaded = await DriftBusinessInputRepository(db).loadAll();
    await db.close();

    final grok = loaded.singleWhere((i) => i.id == 'grok');
    final blank = loaded.singleWhere((i) => i.id == 'chua-khai');

    expect(grok.kind, BusinessInputKind.provider);
    expect(grok.cadence, InputCadence.usageBased);
    expect(grok.expectedAmount, 2000000);
    expect(
      blank.cadence,
      isNull,
      reason: '"chưa khai" phải giữ nguyên là null',
    );
    expect(blank.expectedAmount, isNull);
  });

  BusinessInput input({
    String id = 'i1',
    BusinessInputKind kind = BusinessInputKind.provider,
    InputCadence? cadence,
    double? amount,
  }) => BusinessInput(
    id: id,
    name: 'xAI / Grok',
    kind: kind,
    cadence: cadence,
    expectedAmount: amount,
  );

  group('cam kết hằng tháng', () {
    test('tháng và năm quy về cùng một nhịp', () {
      expect(
        input(cadence: InputCadence.monthly, amount: 500000).monthlyCommitment,
        500000,
      );
      expect(
        input(cadence: InputCadence.yearly, amount: 1200000).monthlyCommitment,
        100000,
      );
    });

    test('trả theo mức dùng KHÔNG phải cam kết', () {
      // Token AI có thể bằng 0 vào tháng người bán không dùng gì. Gộp nó vào
      // con số cam kết là bịa một sự chắc chắn không tồn tại.
      expect(
        input(
          cadence: InputCadence.usageBased,
          amount: 2000000,
        ).monthlyCommitment,
        isNull,
      );
      expect(InputCadence.usageBased.isCommitment, isFalse);
      expect(InputCadence.oneOff.isCommitment, isFalse);
    });

    test('thiếu dữ liệu ⇒ null, không phải 0', () {
      // 0 nói "nguồn này không tốn gì"; null nói "chưa đủ dữ liệu để cộng".
      expect(input(cadence: InputCadence.monthly).monthlyCommitment, isNull);
      expect(input(amount: 500000).monthlyCommitment, isNull);
    });
  });

  group('tổng phải tự khai mình còn thiếu gì', () {
    test('đếm riêng những nguồn không góp được vào tổng', () {
      final summary = BusinessInputSummary.from([
        input(id: 'a', cadence: InputCadence.monthly, amount: 500000),
        input(id: 'b', cadence: InputCadence.yearly, amount: 1200000),
        // Theo mức dùng: có tiền nhưng không phải cam kết.
        input(id: 'c', cadence: InputCadence.usageBased, amount: 3000000),
        // Chưa nhập tiền.
        input(id: 'd', cadence: InputCadence.monthly),
      ]);

      expect(summary.total, 4);
      expect(summary.monthlyCommitment, 600000);
      expect(
        summary.unknownCount,
        2,
        reason:
            'một tổng không nói mình còn thiếu gì sẽ được đọc như một tổng '
            'đầy đủ',
      );
      expect(summary.isComplete, isFalse);
    });

    test('đủ dữ liệu thì nói là đủ', () {
      final summary = BusinessInputSummary.from([
        input(id: 'a', cadence: InputCadence.monthly, amount: 100000),
      ]);

      expect(summary.isComplete, isTrue);
      expect(summary.unknownCount, 0);
    });

    test('chưa có nguồn nào: tổng 0 và ĐỦ — không phải "thiếu dữ liệu"', () {
      // Một doanh nghiệp chưa khai nguồn nào thật sự cam kết 0 đồng; nói
      // "thiếu dữ liệu" ở đây là hỏi một câu người bán chưa cần trả lời.
      final summary = BusinessInputSummary.from(const []);
      expect(summary.monthlyCommitment, 0);
      expect(summary.isComplete, isTrue);
    });
  });

  group('vựng từ canonical', () {
    test('mã lạ ⇒ null, không đoán', () {
      expect(BusinessInputKind.fromCode('franchise'), isNull);
      expect(BusinessInputKind.fromCode(null), isNull);
      expect(InputCadence.fromCode('weekly'), isNull);
      expect(
        BusinessInputKind.fromCode('provider'),
        BusinessInputKind.provider,
      );
      expect(InputCadence.fromCode('usage_based'), InputCadence.usageBased);
    });

    test('supplier chỉ là MỘT loại đầu vào', () {
      // Điểm chính của ADR-TON-023: mô hình cũ chỉ biết loại này.
      expect(BusinessInputKind.values, contains(BusinessInputKind.supplier));
      expect(
        BusinessInputKind.values.length,
        greaterThan(1),
        reason: 'Producer không còn là danh bạ nhà cung cấp',
      );
    });
  });
}
