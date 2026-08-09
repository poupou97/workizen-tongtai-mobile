import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../commerce/commerce_repository.dart';
import 'tongtai_chat_provider.dart' show tongtaiDatabaseProvider;

/// **Miền thương mại chuẩn hoá, nối vào app** — WTM-327 (Epic WTM-324).
///
/// Riverpod-only (ADR-TON-002).
final commerceRepositoryProvider = Provider<CommerceRepository>(
  (ref) => CommerceRepository(ref.watch(tongtaiDatabaseProvider)),
);
