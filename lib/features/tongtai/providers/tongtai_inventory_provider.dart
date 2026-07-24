import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../inventory/product_repository.dart';
import 'tongtai_chat_provider.dart' show tongtaiDatabaseProvider;

/// The real, persistent product source (WTM-121, ADR-TON-009) — Drift over the
/// local business's products (structured columns + versioned domain snapshot).
/// **User Data First**: a new user starts with an empty catalogue; the sample
/// catalogue is Demo-Mode only ([SampleProductRepository]). Tests inject an
/// in-memory controller instead.
final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => DriftProductRepository(ref.watch(tongtaiDatabaseProvider)),
);
