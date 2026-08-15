// Khuôn mặt của Workizen AI — bộ linh vật Ai CRM (WTM-417, thay WTM-111).
//
// ## Vì sao test này không chỉ đổi tên asset
//
// `TongtaiFoxMascot` có **18 chỗ gọi** trải khắp Home · Chat · Cơ hội · Tài
// chính · Báo cáo · Agent · Hoạt động. Nó không phải một widget trang trí; nó
// là *người nói* trong hội thoại. Đổi asset ở đây là đổi mặt của cả sản phẩm,
// nên cái đáng canh là **hợp đồng**, không phải đường dẫn:
//
//   §1 hai dạng khác nhau ở VAI (có đĩa / không đĩa), không ở kích thước;
//   §2 ảnh **thật sự nằm trong bundle** — thiếu khai pubspec thì ô trống, và
//      một ô trống ở chỗ avatar trông như app hỏng chứ không như thiếu ảnh;
//   §3 mọi tư thế trong `MascotPose` đều **có tệp**: enum liệt kê *việc*, và
//      một việc không có hình là một màn onboarding trống giữa chừng.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tongtai_fox_mascot.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tongtai_mascot_pose.dart';

void main() {
  testWidgets('§1 face = đầu trần · avatar = đầu trên đĩa, cùng cỡ yêu cầu', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TongtaiFoxMascot.face(size: 80),
              TongtaiFoxMascot.avatar(size: 40),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(TongtaiFoxMascot).first),
      const Size(80, 80),
    );
    expect(
      tester.getSize(find.byType(TongtaiFoxMascot).last),
      const Size(40, 40),
    );

    // ⚠️ WTM-436 — bản trước khẳng định **đĩa chỉ có ở avatar**, và ghi rõ:
    // *"nếu cả hai cùng có (hoặc cùng không), hai dạng đã mất phần phân biệt
    // vai"*. Founder gọi cái đĩa là *"rất thô"*, concept `cp_home.png` vẽ linh
    // vật **không đĩa**, nên đĩa bị bỏ — và lời cảnh báo ấy nay thành sự thật.
    //
    // **Rekey, không xoá** (P-37). Bất biến mới, và nó kiểm được:
    // **KHÔNG dạng nào còn đĩa.** Gieo lại một `Container` bọc đầu cáo ⇒ đỏ.
    for (final at in [0, 1]) {
      expect(
        find.descendant(
          of: find.byType(TongtaiFoxMascot).at(at),
          matching: find.byType(Container),
        ),
        findsNothing,
        reason:
            'linh vật lại có nền dán sau lưng. Ảnh nguồn vốn trong suốt; mọi '
            'mảng đặc quanh nó là do widget thêm vào (WTM-436).',
      );
    }

    // ⚠️ NỢ ĐỂ LẠI, ghi ra thay vì im lặng: bỏ đĩa xong thì `.avatar` và
    // `.face` chỉ còn khác nhau **cỡ mặc định** — hai tên cho một thứ. Tín hiệu
    // *"AI đang nói"* nay nằm ở **nền thẻ** bao quanh, đúng như concept vẽ.
    //
    // Gộp hai constructor là việc riêng: nó chạm 3 chỗ gọi và vài test, và
    // đang có việc gấp hơn trong Epic WTM-435. Chốt lại ở đây để lần sau khỏi
    // phải phát hiện lại.
  });

  testWidgets('§2 ảnh khuôn mặt nạp được thật từ bundle', (tester) async {
    expect(
      (await rootBundle.load(TongtaiFoxMascot.headAsset)).lengthInBytes,
      greaterThan(0),
      reason:
          '${TongtaiFoxMascot.headAsset} không có trong bundle — thiếu khai '
          'trong pubspec.yaml. `Image.asset` không ném lỗi, nó chỉ vẽ ô trống.',
    );
  });

  testWidgets('§3 MỌI tư thế trong enum đều có tệp trong bundle', (
    tester,
  ) async {
    for (final pose in MascotPose.values) {
      expect(
        (await rootBundle.load(pose.asset)).lengthInBytes,
        greaterThan(0),
        reason:
            'tư thế "${pose.name}" trỏ tới ${pose.asset} nhưng tệp không '
            'vào bundle. Enum liệt kê VIỆC — một việc không có hình là một chỗ '
            'trống giữa màn onboarding.',
      );
    }
  });

  test('§4 tư thế "chưa có gì để xem" KHÔNG dùng hình vui mừng', () {
    // Luật cũ của màn onboarding, nay khoá bằng máy: bộ art mới có sẵn cả cáo
    // nhảy mừng lẫn cáo cầm kính lúp, nên chọn sai ở đây là **chọn**, không
    // phải thiếu.
    const cheerful = {'celebrating', 'jumping', 'thumbs_up', 'excited'};
    for (final pose in [MascotPose.idle, MascotPose.calm, MascotPose.warning]) {
      expect(
        cheerful.any(pose.asset.contains),
        isFalse,
        reason:
            '"${pose.name}" đang dùng ${pose.asset} — một hình vui mừng ở '
            'trạng thái không có gì để mừng thì hình nói dối trước cả chữ',
      );
    }
  });
}
