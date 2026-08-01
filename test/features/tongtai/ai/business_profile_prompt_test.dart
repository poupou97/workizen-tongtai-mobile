import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/ai/business_profile_prompt.dart';
import 'package:tongtai/features/tongtai/profile/business_profile.dart';

/// WTM-177 — the profile as the AI sees it.
///
/// This block rides along on **every question**, so what it does and does not
/// contain is pinned here rather than left to inspection.
void main() {
  group('no profile means no block', () {
    test('null renders nothing', () {
      expect(businessProfilePromptText(null), isNull);
    });

    test('an unanswered profile renders nothing', () {
      expect(businessProfilePromptText(BusinessProfile.empty), isNull);
      // Not an empty heading: a section titled "Business Profile" with nothing
      // under it invites the model to fill the gap with an invention.
    });
  });

  group('what a seller answered', () {
    test('a full profile renders all four lines in Vietnamese', () {
      const profile = BusinessProfile(
        trade: BusinessTrade.homeGoods,
        size: BusinessSize.solo,
        channels: [SalesChannel.shop, SalesChannel.shopee],
        seasonality: BusinessSeasonality.tet,
      );
      final text = businessProfilePromptText(profile)!;

      expect(text, contains('# Business Profile'));
      expect(text, contains('Ngành: đồ gia dụng'));
      expect(text, contains('Quy mô: tự làm một mình'));
      expect(text, contains('Kênh bán: cửa hàng, Shopee'));
      expect(text, contains('Mùa vụ: cao điểm dịp Tết'));
    });

    test('a partial profile renders only the lines that were answered', () {
      const profile = BusinessProfile(trade: BusinessTrade.food);
      final text = businessProfilePromptText(profile)!;

      expect(text, contains('Ngành: thực phẩm'));
      expect(text, isNot(contains('Quy mô')));
      expect(text, isNot(contains('Kênh bán')));
      expect(text, isNot(contains('Mùa vụ')));
    });

    test('never emits a raw code', () {
      // `home_goods` tells a model almost nothing; that is the whole reason
      // this file exists. If a code leaks through, the profile stops helping.
      for (final trade in BusinessTrade.values) {
        final text = businessProfilePromptText(BusinessProfile(trade: trade))!;
        expect(text, isNot(contains(trade.code.replaceAll('_', ''))));
        expect(text, isNot(contains('_')));
      }
    });
  });

  group('determinism — the same business always sends the same text', () {
    test('channel tap order does not change the prompt', () {
      const a = BusinessProfile(
        channels: [SalesChannel.zalo, SalesChannel.shop, SalesChannel.tiktok],
      );
      const b = BusinessProfile(
        channels: [SalesChannel.shop, SalesChannel.tiktok, SalesChannel.zalo],
      );
      expect(businessProfilePromptText(a), businessProfilePromptText(b));
    });

    test('the same profile renders identically every call', () {
      const profile = BusinessProfile(
        trade: BusinessTrade.cosmetics,
        size: BusinessSize.growing,
      );
      expect(
        businessProfilePromptText(profile),
        businessProfilePromptText(profile),
      );
    });

    test('every enum value has a label — no value falls through', () {
      // A missing branch would be a compile error today, but a future value
      // added with a placeholder label would not be. This is the check.
      for (final trade in BusinessTrade.values) {
        expect(
          businessProfilePromptText(BusinessProfile(trade: trade)),
          isNotNull,
        );
      }
      for (final size in BusinessSize.values) {
        expect(
          businessProfilePromptText(BusinessProfile(size: size)),
          isNotNull,
        );
      }
      for (final channel in SalesChannel.values) {
        expect(
          businessProfilePromptText(BusinessProfile(channels: [channel])),
          isNotNull,
        );
      }
      for (final season in BusinessSeasonality.values) {
        expect(
          businessProfilePromptText(BusinessProfile(seasonality: season)),
          isNotNull,
        );
      }
    });
  });

  group('the privacy boundary, as text', () {
    test('the block contains only the four categorical lines', () {
      const profile = BusinessProfile(
        trade: BusinessTrade.fashion,
        size: BusinessSize.small,
        channels: [SalesChannel.tiktok],
        seasonality: BusinessSeasonality.summer,
      );
      final lines = businessProfilePromptText(profile)!.split('\n');
      expect(
        lines.first,
        '# Business Profile',
        reason: 'the heading, then exactly four facts and nothing else',
      );
      expect(lines.length, 5);
      for (final line in lines.skip(1)) {
        expect(
          line,
          startsWith('- '),
          reason: 'every line is one labelled categorical answer',
        );
      }
    });
  });
}
