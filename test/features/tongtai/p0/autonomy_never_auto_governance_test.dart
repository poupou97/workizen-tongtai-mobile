import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/action/business_action.dart';
import 'package:tongtai/features/tongtai/agent/autonomy_settings.dart';

/// ⛔ **Bảy việc tuyệt đối không tự chạy** — Founder duyệt 2026-08-08,
/// giao diện hoá ở WTM-306 (trải nghiệm #4).
///
/// ## Vì sao một màn hình cần suite riêng cho luật này
///
/// WTM-300 đã khoá danh sách cấm ở tầng `BusinessAction` bằng hằng số + assert.
/// Nhưng người bán không gặp tầng đó — họ gặp **một công tắc**. Và một công
/// tắc là chỗ dễ nhất để một luật bị nới: thêm một dòng cảnh báo rồi vẫn cho
/// bấm, và luật vẫn "còn đó" trên giấy.
///
/// Ba lớp ở đây, và lớp 2 là lớp không có màn hình nào đi qua:
///
/// 1. Danh sách cấm vẫn **đúng bảy**
/// 2. `resolve` **kẹp** xuống `confirm` dù cấu hình nói gì
/// 3. Màn thiết lập **không dựng nổi** một lựa chọn vi phạm
void main() {
  const screenFile =
      'lib/features/tongtai/ui/screens/tongtai_autonomy_screen.dart';
  const settingsFile = 'lib/features/tongtai/agent/autonomy_settings.dart';

  test('bộ quét thật sự đọc được code (chống PASS GIẢ)', () {
    expect(File(screenFile).existsSync(), isTrue);
    expect(File(settingsFile).existsSync(), isTrue);
    expect(
      File(settingsFile).readAsStringSync(),
      contains('AutonomyMode resolve('),
    );
  });

  test('lớp 1 · danh sách cấm vẫn ĐÚNG BẢY', () {
    final forbidden = [
      for (final t in BusinessActionType.values)
        if (t.neverAutoByDefault) t,
    ];
    expect(
      forbidden,
      hasLength(7),
      reason:
          'Founder duyệt đúng bảy loại. Thêm/bớt phải là một quyết định có '
          'chủ ý, không phải hệ quả của một lần refactor: ${forbidden.map((t) => t.code)}',
    );
  });

  test('⭐ lớp 2 · `resolve` KẸP xuống `confirm` dù cấu hình nói gì', () {
    // Đường vào này không đi qua màn hình nào: cấu hình có thể tới từ một bản
    // khôi phục `.ttbk` của máy khác, hoặc từ một phiên bản sau nới lỏng UI.
    final rogue = AutonomySettings(
      modes: {for (final area in AutonomyArea.values) area: AutonomyMode.auto},
    );

    for (final type in BusinessActionType.values) {
      if (!type.neverAutoByDefault) continue;
      // Luật là "KHÔNG BAO GIỜ auto", không phải "luôn là confirm": một loại
      // chưa xếp vùng rơi về mặc định `suggest`, và `suggest` cũng an toàn.
      // Viết luật đúng như nó là — một luật chặt hơn sự thật sẽ đỏ oan và bị
      // sửa cho khớp thay vì được tin.
      expect(
        rogue.resolve(type),
        isNot(AutonomyMode.auto),
        reason: '${type.code} bị cấm auto nhưng `resolve` cho phép',
      );
      expect(rogue.allowsAuto(type), isFalse);
    }

    // Và loại ĐÃ xếp vùng thì bị kẹp cụ thể xuống `confirm` — nó vẫn nằm
    // trong luồng làm việc, chỉ là luôn hỏi người bán.
    expect(
      rogue.resolve(BusinessActionType.customerSendColdMessage),
      AutonomyMode.confirm,
    );
  });

  test('lớp 2b · việc ĐƯỢC phép vẫn auto được khi người bán bật', () {
    // Một luật chỉ đáng tin khi nó cũng biết nói "được". Nếu mọi thứ đều bị
    // kẹp thì công tắc là đồ trang trí, và người bán sẽ phát hiện ra.
    final settings = const AutonomySettings().withMode(
      AutonomyArea.marketing,
      AutonomyMode.auto,
    );
    expect(
      settings.allowsAuto(BusinessActionType.campaignPause),
      isTrue,
      reason: 'công tắc phải thật sự nối vào cái gì đó',
    );
  });

  test('lớp 3 · vùng không có gì tự chạy thì KHÔNG nhận mức auto', () {
    for (final area in AutonomyArea.values) {
      if (area.offersAuto) continue;
      final after = const AutonomySettings().withMode(area, AutonomyMode.auto);
      expect(
        after.modeOf(area),
        isNot(AutonomyMode.auto),
        reason: '${area.code} không có việc nào tự chạy được',
      );
    }
  });

  test('lớp 3b · màn thiết lập chặn bằng CẤU TRÚC, không bằng cảnh báo', () {
    final screen = File(screenFile).readAsStringSync();
    expect(
      screen,
      contains('enabled: option != AutonomyMode.auto || area.offersAuto'),
      reason:
          'ô `Tự động` phải KHÔNG bấm được, không phải bấm được rồi hiện một '
          'dòng chữ — một dòng chữ là thứ người ta bấm qua',
    );
    expect(
      screen,
      contains('area.alwaysAsk'),
      reason: 'việc luôn-hỏi phải hiện ra, không im lặng biến mất',
    );
  });

  test('mọi hành động cấm đều nằm trong MỘT vùng nhìn thấy được', () {
    // Một hành động cấm không thuộc vùng nào sẽ không bao giờ hiện trong khối
    // "Luôn hỏi bạn" — luật vẫn đúng, nhưng người bán không biết nó tồn tại.
    final invisible = [
      for (final t in BusinessActionType.values)
        if (t.neverAutoByDefault && AutonomyArea.of(t) == null) t.code,
    ];
    expect(
      invisible,
      // `finance.transfer_money` và `data.overwrite_seller_entered` cố ý không
      // có vùng: Tổng Tài chưa bao giờ dựng hai hành động này, nên một mục cấm
      // cho việc không tồn tại chỉ làm người bán lo về thứ không có.
      ['finance.transfer_money', 'data.overwrite_seller_entered'],
      reason:
          'hành động cấm mới phải được xếp vùng, hoặc phải giải thích được vì '
          'sao nó vô hình',
    );
  });

  test('mỗi hành động thuộc NHIỀU NHẤT một vùng', () {
    // Hai vùng cùng chi phối một hành động nghĩa là hai công tắc cho một thứ,
    // và người bán sẽ gạt nhầm cái không có tác dụng.
    for (final type in BusinessActionType.values) {
      final owners = [
        for (final area in AutonomyArea.values)
          if (area.actions.contains(type)) area.code,
      ];
      expect(
        owners.length,
        lessThanOrEqualTo(1),
        reason: '${type.code}: $owners',
      );
    }
  });

  test('mã lạ trong bộ nhớ ⇒ bỏ dòng, KHÔNG rơi về auto', () {
    final settings = AutonomySettings.fromStorage({
      'customer_care': 'sort_of_auto',
      'inventory': 'confirm',
    });
    expect(settings.modeOf(AutonomyArea.customerCare), AutonomyMode.suggest);
    expect(settings.modeOf(AutonomyArea.inventory), AutonomyMode.confirm);
  });

  test('bộ quét bắt được vi phạm khi vi phạm thật sự có mặt', () {
    const offending = 'enabled: true, // luôn cho chọn auto';
    expect(offending.contains('enabled: option != AutonomyMode.auto'), isFalse);
  });
}
