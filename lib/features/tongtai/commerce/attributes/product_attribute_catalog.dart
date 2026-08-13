/// The canonical `system.*` attribute catalog the sample dataset is enriched
/// with (WTM-335, ADDENDUM). Pure Dart — no Flutter, no Drift — so the
/// classification, the groups and the industry→attribute mapping are testable
/// without a database and reusable off-device.
///
/// Source spec: `docs/05-DATA/COMMERCE-ATTRIBUTE-MODEL.md` §6.3 + §18. Two rules
/// this file is the antidote to:
///
/// * **§17 enrich, not replace** — this is *additive*. It never touches the 100
///   imported products themselves; it only mints DYNAMIC attribute definitions,
///   groups and per-product values keyed on a product's category.
/// * **Alibaba is a vendor, not a business group** — groups here are business
///   sections (General · Inventory · Shipping · Sourcing · Marketplace ·
///   Fashion · Electronics · Custom, §18). None is a vendor, and every seeded
///   definition uses the `system.*` scope: these are standard, not
///   user- or vendor-authored.
library;

import '../../inventory/product_category.dart';
import 'attribute_models.dart';

/// One catalog group (§18). `code` is a stable `system.*` code; `label` is the
/// Vietnamese display heading; `sortOrder` fixes the section order on the
/// detail screen.
class ProductAttributeGroupSpec {
  const ProductAttributeGroupSpec({
    required this.code,
    required this.label,
    required this.sortOrder,
  });

  final String code;
  final String label;
  final int sortOrder;
}

/// One catalog definition: a `system.*` DYNAMIC field. `groupCode` says which
/// [ProductAttributeGroupSpec] it displays under — the group is a *view*, not a
/// second home for the data (spec §6.3 "nhóm hiển thị ≠ nơi lưu").
class ProductAttributeDefinitionSpec {
  const ProductAttributeDefinitionSpec({
    required this.code,
    required this.type,
    required this.label,
    required this.groupCode,
    this.unit,
    this.enumOptions = const [],
  });

  final String code;
  final AttributeType type;
  final String label;

  /// Which catalog group this field is shown under.
  final String groupCode;
  final String? unit;
  final List<String> enumOptions;
}

/// The eight sample groups (§18). Kept in one place so the enricher and the
/// display share the same ordering and labels.
///
/// The **Sourcing** group is deliberately empty of DYNAMIC fields: `MOQ` /
/// `Lead time` are typed columns on `supplier_quotes_table` (§6.3), *not*
/// attributes. The group still exists because the display may mix typed and
/// dynamic values under it — but the attribute layer stores nothing there.
const List<ProductAttributeGroupSpec> kProductAttributeGroups = [
  ProductAttributeGroupSpec(
    code: 'system.group.general',
    label: 'Thông tin chung',
    sortOrder: 0,
  ),
  ProductAttributeGroupSpec(
    code: 'system.group.inventory',
    label: 'Kho & Tồn',
    sortOrder: 1,
  ),
  ProductAttributeGroupSpec(
    code: 'system.group.shipping',
    label: 'Vận chuyển',
    sortOrder: 2,
  ),
  ProductAttributeGroupSpec(
    code: 'system.group.sourcing',
    label: 'Nhập hàng',
    sortOrder: 3,
  ),
  ProductAttributeGroupSpec(
    code: 'system.group.marketplace',
    label: 'Sàn & Kênh bán',
    sortOrder: 4,
  ),
  ProductAttributeGroupSpec(
    code: 'system.group.fashion',
    label: 'Thời trang',
    sortOrder: 5,
  ),
  ProductAttributeGroupSpec(
    code: 'system.group.electronics',
    label: 'Điện tử',
    sortOrder: 6,
  ),
  ProductAttributeGroupSpec(
    code: 'system.group.custom',
    label: 'Thông số khác',
    sortOrder: 7,
  ),
];

// ── canonical DYNAMIC field codes (system.*) ──────────────────────────────────
//
// Named constants so the value rules and the tests reference the exact same
// codes the definitions declare. Every one is spec/metadata (§6.3) — none
// touches price / order / inventory / identity, so none belongs in a column.

const String kAttrMaterial = 'system.material';
const String kAttrForm = 'system.form';
const String kAttrSeason = 'system.season';
const String kAttrWattage = 'system.wattage';
const String kAttrVoltage = 'system.voltage';
const String kAttrWarrantyMonths = 'system.warranty_months';
const String kAttrDisplaySize = 'system.display_size';
const String kAttrExpiryDate = 'system.expiry_date';
const String kAttrStorageGuidance = 'system.storage_guidance';

/// Enum option codes — stored canonical, never the display label (ADR-TON-018
/// discipline applied to attribute values).
const List<String> kMaterialOptions = [
  'cotton',
  'polyester',
  'linen',
  'denim',
  'wool',
  'plastic',
  'stainless_steel',
  'ceramic',
  'glass',
  'wood',
];
const List<String> kFormOptions = ['regular', 'slim', 'oversize', 'crop'];
const List<String> kSeasonOptions = [
  'spring_summer',
  'autumn_winter',
  'all_season',
];
const List<String> kStorageOptions = ['room_temp', 'cool_dry', 'refrigerated'];

/// Human-readable Vietnamese labels for the stored enum option codes. The
/// display maps a raw code → this label; the AI context does the same, so the
/// prompt never carries a bare `stainless_steel`.
const Map<String, String> kAttributeOptionLabels = {
  'cotton': 'Cotton',
  'polyester': 'Polyester',
  'linen': 'Vải lanh',
  'denim': 'Denim',
  'wool': 'Len',
  'plastic': 'Nhựa',
  'stainless_steel': 'Thép không gỉ',
  'ceramic': 'Gốm sứ',
  'glass': 'Thủy tinh',
  'wood': 'Gỗ',
  'regular': 'Thường',
  'slim': 'Ôm',
  'oversize': 'Rộng',
  'crop': 'Lửng',
  'spring_summer': 'Xuân/Hè',
  'autumn_winter': 'Thu/Đông',
  'all_season': 'Bốn mùa',
  'room_temp': 'Nhiệt độ phòng',
  'cool_dry': 'Nơi khô mát',
  'refrigerated': 'Bảo quản lạnh',
};

/// The full `system.*` definition catalog. Order is display order within a
/// group.
const List<ProductAttributeDefinitionSpec> kProductAttributeDefinitions = [
  // Fashion (§ table: chất liệu · form · mùa)
  ProductAttributeDefinitionSpec(
    code: kAttrMaterial,
    type: AttributeType.enumType,
    label: 'Chất liệu',
    groupCode: 'system.group.custom',
    enumOptions: kMaterialOptions,
  ),
  ProductAttributeDefinitionSpec(
    code: kAttrForm,
    type: AttributeType.enumType,
    label: 'Kiểu dáng',
    groupCode: 'system.group.fashion',
    enumOptions: kFormOptions,
  ),
  ProductAttributeDefinitionSpec(
    code: kAttrSeason,
    type: AttributeType.enumType,
    label: 'Mùa',
    groupCode: 'system.group.fashion',
    enumOptions: kSeasonOptions,
  ),
  // Electronics (§ table: công suất · điện áp · bảo hành) + display size
  ProductAttributeDefinitionSpec(
    code: kAttrWattage,
    type: AttributeType.decimal,
    label: 'Công suất',
    groupCode: 'system.group.electronics',
    unit: 'W',
  ),
  ProductAttributeDefinitionSpec(
    code: kAttrVoltage,
    type: AttributeType.integer,
    label: 'Điện áp',
    groupCode: 'system.group.electronics',
    unit: 'V',
  ),
  ProductAttributeDefinitionSpec(
    code: kAttrWarrantyMonths,
    type: AttributeType.integer,
    label: 'Bảo hành',
    groupCode: 'system.group.electronics',
    unit: 'tháng',
  ),
  ProductAttributeDefinitionSpec(
    code: kAttrDisplaySize,
    type: AttributeType.decimal,
    label: 'Kích thước hiển thị',
    groupCode: 'system.group.electronics',
    unit: 'inch',
  ),
  // Food (§ table: hạn sử dụng · bảo quản). No "Thực phẩm" category ships in the
  // demo dataset today, but the definitions exist so the day one is imported the
  // fields already have a home (spec §17 additive).
  ProductAttributeDefinitionSpec(
    code: kAttrExpiryDate,
    type: AttributeType.date,
    label: 'Hạn sử dụng',
    groupCode: 'system.group.custom',
  ),
  ProductAttributeDefinitionSpec(
    code: kAttrStorageGuidance,
    type: AttributeType.enumType,
    label: 'Bảo quản',
    groupCode: 'system.group.custom',
    enumOptions: kStorageOptions,
  ),
];

/// A resolved per-product value the enricher will write: the definition code
/// plus the canonical raw string. `entityType`/`entityId` are supplied by the
/// enricher.
class ProductAttributeValueSpec {
  const ProductAttributeValueSpec({required this.code, required this.valueRaw});

  final String code;
  final String valueRaw;
}

/// The **industry → attribute** rule (§17 table), keyed on a product's
/// `category`. Given a product's category and a stable seed (its id), returns
/// the DYNAMIC values that product should carry.
///
/// Two deliberate properties, both from the spec:
///
/// * **Not every product has every field.** The rule is industry-dependent, and
///   within an industry a field is applied only when the product's seed selects
///   it — so the dataset stays realistically sparse, never a full grid.
/// * **Deterministic.** The same product id always yields the same values, so a
///   re-seed is idempotent and a test can assert exact values.
///
/// A category the rule does not know (or an empty category) yields no
/// attributes — those products render with the core section only, which the
/// "no attributes ⇒ no grouped block" test relies on.
List<ProductAttributeValueSpec> attributesForProduct({
  required String category,
  required String seed,
}) {
  // WTM-393: khớp theo **mã canonical**, không theo nhãn hiển thị — nên một sản
  // phẩm dù mang mã ('electronics'), nhãn VI ('Điện tử') hay nhãn EN cũ
  // ('Electronics') đều nhận đúng thuộc tính. Trước đây chỉ khớp nhãn VI, nên
  // ~14 sản phẩm bộ sinh (danh mục tiếng Anh) không bao giờ được enrich.
  final normalized =
      ProductCategory.parse(category)?.code ?? category.trim().toLowerCase();
  final n = _seedInt(seed);
  switch (normalized) {
    case 'fashion':
      return [
        ProductAttributeValueSpec(
          code: kAttrMaterial,
          valueRaw: kMaterialOptions[n % 5], // cotton..wool
        ),
        ProductAttributeValueSpec(
          code: kAttrForm,
          valueRaw: kFormOptions[n % kFormOptions.length],
        ),
        // Season is sparse: only ~2/3 of fashion items carry it.
        if (n % 3 != 0)
          ProductAttributeValueSpec(
            code: kAttrSeason,
            valueRaw: kSeasonOptions[n % kSeasonOptions.length],
          ),
      ];
    case 'electronics':
      return [
        ProductAttributeValueSpec(
          code: kAttrWattage,
          valueRaw: '${100 + (n % 20) * 25}', // 100..575 W
        ),
        ProductAttributeValueSpec(
          code: kAttrVoltage,
          valueRaw: n.isEven ? '220' : '110',
        ),
        ProductAttributeValueSpec(
          code: kAttrWarrantyMonths,
          valueRaw: '${[6, 12, 12, 24, 36][n % 5]}',
        ),
        // Display size only for the subset that actually has a screen.
        if (n % 4 == 0)
          ProductAttributeValueSpec(
            code: kAttrDisplaySize,
            valueRaw: '${[13.3, 15.6, 24.0, 27.0][n % 4]}',
          ),
      ];
    case 'home_appliances':
      // §table: kích thước · chất liệu. "Kích thước" here is the *display* spec
      // (dung tích / đường chéo), which is DYNAMIC — distinct from shipping
      // dims (§6.2). Modelled as the display-size field + a fixed material.
      return [
        ProductAttributeValueSpec(
          code: kAttrMaterial,
          valueRaw: kMaterialOptions[5 + (n % 5)], // plastic..wood
        ),
        if (n % 2 == 0)
          ProductAttributeValueSpec(
            code: kAttrDisplaySize,
            valueRaw: '${[1.5, 2.0, 3.5, 5.0][n % 4]}',
          ),
      ];
    case 'food':
      return [
        ProductAttributeValueSpec(
          code: kAttrStorageGuidance,
          valueRaw: kStorageOptions[n % kStorageOptions.length],
        ),
        ProductAttributeValueSpec(
          code: kAttrExpiryDate,
          valueRaw: _futureDate(days: 60 + (n % 12) * 15),
        ),
      ];
    default:
      // Every other demo category (Mỹ phẩm, Mẹ & Bé, Thể thao, Văn phòng phẩm,
      // Đồ chơi) stays attribute-free for now: the spec table names only four
      // industries, and inventing fields for the rest would be fabricating data
      // the seller never entered.
      return const [];
  }
}

/// A small, stable non-negative integer derived from [seed]. Same seed → same
/// number, so seeding is deterministic and re-seeding is idempotent.
int _seedInt(String seed) {
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash;
}

/// An ISO `yyyy-MM-dd` date [days] in the future, computed off a fixed epoch so
/// the sample value is stable across runs (not "now + days", which would drift).
String _futureDate({required int days}) {
  final base = DateTime(2026, 1, 1).add(Duration(days: days));
  final y = base.year.toString().padLeft(4, '0');
  final m = base.month.toString().padLeft(2, '0');
  final d = base.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
