import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../consumer/customer_repository.dart';
import 'tongtai_chat_provider.dart' show tongtaiDatabaseProvider;

/// The real, persistent customer source (WTM-123) — Drift over the local
/// business's customers. **User Data First**: a new user starts empty; the
/// sample directory is Demo-Mode only ([SampleCustomerRepository]) and is never
/// wired here. Tests inject an in-memory repository instead.
final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => DriftCustomerRepository(ref.watch(tongtaiDatabaseProvider)),
);
