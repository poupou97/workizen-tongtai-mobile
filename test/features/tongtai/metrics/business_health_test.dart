import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/metrics/business_health.dart';
import 'package:tongtai/features/tongtai/metrics/business_metrics.dart';

/// WTM-128/132 — BusinessHealth is the model Home renders (status + reason +
/// confidence). The v1 derivation is a pure function of BusinessMetrics; a later
/// AI assessor replaces it without changing Home's UI or API.
void main() {
  test('no sales → not enough data (model)', () {
    final h = BusinessHealth.from(BusinessMetrics.empty);
    expect(h, BusinessHealth.notEnoughData);
    expect(h.status, BusinessHealthStatus.notEnoughData);
    expect(h.isHealthy, isFalse);
    expect(h.reason, isNotEmpty);
    expect(h.confidence, 1.0); // rule-based v1
  });

  test('with sales → healthy (model)', () {
    final metrics = BusinessMetrics(
      revenue: 100000,
      ordersCount: 3,
      customersCount: 2,
      averageOrderValue: 33333,
    );
    final h = BusinessHealth.from(metrics);
    expect(h.status, BusinessHealthStatus.healthy);
    expect(h.isHealthy, isTrue);
    expect(h.confidence, 1.0);
  });

  test('bilingual status labels', () {
    expect(BusinessHealth.healthy.label('en'), 'Healthy');
    expect(BusinessHealth.healthy.label('vi'), 'Khỏe mạnh');
    expect(BusinessHealth.notEnoughData.label('en'), 'Not enough data');
    expect(BusinessHealth.notEnoughData.label('vi'), 'Chưa đủ dữ liệu');
    expect(BusinessHealthStatus.healthy.labelEn, 'Healthy');
  });
}
