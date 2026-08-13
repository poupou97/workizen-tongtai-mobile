import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/product_attribute_catalog.dart';
import 'package:tongtai/features/tongtai/inventory/product_category.dart';
import 'package:tongtai/features/tongtai/inventory/product_inventory_service.dart'
    show kSampleProducts;
import 'package:tongtai/features/tongtai/sample/historical_data_generator.dart';

/// WTM-393 — product category is **one canonical taxonomy**.
///
/// The bug (found on Nokia 6.1, audit WTM-392): the Kho screen showed English
/// chips ("Electronics", "Accessories") next to Vietnamese ones because two seed
/// sources wrote `Product.category` in two languages — the XLSX in Vietnamese,
/// the history generator in English.
///
/// The Founder's acceptance (2026-08-13): *"Governance test phải đỏ khi ai đó
/// seed lại một danh mục tiếng Anh — không chỉ test rằng UI hiện đúng chữ."* So
/// these tests assert the **stored** value, at the data layer: every seed source
/// must store an exact [ProductCategory.code], never a display label. Reverting
/// the generator to `'Electronics'` (a label) turns this suite RED.
///
/// Real assertions only — no `expect(true, true)`; each drives the real seed
/// data, the real `parse`, or the real enricher.
void main() {
  final canonicalCodes = {for (final c in ProductCategory.values) c.code};
  bool isCanonicalCode(String raw) => canonicalCodes.contains(raw);

  // A fixed clock so generation is deterministic and never reaches for the
  // real wall clock (repo convention; here only the categories matter).
  HistoricalDataGenerator generator() =>
      HistoricalDataGenerator(clock: () => DateTime(2026, 8, 1));

  group('WTM-393 · one canonical product taxonomy', () {
    test('every history-generator product stores an exact canonical code, for '
        'every business profile (RED if a label is ever seeded again)', () {
      for (final profile in BusinessProfile.values) {
        final data = generator().generate(
          HistoricalDataSpec(months: 12, profile: profile),
        );
        expect(
          data.products,
          isNotEmpty,
          reason: 'profile $profile generated no products',
        );
        for (final p in data.products) {
          expect(
            isCanonicalCode(p.category),
            isTrue,
            reason:
                '[$profile] ${p.sku} category "${p.category}" is NOT a '
                'canonical ProductCategory.code — a display label leaked into '
                'seed data (the WTM-393 / "114 products" bug).',
          );
        }
      }
    });

    test('the built-in kSampleProducts store canonical codes too', () {
      for (final p in kSampleProducts) {
        expect(
          isCanonicalCode(p.category),
          isTrue,
          reason:
              '${p.sku} category "${p.category}" is not a canonical code '
              '(WTM-393).',
        );
      }
    });

    test(
      'a raw label — English OR Vietnamese — is NOT a canonical code: this is '
      'the exact gate the bug tripped',
      () {
        expect(isCanonicalCode('Electronics'), isFalse);
        expect(isCanonicalCode('Home'), isFalse);
        expect(isCanonicalCode('Accessories'), isFalse);
        // Even the correct Vietnamese label is a label, not a stored code.
        expect(isCanonicalCode('Điện tử'), isFalse);
      },
    );

    test('parse() heals every legacy label seen in real seed data', () {
      // English variants the generator + kSampleProducts used to write, and that
      // already sit on real devices (Nokia 6.1) — they must localize on read.
      expect(ProductCategory.parse('Electronics'), ProductCategory.electronics);
      expect(ProductCategory.parse('Home'), ProductCategory.homeAppliances);
      expect(
        ProductCategory.parse('Home Goods'),
        ProductCategory.homeAppliances,
      );
      expect(
        ProductCategory.parse('Smart Home'),
        ProductCategory.homeAppliances,
      );
      expect(ProductCategory.parse('Textiles'), ProductCategory.fashion);
      expect(ProductCategory.parse('Accessories'), ProductCategory.accessories);
      expect(ProductCategory.parse('Beauty'), ProductCategory.cosmetics);
      // Vietnamese XLSX labels heal too.
      expect(ProductCategory.parse('Điện tử'), ProductCategory.electronics);
      expect(ProductCategory.parse('Gia dụng'), ProductCategory.homeAppliances);
      expect(ProductCategory.parse('Mẹ & Bé'), ProductCategory.motherBaby);
      expect(ProductCategory.parse('Đồ chơi'), ProductCategory.toys);
      // Canonical codes round-trip.
      expect(ProductCategory.parse('electronics'), ProductCategory.electronics);
      // A seller's own words are never swallowed.
      expect(ProductCategory.parse('Đặc sản quê'), isNull);
      expect(ProductCategory.normalise('Đặc sản quê'), 'Đặc sản quê');
    });

    test(
      'display() localizes every seeded category to its canonical VN label',
      () {
        final data = generator().generate(const HistoricalDataSpec(months: 6));
        for (final p in data.products) {
          final cat = ProductCategory.parse(p.category);
          expect(cat, isNotNull, reason: '${p.category} did not parse');
          expect(ProductCategory.display(p.category, 'vi'), cat!.labelVi);
          // The stored value is a code, so the label must differ from it.
          expect(ProductCategory.display(p.category, 'vi'), isNot(p.category));
        }
      },
    );

    test(
      'the ~14 formerly-English generator products now gain attribute '
      'enrichment (Option A benefit): the enricher keys off the canonical code',
      () {
        expect(
          attributesForProduct(
            category: ProductCategory.electronics.code,
            seed: 'x',
          ),
          isNotEmpty,
        );
        expect(
          attributesForProduct(
            category: ProductCategory.homeAppliances.code,
            seed: 'x',
          ),
          isNotEmpty,
        );
        expect(
          attributesForProduct(
            category: ProductCategory.fashion.code,
            seed: 'x',
          ),
          isNotEmpty,
        );
        // A Vietnamese label still enriches — no regression for XLSX products.
        expect(
          attributesForProduct(category: 'Điện tử', seed: 'x'),
          isNotEmpty,
        );
      },
    );
  });
}
