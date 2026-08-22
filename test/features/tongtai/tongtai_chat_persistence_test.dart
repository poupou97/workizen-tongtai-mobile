import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/database/migrations/schema_integrity.dart';
import 'package:tongtai/database/migrations/tongtai_migrations.dart';
import 'package:tongtai/features/tongtai/chat/chat_controller.dart';
import 'package:tongtai/features/tongtai/chat/chat_message.dart';
import 'package:tongtai/features/tongtai/chat/chat_message_store.dart';

/// WTM-81 — Chat Message Persistence (local-only per ADR-TON-004).
///
///  - AC1 (local-first reading): messages persist in SQLite; nothing leaves
///    the device (no sync-outbox rows — asserted).
///  - AC2: sender / timestamp / read-status live as real indexed columns.
///  - AC3: history searchable by keyword or date at the store layer.
///  - AC5: messages survive a restart (fresh controller over the same DB),
///    including messages written before a reply arrived.
class _FixedResponder implements ChatResponder {
  const _FixedResponder(this.replyText);
  final String replyText;

  @override
  Future<String> reply(List<ChatMessage> history, String prompt) async =>
      replyText;
}

void main() {
  late AppDatabase db;
  late DriftChatMessageStore store;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    store = DriftChatMessageStore(db);
  });

  tearDown(() async {
    await db.close();
  });

  ChatMessage message(
    String id, {
    ChatSender sender = ChatSender.seller,
    String text = 'hello',
    DateTime? at,
    ChatMessageStatus status = ChatMessageStatus.sending,
    ChatAttachment? attachment,
  }) => ChatMessage(
    id: id,
    sender: sender,
    text: text,
    timestamp: at ?? DateTime(2026, 7, 22, 9),
    status: status,
    attachment: attachment,
  );

  group('schema v4', () {
    test('chat_messages_table exists with its metadata indices (AC2)', () async {
      final integrity = await verifyTongtaiSchema(db);
      expect(integrity.isValid, isTrue, reason: '$integrity');

      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
            variables: [Variable(kChatMessagesTableName)],
          )
          .get();
      expect(tables, hasLength(1));

      final indices = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name=?",
            variables: [Variable(kChatMessagesTableName)],
          )
          .get();
      final names = [for (final row in indices) row.data['name'] as String];
      expect(names, contains('chat_messages_conversation'));
      expect(names, contains('chat_messages_sent_at'));
    });

    test('a v3 database upgrades to v4 gaining only the chat table', () async {
      // Simulate the upgrade step exactly as buildTongtaiMigrationStrategy
      // runs it for `from < 4`: create the table on a database that lacks it.
      await db.customStatement('DROP TABLE $kChatMessagesTableName');
      final before = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
            variables: [Variable(kChatMessagesTableName)],
          )
          .get();
      expect(before, isEmpty);

      final migrator = db.createMigrator();
      final chatTable = db.allTables.firstWhere(
        (t) => t.actualTableName == kChatMessagesTableName,
      );
      await migrator.createTable(chatTable);

      final integrity = await verifyTongtaiSchema(db);
      expect(integrity.isValid, isTrue, reason: '$integrity');
      // Round-trip works on the upgraded schema.
      await store.save(message('up-1'));
      expect(await store.loadAll(), hasLength(1));
    });

    test('schema version constant advanced in lock-step', () {
      expect(kTongtaiSchemaVersion, 28);
      // v12 (WTM-209): orders_table rebuilt without the channel_id FK — it
      //                pointed at channels_table, a dead v1 table nothing ever
      //                wrote, so every real channel code failed the constraint.
      //                channels_table dropped (WTM-190 precedent).
      // v13 (WTM-212): DTV eliminated — mọi cột dẫn xuất chết bị xoá trong một
      //                lần quét; an toàn cho mọi .ttbk vì codec mã hoá domain
      //                object, không mã hoá cột thô.
      // v17 (WTM-282): orders_table.provenance_code — nguồn gốc bản ghi. Cột
      //                nullable, KHÔNG backfill: dòng cũ không khai nguồn gốc,
      //                và ghi suy đoán xuống đĩa sẽ biến nó thành lời khai.
      // v18 (WTM-283): connections_table thêm; integrations_table XOÁ — bảng
      //                rỗng từ v1 mang 4 cột token, mã hoá một quyết định
      //                trái luật credential của Founder.
      // v19 (WTM-291): external_identities_table + identity_link_events_table
      //                (ADR-TON-024). Thuần thêm mới. Lịch sử KHÔNG có khoá
      //                ngoại tới bảng danh tính — gỡ liên kết là xoá dòng danh
      //                tính, mà bằng chứng phải sống sót qua chính việc nó ghi.
      // v20 (WTM-292): settlement_lines_table + payouts_table. `funded_by`
      //                KHÔNG có DEFAULT — một mặc định ở đó là app tự khai
      //                thay sàn rằng "sàn tài trợ", sai theo hướng tâng bốc.
      // v21 (WTM-299): proposed_changes_table. Không cột điểm — mức tin cậy
      //                tính từ evidence lúc đọc.
      // v22 (WTM-300): business_actions_table — cửa ghi duy nhất.
      // v23 (WTM-301): agent_tasks_table — độc lập với nơi chạy.
      // v24 (WTM-327): product_variants + supplier_quotes + import_jobs.
      // v25 (WTM-323): shipments_table. v26 (WTM-337): demo_events_table.
      // v27 (WTM-334): tầng thuộc tính động — attribute_definitions/values/
      //                groups/group_items. Bốn bảng, thuần thêm; `.ttbk` mang
      //                bốn dataset OPTIONAL, backup cũ vẫn restore.
      // v28 (WTM-443): import_column_maps_table — bản đồ cột người bán tự chỉ
      //                khi nhập file sàn. Một bảng, thuần thêm, khoá tự nhiên
      //                (business_id, vendor, file_kind).
      //                ⚠️ CHƯA vào `.ttbk`: bảng này cố ý **chưa** có dataset
      //                nào trong `BackupDatasets` — khai một tên mà chưa nối
      //                đường đọc/ghi thì schema nói dối về thứ nó hỗ trợ, đúng
      //                khuyết tật của `integrations_table` đã xoá ở v18. Nối
      //                backup là vé riêng.
      expect(db.schemaVersion, 28);
    });
  });

  group('DriftChatMessageStore', () {
    test('save + loadAll round-trips every field, oldest first', () async {
      await store.save(
        message(
          'm2',
          sender: ChatSender.assistant,
          text: 'chào bạn',
          at: DateTime(2026, 7, 22, 9, 5),
          status: ChatMessageStatus.read,
        ),
      );
      await store.save(
        message(
          'm1',
          text: 'xin chào',
          at: DateTime(2026, 7, 22, 9, 0),
          status: ChatMessageStatus.delivered,
          attachment: const ChatAttachment(
            path: '/data/user/0/app/hoa-don.jpg',
            name: 'hoa-don.jpg',
          ),
        ),
      );

      final all = await store.loadAll();
      expect(all.map((m) => m.id), ['m1', 'm2']); // sorted by sentAt
      final first = all.first;
      expect(first.sender, ChatSender.seller);
      expect(first.text, 'xin chào');
      expect(first.timestamp, DateTime(2026, 7, 22, 9, 0));
      expect(first.status, ChatMessageStatus.delivered);
      expect(first.attachment!.path, '/data/user/0/app/hoa-don.jpg');
      expect(first.attachment!.name, 'hoa-don.jpg');
      expect(all.last.attachment, isNull);
    });

    test('updateStatus persists the read receipt (AC2)', () async {
      await store.save(message('m1', status: ChatMessageStatus.delivered));
      await store.updateStatus('m1', ChatMessageStatus.read);
      final all = await store.loadAll();
      expect(all.single.status, ChatMessageStatus.read);
    });

    test('search is case-insensitive for Vietnamese keywords (AC3)', () async {
      // The keyword match runs in Dart (not SQLite LIKE), so case folding
      // covers Vietnamese letters too: "QUẠT" finds "quạt".
      await store.save(message('m1', text: 'Nhập thêm quạt mini'));
      await store.save(
        message('m2', text: 'Doanh thu tháng 7', at: DateTime(2026, 7, 22, 10)),
      );

      final hits = await store.search(const ChatHistoryQuery(text: 'QUẠT'));
      expect(hits.map((m) => m.id), ['m1']);
    });

    test('search by ASCII keyword ignores case (AC3)', () async {
      await store.save(message('m1', text: 'Order DH-2026-0101 shipped'));
      await store.save(
        message('m2', text: 'khác', at: DateTime(2026, 7, 22, 10)),
      );
      final hits = await store.search(const ChatHistoryQuery(text: 'dh-2026'));
      expect(hits.map((m) => m.id), ['m1']);
    });

    test('wildcard characters in user input match literally', () async {
      await store.save(message('m1', text: 'discount 100%'));
      await store.save(
        message('m2', text: 'discount 100x', at: DateTime(2026, 7, 22, 10)),
      );
      final hits = await store.search(const ChatHistoryQuery(text: '100%'));
      expect(hits.map((m) => m.id), ['m1']);
    });

    test('search by inclusive date range (AC3)', () async {
      await store.save(message('m1', at: DateTime(2026, 7, 20)));
      await store.save(message('m2', at: DateTime(2026, 7, 21)));
      await store.save(message('m3', at: DateTime(2026, 7, 22)));

      final hits = await store.search(
        ChatHistoryQuery(
          from: DateTime(2026, 7, 20),
          to: DateTime(2026, 7, 21),
        ),
      );
      expect(hits.map((m) => m.id), ['m1', 'm2']);
    });

    test('keyword and date filters combine', () async {
      await store.save(message('m1', text: 'quạt', at: DateTime(2026, 7, 20)));
      await store.save(message('m2', text: 'quạt', at: DateTime(2026, 7, 22)));
      final hits = await store.search(
        ChatHistoryQuery(text: 'quạt', from: DateTime(2026, 7, 21)),
      );
      expect(hits.map((m) => m.id), ['m2']);
    });
  });

  group('controller persistence (AC5 — survives restart)', () {
    TongtaiChatController makeController(
      ChatMessageStore store, {
      String prefix = 'a',
    }) {
      var id = 0;
      return TongtaiChatController(
        responder: const _FixedResponder('đã nhận'),
        store: store,
        clock: () => DateTime(2026, 7, 22, 9, id + 1),
        idFactory: () => '$prefix${++id}',
      );
    }

    test(
      'send writes through; a fresh controller hydrates the history',
      () async {
        final first = makeController(store);
        await first.send('xin chào');
        expect(first.messages, hasLength(2));

        // "Restart": new controller over the same database.
        final second = makeController(store, prefix: 'b');
        expect(second.isHydrated, isFalse);
        await second.hydrate();
        expect(second.isHydrated, isTrue);
        expect(second.messages, hasLength(2));
        expect(second.messages.first.text, 'xin chào');
        expect(second.messages.first.status, ChatMessageStatus.read);
        expect(second.messages.last.text, 'đã nhận');
      },
    );

    test('a message keeps its delivered state on disk if no reply ever came '
        '(offline shape)', () async {
      // Responder that never completes within the test: simulate by writing
      // through the store directly the way send() does before the reply.
      await store.save(message('m1', status: ChatMessageStatus.sending));
      await store.updateStatus('m1', ChatMessageStatus.delivered);

      final revived = makeController(store);
      await revived.hydrate();
      expect(revived.messages.single.status, ChatMessageStatus.delivered);
    });

    test(
      'hydrate is idempotent and does not duplicate live messages',
      () async {
        final controller = makeController(store);
        await controller.send('one');
        await controller.hydrate();
        await controller.hydrate();
        expect(controller.messages, hasLength(2)); // seller + reply, no dupes
      },
    );

    test('ADR-TON-004: chat writes create NO sync-outbox rows', () async {
      final controller = makeController(store);
      await controller.send('bí mật kinh doanh');
      final outbox = await db.select(db.syncQueueItemsTable).get();
      expect(outbox, isEmpty);
    });
  });

  group('InMemoryChatMessageStore parity', () {
    test('round-trip + search behave like the Drift store', () async {
      final mem = InMemoryChatMessageStore();
      await mem.save(
        message('m1', text: 'quạt mini', at: DateTime(2026, 7, 20)),
      );
      await mem.save(
        message('m2', text: 'doanh thu', at: DateTime(2026, 7, 22)),
      );
      await mem.updateStatus('m1', ChatMessageStatus.read);

      expect((await mem.loadAll()).map((m) => m.id), ['m1', 'm2']);
      expect(
        (await mem.search(
          const ChatHistoryQuery(text: 'QUẠT MINI'),
        )).map((m) => m.id),
        ['m1'],
      );
      expect(
        (await mem.search(
          ChatHistoryQuery(from: DateTime(2026, 7, 21)),
        )).map((m) => m.id),
        ['m2'],
      );
      expect((await mem.loadAll()).first.status, ChatMessageStatus.read);
    });
  });
}
