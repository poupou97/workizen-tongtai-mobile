import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../core/screen_data_controller.dart';
import '../../core/tongtai_formatters.dart';
import '../../opportunity/opportunity.dart';
import '../../producer/supplier_favorite.dart';
import '../../producer/supplier_favorites_controller.dart';
import '../../producer/supplier_search_service.dart' show kSampleSuppliers;
import '../../providers/tongtai_context_provider.dart';
import '../../providers/tongtai_search_provider.dart';
import '../../providers/tongtai_data_invalidation.dart';
import '../widgets/tongtai_screen_data.dart';
import '../widgets/tongtai_screen_header.dart';
import '../../producer/business_input.dart';
import 'tongtai_business_inputs_screen.dart';
import 'tongtai_supplier_favorites_screen.dart';

/// Producer/Sourcing tab for Tổng Tài (WTM-24).
///
/// P0 correction 2026-07-30: previously a static design shell that read no
/// data (same defect class as the Consumer tab — Home counted favourites
/// while this tab always showed the empty states). It now reads the SAME
/// sources Home does: the persisted favourites store and the rule-generated
/// opportunities (locked by p0/count_list_contract_test.dart).
///
/// Supplier names resolve from the curated Phase-2 catalog (kSampleSuppliers,
/// the allowlisted sourcing directory — there is no supplier repository yet).
class TongtaiProducerScreen extends ConsumerStatefulWidget {
  const TongtaiProducerScreen({super.key});

  @override
  ConsumerState<TongtaiProducerScreen> createState() =>
      _TongtaiProducerScreenState();
}

class _TongtaiProducerScreenState extends ConsumerState<TongtaiProducerScreen> {
  /// ⚠️ WTM-383: màn này từng thuộc bảng màu *"producer = xanh lá"*, nên
  /// `_green` sơn cả hộp **"Tóm tắt AI"** lẫn sáu chip **"Năng lực AI"**. Trong
  /// khi thẻ AI ở Trang chủ là **tím** — tức là trong cùng một app, *"Tổng Tài
  /// đang nói"* có hai màu.
  ///
  /// AI nay đi bằng [TtColors.ai]; xanh lá chỉ còn ở nơi nó **thật sự** nói
  /// *"kết quả tích cực"*.
  static const _ai = TtColors.ai;

  /// Both sources behind this tab load together (WTM-148): if either the
  /// favourites store or the opportunity generator throws, the tab says so
  /// instead of quietly rendering the empty states it used to be made of.
  late final ScreenDataController<_ProducerData> _data;

  @override
  void initState() {
    super.initState();
    _data = ScreenDataController<_ProducerData>(
      _read,
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'producer',
    )..load();
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  Future<_ProducerData> _read() async {
    final store = ref.read(tongtaiSearchFavoritesStoreProvider);
    return (
      favorites: await store.loadAll(),
      opportunities: await ref.read(generatedOpportunitiesProvider.future),
      inputs: await ref.read(businessInputRepositoryProvider).loadAll(),
    );
  }

  String _supplierName(String supplierId) {
    for (final s in kSampleSuppliers) {
      if (s.id == supplierId) return s.name;
    }
    return supplierId;
  }

  /// Mở danh sách nguồn đầu vào (WTM-234). Đây là **đường vào duy nhất** của
  /// capability đó — thiếu nó, màn kia là màn mồ côi thứ ba (P-29/P-30).
  Future<void> _openInputs() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const TongtaiBusinessInputsScreen()),
    );
    if (mounted) await _data.refresh();
  }

  Future<void> _openFavorites() async {
    final controller = SupplierFavoritesController(
      ref.read(tongtaiSearchFavoritesStoreProvider),
    );
    await controller.load();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TongtaiSupplierFavoritesScreen(favorites: controller),
      ),
    );
    controller.dispose();
    await _data.refresh();
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
        screen: 'producer',
        title: l10n.titleProducerHub,
        subtitle: tongtaiScreenSubtitle(context.l10n, 'producer'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListenableBuilder(
        listenable: _data,
        builder: (context, _) => TongtaiScreenData<_ProducerData>(
          prefix: 'producer',
          state: _data.state,
          onRetry: _data.retry,
          builder: _body,
        ),
      ),
    );
  }

  Widget _body(BuildContext context, _ProducerData data) {
    final l10n = context.l10n;
    final favorites = data.favorites;
    final opportunities = data.opportunities;
    // Suy tại chỗ đọc, không lưu — một cột "tổng cam kết" sẽ là bản sao thứ
    // hai của thứ các nguồn đã nói (ADR-TON-015).
    final inputSummary = BusinessInputSummary.from(data.inputs);
    final topOpportunities =
        (opportunities.toList()..sort(
              (a, b) => (b.score.value ?? -1).compareTo(a.score.value ?? -1),
            ))
            .take(3)
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card — deterministic counts from the same sources Home
          // reads (zero is valid business data, WTM-128).
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
                  Text(
                    l10n.producerAiSummary,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TtColors.aiSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _ai),
                    ),
                    child: Text(
                      l10n.producerSummaryLine(
                        opportunities.length,
                        favorites.length,
                      ),
                      key: const Key('producer-summary-line'),
                      style: const TextStyle(fontSize: 14, color: _ai),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Nguồn đầu vào (WTM-234) — đứng trước phần chrome vì đây là dữ liệu
          // thật của người bán. Producer quản lý TOÀN BỘ đầu vào; nhà cung cấp
          // hàng hoá bên dưới chỉ là một loại (ADR-TON-023).
          Text(
            l10n.producerInputsSection,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: TtColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                ListTile(
                  key: const Key('producer-inputs-commitment'),
                  title: Text(l10n.inputsCommitmentLabel),
                  subtitle: Text(
                    inputSummary.isComplete
                        ? l10n.inputsAllCounted
                        : l10n.inputsUnknownCount(inputSummary.unknownCount),
                  ),
                  trailing: Text(
                    TongtaiFormatters.vnd(inputSummary.monthlyCommitment),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const Key('producer-view-inputs'),
                    onPressed: _openInputs,
                    child: Text(l10n.actionViewAll),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // AI Capabilities — static feature descriptions (chrome).
          Text(
            l10n.producerAiCapabilities,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CapabilityPill(label: l10n.producerCapScoring),
              _CapabilityPill(label: l10n.producerCapRanking),
              _CapabilityPill(label: l10n.producerCapTrends),
              _CapabilityPill(label: l10n.producerCapPrice),
              _CapabilityPill(label: l10n.producerCapQuality),
              _CapabilityPill(label: l10n.producerCapDelivery),
            ],
          ),
          const SizedBox(height: 24),
          // Opportunities — the SAME rule-generated list the feed and Home
          // read, top 3 by score.
          Text(
            l10n.producerRecentOpps,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (topOpportunities.isEmpty)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: TtColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text(l10n.producerEmptyOpps)),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: TtColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  for (final o in topOpportunities)
                    ListTile(
                      dense: true,
                      title: Text(o.title),
                      subtitle: Text(
                        '${tongtaiImpactLabel(o, estimatePrefix: l10n.oppEstimatePrefix, observedPrefix: l10n.oppObservedPrefix, money: TongtaiFormatters.vnd)}'
                        ' · ${l10n.oppScoreLabel} '
                        '${o.score.value?.round() ?? '—'}',
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          // Suppliers — the persisted favourites Home's Producer tile counts;
          // names from the curated catalog.
          //
          // ⚠️ WTM-422 — nhãn TRƯỚC ĐÂY là *"Nhà cung cấp đã xác minh"*, mà con
          // số bên cạnh là `favorites.length`: **số NCC người bán đã lưu**.
          // App không có bước xác minh nào cả, nên nhãn đang tuyên bố một việc
          // nó không làm — cùng họ WTM-421 (gỡ mọi tuyên bố không có nguồn).
          //
          // Nó còn đẻ ra một mâu thuẫn nhìn thấy được: *"đã xác minh: 0"* đứng
          // cạnh màn sản phẩm liệt kê **ba báo giá NCC có tên và giá**. Người
          // bán không đọc theo định nghĩa miền — họ thấy 0 chọi 3 và mất tin
          // vào MỌI con số trên app, không riêng ô này.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.producerSavedSuppliers,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                '${favorites.length}',
                key: const Key('producer-fav-count'),
                // Con số là một **sự thật**, không phải một phán quyết. Xanh
                // lá ở đây từng làm "0 nhà cung cấp yêu thích" trông như tin
                // tốt (XÁM ≠ XANH).
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TtColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (favorites.isEmpty)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: TtColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text(l10n.producerEmptySuppliers)),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: TtColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  for (final f in favorites)
                    ListTile(
                      dense: true,
                      title: Text(_supplierName(f.supplierId)),
                      trailing: const Icon(
                        Icons.favorite,
                        size: 16,
                        color: TtColors.brandOnDark,
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const Key('producer-view-favorites'),
                      onPressed: _openFavorites,
                      child: Text(l10n.actionViewAll),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// What the Producer tab needs in one read — favourites and the rule-generated
/// opportunities, loaded together so a partial failure cannot masquerade as an
/// empty hub.
typedef _ProducerData = ({
  List<SupplierFavorite> favorites,
  List<Opportunity> opportunities,
  List<BusinessInput> inputs,
});

/// Viên "năng lực AI" trên trung tâm nguồn hàng.
///
/// ⛔ **Không có tham số màu, và đó là chủ đích.**
///
/// Cả năm lời gọi trước đây đều truyền cùng một màu (`TtColors.ai`), nên tham
/// số ấy không phân biệt được gì — nó chỉ mở đường cho lần sau ai đó truyền
/// một sắc khác vào một dải vốn **luôn** là AI, và luật màu mất một mảnh.
///
/// Vai ở đây cố định: mọi viên trong dải này nói *"đây là việc AI làm"*.
class _CapabilityPill extends StatelessWidget {
  final String label;

  const _CapabilityPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TtStatus.ai.soft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TtStatus.ai.color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          // Nền nhạt + viền mang màu AI; chữ phải dùng bản đọc được, nếu không
          // nó ngồi ở 2,31:1 (WTM-169).
          color: TtColors.readableOn(TtStatus.ai.color),
        ),
      ),
    );
  }
}
