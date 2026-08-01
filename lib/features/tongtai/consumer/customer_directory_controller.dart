import '../analytics/customer_rfm.dart';
import '../orders/order_repository.dart';
import 'package:flutter/foundation.dart';

import 'customer.dart';
import 'customer_directory_service.dart';
import 'customer_form.dart';
import 'customer_repository.dart';

/// Directory of customers backing the Customer list screen (WTM-75) and its
/// Add/Edit form (WTM-76), reads/writes through a [CustomerRepository]
/// (WTM-123) — Drift (real, persistent), Sample (demo) or in-memory (tests).
///
/// Holds the working set of customers and exposes a fresh
/// [CustomerDirectoryService] view for read-only querying/paging. Adds and edits
/// go through [upsert], which persists then notifies so the list rebuilds. The
/// UI never knows the source — same pattern as `ProductCatalogController`
/// (WTM-121).
class CustomerDirectoryController extends ChangeNotifier {
  CustomerDirectoryController(this._repository, {this.orders, this.clock});

  /// Where the counters come from (WTM-201).
  ///
  /// `Customer.orderCount`/`totalSpent`/`lastPurchaseDate` are stored fields
  /// that **nothing updates when the seller records an order**, so a customer
  /// who just bought something still read *"0 đơn · ₫0"* while RFM, Reports and
  /// the lifecycle ladder all counted the order. Derived here — in the one
  /// place every screen goes through — rather than in each screen, so the next
  /// screen cannot forget.
  ///
  /// Nullable so existing call sites compile; `null` means the stored values are
  /// shown as-is, which is only correct for fixtures that set them by hand.
  final OrderRepository? orders;

  /// Injectable clock for the derivation window.
  final DateTime Function()? clock;

  /// Demo/preview directory (read-only sample data). Not persisted.
  factory CustomerDirectoryController.sample() =>
      CustomerDirectoryController(const SampleCustomerRepository());

  /// In-memory directory for tests, optionally pre-filled.
  factory CustomerDirectoryController.inMemory([
    Iterable<Customer> initial = const [],
  ]) => CustomerDirectoryController(InMemoryCustomerRepository(initial));

  final CustomerRepository _repository;
  final List<Customer> _customers = [];
  bool _hydrated = false;

  /// True once [hydrate] has loaded from the repository.
  bool get isHydrated => _hydrated;

  /// Current customers as an unmodifiable snapshot.
  List<Customer> get customers => List.unmodifiable(_customers);

  /// Number of customers in the directory.
  int get count => _customers.length;

  /// A read-only query/paging view over the current customers. A new instance
  /// is returned each call so it always reflects the latest mutations.
  CustomerDirectoryService get service => CustomerDirectoryService(_customers);

  /// Possible duplicates of the entry being typed (WTM-76 AC5). Pass the edited
  /// customer's id as [exceptId] so a record never collides with itself.
  List<Customer> findDuplicates({
    required String name,
    required String phone,
    String? exceptId,
  }) => findCustomerDuplicates(
    _customers,
    name: name,
    phone: phone,
    exceptId: exceptId,
  );

  /// Loads the directory from the repository (call once when the screen mounts).
  Future<void> hydrate() async {
    final loaded = await _repository.loadAll();
    final source = orders;
    _customers
      ..clear()
      ..addAll(
        source == null
            ? loaded
            : deriveCustomerCounters(
                loaded,
                await source.loadAll(),
                now: (clock ?? DateTime.now)(),
              ),
      );
    _hydrated = true;
    notifyListeners();
  }

  /// Persist [customer] (new id) or replace the existing customer with the same
  /// id, then notify listeners. Returns `true` when it replaced an existing
  /// customer (edit), `false` when it was appended (add).
  Future<bool> upsert(Customer customer) async {
    await _repository.upsert(customer);
    final index = _customers.indexWhere((c) => c.id == customer.id);
    final replaced = index >= 0;
    if (replaced) {
      _customers[index] = customer;
    } else {
      _customers.add(customer);
    }
    notifyListeners();
    return replaced;
  }
}
