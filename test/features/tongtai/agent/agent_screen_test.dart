import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/action/business_action.dart';
import 'package:tongtai/features/tongtai/agent/brief_inbox.dart';
import 'package:tongtai/features/tongtai/agent/business_brief.dart';
import 'package:tongtai/features/tongtai/consumer/identity_evidence.dart';
import 'package:tongtai/features/tongtai/proposal/proposed_change.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_agentic_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_agent_screen.dart';

import '../../../support/pump_until.dart';

/// WTM-304 · **màn Tổng Tài** — trải nghiệm #1.
///
/// Test đi qua `Key`, không qua chữ hiển thị (ADR-TON-015 §3): chữ đổi theo
/// locale, và một test bám vào chữ sẽ lặng lẽ thôi kiểm màn hình vào ngày ai
/// đó sửa một nhãn.
void main() {
  final observed = DateTime(2026, 8, 8, 9);

  BriefItem customerItem({
    String id = 'cust-1',
    String? label = 'Chị Phương',
  }) => BriefItem(
    kind: BriefKind.customerAtRisk,
    severity: BriefSeverity.warning,
    subjectKind: 'customer',
    subjectId: id,
    subjectLabel: label,
    headline: '${label ?? 'Một khách quen'} đã 45 ngày chưa quay lại',
    suggestion: 'Nhắn hỏi thăm và gợi ý mặt hàng họ hay mua',
    evidence: const [
      IdentityEvidence(
        kind: IdentityEvidenceKind.orderHistoryMatch,
        source: 'rule:customer-risk',
        detail: 'Đã mua 8 lần',
      ),
      IdentityEvidence(
        kind: IdentityEvidenceKind.orderHistoryMatch,
        source: 'rule:customer-risk',
        detail: 'Lần mua gần nhất cách đây 45 ngày',
      ),
    ],
    move: const DoSomething(
      actionType: BusinessActionType.customerSendMessage,
      vendor: ActionVendor.demo,
    ),
    observedAt: DateTime(2026, 8, 8, 9),
  );

  BriefItem signalItem() => BriefItem(
    kind: BriefKind.businessSignal,
    severity: BriefSeverity.info,
    subjectKind: 'business',
    subjectId: 'revenueDrop',
    headline: 'Doanh thu kỳ này thấp hơn kỳ trước',
    suggestion: 'Mở Báo cáo để xem điều gì đã đổi',
    evidence: const [
      IdentityEvidence(
        kind: IdentityEvidenceKind.businessRecordObservation,
        source: 'rule:business-alerts/revenueDrop',
        detail: '8 triệu so với 12 triệu kỳ trước',
      ),
    ],
    observedAt: DateTime(2026, 8, 8, 9),
  );

  BriefItem sampleItem() => BriefItem(
    kind: BriefKind.marginTooThin,
    severity: BriefSeverity.critical,
    subjectKind: 'product',
    subjectId: 'sample-prod-1',
    subjectLabel: 'Nồi chiên (mẫu)',
    headline: 'Nồi chiên (mẫu) đang bán dưới giá vốn',
    suggestion: 'Cân nhắc nâng giá bán',
    evidence: const [
      IdentityEvidence(
        kind: IdentityEvidenceKind.businessRecordObservation,
        source: 'rule:margin',
        detail: 'Giá bán 80.000 ₫',
      ),
    ],
    move: const ChangeAFact(
      domain: ProposalDomain.pricing,
      field: 'pricePerUnit',
      proposedValue: '112000',
    ),
    observedAt: DateTime(2026, 8, 8, 9),
  );

  Future<void> pumpAgent(
    WidgetTester tester, {
    required List<BriefItem> items,
    Map<String, BriefDecision> decisions = const {},
    DateTime? now,
    Object? error,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          businessBriefProvider.overrideWith(
            (ref) async => error != null ? throw StateError('$error') : items,
          ),
          briefDecisionsProvider.overrideWith((ref) async => decisions),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('vi'), Locale('en')],
          home: TongtaiAgentScreen(clock: () => now ?? observed),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  group('⭐ Cảm giác "đã nhìn doanh nghiệp trước khi tôi mở app"', () {
    testWidgets('lời chào + số việc, ngay trên đầu', (tester) async {
      await pumpAgent(tester, items: [customerItem(), signalItem()]);
      await pumpUntilFound(tester, find.byKey(const Key('agent-headline')));

      expect(find.byKey(const Key('agent-greeting')), findsOneWidget);
      expect(find.text('Chào buổi sáng'), findsOneWidget);
      expect(find.text('Có 2 việc đáng chú ý hôm nay'), findsOneWidget);
    });

    testWidgets('buổi chiều thì chào buổi chiều', (tester) async {
      await pumpAgent(
        tester,
        items: [customerItem()],
        now: DateTime(2026, 8, 8, 14),
      );
      await pumpUntilFound(tester, find.byKey(const Key('agent-greeting')));
      expect(find.text('Chào buổi chiều'), findsOneWidget);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Trật tự trên màn là trật tự của VIỆC', () {
    testWidgets('việc cần quyết tách khỏi việc chỉ để biết', (tester) async {
      await pumpAgent(tester, items: [customerItem(), signalItem()]);
      await pumpUntilFound(tester, find.byKey(const Key('agent-list')));

      expect(find.byKey(const Key('agent-section-decide')), findsOneWidget);
      expect(find.byKey(const Key('agent-section-know')), findsOneWidget);
    });

    testWidgets('không có việc để biết ⇒ không hiện mục đó', (tester) async {
      await pumpAgent(tester, items: [customerItem()]);
      await pumpUntilFound(tester, find.byKey(const Key('agent-list')));
      expect(find.byKey(const Key('agent-section-know')), findsNothing);
    });

    testWidgets('mỗi việc có key theo id của đối tượng', (tester) async {
      await pumpAgent(tester, items: [customerItem(id: 'cust-9')]);
      await pumpUntilFound(
        tester,
        find.byKey(const Key('agent-item-customer_at_risk:cust-9')),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('⭐ Vì sao đi kèm, không phải một khẳng định trần', () {
    testWidgets('lý do hiện thành câu người bán đọc được', (tester) async {
      await pumpAgent(tester, items: [customerItem()]);
      await pumpUntilFound(tester, find.byKey(const Key('agent-list')));

      expect(find.text('Đã mua 8 lần'), findsOneWidget);
      expect(find.text('Lần mua gần nhất cách đây 45 ngày'), findsOneWidget);
    });

    testWidgets('KHÔNG lộ mã nguồn bằng chứng ra màn hình', (tester) async {
      // `rule:customer-risk` là từ vựng của hệ thống. Người bán đọc "vì sao",
      // không đọc tên luật.
      await pumpAgent(tester, items: [customerItem()]);
      await pumpUntilFound(tester, find.byKey(const Key('agent-list')));

      expect(find.textContaining('rule:'), findsNothing);
      expect(find.textContaining('correlationId'), findsNothing);
      expect(find.textContaining('AgentTask'), findsNothing);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Dữ liệu mẫu phải NHÌN RA ĐƯỢC (WTM-143)', () {
    testWidgets('việc về bản ghi mẫu mang nhãn', (tester) async {
      await pumpAgent(tester, items: [sampleItem()]);
      await pumpUntilFound(tester, find.byKey(const Key('agent-list')));
      expect(find.text('Dữ liệu mẫu'), findsOneWidget);
    });

    testWidgets('việc về dữ liệu thật KHÔNG mang nhãn', (tester) async {
      await pumpAgent(tester, items: [customerItem()]);
      await pumpUntilFound(tester, find.byKey(const Key('agent-list')));
      expect(find.text('Dữ liệu mẫu'), findsNothing);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Trạng thái quyết định hiện ngay trên thẻ', () {
    testWidgets('đã duyệt ⇒ chip "Bạn đã duyệt"', (tester) async {
      await pumpAgent(
        tester,
        items: [customerItem()],
        decisions: {'customer_at_risk:cust-1': BriefDecision.accepted},
      );
      await pumpUntilFound(
        tester,
        find.byKey(const Key('agent-status-accepted-customer_at_risk:cust-1')),
      );
    });

    testWidgets('chưa quyết ⇒ không có chip nào', (tester) async {
      await pumpAgent(tester, items: [customerItem()]);
      await pumpUntilFound(tester, find.byKey(const Key('agent-list')));
      expect(
        find.byKey(const Key('agent-status-pending-customer_at_risk:cust-1')),
        findsNothing,
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Rỗng và hỏng là HAI câu khác nhau', () {
    testWidgets('không có việc nào ⇒ trạng thái rỗng tử tế', (tester) async {
      // "Chưa có việc nào cần bạn quyết" là một TIN TỐT. Một ô "Không có dữ
      // liệu" ở đây sẽ đọc như app hỏng.
      await pumpAgent(tester, items: const []);
      await pumpUntilFound(tester, find.byKey(const Key('agent-empty')));
      expect(find.text('Chưa có việc nào cần bạn quyết'), findsOneWidget);
    });

    testWidgets('⭐ đọc hỏng KHÔNG hiện thành "không có việc nào"', (
      tester,
    ) async {
      await pumpAgent(tester, items: const [], error: 'ổ đĩa lỗi');
      await pumpUntilFound(tester, find.byKey(const Key('agent-error')));
      expect(
        find.byKey(const Key('agent-empty')),
        findsNothing,
        reason:
            '"chưa tính được" và "không có gì" dẫn tới hai hành vi khác nhau',
      );
    });
  });
}
