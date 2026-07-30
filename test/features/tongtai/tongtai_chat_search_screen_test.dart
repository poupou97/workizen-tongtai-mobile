import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/chat/chat_message.dart';
import 'package:tongtai/features/tongtai/chat/chat_message_store.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_chat_search_screen.dart';

/// WTM-84 — chat search finds messages by content and by period.
void main() {
  DateTime fixedNow() => DateTime(2026, 7, 24, 10);

  Future<InMemoryChatMessageStore> seededStore() async {
    final store = InMemoryChatMessageStore();
    await store.save(
      ChatMessage(
        id: 'm1',
        sender: ChatSender.seller,
        text: 'Bán 5 quạt cho khách sỉ',
        timestamp: DateTime(2026, 7, 24, 9),
        status: ChatMessageStatus.read,
      ),
    );
    await store.save(
      ChatMessage(
        id: 'm2',
        sender: ChatSender.assistant,
        text: 'Quạt tích điện đang vào mùa, nên nhập thêm.',
        timestamp: DateTime(2026, 7, 24, 9, 1),
        status: ChatMessageStatus.read,
      ),
    );
    await store.save(
      ChatMessage(
        id: 'm3',
        sender: ChatSender.seller,
        text: 'Nhập hàng áo thun cotton',
        timestamp: DateTime(2026, 7, 23, 8),
        status: ChatMessageStatus.read,
      ),
    );
    return store;
  }

  Widget host(ChatMessageStore store) => MaterialApp(
    home: TongtaiChatSearchScreen(store: store, clock: fixedNow),
  );

  testWidgets('shows a prompt before any keyword is entered', (tester) async {
    await tester.pumpWidget(host(await seededStore()));

    expect(find.byKey(const Key('chat-search-prompt')), findsOneWidget);
    expect(find.byKey(const Key('chat-search-results')), findsNothing);
  });

  testWidgets('finds messages by content, case-insensitive', (tester) async {
    await tester.pumpWidget(host(await seededStore()));

    await tester.enterText(find.byKey(const Key('chat-search-field')), 'quạt');
    await tester.pumpAndSettle();

    // Both "quạt" (m1) and "Quạt" (m2) match.
    expect(find.text('2 results'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));
    // Day header inside the results (distinct from the "Hôm nay" range chip).
    expect(
      find.descendant(
        of: find.byKey(const Key('chat-search-results')),
        matching: find.text('Today'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('no match shows the empty state', (tester) async {
    await tester.pumpWidget(host(await seededStore()));

    await tester.enterText(
      find.byKey(const Key('chat-search-field')),
      'khôngtồntại',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-search-empty')), findsOneWidget);
    expect(find.byKey(const Key('chat-search-results')), findsNothing);
  });

  testWidgets('the Today range excludes older messages', (tester) async {
    await tester.pumpWidget(host(await seededStore()));

    // "áo" only appears in m3 (yesterday).
    await tester.enterText(find.byKey(const Key('chat-search-field')), 'áo');
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);

    // Restrict to today → the yesterday match drops out.
    await tester.tap(find.byKey(const Key('chat-search-range-today')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-search-empty')), findsOneWidget);
  });
}
