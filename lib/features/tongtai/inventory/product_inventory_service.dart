import 'package:flutter/foundation.dart';

import 'product.dart';
import 'product_category.dart';

/// How the product list is ordered (WTM-68 AC: sort by name, price, quantity, or
/// last updated).
enum ProductSort {
  name,
  price,
  quantity,
  lastUpdated;

  String get labelEn => switch (this) {
    ProductSort.name => 'Name',
    ProductSort.price => 'Price',
    ProductSort.quantity => 'Quantity',
    ProductSort.lastUpdated => 'Updated',
  };

  String get labelVi => switch (this) {
    ProductSort.name => 'Tên',
    ProductSort.price => 'Giá',
    ProductSort.quantity => 'Số lượng',
    ProductSort.lastUpdated => 'Cập nhật',
  };

  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// Minimum / maximum products shown per page (WTM-68 AC: 20–50 per page). The
/// default page size sits at the low end so pagination is visible even on a
/// modest catalog.
const int kMinProductPageSize = 20;
const int kMaxProductPageSize = 50;

/// The active inventory query: free-text search, an optional category facet,
/// sort order + direction, and the current page window. Immutable so the screen
/// holds one in state and rebuilds deterministically.
@immutable
class ProductQuery {
  const ProductQuery({
    this.text = '',
    this.category,
    this.sort = ProductSort.name,
    this.ascending = true,
    this.pageIndex = 0,
    this.pageSize = kMinProductPageSize,
    this.onlyIds,
  });

  /// Free text, matched (case-insensitive) against name, category and SKU.
  final String text;

  /// Category facet, e.g. "Electronics"; null means "all categories".
  final String? category;

  /// Sort key.
  final ProductSort sort;

  /// Sort direction; true = ascending.
  final bool ascending;

  /// Current page, 0-based.
  final int pageIndex;

  /// Products per page (clamped to [kMinProductPageSize]..[kMaxProductPageSize]
  /// by the service).
  final int pageSize;

  /// Giới hạn kết quả về đúng tập mặt hàng này. `null` = không giới hạn.
  ///
  /// Dùng cho những lát cắt **do dữ liệu quyết định** chứ không do người dùng
  /// gõ — ví dụ "hàng chậm bán" (WTM-411): tập ấy tính từ đơn hàng, không diễn
  /// đạt được bằng một chuỗi tìm kiếm hay một danh mục.
  final Set<String>? onlyIds;

  /// Whether a category facet is applied.
  bool get hasCategory => category != null;

  /// Đang xem một lát cắt do dữ liệu quyết định.
  bool get hasIdFilter => onlyIds != null;

  /// Copy with individual overrides. Pass `clearCategory: true` to reset the
  /// category facet to null (a plain null argument can't distinguish "leave
  /// unchanged" from "clear").
  ProductQuery copyWith({
    String? text,
    String? category,
    bool clearCategory = false,
    ProductSort? sort,
    bool? ascending,
    int? pageIndex,
    int? pageSize,
    Set<String>? onlyIds,
    bool clearOnlyIds = false,
  }) {
    return ProductQuery(
      text: text ?? this.text,
      category: clearCategory ? null : (category ?? this.category),
      sort: sort ?? this.sort,
      ascending: ascending ?? this.ascending,
      pageIndex: pageIndex ?? this.pageIndex,
      pageSize: pageSize ?? this.pageSize,
      onlyIds: clearOnlyIds ? null : (onlyIds ?? this.onlyIds),
    );
  }
}

/// One page of product results plus the metadata a paginator UI needs.
@immutable
class ProductPage {
  const ProductPage({
    required this.items,
    required this.pageIndex,
    required this.pageSize,
    required this.totalCount,
  });

  /// The products on this page.
  final List<Product> items;

  /// This page's 0-based index (already clamped into range).
  final int pageIndex;

  /// Effective page size (already clamped to the 20–50 bound).
  final int pageSize;

  /// Total matching products across all pages.
  final int totalCount;

  /// Total number of pages (always at least 1, even when empty).
  int get pageCount => totalCount == 0 ? 1 : ((totalCount - 1) ~/ pageSize) + 1;

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

/// In-memory product inventory — local-first, no backend (ADR-002).
///
/// All matching, filtering, sorting and paging is pure Dart over an in-memory
/// list, so results return synchronously. A Drift/remote-backed implementation
/// can later replace the data source without touching callers.
class ProductInventoryService {
  ProductInventoryService(List<Product> products)
    : _products = List.unmodifiable(products);

  /// Convenience constructor seeded with the built-in sample catalog.
  factory ProductInventoryService.sample() =>
      ProductInventoryService(kSampleProducts);

  final List<Product> _products;

  /// The full, unfiltered catalog.
  List<Product> get all => _products;

  /// Distinct categories across the catalog as **canonical values** (WTM-393),
  /// sorted by their Vietnamese label.
  ///
  /// Two sources write `Product.category` — the XLSX (nhãn VI) and the history
  /// generator (mã canonical). Grouping by the raw string would show "Điện tử"
  /// and "electronics" as two chips for one concept. Collapsing through
  /// [ProductCategory.normalise] gives **one chip per category**; the UI turns
  /// each back into a label with [ProductCategory.display].
  List<String> get categories {
    final set = <String>{
      for (final p in _products) ProductCategory.normalise(p.category),
    };
    final list = set.toList()
      ..sort(
        (a, b) => ProductCategory.display(
          a,
          'vi',
        ).compareTo(ProductCategory.display(b, 'vi')),
      );
    return list;
  }

  /// Applies [query]'s search text + category facet and sorts the full match
  /// set (no paging). Free text matches name, category or SKU
  /// (case-insensitive); the category facet is an exact match.
  List<Product> filter(ProductQuery query) {
    final q = query.text.trim().toLowerCase();
    final results = <Product>[
      for (final p in _products)
        if (_matches(p, q, query)) p,
    ];
    _sort(results, query.sort, query.ascending);
    return results;
  }

  /// One page of [filter] results, honoring the 20–50-per-page bound and
  /// clamping the requested page into range (so a stale page index never yields
  /// an out-of-range slice).
  ProductPage page(ProductQuery query) {
    final matches = filter(query);
    final size = query.pageSize.clamp(kMinProductPageSize, kMaxProductPageSize);
    final pageCount = matches.isEmpty ? 1 : ((matches.length - 1) ~/ size) + 1;
    final index = query.pageIndex.clamp(0, pageCount - 1);
    final start = index * size;
    final end = start + size < matches.length ? start + size : matches.length;
    return ProductPage(
      items: matches.sublist(start, end),
      pageIndex: index,
      pageSize: size,
      totalCount: matches.length,
    );
  }

  bool _matches(Product p, String q, ProductQuery query) {
    // Lát cắt do dữ liệu quyết định đứng TRƯỚC mọi tiêu chí gõ tay: nó là câu
    // hỏi người dùng vừa đặt ("cho tôi xem hàng đang nằm"), còn tìm kiếm và
    // danh mục chỉ thu hẹp bên trong câu hỏi ấy.
    final only = query.onlyIds;
    if (only != null && !only.contains(p.id)) return false;

    // Facet compares canonical values so a chip selected as "Điện tử" still
    // matches a product stored as the code "electronics" (WTM-393).
    if (query.category != null &&
        ProductCategory.normalise(p.category) !=
            ProductCategory.normalise(query.category!)) {
      return false;
    }
    if (q.isEmpty) return true;
    // Free text matches the localized label too, so searching "điện tử" finds a
    // product whose stored category is the code "electronics".
    return p.name.toLowerCase().contains(q) ||
        p.category.toLowerCase().contains(q) ||
        ProductCategory.display(p.category, 'vi').toLowerCase().contains(q) ||
        p.sku.toLowerCase().contains(q);
  }

  void _sort(List<Product> list, ProductSort sort, bool ascending) {
    int compare(Product a, Product b) {
      final int c = switch (sort) {
        ProductSort.name => a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        ),
        ProductSort.price => a.pricePerUnit.compareTo(b.pricePerUnit),
        // ADR-TON-023: hàng không có tồn kho xuống cuối thay vì giả vờ bằng
        // 0 — xếp nó lẫn với hàng ĐANG hết là trộn hai sự thật khác nhau.
        ProductSort.quantity => switch ((a.quantity, b.quantity)) {
          (null, null) => 0,
          (null, _) => 1,
          (_, null) => -1,
          (final x?, final y?) => x.compareTo(y),
        },
        ProductSort.lastUpdated => a.updatedAt.compareTo(b.updatedAt),
      };
      if (c != 0) return ascending ? c : -c;
      // Deterministic tiebreak by id, always ascending, so equal keys keep a
      // stable order regardless of sort direction.
      return a.id.compareTo(b.id);
    }

    list.sort(compare);
  }
}

/// Sample product catalog used until a real (Drift-backed) data source is wired
/// in. Mirrors the mock data shape in `docs/tongtai/SCREEN-INVENTORY.md`,
/// extended to 28 SKUs across five categories with a realistic spread of stock
/// statuses so every facet, sort key and the 20-per-page pagination have real
/// data to exercise. Prices are in Vietnamese đồng.
///
/// Not `const` because [Product.updatedAt] is a runtime [DateTime]; the values
/// are fixed dates so sorting is deterministic.
final List<Product> kSampleProducts = [
  Product(
    id: 'p01',
    sku: 'SKU-EL-001',
    name: 'Quạt mini cầm tay',
    category: 'electronics', // ProductCategory.electronics.code (WTM-393)
    quantity: 195,
    pricePerUnit: 89000,
    reorderLevel: 50,
    updatedAt: DateTime(2026, 7, 1, 9),
  ),
  Product(
    id: 'p02',
    sku: 'SKU-AC-002',
    name: 'Túi chống nước du lịch',
    category: 'accessories', // ProductCategory.accessories.code (WTM-393)
    quantity: 40,
    pricePerUnit: 145000,
    reorderLevel: 50,
    updatedAt: DateTime(2026, 7, 2, 9),
  ),
  Product(
    id: 'p03',
    sku: 'SKU-EL-003',
    name: 'Máy pha cà phê mini',
    category: 'electronics', // ProductCategory.electronics.code (WTM-393)
    quantity: 0,
    pricePerUnit: 349000,
    reorderLevel: 30,
    updatedAt: DateTime(2026, 7, 3, 9),
  ),
  Product(
    id: 'p04',
    sku: 'SKU-TX-004',
    name: 'Áo thun cotton',
    category: 'fashion', // ProductCategory.fashion.code (WTM-393)
    quantity: 320,
    pricePerUnit: 120000,
    reorderLevel: 80,
    updatedAt: DateTime(2026, 7, 4, 9),
  ),
  Product(
    id: 'p05',
    sku: 'SKU-HG-005',
    name: 'Bộ nồi inox 5 món',
    category:
        'home_appliances', // ProductCategory.homeAppliances.code (WTM-393)
    quantity: 60,
    pricePerUnit: 890000,
    reorderLevel: 20,
    updatedAt: DateTime(2026, 7, 5, 9),
  ),
  Product(
    id: 'p06',
    sku: 'SKU-BE-006',
    name: 'Son dưỡng môi',
    category: 'cosmetics', // ProductCategory.cosmetics.code (WTM-393)
    quantity: 15,
    pricePerUnit: 65000,
    reorderLevel: 40,
    updatedAt: DateTime(2026, 7, 6, 9),
  ),
  Product(
    id: 'p07',
    sku: 'SKU-EL-007',
    name: 'Tai nghe bluetooth',
    category: 'electronics', // ProductCategory.electronics.code (WTM-393)
    quantity: 210,
    pricePerUnit: 259000,
    reorderLevel: 60,
    updatedAt: DateTime(2026, 7, 7, 9),
  ),
  Product(
    id: 'p08',
    sku: 'SKU-AC-008',
    name: 'Ví da nam',
    category: 'accessories', // ProductCategory.accessories.code (WTM-393)
    quantity: 8,
    pricePerUnit: 199000,
    reorderLevel: 25,
    updatedAt: DateTime(2026, 7, 8, 9),
  ),
  Product(
    id: 'p09',
    sku: 'SKU-TX-009',
    name: 'Khăn tắm cotton',
    category: 'fashion', // ProductCategory.fashion.code (WTM-393)
    quantity: 0,
    pricePerUnit: 85000,
    reorderLevel: 40,
    updatedAt: DateTime(2026, 7, 9, 9),
  ),
  Product(
    id: 'p10',
    sku: 'SKU-HG-010',
    name: 'Đèn ngủ LED',
    category:
        'home_appliances', // ProductCategory.homeAppliances.code (WTM-393)
    quantity: 145,
    pricePerUnit: 175000,
    reorderLevel: 50,
    updatedAt: DateTime(2026, 7, 10, 9),
  ),
  Product(
    id: 'p11',
    sku: 'SKU-BE-011',
    name: 'Kem chống nắng SPF50',
    category: 'cosmetics', // ProductCategory.cosmetics.code (WTM-393)
    quantity: 88,
    pricePerUnit: 235000,
    reorderLevel: 30,
    updatedAt: DateTime(2026, 7, 11, 9),
  ),
  Product(
    id: 'p12',
    sku: 'SKU-EL-012',
    name: 'Sạc dự phòng 20000mAh',
    category: 'electronics', // ProductCategory.electronics.code (WTM-393)
    quantity: 30,
    pricePerUnit: 399000,
    reorderLevel: 30,
    updatedAt: DateTime(2026, 7, 12, 9),
  ),
  Product(
    id: 'p13',
    sku: 'SKU-TX-013',
    name: 'Chăn lông cừu',
    category: 'fashion', // ProductCategory.fashion.code (WTM-393)
    quantity: 52,
    pricePerUnit: 450000,
    reorderLevel: 15,
    updatedAt: DateTime(2026, 7, 13, 9),
  ),
  Product(
    id: 'p14',
    sku: 'SKU-AC-014',
    name: 'Kính râm thời trang',
    category: 'accessories', // ProductCategory.accessories.code (WTM-393)
    quantity: 120,
    pricePerUnit: 159000,
    reorderLevel: 40,
    updatedAt: DateTime(2026, 7, 14, 9),
  ),
  Product(
    id: 'p15',
    sku: 'SKU-HG-015',
    name: 'Thảm chùi chân',
    category:
        'home_appliances', // ProductCategory.homeAppliances.code (WTM-393)
    quantity: 5,
    pricePerUnit: 55000,
    reorderLevel: 30,
    updatedAt: DateTime(2026, 7, 15, 9),
  ),
  Product(
    id: 'p16',
    sku: 'SKU-BE-016',
    name: 'Nước hoa mini',
    category: 'cosmetics', // ProductCategory.cosmetics.code (WTM-393)
    quantity: 0,
    pricePerUnit: 320000,
    reorderLevel: 20,
    updatedAt: DateTime(2026, 7, 16, 9),
  ),
  Product(
    id: 'p17',
    sku: 'SKU-EL-017',
    name: 'Chuột không dây',
    category: 'electronics', // ProductCategory.electronics.code (WTM-393)
    quantity: 260,
    pricePerUnit: 149000,
    reorderLevel: 70,
    updatedAt: DateTime(2026, 7, 17, 9),
  ),
  Product(
    id: 'p18',
    sku: 'SKU-TX-018',
    name: 'Áo khoác gió',
    category: 'fashion', // ProductCategory.fashion.code (WTM-393)
    quantity: 90,
    pricePerUnit: 289000,
    reorderLevel: 35,
    updatedAt: DateTime(2026, 7, 18, 9),
  ),
  Product(
    id: 'p19',
    sku: 'SKU-AC-019',
    name: 'Dây đồng hồ da',
    category: 'accessories', // ProductCategory.accessories.code (WTM-393)
    quantity: 34,
    pricePerUnit: 99000,
    reorderLevel: 40,
    updatedAt: DateTime(2026, 7, 19, 9),
  ),
  Product(
    id: 'p20',
    sku: 'SKU-HG-020',
    name: 'Bình giữ nhiệt 500ml',
    category:
        'home_appliances', // ProductCategory.homeAppliances.code (WTM-393)
    quantity: 175,
    pricePerUnit: 189000,
    reorderLevel: 45,
    updatedAt: DateTime(2026, 7, 20, 9),
  ),
  Product(
    id: 'p21',
    sku: 'SKU-BE-021',
    name: 'Mặt nạ dưỡng da (hộp 10)',
    category: 'cosmetics', // ProductCategory.cosmetics.code (WTM-393)
    quantity: 47,
    pricePerUnit: 129000,
    reorderLevel: 25,
    updatedAt: DateTime(2026, 7, 21, 9),
  ),
  Product(
    id: 'p22',
    sku: 'SKU-EL-022',
    name: 'Đồng hồ thông minh',
    category: 'electronics', // ProductCategory.electronics.code (WTM-393)
    quantity: 12,
    pricePerUnit: 1290000,
    reorderLevel: 20,
    updatedAt: DateTime(2026, 7, 22, 9),
  ),
  Product(
    id: 'p23',
    sku: 'SKU-TX-023',
    name: 'Quần jeans nam',
    category: 'fashion', // ProductCategory.fashion.code (WTM-393)
    quantity: 205,
    pricePerUnit: 349000,
    reorderLevel: 60,
    updatedAt: DateTime(2026, 7, 23, 9),
  ),
  Product(
    id: 'p24',
    sku: 'SKU-AC-024',
    name: 'Balo laptop 15 inch',
    category: 'accessories', // ProductCategory.accessories.code (WTM-393)
    quantity: 68,
    pricePerUnit: 459000,
    reorderLevel: 25,
    updatedAt: DateTime(2026, 7, 24, 9),
  ),
  Product(
    id: 'p25',
    sku: 'SKU-HG-025',
    name: 'Chảo chống dính 26cm',
    category:
        'home_appliances', // ProductCategory.homeAppliances.code (WTM-393)
    quantity: 0,
    pricePerUnit: 259000,
    reorderLevel: 20,
    updatedAt: DateTime(2026, 7, 25, 9),
  ),
  Product(
    id: 'p26',
    sku: 'SKU-BE-026',
    name: 'Sữa rửa mặt',
    category: 'cosmetics', // ProductCategory.cosmetics.code (WTM-393)
    quantity: 130,
    pricePerUnit: 115000,
    reorderLevel: 40,
    updatedAt: DateTime(2026, 7, 26, 9),
  ),
  Product(
    id: 'p27',
    sku: 'SKU-EL-027',
    name: 'Loa bluetooth mini',
    category: 'electronics', // ProductCategory.electronics.code (WTM-393)
    quantity: 95,
    pricePerUnit: 299000,
    reorderLevel: 30,
    updatedAt: DateTime(2026, 7, 27, 9),
  ),
  Product(
    id: 'p28',
    sku: 'SKU-TX-028',
    name: 'Tất cổ ngắn (set 5)',
    category: 'fashion', // ProductCategory.fashion.code (WTM-393)
    quantity: 18,
    pricePerUnit: 79000,
    reorderLevel: 50,
    updatedAt: DateTime(2026, 7, 28, 9),
  ),
];
