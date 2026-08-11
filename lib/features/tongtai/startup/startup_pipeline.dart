/// **Khởi động Tổng Tài** — WTM-367 (Epic WTM-362).
///
/// Tham chiếu thị giác: `docs/01-PRODUCT/concept-1/screen-startup.png`.
///
/// ## ⛔ Hai chỗ concept vẽ sai, và không được chép
///
/// **1 · "68%" là tiến trình giả.** Một thanh chạy theo `Duration` cố định bị
/// cấm ở §16 lẫn §21, và nó là cùng cám dỗ đã phải chặn ở `AnalysisPipeline`
/// (WTM-353). Phần trăm ở đây chỉ hợp lệ vì nó là **số bước THẬT đã xong / tổng
/// số bước THẬT** — và danh sách bước là [StartupStep], một enum, nên nó không
/// co giãn theo ý muốn của màn hình.
///
/// **2 · "Đang kiểm tra dữ liệu và các mô hình AI" — sai sự thật.** App **không
/// tải mô hình AI nào** lúc khởi động: chế độ BYOK gọi thẳng nhà cung cấp vào
/// lúc người bán hỏi, và bản demo không gọi gì cả. Câu chữ phải nói đúng việc
/// đang làm, nếu không màn khởi động thành quảng cáo cho một năng lực không
/// chạy.
///
/// ## Vì sao các bước này, và chỉ các bước này
///
/// Mỗi bước là việc **dù sao cũng phải xảy ra** trước khi Trang chủ vẽ được.
/// Không có bước nào thêm vào để thanh dài hơn:
///
/// * mở CSDL — chạy migration, và đây là phần chậm nhất khi lên phiên bản;
/// * đọc cờ onboarding — quyết định đi tới màn nào;
/// * đếm danh mục và đơn hàng — Trang chủ cần ngay, làm ở đây thì nó khỏi quay.
///
/// ## Nhanh quá thì đừng nháy
///
/// Một màn loading chớp qua tệ hơn không có màn nào. [StartupRun.tookLongEnough]
/// cho màn hình biết có đáng hiện không.
library;

import 'package:flutter/foundation.dart';

/// Một bước khởi động thật.
///
/// Enum chứ không phải danh sách chuỗi: thêm một bước là sửa ở đây, và trình
/// biên dịch chỉ ra mọi chỗ phải cập nhật — kể cả bảng phần trăm.
enum StartupStep {
  /// Mở CSDL và chạy migration nếu có.
  database('database'),

  /// Đọc cờ *"đã onboard chưa"*.
  profile('profile'),

  /// Đếm danh mục — con số Trang chủ cần ngay.
  catalog('catalog'),

  /// Đếm đơn hàng.
  orders('orders');

  const StartupStep(this.code);

  final String code;
}

/// Một bước **đã xong**, kèm số bản ghi thật nếu bước ấy đếm được gì.
@immutable
class StartupProgress {
  const StartupProgress({
    required this.step,
    required this.done,
    required this.total,
    this.count,
  });

  final StartupStep step;

  /// Đã xong bao nhiêu bước, trên tổng bao nhiêu.
  final int done;
  final int total;

  /// Số bản ghi bước này vừa đọc. `null` khi bước không đếm gì (mở CSDL, đọc
  /// cờ) — và khi đó màn hình **không** được bịa ra một con số cho đẹp.
  final int? count;

  /// 0..1. Là tỉ lệ **bước thật**, không phải một đường cong thời gian.
  double get fraction => done / total;
}

/// Kết quả khởi động.
@immutable
class StartupRun {
  const StartupRun({
    required this.steps,
    required this.elapsed,
    required this.onboardingCompleted,
  });

  final List<StartupProgress> steps;
  final Duration elapsed;

  /// Cổng vào: đã onboard thì vào thẳng shell.
  final bool onboardingCompleted;

  /// Khởi động lâu hơn ngưỡng này thì màn khởi động mới đáng hiện.
  ///
  /// 400ms: dưới mức đó, người dùng chỉ thấy một cái nháy — và một cái nháy
  /// làm app trông giật, tức là màn "trấn an" lại thành thứ gây lo.
  static const Duration visibleThreshold = Duration(milliseconds: 400);

  bool get tookLongEnough => elapsed >= visibleThreshold;

  int? countOf(StartupStep step) =>
      steps.where((s) => s.step == step).map((s) => s.count).firstOrNull;
}

/// Nơi pipeline lấy dữ liệu. Màn hình không biết gì về repository.
abstract interface class StartupSource {
  /// Mở CSDL / chạy migration. Trả về khi CSDL sẵn sàng đọc.
  Future<void> openDatabase();

  Future<bool> loadOnboardingCompleted();

  Future<int> countProducts();

  Future<int> countOrders();
}

class StartupPipeline {
  const StartupPipeline({required this.source, required this.clock});

  final StartupSource source;

  /// Đồng hồ tiêm vào để test đo được thời gian mà không phải chờ thật.
  final Stopwatch Function() clock;

  /// Chạy. Phát tiến trình khi **mỗi bước xong**, không phải khi nó bắt đầu.
  ///
  /// Không `Future.delayed`, không `Duration` cố định: con số duy nhất trên màn
  /// là *bước đã xong / tổng bước*.
  Stream<StartupProgress> run({
    required void Function(StartupRun) onDone,
  }) async* {
    final watch = clock()..start();
    final total = StartupStep.values.length;
    final steps = <StartupProgress>[];
    var done = 0;

    StartupProgress step(StartupStep s, {int? count}) {
      done++;
      final p = StartupProgress(
        step: s,
        done: done,
        total: total,
        count: count,
      );
      steps.add(p);
      return p;
    }

    await source.openDatabase();
    yield step(StartupStep.database);

    final onboarded = await source.loadOnboardingCompleted();
    yield step(StartupStep.profile);

    yield step(StartupStep.catalog, count: await source.countProducts());
    yield step(StartupStep.orders, count: await source.countOrders());

    watch.stop();
    onDone(
      StartupRun(
        steps: List.unmodifiable(steps),
        elapsed: watch.elapsed,
        onboardingCompleted: onboarded,
      ),
    );
  }
}
