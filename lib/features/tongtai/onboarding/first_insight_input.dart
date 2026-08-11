import 'package:flutter/foundation.dart';

import '../consumer/customer.dart';
import '../analytics/customer_rfm.dart';
import '../predictive/customer_risk_rule.dart';
import '../predictive/business_alerts_rule.dart';
import '../finance/settlement.dart';
import '../inventory/product.dart';
import '../orders/order.dart';

/// Mọi thứ `FirstInsightEngine` cần, đã tải sẵn — WTM-354.
///
/// Một lớp riêng thay vì mười tham số: khi thêm một nguồn dữ liệu, chỗ phải
/// sửa là đây, và trình biên dịch chỉ ra mọi nơi dựng nó. Mười tham số vị trí
/// thì thêm cái thứ mười một là một lỗi im lặng.
@immutable
class FirstInsightInput {
  const FirstInsightInput({
    required this.now,
    required this.marketplaceOrdersWithoutFees,
    this.products = const [],
    this.orders = const [],
    this.customers = const [],
    this.profiles = const [],
    this.risk,
    this.alerts = const [],
    this.settlementLines = const [],
    this.payouts = const [],
  });

  final DateTime now;

  final List<Product> products;
  final List<CustomerOrder> orders;
  final List<Customer> customers;
  final List<CustomerRfm> profiles;

  /// `null` = Rule Twin **từ chối** chấm rủi ro vì thiếu dữ liệu, khác hẳn
  /// "không khách nào rủi ro".
  final CustomerRiskAssessment? risk;

  final List<BusinessAlert> alerts;
  final List<SettlementLine> settlementLines;
  final List<Payout> payouts;

  /// Số đơn bán qua sàn mà **chưa có dòng đối soát nào**.
  ///
  /// Bắt buộc truyền, không có mặc định `0`. Một giá trị mặc định ở đây sẽ làm
  /// lời thật trông như đã tính được trong khi phí sàn còn chưa về — đúng chỗ
  /// người bán Việt Nam mất tiền nhiều nhất mà báo cáo hay bỏ sót.
  final int marketplaceOrdersWithoutFees;
}
