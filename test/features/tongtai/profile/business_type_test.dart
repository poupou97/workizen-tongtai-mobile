import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/ai/business_profile_prompt.dart';
import 'package:tongtai/features/tongtai/profile/business_profile.dart';

/// WTM-228 / ADR-TON-023 — hồ sơ nói được doanh nghiệp vận hành kiểu gì.
///
/// `BusinessTrade` là *ngành hàng*; cái thiếu là *loại hình*. Một xưởng may và
/// một studio phần mềm đều có thể chọn ngành "khác", trong khi mô hình vận
/// hành của họ không có điểm chung nào — và AI đang khuyên cả hai như nhau.
void main() {
  group('type và trade là hai chiều khác nhau', () {
    test('cùng một ngành, hai loại hình', () {
      const shop = BusinessProfile(
        type: BusinessType.physical,
        trade: BusinessTrade.other,
      );
      const studio = BusinessProfile(
        type: BusinessType.digital,
        trade: BusinessTrade.other,
      );

      expect(shop.trade, studio.trade);
      expect(
        shop.type,
        isNot(studio.type),
        reason: 'gộp hai chiều lại là mất đúng thông tin AI cần nhất',
      );
    });
  });

  group('chưa khai ≠ hàng vật lý', () {
    test('mã vắng mặt hoặc lạ đọc ra null', () {
      // Cố ý KHÁC `ProductKind.fromCode`, nơi mã vắng mặt đọc ra `physical`:
      // ở đó mọi dòng cũ THẬT SỰ là hàng vật lý vì mô hình trước chỉ có một
      // loại. Ở đây người bán chưa từng được hỏi, nên trả lời hộ họ là bịa.
      expect(BusinessType.fromCode(null), isNull);
      expect(BusinessType.fromCode('franchise'), isNull);
      expect(BusinessType.fromCode('hybrid'), BusinessType.hybrid);
    });

    test('hồ sơ chỉ có mỗi loại hình vẫn là hồ sơ có dữ liệu', () {
      const profile = BusinessProfile(type: BusinessType.service);
      expect(profile.isEmpty, isFalse);
      expect(BusinessProfile.empty.isEmpty, isTrue);
    });
  });

  group('.ttbk giữ được loại hình', () {
    test('mã canonical đi và về nguyên vẹn', () {
      const profile = BusinessProfile(
        type: BusinessType.hybrid,
        trade: BusinessTrade.food,
      );

      final restored = BusinessProfile.fromJson(profile.toJson());

      expect(restored.type, BusinessType.hybrid);
      expect(profile.toJson()['type'], 'hybrid', reason: 'mã, không phải nhãn');
    });

    test('file cũ không có khoá này restore thành "chưa khai"', () {
      final json = const BusinessProfile(
        type: BusinessType.digital,
        trade: BusinessTrade.food,
      ).toJson()..remove('type');

      final restored = BusinessProfile.fromJson(json);

      expect(restored.type, isNull);
      expect(restored.trade, BusinessTrade.food, reason: 'phần còn lại nguyên');
    });
  });

  group('AI thấy loại hình trước ngành hàng', () {
    test('loại hình đứng đầu khối prompt', () {
      final text = businessProfilePromptText(
        const BusinessProfile(
          type: BusinessType.digital,
          trade: BusinessTrade.other,
        ),
      )!;

      // Loại hình quyết định lời khuyên nào còn nghĩa: gợi ý "nhập thêm hàng"
      // cho một studio phần mềm là vô nghĩa dù ngành có đúng đến đâu.
      expect(text.indexOf('Loại hình'), lessThan(text.indexOf('Ngành')));
      expect(text, contains('không có tồn kho'));
    });

    test('chưa khai thì prompt không nhắc tới — không đoán hộ', () {
      final text = businessProfilePromptText(
        const BusinessProfile(trade: BusinessTrade.fashion),
      )!;

      expect(text, isNot(contains('Loại hình')));
    });
  });
}
