import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/profile/business_profile.dart';

/// WTM-177 — the negative control for the AI Business Profile.
///
/// The profile is injected into **every AI prompt**, so in BYOK mode it leaves
/// the device on every question the seller asks. That makes it the highest-risk
/// object in the app for a privacy leak, and the cheapest way to cause one is
/// to add a convenient free-text field six months from now.
///
/// These tests read the source files. That is deliberate: a behavioural test
/// only proves today's values are safe, while the risk here is a *future*
/// column. Structure is what has to be pinned.
void main() {
  final model = File('lib/features/tongtai/profile/business_profile.dart');
  final table = File('lib/database/tables/business_profiles.dart');

  setUpAll(() {
    // Guard the guard: if the paths move, these tests must fail loudly rather
    // than silently pass on an empty string.
    expect(model.existsSync(), isTrue, reason: 'model file moved');
    expect(table.existsSync(), isTrue, reason: 'table file moved');
  });

  /// Words that name a person or a place, in either language. An identifier
  /// containing one of these is almost certainly personal data.
  const forbidden = <String>[
    'name',
    'ten',
    'phone',
    'sdt',
    'dienthoai',
    'email',
    'address',
    'diachi',
    'note',
    'ghichu',
    'comment',
    'description',
    'freetext',
    'customer',
    'khachhang',
    'revenue',
    'doanhthu',
    'amount',
    'sotien',
  ];

  /// The identifiers a file actually declares — column getters and fields —
  /// split into camelCase words.
  ///
  /// The first version of this test lowercased the whole file and searched for
  /// substrings. It failed on `isNotEmpty` (contains "note") and
  /// `extendsTable` (contains "ten"). A check that cries wolf gets deleted by
  /// the next person, so precision here is what keeps the guard alive.
  Set<String> declaredWords(File file) {
    final source = file
        .readAsLinesSync()
        .where(
          (l) =>
              !l.trimLeft().startsWith('///') && !l.trimLeft().startsWith('//'),
        )
        .join('\n');
    final identifiers = <String>{
      // `TextColumn get tradeCode =>`
      ...RegExp(r'\bget\s+(\w+)').allMatches(source).map((m) => m[1]!),
      // `final BusinessTrade? trade;`
      ...RegExp(
        r'\bfinal\s+[\w<>?,\s]+?\s(\w+);',
      ).allMatches(source).map((m) => m[1]!),
      // `this.trade,`
      ...RegExp(r'\bthis\.(\w+)').allMatches(source).map((m) => m[1]!),
    };
    return {
      for (final id in identifiers)
        ...id
            .replaceAllMapped(
              RegExp('([a-z0-9])([A-Z])'),
              (m) => '${m[1]}_${m[2]}',
            )
            .toLowerCase()
            .split('_')
            .where((w) => w.isNotEmpty),
    };
  }

  void expectNoPersonalIdentifiers(File file, String label) {
    final words = declaredWords(file);
    for (final word in forbidden) {
      expect(
        words,
        isNot(contains(word)),
        reason:
            '$label declares an identifier containing "$word". The profile is '
            'sent to an AI provider on every question, so it may hold only '
            'categorical facts about the trade. If this is a legitimate field, '
            'it belongs on a different table.',
      );
    }
  }

  group('the profile cannot carry personal data', () {
    test('no column in the table is named after a person or a place', () {
      expectNoPersonalIdentifiers(table, 'business_profiles.dart');
    });

    test('no field in the model is named after a person or a place', () {
      expectNoPersonalIdentifiers(model, 'business_profile.dart');
    });

    test('BusinessProfile has no free-text field at all', () {
      // Scoped to the class body: the enums each carry a `final String code`,
      // which is a closed vocabulary, not free text. The risk is a String on
      // the profile itself — the one shape that can hold "chị Lan 0909…" and
      // then ride along to an AI provider on every question forever after.
      final source = model.readAsStringSync();
      final body = source.substring(source.indexOf('class BusinessProfile {'));
      final stringFields = RegExp(
        r'^\s*final\s+String\??\s+\w+;',
        multiLine: true,
      ).allMatches(body);
      expect(
        stringFields.map((m) => m[0]!.trim()),
        isEmpty,
        reason:
            'a String field on BusinessProfile is a place for a seller to type '
            'a customer name and phone number, which would then be shipped to '
            'an AI provider on every question thereafter',
      );
    });

    test('the guard itself catches a planted violation', () {
      // Without this, a bug in `declaredWords` would make every test above
      // pass vacuously — the failure mode that makes a governance test worse
      // than no test, because it also removes the suspicion.
      final planted = File('${Directory.systemTemp.path}/planted_profile.dart')
        ..writeAsStringSync(
          'class Bad {\n'
          '  TextColumn get ownerPhone => text().nullable()();\n'
          '  final String customerNote;\n'
          '}\n',
        );
      addTearDown(() => planted.deleteSync());

      final words = declaredWords(planted);
      expect(words, contains('phone'));
      expect(words, contains('customer'));
      expect(words, contains('note'));
    });
  });

  group('what the profile actually serialises', () {
    test('a fully answered profile emits exactly six keys', () {
      const profile = BusinessProfile(
        // WTM-228: `type` là khoá thứ sáu, thêm CÓ CHỦ Ý — test này tồn tại để
        // một trường mới không lặng lẽ đi kèm ra khỏi máy người bán.
        type: BusinessType.digital,
        trade: BusinessTrade.fashion,
        size: BusinessSize.small,
        channels: [SalesChannel.shopee],
        seasonality: BusinessSeasonality.tet,
      );
      expect(profile.toJson().keys.toSet(), {
        'type',
        'trade',
        'size',
        'channels',
        'seasonality',
        'updatedAt',
      }, reason: 'the whole payload, enumerated — nothing else can ride along');
    });

    test('every serialised value is a known code, not a display label', () {
      final codes = {
        ...BusinessTrade.values.map((v) => v.code),
        ...BusinessSize.values.map((v) => v.code),
        ...SalesChannel.values.map((v) => v.code),
        ...BusinessSeasonality.values.map((v) => v.code),
      };
      for (final code in codes) {
        expect(
          code,
          matches(RegExp(r'^[a-z_]+$')),
          reason:
              'codes are lowercase ASCII so they survive a language switch; a '
              'display label would change meaning between builds',
        );
      }
    });

    test('the vocabulary is closed and small', () {
      // A leak needs somewhere to go. Enumerating the entire vocabulary means
      // the set of values that can ever reach an AI provider is finite and
      // reviewable — this test is the review.
      expect(BusinessTrade.values.length, 7);
      expect(BusinessSize.values.length, 4);
      expect(SalesChannel.values.length, 7);
      expect(BusinessSeasonality.values.length, 5);
    });
  });
}
