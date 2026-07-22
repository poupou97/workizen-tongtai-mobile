// Deep-link route model + parse-result types for Tổng Tài (WTM-57).
//
// A *deep link* is an external `tongtai://…` URL (from a push notification,
// another app, or a shared link) that should open a specific screen. This file
// defines the vocabulary of destinations the app understands ([TongtaiRoute] +
// [TongtaiRouteKind]) and the outcome of trying to resolve one
// ([TongtaiDeepLinkResult]). Parsing/validation lives in
// `tongtai_deep_link_parser.dart`; navigation lives in the provider.
//
// The types here are pure value objects with no Flutter dependency, so they are
// trivially unit-testable and safe to reuse from any layer.

import 'package:flutter/foundation.dart';

import '../tongtai_design_tokens.dart' show TongtaiTabs;

/// The custom URL scheme every Tổng Tài deep link must use, e.g.
/// `tongtai://suppliers/42`.
const String kTongtaiDeepLinkScheme = 'tongtai';

/// Every screen a deep link can target.
///
/// Names follow the destination, not the URL, so several URL shapes can map to
/// the same kind (e.g. both `tongtai://suppliers/ID` and
/// `tongtai://producer/supplier/ID` resolve to [supplierDetail]).
enum TongtaiRouteKind {
  home,
  producer,
  supplierList,
  supplierDetail,
  inventoryProducts,
  productDetail,
  customerList,
  customerDetail,
  journey,
  opportunityDetail,
  reports,
  financeAccounts,
  chat,
  search;

  /// Which of the five bottom-nav tabs hosts this destination. Deep links can
  /// only *land* on one of these tabs (detail screens live inside a tab), so
  /// this is what the navigator selects.
  int get tabIndex => switch (this) {
    TongtaiRouteKind.home => TongtaiTabs.home,
    TongtaiRouteKind.journey => TongtaiTabs.home,
    TongtaiRouteKind.search => TongtaiTabs.home,
    TongtaiRouteKind.producer => TongtaiTabs.producer,
    TongtaiRouteKind.supplierList => TongtaiTabs.producer,
    TongtaiRouteKind.supplierDetail => TongtaiTabs.producer,
    TongtaiRouteKind.opportunityDetail => TongtaiTabs.producer,
    TongtaiRouteKind.inventoryProducts => TongtaiTabs.inventory,
    TongtaiRouteKind.productDetail => TongtaiTabs.inventory,
    TongtaiRouteKind.customerList => TongtaiTabs.consumer,
    TongtaiRouteKind.customerDetail => TongtaiTabs.consumer,
    TongtaiRouteKind.reports => TongtaiTabs.more,
    TongtaiRouteKind.financeAccounts => TongtaiTabs.more,
    TongtaiRouteKind.chat => TongtaiTabs.more,
  };

  /// Whether this destination is a specific record that needs an id
  /// (e.g. a single supplier), as opposed to a list or dashboard.
  bool get requiresId => switch (this) {
    TongtaiRouteKind.supplierDetail => true,
    TongtaiRouteKind.productDetail => true,
    TongtaiRouteKind.customerDetail => true,
    TongtaiRouteKind.opportunityDetail => true,
    _ => false,
  };
}

/// A fully resolved, validated deep-link destination.
///
/// Instances are only ever produced by the parser after the URL scheme,
/// route, and parameters have been validated and sanitized, so consumers can
/// trust [entityId] and [queryParams] without re-checking them.
@immutable
class TongtaiRoute {
  const TongtaiRoute(this.kind, {this.entityId, this.queryParams = const {}});

  /// The destination screen.
  final TongtaiRouteKind kind;

  /// The record id for detail routes (e.g. the supplier id). `null` for lists
  /// and dashboards. Guaranteed to match [_idPattern] when present.
  final String? entityId;

  /// Sanitized query parameters (e.g. `{'q': 'gạo'}` for a search link).
  final Map<String, String> queryParams;

  /// The bottom-nav tab this route lands on.
  int get tabIndex => kind.tabIndex;

  /// A stable, canonical `tongtai://…` string for this route — handy for logs,
  /// analytics, and round-trip tests. Not necessarily byte-identical to the
  /// URL that produced it (aliases are normalized to one canonical form).
  String get canonicalUri {
    final path = switch (kind) {
      TongtaiRouteKind.home => 'home',
      TongtaiRouteKind.producer => 'producer',
      TongtaiRouteKind.supplierList => 'producer/suppliers',
      TongtaiRouteKind.supplierDetail => 'suppliers/$entityId',
      TongtaiRouteKind.inventoryProducts => 'inventory/products',
      TongtaiRouteKind.productDetail => 'inventory/product/$entityId',
      TongtaiRouteKind.customerList => 'consumer/customers',
      TongtaiRouteKind.customerDetail => 'consumer/customer/$entityId',
      TongtaiRouteKind.journey =>
        entityId == null ? 'journey/active' : 'journey/$entityId',
      TongtaiRouteKind.opportunityDetail => 'opportunity/$entityId',
      TongtaiRouteKind.reports => 'reports',
      TongtaiRouteKind.financeAccounts => 'finance/accounts',
      TongtaiRouteKind.chat => 'chat',
      TongtaiRouteKind.search => 'search',
    };
    final query = queryParams.isEmpty
        ? ''
        : '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    return '$kTongtaiDeepLinkScheme://$path$query';
  }

  @override
  bool operator ==(Object other) =>
      other is TongtaiRoute &&
      other.kind == kind &&
      other.entityId == entityId &&
      mapEquals(other.queryParams, queryParams);

  @override
  int get hashCode => Object.hash(
    kind,
    entityId,
    Object.hashAllUnordered(
      queryParams.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() =>
      'TongtaiRoute(${kind.name}, id: $entityId, query: $queryParams)';
}

/// Why a deep link could not be resolved. Each value maps to a friendly,
/// bilingual message via [TongtaiDeepLinkFailure.messageFor].
enum TongtaiDeepLinkError {
  /// The input was empty / whitespace only.
  empty,

  /// The string could not be parsed as a URI at all.
  malformed,

  /// A URI, but not a `tongtai://` one.
  unsupportedScheme,

  /// A `tongtai://` URI whose path matches no known screen.
  unknownRoute,

  /// A known detail route, but the required id was missing.
  missingParameter,

  /// A parameter was present but failed validation/sanitization
  /// (bad characters, too long, path traversal, …).
  invalidParameter,
}

/// The outcome of resolving a deep link: either a [TongtaiDeepLinkSuccess]
/// carrying a validated [TongtaiRoute], or a [TongtaiDeepLinkFailure] carrying
/// a reason and a user-facing message.
sealed class TongtaiDeepLinkResult {
  const TongtaiDeepLinkResult();

  /// The resolved route, or `null` on failure. Convenience for callers that
  /// don't want to pattern-match.
  TongtaiRoute? get routeOrNull => this is TongtaiDeepLinkSuccess
      ? (this as TongtaiDeepLinkSuccess).route
      : null;

  bool get isSuccess => this is TongtaiDeepLinkSuccess;
  bool get isFailure => this is TongtaiDeepLinkFailure;
}

/// A successfully resolved deep link.
final class TongtaiDeepLinkSuccess extends TongtaiDeepLinkResult {
  const TongtaiDeepLinkSuccess(this.route);

  final TongtaiRoute route;

  @override
  bool operator ==(Object other) =>
      other is TongtaiDeepLinkSuccess && other.route == route;

  @override
  int get hashCode => route.hashCode;

  @override
  String toString() => 'TongtaiDeepLinkSuccess($route)';
}

/// A deep link that could not be resolved, with a reason and a friendly,
/// bilingual message the UI can surface (e.g. in a SnackBar).
final class TongtaiDeepLinkFailure extends TongtaiDeepLinkResult {
  const TongtaiDeepLinkFailure(this.error, {this.rawLink});

  final TongtaiDeepLinkError error;

  /// The original link that failed, for logging (never shown verbatim to the
  /// user to avoid leaking odd input into the UI).
  final String? rawLink;

  String get _messageEn => switch (error) {
    TongtaiDeepLinkError.empty => 'No link to open.',
    TongtaiDeepLinkError.malformed =>
      "This link isn't valid and can't be opened.",
    TongtaiDeepLinkError.unsupportedScheme =>
      "This link isn't a Tổng Tài link, so it can't be opened here.",
    TongtaiDeepLinkError.unknownRoute =>
      "We couldn't find the screen this link points to.",
    TongtaiDeepLinkError.missingParameter =>
      'This link is missing the item it should open.',
    TongtaiDeepLinkError.invalidParameter =>
      "This link points to something that doesn't look right, so it wasn't opened.",
  };

  String get _messageVi => switch (error) {
    TongtaiDeepLinkError.empty => 'Không có liên kết để mở.',
    TongtaiDeepLinkError.malformed =>
      'Liên kết này không hợp lệ nên không thể mở.',
    TongtaiDeepLinkError.unsupportedScheme =>
      'Đây không phải liên kết Tổng Tài nên không thể mở ở đây.',
    TongtaiDeepLinkError.unknownRoute =>
      'Không tìm thấy màn hình mà liên kết này trỏ tới.',
    TongtaiDeepLinkError.missingParameter => 'Liên kết này thiếu mục cần mở.',
    TongtaiDeepLinkError.invalidParameter =>
      'Liên kết này trỏ tới nội dung không hợp lệ nên đã không được mở.',
  };

  /// A friendly message for the given language code (`'vi'` → Vietnamese,
  /// anything else → English).
  String messageFor(String languageCode) =>
      languageCode == 'vi' ? _messageVi : _messageEn;

  @override
  bool operator ==(Object other) =>
      other is TongtaiDeepLinkFailure &&
      other.error == error &&
      other.rawLink == rawLink;

  @override
  int get hashCode => Object.hash(error, rawLink);

  @override
  String toString() => 'TongtaiDeepLinkFailure(${error.name}, raw: $rawLink)';
}
