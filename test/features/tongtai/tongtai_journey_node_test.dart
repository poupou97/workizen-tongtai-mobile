import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/journey/journey_node.dart';

/// WTM-185 (J1) — the Journey domain model, and the two invariants that keep
/// ADR-TON-016 checkable rather than merely written down.
void main() {
  JourneyNode node({
    String id = 'n1',
    String? parentId = 'root',
    JourneyNodeOrigin origin = JourneyNodeOrigin.ruleTwin,
    JourneyNodeState state = JourneyNodeState.pending,
    JourneyNodeKind kind = JourneyNodeKind.step,
  }) => JourneyNode(
    id: id,
    journeyId: 'j1',
    parentId: parentId,
    kind: kind,
    title: id,
    origin: origin,
    state: state,
  );

  group('ADR-TON-016 boundary — AI proposes, a person completes', () {
    test('an AI-authored node cannot be constructed as done', () {
      expect(
        () => node(origin: JourneyNodeOrigin.ai, state: JourneyNodeState.done),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a rule-authored node CAN be done', () {
      // The guard must be about authorship, not about completion in general —
      // otherwise derived completion could never mark anything done.
      expect(
        node(
          origin: JourneyNodeOrigin.ruleTwin,
          state: JourneyNodeState.done,
        ).isDone,
        isTrue,
      );
    });

    test('a user-authored node CAN be done', () {
      expect(
        node(
          origin: JourneyNodeOrigin.user,
          state: JourneyNodeState.done,
        ).isDone,
        isTrue,
      );
    });

    test('an AI node cannot be a root', () {
      expect(
        () => node(origin: JourneyNodeOrigin.ai, parentId: null),
        throwsA(isA<AssertionError>()),
      );
    });

    test('an AI node hanging off a parent is fine', () {
      expect(node(origin: JourneyNodeOrigin.ai).origin, JourneyNodeOrigin.ai);
    });
  });

  group('the invariants survive release builds', () {
    // Constructor asserts are compiled out in release, so a hand-edited or
    // corrupted `.ttbk` could otherwise smuggle in an AI-authored completed
    // node. `fromJson` rejects it independently of asserts.
    test('fromJson rejects an AI node marked done', () {
      final json = node().toJson()
        ..['origin'] = 'ai'
        ..['state'] = 'done';
      expect(JourneyNode.fromJson(json), isNull);
    });

    test('fromJson rejects an orphan AI node', () {
      final json = node().toJson()
        ..['origin'] = 'ai'
        ..['parentId'] = null;
      expect(JourneyNode.fromJson(json), isNull);
    });
  });

  group('unknown codes are dropped, never defaulted', () {
    test('an unknown kind drops the node', () {
      final json = node().toJson()..['kind'] = 'quantum_widget';
      expect(JourneyNode.fromJson(json), isNull);
    });

    test('an unknown origin drops the node', () {
      // Defaulting here would be the worst possible guess: an unknown author
      // would silently become `user`, and the ADR-TON-016 boundary would read
      // as "a person put this here" when nobody knows who did.
      final json = node().toJson()..['origin'] = 'from_the_future';
      expect(JourneyNode.fromJson(json), isNull);
    });

    test('an unknown state drops the node', () {
      final json = node().toJson()..['state'] = 'schrodinger';
      expect(JourneyNode.fromJson(json), isNull);
    });

    test('an unknown completion falls back to manual, keeping the node', () {
      // Completion is the one field where a default is safe: `manual` means
      // "a person decides", which is never a claim about data.
      final json = node().toJson()..['completion'] = 'telepathic';
      final parsed = JourneyNode.fromJson(json);
      expect(parsed, isNotNull);
      expect(parsed!.completion, JourneyCompletion.manual);
    });
  });

  group('round-trip', () {
    test('carries every field through JSON', () {
      final original = JourneyNode(
        id: 'n7',
        journeyId: 'j1',
        parentId: 'm1',
        kind: JourneyNodeKind.task,
        title: 'Nhập 50 mã hàng',
        origin: JourneyNodeOrigin.ruleTwin,
        orderIndex: 3,
        state: JourneyNodeState.inProgress,
        completion: JourneyCompletion.derived,
        derivedMetric: 'orders',
        derivedTarget: 50,
        reasonCodes: const ['goal.behind_pace', 'profile.channel_shopee'],
        completedAt: DateTime(2026, 8, 1),
      );
      final back = JourneyNode.fromJson(original.toJson())!;

      expect(back.id, 'n7');
      expect(back.kind, JourneyNodeKind.task);
      expect(back.origin, JourneyNodeOrigin.ruleTwin);
      expect(back.completion, JourneyCompletion.derived);
      expect(back.derivedMetric, 'orders');
      expect(back.derivedTarget, 50);
      expect(back.reasonCodes, hasLength(2));
      expect(back.completedAt, DateTime(2026, 8, 1));
    });

    test('every enum serialises as a lowercase code, never a label', () {
      final codes = [
        ...JourneyState.values.map((v) => v.code),
        ...JourneyNodeKind.values.map((v) => v.code),
        ...JourneyNodeState.values.map((v) => v.code),
        ...JourneyNodeOrigin.values.map((v) => v.code),
        ...JourneyCompletion.values.map((v) => v.code),
      ];
      for (final code in codes) {
        expect(code, matches(RegExp(r'^[a-z_]+$')));
      }
    });
  });

  group('the Bible states are all representable', () {
    test('journey has the five states the Concept names', () {
      expect(JourneyState.values.map((v) => v.code), [
        'draft',
        'active',
        'paused',
        'completed',
        'archived',
      ]);
    });

    test('a node can be blocked — Failure Recovery needs it', () {
      // The Bible requires "if a step fails, AI suggests alternatives". With
      // no way to say a step failed, that rule cannot be built at all.
      expect(
        node(state: JourneyNodeState.blocked).state,
        JourneyNodeState.blocked,
      );
    });
  });
}
