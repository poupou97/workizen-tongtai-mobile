import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_directory_service.dart';
import 'package:tongtai/features/tongtai/navigation/tongtai_design_tokens.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_list_screen.dart';

/// Real unit tests for the WTM-75 customer-directory logic: the value-tier
/// derivation, the tier-color mapping, phone masking, free-text + location
/// filtering, all four sort keys and both directions, and the 20–50-per-page
/// pagination window.
void main() {
  Customer customer({
    String id = 'x',
    String name = 'Khách Hàng',
    String phone = '+84900000000',
    String location = 'Hà Nội',
    int orderCount = 5,
    double totalSpent = 5000000,
    DateTime? lastPurchaseDate,
  }) {
    return Customer(
      id: id,
      name: name,
      phone: phone,
      location: location,
      orderCount: orderCount,
      totalSpent: totalSpent,
      lastPurchaseDate: lastPurchaseDate ?? DateTime(2026, 1, 1),
    );
  }

  group('Customer.tier', () {
    test('at or above the VIP threshold is VIP', () {
      expect(customer(totalSpent: kCustomerTierVipMin).tier, CustomerTier.vip);
      expect(customer(totalSpent: kCustomerTierVipMin + 1).tier,
          CustomerTier.vip);
    });

    test('between Gold and VIP thresholds is Gold', () {
      expect(customer(totalSpent: kCustomerTierGoldMin).tier, CustomerTier.gold);
      expect(customer(totalSpent: kCustomerTierVipMin - 1).tier,
          CustomerTier.gold);
    });

    test('between Silver and Gold thresholds is Silver', () {
      expect(customer(totalSpent: kCustomerTierSilverMin).tier,
          CustomerTier.silver);
      expect(customer(totalSpent: kCustomerTierGoldMin - 1).tier,
          CustomerTier.silver);
    });

    test('below the Silver threshold is Bronze', () {
      expect(customer(totalSpent: kCustomerTierSilverMin - 1).tier,
          CustomerTier.bronze);
      expect(customer(totalSpent: 0).tier, CustomerTier.bronze);
    });

    test('equality is by id', () {
      expect(customer(id: 'same', name: 'A'), customer(id: 'same', name: 'B'));
      expect(customer(id: 'same').hashCode, customer(id: 'same').hashCode);
    });
  });

  group('Customer.maskedPhone', () {
    test('keeps the first six and last three characters', () {
      expect(customer(phone: '+84912345678').maskedPhone, '+84912***678');
    });

    test('returns short numbers unchanged', () {
      expect(customer(phone: '12345').maskedPhone, '12345');
    });

    test('the masked form always hides the middle of a full number', () {
      final masked = customer(phone: '+84987654321').maskedPhone;
      expect(masked, contains('***'));
      expect(masked, isNot('+84987654321'));
    });
  });

  group('CustomerTier — labels & high-value flag', () {
    test('English and Vietnamese labels and the language switch', () {
      expect(CustomerTier.gold.labelEn, 'Gold');
      expect(CustomerTier.gold.labelVi, 'Vàng');
      expect(CustomerTier.silver.labelVi, isNot('Silver'));
      expect(CustomerTier.vip.label('vi'), CustomerTier.vip.labelVi);
      expect(CustomerTier.vip.label('en'), CustomerTier.vip.labelEn);
    });

    test('VIP and Gold are high-value; Silver and Bronze are not', () {
      expect(CustomerTier.vip.isHighValue, isTrue);
      expect(CustomerTier.gold.isHighValue, isTrue);
      expect(CustomerTier.silver.isHighValue, isFalse);
      expect(CustomerTier.bronze.isHighValue, isFalse);
    });
  });

  group('tongtaiCustomerTierColor', () {
    test('maps each tier to its color', () {
      expect(tongtaiCustomerTierColor(CustomerTier.gold),
          TongtaiDesignTokens.warning);
      expect(tongtaiCustomerTierColor(CustomerTier.silver),
          TongtaiDesignTokens.neutral);
    });

    test('the four tiers have distinct colors', () {
      final colors = {
        for (final t in CustomerTier.values) tongtaiCustomerTierColor(t),
      };
      expect(colors.length, CustomerTier.values.length);
    });
  });

  group('sample directory', () {
    final service = CustomerDirectoryService.sample();

    test('has more than one page worth at the default size', () {
      expect(service.all.length, greaterThan(kMinCustomerPageSize));
    });

    test('exposes distinct, sorted locations', () {
      final locations = service.locations;
      expect(locations, contains('Hà Nội'));
      expect(locations.toSet().length, locations.length);
      final sorted = [...locations]..sort();
      expect(locations, sorted);
    });

    test('every phone is unique', () {
      final phones = service.all.map((c) => c.phone).toList();
      expect(phones.toSet().length, phones.length);
    });

    test('covers all four value tiers', () {
      final tiers = service.all.map((c) => c.tier).toSet();
      expect(tiers, containsAll(CustomerTier.values));
    });
  });

  group('filter — search text', () {
    final service = CustomerDirectoryService.sample();

    test('empty query returns the whole directory', () {
      expect(service.filter(const CustomerQuery()).length, service.all.length);
    });

    test('matches customer name case-insensitively', () {
      final results = service.filter(const CustomerQuery(text: 'phương'));
      expect(results, isNotEmpty);
      expect(results.every((c) => c.name.toLowerCase().contains('phương')),
          isTrue);
    });

    test('matches phone number', () {
      final results =
          service.filter(const CustomerQuery(text: '+84912345678'));
      expect(results.map((c) => c.phone), contains('+84912345678'));
      expect(results.length, 1);
    });

    test('matches location text', () {
      final results = service.filter(const CustomerQuery(text: 'hà nội'));
      expect(results, isNotEmpty);
      expect(results.every((c) => c.location == 'Hà Nội'), isTrue);
    });

    test('no match yields an empty list', () {
      expect(service.filter(const CustomerQuery(text: 'zzzznope')), isEmpty);
    });
  });

  group('filter — location facet', () {
    final service = CustomerDirectoryService.sample();

    test('keeps only customers in that location', () {
      final results =
          service.filter(const CustomerQuery(location: 'Hà Nội'));
      expect(results, isNotEmpty);
      expect(results.every((c) => c.location == 'Hà Nội'), isTrue);
    });

    test('facet combines (AND) with the search text', () {
      final results = service.filter(
        const CustomerQuery(text: 'phương', location: 'Hà Nội'),
      );
      expect(results, isNotEmpty);
      for (final c in results) {
        expect(c.location, 'Hà Nội');
        expect(c.name.toLowerCase(), contains('phương'));
      }
    });
  });

  group('filter — sorting', () {
    final service = CustomerDirectoryService.sample();

    List<T> keys<T>(List<Customer> cs, T Function(Customer) f) =>
        cs.map(f).toList();

    test('by name ascending / descending', () {
      final asc = service.filter(const CustomerQuery(sort: CustomerSort.name));
      final desc = service.filter(
        const CustomerQuery(sort: CustomerSort.name, ascending: false),
      );
      final ascNames = keys(asc, (c) => c.name.toLowerCase());
      expect(ascNames, orderedByAscending);
      expect(keys(desc, (c) => c.name.toLowerCase()),
          ascNames.reversed.toList());
    });

    test('by spent ascending puts the lowest-value customer first', () {
      final asc = service.filter(const CustomerQuery(sort: CustomerSort.spent));
      expect(keys(asc, (c) => c.totalSpent), orderedByAscending);
      final min =
          service.all.map((c) => c.totalSpent).reduce((a, b) => a < b ? a : b);
      expect(asc.first.totalSpent, min);
    });

    test('by frequency descending puts the most-frequent buyer first', () {
      final desc = service.filter(
        const CustomerQuery(sort: CustomerSort.frequency, ascending: false),
      );
      expect(keys(desc, (c) => c.orderCount), orderedByDescending);
      final max =
          service.all.map((c) => c.orderCount).reduce((a, b) => a > b ? a : b);
      expect(desc.first.orderCount, max);
    });

    test('by recency (last purchase date)', () {
      final asc =
          service.filter(const CustomerQuery(sort: CustomerSort.recency));
      for (var i = 0; i + 1 < asc.length; i++) {
        expect(
          asc[i].lastPurchaseDate.isAfter(asc[i + 1].lastPurchaseDate),
          isFalse,
        );
      }
    });
  });

  group('page — pagination (AC: 20–50 per page)', () {
    final service = CustomerDirectoryService.sample();

    test('default page size is 20 and the first page fills it', () {
      final p = service.page(const CustomerQuery());
      expect(p.pageSize, 20);
      expect(p.items.length, 20);
      expect(p.pageIndex, 0);
      expect(p.hasPrevious, isFalse);
      expect(p.hasNext, isTrue);
    });

    test('page count and last-page slice are correct', () {
      final total = service.all.length; // 26
      final p0 = service.page(const CustomerQuery());
      expect(p0.totalCount, total);
      expect(p0.pageCount, 2);

      final p1 = service.page(const CustomerQuery(pageIndex: 1));
      expect(p1.items.length, total - 20); // 6
      expect(p1.pageIndex, 1);
      expect(p1.hasNext, isFalse);
      expect(p1.hasPrevious, isTrue);
      expect(p1.lastItemNumber, total);
    });

    test('the union of all pages equals the full filtered set with no gaps', () {
      final full = service.filter(const CustomerQuery());
      final collected = <Customer>[
        ...service.page(const CustomerQuery(pageIndex: 0)).items,
        ...service.page(const CustomerQuery(pageIndex: 1)).items,
      ];
      expect(collected, full);
    });

    test('page size is clamped into the 20–50 bound', () {
      expect(service.page(const CustomerQuery(pageSize: 5)).pageSize, 20);
      expect(service.page(const CustomerQuery(pageSize: 999)).pageSize, 50);
      // At 50 per page the 26-customer directory collapses to a single page.
      final big = service.page(const CustomerQuery(pageSize: 50));
      expect(big.pageCount, 1);
      expect(big.items.length, 26);
    });

    test('an out-of-range page index is clamped to the last page', () {
      final p = service.page(const CustomerQuery(pageIndex: 99));
      expect(p.pageIndex, p.pageCount - 1);
      expect(p.items, isNotEmpty);
    });

    test('empty results still report a single page', () {
      final p = service.page(const CustomerQuery(text: 'zzzznope'));
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
