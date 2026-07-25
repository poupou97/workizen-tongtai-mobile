import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../metrics/business_context_service.dart';
import 'tongtai_consumer_provider.dart';
import 'tongtai_inventory_provider.dart';
import 'tongtai_orders_provider.dart';

/// The business Aggregate Root builder (WTM-129) — [BusinessContextService] over
/// the persisted Orders + Consumer + Inventory repositories. Home and (later)
/// Workizen AI consume the returned `BusinessContext`; **AI never reads a
/// repository directly**. Tests inject in-memory repositories.
final businessContextServiceProvider = Provider<BusinessContextService>(
  (ref) => BusinessContextService(
    ref.watch(orderRepositoryProvider),
    ref.watch(customerRepositoryProvider),
    ref.watch(productRepositoryProvider),
  ),
);
