import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **Mọi buildType cài được lên máy phải ký giống nhau** — WTM-385 (P-33).
///
/// ## Vì sao có suite này
///
/// Khoá ký của `com.workizen.tongtai` đã đổi (WTM-332), nên **cài đè là bất
/// khả thi** khi chữ ký lệch — và lối thoát mà mọi hướng dẫn trên mạng đưa ra
/// là *"gỡ app rồi cài lại"*, tức **xoá sạch dữ liệu kinh doanh thật** của
/// người dùng, không khôi phục được.
///
/// Repo đã ghi lý do ấy rất rõ, và đã vá cho `release`. Nhưng `debug` và
/// `profile` thì **không ai đụng tới** — nên cái bẫy còn nguyên, chỉ đổi cửa:
///
/// ```
/// flutter run             → INSTALL_FAILED_UPDATE_INCOMPATIBLE
/// flutter run --profile   → INSTALL_FAILED_UPDATE_INCOMPATIBLE
/// ```
///
/// Và `profile` đúng là bản WTM-277 cần để đo scroll jank trên máy thật.
///
/// ## Bài học lớp lỗi mà suite này giữ
///
/// **Ghi lý do là chưa đủ nếu bản vá chỉ bịt một cửa.** Người viết bản vá cũ
/// nghĩ tới đúng cửa họ đang đứng. Câu phải hỏi sau mỗi bản vá là *"còn cửa
/// nào khác cùng lớp?"* — và suite này là câu hỏi ấy, viết thành mã.
void main() {
  final gradle = File('android/app/build.gradle.kts');

  String source() => gradle.readAsStringSync();

  test('⭐ đọc được file thật (chống PASS giả)', () {
    // Không có cửa này thì mọi khẳng định dưới đây PASS trên một chuỗi rỗng.
    expect(gradle.existsSync(), isTrue);
    expect(source(), contains('buildTypes'));
    expect(source(), contains('signingConfigs'));
  });

  /// Chỉ phần **trong** `buildTypes { … }`.
  ///
  /// ⚠️ Bản đầu quét cả file và bắt trúng `getByName("release")` của khối
  /// `signingConfigs` đứng phía trên — tức là khẳng định đúng chữ nhưng sai
  /// chỗ. Cắt đúng khối trước khi hỏi.
  String buildTypesBlock() {
    final code = source();
    final at = code.indexOf('buildTypes');
    expect(at, greaterThan(-1), reason: 'không thấy khối buildTypes');
    return code.substring(at);
  }

  test('⛔ cả ba buildType cài được đều khai signingConfig', () {
    final code = buildTypesBlock();
    for (final type in const ['release', 'debug', 'profile']) {
      // `release { … }` và `getByName("profile") { … }` là hai cách khai khác
      // nhau — bắt cả hai, đừng bắt mỗi cách mình vừa viết.
      final at = code.indexOf(RegExp('$type"?\\)?\\s*\\{'));
      expect(
        at,
        greaterThan(-1),
        reason:
            '`$type` không xuất hiện trong buildTypes — bản dựng này sẽ dùng '
            'khoá mặc định, và người cài nó lên máy Founder sẽ được khuyên gỡ '
            'app (P-33)',
      );
      expect(
        code.substring(at, (at + 120).clamp(0, code.length)),
        contains('signingConfig'),
        reason: '`$type` không khai signingConfig',
      );
    }
  });

  test('⭐ ba buildType dùng CÙNG một cách giải chữ ký', () {
    // Không chỉ "có khai" — phải khai **giống nhau**. Ba nhánh `if` chép tay
    // là ba chỗ để lệch nhau vào lần sửa sau (P-27/P-28).
    final uses = RegExp(
      r'signingConfig\s*=\s*(\w+)',
    ).allMatches(buildTypesBlock()).map((m) => m.group(1)).toSet();
    expect(
      uses,
      hasLength(1),
      reason:
          'ba buildType đang giải chữ ký theo ${uses.length} cách khác nhau: '
          '$uses — chúng phải cùng một biến',
    );
  });

  test('⛔ khoá thật KHÔNG bao giờ nằm trong repo', () {
    // Cửa đi kèm: bản vá trên chỉ an toàn nếu `key.properties` vẫn ở ngoài
    // repo. Ký mọi buildType bằng khoá thật mà lỡ commit khoá lên thì đổi một
    // rủi ro mất dữ liệu thành một rủi ro lộ khoá phát hành.
    //
    // ⚠️ Bản đầu của test này `grep` mỗi `.gitignore` ở gốc repo và **báo động
    // nhầm**: luật thật nằm ở `android/.gitignore`. Suýt nữa thành một cảnh
    // báo bảo mật không có thật.
    //
    // Nên hỏi thẳng **git** — nó mới là thứ quyết định file nào đi theo repo.
    if (File('android/key.properties').existsSync()) {
      final ignored = Process.runSync('git', [
        'check-ignore',
        'android/key.properties',
      ]);
      expect(
        ignored.exitCode,
        0,
        reason: 'key.properties tồn tại mà git KHÔNG bỏ qua nó',
      );
    }
    final tracked = Process.runSync('git', [
      'ls-files',
      'android/key.properties',
      '**/*.jks',
      '**/*.keystore',
    ]);
    expect(
      (tracked.stdout as String).trim(),
      isEmpty,
      reason: 'khoá ký đang bị git theo dõi: ${tracked.stdout}',
    );
  });
}
