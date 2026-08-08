import 'package:flutter/foundation.dart';

import '../action/business_action.dart';

/// **Vùng tự chủ** — WTM-306 (trải nghiệm #4).
///
/// ## Vì sao là ba vùng, không phải mười hai loại hành động
///
/// `BusinessActionType` có mười hai giá trị. Bắt người bán chỉnh từng cái là
/// bắt họ học từ vựng của hệ thống — đúng thứ Founder Task Order §8 cấm.
///
/// Ba vùng là ba câu người bán đã nghĩ sẵn trong đầu: *chăm khách* · *lo hàng*
/// · *chạy quảng cáo*. Mỗi hành động thuộc **đúng một** vùng, nên không có ô
/// nào không ai sở hữu và không luật nào áp hai lần.
enum AutonomyArea {
  /// Nhắn tin, chăm sóc, giữ khách.
  customerCare('customer_care', [
    BusinessActionType.customerSendMessage,
    BusinessActionType.customerSendColdMessage,
    BusinessActionType.customerContactOutsideBook,
    BusinessActionType.customerMergeRecords,
  ]),

  /// Nhập hàng, mức tồn, giá.
  inventory('inventory', [
    BusinessActionType.inventoryCreatePurchaseOrder,
    BusinessActionType.inventoryOrderAboveLimit,
    BusinessActionType.productUpdatePrice,
  ]),

  /// Chiến dịch quảng cáo.
  marketing('marketing', [
    BusinessActionType.campaignPause,
    BusinessActionType.campaignAdjustBudget,
  ]);

  const AutonomyArea(this.code, this.actions);

  final String code;

  /// Các hành động vùng này chi phối.
  final List<BusinessActionType> actions;

  /// Hành động trong vùng **được phép** tự chạy nếu người bán bật.
  List<BusinessActionType> get autoCapable => [
    for (final a in actions)
      if (!a.neverAutoByDefault) a,
  ];

  /// ⛔ Hành động **luôn hỏi người bán**, bất kể mức nào được chọn.
  List<BusinessActionType> get alwaysAsk => [
    for (final a in actions)
      if (a.neverAutoByDefault) a,
  ];

  /// Vùng này có gì để tự chạy không.
  ///
  /// Một vùng mà **mọi** hành động đều nằm trong danh sách cấm thì mức `Tự
  /// động` là một ô trống rỗng — hiện nó ra chỉ để người bán bật rồi không
  /// thấy gì xảy ra.
  bool get offersAuto => autoCapable.isNotEmpty;

  static AutonomyArea? fromCode(String? code) {
    for (final a in AutonomyArea.values) {
      if (a.code == code) return a;
    }
    return null;
  }

  /// Vùng của một hành động — `null` nếu chưa xếp vùng nào.
  ///
  /// `applyProposedChange` và `overwriteSellerEnteredData` cố ý **không** thuộc
  /// vùng nào: cái đầu là hệ quả của một lần người bán bấm (không có gì để tự
  /// chủ), cái sau bị cấm bằng cấu trúc ở tầng dưới.
  static AutonomyArea? of(BusinessActionType type) {
    for (final area in AutonomyArea.values) {
      if (area.actions.contains(type)) return area;
    }
    return null;
  }
}

/// Mức tự chủ người bán đã chọn cho từng vùng.
///
/// ## ⭐ `resolve` là chỗ danh sách cấm được thi hành, không phải màn hình
///
/// Màn hình **cũng** làm cho `Tự động` không chọn được với vùng không có gì tự
/// chạy — nhưng đó là lớp thứ hai. Lớp thứ nhất ở đây: dù cấu hình có nói gì,
/// một hành động trong danh sách cấm luôn trả về [AutonomyMode.confirm].
///
/// Hai lớp vì một lý do cụ thể: cấu hình có thể tới từ một bản khôi phục
/// `.ttbk` của máy khác, và bản khôi phục không đi qua màn hình nào.
@immutable
class AutonomySettings {
  const AutonomySettings({this.modes = const {}});

  /// Vùng → mức. Vùng vắng mặt ⇒ [defaultMode].
  final Map<AutonomyArea, AutonomyMode> modes;

  /// Mức mặc định khi người bán chưa chọn gì.
  ///
  /// `suggest` chứ không phải `confirm`: mặc định của một trợ lý mới là **nói**,
  /// không phải **hỏi xin làm**. Thêm một loại hành động mới cũng vào đúng mức
  /// này, nên nó không tự có quyền chạy.
  static const AutonomyMode defaultMode = AutonomyMode.suggest;

  AutonomyMode modeOf(AutonomyArea area) => modes[area] ?? defaultMode;

  /// Mức **thật sự có hiệu lực** cho một hành động.
  ///
  /// Kẹp xuống `confirm` cho mọi hành động trong danh sách cấm — đó là hằng số
  /// trong code (`neverAutoByDefault`), không phải một lựa chọn cấu hình.
  AutonomyMode resolve(BusinessActionType type) {
    final area = AutonomyArea.of(type);
    final chosen = area == null ? defaultMode : modeOf(area);
    if (chosen == AutonomyMode.auto && type.neverAutoByDefault) {
      return AutonomyMode.confirm;
    }
    return chosen;
  }

  /// Hành động này có được phép tự chạy với cấu hình hiện tại không.
  bool allowsAuto(BusinessActionType type) =>
      BusinessAction.allowsAuto(type, resolve(type));

  AutonomySettings withMode(AutonomyArea area, AutonomyMode mode) {
    // Chặn ngay tại chỗ đặt: một vùng không có gì tự chạy được mà mang mức
    // `Tự động` là một cấu hình nói dối người bán về thứ sắp xảy ra.
    if (mode == AutonomyMode.auto && !area.offersAuto) return this;
    return AutonomySettings(modes: {...modes, area: mode});
  }

  Map<String, String> toStorage() => {
    for (final e in modes.entries) e.key.code: e.value.code,
  };

  /// Mã lạ ⇒ **bỏ dòng**, không rơi về một mức nào (ADR-TON-018).
  ///
  /// Rơi về `auto` sẽ trao quyền chạy vì một lỗi chính tả; rơi về `suggest` sẽ
  /// im lặng gỡ mất một lựa chọn người bán đã đặt. Bỏ dòng thì mức về mặc
  /// định **và** khác biệt nhìn thấy được trên màn hình.
  static AutonomySettings fromStorage(Map<String, String> stored) {
    final modes = <AutonomyArea, AutonomyMode>{};
    for (final entry in stored.entries) {
      final area = AutonomyArea.fromCode(entry.key);
      final mode = AutonomyMode.fromCode(entry.value);
      if (area != null && mode != null) modes[area] = mode;
    }
    return AutonomySettings(modes: modes);
  }

  @override
  bool operator ==(Object other) =>
      other is AutonomySettings && mapEquals(other.modes, modes);

  @override
  int get hashCode =>
      Object.hashAll([for (final area in AutonomyArea.values) modes[area]]);
}
