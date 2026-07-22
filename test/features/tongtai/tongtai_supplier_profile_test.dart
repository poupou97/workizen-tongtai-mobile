import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/producer/supplier.dart';
import 'package:tongtai/features/tongtai/producer/supplier_profile.dart';
import 'package:tongtai/features/tongtai/producer/supplier_search_service.dart';

/// Real unit tests for the WTM-64 Supplier-detail domain: monogram initials,
/// the deterministic profile builder, and each acceptance-criteria facet —
/// business profile, product catalog breakdown, certifications, transaction
/// summary, and contact details.
void main() {
  const techpro = Supplier(
    id: 's1',
    name: 'TechPro Wholesale',
    location: 'Shenzhen, China',
    rating: 4.8,
    reviewCount: 245,
    categories: ['Electronics', 'Accessories'],
    minOrderUnits: 100,
    leadTime: '7-14 days',
  );

  group('supplierInitials', () {
    test('takes the first letter of the first two words, uppercased', () {
      expect(supplierInitials('TechPro Wholesale'), 'TW');
      expect(supplierInitials('global trade partners'), 'GT');
    });

    test('uses the first two chars of a single word', () {
      expect(supplierInitials('Vinamilk'), 'VI');
    });

    test('handles a single-character word', () {
      expect(supplierInitials('X'), 'X');
    });

    test('collapses extra whitespace', () {
      expect(supplierInitials('  Saigon   Textile  '), 'ST');
    });

    test('falls back to ? for blank input', () {
      expect(supplierInitials('   '), '?');
      expect(supplierInitials(''), '?');
    });
  });

  group('supplierCertifications (AC3)', () {
    test('always includes the baseline ISO 9001', () {
      expect(supplierCertifications(const []), contains('ISO 9001'));
    });

    test('adds category-specific certifications', () {
      final certs = supplierCertifications(const ['Electronics']);
      expect(certs, containsAll(<String>['CE', 'RoHS', 'ISO 9001']));
    });

    test('is de-duplicated across overlapping categories', () {
      // Electronics and Smart Home both imply CE + RoHS.
      final certs = supplierCertifications(const ['Electronics', 'Smart Home']);
      expect(certs.where((c) => c == 'CE').length, 1);
      expect(certs.where((c) => c == 'RoHS').length, 1);
    });

    test('is alphabetically sorted', () {
      final certs = supplierCertifications(const [
        'Agriculture',
        'Electronics',
      ]);
      final sorted = [...certs]..sort();
      expect(certs, sorted);
    });
  });

  group('supplierCatalog (AC2)', () {
    test('has one row per category, in order', () {
      final catalog = supplierCatalog(techpro);
      expect(catalog.map((r) => r.category).toList(), [
        'Electronics',
        'Accessories',
      ]);
    });

    test('every category carries at least a few products', () {
      for (final row in supplierCatalog(techpro)) {
        expect(row.count, greaterThanOrEqualTo(4));
      }
    });

    test('is deterministic for the same supplier', () {
      expect(supplierCatalog(techpro), supplierCatalog(techpro));
    });
  });

  group('supplierTransactions (AC5)', () {
    test('order frequency and volume are positive', () {
      final tx = supplierTransactions(techpro);
      expect(tx.totalOrders, greaterThan(0));
      expect(tx.totalVolumeUnits, greaterThan(0));
    });

    test('average order volume equals the minimum order size', () {
      final tx = supplierTransactions(techpro);
      expect(tx.averageOrderVolume, techpro.minOrderUnits.toDouble());
    });

    test('repeat-buyer rate stays within 0..1', () {
      for (final s in SupplierSearchService.sample().all) {
        final rate = supplierTransactions(s).repeatBuyerRate;
        expect(rate, inInclusiveRange(0.0, 1.0));
      }
    });

    test('averageOrderVolume is 0 when there is no order history', () {
      const empty = SupplierTransactionSummary(
        totalOrders: 0,
        totalVolumeUnits: 0,
        repeatBuyerRate: 0,
      );
      expect(empty.averageOrderVolume, 0);
    });
  });

  group('contact details (AC4)', () {
    test('email is a slug of the supplier name', () {
      expect(
        supplierContactEmail('TechPro Wholesale'),
        'sales@techprowholesale.example',
      );
    });

    test('phone uses the country dialling code', () {
      final phone = supplierContactPhone(techpro); // China
      expect(phone, startsWith('+86 '));
    });

    test('phone falls back to +1 for unknown countries', () {
      const s = Supplier(
        id: 'x',
        name: 'Nowhere Co',
        location: 'Atlantis',
        rating: 4.0,
        reviewCount: 1,
        categories: [],
        minOrderUnits: 10,
        leadTime: '1 day',
      );
      expect(supplierContactPhone(s), startsWith('+1 '));
    });
  });

  group('buildSupplierProfile (AC1 composition)', () {
    test('carries the base supplier fields through', () {
      final profile = buildSupplierProfile(techpro);
      expect(profile.name, techpro.name);
      expect(profile.location, techpro.location);
      expect(profile.rating, techpro.rating);
      expect(profile.reviewCount, techpro.reviewCount);
      expect(profile.initials, 'TW');
    });

    test('description mentions the supplier name and lead time', () {
      final profile = buildSupplierProfile(techpro);
      expect(profile.description, contains('TechPro Wholesale'));
      expect(profile.description, contains('7-14 days'));
    });

    test('productCount equals the sum of the catalog breakdown', () {
      final profile = buildSupplierProfile(techpro);
      final expected = profile.catalog.fold<int>(0, (sum, r) => sum + r.count);
      expect(profile.productCount, expected);
      expect(profile.productCount, greaterThan(0));
    });

    test('exposes contact channels', () {
      final profile = buildSupplierProfile(techpro);
      expect(profile.hasContact, isTrue);
      expect(profile.contactEmail, isNotNull);
      expect(profile.contactPhone, isNotNull);
    });

    test('builds a complete profile for every sample supplier', () {
      for (final s in SupplierSearchService.sample().all) {
        final profile = buildSupplierProfile(s);
        expect(profile.certifications, isNotEmpty);
        expect(profile.catalog.length, s.categories.length);
        expect(profile.productCount, greaterThan(0));
        expect(profile.transactions.totalOrders, greaterThan(0));
      }
    });
  });

  group('value objects', () {
    test('SupplierCategoryCount equality is by category + count', () {
      expect(
        const SupplierCategoryCount('Electronics', 5),
        const SupplierCategoryCount('Electronics', 5),
      );
      expect(
        const SupplierCategoryCount('Electronics', 5),
        isNot(const SupplierCategoryCount('Electronics', 6)),
      );
    });
  });
}
