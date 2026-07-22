import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/tongtai_tab_state_provider.dart';

/// A [SingleChildScrollView] whose scroll offset is remembered per tab (WTM-56).
///
/// On first layout it restores the offset previously saved for [tabIndex]
/// (from memory, or from local storage after an app restart); when the user
/// stops scrolling it writes the new offset back. If the tab is refreshed
/// (its cached state cleared) the view scrolls back to the top.
///
/// Drop-in replacement for a `SingleChildScrollView` inside a Tổng Tài tab —
/// just supply the [tabIndex] the screen lives on.
class TongtaiPersistentScrollView extends ConsumerStatefulWidget {
  const TongtaiPersistentScrollView({
    required this.tabIndex,
    required this.child,
    this.padding,
    this.physics,
    super.key,
  });

  /// Tab this scroll view belongs to (see `TongtaiTabs`).
  final int tabIndex;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  @override
  ConsumerState<TongtaiPersistentScrollView> createState() =>
      _TongtaiPersistentScrollViewState();
}

class _TongtaiPersistentScrollViewState
    extends ConsumerState<TongtaiPersistentScrollView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Restore after the first frame, once the viewport has been laid out and
    // maxScrollExtent is known.
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreOffset());
  }

  void _restoreOffset() {
    if (!mounted || !_scrollController.hasClients) return;
    final saved = ref
        .read(tongtaiTabStateProvider.notifier)
        .stateFor(widget.tabIndex)
        .scrollOffset;
    if (saved <= 0) return;
    final max = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(saved.clamp(0.0, max));
  }

  bool _onScrollEnd(ScrollEndNotification notification) {
    // Only persist offsets from our own scroll view (depth 0), not nested ones.
    if (notification.depth != 0) return false;
    ref
        .read(tongtaiTabStateProvider.notifier)
        .saveScrollOffset(widget.tabIndex, notification.metrics.pixels);
    return false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // React to an external refresh/clear of this tab: jump back to the top.
    ref.listen(tongtaiTabStateProvider, (previous, next) {
      final wasScrolled =
          (previous?[widget.tabIndex]?.scrollOffset ?? 0.0) > 0.0;
      final nowReset = (next[widget.tabIndex]?.scrollOffset ?? 0.0) == 0.0;
      if (wasScrolled &&
          nowReset &&
          _scrollController.hasClients &&
          _scrollController.offset != 0.0) {
        _scrollController.jumpTo(0);
      }
    });

    return NotificationListener<ScrollEndNotification>(
      onNotification: _onScrollEnd,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: widget.padding,
        physics: widget.physics,
        child: widget.child,
      ),
    );
  }
}
