import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/startup/startup_pipeline.dart';

/// WTM-367 (DS5) — khởi động phải là **công việc thật**.
///
/// Cùng khuôn với `analysis_pipeline_test`: một thanh chạy theo `Duration` cố
/// định vẫn cho ĐÚNG số đếm, nên không test hành vi nào bắt được nó — chỉ có
/// quét mã nguồn.
void main() {
  group('mỗi bước phát tín hiệu SAU khi việc của nó xong', () {
    test('bốn bước, đúng thứ tự, đúng tỉ lệ', () async {
      final source = _FakeSource(products: 114, orders: 636, onboarded: true);
      StartupRun? run;

      final seen = await StartupPipeline(
        source: source,
        clock: Stopwatch.new,
      ).run(onDone: (r) => run = r).toList();

      expect(seen.map((p) => p.step), [
        StartupStep.database,
        StartupStep.profile,
        StartupStep.catalog,
        StartupStep.orders,
      ]);
      expect(seen.map((p) => p.done), [1, 2, 3, 4]);
      expect(seen.last.fraction, 1.0);
      expect(run, isNotNull);
      expect(run!.onboardingCompleted, isTrue);
    });

    test('số đếm là số THẬT, không phải số của ảnh concept', () async {
      final source = _FakeSource(products: 7, orders: 3, onboarded: false);
      StartupRun? run;
      await StartupPipeline(
        source: source,
        clock: Stopwatch.new,
      ).run(onDone: (r) => run = r).toList();

      expect(run!.countOf(StartupStep.catalog), 7);
      expect(run!.countOf(StartupStep.orders), 3);
      // Bước không đếm gì thì `count` là `null` — màn hình KHÔNG được bịa ra
      // một con số cho đẹp.
      expect(run!.countOf(StartupStep.database), isNull);
      expect(run!.countOf(StartupStep.profile), isNull);
    });

    test('mở CSDL chạy TRƯỚC mọi phép đếm', () async {
      // Đếm trước khi migration xong là đếm trên một schema có thể chưa tồn
      // tại — và trên máy vừa lên phiên bản thì đó là lỗi, không phải lý thuyết.
      final source = _FakeSource(products: 1, orders: 1, onboarded: false);
      await StartupPipeline(
        source: source,
        clock: Stopwatch.new,
      ).run(onDone: (_) {}).toList();

      expect(source.calls.first, 'openDatabase');
      expect(source.calls, [
        'openDatabase',
        'onboarding',
        'products',
        'orders',
      ]);
    });

    test('máy trống ⇒ đếm 0, vẫn đi tới cùng', () async {
      StartupRun? run;
      await StartupPipeline(
        source: _FakeSource(products: 0, orders: 0, onboarded: false),
        clock: Stopwatch.new,
      ).run(onDone: (r) => run = r).toList();

      expect(run!.countOf(StartupStep.catalog), 0);
      expect(run!.steps, hasLength(4));
    });
  });

  group('⭐ một bước hỏng KHÔNG kéo theo cả lượt khởi động', () {
    test('CSDL hỏng ⇒ vẫn chạy nốt ba bước còn lại', () async {
      StartupRun? run;
      final seen = await StartupPipeline(
        source: _FakeSource(
          products: 5,
          orders: 2,
          onboarded: true,
          failOn: 'openDatabase',
        ),
        clock: Stopwatch.new,
      ).run(onDone: (r) => run = r).toList();

      expect(seen, hasLength(4));
      expect(seen.first.failed, isTrue);
      // Hâm nóng hỏng không được nhốt người dùng: repository vẫn tự mở CSDL
      // khi màn hình đọc, nên đi tiếp là an toàn.
      expect(run, isNotNull);
    });

    test('⭐ bước hỏng KHÔNG khai một con số', () async {
      StartupRun? run;
      await StartupPipeline(
        source: _FakeSource(
          products: 5,
          orders: 2,
          onboarded: true,
          failOn: 'products',
        ),
        clock: Stopwatch.new,
      ).run(onDone: (r) => run = r).toList();

      // "Đọc được 0 sản phẩm" và "không đọc được" là hai câu khác nhau —
      // `count` phải là `null`, không phải 0.
      expect(run!.countOf(StartupStep.catalog), isNull);
      final catalog = run!.steps.firstWhere(
        (s) => s.step == StartupStep.catalog,
      );
      expect(catalog.failed, isTrue);
      // Bước sau nó vẫn chạy và vẫn đếm được.
      expect(run!.countOf(StartupStep.orders), 2);
    });

    test('pipeline không bao giờ ném ra ngoài', () async {
      await expectLater(
        StartupPipeline(
          source: _FakeSource(
            products: 1,
            orders: 1,
            onboarded: false,
            failOn: 'orders',
          ),
          clock: Stopwatch.new,
        ).run(onDone: (_) {}).toList(),
        completes,
      );
    });
  });

  group('⭐ nhanh quá thì đừng nháy', () {
    test('ngưỡng hiện màn là 400ms', () {
      expect(StartupRun.visibleThreshold.inMilliseconds, 400);
    });

    test('khởi động chớp nhoáng ⇒ tookLongEnough = false', () {
      const fast = StartupRun(
        steps: [],
        elapsed: Duration(milliseconds: 80),
        onboardingCompleted: true,
      );
      // Một màn loading chớp qua làm app trông giật — thứ để trấn an lại thành
      // thứ gây lo.
      expect(fast.tookLongEnough, isFalse);

      const slow = StartupRun(
        steps: [],
        elapsed: Duration(milliseconds: 900),
        onboardingCompleted: true,
      );
      expect(slow.tookLongEnough, isTrue);
    });
  });

  group('⛔ governance · khởi động không được là sân khấu', () {
    late String code;

    setUpAll(() {
      code = File('lib/features/tongtai/startup/startup_pipeline.dart')
          .readAsLinesSync()
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
    });

    test('đọc được mã nguồn (chống PASS giả)', () {
      expect(code, contains('class StartupPipeline'));
      expect(code, contains('openDatabase'));
    });

    test('không Future.delayed trong pipeline', () {
      expect(code.contains('Future.delayed'), isFalse);
    });

    test(
      '⭐ Duration DUY NHẤT là ngưỡng hiện màn, không phải nhịp tiến trình',
      () {
        // Không cấm sạch `Duration(`: `visibleThreshold` là một ngưỡng giao diện
        // hợp lệ. Cấm sạch sẽ buộc người sau phải nới luật, và một luật đã nới
        // một lần thì lần sau nới dễ hơn.
        //
        // Nên luật siết đúng chỗ: trong file này được phép có **đúng một**
        // `Duration(`, và nó phải là dòng khai `visibleThreshold`. Bất kỳ
        // `Duration` thứ hai nào cũng là nhịp thời gian lẻn vào.
        final lines = code
            .split('\n')
            .where((l) => l.contains('Duration('))
            .toList();

        expect(lines, hasLength(1), reason: lines.join(' | '));
        expect(lines.single, contains('visibleThreshold'));
      },
    );

    test('⭐ màn khởi động không có Duration nào', () {
      // Concept vẽ một thanh đứng ở 68%. Con số duy nhất hợp lệ là *bước thật
      // đã xong / tổng bước thật*, và nó không cần đồng hồ nào cả.
      final screen =
          File('lib/features/tongtai/ui/screens/tongtai_startup_screen.dart')
              .readAsLinesSync()
              .where(
                (l) =>
                    !l.trimLeft().startsWith('//') &&
                    !l.trimLeft().startsWith('///'),
              )
              .join('\n');

      expect(screen.contains('Future.delayed'), isFalse);
      expect(screen.contains('Duration('), isFalse);
      // Và không có con số phần trăm nào viết cứng.
      for (final fake in const ['68%', '0.68', 'percent = ']) {
        expect(screen.contains(fake), isFalse, reason: fake);
      }
    });

    test('⛔ không hứa tải mô hình AI lúc khởi động', () {
      // App không tải mô hình nào: BYOK gọi thẳng nhà cung cấp lúc người bán
      // hỏi. Concept viết "đang kiểm tra dữ liệu và các mô hình AI" — nói thế
      // là quảng cáo cho một năng lực không chạy.
      final strings = File('lib/core/l10n/app_strings.dart').readAsStringSync();
      final startupBlock = strings.substring(
        strings.indexOf('startupStep(String stepCode'),
      );
      final vi = startupBlock.substring(0, startupBlock.length.clamp(0, 4000));
      expect(vi.contains('mô hình AI'), isFalse);
      expect(vi.contains('AI model'), isFalse);
    });
  });
}

class _FakeSource implements StartupSource {
  _FakeSource({
    required this.products,
    required this.orders,
    required this.onboarded,
    this.failOn,
  });

  final int products;
  final int orders;
  final bool onboarded;

  /// Tên bước sẽ ném lỗi — để đo hành vi khi một bước hỏng.
  final String? failOn;

  final List<String> calls = [];

  void _maybeThrow(String step) {
    calls.add(step);
    if (failOn == step) throw StateError('hỏng ở $step');
  }

  @override
  Future<void> openDatabase() async => _maybeThrow('openDatabase');

  @override
  Future<bool> loadOnboardingCompleted() async {
    _maybeThrow('onboarding');
    return onboarded;
  }

  @override
  Future<int> countProducts() async {
    _maybeThrow('products');
    return products;
  }

  @override
  Future<int> countOrders() async {
    _maybeThrow('orders');
    return orders;
  }
}
