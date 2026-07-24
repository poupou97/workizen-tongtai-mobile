import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/finance_repository.dart';
import 'tongtai_chat_provider.dart' show tongtaiDatabaseProvider;

/// The real, persistent finance source (WTM-120) — Drift over the local
/// business's transactions. **User Data First**: a new user starts empty; the
/// sample ledger is Demo-Mode only ([SampleFinanceRepository]) and is never
/// wired here. Tests inject an in-memory controller instead.
final financeRepositoryProvider = Provider<FinanceRepository>(
  (ref) => DriftFinanceRepository(ref.watch(tongtaiDatabaseProvider)),
);
