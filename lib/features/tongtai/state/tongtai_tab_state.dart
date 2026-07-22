import 'package:flutter/foundation.dart';

/// Immutable snapshot of a single tab's UI state (WTM-56).
///
/// Captures the two things a user expects to survive tab switches and app
/// restarts: the [scrollOffset] of the tab's primary scroll view and any
/// in-progress [formValues] (keyed by a stable field id). The type is a plain
/// value object — it holds no controllers and is safe to persist as JSON.
@immutable
class TongtaiTabState {
  const TongtaiTabState({
    this.scrollOffset = 0.0,
    this.formValues = const {},
  });

  /// Saved vertical scroll position, in logical pixels.
  final double scrollOffset;

  /// Unsaved form input, keyed by a stable field id (e.g. `'note'`).
  final Map<String, String> formValues;

  /// Whether this state carries nothing worth restoring — used to prune empty
  /// entries so persisted storage does not grow with no-op tabs.
  bool get isEmpty => scrollOffset == 0.0 && formValues.isEmpty;

  TongtaiTabState copyWith({
    double? scrollOffset,
    Map<String, String>? formValues,
  }) {
    return TongtaiTabState(
      scrollOffset: scrollOffset ?? this.scrollOffset,
      formValues: formValues ?? this.formValues,
    );
  }

  /// Returns a copy with [fieldKey] set to [value].
  TongtaiTabState withFormValue(String fieldKey, String value) {
    return copyWith(
      formValues: {...formValues, fieldKey: value},
    );
  }

  /// Returns a copy with [fieldKey] removed (no-op if absent).
  TongtaiTabState withoutFormValue(String fieldKey) {
    if (!formValues.containsKey(fieldKey)) return this;
    final next = Map<String, String>.from(formValues)..remove(fieldKey);
    return copyWith(formValues: next);
  }

  Map<String, dynamic> toJson() => {
        'scrollOffset': scrollOffset,
        'formValues': formValues,
      };

  factory TongtaiTabState.fromJson(Map<String, dynamic> json) {
    final rawOffset = json['scrollOffset'];
    final rawForm = json['formValues'];
    return TongtaiTabState(
      scrollOffset: rawOffset is num ? rawOffset.toDouble() : 0.0,
      formValues: rawForm is Map
          ? rawForm.map((k, v) => MapEntry('$k', '$v'))
          : const {},
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TongtaiTabState &&
        other.scrollOffset == scrollOffset &&
        mapEquals(other.formValues, formValues);
  }

  @override
  int get hashCode => Object.hash(scrollOffset, Object.hashAllUnordered(
        formValues.entries.map((e) => Object.hash(e.key, e.value)),
      ));

  @override
  String toString() =>
      'TongtaiTabState(scrollOffset: $scrollOffset, formValues: $formValues)';
}
