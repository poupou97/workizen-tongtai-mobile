import '../consumer/customer.dart';
import '../consumer/customer_order.dart';
import '../consumer/customer_order_history_service.dart';
import '../core/tongtai_formatters.dart';
import '../inventory/product.dart';
import '../inventory/product_category.dart';

/// Builds the system prompt Workizen AI sends with every chat turn (WTM-82
/// AC2/AC3/AC4) — deterministic, local-only, no network.
///
/// Base identity + business snapshot always go in. When the seller's prompt
/// mentions a known customer, that customer's segment/tier, purchase history
/// and a tone instruction tailored to their segment are injected (AC2 + AC4).
/// When it mentions a known product, the product's price/stock details are
/// injected for grounded recommendations (AC3).
class WorkizenAiContextBuilder {
  /// WTM-144 (P0 §1): defaults are EMPTY, not samples — a real business must
  /// never be answered from fixture data. Production wiring passes the live
  /// repositories' rows; demo coherence comes from seeding those same
  /// repositories (ADR-TON-014).
  WorkizenAiContextBuilder({
    List<Customer>? customers,
    List<Product>? products,
    CustomerOrderHistoryService? orderHistory,
    Map<String, String>? productAttributeContext,
  }) : _customers = customers ?? const [],
       _products = products ?? const [],
       _orderHistory = orderHistory ?? CustomerOrderHistoryService(const []),
       _productAttributeContext = productAttributeContext ?? const {};

  final List<Customer> _customers;
  final List<Product> _products;
  final CustomerOrderHistoryService _orderHistory;

  /// Per-product **grouped** attribute context (WTM-335 §14), keyed by product
  /// id. Each value is already grouped text (`## <group>` / `- field: value`)
  /// produced by `buildAttributeAiContext` — never a raw key/value dump, and
  /// never carrying codes, ids or scope.
  ///
  /// It is *injected*, not read here: attributes load only on demand at the
  /// detail screen (ADR-TON-019), so a caller with a product in focus builds
  /// this map from that one read and passes it in. The whole-business chat
  /// leaves it empty, and the prompt simply omits the section — no list-path
  /// attribute read ever happens.
  final Map<String, String> _productAttributeContext;

  /// Customers whose name appears in [prompt] (case-insensitive).
  List<Customer> customersMentionedIn(String prompt) {
    final haystack = prompt.toLowerCase();
    return [
      for (final c in _customers)
        if (c.name.trim().isNotEmpty && haystack.contains(c.name.toLowerCase()))
          c,
    ];
  }

  /// Products whose name appears in [prompt] (case-insensitive).
  List<Product> productsMentionedIn(String prompt) {
    final haystack = prompt.toLowerCase();
    return [
      for (final p in _products)
        if (p.name.trim().isNotEmpty && haystack.contains(p.name.toLowerCase()))
          p,
    ];
  }

  /// The full system prompt for [prompt].
  String build(String prompt) {
    final buffer = StringBuffer()
      ..writeln(
        'Bạn là Workizen AI — trợ lý kinh doanh cho chủ shop SME Việt Nam '
        'trong ứng dụng Tổng Tài. Trả lời ngắn gọn, thực tế, bằng tiếng Việt '
        '(thêm English khi người dùng viết tiếng Anh). Chỉ dùng dữ liệu được '
        'cung cấp dưới đây; không bịa số liệu.',
      )
      ..writeln()
      ..writeln('## Toàn cảnh kinh doanh')
      ..writeln(_businessSnapshot());

    final customers = customersMentionedIn(prompt);
    for (final customer in customers.take(2)) {
      buffer
        ..writeln()
        ..writeln('## Khách hàng được nhắc tới: ${customer.name}')
        ..writeln(_customerContext(customer))
        ..writeln(_toneInstruction(customer));
    }

    final products = productsMentionedIn(prompt);
    for (final product in products.take(3)) {
      buffer
        ..writeln()
        ..writeln('## Sản phẩm được nhắc tới: ${product.name}')
        ..writeln(_productContext(product));
    }

    return buffer.toString().trimRight();
  }

  String _businessSnapshot() {
    final tierCounts = <CustomerTier, int>{};
    for (final c in _customers) {
      tierCounts[c.tier] = (tierCounts[c.tier] ?? 0) + 1;
    }
    final lowStock = _products.where((p) => p.needsRestock).length;
    final tierLine = CustomerTier.values
        .map((t) => '${t.labelVi}: ${tierCounts[t] ?? 0}')
        .join(' · ');
    return '- Khách hàng: ${_customers.length} ($tierLine)\n'
        '- Sản phẩm: ${_products.length} (cần nhập thêm: $lowStock)';
  }

  String _customerContext(Customer customer) {
    final orders = _orderHistory.ordersFor(customer.id);
    final lines = StringBuffer()
      ..writeln(
        '- Hạng: ${customer.tier.labelVi}'
        '${customer.segments.isEmpty ? '' : ' · Phân khúc: ${customer.segments.join(', ')}'}',
      )
      ..writeln(
        '- Đã mua ${customer.orderCount} đơn, tổng '
        '${TongtaiFormatters.vnd(customer.totalSpent)}',
      );
    if (orders.isEmpty) {
      lines.writeln('- Chưa có lịch sử đơn chi tiết trong máy.');
    } else {
      lines.writeln('- Đơn gần nhất:');
      for (final CustomerOrder order in orders.take(3)) {
        final items = order.items
            .map((i) => '${i.quantity}× ${i.productName}')
            .join(', ');
        lines.writeln(
          '  • ${order.orderNumber} (${TongtaiFormatters.isoDate(order.date)}, '
          '${order.status.labelVi}): $items — '
          '${TongtaiFormatters.vnd(order.totalAmount)}',
        );
      }
    }
    return lines.toString().trimRight();
  }

  /// AC4 — response tone tailored to the customer's segment/tier.
  String _toneInstruction(Customer customer) => switch (customer.tier) {
    CustomerTier.vip =>
      '- Giọng điệu: trang trọng, ưu tiên giữ chân khách VIP; chủ động đề '
          'xuất ưu đãi riêng.',
    CustomerTier.gold =>
      '- Giọng điệu: thân thiết, gợi ý nâng hạng lên VIP bằng combo/ưu đãi '
          'tích luỹ.',
    CustomerTier.silver =>
      '- Giọng điệu: khuyến khích mua lại; nhấn mạnh sản phẩm phù hợp lịch '
          'sử mua.',
    CustomerTier.bronze =>
      '- Giọng điệu: chào mừng khách mới, đơn giản, tạo tin tưởng; tránh '
          'thúc ép.',
  };

  String _productContext(Product product) {
    final core =
        '- SKU ${product.sku} · ${ProductCategory.display(product.category, 'vi')}\n'
        '- Giá bán: ${TongtaiFormatters.vnd(product.pricePerUnit)}'
        // Sản phẩm không có tồn kho thì KHÔNG nhắc tồn kho với AI: một dòng
        // "Tồn kho: 0" trong prompt là lời nói dối đi thẳng vào mô hình.
        '${product.quantity == null ? '' : ' · Tồn kho: ${product.quantity}'}'
        '${product.needsRestock ? ' (DƯỚI mức đặt lại ${product.reorderLevel} — cần nhập thêm)' : ''}';

    // §14: thuộc tính động đi vào prompt **đã gom nhóm**, không phải một đống
    // key-value thô — và chỉ khi sản phẩm này thật sự có (map rỗng ⇒ bỏ qua,
    // không thêm tiêu đề trống).
    final attributes = _productAttributeContext[product.id];
    if (attributes == null || attributes.trim().isEmpty) return core;
    return '$core\n$attributes';
  }
}
