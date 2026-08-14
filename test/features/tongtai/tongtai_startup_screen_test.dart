// Màn khởi động — WTM-367, dựng lại theo nhận diện mới ở WTM-416.
//
// Màn này chạy TRƯỚC mọi thứ khác, nên nó cũng là màn hỏng âm thầm nhất: nếu
// một asset không vào bundle hoặc bố cục tràn ở máy nhỏ, người dùng thấy ngay
// giây đầu tiên mà không suite nào kêu — trước WTM-416 nó **không có một test
// nào**.
//
// Ba điều được giữ ở đây, và cả ba đều là *nội dung*, không phải hình dáng:
//
//   §1 con số tiến trình là **bước thật đã xong**, không phải một đường cong
//      thời gian (cùng luật với `AnalysisPipeline`);
//   §2 asset nhận diện **thật sự nạp được** — tức là đã khai trong `pubspec`;
//   §3 màn không tràn ở 320px/1.3× — kích thước nhỏ nhất repo này cam kết.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/startup/startup_pipeline.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_startup_screen.dart';

Widget _host(Widget screen) => MaterialApp(
  locale: const Locale('vi'),
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en'), Locale('vi')],
  home: screen,
);

void main() {
  testWidgets('§1 tiến trình hiển thị đúng số bước THẬT đã xong', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const TongtaiStartupScreen(
          progress: [
            StartupProgress(step: StartupStep.database, done: 1, total: 4),
            StartupProgress(
              step: StartupStep.catalog,
              done: 2,
              total: 4,
              count: 100,
            ),
          ],
        ),
      ),
    );

    expect(find.text('2/4'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('startup-bar')),
    );
    expect(bar.value, 0.5);

    // Chỉ những chặng ĐÃ XONG mới có dòng. Không có dòng nào cho việc sắp làm —
    // đó là chỗ một con số có thể xuất hiện trước việc sinh ra nó.
    expect(find.byKey(const Key('startup-step-database')), findsOneWidget);
    expect(find.byKey(const Key('startup-step-catalog')), findsOneWidget);
    expect(find.byKey(const Key('startup-step-profile')), findsNothing);
  });

  testWidgets('§2 asset nhận diện nạp được thật (không chỉ có trên đĩa)', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const TongtaiStartupScreen(progress: [])));

    final assets = tester
        .widgetList<Image>(find.byType(Image))
        .map((w) => (w.image as AssetImage).assetName)
        .toSet();
    expect(assets, contains('assets/startup/logo_lockup.png'));
    expect(assets, contains('assets/startup/startup_mascot.png'));

    // ⚠️ Phần quan trọng: `Image.asset` KHÔNG ném lỗi khi thiếu khai báo trong
    // `pubspec` — nó chỉ vẽ ô trống. Nạp thẳng qua bundle mới phân biệt được
    // "có tệp trên đĩa" với "có tệp trong APK".
    for (final name in assets) {
      expect(
        (await rootBundle.load(name)).lengthInBytes,
        greaterThan(0),
        reason: '$name không có trong bundle — thiếu khai trong pubspec.yaml',
      );
    }
  });

  testWidgets('§3 không tràn ở 320px/1.3× — máy nhỏ nhất được cam kết', (
    tester,
  ) async {
    final overflows = <String>[];
    final prior = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        overflows.add(details.exceptionAsString());
      } else {
        prior?.call(details);
      }
    };
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: _host(
          const TongtaiStartupScreen(
            progress: [
              StartupProgress(step: StartupStep.database, done: 1, total: 4),
            ],
          ),
        ),
      ),
    );

    // ⚠️ Trả `onError` về TRƯỚC khi `expect`. Đảo thứ tự thì chính lần expect
    // thất bại lại rơi vào cái bẫy mình vừa đặt, và thông báo lỗi nói về
    // FlutterError chứ không nói về tràn bố cục.
    FlutterError.onError = prior;
    expect(overflows, isEmpty, reason: overflows.join('\n'));
  });
}
