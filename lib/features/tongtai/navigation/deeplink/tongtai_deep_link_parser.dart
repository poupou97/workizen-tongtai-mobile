// Deep-link parser for Tổng Tài (WTM-57).
//
// Turns an external `tongtai://…` string into a validated [TongtaiRoute], or a
// [TongtaiDeepLinkFailure] explaining why it couldn't. This is the single choke
// point where untrusted input (push payloads, shared links, other apps) is
// validated and sanitized *before* any navigation happens.
//
// The route table intentionally accepts a few aliases per destination so that
// both the canonical scheme in docs/tongtai/NAVIGATION-MAP.md
// (`tongtai://producer/supplier/ID`) and the shorter forms used in push
// payloads (`tongtai://suppliers/ID`) resolve to the same screen.

import 'tongtai_deep_link.dart';

/// Parses and validates `tongtai://…` deep links.
///
/// Stateless and cheap to construct — use the shared [instance] or the
/// top-level [parseTongtaiDeepLink] helper.
class TongtaiDeepLinkParser {
  const TongtaiDeepLinkParser();

  /// A shared, reusable instance.
  static const TongtaiDeepLinkParser instance = TongtaiDeepLinkParser();

  /// Ids may only contain URL-safe record characters. This deliberately
  /// rejects `/`, `.`, whitespace and every path-traversal / injection
  /// character, and caps the length so a hostile link can't blow past
  /// downstream buffers.
  static final RegExp _idPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  /// Upper bound on a sanitized query value (e.g. a search string). Long enough
  /// for real queries, short enough to stay safe.
  static const int _maxQueryValueLength = 200;

  /// Resolve [rawLink] into a [TongtaiDeepLinkResult].
  ///
  /// Never throws: malformed input becomes a [TongtaiDeepLinkFailure]. A
  /// failure carries a [TongtaiDeepLinkError]; callers pick the display
  /// language later via [TongtaiDeepLinkFailure.messageFor].
  TongtaiDeepLinkResult parse(String rawLink) {
    final trimmed = rawLink.trim();
    if (trimmed.isEmpty) {
      return const TongtaiDeepLinkFailure(TongtaiDeepLinkError.empty);
    }

    final Uri uri;
    try {
      uri = Uri.parse(trimmed);
    } on FormatException {
      return TongtaiDeepLinkFailure(
        TongtaiDeepLinkError.malformed,
        rawLink: trimmed,
      );
    }

    if (uri.scheme.toLowerCase() != kTongtaiDeepLinkScheme) {
      return TongtaiDeepLinkFailure(
        TongtaiDeepLinkError.unsupportedScheme,
        rawLink: trimmed,
      );
    }

    // Treat the authority (host) as the first path segment: for
    // `tongtai://suppliers/42` the host is `suppliers` and the path is `/42`.
    // `Uri` percent-decodes both host and path segments for us.
    final segments = <String>[
      if (uri.host.isNotEmpty) uri.host.toLowerCase(),
      ...uri.pathSegments.where((s) => s.isNotEmpty),
    ];

    return _match(segments, uri, trimmed);
  }

  TongtaiDeepLinkResult _match(
    List<String> segments,
    Uri uri,
    String rawLink,
  ) {
    // An empty path (`tongtai://`) has nowhere to go.
    if (segments.isEmpty) {
      return TongtaiDeepLinkFailure(
        TongtaiDeepLinkError.unknownRoute,
        rawLink: rawLink,
      );
    }

    final head = segments.first;
    final rest = segments.sublist(1);

    switch (head) {
      case 'home':
        return _leaf(TongtaiRouteKind.home, rest, rawLink);

      case 'producer':
        // producer               → producer hub
        // producer/suppliers     → supplier list
        // producer/supplier/{id} → supplier detail
        if (rest.isEmpty) {
          return _success(const TongtaiRoute(TongtaiRouteKind.producer));
        }
        if (rest.length == 1 && rest.first == 'suppliers') {
          return _success(const TongtaiRoute(TongtaiRouteKind.supplierList));
        }
        if (rest.length == 2 && rest.first == 'supplier') {
          return _detail(TongtaiRouteKind.supplierDetail, rest[1], rawLink);
        }
        return _unknown(rawLink);

      // Short alias used in push payloads: suppliers[/ID].
      case 'suppliers':
        if (rest.isEmpty) {
          return _success(const TongtaiRoute(TongtaiRouteKind.supplierList));
        }
        if (rest.length == 1) {
          return _detail(TongtaiRouteKind.supplierDetail, rest.first, rawLink);
        }
        return _unknown(rawLink);

      case 'inventory':
        // inventory/products      → product list
        // inventory/product/{id}  → product detail
        if (rest.length == 1 && rest.first == 'products') {
          return _success(const TongtaiRoute(TongtaiRouteKind.inventoryProducts));
        }
        if (rest.length == 2 && rest.first == 'product') {
          return _detail(TongtaiRouteKind.productDetail, rest[1], rawLink);
        }
        return _unknown(rawLink);

      // Short alias: products[/ID].
      case 'products':
        if (rest.isEmpty) {
          return _success(const TongtaiRoute(TongtaiRouteKind.inventoryProducts));
        }
        if (rest.length == 1) {
          return _detail(TongtaiRouteKind.productDetail, rest.first, rawLink);
        }
        return _unknown(rawLink);

      case 'consumer':
        // consumer/customers      → customer list
        // consumer/customer/{id}  → customer detail
        if (rest.length == 1 && rest.first == 'customers') {
          return _success(const TongtaiRoute(TongtaiRouteKind.customerList));
        }
        if (rest.length == 2 && rest.first == 'customer') {
          return _detail(TongtaiRouteKind.customerDetail, rest[1], rawLink);
        }
        return _unknown(rawLink);

      // Short alias: customers[/ID].
      case 'customers':
        if (rest.isEmpty) {
          return _success(const TongtaiRoute(TongtaiRouteKind.customerList));
        }
        if (rest.length == 1) {
          return _detail(TongtaiRouteKind.customerDetail, rest.first, rawLink);
        }
        return _unknown(rawLink);

      case 'journey':
        // journey            → active journey
        // journey/active     → active journey
        // journey/{id}       → a specific journey
        if (rest.isEmpty || (rest.length == 1 && rest.first == 'active')) {
          return _success(const TongtaiRoute(TongtaiRouteKind.journey));
        }
        if (rest.length == 1) {
          return _detail(TongtaiRouteKind.journey, rest.first, rawLink);
        }
        return _unknown(rawLink);

      case 'opportunity':
        if (rest.length == 1) {
          return _detail(TongtaiRouteKind.opportunityDetail, rest.first, rawLink);
        }
        return _unknown(rawLink);

      case 'reports':
        return _leaf(TongtaiRouteKind.reports, rest, rawLink);

      case 'finance':
        if (rest.isEmpty || (rest.length == 1 && rest.first == 'accounts')) {
          return _success(const TongtaiRoute(TongtaiRouteKind.financeAccounts));
        }
        return _unknown(rawLink);

      case 'chat':
        return _leaf(TongtaiRouteKind.chat, rest, rawLink);

      case 'search':
        final query = _sanitizeQueryValue(uri.queryParameters['q']);
        return _success(
          TongtaiRoute(
            TongtaiRouteKind.search,
            queryParams: query == null ? const {} : {'q': query},
          ),
        );

      default:
        return _unknown(rawLink);
    }
  }

  /// A leaf route (home/reports/chat) that must not carry extra path segments.
  TongtaiDeepLinkResult _leaf(
    TongtaiRouteKind kind,
    List<String> rest,
    String rawLink,
  ) {
    if (rest.isNotEmpty) return _unknown(rawLink);
    return _success(TongtaiRoute(kind));
  }

  /// A detail route that requires a valid id.
  TongtaiDeepLinkResult _detail(
    TongtaiRouteKind kind,
    String rawId,
    String rawLink,
  ) {
    final id = _sanitizeId(rawId);
    if (id == null) {
      return TongtaiDeepLinkFailure(
        TongtaiDeepLinkError.invalidParameter,
        rawLink: rawLink,
      );
    }
    return _success(TongtaiRoute(kind, entityId: id));
  }

  TongtaiDeepLinkResult _success(TongtaiRoute route) =>
      TongtaiDeepLinkSuccess(route);

  TongtaiDeepLinkResult _unknown(String rawLink) => TongtaiDeepLinkFailure(
        TongtaiDeepLinkError.unknownRoute,
        rawLink: rawLink,
      );

  /// Validate + sanitize a record id. Returns the cleaned id, or `null` if it
  /// fails validation (empty, illegal characters, path traversal, too long).
  String? _sanitizeId(String raw) {
    final trimmed = raw.trim();
    if (!_idPattern.hasMatch(trimmed)) return null;
    return trimmed;
  }

  /// Sanitize a free-text query value: trim, strip control characters, and cap
  /// the length. Returns `null` for an empty/whitespace value.
  String? _sanitizeQueryValue(String? raw) {
    if (raw == null) return null;
    // Drop C0/C1 control characters that could corrupt the UI or logs.
    final cleaned = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
    if (cleaned.isEmpty) return null;
    return cleaned.length > _maxQueryValueLength
        ? cleaned.substring(0, _maxQueryValueLength)
        : cleaned;
  }
}

/// Convenience wrapper around [TongtaiDeepLinkParser.instance].
TongtaiDeepLinkResult parseTongtaiDeepLink(String rawLink) =>
    TongtaiDeepLinkParser.instance.parse(rawLink);
