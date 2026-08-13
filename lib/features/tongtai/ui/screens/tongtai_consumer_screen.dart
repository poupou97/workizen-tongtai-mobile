import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';

import '../../providers/tongtai_orders_provider.dart';
import '../../analytics/customer_rfm.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../consumer/customer.dart';
import '../../consumer/customer_segment.dart';
import '../../core/screen_data_controller.dart';
import '../../core/tongtai_formatters.dart';
import '../../providers/tongtai_consumer_provider.dart';
import '../../providers/tongtai_data_invalidation.dart';
import '../widgets/tongtai_screen_data.dart';
import '../widgets/tongtai_screen_header.dart';
import 'tongtai_customer_list_screen.dart';

/// Consumer/Customer Intelligence tab for Tổng Tài (WTM-26).
///
/// P0 correction 2026-07-30: this screen previously was a static design shell
/// that read NO data — the bottom-nav Consumer tab showed zeros while Home
/// counted real customers (Founder repro: Home Consumer = 1, tab empty).
/// It now derives EVERYTHING from the same [customerRepositoryProvider] that
/// Home's BusinessContext counts, so the two can never disagree
/// (Single Source of Truth — locked by p0/count_list_contract_test.dart).
class TongtaiConsumerScreen extends ConsumerStatefulWidget {
  const TongtaiConsumerScreen({super.key, this.clock});

  /// Injectable clock for the "active in the last 90 days" segment.
  final DateTime Function()? clock;

  @override
  ConsumerState<TongtaiConsumerScreen> createState() =>
      _TongtaiConsumerScreenState();
}

class _TongtaiConsumerScreenState extends ConsumerState<TongtaiConsumerScreen> {
  // ⛔ WTM-407 — hằng `_blue = TtColors.info` đã bị **xoá**, không chỉ thôi
  // dùng.
  //
  // Nó là cái bình đựng sẵn: chừng nào còn một hằng tên "_blue" trong màn này,
  // con số tiếp theo ai đó thêm vào sẽ được tô bằng nó — và luật A2 lại thủng ở
  // đúng chỗ vừa vá. Màu định vị của Khách hàng nay chỉ sống ở thanh nav, nơi
  // nó làm đúng việc của mình: chỉ đường, không phán xét.

  late final DateTime Function() _clock;

  /// The screen's single data path (WTM-148): a throwing repository now
  /// becomes a visible, retryable failure instead of an empty tab that looks
  /// exactly like "you have no customers".
  late final ScreenDataController<List<Customer>> _data;

  @override
  void initState() {
    super.initState();
    _clock = widget.clock ?? DateTime.now;
    _data = ScreenDataController<List<Customer>>(
      // WTM-201: counters derived from real orders. Reading the stored
      // `orderCount`/`totalSpent` showed "0 đơn · ₫0" for a customer who had
      // just bought something — nothing writes those fields when an order is
      // recorded, while RFM, Reports and the lifecycle ladder all count it.
      () async => deriveCustomerCounters(
        await ref.read(customerRepositoryProvider).loadAll(),
        await ref.read(orderRepositoryProvider).loadAll(),
        now: _clock(),
      ),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'consumer',
    )..load();
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  Future<void> _openList() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const TongtaiCustomerListScreen()),
    );
    // The user may have created/edited/deleted customers in the list — refresh
    // (not reload) so the tab stays consistent without blanking on the way.
    await _data.refresh();
  }

  bool _isActive(Customer c) {
    final last = c.lastPurchaseDate;
    return last != null && _clock().difference(last).inDays <= 90;
  }

  @override
  Widget build(BuildContext context) {
    // The business data can change from another screen (restore a backup, seed
    // or remove sample data). This screen is kept alive by the shell's
    // IndexedStack, so its `initState` load never runs again — without this it
    // would keep rendering a business that no longer exists (WTM-174).
    ref.listen(businessDataRevisionProvider, (_, _) => _data.refresh());
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: tongtaiScreenHeader(
        context,
        screen: 'consumer',
        title: l10n.titleConsumerIntelligence,
        subtitle: tongtaiScreenSubtitle(context.l10n, 'consumer'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListenableBuilder(
        listenable: _data,
        builder: (context, _) => TongtaiScreenData<List<Customer>>(
          prefix: 'consumer',
          state: _data.state,
          onRetry: _data.retry,
          builder: _body,
        ),
      ),
    );
  }

  Widget _body(BuildContext context, List<Customer> customers) {
    final l10n = context.l10n;
    final total = customers.length;
    final vip = customers.where((c) => c.tier == CustomerTier.vip).length;
    final active = customers.where(_isActive).length;
    final fresh = customers.where((c) => c.orderCount == 0).length;

    // ⚠️ WTM-381: gộp theo phân khúc **đã phân giải**, không theo chuỗi thô.
    //
    // Trước đây khoá của bảng đếm là chính chuỗi lưu trong `segments`, mà chuỗi
    // ấy có hai nguồn ghi bằng hai hệ đặt tên — nên *"Khách mới"* và *"new"*
    // thành hai dòng, với hai con số. Người bán không biết mình có 6 hay 8
    // khách mới.
    //
    // Khoá nay là mã canonical (hoặc chính chuỗi người dùng tự đặt, khi không
    // phân giải được), nên một phân khúc chỉ còn **một** chip và **một** số.
    final segmentTally = <String, int>{};
    for (final c in customers) {
      for (final s in c.segments) {
        if (s.trim().isEmpty) continue;
        final key = CustomerSegment.normalise(s);
        segmentTally[key] = (segmentTally[key] ?? 0) + 1;
      }
    }

    final recent = customers.where((c) => c.lastPurchaseDate != null).toList()
      ..sort((a, b) => b.lastPurchaseDate!.compareTo(a.lastPurchaseDate!));
    final interactions = recent.take(5).toList();

    final purchased = customers.where((c) => c.orderCount >= 1).length;
    final retained = customers.where((c) => c.orderCount >= 2).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card — count badge MUST equal Home's Consumer tile
          // (both read customerRepository; contract-tested).
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // The count badge is fixed width; the title is the part
                      // that has to give way on a 320 px phone (WTM-169).
                      Expanded(
                        child: Text(
                          l10n.titleCustomers,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        // WTM-407 — huy hiệu đếm thôi mặc màu năng lực. Một
                        // viên xanh dương đặc chứa con số đọc như một trạng
                        // thái INFO; nó chỉ là **tổng số khách**.
                        decoration: BoxDecoration(
                          color: TtColors.surfaceTertiary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$total',
                          key: const Key('consumer-count-badge'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: TtColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Three Vietnamese segment labels side by side ran 69 px
                  // past a 320 px screen at a 1.3x font — each column now takes
                  // an equal third instead of its natural width (WTM-169).
                  Row(
                    children: [
                      Expanded(
                        child: _CustomerStat(
                          label: l10n.segActive,
                          value: '$active',
                        ),
                      ),
                      Expanded(
                        child: _CustomerStat(label: l10n.segVip, value: '$vip'),
                      ),
                      Expanded(
                        child: _CustomerStat(
                          label: l10n.segNew,
                          value: '$fresh',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const Key('consumer-view-all'),
                      onPressed: _openList,
                      child: Text(l10n.actionViewAll),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Customer segments — aggregated from the customers' own segment
          // labels; empty state only when NO customer carries a segment.
          Text(
            l10n.sectionCustomerSegments,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (segmentTally.isEmpty)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: TtColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text(l10n.emptyCustomerSegments)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry
                    in (segmentTally.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value))))
                  Chip(
                    label: Text(
                      '${CustomerSegment.display(entry.key, l10n.languageCode)}'
                      ' (${entry.value})',
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 24),
          // Recent interactions — latest purchases, newest first.
          Text(
            l10n.sectionRecentInteractions,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (interactions.isEmpty)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: TtColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text(l10n.emptyRecentInteractions)),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: TtColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  for (final c in interactions)
                    ListTile(
                      dense: true,
                      title: Text(c.name),
                      subtitle: Text(
                        '${TongtaiFormatters.vndShort(c.totalSpent)} · '
                        '${TongtaiFormatters.isoDate(c.lastPurchaseDate!)}',
                      ),
                      trailing: Text(
                        c.tier.label(l10n.languageCode),
                        style: const TextStyle(
                          fontSize: 12,
                          color: TtColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          // Customer lifecycle — derived from order history, one source.
          Text(
            l10n.sectionCustomerLifecycle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: TtColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LifecycleStage(
                  stage: l10n.lifecycleAwareness,
                  count: '$total',
                ),
                const SizedBox(height: 12),
                _LifecycleStage(
                  stage: l10n.lifecycleConsideration,
                  count: '$fresh',
                ),
                const SizedBox(height: 12),
                _LifecycleStage(
                  stage: l10n.lifecyclePurchase,
                  count: '$purchased',
                ),
                const SizedBox(height: 12),
                _LifecycleStage(
                  stage: l10n.lifecycleRetention,
                  count: '$retained',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Một ô đếm phân khúc — **con số, không phán quyết** (WTM-407).
///
/// ⛔ **Không có tham số `color`, và đó là chủ đích.**
///
/// Trước đây cả ba số `75 / 0 / 4` tô **xanh dương** vì xanh dương là màu định
/// vị của năng lực Khách hàng. Trên máy Founder, ô `VIP` hiện **0** bằng màu
/// ấy — mà xanh dương = INFO trong luật màu, nên một con số không mặc áo một
/// phán quyết. Đúng lỗi WTM-389 đã dọn ở Home, còn sót lại ở đây.
///
/// Bỏ hẳn tham số thay vì đổi giá trị mặc định: một tham số `Color` sẽ được
/// truyền lại màu năng lực vào lần sau, bởi người không đọc ghi chú này.
class _CustomerStat extends StatelessWidget {
  final String label;
  final String value;

  const _CustomerStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: TtColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: TtColors.textSecondary),
        ),
      ],
    );
  }
}

/// Một chặng vòng đời — cũng **con số, không phán quyết** (WTM-407).
/// Xem chú thích ở [_CustomerStat]: không có tham số `color`, có chủ đích.
class _LifecycleStage extends StatelessWidget {
  final String stage;
  final String count;

  const _LifecycleStage({required this.stage, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // The stage name is the flexible half; the count is two characters and
        // must never be the thing that gets clipped (WTM-169).
        Expanded(
          child: Text(
            stage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          count,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: TtColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
