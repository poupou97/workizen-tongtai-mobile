import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tongtai_inventory_provider.dart';
import 'tongtai_orders_provider.dart';
import '../consumer/customer_insight.dart';
import '../consumer/customer_repository.dart';
import 'tongtai_chat_provider.dart' show tongtaiDatabaseProvider;

/// The real, persistent customer source (WTM-123) — Drift over the local
/// business's customers. **User Data First**: a new user starts empty; the
/// sample directory is Demo-Mode only ([SampleCustomerRepository]) and is never
/// wired here. Tests inject an in-memory repository instead.
final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => DriftCustomerRepository(ref.watch(tongtaiDatabaseProvider)),
);

/// **Gợi ý cho một khách** — WTM-347.
///
/// `family` theo khách: mở màn nào thì đọc màn đó. Đưa vào
/// `kBusinessDataProviders` sẽ phải liệt kê từng khách một, tức là không đưa
/// được — nên nó nằm trong allowlist của governance kèm lý do này.
final customerSuggestionsProvider =
    FutureProvider.family<List<ProductSuggestion>, String>((
      ref,
      customerId,
    ) async {
      final orders = await ref.watch(orderRepositoryProvider).loadAll();
      final products = await ref.watch(productRepositoryProvider).loadAll();
      return suggestionsFor(
        customerId: customerId,
        orders: orders,
        products: products,
      );
    });
