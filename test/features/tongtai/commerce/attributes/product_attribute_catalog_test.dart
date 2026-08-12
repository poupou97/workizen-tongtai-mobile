import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/attribute_models.dart';
import 'package:tongtai/features/tongtai/commerce/attributes/product_attribute_catalog.dart';

/// WTM-335 — the `system.*` enrichment catalog and the industry→attribute rule
/// (spec §17/§18). Pure Dart: no database, no widget. Every assertion is real —
/// it drives the actual mapping, never `expect(true, true)`.
void main() {
  group('catalog shape (§18)', () {
    test('every definition uses the system.* scope — not user/vendor', () {
      for (final spec in kProductAttributeDefinitions) {
        final ns = AttributeNamespace.tryParse(spec.code);
        expect(ns, isNotNull, reason: '${spec.code} must be a valid code');
        expect(
          ns!.scope,
          AttributeScope.system,
          reason: 'seeded standard fields are system.*, never vendor-authored',
        );
      }
    });

    test('no definition shadows a core field', () {
      for (final spec in kProductAttributeDefinitions) {
        final leaf = AttributeNamespace.tryParse(spec.code)!.leaf;
        expect(
          kCoreShadowedFields.contains(leaf),
          isFalse,
          reason: '${spec.code} would shadow the core field $leaf',
        );
      }
    });

    test('every definition points at a group that exists', () {
      final groupCodes = {for (final g in kProductAttributeGroups) g.code};
      for (final spec in kProductAttributeDefinitions) {
        expect(
          groupCodes.contains(spec.groupCode),
          isTrue,
          reason: '${spec.code} → ${spec.groupCode} has no group',
        );
      }
    });

    test('no group is named after a vendor (Alibaba is not a group)', () {
      for (final g in kProductAttributeGroups) {
        expect(
          g.code.toLowerCase().contains('alibaba'),
          isFalse,
          reason: 'a vendor must never become a business group (§17)',
        );
        expect(g.code.startsWith('system.group.'), isTrue);
      }
    });

    test('every enum definition ships non-empty options', () {
      for (final spec in kProductAttributeDefinitions) {
        if (spec.type.usesOptions) {
          expect(
            spec.enumOptions,
            isNotEmpty,
            reason: '${spec.code} is an ENUM and needs options',
          );
        }
      }
    });
  });

  group('industry → attribute rule (§17)', () {
    test('Fashion gets material + form (season is sparse)', () {
      final codes = attributesForProduct(
        category: 'Thời trang',
        seed: 'import-F1',
      ).map((v) => v.code).toSet();
      expect(codes, contains(kAttrMaterial));
      expect(codes, contains(kAttrForm));
      // Season present or absent depending on seed — but never any electronics
      // field on a fashion product.
      expect(codes, isNot(contains(kAttrWattage)));
    });

    test('Electronics gets wattage + voltage + warranty', () {
      final codes = attributesForProduct(
        category: 'Điện tử',
        seed: 'import-E1',
      ).map((v) => v.code).toSet();
      expect(
        codes,
        containsAll([kAttrWattage, kAttrVoltage, kAttrWarrantyMonths]),
      );
      expect(codes, isNot(contains(kAttrSeason)));
    });

    test('Home goods gets a material (§ kích thước · chất liệu)', () {
      final codes = attributesForProduct(
        category: 'Gia dụng',
        seed: 'import-H1',
      ).map((v) => v.code).toSet();
      expect(codes, contains(kAttrMaterial));
    });

    test('Food gets expiry + storage guidance', () {
      final codes = attributesForProduct(
        category: 'Thực phẩm',
        seed: 'import-K1',
      ).map((v) => v.code).toSet();
      expect(codes, containsAll([kAttrExpiryDate, kAttrStorageGuidance]));
    });

    test('an unknown or empty category yields NO attributes', () {
      // This is what makes "not every product has every field" true, and what
      // the detail screen's "no attributes ⇒ no grouped block" test relies on.
      expect(attributesForProduct(category: 'Mỹ phẩm', seed: 'x'), isEmpty);
      expect(attributesForProduct(category: '', seed: 'x'), isEmpty);
      expect(attributesForProduct(category: 'Đồ chơi', seed: 'x'), isEmpty);
    });

    test('the rule is deterministic — same seed, same values', () {
      final a = attributesForProduct(category: 'Điện tử', seed: 'import-E7');
      final b = attributesForProduct(category: 'Điện tử', seed: 'import-E7');
      expect(
        a.map((v) => '${v.code}=${v.valueRaw}').toList(),
        b.map((v) => '${v.code}=${v.valueRaw}').toList(),
      );
    });

    test('generated values are valid for their definition type', () {
      final byCode = {for (final d in kProductAttributeDefinitions) d.code: d};
      for (final category in const [
        'Thời trang',
        'Điện tử',
        'Gia dụng',
        'Thực phẩm',
      ]) {
        // Sweep several seeds so the sparse branches are exercised too.
        for (var i = 0; i < 20; i++) {
          for (final v in attributesForProduct(
            category: category,
            seed: 'seed-$category-$i',
          )) {
            final def = byCode[v.code]!;
            expect(
              def.type.isValidValue(v.valueRaw, options: def.enumOptions),
              isTrue,
              reason:
                  '${v.code} value "${v.valueRaw}" invalid for ${def.type.code}',
            );
          }
        }
      }
    });

    test(
      'the dataset is realistically sparse — not every field on every item',
      () {
        // Across many fashion seeds, some carry season and some do not; if the
        // rule handed every product every field, this set would have size 1.
        final seasonPresence = <bool>{};
        for (var i = 0; i < 30; i++) {
          final has = attributesForProduct(
            category: 'Thời trang',
            seed: 'F$i',
          ).any((v) => v.code == kAttrSeason);
          seasonPresence.add(has);
        }
        expect(
          seasonPresence,
          containsAll([true, false]),
          reason: 'season is deliberately sparse across fashion products',
        );
      },
    );
  });
}
