import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/prefs.dart' show sharedPreferencesProvider;
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tongtai_more_action.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/tongtai.dart';
import 'package:tongtai/main.dart' show TongtaiApp;

import '../../support/tap_by_key.dart';

/// App-level boot tests (WTM-105).
///
/// The repo split rewired `main.dart` straight to [TongtaiAppShell], bypassing
/// [TongtaiRootGate] — so a fresh install never saw the WTM-59 tutorial even
/// though the gate itself was fully unit-tested. These tests pump the real app
/// widget ([TongtaiApp], exactly what `main()` runs) over the production
/// SharedPreferences-backed store, so the wiring itself is what's under test:
///  - AC2: first launch (no flag) boots into the tutorial
///  - AC3: finishing or skipping the tutorial reveals the shell + persists
///  - AC4: a later launch with the flag set boots straight to the shell
///  - end-to-end: the More screen "Replay Tutorial" action shows the tutorial
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> bootPrefs(Map<String, Object> seed) {
    SharedPreferences.setMockInitialValues(seed);
    return SharedPreferences.getInstance();
  }

  // Mirrors main(): prefs is overridden as in production. The Drift database is
  // also overridden with an in-memory one so the Home dashboard's real
  // repository load (WTM-128) stays off the file-system (path_provider is
  // unavailable under `flutter test`); everything else is the production path.
  Widget app(SharedPreferences prefs) => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      tongtaiDatabaseProvider.overrideWithValue(
        AppDatabase.forExecutor(NativeDatabase.memory()),
      ),
    ],
    child: const TongtaiApp(),
  );

  // WTM-178: sáu slide → hội thoại. Epic WTM-349: hội thoại → Onboarding V2.
  // Acceptance criteria KHÔNG đổi qua cả hai lần — lần đầu mở app thấy
  // onboarding, đi hết thì thấy shell và cờ được lưu — nên finder được trỏ lại
  // chứ test không bị viết lại. Đó cũng là lý do file này vẫn có giá trị: nó đo
  // hợp đồng của app, không đo cách một màn được vẽ.
  Finder tutorial() => find.byKey(const Key('onboarding-v2-welcome'));
  Finder appShell() => find.byType(TongtaiBottomNav);

  testWidgets('AC2: first launch (no flag) boots into the tutorial', (
    tester,
  ) async {
    final prefs = await bootPrefs({});
    await tester.pumpWidget(app(prefs));
    await tester.pumpAndSettle();

    expect(tutorial(), findsOneWidget);
    expect(appShell(), findsNothing);
  });

  testWidgets('AC3: finishing the tutorial reveals the shell and persists', (
    tester,
  ) async {
    final prefs = await bootPrefs({});
    await tester.pumpWidget(app(prefs));
    await tester.pumpAndSettle();

    // Đường ngắn nhất qua V2: bắt đầu → bỏ qua hồ sơ → "chưa có dữ liệu" →
    // mục tiêu → xong. Người vội vẫn đi qua cửa dữ liệu, vì đó là chỗ rẽ quyết
    // định họ nhận được gì chứ không phải một bước thủ tục.
    await tester.tap(find.byKey(const Key('onboarding-v2-start')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-v2-profile-skip-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-v2-data-none')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-v2-goal-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-v2-finish')));
    await tester.pumpAndSettle();

    expect(tutorial(), findsNothing);
    expect(appShell(), findsOneWidget);
    expect(prefs.getBool(TongtaiOnboardingStore.storageKey), isTrue);
  });

  testWidgets('AC3: đường ngắn nhất vẫn kết thúc bằng một kế hoạch', (
    tester,
  ) async {
    final prefs = await bootPrefs({});
    await tester.pumpWidget(app(prefs));
    await tester.pumpAndSettle();

    // V1 có lối "bỏ qua tất cả" một chạm từ màn chào. V2 bỏ nó có chủ ý: lối
    // đó thả người bán vào một ứng dụng TRỐNG, tức là đúng vấn đề Epic
    // WTM-349 sinh ra để sửa. Đường nhanh nhất nay đi qua cửa dữ liệu và kết
    // thúc bằng kế hoạch khởi đầu — dài hơn ba chạm, và ba chạm đó là toàn bộ
    // giá trị người bán nhận được.
    await tester.tap(find.byKey(const Key('onboarding-v2-start')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-v2-profile-skip-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-v2-data-none')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-v2-goal-next')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-v2-plan')), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-v2-finish')));
    await tester.pumpAndSettle();

    expect(tutorial(), findsNothing);
    expect(appShell(), findsOneWidget);
    expect(prefs.getBool(TongtaiOnboardingStore.storageKey), isTrue);
  });

  testWidgets('AC4: a later launch with the flag set skips the tutorial', (
    tester,
  ) async {
    final prefs = await bootPrefs({TongtaiOnboardingStore.storageKey: true});
    await tester.pumpWidget(app(prefs));
    await tester.pumpAndSettle();

    expect(tutorial(), findsNothing);
    expect(appShell(), findsOneWidget);
  });

  testWidgets('end-to-end: More → "Replay Tutorial" brings the tutorial back', (
    tester,
  ) async {
    final prefs = await bootPrefs({TongtaiOnboardingStore.storageKey: true});
    await tester.pumpWidget(app(prefs));
    await tester.pumpAndSettle();
    expect(appShell(), findsOneWidget);

    // Open More — it left the bottom bar in WTM-192 and now lives in the
    // AppBar — then trigger the replay action that was a no-op for users while
    // the gate was unwired.
    await tester.tap(find.byKey(TongtaiMoreAction.actionKey));
    await tester.pumpAndSettle();
    await tester.tapByKey(
      'more-replay-tutorial',
      scrollableUnder: 'more-scroll',
    );

    expect(tutorial(), findsOneWidget);
    expect(appShell(), findsNothing);
    expect(prefs.getBool(TongtaiOnboardingStore.storageKey), isNull);
  });
}
