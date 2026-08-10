import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/finance/finance_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/journey/business_goal_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/predictive/rule_twin.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_capability_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_context_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_data_invalidation.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_finance_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_inventory_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_journey_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_orders_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_predictive_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_sample_provider.dart';
import 'package:tongtai/features/tongtai/sample/historical_data_generator.dart';

/// **WTM-149 device defect 1 — stale predictive screens after seeding or
/// removing sample data.**
///
/// Reproduced on a real device: More → "Load 12 months of sample data" → Revenue
/// forecast (12 months of history) → More → "Remove sample data" → Revenue
/// forecast **still showed the full 12-month forecast**. Only an app restart
/// cleared it. Home looked right purely by accident — it re-reads its
/// repositories in `initState`.
///
/// The cause is structural, not cosmetic: `revenueCapabilityProvider`,
/// `customerCapabilityProvider`, `revenueForecastProvider`,
/// `customerRiskProvider`, `businessAlertsProvider` and
/// `generatedOpportunitiesProvider` are non-auto-dispose `FutureProvider`s, so
/// their first value is cached for the life of the process. It breaks the
/// Founder's cross-screen contract (Summary Count == Domain Visible Records)
/// and the "resetting sample data is safe and observable" gate.
///
/// This suite pins the fix from both ends:
///
/// 1. **Behaviour** — the PRODUCTION provider graph over in-memory
///    repositories: prime the cache, mutate the data through the real seeders,
///    and prove the cached answer is stale until
///    `invalidateBusinessDataProviders` runs, then correct afterwards.
/// 2. **Structure** — every mutation of the business data in
///    `lib/features/tongtai/ui/` must be followed by that one call, and every
///    cached read of the business data must be in its list. A future handler
///    (or a future provider) that forgets fails here instead of on a device.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ══ 1 · Behaviour ═══════════════════════════════════════════════════════════

  group('production provider graph', () {
    late InMemoryCustomerRepository customers;
    late InMemoryProductRepository products;
    late InMemoryOrderRepository orders;
    late InMemoryBusinessGoalRepository goals;
    late InMemoryFinanceRepository finance;

    /// The PRODUCTION wiring — the real `sampleDataSeederProvider`,
    /// `historicalDataSeederProvider`, capability providers and Rule Twins, with
    /// only the repository seams swapped for in-memory ones (the same override
    /// set the existing predictive provider tests use).
    ProviderContainer container() {
      customers = InMemoryCustomerRepository();
      products = InMemoryProductRepository();
      orders = InMemoryOrderRepository();
      goals = InMemoryBusinessGoalRepository();
      finance = InMemoryFinanceRepository();
      final c = ProviderContainer(
        overrides: [
          customerRepositoryProvider.overrideWithValue(customers),
          productRepositoryProvider.overrideWithValue(products),
          orderRepositoryProvider.overrideWithValue(orders),
          businessGoalRepositoryProvider.overrideWithValue(goals),
          financeRepositoryProvider.overrideWithValue(finance),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    /// 12 months ending with the current month — what the More screen's "Load 12
    /// months of sample data" seeds.
    const spec = HistoricalDataSpec();

    test(
      'seed → the forecast is STALE until the helper runs, then correct',
      () async {
        final c = container();

        // 1. Prime the cache on an empty business: an honest refusal.
        final before = await c.read(revenueForecastProvider.future);
        expect(before.result, isNull);
        expect(before.sufficiency, DataSufficiency.insufficient);

        // 2. Seed 12 months through the REAL seeder — the repositories now hold
        //    hundreds of orders.
        await c.read(historicalDataSeederProvider).seed(spec);
        expect(await orders.loadAll(), isNotEmpty);

        // 3. The defect, pinned: the cached FutureProvider still answers with
        //    the pre-seed refusal. This is what the device showed.
        final stale = await c.read(revenueForecastProvider.future);
        expect(
          stale.result,
          isNull,
          reason:
              'FutureProvider giữ nguyên giá trị đã cache — đây chính là lỗi, '
              'nên bước tiếp theo BẮT BUỘC phải invalidate',
        );

        // 4. The fix.
        invalidateBusinessDataProvidersIn(c);
        final after = await c.read(revenueForecastProvider.future);

        expect(after.result, isNotNull);
        expect(after.sufficiency, isNot(DataSufficiency.insufficient));
        expect(after.result!.nextMonthRevenue, greaterThan(0));
        expect(after.result!.basis.length, greaterThanOrEqualTo(6));
        // The value genuinely CHANGED, not merely "is also non-null".
        expect(after.sufficiency, isNot(before.sufficiency));
      },
    );

    test('removeAll → the forecast returns to an honest refusal', () async {
      final c = container();

      await c.read(historicalDataSeederProvider).seed(spec);
      invalidateBusinessDataProvidersIn(c);
      final seeded = await c.read(revenueForecastProvider.future);
      expect(seeded.result, isNotNull);

      // "Xóa dữ liệu mẫu" — every sample row goes.
      await c.read(sampleDataSeederProvider).removeAll();
      expect(await orders.loadAll(), isEmpty);

      // Still stale without the helper …
      expect(
        (await c.read(revenueForecastProvider.future)).result,
        isNotNull,
        reason: 'chưa invalidate thì màn hình dự báo vẫn giữ 12 tháng cũ',
      );

      // … and honest with it.
      invalidateBusinessDataProvidersIn(c);
      final cleared = await c.read(revenueForecastProvider.future);
      expect(cleared.result, isNull);
      expect(cleared.sufficiency, DataSufficiency.insufficient);
      expect(cleared.reasonCodes, contains(ReasonCode.notEnoughHistory));
    });

    test('the whole cached surface refreshes together — capabilities, risk, '
        'alerts and opportunities', () async {
      final c = container();

      // Prime every cached read on the empty business.
      final revenueBefore = await c.read(revenueCapabilityProvider.future);
      final customersBefore = await c.read(customerCapabilityProvider.future);
      final riskBefore = await c.read(customerRiskProvider.future);
      final alertsBefore = await c.read(businessAlertsProvider.future);
      final opportunitiesBefore = await c.read(
        generatedOpportunitiesProvider.future,
      );
      expect(customersBefore.profiles, isEmpty);
      expect(riskBefore.result, isNull);
      expect(opportunitiesBefore, isEmpty);

      await c.read(historicalDataSeederProvider).seed(spec);
      invalidateBusinessDataProvidersIn(c);

      final revenueAfter = await c.read(revenueCapabilityProvider.future);
      final customersAfter = await c.read(customerCapabilityProvider.future);
      final riskAfter = await c.read(customerRiskProvider.future);
      final alertsAfter = await c.read(businessAlertsProvider.future);
      final opportunitiesAfter = await c.read(
        generatedOpportunitiesProvider.future,
      );

      // The window is a fixed number of month buckets either way — what
      // changes is what is IN them.
      expect(revenueBefore.totalRevenue, 0);
      expect(revenueBefore.monthsWithRevenue, 0);
      expect(revenueAfter.totalRevenue, greaterThan(0));
      expect(revenueAfter.monthsWithRevenue, greaterThanOrEqualTo(6));
      expect(customersAfter.profiles, isNotEmpty);
      expect(riskAfter.result, isNotNull);
      expect(riskAfter.result!.entries, isNotEmpty);
      // The generated history deliberately contains at-risk/churned customers
      // and short-stocked products, so alerts must appear where there were
      // none.
      expect(alertsBefore.result ?? const [], isEmpty);
      expect(alertsAfter.result, isNotNull);
      expect(alertsAfter.result!, isNotEmpty);
      expect(opportunitiesAfter, isNotEmpty);
    });

    test('the plain sample fixtures refresh the same way', () async {
      final c = container();
      expect(await c.read(generatedOpportunitiesProvider.future), isEmpty);

      await c.read(sampleDataSeederProvider).seed();
      invalidateBusinessDataProvidersIn(c);

      expect(
        (await c.read(customerCapabilityProvider.future)).profiles,
        isNotEmpty,
      );
      expect(await c.read(generatedOpportunitiesProvider.future), isNotEmpty);
    });
  });

  // ══ 2 · Structure ══════════════════════════════════════════════════════════

  group('governance', () {
    /// Source lines with `//` / `///` comment lines dropped, so a code example
    /// inside a doc comment can neither satisfy nor break these scans.
    List<String> codeLines(File file) => [
      for (final line in file.readAsLinesSync())
        if (!line.trimLeft().startsWith('//')) line,
    ];

    const helperCall = 'invalidateBusinessDataProviders(ref)';

    test('every seeder mutation in ui/ is followed by '
        'invalidateBusinessDataProviders(ref)', () {
      // `seed(...)` / `removeAll()` on a seeder — the only writes that can
      // change the whole business at once.
      final mutation = RegExp(r'\.(seed|removeAll)\(');
      final offenders = <String>[];
      var checked = 0;

      for (final file
          in Directory('lib/features/tongtai/ui')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final lines = codeLines(file);
        for (var i = 0; i < lines.length; i++) {
          if (!mutation.hasMatch(lines[i])) continue;
          if (!lines[i].contains('Seeder') &&
              !lines[i].contains('seeder') &&
              !lines[i].contains('HistoricalDataSpec')) {
            continue; // not a seeder call (e.g. a list `.removeAll()`)
          }
          checked++;
          // The invalidation must follow before the handler does anything
          // else with the (now stale) providers. The window is 20 lines, not
          // 6, because WTM-148 put the shared failure guard in between: the
          // mutation runs inside `runTongtaiAction`, the failure branch
          // returns early, and the invalidation happens on the success path.
          // That ordering is stricter than before — caches are no longer
          // dropped for a write that never landed.
          final window = lines
              .skip(i + 1)
              .take(20)
              .where((l) => l.contains(helperCall));
          if (window.isEmpty) {
            offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
          }
          // …and the mutation itself must be guarded, or a failed seed would
          // still vanish silently (ADR-TON-017).
          final guarded = lines
              .skip((i - 6).clamp(0, lines.length))
              .take(8)
              .any((l) => l.contains('runTongtaiAction'));
          if (!guarded) {
            offenders.add(
              '${file.path}:${i + 1}: ghi dữ liệu KHÔNG qua runTongtaiAction '
              '— lỗi sẽ biến mất im lặng (WTM-148)',
            );
          }
        }
      }

      expect(
        checked,
        greaterThanOrEqualTo(3),
        // WTM-343 gộp ba lối nạp mẫu làm một, nên More còn ×2 (nạp · xoá).
        reason:
            'quét phải tìm thấy các handler seed/remove thật (More ×2, '
            'Home ×1) — nếu không, chính bài test này đã hỏng',
      );
      expect(
        offenders,
        isEmpty,
        reason:
            'Mọi hành động ghi dữ liệu kinh doanh phải gọi '
            '$helperCall ngay sau đó (WTM-149 defect 1), nếu không các màn '
            'hình dự báo giữ số liệu cũ tới khi khởi động lại app:\n'
            '${offenders.join('\n')}',
      );
    });

    test('the More screen seed AND remove handlers both invalidate', () {
      final source = File(
        'lib/features/tongtai/ui/screens/tongtai_more_screen.dart',
      );
      final lines = codeLines(source);

      /// The body of `_name`, from its signature to the next member.
      List<String> bodyOf(String name) {
        final start = lines.indexWhere((l) => l.contains('$name(BuildContext'));
        expect(start, isNot(-1), reason: 'không tìm thấy handler $name');
        final rest = lines.skip(start + 1).toList();
        final end = rest.indexWhere(
          (l) => l.startsWith('  Future<') || l.startsWith('  @override'),
        );
        return end < 0 ? rest : rest.take(end).toList();
      }

      // WTM-343: `_seedHistory` không còn — một lối nạp mẫu duy nhất.
      for (final handler in const ['_seedSamples', '_removeSamples']) {
        expect(
          bodyOf(handler).any((l) => l.contains(helperCall)),
          isTrue,
          reason:
              '$handler đổi dữ liệu kinh doanh nên phải gọi $helperCall '
              '(WTM-149 defect 1)',
        );
      }
    });

    test('every cached FutureProvider over business data is in '
        'kBusinessDataProviders', () {
      /// Cached reads that are deliberately NOT invalidated — see the doc on
      /// [kBusinessDataProviders]. Sample data cannot change either of them.
      const allowlist = {
        'tongtaiUserIdProvider', // install identity
        'tongtaiHasAiKeyProvider', // BYOK key presence
        // WTM-317: đọc danh sách file trên **Drive**, không đọc DB. Gieo hay
        // xoá dữ liệu mẫu không đổi được thứ đang nằm trên Drive của người
        // bán. Nó được làm mới bởi chính hành động sinh ra file mới
        // (`backupNow` → `ref.invalidate`), đúng nhịp của nó.
        'driveBackupListProvider',
        // WTM-318: hỏi Keystore *đã có token và nơi nhận chưa*, không hỏi DB.
        // Nó được làm mới bởi chính các bước thiết lập Telegram, đúng nhịp
        // của nó — gieo/xoá dữ liệu mẫu không đổi được câu trả lời.
        'telegramReadyProvider',
        // WTM-319: ba cái này đọc **Atlassian**, không đọc DB nghiệp vụ. Gieo
        // hay xoá dữ liệu mẫu của Tổng Tài không đổi được issue trong Jira.
        // Chúng được làm mới bởi chính các bước chọn dự án/space.
        'workContextProvider',
        'knowledgeReferencesProvider',
        'atlassianReadyProvider',
        // WTM-329: `family` theo sản phẩm — mở màn nào thì đọc màn đó, và nó
        // được `ref.watch` lại mỗi lần mở. Đưa vào `kBusinessDataProviders`
        // sẽ phải liệt kê từng sản phẩm một, tức là không đưa được.
        'supplierComparisonProvider',
        // WTM-339: `family` theo khách. Nó `ref.watch`
        // `customerConversationsProvider.future` — cái đã nằm trong
        // `kBusinessDataProviders` — nên làm mới cái cha là làm mới cả họ.
        // Liệt kê từng khách một thì không liệt kê được.
        'customerConversationProvider',
        // WTM-347: `family` theo khách — gợi ý mua kèm chỉ đọc khi mở đúng màn
        // khách đó. Liệt kê từng khách một thì không liệt kê được.
        'customerSuggestionsProvider',
      };

      final declaration = RegExp(r'^final (\w+) = FutureProvider');
      final discovered = <String>{};
      for (final file in Directory(
        'lib/features/tongtai/providers',
      ).listSync().whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        for (final line in codeLines(file)) {
          final match = declaration.firstMatch(line);
          if (match != null) discovered.add(match.group(1)!);
        }
      }
      // Multi-line declarations (`final x =\n    FutureProvider<…>`) — catch
      // them too, so formatting can never hide a provider from this scan.
      for (final file in Directory(
        'lib/features/tongtai/providers',
      ).listSync().whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        final source = codeLines(file).join('\n');
        for (final match in RegExp(
          r'final (\w+)\s*=\s*\n?\s*FutureProvider',
        ).allMatches(source)) {
          discovered.add(match.group(1)!);
        }
      }

      expect(
        discovered.length,
        greaterThanOrEqualTo(8),
        reason: 'quét phải thấy toàn bộ FutureProvider hiện có',
      );

      final mustInvalidate = discovered.difference(allowlist);
      final listSource = File(
        'lib/features/tongtai/providers/tongtai_data_invalidation.dart',
      ).readAsStringSync();
      // The array literal only — a name mentioned in the doc comment above it
      // must not count as "handled".
      final arrayStart = listSource.indexOf('kBusinessDataProviders =');
      final array = listSource.substring(
        arrayStart,
        listSource.indexOf('];', arrayStart),
      );

      final missing = [
        for (final name in mustInvalidate)
          if (!array.contains('$name,')) name,
      ];
      expect(
        missing,
        isEmpty,
        reason:
            'FutureProvider mới đọc dữ liệu kinh doanh phải được thêm vào '
            'kBusinessDataProviders (hoặc vào allowlist kèm lý do), nếu '
            'không nó sẽ phục vụ dữ liệu cũ sau khi seed/xóa mẫu: $missing',
      );
      // …and the runtime list must actually hold them, not just mention them.
      expect(kBusinessDataProviders, hasLength(mustInvalidate.length));
    });
  });
}
