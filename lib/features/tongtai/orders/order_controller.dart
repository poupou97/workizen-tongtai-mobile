import 'package:flutter/foundation.dart';

import 'order.dart';
import 'order_repository.dart';

/// Working set of sales orders backing the Orders capability (WTM-125), reads/
/// writes through an [OrderRepository] — Drift (real, persistent), Sample (demo)
/// or in-memory (tests). Same repo-backed `hydrate`/`upsert` pattern as the
/// other capability controllers. Orders owns revenue + lifecycle; downstream
/// consumers (Reports, Home, Consumer history) read orders through this seam,
/// never their own sample copy.
class OrderController extends ChangeNotifier {
  OrderController(this._repository);

  /// Demo/preview orders (read-only sample data). Not persisted.
  factory OrderController.sample() =>
      OrderController(const SampleOrderRepository());

  /// In-memory orders for tests, optionally pre-filled.
  factory OrderController.inMemory([
    Iterable<CustomerOrder> initial = const [],
  ]) => OrderController(InMemoryOrderRepository(initial));

  final OrderRepository _repository;
  final List<CustomerOrder> _orders = [];
  bool _hydrated = false;

  /// True once [hydrate] has loaded from the repository.
  bool get isHydrated => _hydrated;

  /// Current orders, newest first, as an unmodifiable snapshot.
  List<CustomerOrder> get orders {
    final sorted = List.of(_orders)..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(sorted);
  }

  /// Number of orders.
  int get count => _orders.length;

  /// Orders for one customer, newest first.
  List<CustomerOrder> forCustomer(String customerId) =>
      orders.where((o) => o.customerId == customerId).toList();

  /// Loads all orders from the repository (call once when a screen mounts).
  Future<void> hydrate() async {
    final loaded = await _repository.loadAll();
    _orders
      ..clear()
      ..addAll(loaded);
    _hydrated = true;
    notifyListeners();
  }

  /// Persist [order] (new id) or replace the existing order with the same id,
  /// then notify listeners. Returns `true` when it replaced (edit), `false`
  /// when appended (add).
  Future<bool> upsert(CustomerOrder order) async {
    await _repository.upsert(order);
    final index = _orders.indexWhere((o) => o.id == order.id);
    final replaced = index >= 0;
    if (replaced) {
      _orders[index] = order;
    } else {
      _orders.add(order);
    }
    notifyListeners();
    return replaced;
  }
}
