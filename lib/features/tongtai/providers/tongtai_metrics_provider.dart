import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../metrics/business_metrics_service.dart';
import 'tongtai_consumer_provider.dart';
import 'tongtai_orders_provider.dart';

/// The KPI single-source-of-truth (WTM-127) — [BusinessMetricsService] over the
/// persisted Orders + Consumer repositories. Reports and Home read their KPIs
/// from here (never their own calculation); tests inject in-memory repositories.
final businessMetricsServiceProvider = Provider<BusinessMetricsService>(
  (ref) => BusinessMetricsService(
    ref.watch(orderRepositoryProvider),
    ref.watch(customerRepositoryProvider),
  ),
);
