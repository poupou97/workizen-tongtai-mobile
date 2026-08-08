import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'autonomy_settings.dart';

/// Nơi mức tự chủ được lưu — WTM-306.
///
/// `SharedPreferences` chứ không phải một bảng: đây là **thiết lập của người
/// dùng trên máy này**, không phải dữ liệu nghiệp vụ. Nó không đi vào `.ttbk`
/// (ADR-TON-018 chỉ chép dữ liệu nghiệp vụ), và đó là đúng — khôi phục sổ sách
/// của một cửa hàng không nên kéo theo quyền hạn người ta trao cho AI.
class AutonomySettingsStore {
  const AutonomySettingsStore(this._prefs);

  final SharedPreferences _prefs;

  /// Có `v1` trong khoá vì mức tự chủ là **quyền hạn**. Đổi cách hiểu một mã
  /// mà đọc lại bằng khoá cũ có thể trao quyền rộng hơn người bán đã chọn.
  static const String key = 'tongtai.autonomy.v1';

  AutonomySettings load() {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return const AutonomySettings();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const AutonomySettings();
      return AutonomySettings.fromStorage({
        for (final e in decoded.entries)
          if (e.key is String && e.value is String)
            e.key as String: e.value as String,
      });
    } on FormatException {
      // Bản ghi hỏng ⇒ về **mặc định**, không về mức cuối cùng đoán được.
      // Đoán ở đây là đoán về quyền hạn.
      return const AutonomySettings();
    }
  }

  Future<void> save(AutonomySettings settings) =>
      _prefs.setString(key, jsonEncode(settings.toStorage()));
}
