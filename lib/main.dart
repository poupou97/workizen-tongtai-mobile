import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/design/tt.dart';
import 'core/l10n/language_notifier.dart';
import 'core/perf/startup_trace.dart';
import 'core/prefs.dart';
import 'core/telemetry/tongtai_telemetry.dart';
import 'features/tongtai/ui/tongtai_root_gate.dart';

/// Tổng Tài — AI-First Business OS (Workizen).
///
/// Standalone entrypoint created by the repo split (ADR-TON-001): the product
/// now ships from its own repository with applicationId com.workizen.tongtai.
/// Local-first · BYOK · privacy by default.
Future<void> main() async {
  StartupTrace.begin();
  WidgetsFlutterBinding.ensureInitialized();
  StartupTrace.mark('bindings');
  final prefs = await SharedPreferences.getInstance();
  StartupTrace.mark('prefs');
  // WTM-108 (D-7/ADR-TON-005): operational telemetry — Firebase only when the
  // Founder-provided config exists; the privacy-safe no-op otherwise.
  final telemetry = await initTongtaiTelemetry();
  StartupTrace.mark('telemetry-init');
  // Operational catalogue only (docs/05-OPERATIONS/TELEMETRY-EVENTS.md) —
  // events carry counts/flags, never business content.
  //
  // Deliberately NOT awaited (WTM-166): nobody needs to know the app opened
  // before it opens. Awaiting it cost ~8ms of launch on the measured device,
  // and made a slow telemetry backend able to hold up the first frame.
  // Firebase init above IS still awaited — Crashlytics has to be installed
  // before there is anything for it to miss.
  unawaited(telemetry.logEvent('app_open'));
  StartupTrace.mark('app-open-dispatched');
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tongtaiTelemetryProvider.overrideWithValue(telemetry),
      ],
      child: const TongtaiApp(),
    ),
  );
  StartupTrace.mark('run-app');
  // The frame the user first sees — scheduled from here so it is measured
  // once, not on every rebuild of some widget.
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => StartupTrace.mark('first-frame'),
  );
}

class TongtaiApp extends ConsumerWidget {
  const TongtaiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Tổng Tài',
      debugShowCheckedModeBanner: false,
      // ⭐ Hạt giống là **cam thương hiệu**, không phải xanh lá (WTM-375).
      //
      // Mọi widget Material không được tạo kiểu riêng — hộp thoại, công tắc,
      // ô đánh dấu, tay kéo chọn chữ, snackbar, nút mặc định — lấy màu từ hạt
      // giống này. Gieo bằng `producerGreen` nghĩa là **cả app ngầm nói "tốt /
      // thành công"** ở mọi chỗ chưa ai sơn tay, trong khi luật Design System
      // nói XANH LÁ = KẾT QUẢ TÍCH CỰC và CAM = HÀNH ĐỘNG.
      //
      // Đây là lý do nút `Lưu` của màn Nguồn đầu vào trông khác bốn nút Lưu
      // còn lại: nó là nút *mặc định*, nên nó mang màu của hạt giống.
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: TtColors.brand),
      ),
      locale: kAppLocale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [kAppLocale],
      home: const TongtaiRootGate(),
    );
  }
}
