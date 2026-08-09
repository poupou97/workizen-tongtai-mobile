import 'package:flutter/foundation.dart';

import '../../profile/business_profile.dart' show SalesChannel;

/// Nhận dạng file xuất từ sàn — WTM-322 (C6 · Epic WTM-315).
///
/// ## ⚠️ Tôi KHÔNG có file thật của Shopee/TikTok
///
/// Tên cột dưới đây đến từ tài liệu và từ các bản xuất công khai, **chưa đối
/// chiếu với một file thật của Founder**. Nói ra điều đó ở đây vì nó quyết
/// định cách lớp này được thiết kế.
///
/// Cách sai: đoán một bộ tên cột rồi hardcode. Ngày gặp file thật, app báo
/// *"không đọc được"* và không ai biết vì sao.
///
/// Cách ở đây: **nhận dạng theo điểm số trên nhiều bí danh**, và khi không
/// khớp thì **báo cáo đúng những cột nó nhìn thấy**. File thật sẽ tự nói cho ta
/// biết tên cột thật của nó, thay vì bắt ta đi tìm.
///
/// ## Hai file, không phải một
///
/// | File | Cho gì |
/// |---|---|
/// | Đơn hàng | doanh thu · khách · sản phẩm |
/// | **Báo cáo thu nhập** | **phí sàn · hoa hồng · vận chuyển · voucher · payout** |
///
/// Thiếu file thứ hai ⇒ app tính **doanh thu đúng mà lợi nhuận sai** — con số
/// nguy hiểm nhất có thể in ra.
@immutable
class MarketplaceProfile {
  const MarketplaceProfile({
    required this.vendor,
    required this.displayName,
    required this.channel,
    required this.orderColumns,
    required this.incomeColumns,
  });

  /// Mã canonical — khớp `ConnectionCatalog` và `ActionVendor`.
  final String vendor;

  final String displayName;

  /// Kênh bán, để lời thật biết đơn này **phải có** phí sàn.
  final SalesChannel channel;

  /// Bí danh cột của **file đơn hàng**, theo vai trò canonical.
  final Map<MarketplaceField, List<String>> orderColumns;

  /// Bí danh cột của **báo cáo thu nhập**.
  final Map<MarketplaceField, List<String>> incomeColumns;

  /// Điểm khớp của một bộ tiêu đề với hồ sơ này, cho một loại file.
  ///
  /// Không phải "khớp hết hay không": file thật luôn có cột thừa và đôi khi
  /// thiếu cột phụ. Điểm số cho phép chọn hồ sơ **gần nhất** rồi nói ra phần
  /// chưa khớp, thay vì từ chối cả file.
  int scoreFor(List<String> headers, MarketplaceFileKind kind) {
    final columns = kind == MarketplaceFileKind.orders
        ? orderColumns
        : incomeColumns;
    final normalised = headers.map(_normalise).toSet();
    var score = 0;
    for (final aliases in columns.values) {
      for (final alias in aliases) {
        if (normalised.contains(_normalise(alias))) {
          score++;
          break;
        }
      }
    }
    return score;
  }

  /// Tên cột thật ứng với một vai trò, `null` khi file không có.
  String? columnFor(
    List<String> headers,
    MarketplaceField field,
    MarketplaceFileKind kind,
  ) {
    final aliases = (kind == MarketplaceFileKind.orders
        ? orderColumns
        : incomeColumns)[field];
    if (aliases == null) return null;
    for (final header in headers) {
      for (final alias in aliases) {
        if (_normalise(header) == _normalise(alias)) return header;
      }
    }
    return null;
  }

  /// So sánh bỏ qua hoa/thường, dấu cách, gạch dưới và ngoặc.
  ///
  /// File sàn hay có `Order ID`, `order_id`, `Mã đơn hàng`, `Mã đơn hàng (*)` —
  /// bốn cách viết của một cột.
  static String _normalise(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[\s_\-\.\(\)\*:]+'), '').trim();

  /// Hồ sơ đã biết. **Dữ liệu**, không phải `switch` — thêm sàn là thêm một
  /// mục, không phải sửa parser.
  static const List<MarketplaceProfile> all = [
    MarketplaceProfile(
      vendor: 'shopee',
      displayName: 'Shopee',
      channel: SalesChannel.shopee,
      orderColumns: {
        MarketplaceField.orderId: [
          'Mã đơn hàng',
          'Order ID',
          'order_sn',
          'Order SN',
        ],
        MarketplaceField.orderDate: [
          'Ngày đặt hàng',
          'Order Creation Date',
          'create_time',
        ],
        MarketplaceField.status: ['Trạng thái đơn hàng', 'Order Status'],
        MarketplaceField.sku: [
          'SKU phân loại hàng',
          'SKU Reference No.',
          'sku',
        ],
        MarketplaceField.productName: ['Tên sản phẩm', 'Product Name'],
        MarketplaceField.quantity: ['Số lượng', 'Quantity'],
        MarketplaceField.unitPrice: ['Giá gốc', 'Original Price', 'Deal Price'],
        MarketplaceField.buyerName: ['Người Mua', 'Username (Buyer)'],
        MarketplaceField.buyerId: ['Mã người mua', 'Buyer User ID'],
      },
      incomeColumns: {
        MarketplaceField.orderId: ['Mã đơn hàng', 'Order ID', 'order_sn'],
        MarketplaceField.commission: [
          'Phí hoa hồng',
          'Commission Fee',
          'Phí cố định',
        ],
        MarketplaceField.transactionFee: [
          'Phí thanh toán',
          'Transaction Fee',
          'Phí giao dịch',
        ],
        MarketplaceField.serviceFee: ['Phí dịch vụ', 'Service Fee'],
        MarketplaceField.shippingFee: [
          'Phí vận chuyển',
          'Shipping Fee',
          'Phí vận chuyển người bán trả',
        ],
        MarketplaceField.voucher: [
          'Voucher từ Người bán',
          'Seller Voucher',
          'Khuyến mãi từ Người bán',
        ],
        MarketplaceField.platformVoucher: [
          'Voucher từ Shopee',
          'Shopee Voucher',
        ],
        MarketplaceField.payout: [
          'Tổng số tiền người bán nhận được',
          'Total Released Amount',
        ],
      },
    ),
    MarketplaceProfile(
      vendor: 'tiktok_shop',
      displayName: 'TikTok Shop',
      channel: SalesChannel.tiktok,
      orderColumns: {
        MarketplaceField.orderId: ['Order ID', 'Mã đơn hàng'],
        MarketplaceField.orderDate: ['Created Time', 'Thời gian tạo đơn'],
        MarketplaceField.status: ['Order Status', 'Trạng thái'],
        MarketplaceField.sku: ['Seller SKU', 'SKU'],
        MarketplaceField.productName: ['Product Name', 'Tên sản phẩm'],
        MarketplaceField.quantity: ['Quantity', 'Số lượng'],
        MarketplaceField.unitPrice: ['SKU Unit Original Price', 'Đơn giá'],
        MarketplaceField.buyerName: ['Buyer Username', 'Tên người mua'],
        MarketplaceField.buyerId: ['Buyer User ID'],
      },
      incomeColumns: {
        MarketplaceField.orderId: ['Order ID', 'Mã đơn hàng'],
        MarketplaceField.commission: [
          'Platform Commission',
          'Hoa hồng nền tảng',
        ],
        MarketplaceField.transactionFee: ['Transaction Fee', 'Phí giao dịch'],
        MarketplaceField.serviceFee: ['Affiliate Commission', 'Phí dịch vụ'],
        MarketplaceField.shippingFee: ['Shipping Cost', 'Phí vận chuyển'],
        MarketplaceField.voucher: ['Seller Discount', 'Giảm giá người bán'],
        MarketplaceField.platformVoucher: ['Platform Discount'],
        MarketplaceField.payout: ['Settlement Amount', 'Số tiền quyết toán'],
      },
    ),
  ];

  static MarketplaceProfile? byVendor(String vendor) {
    for (final p in all) {
      if (p.vendor == vendor) return p;
    }
    return null;
  }
}

/// Vai trò canonical của một cột — **không** phải tên cột của sàn nào.
enum MarketplaceField {
  orderId,
  orderDate,
  status,
  sku,
  productName,
  quantity,
  unitPrice,
  buyerName,
  buyerId,
  commission,
  transactionFee,
  serviceFee,
  shippingFee,
  voucher,

  /// Voucher **sàn tài trợ** — không phải chi phí của người bán.
  ///
  /// ADR-TON-024 gọi tên đúng chỗ này: nhầm nó thành chi phí làm lợi nhuận sai
  /// theo **hướng tâng bốc**, tức là kiểu sai không ai đi kiểm.
  platformVoucher,

  payout,
}

/// File này là loại gì.
enum MarketplaceFileKind {
  /// Đơn hàng — doanh thu · khách · sản phẩm.
  orders('orders'),

  /// Báo cáo thu nhập — phí · hoa hồng · vận chuyển · voucher · payout.
  income('income');

  const MarketplaceFileKind(this.code);

  final String code;
}

/// Kết quả nhận dạng một file.
@immutable
class MarketplaceMatch {
  const MarketplaceMatch({
    required this.profile,
    required this.kind,
    required this.score,
    required this.headers,
  });

  final MarketplaceProfile profile;
  final MarketplaceFileKind kind;
  final int score;
  final List<String> headers;

  /// Nhận ra chắc chắn chưa.
  ///
  /// Ngưỡng bốn cột: dưới mức đó thì rất có thể đang khớp nhầm với một file
  /// bất kỳ có cột tên "Số lượng".
  bool get isConfident => score >= 4;

  /// Tìm hồ sơ khớp nhất cho một bộ tiêu đề. `null` = không nhận ra.
  static MarketplaceMatch? detect(List<String> headers) {
    MarketplaceMatch? best;
    for (final profile in MarketplaceProfile.all) {
      for (final kind in MarketplaceFileKind.values) {
        final score = profile.scoreFor(headers, kind);
        if (best == null || score > best.score) {
          best = MarketplaceMatch(
            profile: profile,
            kind: kind,
            score: score,
            headers: headers,
          );
        }
      }
    }
    return best != null && best.isConfident ? best : null;
  }
}
