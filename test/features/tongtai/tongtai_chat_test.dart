import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/chat/chat_controller.dart';
import 'package:tongtai/features/tongtai/chat/chat_message.dart';
import 'package:tongtai/features/tongtai/chat/chat_message_store.dart';
import 'package:tongtai/core/design/tt.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_chat_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_chat_search_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_home_screen.dart';

/// Tests for the WTM-80 Chat Screen UI: controller unit tests (delivery
/// states, typing flag, reply pipeline) and widget tests for every AC.
class _FixedResponder implements ChatResponder {
  _FixedResponder(this.replyText);
  final String replyText;
  List<ChatMessage>? lastHistory;

  @override
  Future<String> reply(List<ChatMessage> history, String prompt) async {
    lastHistory = history;
    return replyText;
  }
}

/// Responder that completes only when the test says so — lets a test observe
/// the typing indicator while a reply is pending.
class _GatedResponder implements ChatResponder {
  final Completer<String> gate = Completer<String>();

  @override
  Future<String> reply(List<ChatMessage> history, String prompt) => gate.future;
}

TongtaiChatController makeController(
  ChatResponder responder, {
  DateTime Function()? clock,
}) {
  var id = 0;
  return TongtaiChatController(
    responder: responder,
    clock: clock ?? () => DateTime(2026, 7, 22, 9, 30),
    idFactory: () => 'm${++id}',
  );
}

void main() {
  group('TongtaiChatController', () {
    test('send appends the seller message and the assistant reply', () async {
      final responder = _FixedResponder('Chào bạn!');
      final controller = makeController(responder);

      await controller.send('Xin chào');

      expect(controller.messages, hasLength(2));
      final seller = controller.messages.first;
      final assistant = controller.messages.last;
      expect(seller.sender, ChatSender.seller);
      expect(seller.text, 'Xin chào');
      expect(seller.timestamp, DateTime(2026, 7, 22, 9, 30));
      expect(assistant.sender, ChatSender.assistant);
      expect(assistant.text, 'Chào bạn!');
    });

    test('AC3: the seller message ends read after the reply arrives', () async {
      final controller = makeController(_FixedResponder('ok'));
      await controller.send('hello');
      expect(controller.messages.first.status, ChatMessageStatus.read);
    });

    test('AC5: typing flag is up exactly while the responder works', () async {
      final responder = _GatedResponder();
      final controller = makeController(responder);

      final pending = controller.send('hi');
      // Let send() run its write-through persistence (WTM-81) and reach the
      // responder; it is now suspended on the gated reply.
      await Future<void>.delayed(Duration.zero);
      // Reply not yet produced: typing, message delivered but not read.
      expect(controller.isAssistantTyping, isTrue);
      expect(controller.messages.single.status, ChatMessageStatus.delivered);

      responder.gate.complete('done');
      await pending;
      expect(controller.isAssistantTyping, isFalse);
      expect(controller.messages.first.status, ChatMessageStatus.read);
    });

    test('blank text with no attachment is ignored', () async {
      final controller = makeController(_FixedResponder('x'));
      await controller.send('   ');
      expect(controller.messages, isEmpty);
    });

    test('an attachment alone is a valid message (AC4)', () async {
      final controller = makeController(_FixedResponder('nice photo'));
      await controller.send(
        '',
        attachment: const ChatAttachment(path: '/tmp/a.jpg', name: 'a.jpg'),
      );
      expect(controller.messages.first.hasAttachment, isTrue);
      expect(controller.messages.first.attachment!.isImage, isTrue);
      expect(controller.messages, hasLength(2));
    });

    test('the responder sees the history including the new message', () async {
      final responder = _FixedResponder('r');
      final controller = makeController(responder);
      await controller.send('first');
      await controller.send('second');
      expect(responder.lastHistory!.map((m) => m.text), contains('second'));
    });
  });

  group('ChatAttachment.isImage', () {
    test('recognizes image extensions case-insensitively', () {
      expect(
        const ChatAttachment(path: 'x', name: 'Photo.JPG').isImage,
        isTrue,
      );
      expect(const ChatAttachment(path: 'x', name: 'a.png').isImage, isTrue);
      expect(
        const ChatAttachment(path: 'x', name: 'invoice.pdf').isImage,
        isFalse,
      );
    });
  });

  group('TongtaiChatScreen widget', () {
    // The screen reads the chat-store provider only when it builds its own
    // controller; these tests inject one, so an empty ProviderScope suffices.
    Widget host(
      TongtaiChatController controller, {
      Future<String?> Function()? picker,
    }) => ProviderScope(
      child: MaterialApp(
        home: TongtaiChatScreen(
          controller: controller,
          attachmentPicker: picker,
        ),
      ),
    );

    testWidgets('AC2: typing (emoji included) and sending clears the input '
        'and shows the bubble', (tester) async {
      final controller = makeController(_FixedResponder('reply'));
      await tester.pumpWidget(host(controller));

      await tester.enterText(
        find.byKey(const Key('chat-input')),
        'Bán 5 quạt 🎉',
      );
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();

      expect(find.text('Bán 5 quạt 🎉'), findsOneWidget);
      expect(find.text('reply'), findsOneWidget);
      final input = tester.widget<TextField>(
        find.byKey(const Key('chat-input')),
      );
      expect(input.controller!.text, isEmpty);
    });

    testWidgets('AC1: seller bubble sits right, assistant bubble left, both '
        'with timestamps', (tester) async {
      final controller = makeController(_FixedResponder('reply'));
      await tester.pumpWidget(host(controller));
      await tester.enterText(find.byKey(const Key('chat-input')), 'hello');
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();

      Alignment alignmentOf(String id) {
        final align = tester.widget<Align>(
          find
              .ancestor(
                of: find.byKey(Key('chat-bubble-$id')),
                matching: find.byType(Align),
              )
              .first,
        );
        return align.alignment as Alignment;
      }

      expect(alignmentOf('m1'), Alignment.centerRight); // seller
      expect(alignmentOf('m2'), Alignment.centerLeft); // assistant
      // Timestamp (09:30 from the injected clock) on both bubbles.
      expect(find.text('09:30'), findsNWidgets(2));
    });

    testWidgets('AC3: the seller message shows blue double ticks once read', (
      tester,
    ) async {
      final controller = makeController(_FixedResponder('reply'));
      await tester.pumpWidget(host(controller));
      await tester.enterText(find.byKey(const Key('chat-input')), 'hello');
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();

      final ticks = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('chat-bubble-m1')),
          matching: find.byIcon(Icons.done_all),
        ),
      );
      expect(ticks.color, TtColors.info);
    });

    testWidgets('AC5: typing indicator shows while the reply is pending and '
        'presence reads Online', (tester) async {
      final responder = _GatedResponder();
      final controller = makeController(responder);
      await tester.pumpWidget(host(controller));

      expect(find.text('Online'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('chat-input')), 'hi');
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pump();

      expect(find.byKey(const Key('chat-typing')), findsOneWidget);

      responder.gate.complete('done');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-typing')), findsNothing);
    });

    testWidgets('AC4: picking an attachment previews it, sending renders it '
        'in the bubble', (tester) async {
      final controller = makeController(_FixedResponder('got it'));
      await tester.pumpWidget(
        host(controller, picker: () async => '/tmp/chat/hoa-don.pdf'),
      );

      await tester.tap(find.byKey(const Key('chat-attach')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-pending-attachment')), findsOneWidget);
      expect(find.text('hoa-don.pdf'), findsOneWidget);

      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();

      // Preview row is gone; the document chip lives in the sent bubble now.
      expect(find.byKey(const Key('chat-pending-attachment')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('chat-bubble-m1')),
          matching: find.text('hoa-don.pdf'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a queued attachment can be removed before sending', (
      tester,
    ) async {
      final controller = makeController(_FixedResponder('x'));
      await tester.pumpWidget(
        host(controller, picker: () async => '/tmp/a.jpg'),
      );

      await tester.tap(find.byKey(const Key('chat-attach')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-remove-attachment')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chat-pending-attachment')), findsNothing);
    });

    testWidgets('empty state greets in ONE locale (P0 §2 WTM-145)', (
      tester,
    ) async {
      final controller = makeController(_FixedResponder('x'));
      await tester.pumpWidget(host(controller));
      // Default test locale is EN; the VI variant must NOT be on screen.
      expect(find.text('Ask Workizen AI about your business'), findsOneWidget);
      expect(
        find.text('Hỏi Workizen AI về việc kinh doanh của bạn'),
        findsNothing,
      );
    });
  });

  group('Home entry point', () {
    testWidgets('the chat action on Home opens the chat screen', (
      tester,
    ) async {
      // No controller injected here, so the screen builds its own over the
      // chat-store provider — override it away from the real database.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tongtaiChatStoreProvider.overrideWithValue(
              InMemoryChatMessageStore(),
            ),
          ],
          child: const MaterialApp(home: TongtaiHomeScreen()),
        ),
      );
      await tester.tap(find.byKey(const Key('home-open-chat')));
      await tester.pumpAndSettle();
      expect(find.byType(TongtaiChatScreen), findsOneWidget);
      expect(find.text('Workizen AI'), findsOneWidget);
    });

    testWidgets('WTM-81: a persisted conversation hydrates into the screen', (
      tester,
    ) async {
      final store = InMemoryChatMessageStore();
      await store.save(
        ChatMessage(
          id: 'old-1',
          sender: ChatSender.seller,
          text: 'tin nhắn từ phiên trước',
          timestamp: DateTime(2026, 7, 21, 8),
          status: ChatMessageStatus.read,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [tongtaiChatStoreProvider.overrideWithValue(store)],
          child: const MaterialApp(home: TongtaiChatScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('tin nhắn từ phiên trước'), findsOneWidget);
    });

    testWidgets('the search action opens chat search (WTM-84)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tongtaiChatStoreProvider.overrideWithValue(
              InMemoryChatMessageStore(),
            ),
          ],
          child: const MaterialApp(home: TongtaiChatScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('chat-open-search')));
      await tester.pumpAndSettle();

      expect(find.byType(TongtaiChatSearchScreen), findsOneWidget);
    });
  });
}
