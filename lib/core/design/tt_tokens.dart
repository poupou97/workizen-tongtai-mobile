/// **Tổng Tài Design System v1.0 — tầng token** (WTM-363, Epic WTM-362).
///
/// Nguồn: directive Founder 2026-08-11 + `docs/01-PRODUCT/concept-1/concepts.png`.
/// Khi ảnh và spec lệch nhau, **spec thắng** — ảnh là tham chiếu thị giác, không
/// phải bảng màu để lấy mẫu pixel.
///
/// ## ⭐ Nguyên tắc phải nhớ trước khi dùng bất kỳ màu nào
///
/// ```
/// TÍM      = AI đang hiểu / đang kết luận
/// CAM      = người bán bấm được  (thương hiệu + hành động)
/// XANH LÁ  = tích cực / khoẻ
/// LAM      = thông tin
/// HỔ PHÁCH = cần chú ý
/// ĐỎ       = nguy cấp
/// XÁM      = CHƯA BIẾT
/// ```
///
/// Hai lỗi dễ mắc nhất, và cả hai đều làm người dùng hiểu sai sản phẩm:
///
/// * **CAM ≠ AI.** *"Tổng Tài phát hiện 3 SKU sắp hết"* là tím; *"Tạo đơn nhập"*
///   là cam. Tô câu kết luận màu cam sẽ dạy người bán rằng chữ cam nghĩa là
///   "AI nói", rồi họ thôi bấm những nút thật sự bấm được.
/// * **XÁM ≠ XANH.** *"Chưa đủ dữ liệu"* không bao giờ mang màu thành công. Một
///   ô trống tô xanh là lời trấn an cho điều chưa ai kiểm.
///
/// ## Quan hệ với `TongtaiDesignTokens`
///
/// Lớp cũ **không bị xoá** và ~40 màn vẫn dùng nó. Đây không phải tầng song
/// song: giá trị nào trùng thì lớp cũ chuyển tiếp sang đây, giá trị nào lệch
/// thì bảng migration trong `docs/02-ARCHITECTURE/TONG_TAI_DESIGN_SYSTEM_V1.md`
/// nói rõ lệch ở đâu và vì sao. Migration là tăng dần, không big-bang.
library;

import 'package:flutter/widgets.dart';

/// Màu — **semantic, không phải tên màu**. Không có `orange`/`purple` ở đây;
/// có `action` và `ai`, vì đó là thứ quyết định lúc chọn.
abstract final class TtColors {
  // ── Thương hiệu / hành động ────────────────────────────────────────────
  /// Màu thương hiệu — dùng cho **biểu tượng, viền, chữ trên nền sáng**.
  static const Color brand = Color(0xFFF97316);

  /// ⚠️ Nền của nút mang chữ trắng — **đậm hơn** [brand] có chủ đích.
  ///
  /// Spec của Founder ghi nền nút là `#F97316`. Chữ trắng trên màu đó chỉ đạt
  /// **2,80:1**, dưới ngưỡng WCAG AA 4,5:1 — và suite `accessibility_test` của
  /// repo này bắt đúng điều đó khi thử. `#C2410C` đạt **5,18:1** và là sắc cam
  /// sáng nhất còn qua được ngưỡng.
  ///
  /// Đây là chỗ duy nhất trong Design System lệch khỏi spec, và nó lệch vì một
  /// cổng chất lượng đã có sẵn chứ không vì sở thích. Cùng bài học mà
  /// `TongtaiDesignTokens` đã ghi cho `inventoryOrange` (2,15:1).
  static const Color brandOnDark = Color(0xFFC2410C);

  static const Color brandPressed = Color(0xFF9A3412);
  static const Color brandSoft = Color(0xFFFFF7ED);

  // ── AI / trí tuệ ───────────────────────────────────────────────────────
  /// Chỗ **Tổng Tài đang nói**: quan sát, lý lẽ, đề xuất.
  static const Color ai = Color(0xFF7C3AED);
  static const Color aiSoft = Color(0xFFF5F3FF);
  static const Color aiBorder = Color(0xFFDDD6FE);

  // ── Trạng thái ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFF0FDF4);

  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFEFF6FF);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFFFBEB);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);

  /// ⭐ **CHƯA BIẾT.** Dùng cho *"chưa đủ dữ liệu"* · *"chưa phân tích"* ·
  /// *"không xác định"*. Cố ý **không** có biến thể xanh: thiếu thông tin không
  /// phải một kết quả tốt, và tô nó màu tốt là nói dối bằng màu.
  static const Color unknown = Color(0xFF94A3B8);
  static const Color unknownSoft = Color(0xFFF1F5F9);

  /// ⭐ **BIẾT RÕ, KHÔNG PHÁN XÉT** — *"dữ liệu thường"* trong luật màu Founder
  /// (WTM-425). Tạm dừng · đang là demo · đã rời bỏ · không có mức đổi để so.
  ///
  /// **Đậm hơn [unknown] có chủ ý.** `unknown` nhạt (`#94A3B8`) vì nó nói *"tôi
  /// không biết"* — mờ là đúng. Trung tính thì **biết rất rõ**, chỉ là không
  /// khen không chê, nên nó phải đọc được như một khẳng định bình thường.
  /// Cùng một sắc cho cả hai là xoá mất đúng chỗ khác nhau ấy.
  static const Color neutral = textSecondary;

  /// ⚠️ **KHÔNG** dùng lại `surfaceTertiary` cho nền này.
  ///
  /// Bản đầu tôi viết `neutralSoft = surfaceTertiary`, mà `surfaceTertiary`
  /// đúng bằng [unknownSoft] (`#F1F5F9`) — nên *"trung tính"* và *"chưa biết"*
  /// dùng chung một nền, tức vừa tách xong hai nghĩa ở tầng chữ thì lại nhập
  /// chúng ở tầng nền. Cổng `tt_tokens_test` bắt được ngay ("mọi mức đều có
  /// màu và nền riêng").
  ///
  /// Bản thứ hai `#F8FAFC` cũng sai, và sai theo kiểu **test không bắt được**:
  /// nó đúng bằng [surfaceSecondary] — **nền trang của hầu hết màn** — nên huy
  /// hiệu sẽ tàng hình đúng ở chỗ nó hay đứng nhất. Cổng chỉ hỏi *"các mức có
  /// khác nhau không"*, không hỏi *"có nhìn thấy không"*.
  ///
  /// `#E8EDF3` đậm hơn một bậc: khác [unknownSoft], và đọc được trên cả
  /// [surface] lẫn [surfaceSecondary]. Chữ [neutral] trên nền này đạt ~6,4:1.
  static const Color neutralSoft = Color(0xFFE8EDF3);

  // ── Chữ ────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnBrand = Color(0xFFFFFFFF);

  // ── Mặt nền ────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF8FAFC);
  static const Color surfaceTertiary = Color(0xFFF1F5F9);

  /// ⚠️ Nền cho chữ trắng, sắc hổ phách — cùng lý do với [brandOnDark].
  ///
  /// `warning` `#F59E0B` với chữ trắng chỉ đạt **2,15:1** — cặp tệ nhất trong
  /// cả bảng màu (WTM-169 đã trả giá một lần). `#B45309` đạt **5,02:1**.
  static const Color warningOnDark = Color(0xFFB45309);

  // ── Biến thể đậm, dùng được trong `const` ───────────────────────────────
  //
  // `readableOn` là một hàm nên nó không nằm trong biểu thức `const` được, mà
  // rất nhiều chỗ trong app dựng màu ở vị trí const. Bốn hằng dưới đây là cùng
  // giá trị, khai riêng để hàm và hằng không thể lệch nhau: hàm trả về **chính
  // chúng**.
  static const Color successOnLight = Color(0xFF047857);
  static const Color infoOnLight = Color(0xFF1D4ED8);
  static const Color aiOnLight = Color(0xFF6D28D9);
  static const Color dangerOnLight = Color(0xFFB91C1C);

  /// Chữ **đọc được** đặt trên một màu ngữ nghĩa.
  ///
  /// Có hàm này để một component được **trao** một màu (chip, badge, tiêu đề)
  /// vẫn dựng được nhãn dễ đọc mà người gọi không phải nhớ một hằng số thứ hai.
  /// Màu lạ rơi về [textPrimary] — đoán một tỉ lệ tương phản chính là cách lỗi
  /// WTM-169 xảy ra.
  ///
  /// Bảng này phủ **cả** màu của Design System **và** màu của
  /// `TongtaiDesignTokens`, vì hai bảng màu còn sống song song trong lúc di
  /// trú. Một bảng ánh xạ, một chủ — `TongtaiDesignTokens.readableText` nay chỉ
  /// chuyển tiếp về đây.
  static Color readableOn(Color base) => switch (base.toARGB32()) {
    // Design System
    0xFF16A34A => successOnLight,
    0xFF2563EB => infoOnLight,
    0xFFF59E0B => warningOnDark,
    0xFFDC2626 => dangerOnLight,
    0xFF7C3AED => aiOnLight,
    0xFF94A3B8 => textSecondary,
    0xFFF97316 => brandOnDark,
    // Bảng cũ, còn dùng ở những màn chưa di trú
    0xFF10B981 => successOnLight, // producerGreen
    0xFF3B82F6 => infoOnLight, // consumerBlue
    0xFF8B5CF6 || 0xFFA78BFA => aiOnLight, // financePurple/copilot
    0xFFEF4444 => dangerOnLight, // error cũ
    0xFF6B7280 => textSecondary, // setupGray/neutral
    _ => textPrimary,
  };

  // ── Viền ───────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
  static const Color divider = Color(0xFFE5E7EB);
}

/// Mức nghiêm trọng — **một chỗ duy nhất** ánh xạ mức sang màu.
///
/// Có enum này để không màn nào tự viết `switch` màu riêng: hai bảng ánh xạ sẽ
/// lệch nhau đúng vào ngày ai đó sửa một bên (P-27/P-28, repo này đã dọn bốn
/// lần).
enum TtStatus {
  success,
  info,
  warning,
  danger,

  /// AI đang nói — không phải một mức nghiêm trọng, nhưng nó dùng chung khe
  /// "màu ngữ nghĩa" nên nằm ở đây để không ai chế thêm bảng thứ hai.
  ai,

  /// **Biết rõ, nhưng không phán xét** — dữ liệu thường (WTM-425).
  ///
  /// Luật màu Founder có khai vai này (*"Neutral = dữ liệu thường"*), nhưng
  /// enum thì không, nên bốn chỗ đã **mượn tạm `unknown`** cho nó:
  ///
  ///   * `ConnectionStatus.paused` — người dùng chủ động dừng, biết rất rõ;
  ///   * `ConnectionReadiness.demo` — biết chắc đây là demo;
  ///   * `CustomerSegment.churned`/`dormant` — kết luận đã có, chỉ là không nên
  ///     tô đỏ;
  ///   * mức đổi **bằng 0** — đã so và biết là bằng phẳng.
  ///
  /// ⚠️ Ranh giới hẹp: *đã so, bằng phẳng* là [neutral]; *chưa có kỳ trước để
  /// so* vẫn là [unknown]. Tôi đã trượt đúng chỗ này một lần ở WTM-425 và
  /// `tt_components_test` bắt lại.
  ///
  /// Một chủ gánh hai khái niệm là **P-27 lộn ngược**, và hậu quả cùng loại:
  /// sửa màu cho *"thiếu dữ liệu"* sẽ lặng lẽ đổi màu của *"tạm dừng"*, không
  /// ai thấy cho tới lúc nhìn màn hình.
  neutral,

  /// **Chưa biết** — thiếu dữ liệu để kết luận. **Không** phải success, và
  /// cũng **không** phải [neutral]: *không biết* khác *biết mà không phán xét*.
  unknown;

  Color get color => switch (this) {
    TtStatus.success => TtColors.success,
    TtStatus.info => TtColors.info,
    TtStatus.warning => TtColors.warning,
    TtStatus.danger => TtColors.danger,
    TtStatus.ai => TtColors.ai,
    TtStatus.neutral => TtColors.neutral,
    TtStatus.unknown => TtColors.unknown,
  };

  Color get soft => switch (this) {
    TtStatus.success => TtColors.successSoft,
    TtStatus.info => TtColors.infoSoft,
    TtStatus.warning => TtColors.warningSoft,
    TtStatus.danger => TtColors.dangerSoft,
    TtStatus.ai => TtColors.aiSoft,
    TtStatus.neutral => TtColors.neutralSoft,
    TtStatus.unknown => TtColors.unknownSoft,
  };
}

/// Chữ. Font Inter, dự phòng SF Pro (iOS) → Roboto (Android) → hệ thống.
///
/// Khai `fontFamilyFallback` chứ không ép một font đóng gói: tiếng Việt có dấu
/// chồng, và font hệ thống của mỗi nền tảng dựng dấu tốt hơn một bản Inter cắt
/// gọn để giảm dung lượng.
abstract final class TtType {
  static const String family = 'Inter';
  static const List<String> fallback = ['SF Pro Text', 'Roboto'];

  static const TextStyle display = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 34 / 28,
    color: TtColors.textPrimary,
  );
  static const TextStyle h1 = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 30 / 24,
    color: TtColors.textPrimary,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 26 / 20,
    color: TtColors.textPrimary,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    color: TtColors.textPrimary,
  );
  static const TextStyle title = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 22 / 16,
    color: TtColors.textPrimary,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: TtColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: TtColors.textPrimary,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    color: TtColors.textPrimary,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    color: TtColors.textSecondary,
  );
  static const TextStyle label = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    color: TtColors.textSecondary,
  );

  /// Con số nghiệp vụ lớn — phải quét được bằng mắt trong một nhịp.
  static const TextStyle metricLarge = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 34 / 28,
    color: TtColors.textPrimary,
  );
  static const TextStyle metric = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 26 / 20,
    color: TtColors.textPrimary,
  );
}

/// Khoảng cách — lưới 4px.
///
/// Trùng đúng với `TongtaiDesignTokens.spacing*` đang chạy, nên đây là chỗ hai
/// lớp gặp nhau mà không ai phải đổi con số nào.
abstract final class TtSpace {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;

  /// Lề ngang của mọi màn.
  static const double screenH = x4;

  /// Giữa hai khối lớn.
  static const double section = x6;

  /// Tiêu đề → nội dung của nó.
  static const double headingToContent = x3;

  static const double cardPadding = x4;
  static const double heroPadding = x5;
  static const double rowGap = x3;
}

/// Bo góc.
///
/// ⚠️ **Tên ở đây lệch tên cũ một bậc.** `TongtaiDesignTokens.radiusLg` = 12
/// tương ứng [TtRadius.md]; `radiusXl` = 16 tương ứng [TtRadius.lg]. Di trú
/// phải đi theo **giá trị**, không theo tên — đổi tên tại chỗ sẽ âm thầm bo lại
/// góc của mọi màn đang chạy.
abstract final class TtRadius {
  static const double xs = 6;
  static const double sm = 8;

  /// Nút và ô nhập.
  static const double md = 12;

  /// Thẻ tiêu chuẩn.
  static const double lg = 16;

  /// Thẻ AI / hero.
  static const double xl = 20;

  /// Đáy bottom sheet.
  static const double sheet = 24;

  static const double full = 999;
}

/// Đổ bóng. **Mặc định là KHÔNG có.**
///
/// Viền nhẹ đọc tốt hơn bóng trên nền sáng, và một màn mà mọi thẻ đều nổi lên
/// thì không thẻ nào còn nổi. Bóng chỉ dành cho thứ thật sự lơ lửng: FAB,
/// modal, thanh hành động dính đáy, overlay.
abstract final class TtElevation {
  static const List<BoxShadow> none = [];

  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 3, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x1A0F172A), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

/// Chuyển động.
///
/// ⛔ Không có "thời lượng loading": một thanh chạy theo `Duration` cố định là
/// tiến trình giả, và nó bị cấm ở §16 lẫn §21. Thời lượng ở đây chỉ dành cho
/// chuyển cảnh và hiện/ẩn.
abstract final class TtMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Curve curve = Curves.easeOutCubic;

  /// Insight hiện ra: mờ dần + trượt lên 8px.
  static const double revealOffset = 8;
}
