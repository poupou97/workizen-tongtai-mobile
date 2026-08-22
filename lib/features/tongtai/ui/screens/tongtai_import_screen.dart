import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tt.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../commerce/commerce_models.dart';
import '../../commerce/import/commerce_import.dart';
import '../../commerce/import/commerce_source_resolver.dart';
import '../../commerce/import/import_column_map.dart';
import '../../commerce/import/marketplace_profile.dart';
import '../../profile/business_profile.dart' show SalesChannel;
import '../../core/screen_data_controller.dart';
import '../../providers/tongtai_commerce_provider.dart';
import '../../providers/tongtai_inventory_provider.dart';
import '../../providers/tongtai_orders_provider.dart';
import '../../providers/tongtai_data_invalidation.dart';
import '../widgets/tongtai_screen_data.dart';

/// **Nhập dữ liệu cửa hàng** — WTM-326 (C2 · Epic WTM-324).
/// `IMPLEMENTATION_LEVEL=L3`.
///
/// ## Ngôn ngữ nghiệp vụ, không phải màn ETL (§27)
///
/// *"100 sản phẩm đã sẵn sàng"*, không phải *"parsed 100 rows"*. ⛔ Không
/// expose: CSV parser · schema · foreign key · canonical mapping · import job
/// internals.
///
/// Số dòng và tên bảng **có** hiện, nhưng ở cỡ chữ nhỏ dưới câu tiếng Việt —
/// dành cho ai muốn mở Excel ra sửa, không phải nội dung chính.
///
/// ## Xem trước là một bước riêng, không phải một hộp thoại
///
/// Người bán phải **thấy** trước khi nhập (§12). Gộp hai bước lại thành một
/// nút "Nhập" kèm hộp thoại xác nhận sẽ biến việc xem xét thành việc bấm OK.
class TongtaiImportScreen extends ConsumerStatefulWidget {
  const TongtaiImportScreen({super.key, this.pickFile});

  /// Chọn file **và đọc nội dung**.
  ///
  /// Một seam chứ không phải "chọn đường dẫn rồi đọc trong widget": I/O thật
  /// khởi động từ callback của widget chạy trong vùng fake-async của test và
  /// không bao giờ xong — cùng lý do `TongtaiBackupScreen` có seam này.
  final Future<PickedImportFile?> Function()? pickFile;

  @override
  ConsumerState<TongtaiImportScreen> createState() =>
      _TongtaiImportScreenState();
}

/// Một file người bán đã chọn.
@immutable
class PickedImportFile {
  const PickedImportFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class _TongtaiImportScreenState extends ConsumerState<TongtaiImportScreen> {
  bool _busy = false;
  CommerceImportPreview? _preview;
  CommerceImportResult? _result;

  /// File vừa chọn, giữ lại để **đọc lại** sau khi người bán ghép cột.
  ///
  /// Không giữ thì bước ghép cột phải bắt họ chọn file lần nữa — và một người
  /// vừa bị app nói *"chưa nhận ra file này"* mà còn bị bắt chọn lại file thì
  /// sẽ bỏ cuộc ở đó.
  PickedImportFile? _picked;

  /// `true` khi bộ đang xem trước là bộ mẫu — quyết định cờ `isDemo` của lần
  /// nhập. Cờ nằm ở **lần nhập**, không ở từng dòng.

  Future<PickedImportFile?> _defaultPick() async {
    final file = await openFile();
    if (file == null) return null;
    return PickedImportFile(name: file.name, bytes: await file.readAsBytes());
  }

  Future<void> _readPicked() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _result = null;
    });

    CommerceImportPreview? preview;
    final failure = await runTongtaiAction(
      () async {
        final picked = await (widget.pickFile ?? _defaultPick)();
        if (picked == null) return;
        _picked = picked;

        // App tự nhận file danh mục hay file sàn (WTM-322). Bắt người bán tự
        // khai loại file là đẩy việc phân loại sang người ít có khả năng phân
        // loại nhất.
        final source = CommerceSourceResolver.resolve(
          bytes: picked.bytes,
          fileName: picked.name,
          now: DateTime.now(),
          knownProducts: await ref.read(productRepositoryProvider).loadAll(),
          existingOrderIds: {
            for (final o in await ref.read(orderRepositoryProvider).loadAll())
              o.id,
          },
          // Bản đồ người bán đã tự chỉ trước đây (WTM-443). Truyền vào
          // **resolver**, không chỉ vào bộ đọc: cổng định tuyến cũng phải biết,
          // nếu không thì file sàn lạ không bao giờ tới được bộ đọc.
          savedMaps: await ref
              .read(importColumnMapRepositoryProvider)
              .loadAll(),
        );
        preview = await source.read();
      },
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'import',
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      if (preview != null) {
        _preview = preview;
      }
    });
    if (failure != null) showTongtaiFailure(context, failure);
  }

  /// Lưu bản đồ người bán vừa chỉ, rồi **đọc lại chính file đó** — WTM-443.
  ///
  /// Đọc lại chứ không "áp bản đồ vào bản xem trước đang có": bản xem trước
  /// hiện tại là một lời từ chối, nó không mang dòng dữ liệu nào. Chỉ có đường
  /// đọc thật mới cho ra đơn hàng, và đi lại đúng đường ấy nghĩa là mọi luật
  /// đã có — khớp SKU, chống trùng, cảnh báo thiếu báo cáo thu nhập — vẫn chạy
  /// nguyên vẹn, không có nhánh tắt nào cho file đã ghép tay.
  Future<void> _saveMapAndReread(ImportColumnMap map) async {
    final picked = _picked;
    if (_busy || picked == null) return;
    setState(() => _busy = true);

    CommerceImportPreview? preview;
    final failure = await runTongtaiAction(
      () async {
        await ref.read(importColumnMapRepositoryProvider).upsert(map);
        final source = CommerceSourceResolver.resolve(
          bytes: picked.bytes,
          fileName: picked.name,
          now: DateTime.now(),
          knownProducts: await ref.read(productRepositoryProvider).loadAll(),
          existingOrderIds: {
            for (final o in await ref.read(orderRepositoryProvider).loadAll())
              o.id,
          },
          savedMaps: await ref
              .read(importColumnMapRepositoryProvider)
              .loadAll(),
        );
        preview = await source.read();
      },
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'import',
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      if (preview != null) _preview = preview;
    });
    if (failure != null) showTongtaiFailure(context, failure);
  }

  Future<void> _import() async {
    final preview = _preview;
    if (_busy || preview == null) return;
    setState(() => _busy = true);

    CommerceImportResult? result;
    final failure = await runTongtaiAction(
      () async => result = await ref
          .read(commerceImporterProvider)
          .apply(
            preview,
            // Màn này chỉ nhận file của người bán. Bộ đóng kèm đi đường
            // "Nạp dữ liệu mẫu" và tự khai `bundledDemo` ở đó.
            sourceVendor: ImportVendor.localFile,
          ),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'import',
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = result;
      if (result != null) _preview = null;
    });

    // Một lần nhập đổi Home, Inventory, Producer, Finance và mọi cơ hội. Chỉ
    // làm mới màn này sẽ để mọi màn khác nói con số cũ (WTM-149 defect 1).
    invalidateBusinessDataProviders(ref);
    ref.invalidate(importJobsProvider);

    if (failure != null) {
      showTongtaiFailure(context, failure);
      return;
    }
    final done = result;
    if (done != null) {
      _say(context.l10n.importDone(done.counts['products'] ?? 0));
    }
  }

  Future<void> _undo(ImportJob job) async {
    if (_busy) return;
    setState(() => _busy = true);

    var removed = 0;
    final failure = await runTongtaiAction(
      () async {
        final counts = await ref
            .read(commerceRepositoryProvider)
            .deleteImport(job.id);
        removed = counts.values.fold(0, (sum, v) => sum + v);
      },
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'import',
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = null;
    });
    invalidateBusinessDataProviders(ref);
    ref.invalidate(importJobsProvider);

    if (failure != null) {
      showTongtaiFailure(context, failure);
      return;
    }
    _say(context.l10n.importResetDone(removed));
  }

  void _say(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preview = _preview;
    final jobs = ref.watch(importJobsProvider);

    return Scaffold(
      backgroundColor: TtColors.surfaceSecondary,
      appBar: AppBar(
        title: Text(l10n.titleImport),
        elevation: 0,
        backgroundColor: TtColors.surfaceSecondary,
        foregroundColor: TtColors.textPrimary,
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('import-list'),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.importIntro,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: TtColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // ⛔ WTM-343 — KHÔNG còn nút "Dùng bộ dữ liệu mẫu" ở đây.
            //
            // Bộ 100 sản phẩm là **dữ liệu mẫu**, và dữ liệu mẫu có đúng một
            // chủ: "Nạp dữ liệu mẫu" trong Thêm. Màn này chỉ làm một việc —
            // nhận file Excel **của người bán**. Hai lối vào cho một khái niệm
            // là hai chỗ để chọn nhầm (P-27).
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                key: const Key('import-pick-file'),
                onPressed: _busy ? null : _readPicked,
                child: Text(l10n.importPickFile),
              ),
            ),
            // ⭐ MỘT trong hai thẻ, không bao giờ cả hai — WTM-446.
            //
            // Bản đầu hiện cả hai, và trên máy thật nó thành ra nói với người
            // bán hai điều trái ngược theo đúng thứ tự tệ nhất:
            //
            //   trên  → "Không có gì để nhập từ file này."   (ngõ cụt)
            //   dưới  → "Chỉ giúp cột nào là cột nào…"       (phải cuộn mới thấy)
            //
            // Người ta đọc từ trên xuống, gặp ngõ cụt, rồi đóng app. Lời mời ở
            // dưới không bao giờ được đọc.
            //
            // Thẻ ngõ cụt ấy cũng **sai về sự thật**: có thứ để nhập, chỉ là
            // app chưa biết cột nào là cột nào. Và câu "File không có bảng sản
            // phẩm nào tên PRODUCTS" là từ vựng của bộ đọc danh mục rò ra màn
            // hình — vô nghĩa với người vừa xuất file đơn từ Shopee (§27).
            //
            // ⚠️ Sửa bằng cách ĐỔI THỨ TỰ ưu tiên, không đổi câu chữ: câu lỗi
            // kia vẫn đúng khi người bán thật sự đưa vào một file danh mục
            // hỏng. Lỗi nằm ở chỗ hai thẻ cùng hiện.
            if (preview != null && preview.unrecognisedHeaders.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ColumnMappingCard(
                headers: preview.unrecognisedHeaders,
                busy: _busy,
                onSave: _saveMapAndReread,
              ),
            ] else if (preview != null) ...[
              const SizedBox(height: 16),
              _PreviewCard(preview: preview, busy: _busy, onImport: _import),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              _ResultCard(result: _result!),
            ],
            const SizedBox(height: 24),
            Text(
              l10n.importHistory,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TtColors.textPrimary,
              ),
            ),
            Text(
              // Luật "mỗi đường xoá khai phạm vi" (WTM-307) nói với con người
              // ở đây, không chỉ nói trong comment của repository.
              l10n.importResetConfirm,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: TtColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            switch (jobs) {
              AsyncData(value: final list) when list.isEmpty => Text(
                l10n.stateEmpty,
                key: const Key('import-history-empty'),
                style: const TextStyle(
                  fontSize: 13,
                  color: TtColors.textSecondary,
                ),
              ),
              AsyncData(value: final list) => Column(
                children: [
                  for (final job in list)
                    _JobRow(job: job, busy: _busy, onUndo: () => _undo(job)),
                ],
              ),
              _ => const SizedBox.shrink(),
            },
          ],
        ),
      ),
    );
  }
}

/// Xem trước — **cái gì có trong file**, bằng ngôn ngữ nghiệp vụ.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.preview,
    required this.busy,
    required this.onImport,
  });

  final CommerceImportPreview preview;
  final bool busy;
  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final counts = preview.counts;

    return Container(
      key: const Key('import-preview'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TtColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TtColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preview.sourceName,
            style: const TextStyle(fontSize: 13, color: TtColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.importReadyProducts(counts['products'] ?? 0),
            key: const Key('import-preview-products'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: TtColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          for (final line in [
            if ((counts['variants'] ?? 0) > 0)
              l10n.importReadyVariants(counts['variants']!),
            if ((counts['quotes'] ?? 0) > 0)
              l10n.importReadySuppliers(counts['quotes']!),
            if ((counts['orders'] ?? 0) > 0)
              l10n.importReadyOrders(counts['orders']!),
            if ((counts['customers'] ?? 0) > 0)
              l10n.importReadyCustomers(counts['customers']!),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '· $line',
                style: const TextStyle(
                  fontSize: 13,
                  color: TtColors.textSecondary,
                ),
              ),
            ),
          if (preview.errors.isNotEmpty) ...[
            const SizedBox(height: 10),
            _IssueBlock(
              key: const Key('import-preview-errors'),
              headline: l10n.importBlocked(preview.errors.length),
              issues: preview.errors,
              tone: TtStatus.danger,
            ),
          ],
          if (preview.warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            _IssueBlock(
              key: const Key('import-preview-warnings'),
              headline: l10n.importWarned(preview.warnings.length),
              issues: preview.warnings,
              tone: TtStatus.warning,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const Key('import-confirm'),
              // Có lỗi **không** chặn cả file: 100 sản phẩm không đáng bị từ
              // chối vì một đơn hàng hỏng. Chỉ khi không còn gì hợp lệ thì nút
              // mới tắt.
              onPressed: busy || !preview.hasAnythingToImport
                  ? null
                  : () => onImport(),
              child: Text(
                busy
                    ? l10n.importRunning
                    : preview.hasAnythingToImport
                    ? l10n.importConfirm
                    : l10n.importNothing,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueBlock extends StatelessWidget {
  const _IssueBlock({
    super.key,
    required this.headline,
    required this.issues,
    required this.tone,
  });

  final String headline;
  final List<ImportIssue> issues;

  /// **Vai**, không phải màu. Bản trước nhận `Color` và phía gọi truyền
  /// `Colors.orange` cho khối *cảnh báo* — mà cam là màu Brand/Primary Action,
  /// nên chỗ đang báo có vấn đề lại đọc ra *"bấm vào đây"* (WTM-424).
  final TtStatus tone;

  @override
  Widget build(BuildContext context) {
    // Ba dòng đầu là đủ để hiểu chuyện gì; ba mươi dòng thì không ai đọc.
    final shown = issues.take(3).toList();
    final rest = issues.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headline,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: tone.color,
          ),
        ),
        for (final issue in shown)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${issue.subject}: ${issue.detail}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TtColors.textPrimary,
                  ),
                ),
                // Chỗ sửa — nhỏ, cho ai muốn mở Excel ra. Không phải nội dung
                // chính (§27).
                if (issue.sheet != null && issue.rowNumber != null)
                  Text(
                    context.l10n.importIssueLocation(
                      issue.sheet!,
                      issue.rowNumber!,
                    ),
                    style: const TextStyle(
                      fontSize: 11,
                      color: TtColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        if (rest > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              context.l10n.importMoreIssues(rest),
              style: const TextStyle(
                fontSize: 12,
                color: TtColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final CommerceImportResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      key: const Key('import-result'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TtStatus.success.soft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: TtStatus.success.color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.importDone(result.counts['products'] ?? 0),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: TtColors.textPrimary,
            ),
          ),
          if (result.skipped.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l10n.importBlocked(result.skipped.length),
              style: const TextStyle(
                fontSize: 12,
                color: TtColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job, required this.busy, required this.onUndo});

  final ImportJob job;
  final bool busy;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.sourceFile ?? l10n.stateEmpty,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TtColors.textPrimary,
                  ),
                ),
                Text(
                  '${job.importedAt.day}/${job.importedAt.month} · '
                  '${l10n.importRecordCount(job.totalRecords)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TtColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: TextButton(
              key: Key('import-undo-${job.id}'),
              onPressed: busy ? null : onUndo,
              child: Text(l10n.importReset),
            ),
          ),
        ],
      ),
    );
  }
}

/// **Người bán tự chỉ cột** — WTM-443 (Epic WTM-440).
///
/// ## Vì sao bước này tồn tại
///
/// Sáu `MarketplaceProfile` đoán tên cột từ tài liệu sàn, **chưa đối chiếu file
/// thật nào**. Kế hoạch đối chiếu ("xin một file xuất thật") hỏng vì file đơn
/// của sàn mang tên · số điện thoại · địa chỉ của **khách hàng người ta**.
///
/// Nên app không đi tìm file nữa: nó đoán trước, người bán sửa nếu sai, và app
/// nhớ. **File không bao giờ rời máy họ.**
///
/// ## Ngôn ngữ nghiệp vụ, không phải ngôn ngữ ETL (§27)
///
/// Câu hỏi là *"File này của sàn nào?"*, không phải *"map source columns to
/// canonical fields"*. Vai trò hiện bằng tên người bán đọc được — *"Mã đơn
/// hàng"*, không phải `orderId`.
class _ColumnMappingCard extends StatefulWidget {
  const _ColumnMappingCard({
    required this.headers,
    required this.busy,
    required this.onSave,
  });

  final List<String> headers;
  final bool busy;
  final Future<void> Function(ImportColumnMap) onSave;

  @override
  State<_ColumnMappingCard> createState() => _ColumnMappingCardState();
}

class _ColumnMappingCardState extends State<_ColumnMappingCard> {
  String _vendor = ImportColumnMap.kOtherMarketplaceVendor;
  MarketplaceFileKind _kind = MarketplaceFileKind.orders;
  final Map<MarketplaceField, String> _columns = {};

  /// Vai trò hiện ra để ghép: bắt buộc trước, rồi vài vai trò hay dùng.
  ///
  /// Không hiện **cả 16** vai trò: một bảng 16 dòng ô chọn là thứ khiến người
  /// bán đóng app. Vai trò bắt buộc là thứ chặn việc đọc file; phần còn lại
  /// thiếu thì app vẫn đọc được và **nói ra là thiếu**.
  List<MarketplaceField> get _fields {
    final required = ImportColumnMap.requiredFor(_kind).toList();
    final extra = _kind == MarketplaceFileKind.orders
        ? const [
            MarketplaceField.orderDate,
            MarketplaceField.productName,
            MarketplaceField.buyerName,
          ]
        : const [
            MarketplaceField.commission,
            MarketplaceField.transactionFee,
            MarketplaceField.shippingFee,
            MarketplaceField.payout,
          ];
    return [...required, ...extra];
  }

  ImportColumnMap get _map =>
      ImportColumnMap(vendor: _vendor, kind: _kind, columns: _columns);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final missing = _map.missingRequired;

    return Container(
      key: const Key('import-column-map'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TtColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TtColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.importMapTitle,
            key: const Key('import-column-map-title'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: TtColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.importMapIntro,
            style: const TextStyle(fontSize: 13, color: TtColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _Labelled(
            label: l10n.importMapVendor,
            child: DropdownButton<String>(
              key: const Key('import-column-map-vendor'),
              value: _vendor,
              isExpanded: true,
              items: [
                for (final p in MarketplaceProfile.all)
                  DropdownMenuItem(value: p.vendor, child: Text(p.displayName)),
                DropdownMenuItem(
                  value: ImportColumnMap.kOtherMarketplaceVendor,
                  child: Text(
                    l10n.profileChannel(SalesChannel.marketplaceOther.code),
                  ),
                ),
              ],
              onChanged: widget.busy
                  ? null
                  : (v) => setState(() => _vendor = v ?? _vendor),
            ),
          ),
          const SizedBox(height: 12),
          _Labelled(
            label: l10n.importMapKind,
            child: DropdownButton<MarketplaceFileKind>(
              key: const Key('import-column-map-kind'),
              value: _kind,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: MarketplaceFileKind.orders,
                  child: Text(l10n.importMapKindOrders),
                ),
                DropdownMenuItem(
                  value: MarketplaceFileKind.income,
                  child: Text(l10n.importMapKindIncome),
                ),
              ],
              onChanged: widget.busy
                  ? null
                  : (v) => setState(() {
                      _kind = v ?? _kind;
                      // Vai trò của hai loại file khác nhau; giữ lại lựa chọn
                      // cũ sẽ mang cột "phí sàn" sang file đơn hàng.
                      _columns.clear();
                    }),
            ),
          ),
          const SizedBox(height: 16),
          for (final field in _fields) ...[
            _Labelled(
              label: l10n.importMapField(field.name),
              child: DropdownButton<String?>(
                key: Key('import-column-map-field-${field.name}'),
                value: _columns[field],
                isExpanded: true,
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.importMapUnset),
                  ),
                  for (final h in widget.headers)
                    DropdownMenuItem(value: h, child: Text(h)),
                ],
                onChanged: widget.busy
                    ? null
                    : (v) => setState(() {
                        if (v == null) {
                          _columns.remove(field);
                        } else {
                          _columns[field] = v;
                        }
                      }),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              l10n.importMapMissing(
                missing.map((f) => l10n.importMapField(f.name)).join(', '),
              ),
              key: const Key('import-column-map-missing'),
              style: const TextStyle(fontSize: 13, color: TtColors.warning),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('import-column-map-save'),
              // Thiếu vai trò bắt buộc ⇒ **chặn**. Nhập nửa vời tệ hơn không
              // nhập: một đơn không có mã thì lần nhập sau đếm nó lần nữa.
              onPressed: widget.busy || missing.isNotEmpty
                  ? null
                  : () => widget.onSave(_map),
              child: Text(l10n.importMapSave),
            ),
          ),
        ],
      ),
    );
  }
}

/// Một nhãn nhỏ trên một ô chọn.
class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: TtColors.textSecondary),
      ),
      child,
    ],
  );
}
