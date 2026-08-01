import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/export/backup_format.dart';
import 'package:tongtai/features/tongtai/profile/business_profile.dart';
import 'package:tongtai/features/tongtai/profile/business_profile_repository.dart';

/// WTM-177 — AI Business Profile: model, persistence and the two rules that
/// keep it from doing harm (no PII, no breaking old backups).
void main() {
  late Directory dir;
  late AppDatabase db;
  late BusinessProfileRepository repo;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('tongtai_profile_test');
    db = AppDatabase.forExecutor(NativeDatabase(File('${dir.path}/t.sqlite')));
    repo = BusinessProfileRepository(db);
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  group('persistence', () {
    test(
      'a device that never answered reads as empty, not as an error',
      () async {
        final profile = await repo.load();
        expect(profile.isEmpty, isTrue);
        expect(profile.trade, isNull);
        expect(profile.channels, isEmpty);
      },
    );

    test('round-trips every field through a real SQLite file', () async {
      final saved = BusinessProfile(
        trade: BusinessTrade.fashion,
        size: BusinessSize.small,
        channels: const [SalesChannel.shopee, SalesChannel.shop],
        seasonality: BusinessSeasonality.tet,
      );
      await repo.save(saved, now: DateTime(2026, 8, 1));

      final loaded = await repo.load();
      expect(loaded.trade, BusinessTrade.fashion);
      expect(loaded.size, BusinessSize.small);
      expect(
        loaded.channels,
        containsAll([SalesChannel.shop, SalesChannel.shopee]),
      );
      expect(loaded.seasonality, BusinessSeasonality.tet);
      expect(loaded.updatedAt, DateTime(2026, 8, 1));
    });

    test(
      'saving twice updates the one row instead of adding a second',
      () async {
        await repo.save(
          const BusinessProfile(trade: BusinessTrade.food),
          now: DateTime(2026, 8, 1),
        );
        await repo.save(
          const BusinessProfile(trade: BusinessTrade.cosmetics),
          now: DateTime(2026, 8, 2),
        );

        final rows = await db.select(db.businessProfilesTable).get();
        expect(
          rows.length,
          1,
          reason:
              'one device runs one business — a second row could never be '
              'chosen between',
        );
        expect((await repo.load()).trade, BusinessTrade.cosmetics);
      },
    );

    test('a partially answered profile is kept, not rejected', () async {
      await repo.save(
        const BusinessProfile(trade: BusinessTrade.services),
        now: DateTime(2026, 8, 1),
      );
      final loaded = await repo.load();
      expect(loaded.trade, BusinessTrade.services);
      expect(loaded.size, isNull);
      expect(loaded.isNotEmpty, isTrue);
    });
  });

  group('unknown codes', () {
    test('an unrecognised code reads as null, never as a default', () async {
      // A row written by a newer build. ADR-TON-018 sets the rule for restore
      // and it applies here for the same reason: guessing turns missing
      // information into confident wrong information.
      await db.customStatement(
        "INSERT INTO business_profiles_table "
        "(id, trade_code, updated_at) VALUES (1, 'quantum_widgets', 0)",
      );
      final loaded = await repo.load();
      expect(loaded.trade, isNull);
      expect(loaded.trade, isNot(BusinessTrade.other));
    });

    test(
      'one unknown code does not discard the fields that are valid',
      () async {
        await db.customStatement(
          "INSERT INTO business_profiles_table "
          "(id, trade_code, size_code, updated_at) "
          "VALUES (1, 'from_the_future', 'solo', 0)",
        );
        final loaded = await repo.load();
        expect(loaded.trade, isNull);
        expect(loaded.size, BusinessSize.solo);
      },
    );
  });

  group('channel codes', () {
    test('are stored sorted so tap order never looks like an edit', () {
      const a = BusinessProfile(
        channels: [SalesChannel.zalo, SalesChannel.shop],
      );
      const b = BusinessProfile(
        channels: [SalesChannel.shop, SalesChannel.zalo],
      );
      expect(a.channelCodes, b.channelCodes);
    });

    test('an unknown channel is dropped, the rest survive', () {
      final channels = BusinessProfile.channelsFromCodes('shop,mars,shopee');
      expect(channels, [SalesChannel.shop, SalesChannel.shopee]);
    });
  });

  group(
    'backup compatibility (the rule that protects existing .ttbk files)',
    () {
      test('businessProfile is NOT in the required dataset list', () {
        // BackupService rejects a package missing any required dataset. If the
        // profile were required, every .ttbk written before today would stop
        // restoring — an additive feature causing a data-loss-shaped bug.
        expect(
          BackupDatasets.all,
          isNot(contains(BackupDatasets.businessProfile)),
          reason:
              'adding this to `all` retroactively invalidates every backup '
              'file that already exists on sellers\' devices',
        );
        expect(
          BackupDatasets.optional,
          contains(BackupDatasets.businessProfile),
        );
      });

      test('the required list is exactly the original six', () {
        expect(BackupDatasets.all, hasLength(6));
      });

      test('round-trips through JSON as codes, never as labels', () {
        const profile = BusinessProfile(
          trade: BusinessTrade.homeGoods,
          size: BusinessSize.growing,
          channels: [SalesChannel.tiktok],
          seasonality: BusinessSeasonality.yearEnd,
        );
        final json = profile.toJson();
        expect(json['trade'], 'home_goods');
        expect(json['channels'], ['tiktok']);

        final back = BusinessProfile.fromJson(json);
        expect(back.trade, BusinessTrade.homeGoods);
        expect(back.seasonality, BusinessSeasonality.yearEnd);
      });

      test(
        'decoding a profile from a newer build keeps what it understands',
        () {
          final back = BusinessProfile.fromJson({
            'trade': 'fashion',
            'size': 'enormous',
            'channels': ['shop', 'telepathy'],
            'seasonality': null,
          });
          expect(back.trade, BusinessTrade.fashion);
          expect(back.size, isNull);
          expect(back.channels, [SalesChannel.shop]);
        },
      );
    },
  );
}
