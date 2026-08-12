import 'package:flutter/material.dart';

import 'tt_tokens.dart';

/// **Theme Material của Tổng Tài** — WTM-379/380 (Epic WTM-362).
///
/// ## Vì sao nó ở đây chứ không nằm trong `main.dart`
///
/// Nó **là** một phần của Design System: mọi widget Material không được tạo
/// kiểu riêng — hộp thoại, công tắc, ô đánh dấu, tay kéo chọn chữ, snackbar,
/// nút mặc định — lấy màu từ đây. Để nó là một biểu thức vô danh nằm giữa
/// `build()` của `TongtaiApp` nghĩa là thứ **ảnh hưởng rộng nhất** trong sản
/// phẩm lại là thứ **không ai sở hữu**.
///
/// ## ⚠️ WTM-380 — `fromSeed` một mình là KHÔNG đủ
///
/// WTM-375 đổi hạt giống từ xanh lá sang cam, và WTM-379 khoá được điều đó
/// bằng test. Nhưng test chỉ biết **hạt giống màu gì**; nó không biết **hộp
/// thoại trông thế nào**. Cắm Nokia 6.1 vào thì thấy ngay:
///
/// * hộp thoại nền **kem ám cam**, không phải trắng;
/// * nút *"Nạp mẫu"*, *"Bắt đầu hành trình"*, các link *"Xem tất cả"* — tất cả
///   màu **nâu đất**, không phải cam thương hiệu.
///
/// Lý do: `ColorScheme.fromSeed` **không giữ** màu hạt giống. Nó sinh ra một
/// thang tông Material 3 và lấy một bậc **tối** làm `primary`, đồng thời nhuộm
/// `surface` theo sắc hạt giống. Kết quả là trên cùng một màn có **hai màu
/// cam**: cam của Design System, và nâu Material tự sinh.
///
/// Nên hạt giống ở lại (nó vẫn sinh các vai phụ hợp lý), còn **những vai người
/// dùng nhìn thấy thì ghi đè thẳng bằng token DS**. Design System không được
/// dừng lại đúng ở ranh giới của widget tự viết.
ColorScheme _scheme() =>
    ColorScheme.fromSeed(seedColor: TtColors.brand).copyWith(
      // Cam **đậm** chứ không phải `brand`: chữ trắng trên `brand` chỉ đạt
      // 2,80:1 — cùng lý do `TtPrimaryButton` dùng `brandOnDark`.
      primary: TtColors.brandOnDark,
      onPrimary: TtColors.textOnBrand,
      primaryContainer: TtColors.brandSoft,
      onPrimaryContainer: TtColors.brandPressed,

      // Bề mặt là **trắng thật**, không phải trắng ám cam. Một hộp thoại kem
      // trông như của một app khác đặt chồng lên app này.
      surface: TtColors.surface,
      onSurface: TtColors.textPrimary,
      onSurfaceVariant: TtColors.textSecondary,
      surfaceContainerHighest: TtColors.surfaceTertiary,
      outline: TtColors.borderStrong,
      outlineVariant: TtColors.border,

      error: TtColors.dangerOnLight,
      onError: TtColors.textOnBrand,
      errorContainer: TtColors.dangerSoft,
    );

final ThemeData tongtaiTheme = _build();

ThemeData _build() {
  final scheme = _scheme();
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: TtColors.surfaceSecondary,

    // Hộp thoại: nền trắng, bo theo thang bán kính DS. Trước WTM-380 nó lấy
    // `surface` ám cam của thang tông M3.
    dialogTheme: DialogThemeData(
      backgroundColor: TtColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TtRadius.lg),
      ),
      titleTextStyle: TtType.h3.copyWith(color: TtColors.textPrimary),
      contentTextStyle: TtType.body.copyWith(color: TtColors.textSecondary),
    ),

    // `surfaceTintColor` trong suốt ở mọi bề mặt nổi: lớp phủ tông màu của M3
    // là đúng thứ biến thẻ trắng thành thẻ kem khi nó được nâng lên.
    cardTheme: const CardThemeData(
      color: TtColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: TtColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: TtColors.surfaceSecondary,
      surfaceTintColor: Colors.transparent,
      foregroundColor: TtColors.textPrimary,
      elevation: 0,
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: TtColors.surface,
      surfaceTintColor: Colors.transparent,
    ),

    // Snackbar là **chữ trắng trên nền tối**, không phải một mảng nâu.
    snackBarTheme: SnackBarThemeData(
      backgroundColor: TtColors.textPrimary,
      contentTextStyle: TtType.body.copyWith(color: TtColors.textOnBrand),
      actionTextColor: TtColors.brand,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TtRadius.md),
      ),
    ),

    // Điều khiển bật/tắt: **cam = hành động**, đúng luật. Trước đây chúng mang
    // nâu Material, nên một công tắc đang bật trông không giống bất kỳ thứ gì
    // khác trong app.
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? TtColors.textOnBrand
            : TtColors.surface,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? TtColors.brandOnDark
            : TtColors.borderStrong,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? TtColors.brandOnDark
            : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(TtColors.textOnBrand),
      side: const BorderSide(color: TtColors.borderStrong, width: 2),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? TtColors.brandOnDark
            : TtColors.borderStrong,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: TtColors.brandOnDark,
      linearTrackColor: TtColors.surfaceTertiary,
      circularTrackColor: TtColors.surfaceTertiary,
    ),

    // Ô nhập: viền DS, và viền khi focus là **cam**, không phải nâu.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TtColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TtRadius.md),
        borderSide: const BorderSide(color: TtColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TtRadius.md),
        borderSide: const BorderSide(color: TtColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TtRadius.md),
        borderSide: const BorderSide(color: TtColors.brandOnDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TtRadius.md),
        borderSide: const BorderSide(color: TtColors.dangerOnLight),
      ),
    ),

    // Con trỏ và tay kéo chọn chữ — chi tiết nhỏ, nhưng nó xuất hiện ở mọi ô
    // nhập của mọi form, nên nó cũng phải nói cùng một thứ tiếng.
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: TtColors.brandOnDark,
      selectionHandleColor: TtColors.brandOnDark,
    ),
  );
}
