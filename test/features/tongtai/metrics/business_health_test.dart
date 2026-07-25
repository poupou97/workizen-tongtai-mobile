import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/metrics/business_health.dart';
import 'package:tongtai/features/tongtai/metrics/business_metrics.dart';

/// WTM-128 — BusinessHealth is the coarse read Home renders. The v1 derivation
/// is a pure function of BusinessMetrics; a later AI assessor replaces it without
/// changing Home's UI contract (the enum + labels).
void main() {
  test('no sales → not enough data', () {
    expect(
      BusinessHealth.from(BusinessMetrics.empty),
      BusinessHealth.notEnoughData,
    );
  });

  test('with sales → healthy', () {
    final metrics = BusinessMetrics(
      revenue: 100000,
      ordersCount: 3,
      customersCount: 2,
      averageOrderValue: 33333,
    );
    expect(BusinessHealth.from(metrics), BusinessHealth.healthy);
  });

  test('bilingual labels', () {
    expect(BusinessHealth.healthy.label('en'), 'Healthy');
    expect(BusinessHealth.healthy.label('vi'), 'Khỏe mạnh');
    expect(BusinessHealth.notEnoughData.label('en'), 'Not enough data');
    expect(BusinessHealth.notEnoughData.label('vi'), 'Chưa đủ dữ liệu');
  });
}
