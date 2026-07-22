import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in main() with the real instance; tests override too.
/// (Extracted from the Hub's mascot_state.dart during the repo split —
/// Tổng Tài must not depend on Hub feature code, per ADR-TON-001.)
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);
