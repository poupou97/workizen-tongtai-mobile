import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_score.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity.dart';
import 'package:tongtai/features/tongtai/opportunity/opportunity_feed_controller.dart';

/// WTM-182 — hiding the opportunity types the rule engine cannot produce.
///
/// Founder Decision 2026-08-01: *"Giữ Domain. Ẩn Capability chưa có dữ liệu."*
/// So these tests pin **both halves**: the domain keeps all four types, and the
/// feed shows only the two that can exist.
void main() {
  Opportunity make(String id, OpportunityType type) => Opportunity(
    id: id,
    type: type,
    title: id,
    description: id,
    expectedImpact: 1000000,
    score: OpportunityScore.fixed(80),
    discoveredAt: DateTime(2026, 8, 1),
  );

  group('the domain keeps everything', () {
    test('all four types still exist', () {
      // If someone "cleans up" by deleting the enum values, every .ttbk file
      // and sample record holding one becomes unreadable. Hiding is a
      // presentation decision; the domain is not allowed to forget.
      expect(OpportunityType.values, hasLength(4));
      expect(OpportunityType.values, contains(OpportunityType.arbitrage));
      expect(OpportunityType.values, contains(OpportunityType.crossBorder));
    });

    test('hidden types still round-trip through storage', () {
      expect(
        OpportunityType.fromStorage('arbitrage'),
        OpportunityType.arbitrage,
      );
      expect(
        OpportunityType.fromStorage('crossBorder'),
        OpportunityType.crossBorder,
      );
    });

    test('hidden types still have labels in both languages', () {
      // They are hidden from the feed, not from the app: a restored record or
      // a future re-enable must not render as a blank chip.
      for (final type in OpportunityType.values) {
        expect(type.labelEn, isNotEmpty);
        expect(type.labelVi, isNotEmpty);
      }
    });
  });

  group('only what the engine can produce is visible', () {
    test('visible is exactly seasonal + trend', () {
      // The rule engine emits only these two; arbitrage needs prices from two
      // marketplaces and cross-border needs foreign pricing — neither exists
      // on the device until File Bridge (WTM-181).
      expect(OpportunityType.visible, [
        OpportunityType.seasonal,
        OpportunityType.trend,
      ]);
    });

    test('one list controls it — re-enabling is a one-line change', () {
      for (final type in OpportunityType.values) {
        expect(type.isVisible, OpportunityType.visible.contains(type));
      }
    });
  });

  group('the feed', () {
    late OpportunityFeedController controller;

    setUp(() {
      controller = OpportunityFeedController([
        make('t1', OpportunityType.trend),
        make('s1', OpportunityType.seasonal),
        make('a1', OpportunityType.arbitrage),
        make('c1', OpportunityType.crossBorder),
      ]);
    });

    test('shows only the producible types', () {
      final ids = controller
          .feed(const OpportunityQuery())
          .map((o) => o.id)
          .toList();
      expect(ids, containsAll(['t1', 's1']));
      expect(ids, isNot(contains('a1')));
      expect(ids, isNot(contains('c1')));
    });

    test('the facet row never offers a filter that returns nothing', () {
      // The bug this fixes: a seller taps "Arbitrage" and gets an empty list,
      // for ever, with no way to know why.
      expect(
        controller.availableTypes,
        isNot(contains(OpportunityType.arbitrage)),
      );
      expect(
        controller.availableTypes,
        isNot(contains(OpportunityType.crossBorder)),
      );
    });

    test('a hidden opportunity is not deleted, only unlisted', () {
      // Restoring a backup that holds one must not silently drop the record.
      final saved = OpportunityFeedController([
        make('a1', OpportunityType.arbitrage),
      ]);
      expect(saved.feed(const OpportunityQuery()), isEmpty);
      expect(
        saved.all.map((o) => o.id),
        contains('a1'),
        reason: 'hidden from the feed, still present in the store',
      );
    });
  });
}
