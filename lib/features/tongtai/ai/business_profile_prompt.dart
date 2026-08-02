/// Renders the [BusinessProfile] as the prompt block the AI is allowed to see
/// (WTM-177).
///
/// ## Why the labels live here and not on the model
/// The model stores **canonical codes** so a record never changes meaning when
/// the seller switches language (ADR-TON-018). But `home_goods` tells an AI
/// almost nothing, while *"đồ gia dụng"* tells it what to talk about. So the
/// code→words mapping is **presentation**, and it belongs next to the prompt.
///
/// ## Why the words are fixed Vietnamese, not localized
/// The rest of `businessContextPromptText` is already fixed Vietnamese, and it
/// has to be: the prompt must be **deterministic**, so the same business always
/// produces the same text. If these labels followed the UI locale, the same
/// seller would send a different prompt after tapping "English" — and every
/// prompt-content test would depend on a device setting.
///
/// ## The privacy boundary, restated where it matters
/// This block goes out on **every question**. It renders four categorical
/// answers and nothing else. There is no field here that could hold a customer
/// name, because there is no such field on [BusinessProfile] — see
/// `tongtai_business_profile_privacy_test.dart`.
library;

import '../profile/business_profile.dart';

/// Loại hình vận hành (ADR-TON-023). Đứng TRƯỚC ngành hàng vì nó quyết định
/// lời khuyên nào còn nghĩa: gợi ý "nhập thêm hàng" cho một studio phần mềm là
/// vô nghĩa dù ngành có đúng đến đâu.
String _typeLabel(BusinessType type) => switch (type) {
  BusinessType.physical => 'bán hàng vật lý (có nhập, có tồn kho)',
  BusinessType.digital => 'bán sản phẩm số (không có tồn kho)',
  BusinessType.service => 'bán dịch vụ / thời gian',
  BusinessType.hybrid => 'vừa hàng vật lý vừa số hoặc dịch vụ',
};

String _tradeLabel(BusinessTrade trade) => switch (trade) {
  BusinessTrade.fashion => 'thời trang',
  BusinessTrade.food => 'thực phẩm / đồ ăn',
  BusinessTrade.cosmetics => 'mỹ phẩm',
  BusinessTrade.electronics => 'điện tử',
  BusinessTrade.homeGoods => 'đồ gia dụng',
  BusinessTrade.services => 'dịch vụ',
  BusinessTrade.other => 'ngành khác',
};

String _sizeLabel(BusinessSize size) => switch (size) {
  BusinessSize.solo => 'tự làm một mình',
  BusinessSize.small => 'nhỏ (vài người)',
  BusinessSize.growing => 'đang mở rộng',
  BusinessSize.established => 'đã ổn định',
};

String _channelLabel(SalesChannel channel) => switch (channel) {
  SalesChannel.shop => 'cửa hàng',
  SalesChannel.market => 'chợ / sạp',
  SalesChannel.shopee => 'Shopee',
  SalesChannel.tiktok => 'TikTok Shop',
  SalesChannel.facebook => 'Facebook',
  SalesChannel.zalo => 'Zalo',
  SalesChannel.wholesale => 'bán sỉ',
  SalesChannel.website => 'website của mình',
  SalesChannel.appStore => 'chợ ứng dụng',
  SalesChannel.direct => 'bán trực tiếp / hợp đồng',
};

String _seasonalityLabel(BusinessSeasonality seasonality) =>
    switch (seasonality) {
      BusinessSeasonality.none => 'không theo mùa',
      BusinessSeasonality.tet => 'cao điểm dịp Tết',
      BusinessSeasonality.schoolYear => 'cao điểm mùa tựu trường',
      BusinessSeasonality.summer => 'cao điểm mùa hè',
      BusinessSeasonality.yearEnd => 'cao điểm cuối năm',
    };

/// The prompt block, or `null` when the seller has answered nothing.
///
/// `null` rather than an empty heading on purpose: a section that says
/// "Business Profile:" and then nothing invites the model to invent one.
String? businessProfilePromptText(BusinessProfile? profile) {
  if (profile == null || profile.isEmpty) return null;

  final lines = <String>[];
  if (profile.type != null) {
    lines.add('- Loại hình: ${_typeLabel(profile.type!)}');
  }
  if (profile.trade != null) {
    lines.add('- Ngành: ${_tradeLabel(profile.trade!)}');
  }
  if (profile.size != null) {
    lines.add('- Quy mô: ${_sizeLabel(profile.size!)}');
  }
  if (profile.channels.isNotEmpty) {
    // Sorted by the enum's own order so the same set of channels always renders
    // the same way — the prompt must not change because of tap order.
    final channels = [...profile.channels]
      ..sort((a, b) => a.index.compareTo(b.index));
    lines.add('- Kênh bán: ${channels.map(_channelLabel).join(', ')}');
  }
  if (profile.seasonality != null) {
    lines.add('- Mùa vụ: ${_seasonalityLabel(profile.seasonality!)}');
  }

  return '# Business Profile\n${lines.join('\n')}';
}
