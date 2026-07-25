import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../orders/order_repository.dart';
import 'tongtai_chat_provider.dart' show tongtaiDatabaseProvider;

/// The real, persistent Orders source (WTM-125) — Drift over the local
/// business's sales orders. **User Data First**: a new user has no orders; the
/// sample orders are Demo-Mode only ([SampleOrderRepository]) and are never
/// wired here. Reports and Home KPI consume this same repository (Founder G-2).
/// Tests inject an in-memory repository instead.
final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => DriftOrderRepository(ref.watch(tongtaiDatabaseProvider)),
);
