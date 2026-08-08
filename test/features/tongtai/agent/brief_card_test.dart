import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/action/business_action.dart';
import 'package:tongtai/features/tongtai/agent/business_brief.dart';
import 'package:tongtai/features/tongtai/consumer/identity_evidence.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_agentic_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_agent_screen.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tongtai_brief_card.dart';

import '../../../support/pump_until.dart';

/// WTM-304 · **thẻ brief trên Home** — trải nghiệm #1.
///
/// > *"Tổng Tài đã nhìn doanh nghiệp **trước khi tôi mở app**."*
void main() {
  BriefItem item({
    String id = 'cust-1',
    BriefKind kind = BriefKind.customerAtRisk,
    BriefSeverity severity = BriefSeverity.warning,
    String headline = 'Chị Phương đã 45 ngày chưa quay lại',
  }) => BriefItem(
    kind: kind,
    severity: severity,
    subjectKind: 'customer',
    subjectId: id,
    headline: headline,
    suggestion: 'Nhắn hỏi thăm',
    evidence: const [
      IdentityEvidence(
        kind: IdentityEvidenceKind.orderHistoryMatch,
        source: 'rule:customer-risk',
        detail: 'Đã mua 8 lần',
      ),
    ],
    move: const DoSomething(
      actionType: BusinessActionType.customerSendMessage,
      vendor: ActionVendor.demo,
    ),
    observedAt: DateTime(2026, 8, 8, 9),
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    List<BriefItem>? items,
    bool fail = false,
    bool hang = false,
    DateTime? now,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          businessBriefProvider.overrideWith((ref) async {
            if (fail) throw StateError('ổ đĩa lỗi');
            if (hang) return Completer<List<BriefItem>>().future;
            return items ?? const <BriefItem>[];
          }),
          briefDecisionsProvider.overrideWith((ref) async => const {}),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('vi'), Locale('en')],
          home: Scaffold(
            body: SingleChildScrollView(
              child: TongtaiBriefCard(
                clock: () => now ?? DateTime(2026, 8, 8, 9),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  group('⭐ Thẻ mở đầu — lời chào, không phải một ô số', () {
    testWidgets('hiện lời chào và số việc', (tester) async {
      await pumpCard(
        tester,
        items: [
          item(),
          item(id: 'cust-2'),
        ],
      );
      await pumpUntilFound(tester, find.byKey(const Key('home-brief')));

      expect(find.text('Chào buổi sáng'), findsOneWidget);
      expect(find.text('Có 2 việc đáng chú ý hôm nay'), findsOneWidget);
      expect(find.text('Chị Phương đã 45 ngày chưa quay lại'), findsWidgets);
    });

    testWidgets('cắt còn ba dòng nhưng ĐẾM đủ', (tester) async {
      // Thẻ là lời chào, không phải danh sách. Nhưng con số phải nói thật —
      // "3 việc" khi có 5 là một câu sai, dù nhìn gọn hơn.
      await pumpCard(
        tester,
        items: [for (var i = 0; i < 5; i++) item(id: 'cust-$i')],
      );
      await pumpUntilFound(tester, find.byKey(const Key('home-brief')));

      expect(find.text('Có 5 việc đáng chú ý hôm nay'), findsOneWidget);
      expect(
        find.byKey(const Key('home-brief-item-customer_at_risk:cust-3')),
        findsNothing,
      );
    });

    testWidgets('mở được màn Tổng Tài', (tester) async {
      await pumpCard(tester, items: [item()]);
      await pumpUntilFound(tester, find.byKey(const Key('home-brief-open')));

      await tester.tap(find.byKey(const Key('home-brief-open')));
      await tester.pumpAndSettle();
      expect(find.byType(TongtaiAgentScreen), findsOneWidget);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  group('Ba trạng thái, và mỗi cái nói một câu khác nhau', () {
    testWidgets('không có việc nào ⇒ thẻ KHÔNG chiếm chỗ', (tester) async {
      // Home vẫn còn hero và mọi thứ khác. Một thẻ rỗng nói "chưa có gì" ngay
      // trên đầu màn hình chỉ làm loãng thứ quan trọng.
      await pumpCard(tester, items: const []);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('home-brief')), findsNothing);
      expect(find.byKey(const Key('home-brief-failed')), findsNothing);
    });

    testWidgets('đang tính ⇒ không nhấp nháy một khung xám', (tester) async {
      await pumpCard(tester, hang: true);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('home-brief')), findsNothing);
      expect(find.byKey(const Key('home-brief-failed')), findsNothing);
    });

    testWidgets('⭐ hỏng thì NÓI, không im lặng', (tester) async {
      // Im lặng ở đây đọc thành "hôm nay không có gì đáng chú ý" — câu dối
      // nguy hiểm nhất thẻ này có thể nói.
      await pumpCard(tester, fail: true);
      await pumpUntilFound(tester, find.byKey(const Key('home-brief-failed')));
      expect(find.byKey(const Key('home-brief-retry')), findsOneWidget);
    });
  });
}
