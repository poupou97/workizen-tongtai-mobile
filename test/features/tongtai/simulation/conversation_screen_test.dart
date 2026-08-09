import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tongtai/core/prefs.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/action/business_action.dart';
import 'package:tongtai/features/tongtai/action/demo_action_handlers.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_models.dart';
import 'package:tongtai/features/tongtai/commerce/commerce_repository.dart';
import 'package:tongtai/features/tongtai/commerce/import/commerce_importer.dart';
import 'package:tongtai/features/tongtai/commerce/import/xlsx_commerce_source.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/finance/settlement_repository.dart';
import 'package:tongtai/features/tongtai/inventory/product_repository.dart';
import 'package:tongtai/features/tongtai/logistics/shipment_repository.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_agentic_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_connection_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;
import 'package:tongtai/features/tongtai/providers/tongtai_simulation_provider.dart';
import 'package:tongtai/features/tongtai/simulation/customer_conversation.dart';
import 'package:tongtai/features/tongtai/simulation/demo_event_repository.dart';
import 'package:tongtai/features/tongtai/simulation/simulation_engine.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_conversation_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_conversations_screen.dart';

import '../../../support/pump_until.dart';

/// WTM-339 · E3 — hộp thư + khung hội thoại (`IMPLEMENTATION_LEVEL=L3`).
void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  final anchor = DateTime(2026, 8, 9, 12);

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() => db.close());

  /// Danh mục thật + 30 ngày kinh doanh đã chạy tới ngày 6 — đủ để cả hai câu
  /// chuyện có hội thoại (bình luận Facebook ngày 1, khách giận ngày 5).
  Future<void> seedBusiness() async {
    final file = File('assets/demo/TongTai-Commerce-Demo-100-Products.xlsx');
    final preview = await XlsxCommerceSource(
      bytes: file.readAsBytesSync(),
      fileName: file.uri.pathSegments.last,
      now: anchor,
    ).read();
    await CommerceImporter(
      database: db,
      products: DriftProductRepository(db),
      customers: DriftCustomerRepository(db),
      orders: DriftOrderRepository(db),
      settlements: DriftSettlementRepository(db),
      commerce: CommerceRepository(db),
      shipments: ShipmentRepository(db),
      now: () => anchor,
      newId: () => 'test',
    ).apply(preview, sourceVendor: ImportVendor.bundledDemo, isDemo: true);

    final engine = SimulationEngine(
      events: DemoEventRepository(db),
      orders: DriftOrderRepository(db),
      products: DriftProductRepository(db),
      customers: DriftCustomerRepository(db),
      settlements: DriftSettlementRepository(db),
      shipments: ShipmentRepository(db),
      prefs: prefs,
    );
    await engine.start(anchor: anchor);
    await engine.advanceDay(days: 6);
  }

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        tongtaiDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        tongtaiActionHandlersProvider.overrideWithValue(demoActionHandlers),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<ProviderContainer> pumpInbox(WidgetTester tester) async {
    final c = container();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(
          locale: Locale('vi'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: [Locale('vi'), Locale('en')],
          home: TongtaiConversationsScreen(),
        ),
      ),
    );
    return c;
  }

  testWidgets('chưa bắt đầu ⇒ nói phải làm gì, không để màn trắng', (
    tester,
  ) async {
    await pumpInbox(tester);
    await pumpUntilFound(tester, find.byKey(const Key('conversations-empty')));

    expect(find.textContaining('Bắt đầu doanh nghiệp demo'), findsOneWidget);
  });

  testWidgets('⭐ hộp thư hiện việc đang chờ, và mở ra là cả câu chuyện', (
    tester,
  ) async {
    await seedBusiness();
    await pumpInbox(tester);
    await pumpUntilFound(tester, find.byKey(const Key('conversations-list')));

    // Việc cần duyệt nằm ở dòng ĐẦU — không phải cái mới nhất.
    expect(find.text('Cần bạn duyệt'), findsWidgets);

    await tester.tap(find.byType(ListTile).first);
    await pumpUntilFound(tester, find.byKey(const Key('conversation-thread')));

    expect(find.byKey(const Key('conversation-draft')), findsOneWidget);
    expect(find.byKey(const Key('conversation-send')), findsOneWidget);
  });

  testWidgets('⭐ bấm Gửi ⇒ có HÀNH ĐỘNG thật, và nó khai là mô phỏng (§40)', (
    tester,
  ) async {
    await seedBusiness();
    final c = container();

    final conversations = await c.read(customerConversationsProvider.future);
    final waiting = conversationsForInbox(conversations).first;
    expect(waiting.pendingDraft, isNotNull);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('vi'), Locale('en')],
          home: TongtaiConversationScreen(customerId: waiting.customerId),
        ),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('conversation-send')));

    await tester.tap(find.byKey(const Key('conversation-send')));
    await tester.pumpAndSettle();

    final actions = await c
        .read(businessActionExecutorProvider)
        .loadRecent(limit: 10);
    final reply = actions.firstWhere(
      (a) => a.type == BusinessActionType.customerSendMessage,
    );

    // Đường đi thật: vòng đời chạy hết, kết quả có thật.
    expect(reply.status, ActionStatus.succeeded);
    // …nhưng nó khai thẳng là chưa ra khỏi máy — chỗ khoe kết quả và chỗ khai
    // mô phỏng là CÙNG MỘT trường.
    expect(reply.vendor, ActionVendor.demo);
    expect(isDemoResult(reply.externalId), isTrue);

    // Và câu trả lời vào sổ, nên dòng thời gian cũng thấy.
    final timeline = await DemoEventRepository(db).loadTimeline(limit: 500);
    expect(timeline.where((e) => e.id.startsWith('seller-reply-')), isNotEmpty);
  });

  testWidgets('gửi xong ⇒ không còn nút Gửi cho cùng bản nháp', (tester) async {
    await seedBusiness();
    final c = container();

    final waiting = conversationsForInbox(
      await c.read(customerConversationsProvider.future),
    ).first;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('vi'), Locale('en')],
          home: TongtaiConversationScreen(customerId: waiting.customerId),
        ),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('conversation-send')));

    await tester.tap(find.byKey(const Key('conversation-send')));
    await tester.pumpAndSettle();

    // Nháp biến mất vì THỨ TỰ tin nhắn đổi, không vì màn tự nhớ đã bấm rồi.
    expect(find.byKey(const Key('conversation-draft')), findsNothing);

    final after = await c.read(
      customerConversationProvider(waiting.customerId).future,
    );
    expect(after?.pendingDraft, isNull);
    expect(after?.messages.last.side, ConversationSide.seller);
  });

  testWidgets('sửa lời rồi gửi ⇒ gửi đúng lời ĐÃ SỬA', (tester) async {
    await seedBusiness();
    final c = container();

    final waiting = conversationsForInbox(
      await c.read(customerConversationsProvider.future),
    ).first;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('vi'), Locale('en')],
          home: TongtaiConversationScreen(customerId: waiting.customerId),
        ),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('conversation-edit')));

    await tester.tap(find.byKey(const Key('conversation-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('conversation-edit-field')),
      'Dạ em gửi bù chị mã 100k ạ',
    );
    await tester.tap(find.byKey(const Key('conversation-edit-save')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('conversation-send')));
    await tester.pumpAndSettle();

    final after = await c.read(
      customerConversationProvider(waiting.customerId).future,
    );
    expect(after?.messages.last.text, 'Dạ em gửi bù chị mã 100k ạ');
  });
}
