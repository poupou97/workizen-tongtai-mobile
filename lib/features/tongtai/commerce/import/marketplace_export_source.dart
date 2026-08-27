import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../core/provenance.dart';
import '../../core/tongtai_enums.dart';
import '../../finance/settlement.dart';
import '../../inventory/product.dart';
import '../../inventory/product_category.dart';
import '../../orders/order.dart';
import '../commerce_models.dart';
import 'commerce_import.dart';
import 'import_column_map.dart';
import 'marketplace_profile.dart';
import 'xlsx_reader.dart';

/// Đọc file xuất từ Seller Centre — WTM-322 (C6 · Epic WTM-315).
///
/// ## Hai đường, MỘT đích
///
/// ```
/// File Bridge  ─┐
///               ├─→ Canonical Domain ─→ Agentic Foundation
/// Vendor API   ─┘
/// ```
///
/// Nếu hai đường sinh ra hai model thì ngày có API sẽ phải viết lại toàn bộ.
/// Nên lớp này **không** có kiểu dữ liệu riêng: nó trả về đúng `CustomerOrder`
/// và `SettlementLine` mà mọi chỗ khác đã dùng.
///
/// ## ⭐ Đơn hàng KHÔNG tạo sản phẩm
///
/// File đơn của sàn có tên và SKU sản phẩm, nhưng **không có giá vốn**. Tạo
/// sản phẩm từ đó sẽ sinh ra một danh mục toàn món không biết vốn — và lợi
/// nhuận của toàn bộ danh mục lập tức thành *"chưa tính được"*.
///
/// Nên SKU không khớp danh mục ⇒ **ERROR cho đơn đó**, kèm câu nói rõ phải làm
/// gì: nhập danh mục trước. Thứ tự này là một sự thật nghiệp vụ, không phải một
/// hạn chế kỹ thuật.
///
/// ## Voucher sàn tài trợ không phải chi phí người bán
///
/// ADR-TON-024 gọi đúng tên: nhầm chỗ này làm lợi nhuận sai theo **hướng tâng
/// bốc** — kiểu sai không ai đi kiểm.
class MarketplaceExportSource implements CommerceImportSource {
  MarketplaceExportSource({
    required this.bytes,
    required this.fileName,
    required this.now,
    required this.knownProducts,
    this.existingOrderIds = const {},
    this.savedMaps = const [],
    this.reader = const XlsxReader(),
  });

  final Uint8List bytes;
  final String fileName;
  final DateTime now;

  /// Bộ đọc bảng — `.xlsx` mặc định, `.csv` cho bản xuất products Shopify
  /// (WTM-463). Mọi luật phía sau dùng chung, không rẽ theo định dạng.

  /// Danh mục hiện có — dùng để khớp SKU. Đơn không khớp thì **không** nhập.
  final List<Product> knownProducts;

  /// Bản đồ cột người bán đã tự chỉ trước đây — WTM-443.
  ///
  /// Dùng **sau** khi nhận dạng tự động thất bại, không phải trước: hồ sơ đoán
  /// sẵn vẫn là phát đầu tiên. Bản đồ tay là lưới an toàn, không phải đường
  /// chính — nếu nó đi trước thì một hồ sơ đã sửa đúng vẫn bị một bản đồ cũ
  /// ghi đè.
  final List<ImportColumnMap> savedMaps;

  /// Mã đơn đã có trong sổ. Nhập lại cùng file ⇒ không đếm hai lần.
  final Set<String> existingOrderIds;

  final TabularReader reader;

  @override
  String get displayName => fileName;

  @override
  Future<CommerceImportPreview> read() async {
    final Map<String, List<List<String>>> sheets;
    try {
      sheets = reader.read(bytes);
    } on XlsxException catch (e) {
      return CommerceImportPreview.rejected(
        sourceName: fileName,
        issue: ImportIssue(
          level: ImportIssueLevel.error,
          code: e.problem.code,
          subject: fileName,
          detail: switch (e.problem) {
            XlsxProblem.notAZipFile =>
              'Đây không phải file Excel. Vào Kênh Người Bán, xuất báo cáo '
                  'dạng .xlsx rồi chọn lại.',
            XlsxProblem.notASpreadsheet =>
              'File mở được nhưng không có bảng nào bên trong.',
            XlsxProblem.corrupt => 'File hỏng, không đọc được nội dung.',
          },
        ),
      );
    }

    // Sàn xuất một sheet; lấy sheet đầu có dữ liệu.
    SheetTable? table;
    for (final entry in sheets.entries) {
      final candidate = SheetTable(entry.key, entry.value);
      if (candidate.headers.isNotEmpty && !candidate.isEmpty) {
        table = candidate;
        break;
      }
    }
    if (table == null) {
      return CommerceImportPreview.rejected(
        sourceName: fileName,
        issue: const ImportIssue(
          level: ImportIssueLevel.error,
          code: 'empty_file',
          subject: 'file',
          detail: 'File không có dòng dữ liệu nào.',
        ),
      );
    }

    var match = MarketplaceMatch.detect(table.headers);

    // Nhận dạng trượt ⇒ hỏi lại những bản đồ người bán đã tự chỉ (WTM-443).
    match ??= _matchFromSavedMap(table.headers);

    if (match == null) {
      // ⭐ Không nhận ra ⇒ **nói ra những cột đã nhìn thấy**.
      //
      // Đây là chỗ tôi cố ý không đoán: tên cột trong `MarketplaceProfile` đến
      // từ tài liệu, chưa đối chiếu file thật. Khi gặp file thật không khớp,
      // app phải kể lại nó thấy gì — file sẽ tự nói cho ta biết tên cột đúng,
      // thay vì bắt ta đi tìm.
      final seen = table.headers.take(8).join(' · ');
      return CommerceImportPreview.rejected(
        sourceName: fileName,
        issue: ImportIssue(
          level: ImportIssueLevel.error,
          code: 'unknown_marketplace_file',
          subject: fileName,
          detail:
              'Chưa nhận ra đây là file của sàn nào. Các cột đọc được: $seen',
          sheet: table.name,
        ),
        // Danh sách ĐẦY ĐỦ, không cắt còn 8 như câu đọc ở trên: màn hình cần
        // mọi cột để người bán ghép, kể cả cột thứ 30.
        unrecognisedHeaders: table.headers,
      );
    }

    return switch (match.kind) {
      MarketplaceFileKind.orders => _readOrders(table, match),
      MarketplaceFileKind.income => _readIncome(table, match),
      MarketplaceFileKind.products => _readProducts(table, match),
    };
  }

  /// Bản đồ người bán đã chỉ có khớp file này không — WTM-443.
  ///
  /// Một bản đồ **áp dụng được** khi mọi cột nó nhắc tới đều thật sự có mặt
  /// trong file. Đó là điều kiện chặt hơn "vài cột trùng": bản đồ do người
  /// thật chỉ, nên nếu file thiếu cột họ từng chỉ thì đây là **file khác**,
  /// không phải file cũ thiếu vài cột.
  ///
  /// ⚠️ Hai bản đồ cùng khớp ⇒ trả `null`, giống hệt luật hoà điểm giữa hai
  /// sàn: thà nói *chưa nhận ra* và hỏi lại, còn hơn im lặng chọn một cái rồi
  /// gán sai kênh cho cả mẻ đơn.
  MarketplaceMatch? _matchFromSavedMap(List<String> headers) {
    final present = headers.toSet();
    final usable = [
      for (final map in savedMaps)
        if (map.isUsable &&
            map.columns.values.every(
              (c) => c.trim().isEmpty || present.contains(c),
            ) &&
            map.columns.values.any((c) => c.trim().isNotEmpty))
          map,
    ];
    if (usable.length != 1) return null;

    final map = usable.single;
    final base = MarketplaceProfile.byVendor(map.vendor);
    return MarketplaceMatch(
      profile: map.toProfile(base),
      kind: map.kind,
      // Điểm không dùng để so nữa — bản đồ đã do người thật xác nhận. Đặt bằng
      // số vai trò đã chỉ để `isConfident` không chặn nhầm.
      score: map.columns.length,
      headers: headers,
    );
  }

  // ── file đơn hàng ────────────────────────────────────────────────────────

  CommerceImportPreview _readOrders(SheetTable table, MarketplaceMatch match) {
    final issues = <ImportIssue>[];
    final orders = <CustomerOrder>[];
    final profile = match.profile;
    final bySku = {for (final p in knownProducts) p.sku.toUpperCase(): p};

    String column(MarketplaceField field) =>
        profile.columnFor(table.headers, field, MarketplaceFileKind.orders) ??
        '';

    final orderIdColumn = column(MarketplaceField.orderId);
    if (orderIdColumn.isEmpty) {
      return CommerceImportPreview.rejected(
        sourceName: fileName,
        issue: ImportIssue(
          level: ImportIssueLevel.error,
          code: 'missing_order_id',
          subject: profile.displayName,
          detail: 'File không có cột mã đơn hàng.',
          sheet: table.name,
        ),
      );
    }

    // Sàn xuất **một dòng cho mỗi món**, nên nhiều dòng cùng một mã đơn. Gom
    // lại thành một đơn — không gom thì mỗi món thành một đơn và số đơn nhân
    // lên, kéo theo mọi chỉ số đếm theo đơn sai.
    final lines = <String, List<List<String>>>{};
    for (final row in table.dataRows) {
      final id = table.cell(row, orderIdColumn);
      if (id.isEmpty) continue;
      (lines[id] ??= []).add(row);
    }

    for (final entry in lines.entries) {
      final externalId = entry.key;
      final canonicalId = 'mkt-${profile.vendor}-$externalId';

      if (existingOrderIds.contains(canonicalId)) {
        issues.add(
          ImportIssue(
            level: ImportIssueLevel.info,
            code: 'already_imported',
            subject: externalId,
            detail: 'Đơn này đã có trong sổ — bỏ qua, không đếm hai lần.',
            sheet: table.name,
          ),
        );
        continue;
      }

      final items = <OrderItem>[];
      var blocked = false;

      for (final row in entry.value) {
        final sku = table.cell(row, column(MarketplaceField.sku)).toUpperCase();
        final product = bySku[sku];
        if (product == null) {
          // Không tạo sản phẩm từ file đơn — xem doc của lớp này.
          issues.add(
            ImportIssue(
              level: ImportIssueLevel.error,
              code: 'unknown_sku',
              subject: externalId,
              detail:
                  'Mã hàng "${sku.isEmpty ? "(trống)" : sku}" chưa có trong '
                  'danh mục. Nhập danh mục sản phẩm trước rồi nhập lại đơn.',
              sheet: table.name,
            ),
          );
          blocked = true;
          continue;
        }

        final quantity =
            table.integer(row, column(MarketplaceField.quantity)) ?? 1;
        items.add(
          OrderItem(
            productId: product.id,
            productName: product.name,
            sku: product.sku,
            category: product.category,
            quantity: quantity,
            unitPrice:
                table.number(row, column(MarketplaceField.unitPrice)) ??
                product.pricePerUnit,
            // WTM-454 — snapshot the matched product's cost at import time. The
            // marketplace file carries no cost, so the current inventory cost is
            // the best snapshot available; `null` if that product has no cost.
            costPrice: product.costPrice,
          ),
        );
      }

      if (blocked || items.isEmpty) continue;

      orders.add(
        CustomerOrder(
          id: canonicalId,
          // Khách của sàn chưa nối vào danh bạ — WTM-296 lo việc đó, và gộp
          // khách KHÔNG BAO GIỜ tự động (ADR-TON-024).
          customerId: '',
          orderNumber: externalId,
          date:
              table.date(
                entry.value.first,
                column(MarketplaceField.orderDate),
              ) ??
              now,
          status: _status(
            table.cell(entry.value.first, column(MarketplaceField.status)),
          ),
          items: items,
          channel: profile.channel,
          provenance: const Provenance.declared(ProvenanceSource.fileBridge),
        ),
      );
    }

    // ⭐ Cảnh báo quan trọng nhất của cả story này.
    if (orders.isNotEmpty) {
      issues.add(
        ImportIssue(
          level: ImportIssueLevel.warning,
          code: 'income_report_missing',
          subject: profile.displayName,
          detail:
              'Đây mới là file đơn hàng. Chưa có báo cáo thu nhập nên phí sàn '
              'chưa biết — lợi nhuận sẽ hiện là "chưa tính được" cho tới khi '
              'bạn nhập tiếp file đó.',
        ),
      );
    }

    return CommerceImportPreview(
      sourceName: fileName,
      checksum: sha256.convert(bytes).toString(),
      orders: orders,
      issues: issues,
    );
  }

  // ── báo cáo thu nhập ─────────────────────────────────────────────────────

  CommerceImportPreview _readIncome(SheetTable table, MarketplaceMatch match) {
    final issues = <ImportIssue>[];
    final settlements = <SettlementLine>[];
    final profile = match.profile;

    String column(MarketplaceField field) =>
        profile.columnFor(table.headers, field, MarketplaceFileKind.income) ??
        '';

    final orderIdColumn = column(MarketplaceField.orderId);
    if (orderIdColumn.isEmpty) {
      return CommerceImportPreview.rejected(
        sourceName: fileName,
        issue: ImportIssue(
          level: ImportIssueLevel.error,
          code: 'missing_order_id',
          subject: profile.displayName,
          detail:
              'Báo cáo không có cột mã đơn hàng nên không gắn vào đơn nào được.',
          sheet: table.name,
        ),
      );
    }

    // Mỗi khoản là một `kind` riêng — **không** cộng gộp thành một con số
    // "phí sàn". Gộp lại thì không ai trả lời được *"hoa hồng bao nhiêu"*, và
    // đó đúng là câu người bán hỏi khi thấy lợi nhuận mỏng.
    const mapping = <MarketplaceField, SettlementKind>{
      MarketplaceField.commission: SettlementKind.commission,
      MarketplaceField.transactionFee: SettlementKind.platformFee,
      MarketplaceField.serviceFee: SettlementKind.platformFee,
      MarketplaceField.shippingFee: SettlementKind.shippingFee,
      MarketplaceField.voucher: SettlementKind.voucher,
      MarketplaceField.platformVoucher: SettlementKind.voucher,
    };

    for (var i = 0; i < table.dataRows.length; i++) {
      final row = table.dataRows[i];
      final externalId = table.cell(row, orderIdColumn);
      if (externalId.isEmpty) continue;
      final orderId = 'mkt-${profile.vendor}-$externalId';

      for (final field in mapping.keys) {
        final name = column(field);
        if (name.isEmpty) continue;
        final amount = table.number(row, name);
        if (amount == null || amount == 0) continue;

        settlements.add(
          SettlementLine(
            id: 'mkt-${profile.vendor}-$externalId-${field.name}',
            orderId: orderId,
            kind: mapping[field]!,
            // Sàn xuất phí dưới dạng số âm hoặc dương tuỳ báo cáo. `amount`
            // luôn dương, chiều nằm ở `direction` (ADR-TON-024).
            direction: SettlementDirection.outbound,
            amount: amount.abs(),
            currency: 'VND',
            occurredAt: now,
            // ⭐ Voucher **sàn tài trợ** không phải chi phí người bán. Nhầm chỗ
            // này làm lợi nhuận sai theo hướng tâng bốc.
            fundedBy: field == MarketplaceField.platformVoucher
                ? FundingSource.platform
                : FundingSource.seller,
            provenance: const Provenance.declared(ProvenanceSource.fileBridge),
          ),
        );
      }
    }

    if (settlements.isEmpty) {
      issues.add(
        ImportIssue(
          level: ImportIssueLevel.warning,
          code: 'no_fees_found',
          subject: profile.displayName,
          detail: 'Không đọc được khoản phí nào trong báo cáo này.',
          sheet: table.name,
        ),
      );
    }

    // Cột nhìn thấy mà không map được — **nói ra**, không nuốt im lặng (§11).
    final mapped = {
      for (final field in [
        ...mapping.keys,
        MarketplaceField.orderId,
        MarketplaceField.payout,
      ])
        column(field),
    }..removeWhere((c) => c.isEmpty);
    final unmapped = [
      for (final header in table.headers)
        if (!mapped.contains(header)) header,
    ];
    if (unmapped.isNotEmpty) {
      issues.add(
        ImportIssue(
          level: ImportIssueLevel.info,
          code: 'unmapped_columns',
          subject: profile.displayName,
          detail:
              '${unmapped.length} cột chưa dùng tới: '
              '${unmapped.take(5).join(" · ")}',
          sheet: table.name,
        ),
      );
    }

    return CommerceImportPreview(
      sourceName: fileName,
      checksum: sha256.convert(bytes).toString(),
      settlements: settlements,
      issues: issues,
    );
  }

  // ── file danh mục products ───────────────────────────────────────────────

  /// Đọc bản xuất **products** của Shopify — WTM-463.
  ///
  /// ## Vì sao file này từng KHÔNG có đường vào
  ///
  /// Trước WTM-463 hồ sơ chỉ khai order/income, nên một danh mục sản phẩm thật
  /// (giá vốn · SKU · tồn theo biến thể) rơi hết — kể cả khi người bán ghép cột
  /// tay, vì `ImportColumnMap.requiredFor` đòi `orderId`. Lỗ này lộ ra khi
  /// Founder đưa file thật đầu tiên (store demo Nova Furniture).
  ///
  /// ## Một sản phẩm trải trên NHIỀU dòng
  ///
  /// Shopify xuất, cho mỗi Handle:
  ///
  /// * **dòng tiêu đề** — dòng đầu có `Title`; mang trường cấp sản phẩm;
  /// * **mỗi biến thể một dòng** — có `Variant Price`; `Option1 Value` phân
  ///   biệt (một sản phẩm không tuỳ chọn vẫn có một biến thể `Default Title`);
  /// * **các dòng chỉ-ảnh** — chỉ có `Image Src`, là ảnh phụ của gallery.
  ///
  /// Nên phải **gom theo Handle** rồi mới dựng. Dòng chỉ-ảnh **bỏ qua nhưng
  /// đếm** — nuốt im lặng thì người bán không biết vì sao 211 dòng ra 132 biến
  /// thể.
  ///
  /// ## Kỷ luật null-giữ-null
  ///
  /// `Cost per item` trống ⇒ `costPrice = null`, **cấm rơi về 0** (ADR-TON-022:
  /// 0 nói "miễn phí", null nói "chưa ai khai"). Tồn `0` là **0 thật**, khác
  /// `null` (không theo dõi). SKU trống ⇒ trống, **không bịa**. Cả ba khoảng
  /// trống được **đếm và nói ra** ở phần cảnh báo, không đoán.
  CommerceImportPreview _readProducts(
    SheetTable table,
    MarketplaceMatch match,
  ) {
    final profile = match.profile;
    final issues = <ImportIssue>[];

    String column(MarketplaceField field) =>
        profile.columnFor(table.headers, field, MarketplaceFileKind.products) ??
        '';

    final handleColumn = column(MarketplaceField.productHandle);
    if (handleColumn.isEmpty) {
      return CommerceImportPreview.rejected(
        sourceName: fileName,
        issue: ImportIssue(
          level: ImportIssueLevel.error,
          code: 'missing_handle',
          subject: profile.displayName,
          detail:
              'File danh mục không có cột Handle nên không gom được biến thể '
              'về sản phẩm.',
          sheet: table.name,
        ),
      );
    }

    final titleColumn = column(MarketplaceField.productName);
    final priceColumn = column(MarketplaceField.unitPrice);
    final costColumn = column(MarketplaceField.costPrice);
    final qtyColumn = column(MarketplaceField.quantity);
    final skuColumn = column(MarketplaceField.sku);
    final opt1NameColumn = column(MarketplaceField.option1Name);
    final opt1ValueColumn = column(MarketplaceField.option1Value);
    final vendorColumn = column(MarketplaceField.vendor);
    final categoryColumn = column(MarketplaceField.productCategory);
    final imageColumn = column(MarketplaceField.imageSrc);

    // Gom theo Handle, GIỮ THỨ TỰ file (Map của Dart là LinkedHashMap).
    final byHandle = <String, List<List<String>>>{};
    for (final row in table.dataRows) {
      final handle = table.cell(row, handleColumn);
      if (handle.isEmpty) continue;
      (byHandle[handle] ??= []).add(row);
    }

    final products = <Product>[];
    final variants = <ProductVariant>[];
    var imageOnlyCount = 0;
    var variantsMissingCost = 0;
    var productsMissingSku = 0;

    double? priceOf(List<String> row) =>
        priceColumn.isEmpty ? null : table.number(row, priceColumn);

    for (final entry in byHandle.entries) {
      final handle = entry.key;
      final rows = entry.value;
      final productId = 'mkt-${profile.vendor}-$handle';

      // Dòng tiêu đề = dòng ĐẦU có Title; nó mang trường cấp sản phẩm.
      List<String>? titleRow;
      if (titleColumn.isNotEmpty) {
        for (final row in rows) {
          if (table.cell(row, titleColumn).isNotEmpty) {
            titleRow = row;
            break;
          }
        }
      }
      if (titleRow == null) {
        // Shopify luôn có Title ở dòng đầu mỗi Handle; thiếu ⇒ dữ liệu lạ, bỏ
        // cả nhóm và NÓI RA thay vì lẳng lặng nuốt.
        issues.add(
          ImportIssue(
            level: ImportIssueLevel.warning,
            code: 'product_without_title',
            subject: handle,
            detail: 'Nhóm "$handle" không có dòng tên sản phẩm — bỏ qua.',
            sheet: table.name,
          ),
        );
        continue;
      }
      final productTitle = table.cell(titleRow, titleColumn);

      var quantitySum = 0;
      var anyQuantity = false;
      var variantSeq = 0;

      for (final row in rows) {
        final price = priceOf(row);
        if (price != null) {
          // Dòng biến thể.
          final cost = costColumn.isEmpty
              ? null
              : table.number(row, costColumn);
          if (cost == null) variantsMissingCost++;

          final qty = qtyColumn.isEmpty ? null : table.number(row, qtyColumn);
          if (qty != null) {
            anyQuantity = true;
            quantitySum += qty.round();
          }

          final optValue = opt1ValueColumn.isEmpty
              ? null
              : _blankToNull(table.cell(row, opt1ValueColumn));
          final sku = skuColumn.isEmpty ? '' : table.cell(row, skuColumn);

          variants.add(
            ProductVariant(
              id: '$productId-v$variantSeq',
              productId: productId,
              // `Default Title` là ô giữ chỗ của Shopify cho sản phẩm không có
              // tuỳ chọn — hiện tên sản phẩm thay vì rò từ khoá kỹ thuật ra UI.
              name: (optValue == null || optValue == 'Default Title')
                  ? productTitle
                  : optValue,
              sku: sku,
              option1Name: opt1NameColumn.isEmpty
                  ? null
                  : _blankToNull(table.cell(row, opt1NameColumn)),
              option1Value: optValue,
              // Ô trống ⇒ null (kế thừa giá mẹ), KHÔNG 0 (ADR-TON-022).
              costPrice: cost,
              sellingPrice: price,
              // Tồn `0` là 0 thật; ô trống mới là `null` (không theo dõi).
              quantity: qty,
              externalId: _blankToNull(sku),
              provenance: ProvenanceSource.fileBridge,
            ),
          );
          variantSeq++;
        } else if (imageColumn.isNotEmpty &&
            table.cell(row, imageColumn).isNotEmpty) {
          // Dòng chỉ-ảnh: BỎ QUA nhưng CÓ ĐẾM.
          imageOnlyCount++;
        }
        // else: dòng trống thật sự → bỏ, không đếm.
      }

      final productSku = skuColumn.isEmpty
          ? ''
          : table.cell(titleRow, skuColumn);
      if (productSku.isEmpty) productsMissingSku++;

      products.add(
        Product(
          // Id suy ra từ Handle: nhập lại **cùng** file thì ghi đè đúng bản ghi
          // cũ thay vì sinh bản thứ hai.
          id: productId,
          // SKU trống ⇒ trống, không bịa. Danh tính sản phẩm là Handle, không
          // phải SKU — nên SKU trống không chặn việc nhập.
          sku: productSku,
          name: productTitle,
          category: categoryColumn.isEmpty
              ? ''
              : ProductCategory.normalise(table.cell(titleRow, categoryColumn)),
          // Dòng tiêu đề Shopify luôn có giá; `?? 0` chỉ là lưới an toàn.
          pricePerUnit: priceOf(titleRow) ?? 0,
          // Giá vốn null-giữ-null.
          costPrice: costColumn.isEmpty
              ? null
              : table.number(titleRow, costColumn),
          // Tồn cấp sản phẩm = tổng tồn các biến thể; null khi không biến thể
          // nào theo dõi tồn.
          quantity: anyQuantity ? quantitySum : null,
          updatedAt: now,
          brand: vendorColumn.isEmpty
              ? null
              : _blankToNull(table.cell(titleRow, vendorColumn)),
          imageUrl: imageColumn.isEmpty
              ? null
              : _blankToNull(table.cell(titleRow, imageColumn)),
          externalId: handle,
          provenance: ProvenanceSource.fileBridge,
        ),
      );
    }

    // ⭐ Preview NÓI RA cái gì rơi — đếm, không đoán (§11).
    if (imageOnlyCount > 0) {
      issues.add(
        ImportIssue(
          level: ImportIssueLevel.info,
          code: 'image_rows_skipped',
          subject: profile.displayName,
          detail:
              '$imageOnlyCount dòng chỉ có ảnh — bỏ qua, không đếm thành biến '
              'thể.',
          sheet: table.name,
        ),
      );
    }
    if (variantsMissingCost > 0) {
      issues.add(
        ImportIssue(
          level: ImportIssueLevel.warning,
          code: 'missing_cost',
          subject: profile.displayName,
          detail:
              'Thiếu giá vốn ở $variantsMissingCost/${variants.length} biến '
              'thể — nhập được nhưng chưa tính được lời cho những mục đó.',
          sheet: table.name,
        ),
      );
    }
    if (productsMissingSku > 0) {
      issues.add(
        ImportIssue(
          level: ImportIssueLevel.info,
          code: 'missing_sku',
          subject: profile.displayName,
          detail:
              'Thiếu mã SKU ở $productsMissingSku/${products.length} sản phẩm '
              '— giữ trống, không bịa.',
          sheet: table.name,
        ),
      );
    }
    // Bản xuất products của Shopify KHÔNG ghi đơn vị tiền tệ (giá nằm ở cột
    // `Variant Price`, tiền của store). App tính bằng VND, nên nói thẳng thay
    // vì lặng lẽ coi USD là VND — và KHÔNG tự quy đổi tỉ giá (ADR/§17: không
    // fake độ chính xác).
    if (products.isNotEmpty) {
      issues.add(
        ImportIssue(
          level: ImportIssueLevel.warning,
          code: 'currency_unknown',
          subject: profile.displayName,
          detail:
              'File không ghi đơn vị tiền tệ. Giá được lấy nguyên như trong '
              'file — nếu cửa hàng để giá ngoại tệ, hãy quy đổi sang VND trước '
              'khi tin số lời.',
          sheet: table.name,
        ),
      );
    }

    if (products.isEmpty) {
      issues.add(
        ImportIssue(
          level: ImportIssueLevel.warning,
          code: 'no_products_found',
          subject: profile.displayName,
          detail: 'Không đọc được sản phẩm nào trong file danh mục này.',
          sheet: table.name,
        ),
      );
    }

    return CommerceImportPreview(
      sourceName: fileName,
      checksum: sha256.convert(bytes).toString(),
      products: products,
      variants: variants,
      issues: issues,
    );
  }

  static String? _blankToNull(String value) => value.isEmpty ? null : value;

  static OrderStatus _status(String raw) {
    final value = raw.toLowerCase();
    if (value.contains('hoàn') ||
        value.contains('huỷ') ||
        value.contains('hủy') ||
        value.contains('cancel') ||
        value.contains('refund')) {
      return OrderStatus.cancelled;
    }
    if (value.contains('giao') ||
        value.contains('hoàn thành') ||
        value.contains('complete') ||
        value.contains('deliver')) {
      return OrderStatus.delivered;
    }
    if (value.contains('vận chuyển') || value.contains('ship')) {
      return OrderStatus.shipped;
    }
    // Trạng thái lạ ⇒ `pending`. Tính một đơn chưa rõ vào doanh thu là bịa
    // doanh thu.
    return OrderStatus.pending;
  }
}
