import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/tongtai_tab_state_provider.dart';

/// A [TextField] whose value is remembered per tab + field id (WTM-56).
///
/// Restores any previously entered text for `(tabIndex, fieldKey)` on build
/// and writes every change back to the tab-state cache, so a half-filled form
/// survives navigating away and returning — and, because the cache is
/// persisted, an app restart too. A manual refresh of the tab clears the field.
class TongtaiPersistentTextField extends ConsumerStatefulWidget {
  const TongtaiPersistentTextField({
    required this.tabIndex,
    required this.fieldKey,
    this.decoration,
    this.keyboardType,
    this.maxLines = 1,
    super.key,
  });

  /// Tab this field belongs to (see `TongtaiTabs`).
  final int tabIndex;

  /// Stable id for this field within the tab (e.g. `'note'`, `'search'`).
  final String fieldKey;

  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  ConsumerState<TongtaiPersistentTextField> createState() =>
      _TongtaiPersistentTextFieldState();
}

class _TongtaiPersistentTextFieldState
    extends ConsumerState<TongtaiPersistentTextField> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    final saved = ref
        .read(tongtaiTabStateProvider.notifier)
        .stateFor(widget.tabIndex)
        .formValues[widget.fieldKey];
    _textController = TextEditingController(text: saved ?? '');
    _textController.addListener(_onChanged);
  }

  void _onChanged() {
    ref.read(tongtaiTabStateProvider.notifier).saveFormValue(
          widget.tabIndex,
          widget.fieldKey,
          _textController.text,
        );
  }

  @override
  void dispose() {
    _textController.removeListener(_onChanged);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // React to an external refresh/clear: reflect the cleared value in the box.
    ref.listen(tongtaiTabStateProvider, (previous, next) {
      final cached = next[widget.tabIndex]?.formValues[widget.fieldKey] ?? '';
      if (cached.isEmpty && _textController.text.isNotEmpty) {
        // Reset without re-triggering a save loop.
        _textController.removeListener(_onChanged);
        _textController.clear();
        _textController.addListener(_onChanged);
      }
    });

    return TextField(
      controller: _textController,
      decoration: widget.decoration,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
    );
  }
}
