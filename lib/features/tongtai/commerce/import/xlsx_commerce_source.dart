import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../consumer/customer.dart';
import '../../consumer/customer_segment.dart';
import '../../core/provenance.dart';
import '../../core/tongtai_enums.dart';
import '../../finance/settlement.dart';
import '../../inventory/product.dart';
import '../../logistics/shipment.dart';
import '../../orders/order.dart';
import '../../profile/business_profile.dart' show SalesChannel;
import '../commerce_models.dart';
import 'commerce_import.dart';
import 'xlsx_reader.dart';

/// Đọc một file bảng tính thành miền thương mại chuẩn hoá — WTM-326.
///
/// ## Đây là Source Adapter ĐẦU TIÊN, không phải cái duy nhất
///
/// Mọi hiểu biết về Excel dừng lại ở lớp này. Thứ đi ra là `Product`,
/// `ProductVariant`, `SupplierQuote`, `Customer`, `CustomerOrder`,
/// `SettlementLine` — không lớp nào trong số đó biết Excel tồn tại.
///
/// Ngày Shopify/Shopee vào, thứ thêm là **một lớp cạnh lớp này**, không phải
/// một cột trong `products`.
class XlsxCommerceSource implements CommerceImportSource {
  XlsxCommerceSource({
    required this.bytes,
    required this.fileName,
    required this.now,
    this.reader = const XlsxReader(),
  });

  final Uint8List bytes;
  final String fileName;
  final XlsxReader reader;
  final DateTime now;

  @override
  String get displayName => fileName;

  static const List<String> _requiredProductColumns = [
    'sku',
    'name',
    'selling_price',
  ];

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
              'Đây không phải file Excel. Chọn file .xlsx xuất từ sàn hoặc từ Excel.',
            XlsxProblem.notASpreadsheet =>
              'File mở được nhưng không có bảng nào bên trong.',
            XlsxProblem.corrupt => 'File hỏng, không đọc được nội dung.',
          },
        ),
      );
    }

    final issues = <ImportIssue>[];
    final checksum = sha256.convert(bytes).toString();

    final productsSheet = _table(sheets, 'PRODUCTS');
    if (productsSheet == null) {
      return CommerceImportPreview.rejected(
        sourceName: fileName,
        issue: const ImportIssue(
          level: ImportIssueLevel.error,
          code: 'missing_products_sheet',
          subject: 'PRODUCTS',
          detail: 'File không có bảng sản phẩm nào tên PRODUCTS.',
        ),
      );
    }

    final missing = productsSheet.missingColumns(_requiredProductColumns);
    if (missing.isNotEmpty) {
      return CommerceImportPreview.rejected(
        sourceName: fileName,
        issue: ImportIssue(
          level: ImportIssueLevel.error,
          code: 'missing_columns',
          subject: 'PRODUCTS',
          detail:
              'Bảng sản phẩm thiếu cột: ${missing.join(", ")}. '
              'Bổ sung rồi nhập lại.',
          sheet: 'PRODUCTS',
        ),
      );
    }

    final products = _readProducts(productsSheet, issues);
    final productIds = {for (final p in products) p.id};

    final variants = _readVariants(
      _table(sheets, 'VARIANTS'),
      productIds,
      issues,
    );
    final quotes = _readQuotes(
      _table(sheets, 'SUPPLIER_QUOTES'),
      productIds,
      issues,
    );
    final customers = _readCustomers(_table(sheets, 'CUSTOMERS'), issues);
    final customerIds = {for (final c in customers) c.id};
    final orders = _readOrders(
      _table(sheets, 'ORDERS'),
      products,
      customerIds,
      issues,
    );
    final orderIds = {for (final o in orders) o.id};
    final settlements = _readSettlements(
      _table(sheets, 'SETTLEMENT'),
      orderIds,
      issues,
    );

    final shipments = _readShipments(
      _table(sheets, 'SHIPMENTS'),
      orderIds,
      issues,
    );

    return CommerceImportPreview(
      sourceName: fileName,
      checksum: checksum,
      products: products,
      shipments: shipments,
      variants: variants,
      quotes: quotes,
      customers: customers,
      orders: orders,
      settlements: settlements,
      issues: issues,
    );
  }

  SheetTable? _table(Map<String, List<List<String>>> sheets, String name) {
    for (final entry in sheets.entries) {
      if (entry.key.trim().toUpperCase() == name) {
        return SheetTable(name, entry.value);
      }
    }
    return null;
  }

  // ── sản phẩm ─────────────────────────────────────────────────────────────

  List<Product> _readProducts(SheetTable sheet, List<ImportIssue> issues) {
    final out = <Product>[];
    final seenSku = <String, int>{};

    for (var i = 0; i < sheet.dataRows.length; i++) {
      final row = sheet.dataRows[i];
      final rowNumber = i + 2; // +1 tiêu đề, +1 vì người đọc đếm từ 1
      final sku = sheet.cell(row, 'sku');
      final name = sheet.cell(row, 'name');

      if (sku.isEmpty && name.isEmpty) continue; // dòng trống ở cuối bảng

      if (sku.isEmpty || name.isEmpty) {
        issues.add(
          ImportIssue(
            level: ImportIssueLevel.error,
            code: 'missing_identity',
            subject: name.isEmpty ? 'Dòng $rowNumber' : name,
            detail: 'Thiếu ${sku.isEmpty ? "mã SKU" : "tên sản phẩm"}.',
            sheet: 'PRODUCTS',
            rowNumber: rowNumber,
          ),
        );
        continue;
      }

      final previous = seenSku[sku];
      if (previous != null) {
        // Trùng SKU là ERROR chứ không phải WARNING: hai sản phẩm cùng mã sẽ
        // gộp tồn kho và doanh thu của nhau, và không ai phát hiện ra cho tới
        // lúc kiểm kho.
        issues.add(
          ImportIssue(
            level: ImportIssueLevel.error,
            code: 'duplicate_sku',
            subject: name,
            detail: 'Trùng mã SKU "$sku" với dòng $previous.',
            sheet: 'PRODUCTS',
            rowNumber: rowNumber,
          ),
        );
        continue;
      }
      seenSku[sku] = rowNumber;

      final price = sheet.number(row, 'selling_price');
      if (price == null || price <= 0) {
        issues.add(
          ImportIssue(
            level: ImportIssueLevel.error,
            code: 'invalid_price',
            subject: name,
            detail: 'Giá bán không hợp lệ.',
            sheet: 'PRODUCTS',
            rowNumber: rowNumber,
          ),
        );
        continue;
      }

      final cost = sheet.number(row, 'cost_price');
      if (cost == null) {
        // WARNING, không phải ERROR: sản phẩm vẫn bán được, chỉ là chưa tính
        // được lời. Người bán quyết.
        issues.add(
          ImportIssue(
            level: ImportIssueLevel.warning,
            code: 'missing_cost',
            subject: name,
            detail: 'Chưa có giá vốn — sẽ nhập nhưng chưa tính được lời.',
            sheet: 'PRODUCTS',
            rowNumber: rowNumber,
          ),
        );
      }

      final quantity = sheet.number(row, 'quantity');
      if (quantity != null && quantity < 0) {
        issues.add(
          ImportIssue(
            level: ImportIssueLevel.warning,
            code: 'negative_quantity',
            subject: name,
            detail: 'Tồn kho âm (${quantity.toInt()}) — sẽ nhập thành 0.',
            sheet: 'PRODUCTS',
            rowNumber: rowNumber,
          ),
        );
      }

      final externalId = sheet.cell(row, 'product_id').isNotEmpty
          ? sheet.cell(row, 'product_id')
          : sheet.cell(row, 'external_id');

      out.add(
        Product(
          // Id nội bộ suy ra từ mã ở nguồn: nhập lại **cùng** file thì ghi đè
          // đúng bản ghi cũ thay vì sinh bản thứ hai.
          id: 'import-${externalId.isEmpty ? sku : externalId}',
          sku: sku,
          name: name,
          category: sheet.cell(row, 'category'),
          description: sheet.cell(row, 'description'),
          pricePerUnit: price,
          costPrice: cost,
          // `null` đi thẳng xuống: ô trống nghĩa là *không theo dõi tồn*, và
          // đó phải sống sót tới tận cột NULL (ADR-TON-023).
          quantity: quantity == null
              ? null
              : (quantity < 0 ? 0 : quantity.round()),
          reorderLevel: sheet.integer(row, 'reorder_level'),
          updatedAt: sheet.date(row, 'updated_at') ?? now,
          brand: _blankToNull(sheet.cell(row, 'brand')),
          imageUrl: _blankToNull(sheet.cell(row, 'image_url')),
          externalId: _blankToNull(externalId),
          provenance: ProvenanceSource.fileBridge,
        ),
      );
    }
    return out;
  }

  // ── phiên bản ────────────────────────────────────────────────────────────

  List<ProductVariant> _readVariants(
    SheetTable? sheet,
    Set<String> productIds,
    List<ImportIssue> issues,
  ) {
    if (sheet == null || sheet.isEmpty) return const [];
    final out = <ProductVariant>[];

    for (var i = 0; i < sheet.dataRows.length; i++) {
      final row = sheet.dataRows[i];
      final rowNumber = i + 2;
      final external = sheet.cell(row, 'product_id');
      if (external.isEmpty) continue;

      final productId = 'import-$external';
      if (!productIds.contains(productId)) {
        // Phiên bản mồ côi: ERROR cho **dòng đó**, không chặn cả file.
        issues.add(
          ImportIssue(
            level: ImportIssueLevel.error,
            code: 'orphan_variant',
            subject: sheet.cell(row, 'variant_name'),
            detail: 'Phiên bản trỏ tới sản phẩm không có trong file.',
            sheet: 'VARIANTS',
            rowNumber: rowNumber,
          ),
        );
        continue;
      }

      final id = sheet.cell(row, 'variant_id');
      final name = sheet.cell(row, 'variant_name');
      if (id.isEmpty || name.isEmpty) continue;

      out.add(
        ProductVariant(
          id: 'import-$id',
          productId: productId,
          name: name,
          sku: sheet.cell(row, 'sku'),
          option1Name: _blankToNull(sheet.cell(row, 'option_1_name')),
          option1Value: _blankToNull(sheet.cell(row, 'option_1_value')),
          option2Name: _blankToNull(sheet.cell(row, 'option_2_name')),
          option2Value: _blankToNull(sheet.cell(row, 'option_2_value')),
          // Ô trống = kế thừa giá sản phẩm mẹ, KHÔNG phải 0 đồng.
          costPrice: sheet.number(row, 'cost_price'),
          sellingPrice: sheet.number(row, 'selling_price'),
          quantity: sheet.number(row, 'quantity'),
          externalId: id,
          provenance: ProvenanceSource.fileBridge,
        ),
      );
    }
    return out;
  }

  // ── báo giá ──────────────────────────────────────────────────────────────

  List<SupplierQuote> _readQuotes(
    SheetTable? sheet,
    Set<String> productIds,
    List<ImportIssue> issues,
  ) {
    if (sheet == null || sheet.isEmpty) return const [];
    final out = <SupplierQuote>[];

    for (var i = 0; i < sheet.dataRows.length; i++) {
      final row = sheet.dataRows[i];
      final external = sheet.cell(row, 'product_id');
      final productId = 'import-$external';
      if (external.isEmpty || !productIds.contains(productId)) continue;

      final cost = sheet.number(row, 'unit_cost');
      final supplierName = sheet.cell(row, 'supplier_name');
      if (cost == null || supplierName.isEmpty) continue;

      out.add(
        SupplierQuote(
          id: 'import-${sheet.cell(row, "quote_id")}',
          productId: productId,
          supplierId: _blankToNull(sheet.cell(row, 'supplier_id')),
          supplierName: supplierName,
          unitCost: cost,
          currency: sheet.cell(row, 'currency').isEmpty
              ? 'VND'
              : sheet.cell(row, 'currency'),
          minimumOrderQuantity: sheet.number(row, 'minimum_order_quantity'),
          // Ô trống = **chưa biết**. So sánh sẽ nói "chưa biết" thay vì đoán
          // (§17: không fake độ chính xác khi không có input).
          leadTimeDays: sheet.integer(row, 'lead_time_days'),
          rating: sheet.number(row, 'rating'),
          sourceUrl: _blankToNull(sheet.cell(row, 'source_url')),
          notes: _blankToNull(sheet.cell(row, 'notes')),
          externalId: sheet.cell(row, 'quote_id'),
          provenance: ProvenanceSource.fileBridge,
          quotedAt: sheet.date(row, 'quoted_at') ?? now,
        ),
      );
    }
    return out;
  }

  // ── khách hàng ───────────────────────────────────────────────────────────

  List<Customer> _readCustomers(SheetTable? sheet, List<ImportIssue> issues) {
    if (sheet == null || sheet.isEmpty) return const [];
    final out = <Customer>[];

    for (final row in sheet.dataRows) {
      final id = sheet.cell(row, 'customer_id');
      final name = sheet.cell(row, 'name');
      if (id.isEmpty || name.isEmpty) continue;

      out.add(
        Customer(
          id: 'import-$id',
          name: name,
          phone: sheet.cell(row, 'phone'),
          location: sheet.cell(row, 'channel').isEmpty
              ? ''
              : sheet.cell(row, 'channel'),
          email: sheet.cell(row, 'email'),
          orderCount: sheet.integer(row, 'order_count') ?? 0,
          totalSpent: sheet.number(row, 'total_spent') ?? 0,
          // `null` = chưa mua lần nào. Ép thành hôm nay sẽ biến một khách chưa
          // bao giờ mua thành một khách vừa mua sáng nay.
          lastPurchaseDate: sheet.date(row, 'last_order'),
          segments: [
            // WTM-381: quy về mã canonical ngay tại cửa nhập. Ô của bảng tính
            // mang mã máy (`one_time`, `dormant`); in thẳng lên màn là đưa chữ
            // của máy cho người bán đọc.
            if (sheet.cell(row, 'segment').trim().isNotEmpty)
              CustomerSegment.normalise(sheet.cell(row, 'segment')),
          ],
        ),
      );
    }
    return out;
  }

  // ── đơn hàng ─────────────────────────────────────────────────────────────

  List<CustomerOrder> _readOrders(
    SheetTable? sheet,
    List<Product> products,
    Set<String> customerIds,
    List<ImportIssue> issues,
  ) {
    if (sheet == null || sheet.isEmpty) return const [];
    final byId = {for (final p in products) p.id: p};
    final out = <CustomerOrder>[];
    final seen = <String>{};

    for (var i = 0; i < sheet.dataRows.length; i++) {
      final row = sheet.dataRows[i];
      final rowNumber = i + 2;
      final orderId = sheet.cell(row, 'order_id');
      if (orderId.isEmpty) continue;

      if (!seen.add(orderId)) {
        issues.add(
          ImportIssue(
            level: ImportIssueLevel.error,
            code: 'duplicate_order',
            subject: orderId,
            detail: 'Mã đơn trùng — chỉ nhập lần xuất hiện đầu tiên.',
            sheet: 'ORDERS',
            rowNumber: rowNumber,
          ),
        );
        continue;
      }

      final product = byId['import-${sheet.cell(row, "product_id")}'];
      if (product == null) {
        // §7 — không tạo doanh thu giả không liên kết Product.
        issues.add(
          ImportIssue(
            level: ImportIssueLevel.error,
            code: 'orphan_order',
            subject: orderId,
            detail: 'Đơn trỏ tới sản phẩm không có trong file.',
            sheet: 'ORDERS',
            rowNumber: rowNumber,
          ),
        );
        continue;
      }

      final customerId = sheet.cell(row, 'customer_id');
      final resolvedCustomer = 'import-$customerId';
      if (customerId.isNotEmpty && !customerIds.contains(resolvedCustomer)) {
        issues.add(
          ImportIssue(
            level: ImportIssueLevel.warning,
            code: 'unknown_customer',
            subject: orderId,
            detail: 'Khách của đơn này không có trong file.',
            sheet: 'ORDERS',
            rowNumber: rowNumber,
          ),
        );
      }

      final quantity = sheet.integer(row, 'quantity') ?? 1;
      final unitPrice = sheet.number(row, 'unit_price') ?? product.pricePerUnit;

      out.add(
        CustomerOrder(
          id: 'import-$orderId',
          customerId: resolvedCustomer,
          orderNumber: orderId,
          date: sheet.date(row, 'order_date') ?? now,
          status: _orderStatus(sheet.cell(row, 'status')),
          items: [
            OrderItem(
              productId: product.id,
              productName: product.name,
              sku: product.sku,
              category: product.category,
              quantity: quantity,
              unitPrice: unitPrice,
            ),
          ],
          channel: SalesChannel.fromCode(sheet.cell(row, 'channel')),
          // Bản ghi **tự khai** nguồn gốc — không phải suy ra từ tiền tố id.
          provenance: const Provenance.declared(ProvenanceSource.fileBridge),
        ),
      );
    }
    return out;
  }

  // ── đối soát ─────────────────────────────────────────────────────────────

  List<SettlementLine> _readSettlements(
    SheetTable? sheet,
    Set<String> orderIds,
    List<ImportIssue> issues,
  ) {
    if (sheet == null || sheet.isEmpty) return const [];
    final out = <SettlementLine>[];

    for (var i = 0; i < sheet.dataRows.length; i++) {
      final row = sheet.dataRows[i];
      final rowNumber = i + 2;
      final orderRef = sheet.cell(row, 'order_id');
      final orderId = 'import-$orderRef';

      if (!orderIds.contains(orderId)) {
        // Một dòng phí không gắn được vào đơn nào sẽ làm lợi nhuận sai mà
        // không ai truy được về đâu — ERROR, bỏ dòng.
        issues.add(
          ImportIssue(
            level: ImportIssueLevel.error,
            code: 'orphan_settlement',
            subject: orderRef.isEmpty ? 'Dòng $rowNumber' : orderRef,
            detail: 'Khoản phí không gắn được vào đơn nào.',
            sheet: 'SETTLEMENT',
            rowNumber: rowNumber,
          ),
        );
        continue;
      }

      final amount = sheet.number(row, 'amount');
      if (amount == null || amount < 0) continue;

      final kind = _settlementKind(sheet.cell(row, 'kind'));
      out.add(
        SettlementLine(
          id: 'import-${sheet.cell(row, "settlement_id")}',
          orderId: orderId,
          kind: kind,
          // Phí và hoàn tiền đi **ra** khỏi túi người bán.
          direction: kind == SettlementKind.refund
              ? SettlementDirection.outbound
              : SettlementDirection.outbound,
          amount: amount,
          currency: sheet.cell(row, 'currency').isEmpty
              ? 'VND'
              : sheet.cell(row, 'currency'),
          occurredAt: sheet.date(row, 'occurred_at') ?? now,
          fundedBy:
              FundingSource.fromCode(sheet.cell(row, 'funded_by')) ??
              FundingSource.seller,
          // Bản ghi **tự khai** nguồn gốc — không phải suy ra từ tiền tố id.
          provenance: const Provenance.declared(ProvenanceSource.fileBridge),
        ),
      );
    }
    return out;
  }

  // ── vận chuyển ───────────────────────────────────────────────────────────

  List<Shipment> _readShipments(
    SheetTable? sheet,
    Set<String> orderIds,
    List<ImportIssue> issues,
  ) {
    if (sheet == null || sheet.isEmpty) return const [];
    final out = <Shipment>[];

    for (var i = 0; i < sheet.dataRows.length; i++) {
      final row = sheet.dataRows[i];
      final tracking = sheet.cell(row, 'tracking_number');
      if (tracking.isEmpty) continue;

      final status = _shipmentStatus(sheet.cell(row, 'shipment_status'));
      if (status == null) {
        // Trạng thái lạ ⇒ bỏ dòng. Rơi về "đang giao" sẽ khiến một kiện đã
        // hoàn về kho trông như đang trên đường tới khách.
        issues.add(
          ImportIssue(
            level: ImportIssueLevel.warning,
            code: 'unknown_shipment_status',
            subject: tracking,
            detail:
                'Trạng thái "${sheet.cell(row, "shipment_status")}" chưa biết '
                '— bỏ qua chuyến này.',
            sheet: 'SHIPMENTS',
            rowNumber: i + 2,
          ),
        );
        continue;
      }

      final orderRef = sheet.cell(row, 'order_id');
      final orderId = orderRef.isEmpty ? null : 'import-$orderRef';
      if (orderId != null && !orderIds.contains(orderId)) {
        issues.add(
          ImportIssue(
            level: ImportIssueLevel.warning,
            code: 'shipment_without_order',
            subject: tracking,
            detail: 'Chuyến này không gắn được vào đơn nào trong file.',
            sheet: 'SHIPMENTS',
            rowNumber: i + 2,
          ),
        );
      }

      out.add(
        Shipment(
          id: 'import-${sheet.cell(row, "shipment_id")}',
          orderId: orderId,
          trackingNumber: tracking,
          // Tên hãng trong file là nhãn hiển thị; mã canonical suy ra từ nó,
          // và không suy ra được thì để `null` chứ không đoán.
          carrier: _carrier(sheet.cell(row, 'carrier'), tracking),
          status: status,
          lastUpdate: sheet.date(row, 'last_update'),
          eta: sheet.date(row, 'eta'),
          origin: _blankToNull(sheet.cell(row, 'origin')),
          destination: _blankToNull(sheet.cell(row, 'destination')),
          notes: _blankToNull(sheet.cell(row, 'notes')),
          externalId: sheet.cell(row, 'shipment_id'),
          provenance: ProvenanceSource.fileBridge,
        ),
      );
    }
    return out;
  }

  static ShipmentStatus? _shipmentStatus(String raw) =>
      switch (raw.toLowerCase()) {
        'delivered' || 'đã giao' => ShipmentStatus.delivered,
        'in_transit' || 'đang giao' => ShipmentStatus.inTransit,
        // Chậm **không phải** một trạng thái riêng: kiện vẫn đang trên đường.
        // Việc nó chậm là kết luận của Rule Twin, không phải một ô trong file.
        'delayed' => ShipmentStatus.inTransit,
        'failed' => ShipmentStatus.failed,
        'created' || 'chờ lấy hàng' => ShipmentStatus.created,
        'returning' || 'hoàn hàng' => ShipmentStatus.returning,
        _ => null,
      };

  static Carrier? _carrier(String label, String tracking) {
    final normalised = label.toLowerCase().replaceAll(RegExp(r'[\s&]+'), '');
    for (final carrier in Carrier.values) {
      final name = carrier.displayName.toLowerCase().replaceAll(
        RegExp(r'[\s&]+'),
        '',
      );
      if (normalised == carrier.code || normalised == name) return carrier;
    }
    return Carrier.guessFrom(tracking);
  }

  static OrderStatus _orderStatus(String raw) => switch (raw.toLowerCase()) {
    'completed' || 'delivered' || 'done' => OrderStatus.delivered,
    'shipped' || 'in_transit' => OrderStatus.shipped,
    'confirmed' => OrderStatus.confirmed,
    'refunded' ||
    'returned' ||
    'cancelled' ||
    'canceled' => OrderStatus.cancelled,
    // Trạng thái lạ ⇒ **`pending`**, không phải `delivered`. Một đơn chưa biết
    // trạng thái mà tính vào doanh thu là bịa doanh thu.
    _ => OrderStatus.pending,
  };

  /// Sàn dùng nhiều tên cho cùng một khoản. Ánh xạ về từ vựng đóng.
  static SettlementKind _settlementKind(String raw) =>
      switch (raw.toLowerCase()) {
        'commission' => SettlementKind.commission,
        // Phí thanh toán **là** một khoản sàn thu, nhưng không phải hoa hồng —
        // gộp vào `commission` sẽ làm hai con số khác nhau trông như một.
        'payment_fee' || 'payment' => SettlementKind.platformFee,
        'platform_fee' || 'platform' => SettlementKind.platformFee,
        'shipping_fee' || 'shipping' => SettlementKind.shippingFee,
        'discount' => SettlementKind.discount,
        'voucher' => SettlementKind.voucher,
        'refund' => SettlementKind.refund,
        'adjustment' => SettlementKind.adjustment,
        'tax' => SettlementKind.tax,
        // Mã lạ ⇒ `unknown`, và `unknown` là một câu trả lời thật: khoản này
        // có tồn tại, ta chỉ chưa biết gọi nó là gì.
        _ => SettlementKind.unknown,
      };

  static String? _blankToNull(String value) => value.isEmpty ? null : value;
}
