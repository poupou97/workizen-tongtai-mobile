// P0 — **hình học của icon launcher + splash** (WTM-416).
//
// ## Vì sao phải có cổng cho một con số tỉ lệ
//
// Icon Android bị **mặt nạ cắt** ở ba chỗ khác nhau, và không chỗ nào báo lỗi:
//
//   * adaptive icon: khung 108dp, nhìn thấy 72dp, **an toàn 66dp** — phần ngoài
//     bị từng hãng cắt theo hình riêng (tròn · squircle · giọt nước);
//   * `flutter_launcher_icons` còn tự chèn `inset="16%"` vào foreground;
//   * splash Android 12 cắt tròn theo đường kính **66,7%** khung.
//
// Ba lần nhân với nhau, và kết quả chỉ nhìn thấy **sau khi cài lên máy**. Trong
// chính đợt làm này đã trượt hai lần liên tiếp:
//
//   1. đặt 66% vì ghi chú cũ chép số **66dp** thành **66%** ⇒ mặt nạ tròn cắt
//      cụt chấm chữ "i";
//   2. ảnh gốc có quầng alpha = 1 vô hình, `getbbox()` tính cả quầng ⇒ mọi tỉ
//      lệ hụt 10% và icon ra nhỏ hơn thiết kế — cũng không có gì báo.
//
// Cả hai đều là "một thứ tự xưng là cái nó không phải". Cổng này đo **phần
// nhìn thấy được thật** trong tệp đã sinh, rồi nhân đúng những gì Android sẽ
// nhân, nên nó bắt được cả hai chiều: to quá thì bị cắt, nhỏ quá thì trông yếu.
//
// Sinh lại bằng: `tool/build_brand_assets.py` → `dart run flutter_launcher_icons`
// → `dart run flutter_native_splash:create`.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// Vùng an toàn adaptive icon: 66dp trên khung 108dp.
const _safeZone = 66 / 108;

/// Mặt nạ tròn của splash Android 12: 768/1152.
const _splashMask = 768 / 1152;

/// Phần khung mà launcher thật sự cho nhìn thấy: 72dp trên 108dp.
const _viewport = 72 / 108;

/// Tỉ lệ mà `tool/build_brand_assets.py` **tự khai** — đọc từ chính script.
///
/// So với một ngưỡng cứng viết tay thì cách này mạnh hơn hẳn: nó bắt **mọi**
/// lần tệp sinh ra không khớp ý định, bất kể ý định là bao nhiêu. Đúng con
/// đường mà quầng alpha vô hình đã đi qua — script khai 0,58 mà tệp ra 0,52, và
/// không có gì trên đời báo cho ai biết.
double _declaredTarget() {
  final src = File('tool/build_brand_assets.py').readAsStringSync();
  final m = RegExp(r'^TARGET = ([\d.]+)', multiLine: true).firstMatch(src);
  expect(m, isNotNull, reason: 'không đọc được TARGET trong script sinh ảnh');
  return double.parse(m!.group(1)!);
}

/// Tỉ lệ bề ngang phần **nhìn thấy được** (alpha đủ đục) trên bề ngang tệp.
Future<double> _visibleWidthRatio(String path) async {
  final codec = await ui.instantiateImageCodec(
    Uint8List.fromList(File(path).readAsBytesSync()),
  );
  final image = (await codec.getNextFrame()).image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  int minX = image.width, maxX = -1;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      // ⚠️ Ngưỡng 8, không phải 0: quầng alpha = 1 là thứ đã lừa được vòng
      // trước. Mắt không thấy nó thì phép đo cũng không được thấy.
      if (data!.getUint8((y * image.width + x) * 4 + 3) > 8) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
      }
    }
  }
  expect(maxX, greaterThan(-1), reason: '$path rỗng hoàn toàn');
  return (maxX - minX + 1) / image.width;
}

/// Inset mà generator tự chèn — đọc từ XML chứ không chép cứng, vì nó là hành
/// vi của thư viện và có thể đổi khi nâng phiên bản.
double _generatorInset() {
  final xml = File(
    'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
  ).readAsStringSync();
  final m = RegExp(r'android:inset="(\d+)%"').firstMatch(xml);
  return m == null ? 0 : int.parse(m.group(1)!) / 100;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('foreground adaptive nằm gọn trong vùng an toàn 66dp', () async {
    final inset = _generatorInset();
    final ratio = await _visibleWidthRatio(
      'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png',
    );
    final effective = ratio * (1 - 2 * inset);

    expect(
      effective,
      lessThanOrEqualTo(_safeZone),
      reason: 'logo chiếm ${(effective * 108).toStringAsFixed(1)}dp — vượt vùng '
          'an toàn 66dp ⇒ mặt nạ tròn sẽ cắt cụt. Hạ tỉ lệ trong '
          'tool/build_brand_assets.py rồi sinh lại.',
    );
    final target = _declaredTarget();
    expect(
      effective,
      closeTo(target, 0.02),
      reason:
          'script khai ${(target * 100).toStringAsFixed(0)}% nhưng tệp sinh ra '
          '${(effective * 100).toStringAsFixed(1)}%. Lệch giữa ý định và kết quả '
          '— lần trước là do quầng alpha = 1 vô hình lọt vào phép cắt. Sinh lại '
          'bằng tool/build_brand_assets.py.',
    );

    // Con số Founder thấy được: logo chiếm bao nhiêu phần NHÌN THẤY. Vùng an
    // toàn nói cái gì không bị cắt; con số này nói cái gì trông cân.
    expect(
      effective / _viewport,
      lessThanOrEqualTo(0.80),
      reason: 'logo chiếm ${(effective / _viewport * 100).toStringAsFixed(0)}% '
          'phần nhìn thấy — đo trên S24, bản 88% trông chật và chữ CRM sát đáy, '
          'trong khi ô icon bản vẽ Founder ~72%.',
    );
  });

  test('ảnh splash Android 12 nằm trong mặt nạ tròn', () async {
    final ratio = await _visibleWidthRatio(
      'android/app/src/main/res/drawable-xxxhdpi/android12splash.png',
    );
    expect(
      ratio,
      lessThanOrEqualTo(_splashMask),
      reason: 'splash Android 12 cắt tròn ở 66,7% khung — logo rộng hơn thế sẽ '
          'mất chữ CRM ở hai đầu.',
    );
    expect(ratio, greaterThanOrEqualTo(0.35));
  });

  test('splash nền tối dùng ảnh RIÊNG, không dùng lại ảnh nền sáng', () async {
    // Chữ "CRM" trong logo màu navy: đặt nguyên bản sáng lên nền tối thì chữ
    // biến mất. Hai tệp giống hệt nhau ⇒ ai đó đã gộp lại "cho gọn".
    final light = File(
      'android/app/src/main/res/drawable-xxxhdpi/android12splash.png',
    ).readAsBytesSync();
    final dark = File(
      'android/app/src/main/res/drawable-night-xxxhdpi/android12splash.png',
    ).readAsBytesSync();
    expect(
      light.length == dark.length && light.first == dark.first,
      isFalse,
      reason: 'splash sáng và tối đang là cùng một ảnh — trên nền tối chữ CRM '
          'sẽ biến mất',
    );
  });
}
