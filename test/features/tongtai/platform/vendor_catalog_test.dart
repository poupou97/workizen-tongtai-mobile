import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/platform/capability_matrix.dart';
import 'package:tongtai/features/tongtai/platform/vendor_catalog.dart';

/// WTM-293 · N1/N2 — Vendor Catalog + Capability Matrix (ADR-TON-024 luật 3).
///
/// Catalog cũ ghi GitHub *"OAuth device flow · n8n có node sẵn"* — **sai cả
/// hai**, và chỉ lộ ra khi dựng connector thật. Hai ô sai đều lệch **cùng một
/// hướng: lạc quan hơn thực tế**. Suite này khoá hai luật giữ cho một bảng dữ
/// liệu không biến thành lời hứa.
void main() {
  Vendor vendor({
    String id = 'v1',
    VendorVerification verification = VendorVerification.production,
    VendorPricing pricing = VendorPricing.free,
    List<String> regions = const ['VN'],
    bool officialApi = true,
    bool n8nNode = false,
    bool communityNode = false,
    bool freeTier = true,
    bool vietnamSupport = true,
    bool productionReady = true,
    bool requiresAnnualAudit = false,
  }) => Vendor(
    id: id,
    name: id,
    category: PlatformCapability.orders,
    verification: verification,
    pricing: pricing,
    popularity: VendorPopularity.high,
    regions: regions,
    officialApi: officialApi,
    n8nNode: n8nNode,
    communityNode: communityNode,
    freeTier: freeTier,
    vietnamSupport: vietnamSupport,
    productionReady: productionReady,
    requiresAnnualAudit: requiresAnnualAudit,
  );

  // ────────────────────────────────────────────────────────────────────────
  group('Luật · `recommended` là hàm thuần, không phải trường', () {
    test('cùng dữ liệu ⇒ cùng kết quả, mọi lần gọi', () {
      final v = vendor();
      expect(v.recommended, v.recommended);
      expect(VendorCatalog.recommended, VendorCatalog.recommended);
    });

    test('mỗi vế công thức đều chặn được, và nói ra lý do', () {
      // Một cờ gán tay nói "không". Cái này nói "không, vì lý do X" — và đó là
      // thứ làm người đọc sửa được đúng chỗ.
      final cases = <String, Vendor>{
        'api_not_production_ready': vendor(productionReady: false),
        'never_tried': vendor(verification: VendorVerification.documented),
        'no_free_entry': vendor(
          freeTier: false,
          pricing: VendorPricing.subscription,
        ),
        'no_official_integration_path': vendor(officialApi: false),
        'no_vietnam_support': vendor(regions: [], vietnamSupport: false),
        'requires_annual_audit': vendor(requiresAnnualAudit: true),
      };
      cases.forEach((reason, v) {
        expect(v.recommended, isFalse, reason: reason);
        expect(v.notRecommendedBecause, contains(reason));
      });
    });

    test('đủ mọi vế ⇒ được khuyến nghị, và không còn lý do nào', () {
      final v = vendor();
      expect(v.recommended, isTrue);
      expect(v.notRecommendedBecause, isEmpty);
    });

    test('community node KHÔNG thay được node chính thức', () {
      // Bài học WTM-268: "n8n có node sẵn" ≠ "dùng node đó là đúng". Community
      // node còn xa hơn một bậc — không ai bảo trì.
      final v = vendor(officialApi: false, n8nNode: false, communityNode: true);
      expect(v.recommended, isFalse);
      expect(v.notRecommendedBecause, contains('no_official_integration_path'));
    });

    test('`documented` KHÔNG đủ để khuyến nghị — phải ít nhất `tried`', () {
      expect(
        vendor(verification: VendorVerification.documented).recommended,
        isFalse,
      );
      expect(
        vendor(verification: VendorVerification.tried).recommended,
        isTrue,
      );
    });

    test('mã verification lạ ⇒ null, không rơi về mức nào', () {
      expect(VendorVerification.fromCode('probably_fine'), isNull);
      expect(VendorVerification.fromCode(null), isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Dữ liệu catalog phản ánh thực tế đã trả giá', () {
    test('GitHub là `production`, và ghi rõ PAT chứ không phải OAuth', () {
      final github = VendorCatalog.byId('github')!;
      expect(github.verification, VendorVerification.production);
      expect(github.oauth, isFalse, reason: 'catalog cũ ghi sai chỗ này');
      expect(github.apiKey, isTrue);
      expect(github.note, contains('PAT'));
    });

    test('Gmail bị loại vì CASA, không phải vì kỹ thuật', () {
      final gmail = VendorCatalog.byId('gmail')!;
      expect(gmail.requiresAnnualAudit, isTrue);
      expect(gmail.recommended, isFalse);
      expect(gmail.notRecommendedBecause, contains('requires_annual_audit'));
      // Và nó KHÔNG bị loại vì thiếu đường tích hợp — đường có, giá mới là vấn đề.
      expect(
        gmail.notRecommendedBecause,
        isNot(contains('no_official_integration_path')),
      );
    });

    test('mọi vendor chưa thử đều không được khuyến nghị', () {
      for (final v in VendorCatalog.all) {
        if (v.verification == VendorVerification.documented) {
          expect(v.recommended, isFalse, reason: v.id);
        }
      }
    });

    test('id là duy nhất', () {
      final ids = VendorCatalog.all.map((v) => v.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Luật · ba cột, và AI chỉ được hứa ở cột ba', () {
    test('C không được vượt P', () {
      expect(
        () => CapabilityCell(
          platform: 'x',
          capability: PlatformCapability.orders,
          connectorCovers: true,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('D không được vượt C', () {
      expect(
        () => CapabilityCell(
          platform: 'x',
          capability: PlatformCapability.orders,
          platformSupports: true,
          verifiedOnDogfood: true,
          evidence: 'có',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('D không bật được nếu KHÔNG có bằng chứng', () {
      // Không bằng chứng thì đó là ý định, và ý định không nói được với người bán.
      expect(
        () => CapabilityCell(
          platform: 'x',
          capability: PlatformCapability.orders,
          platformSupports: true,
          connectorCovers: true,
          verifiedOnDogfood: true,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('ô chỉ có P KHÔNG sinh ra lời hứa nào', () {
      const cell = CapabilityCell(
        platform: 'shopee',
        capability: PlatformCapability.inventory,
        platformSupports: true,
      );
      expect(cell.toClaim(), isNull);
    });

    test('ô có C nhưng chưa D cũng KHÔNG sinh ra lời hứa', () {
      const cell = CapabilityCell(
        platform: 'x',
        capability: PlatformCapability.orders,
        platformSupports: true,
        connectorCovers: true,
      );
      expect(cell.toClaim(), isNull);
    });

    test('chỉ ô D sinh ra lời hứa, và lời hứa luôn mang bằng chứng', () {
      const cell = CapabilityCell(
        platform: 'x',
        capability: PlatformCapability.orders,
        platformSupports: true,
        connectorCovers: true,
        verifiedOnDogfood: true,
        evidence: 'WTM-xxx · 2026-08-07 · 42 bản ghi',
      );
      final claim = cell.toClaim()!;
      expect(claim.platform, 'x');
      expect(claim.evidence, contains('42 bản ghi'));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Ma trận phản ánh sự thật hôm nay', () {
    test('CHỈ GitHub có lời hứa — không nền tảng nào khác', () {
      // Sự thật hôm nay, và ma trận tồn tại để nó không bị đọc nhầm thành khả năng.
      expect(CapabilityMatrix.claims.map((c) => c.platform).toSet(), {
        'github',
      });
    });

    test('Shopee có P đầy đủ nhưng KHÔNG lời hứa nào', () {
      expect(
        CapabilityMatrix.cell(
          'shopee',
          PlatformCapability.orders,
        )!.platformSupports,
        isTrue,
      );
      expect(CapabilityMatrix.claimsFor('shopee'), isEmpty);
    });

    test('mọi ô C đều có P, và mọi ô D đều có C + bằng chứng', () {
      for (final c in CapabilityMatrix.all) {
        if (c.connectorCovers) {
          expect(c.platformSupports, isTrue, reason: c.toString());
        }
        if (c.verifiedOnDogfood) {
          expect(c.connectorCovers, isTrue, reason: c.toString());
          expect(c.evidence, isNotNull, reason: c.toString());
        }
      }
    });

    test('mọi nền tảng trong ma trận đều có mặt trong catalog', () {
      // Hai bảng lệch nhau là cách một cái được cập nhật còn cái kia thì không.
      for (final c in CapabilityMatrix.all) {
        expect(
          VendorCatalog.byId(c.platform),
          isNotNull,
          reason: '${c.platform} có trong ma trận nhưng không có trong catalog',
        );
      }
    });

    test('không ô nào trùng (platform, capability)', () {
      final keys = CapabilityMatrix.all
          .map((c) => '${c.platform}/${c.capability.code}')
          .toList();
      expect(keys.toSet().length, keys.length);
    });
  });
}
