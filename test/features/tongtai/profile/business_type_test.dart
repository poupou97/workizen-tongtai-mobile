import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/l10n/app_strings.dart';
import 'package:tongtai/features/tongtai/ai/business_profile_prompt.dart';
import 'package:tongtai/features/tongtai/onboarding/onboarding_conversation.dart';
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

  group('kênh bán cho doanh nghiệp số (WTM-232)', () {
    test('có kênh thật để ghi, không còn "chưa ghi" vô cớ', () {
      // Trước đây bảy kênh đều là bán lẻ vật lý, nên một doanh nghiệp số
      // KHÔNG CÓ Ô NÀO ĐÚNG: mọi đơn thành null và "Doanh thu theo kênh"
      // trống vĩnh viễn — không phải vì người bán lười ghi.
      expect(SalesChannel.fromCode('website'), SalesChannel.website);
      expect(SalesChannel.fromCode('app_store'), SalesChannel.appStore);
      expect(SalesChannel.fromCode('direct'), SalesChannel.direct);
    });

    test('mã cũ KHÔNG đổi — đơn đã ghi không được mất kênh', () {
      // Đổi một mã sẽ làm mọi đơn đã ghi mất kênh khi khôi phục (ADR-TON-018).
      for (final pair in const [
        ('shop', SalesChannel.shop),
        ('market', SalesChannel.market),
        ('shopee', SalesChannel.shopee),
        ('tiktok', SalesChannel.tiktok),
        ('facebook', SalesChannel.facebook),
        ('zalo', SalesChannel.zalo),
        ('wholesale', SalesChannel.wholesale),
      ]) {
        expect(SalesChannel.fromCode(pair.$1), pair.$2);
      }
    });

    test('mã lạ vẫn là "chưa ghi", không mượn tên kênh có thật', () {
      // Nhánh mặc định cũ (`_ => 'Bán sỉ'`) làm MỌI mã mới hiện thành "Bán sỉ"
      // — một nhãn sai mà không gì báo.
      expect(SalesChannel.fromCode('temu'), isNull);
      expect(AppStringsVi().profileChannel('temu'), 'Kênh khác');
      expect(AppStringsVi().profileChannel('wholesale'), 'Bán sỉ');
      expect(AppStringsVi().profileChannel('website'), 'Website của mình');
    });

    test('⭐ WTM-442 · MỌI kênh có nhãn thật, cả hai locale', () {
      // `profileChannel` nhận `String`, không nhận enum — nên trình biên dịch
      // KHÔNG chặn được việc thêm một kênh mà quên nhãn. Kênh ấy sẽ lặng lẽ
      // hiện "Kênh khác": trung thực về việc app không biết, nhưng sai, vì
      // app biết rõ. Test này thay chỗ cho cái gate mà kiểu dữ liệu không cho.
      for (final channel in SalesChannel.values) {
        expect(
          AppStringsVi().profileChannel(channel.code),
          isNot('Kênh khác'),
          reason: 'Thiếu nhãn VI cho kênh "${channel.code}".',
        );
        expect(
          AppStringsEn().profileChannel(channel.code),
          isNot('Other channel'),
          reason: 'Thiếu nhãn EN cho kênh "${channel.code}".',
        );
      }
    });

    test('onboarding mời ĐỦ mọi kênh mô hình giữ được', () {
      // Danh sách chép tay trong kịch bản vừa để sót ba kênh mới; nay suy
      // thẳng từ enum nên không thể lệch lần nữa.
      final step = kOnboardingSteps.firstWhere((s) => s.id == 'channels');
      expect(
        step.optionCodes.toSet(),
        SalesChannel.values.map((c) => c.code).toSet(),
      );
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
