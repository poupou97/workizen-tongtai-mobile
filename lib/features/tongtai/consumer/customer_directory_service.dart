import 'package:flutter/foundation.dart';

import 'customer.dart';

/// How the customer list is ordered (WTM-75 AC: sort by purchase volume,
/// frequency, or recency — plus name as the default).
enum CustomerSort {
  name,
  spent, // purchase volume (lifetime spend)
  frequency, // number of purchases (order count)
  recency; // last purchase date

  String get labelEn => switch (this) {
        CustomerSort.name => 'Name',
        CustomerSort.spent => 'Spent',
        CustomerSort.frequency => 'Frequency',
        CustomerSort.recency => 'Recent',
      };
}

/// Minimum / maximum customers shown per page (WTM-75 AC: 20–50 per page). The
/// default page size sits at the low end so pagination is visible even on a
/// modest customer base.
const int kMinCustomerPageSize = 20;
const int kMaxCustomerPageSize = 50;

/// The active directory query: free-text search, an optional location facet,
/// sort order + direction, and the current page window. Immutable so the screen
/// holds one in state and rebuilds deterministically.
@immutable
class CustomerQuery {
  const CustomerQuery({
    this.text = '',
    this.location,
    this.sort = CustomerSort.name,
    this.ascending = true,
    this.pageIndex = 0,
    this.pageSize = kMinCustomerPageSize,
  });

  /// Free text, matched (case-insensitive) against name, phone and location.
  final String text;

  /// Location facet, e.g. "Hà Nội"; null means "all locations".
  final String? location;

  /// Sort key.
  final CustomerSort sort;

  /// Sort direction; true = ascending.
  final bool ascending;

  /// Current page, 0-based.
  final int pageIndex;

  /// Customers per page (clamped to [kMinCustomerPageSize]..[kMaxCustomerPageSize]
  /// by the service).
  final int pageSize;

  /// Whether a location facet is applied.
  bool get hasLocation => location != null;

  /// Copy with individual overrides. Pass `clearLocation: true` to reset the
  /// location facet to null (a plain null argument can't distinguish "leave
  /// unchanged" from "clear").
  CustomerQuery copyWith({
    String? text,
    String? location,
    bool clearLocation = false,
    CustomerSort? sort,
    bool? ascending,
    int? pageIndex,
    int? pageSize,
  }) {
    return CustomerQuery(
      text: text ?? this.text,
      location: clearLocation ? null : (location ?? this.location),
      sort: sort ?? this.sort,
      ascending: ascending ?? this.ascending,
      pageIndex: pageIndex ?? this.pageIndex,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

/// One page of customer results plus the metadata a paginator UI needs.
@immutable
class CustomerPage {
  const CustomerPage({
    required this.items,
    required this.pageIndex,
    required this.pageSize,
    required this.totalCount,
  });

  /// The customers on this page.
  final List<Customer> items;

  /// This page's 0-based index (already clamped into range).
  final int pageIndex;

  /// Effective page size (already clamped to the 20–50 bound).
  final int pageSize;

  /// Total matching customers across all pages.
  final int totalCount;

  /// Total number of pages (always at least 1, even when empty).
  int get pageCount =>
      totalCount == 0 ? 1 : ((totalCount - 1) ~/ pageSize) + 1;

  /// Whether there is a page before this one.
  bool get hasPrevious => pageIndex > 0;

  /// Whether there is a page after this one.
  bool get hasNext => pageIndex < pageCount - 1;

  /// Whether this page has no items.
  bool get isEmpty => items.isEmpty;

  /// 1-based number of the first item on this page (0 when empty).
  int get firstItemNumber => totalCount == 0 ? 0 : pageIndex * pageSize + 1;

  /// 1-based number of the last item on this page (0 when empty).
  int get lastItemNumber =>
      totalCount == 0 ? 0 : pageIndex * pageSize + items.length;
}

/// In-memory customer directory — local-first, no backend (ADR-002).
///
/// All matching, filtering, sorting and paging is pure Dart over an in-memory
/// list, so results return synchronously. A Drift/remote-backed implementation
/// can later replace the data source without touching callers.
class CustomerDirectoryService {
  CustomerDirectoryService(List<Customer> customers)
      : _customers = List.unmodifiable(customers);

  /// Convenience constructor seeded with the built-in sample directory.
  factory CustomerDirectoryService.sample() =>
      CustomerDirectoryService(kSampleCustomers);

  final List<Customer> _customers;

  /// The full, unfiltered directory.
  List<Customer> get all => _customers;

  /// Distinct locations across the directory, alphabetically sorted.
  List<String> get locations {
    final set = <String>{for (final c in _customers) c.location};
    final list = set.toList()..sort();
    return list;
  }

  /// Applies [query]'s search text + location facet and sorts the full match
  /// set (no paging). Free text matches name, phone or location
  /// (case-insensitive); the location facet is an exact match.
  List<Customer> filter(CustomerQuery query) {
    final q = query.text.trim().toLowerCase();
    final results = <Customer>[
      for (final c in _customers)
        if (_matches(c, q, query)) c,
    ];
    _sort(results, query.sort, query.ascending);
    return results;
  }

  /// One page of [filter] results, honoring the 20–50-per-page bound and
  /// clamping the requested page into range (so a stale page index never yields
  /// an out-of-range slice).
  CustomerPage page(CustomerQuery query) {
    final matches = filter(query);
    final size =
        query.pageSize.clamp(kMinCustomerPageSize, kMaxCustomerPageSize);
    final pageCount = matches.isEmpty ? 1 : ((matches.length - 1) ~/ size) + 1;
    final index = query.pageIndex.clamp(0, pageCount - 1);
    final start = index * size;
    final end = start + size < matches.length ? start + size : matches.length;
    return CustomerPage(
      items: matches.sublist(start, end),
      pageIndex: index,
      pageSize: size,
      totalCount: matches.length,
    );
  }

  bool _matches(Customer c, String q, CustomerQuery query) {
    if (query.location != null && c.location != query.location) return false;
    if (q.isEmpty) return true;
    return c.name.toLowerCase().contains(q) ||
        c.phone.toLowerCase().contains(q) ||
        c.location.toLowerCase().contains(q);
  }

  void _sort(List<Customer> list, CustomerSort sort, bool ascending) {
    int compare(Customer a, Customer b) {
      final int c = switch (sort) {
        CustomerSort.name =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        CustomerSort.spent => a.totalSpent.compareTo(b.totalSpent),
        CustomerSort.frequency => a.orderCount.compareTo(b.orderCount),
        CustomerSort.recency =>
          a.lastPurchaseDate.compareTo(b.lastPurchaseDate),
      };
      if (c != 0) return ascending ? c : -c;
      // Deterministic tiebreak by id, always ascending, so equal keys keep a
      // stable order regardless of sort direction.
      return a.id.compareTo(b.id);
    }

    list.sort(compare);
  }
}

/// Sample customer directory used until a real (Drift-backed) data source is
/// wired in. Mirrors the mock-data shape in `docs/tongtai/SCREEN-CONSUMER.md`,
/// extended to 26 customers across five Vietnamese cities with a realistic
/// spread of value tiers so every facet, sort key and the 20-per-page
/// pagination have real data to exercise. Spend is in Vietnamese đồng.
///
/// Not `const` because [Customer.lastPurchaseDate] is a runtime [DateTime]; the
/// values are fixed dates so sorting is deterministic.
final List<Customer> kSampleCustomers = [
  // ── Hà Nội (6) ──────────────────────────────────────────────────────────
  Customer(
    id: 'c01',
    name: 'Phương Nguyễn',
    phone: '+84912345678',
    location: 'Hà Nội',
    orderCount: 24,
    totalSpent: 45600000,
    lastPurchaseDate: DateTime(2026, 7, 10),
  ),
  Customer(
    id: 'c02',
    name: 'Minh Trần',
    phone: '+84908111222',
    location: 'Hà Nội',
    orderCount: 9,
    totalSpent: 8200000,
    lastPurchaseDate: DateTime(2026, 6, 25),
  ),
  Customer(
    id: 'c03',
    name: 'Huy Đặng',
    phone: '+84987333444',
    location: 'Hà Nội',
    orderCount: 3,
    totalSpent: 2340000,
    lastPurchaseDate: DateTime(2026, 5, 15),
  ),
  Customer(
    id: 'c04',
    name: 'Lan Phạm',
    phone: '+84931555666',
    location: 'Hà Nội',
    orderCount: 12,
    totalSpent: 15800000,
    lastPurchaseDate: DateTime(2026, 7, 2),
  ),
  Customer(
    id: 'c05',
    name: 'Tuấn Vũ',
    phone: '+84962777888',
    location: 'Hà Nội',
    orderCount: 1,
    totalSpent: 1050000,
    lastPurchaseDate: DateTime(2026, 2, 11),
  ),
  Customer(
    id: 'c06',
    name: 'Ngọc Hoàng',
    phone: '+84919000111',
    location: 'Hà Nội',
    orderCount: 19,
    totalSpent: 33900000,
    lastPurchaseDate: DateTime(2026, 7, 12),
  ),
  // ── TP. Hồ Chí Minh (6) ─────────────────────────────────────────────────
  Customer(
    id: 'c07',
    name: 'Bảo Lê',
    phone: '+84902101202',
    location: 'TP. Hồ Chí Minh',
    orderCount: 7,
    totalSpent: 6700000,
    lastPurchaseDate: DateTime(2026, 6, 30),
  ),
  Customer(
    id: 'c08',
    name: 'Trang Đỗ',
    phone: '+84977303404',
    location: 'TP. Hồ Chí Minh',
    orderCount: 15,
    totalSpent: 21400000,
    lastPurchaseDate: DateTime(2026, 7, 8),
  ),
  Customer(
    id: 'c09',
    name: 'Khoa Bùi',
    phone: '+84933505606',
    location: 'TP. Hồ Chí Minh',
    orderCount: 2,
    totalSpent: 980000,
    lastPurchaseDate: DateTime(2026, 3, 5),
  ),
  Customer(
    id: 'c10',
    name: 'Thu Hà',
    phone: '+84915707808',
    location: 'TP. Hồ Chí Minh',
    orderCount: 31,
    totalSpent: 52300000,
    lastPurchaseDate: DateTime(2026, 7, 13),
  ),
  Customer(
    id: 'c11',
    name: 'Nam Dương',
    phone: '+84988909010',
    location: 'TP. Hồ Chí Minh',
    orderCount: 5,
    totalSpent: 4150000,
    lastPurchaseDate: DateTime(2026, 6, 18),
  ),
  Customer(
    id: 'c12',
    name: 'Yến Vy',
    phone: '+84906121314',
    location: 'TP. Hồ Chí Minh',
    orderCount: 10,
    totalSpent: 11600000,
    lastPurchaseDate: DateTime(2026, 7, 1),
  ),
  // ── Đà Nẵng (5) ─────────────────────────────────────────────────────────
  Customer(
    id: 'c13',
    name: 'Đức Anh',
    phone: '+84979151617',
    location: 'Đà Nẵng',
    orderCount: 4,
    totalSpent: 3500000,
    lastPurchaseDate: DateTime(2026, 5, 28),
  ),
  Customer(
    id: 'c14',
    name: 'Mai Chi',
    phone: '+84934181920',
    location: 'Đà Nẵng',
    orderCount: 17,
    totalSpent: 27800000,
    lastPurchaseDate: DateTime(2026, 7, 9),
  ),
  Customer(
    id: 'c15',
    name: 'Long Hồ',
    phone: '+84961212223',
    location: 'Đà Nẵng',
    orderCount: 1,
    totalSpent: 720000,
    lastPurchaseDate: DateTime(2026, 1, 20),
  ),
  Customer(
    id: 'c16',
    name: 'Hương Giang',
    phone: '+84918242526',
    location: 'Đà Nẵng',
    orderCount: 8,
    totalSpent: 9900000,
    lastPurchaseDate: DateTime(2026, 6, 22),
  ),
  Customer(
    id: 'c17',
    name: 'Sơn Tùng',
    phone: '+84903272829',
    location: 'Đà Nẵng',
    orderCount: 22,
    totalSpent: 38200000,
    lastPurchaseDate: DateTime(2026, 7, 11),
  ),
  // ── Hải Phòng (5) ───────────────────────────────────────────────────────
  Customer(
    id: 'c18',
    name: 'Quân Phan',
    phone: '+84976303132',
    location: 'Hải Phòng',
    orderCount: 6,
    totalSpent: 5600000,
    lastPurchaseDate: DateTime(2026, 6, 15),
  ),
  Customer(
    id: 'c19',
    name: 'Diệu Linh',
    phone: '+84935333435',
    location: 'Hải Phòng',
    orderCount: 11,
    totalSpent: 13400000,
    lastPurchaseDate: DateTime(2026, 7, 3),
  ),
  Customer(
    id: 'c20',
    name: 'Hải Nam',
    phone: '+84964363738',
    location: 'Hải Phòng',
    orderCount: 2,
    totalSpent: 1800000,
    lastPurchaseDate: DateTime(2026, 4, 9),
  ),
  Customer(
    id: 'c21',
    name: 'Phúc Nguyên',
    phone: '+84917394041',
    location: 'Hải Phòng',
    orderCount: 18,
    totalSpent: 30100000,
    lastPurchaseDate: DateTime(2026, 7, 7),
  ),
  Customer(
    id: 'c22',
    name: 'Vân Anh',
    phone: '+84907424344',
    location: 'Hải Phòng',
    orderCount: 7,
    totalSpent: 7250000,
    lastPurchaseDate: DateTime(2026, 6, 27),
  ),
  // ── Cần Thơ (4) ─────────────────────────────────────────────────────────
  Customer(
    id: 'c23',
    name: 'Gia Bảo',
    phone: '+84978454647',
    location: 'Cần Thơ',
    orderCount: 3,
    totalSpent: 2050000,
    lastPurchaseDate: DateTime(2026, 5, 2),
  ),
  Customer(
    id: 'c24',
    name: 'Kim Ngân',
    phone: '+84936484950',
    location: 'Cần Thơ',
    orderCount: 13,
    totalSpent: 18900000,
    lastPurchaseDate: DateTime(2026, 7, 5),
  ),
  Customer(
    id: 'c25',
    name: 'Đại Phát',
    phone: '+84965515253',
    location: 'Cần Thơ',
    orderCount: 1,
    totalSpent: 460000,
    lastPurchaseDate: DateTime(2026, 1, 8),
  ),
  Customer(
    id: 'c26',
    name: 'Bích Ngọc',
    phone: '+84919545556',
    location: 'Cần Thơ',
    orderCount: 16,
    totalSpent: 24700000,
    lastPurchaseDate: DateTime(2026, 7, 6),
  ),
];
