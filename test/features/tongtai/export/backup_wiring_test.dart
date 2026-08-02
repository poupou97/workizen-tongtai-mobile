import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_backup_provider.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_chat_provider.dart'
    show tongtaiDatabaseProvider;

/// WTM-190 — the **production** backup bundle must carry every dataset.
///
/// ## The bug this exists to prevent
/// `TongtaiBackupRepositories` declares its newer slots as nullable so that the
/// many test call sites keep compiling. That convenience has a cost: forgetting
/// to fill one in the production provider is **not** a compile error, and every
/// existing test still passes, because tests build their own bundle.
///
/// It had already happened twice when this test was written. The AI Business
/// Profile (WTM-177) and the Business Journey tree (WTM-185) both shipped as
/// `.ttbk` datasets, both had passing round-trip tests, and neither was wired
/// into [tongtaiBackupRepositoriesProvider] — so on a real device neither was
/// ever written to a backup. Worse for restore: `Replace` calls
/// `repositories.businessProfile?.deleteAll()`, and a `null` repository has
/// nothing to wipe, so a restored business silently kept the *previous*
/// owner's trade and channels — the exact outcome ADR-TON-018's "Replace means
/// replace" forbids.
void main() {
  test('every optional repository slot is filled in production', () async {
    final dir = await Directory.systemTemp.createTemp('tongtai_backup_wiring');
    final db = AppDatabase.forExecutor(
      NativeDatabase(File('${dir.path}/t.sqlite')),
    );
    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });

    final container = ProviderContainer(
      overrides: [tongtaiDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final repos = container.read(tongtaiBackupRepositoriesProvider);

    expect(
      repos.businessProfile,
      isNotNull,
      reason:
          'WTM-177: without this, a device backup carries no profile and a '
          'restore leaves the previous business profile in place',
    );
    expect(
      repos.journeys,
      isNotNull,
      reason: 'WTM-185: without this, a device backup carries no journey tree',
    );
    expect(
      repos.businessInputs,
      isNotNull,
      reason:
          'WTM-230: nguồn đầu vào phải được nối vào backup — một ô repository '
          'bỏ trống nghĩa là dữ liệu không vào .ttbk VÀ restore không xoá được '
          'nguồn của business cũ (null thì không có gì để xoá)',
    );
    expect(
      repos.opportunityReactions,
      isNotNull,
      reason: 'WTM-190: without this, saves and dismissals are not backed up',
    );
  });

  test('a new nullable slot cannot be added without wiring it', () {
    // The runtime check above only covers the slots that exist today. This one
    // reads the source: every nullable field on the bundle must be named in the
    // production provider. A future dataset added the same way then forgotten
    // fails here on the day it is written, not on the day a seller restores.
    final service = File(
      'lib/features/tongtai/export/backup_service.dart',
    ).readAsStringSync();
    final wiring = File(
      'lib/features/tongtai/providers/tongtai_backup_provider.dart',
    ).readAsStringSync();

    final bundle = RegExp(
      r'class TongtaiBackupRepositories \{(.*?)\n\}',
      dotAll: true,
    ).firstMatch(service);
    expect(bundle, isNotNull, reason: 'TongtaiBackupRepositories moved?');

    final nullableFields = RegExp(
      r'final \w+\?\s+(\w+);',
    ).allMatches(bundle!.group(1)!).map((m) => m.group(1)!).toList();
    expect(
      nullableFields,
      isNotEmpty,
      reason: 'the field regex stopped matching — fix it rather than delete it',
    );

    for (final field in nullableFields) {
      expect(
        wiring.contains('$field:'),
        isTrue,
        reason:
            '`$field` is an optional backup slot that tongtaiBackupRepositoriesProvider '
            'never fills, so real backups silently omit it — wire it up',
      );
    }
  });
}
