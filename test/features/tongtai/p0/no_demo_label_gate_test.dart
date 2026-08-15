// P0 — **cổng: màn hình KHÔNG được nhắc rằng dữ liệu là mẫu** (WTM-430).
//
// ## Luật Founder — đã chốt BA lần
//
//   * WTM-343 (2026-08-09) — gỡ băng-rôn *"đang hiển thị dữ liệu mẫu"* ở Trang chủ
//   * WTM-348 (2026-08-09) — gỡ nhãn *"Dữ liệu mẫu"* trên từng thẻ brief, **sót
//     ngay hôm gỡ băng-rôn kia**
//   * 2026-08-15 — băng-rôn `DEMO` **vẫn còn** trên màn *Doanh nghiệp của bạn*
//
// > *"Bản demo phải trông như thật."* Nó là thứ Founder mang đi cho đối tác xem.
//
// ## Vì sao phải là CỔNG chứ không phải một chú thích nữa
//
// Cả hai lần trước, lý do đã được ghi rất rõ **trong chú thích ngay tại chỗ vừa
// gỡ**. Và nó vẫn rò lần thứ ba, ở một màn khác — vì chú thích chỉ nói với
// người đang đọc đúng tệp đó. Cùng bài học P-45: *một luật chỉ nằm trong chú
// thích thì không chặn được gì.*
//
// ## ⛔ Ranh giới: nhãn đi, DẤU VẾT ở lại
//
// Luật này kéo ngược chiều ADR-TON-014 và chuỗi *"một thứ không được tự xưng là
// cái nó không phải"* (P-39 ảnh giữ chỗ · WTM-421 chứng chỉ bịa). Founder đã
// cân nhắc và chốt. Thứ giữ cho rủi ro *"nhầm mẫu là số của mình"* không thành
// mất mát nằm ở chỗ đáng tin hơn một cái chip:
//
//   * mỗi bản ghi mẫu mang tiền tố `sample-` / `importJobId`;
//   * *"Xoá dữ liệu mẫu"* xoá đúng chúng, không đụng dữ liệu thật;
//   * **§40 nguyên vẹn** — trạng thái kỹ thuật (kết nối · AI bật/tắt · nguồn số
//     liệu · đồng hồ mô phỏng) không bao giờ được giả hay giấu.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _stripComments(String src) => src
    .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
    .split('\n')
    .map((l) {
      final i = l.indexOf('//');
      return i < 0 ? l : l.substring(0, i);
    })
    .join('\n');

/// Khoá l10n **được phép** xuất hiện trong `ui/` dù có chữ "demo/mẫu".
///
/// Phải nêu đích danh + lý do. Không có ngoại lệ chung chung — vì một ngoại lệ
/// không tên sẽ nuốt luôn thứ mà cổng này dựng ra để chặn.
/// ⭐ NĂM nhóm, mỗi nhóm một lý do KHÁC NHAU. Cấm gộp thành "ngoại lệ demo".
const _allowed = <String, String>{
  // ── (1) §40 — TRẠNG THÁI KỸ THUẬT, bắt buộc nói thật ─────────────────────
  //
  // Đây là chiều NGƯỢC LẠI của luật Founder, không phải kẽ hở. Founder cấm nói
  // *"dữ liệu của bạn là giả"*; §40 **bắt buộc** nói *"cái này chưa nối thật /
  // chưa gửi đi đâu"*. Gỡ nhầm nhóm này là biến app thành thứ nói dối về chính
  // nó — nặng hơn nhiều so với việc để lại một băng-rôn.
  'readinessDemo': '§40 · trạng thái connector',
  'readinessDemoConnected': '§40 · trạng thái connector',
  'sourcesDemoLive': '§40 · "không byte nào rời máy này"',
  'briefDemoExecution': '§40 · "diễn tập — chưa gửi đi đâu"',
  'briefDemoExecutionBody': '§40 · việc đã ghi nhưng không kênh nào nhận',
  'demoDayOf': '§40 · đồng hồ mô phỏng, không phải nhãn dữ liệu giả',
  'demoNotStarted': '§40 · trình mô phỏng chưa chạy',
  'demoNeedsCatalogue': '§40 · trình mô phỏng thiếu đầu vào',
  'demoFinished': '§40 · trình mô phỏng đã hết 30 ngày',

  // ── (2) HÀNH ĐỘNG người dùng chủ động bấm ────────────────────────────────
  //
  // Nút và hộp xác nhận của chính tính năng "quản lý dữ liệu mẫu". Cấm chúng
  // thì không còn đường nạp/xoá dữ liệu mẫu nữa.
  'homeCtaDemo': 'nút "Khám phá dữ liệu mẫu"',
  'sourcesStartDemo': 'nút "Bắt đầu doanh nghiệp demo"',
  'moreLoadSample': 'nút nạp',
  'moreLoadSampleAction': 'nút nạp',
  'moreLoadSampleConfirmTitle': 'hộp xác nhận của nút nạp',
  'moreLoadSampleConfirmBody': 'hộp xác nhận của nút nạp',
  'moreRemoveSample': 'nút xoá',
  'moreRemoveSampleAction': 'nút xoá',
  'moreRemoveSampleConfirmTitle': 'hộp xác nhận của nút xoá',
  'moreRemoveSampleConfirmBody': 'hộp xác nhận của nút xoá',
  'moreResetDemo': 'nút đặt lại',
  'moreResetDemoConfirmTitle': 'hộp xác nhận của nút đặt lại',
  'moreResetDemoConfirmBody': 'hộp xác nhận của nút đặt lại',
  'obV2DataSampleTitle': 'lựa chọn lúc onboarding',
  'obV2DataSampleBody': 'mô tả lựa chọn lúc onboarding',
  'demoStart': 'nút điều khiển trình mô phỏng',
  'demoNextEvent': 'nút điều khiển trình mô phỏng',
  'demoNextDay': 'nút điều khiển trình mô phỏng',
  'demoNextWeek': 'nút điều khiển trình mô phỏng',
  'demoReset': 'nút điều khiển trình mô phỏng',

  // ── (3) PHẢN HỒI MỘT LẦN cho việc người dùng VỪA làm ─────────────────────
  //
  // Snackbar sau khi bấm nút, không phải nhắc nhở thường trực trên màn. Người
  // vừa bấm "Nạp dữ liệu mẫu" thì cần biết nó đã chạy.
  'moreSampleLoadedSnack': 'snackbar sau khi nạp',
  'moreSampleRemovedSnack': 'snackbar sau khi xoá',
  'moreResetDemoSnack': 'snackbar sau khi đặt lại',
  'homeSampleLoadedSnack': 'snackbar sau khi nạp',
  'demoAdvanced': 'snackbar sau khi đẩy đồng hồ',

  // ── (4) BUSINESS TRUTH — giải thích một khoảng trống ─────────────────────
  //
  // Nói vì sao một yếu tố KHÔNG chấm được. Gỡ đi thì còn lại một con số không
  // nguồn — đúng thứ WTM-421 vừa dọn sạch.
  'oppUnavailSupplierSample': 'lý do một chỉ số thiếu',
  // ── (5) CHÍNH SÁCH RIÊNG TƯ — tài liệu, không phải nhãn trên màn ─────────
  //
  // ⛔ Vùng **G-3**: chính sách riêng tư phải mô tả đúng cách dữ liệu mẫu được
  // ghi và gỡ. Cắt bớt để cho cổng xanh là **sửa tài liệu pháp lý bằng một
  // cái test** — không agent nào được tự làm việc đó.
  'privacySampleTitle': 'G-3 · chính sách riêng tư',
  'privacySampleBody': 'G-3 · chính sách riêng tư',
};

void main() {
  test('⭐ màn hình KHÔNG nhắc rằng dữ liệu đang xem là mẫu (WTM-430)', () {
    // Bắt theo **khoá l10n**, không theo chuỗi hiển thị: chuỗi đổi theo locale
    // (ADR-TON-007 bắt mọi chữ đi qua `AppStrings`), nên quét chữ "DEMO" sẽ
    // vừa bỏ lọt bản EN vừa bắt oan tên biến.
    final offenders = <String>[];

    for (final e in Directory(
      'lib/features/tongtai/ui',
    ).listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final src = _stripComments(e.readAsStringSync());

      for (final m in RegExp(
        r'l10n\.(\w*[Dd]emo\w*|\w*[Ss]ample\w*)',
      ).allMatches(src)) {
        final key = m.group(1)!;
        if (_allowed.containsKey(key)) continue;
        offenders.add('${e.path} → l10n.$key');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'màn hình đang nhắc người dùng rằng dữ liệu là mẫu. Founder đã chốt '
          'ba lần là KHÔNG — bản demo phải trông như thật. Nếu khoá này thật '
          'sự nói về **trạng thái kỹ thuật** (kết nối, đồng hồ mô phỏng) hoặc '
          'là một **hành động**, thêm vào `_allowed` KÈM lý do.',
    );
  });

  test('băng-rôn DEMO cũ không sống lại dưới tên khác', () {
    // Cổng trên bắt theo **khoá**; cổng này bắt theo **hình dạng**. Một băng-rôn
    // mới hoàn toàn có thể dùng khoá tên khác và đi lọt — nhưng nó khó mà không
    // mang lại đúng cái `Key` cũ, vì test màn hình sẽ tìm theo Key ấy.
    //
    // ⚠️ Đây KHÔNG phải cổng đủ chặt, và tôi ghi rõ thay vì để cái tên đứng canh
    // thay cho mã (P-45, kiểu thứ tư): một băng-rôn dựng bằng `Text` trần với
    // chuỗi viết thẳng sẽ lọt cả hai cổng. Chốt chặn cuối vẫn là mắt người trên
    // máy thật.
    final src = File(
      'lib/features/tongtai/ui/screens/tongtai_business_life_screen.dart',
    ).readAsStringSync();

    expect(
      _stripComments(src),
      isNot(contains('business-life-demo-banner')),
      reason:
          'băng-rôn DEMO đã được gỡ ở WTM-430 — dựng lại là đi ngược lời '
          'Founder đã chốt ba lần',
    );
    expect(
      _stripComments(src),
      contains('business-life-day'),
      reason:
          'đồng hồ mô phỏng PHẢI còn: nó là trạng thái kỹ thuật (§40), không '
          'phải nhãn "dữ liệu là giả". Gỡ nhầm nó là sửa quá tay.',
    );
  });
}
