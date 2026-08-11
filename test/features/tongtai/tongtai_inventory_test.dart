import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_inventory_service.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_inventory_screen.dart';
import 'package:tongtai/core/design/tt.dart';

/// Real unit tests for the WTM-68 inventory logic: the stock-status derivation,
/// the color mapping, free-text + category filtering, all four sort keys and
/// both directions, and the 20–50-per-page pagination window.
void main() {
  Product product({
    String id = 'x',
    String sku = 'SKU-X',
    String name = 'Widget',
    String category = 'Electronics',
    int quantity = 10,
    double pricePerUnit = 1000,
    int reorderLevel = 5,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id,
      sku: sku,
      name: name,
      category: category,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      reorderLevel: reorderLevel,
      updatedAt: updatedAt ?? DateTime(2026, 1, 1),
    );
  }

  group('Product.stockStatus', () {
    test('zero quantity is out of stock', () {
      expect(product(quantity: 0).stockStatus, StockStatus.outOfStock);
    });

    test('at or below the reorder level is low stock', () {
      expect(
        product(quantity: 5, reorderLevel: 5).stockStatus,
        StockStatus.lowStock,
      );
      expect(
        product(quantity: 3, reorderLevel: 5).stockStatus,
        StockStatus.lowStock,
      );
    });

    test('above the reorder level is in stock', () {
      expect(
        product(quantity: 6, reorderLevel: 5).stockStatus,
        StockStatus.inStock,
      );
    });

    test('stockValue is unit price times quantity', () {
      expect(product(quantity: 4, pricePerUnit: 2500).stockValue, 10000);
    });

    test('equality is by id', () {
      expect(product(id: 'same', name: 'A'), product(id: 'same', name: 'B'));
      expect(product(id: 'same').hashCode, product(id: 'same').hashCode);
    });
  });

  group('tongtaiStockStatusColor', () {
    test('maps each status to its semantic color', () {
      // Ánh xạ NGHĨA không đổi (còn hàng → tích cực, sắp hết → cần chú ý, hết
      // → nguy cấp); chỉ bảng màu chuyển sang Design System (WTM-370). Khẳng
      // định theo token, không theo mã màu — một test ghim mã màu sẽ đỏ mỗi
      // lần bảng màu đổi kể cả khi nghĩa giữ nguyên.
      expect(tongtaiStockStatusColor(StockStatus.inStock), TtColors.success);
      expect(tongtaiStockStatusColor(StockStatus.lowStock), TtColors.warning);
      expect(tongtaiStockStatusColor(StockStatus.outOfStock), TtColors.danger);
    });

    test('the three statuses have distinct colors', () {
      final colors = {
        for (final s in StockStatus.values) tongtaiStockStatusColor(s),
      };
      expect(colors.length, StockStatus.values.length);
    });
  });

  group('StockStatus labels', () {
    test('English and Vietnamese labels differ and language switch works', () {
      expect(StockStatus.lowStock.labelEn, 'Low stock');
      expect(StockStatus.lowStock.labelVi, isNot('Low stock'));
      expect(
        StockStatus.outOfStock.label('vi'),
        StockStatus.outOfStock.labelVi,
      );
      expect(
        StockStatus.outOfStock.label('en'),
        StockStatus.outOfStock.labelEn,
      );
    });
  });

  group('sample catalog', () {
    final service = ProductInventoryService.sample();

    test('has more than one page worth at the default size', () {
      expect(service.all.length, greaterThan(kMinProductPageSize));
    });

    test('exposes distinct, sorted categories', () {
      final categories = service.categories;
      expect(categories, contains('Electronics'));
      expect(categories.toSet().length, categories.length);
      final sorted = [...categories]..sort();
      expect(categories, sorted);
    });

    test('every SKU is unique', () {
      final skus = service.all.map((p) => p.sku).toList();
      expect(skus.toSet().length, skus.length);
    });

    test('covers all three stock statuses', () {
      final statuses = service.all.map((p) => p.stockStatus).toSet();
      expect(statuses, containsAll(StockStatus.values));
    });
  });

  group('filter — search text', () {
    final service = ProductInventoryService.sample();

    test('empty query returns the whole catalog', () {
      expect(service.filter(const ProductQuery()).length, service.all.length);
    });

    test('matches product name case-insensitively', () {
      final results = service.filter(const ProductQuery(text: 'bluetooth'));
      expect(results, isNotEmpty);
      expect(
        results.every((p) => p.name.toLowerCase().contains('bluetooth')),
        isTrue,
      );
    });

    test('matches SKU', () {
      final results = service.filter(const ProductQuery(text: 'SKU-EL-001'));
      expect(results.map((p) => p.sku), contains('SKU-EL-001'));
    });

    test('matches category text', () {
      final results = service.filter(const ProductQuery(text: 'beauty'));
      expect(results, isNotEmpty);
      expect(results.every((p) => p.category == 'Beauty'), isTrue);
    });

    test('no match yields an empty list', () {
      expect(service.filter(const ProductQuery(text: 'zzzznope')), isEmpty);
    });
  });

  group('filter — category facet', () {
    final service = ProductInventoryService.sample();

    test('keeps only products in that category', () {
      final results = service.filter(
        const ProductQuery(category: 'Electronics'),
      );
      expect(results, isNotEmpty);
      expect(results.every((p) => p.category == 'Electronics'), isTrue);
    });

    test('facet combines (AND) with the search text', () {
      final results = service.filter(
        const ProductQuery(text: 'bluetooth', category: 'Electronics'),
      );
      expect(results, isNotEmpty);
      for (final p in results) {
        expect(p.category, 'Electronics');
        expect(p.name.toLowerCase(), contains('bluetooth'));
      }
    });
  });

  group('filter — sorting', () {
    final service = ProductInventoryService.sample();

    List<T> keys<T>(List<Product> ps, T Function(Product) f) =>
        ps.map(f).toList();

    test('by name ascending / descending', () {
      final asc = service.filter(const ProductQuery(sort: ProductSort.name));
      final desc = service.filter(
        const ProductQuery(sort: ProductSort.name, ascending: false),
      );
      final ascNames = keys(asc, (p) => p.name.toLowerCase());
      expect(ascNames, orderedByAscending);
      expect(
        keys(desc, (p) => p.name.toLowerCase()),
        ascNames.reversed.toList(),
      );
    });

    test('by price ascending puts the cheapest first', () {
      final asc = service.filter(const ProductQuery(sort: ProductSort.price));
      expect(keys(asc, (p) => p.pricePerUnit), orderedByAscending);
      final min = service.all
          .map((p) => p.pricePerUnit)
          .reduce((a, b) => a < b ? a : b);
      expect(asc.first.pricePerUnit, min);
    });

    test('by quantity descending puts the most-stocked first', () {
      final desc = service.filter(
        const ProductQuery(sort: ProductSort.quantity, ascending: false),
      );
      expect(keys(desc, (p) => p.quantity), orderedByDescending);
      // Mẫu vẫn là hàng vật lý nên đều có số lượng; `!` ở đây là khẳng định
      // về dữ liệu của test, không phải giả định về mô hình.
      final max = service.all
          .map((p) => p.quantity!)
          .reduce((a, b) => a > b ? a : b);
      expect(desc.first.quantity, max);
    });

    test('by last updated', () {
      final asc = service.filter(
        const ProductQuery(sort: ProductSort.lastUpdated),
      );
      for (var i = 0; i + 1 < asc.length; i++) {
        expect(asc[i].updatedAt.isAfter(asc[i + 1].updatedAt), isFalse);
      }
    });
  });

  group('page — pagination (AC: 20–50 per page)', () {
    final service = ProductInventoryService.sample();

    test('default page size is 20 and the first page fills it', () {
      final p = service.page(const ProductQuery());
      expect(p.pageSize, 20);
      expect(p.items.length, 20);
      expect(p.pageIndex, 0);
      expect(p.hasPrevious, isFalse);
      expect(p.hasNext, isTrue);
    });

    test('page count and last-page slice are correct', () {
      final total = service.all.length; // 28
      final p0 = service.page(const ProductQuery());
      expect(p0.totalCount, total);
      expect(p0.pageCount, 2);

      final p1 = service.page(const ProductQuery(pageIndex: 1));
      expect(p1.items.length, total - 20); // 8
      expect(p1.pageIndex, 1);
      expect(p1.hasNext, isFalse);
      expect(p1.hasPrevious, isTrue);
      expect(p1.lastItemNumber, total);
    });

    test(
      'the union of all pages equals the full filtered set with no gaps',
      () {
        final full = service.filter(const ProductQuery());
        final collected = <Product>[
          ...service.page(const ProductQuery(pageIndex: 0)).items,
          ...service.page(const ProductQuery(pageIndex: 1)).items,
        ];
        expect(collected, full);
      },
    );

    test('page size is clamped into the 20–50 bound', () {
      expect(service.page(const ProductQuery(pageSize: 5)).pageSize, 20);
      expect(service.page(const ProductQuery(pageSize: 999)).pageSize, 50);
      // At 50 per page the 28-item catalog collapses to a single page.
      final big = service.page(const ProductQuery(pageSize: 50));
      expect(big.pageCount, 1);
      expect(big.items.length, 28);
    });

    test('an out-of-range page index is clamped to the last page', () {
      final p = service.page(const ProductQuery(pageIndex: 99));
      expect(p.pageIndex, p.pageCount - 1);
      expect(p.items, isNotEmpty);
    });

    test('empty results still report a single page', () {
      final p = service.page(const ProductQuery(text: 'zzzznope'));
      expect(p.isEmpty, isTrue);
      expect(p.pageCount, 1);
      expect(p.firstItemNumber, 0);
      expect(p.lastItemNumber, 0);
    });
  });
}

/// Matches an iterable whose elements are in non-decreasing order.
final Matcher orderedByAscending = predicate<List<dynamic>>((list) {
  for (var i = 0; i + 1 < list.length; i++) {
    if (Comparable.compare(list[i] as Comparable, list[i + 1] as Comparable) >
        0) {
      return false;
    }
  }
  return true;
}, 'is ordered ascending');

/// Matches an iterable whose elements are in non-increasing order.
final Matcher orderedByDescending = predicate<List<dynamic>>((list) {
  for (var i = 0; i + 1 < list.length; i++) {
    if (Comparable.compare(list[i] as Comparable, list[i + 1] as Comparable) <
        0) {
      return false;
    }
  }
  return true;
}, 'is ordered descending');
