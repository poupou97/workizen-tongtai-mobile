import 'package:flutter/foundation.dart';

import 'customer.dart';
import 'customer_directory_service.dart';
import 'customer_form.dart';

/// Mutable, in-memory directory of customers backing the Customer list screen
/// (WTM-75) and its Add/Edit form (WTM-76).
///
/// Holds the working set of customers and exposes a fresh
/// [CustomerDirectoryService] view for read-only querying/paging. Adds and
/// edits go through [upsert], which notifies listeners so the list rebuilds.
/// Local-first, no backend; a Drift-backed store can replace the in-memory list
/// later without touching callers — same pattern as `ProductCatalogController`
/// (WTM-69).
class CustomerDirectoryController extends ChangeNotifier {
  CustomerDirectoryController(Iterable<Customer> initial)
    : _customers = [...initial];

  /// Convenience: a directory seeded with the built-in sample customers.
  factory CustomerDirectoryController.sample() =>
      CustomerDirectoryController(kSampleCustomers);

  final List<Customer> _customers;

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

  /// Insert [customer] (new id) or replace the existing customer with the same
  /// id, then notify listeners. Returns `true` when it replaced an existing
  /// customer (edit), `false` when it was appended (add).
  bool upsert(Customer customer) {
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
