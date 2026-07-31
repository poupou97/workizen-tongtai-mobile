import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/providers/tongtai_consumer_provider.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_risk_screen.dart';

import '../../support/pump_until.dart';

/// WTM-172 — a failed name lookup on the risk screen must say so.
///
/// Before this fix the screen did `await repository.loadAll()` with nobody
/// watching. A throwing read left the name map empty — and an empty name map
/// does not look like an error, it looks like a list of customers whose names
/// happen to be missing. The risk assessment beside them still rendered, which
/// is the worst version of this bug: wrong-looking data presented as fact.
void main() {
  Widget host(CustomerRepository repo) => ProviderScope(
    overrides: [customerRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en'), Locale('vi')],
      home: TongtaiCustomerRiskScreen(),
    ),
  );

  testWidgets('a throwing customer read surfaces, it does not go quiet', (
    tester,
  ) async {
    await tester.pumpWidget(host(_ThrowingCustomers()));
    await pumpUntilFound(tester, find.byType(SnackBar));

    expect(
      find.byType(SnackBar),
      findsOneWidget,
      reason:
          'the seller has to learn the names could not be read; silence here '
          'reads as "these customers have no names"',
    );
  });

  testWidgets('a working read fills the names with no error shown', (
    tester,
  ) async {
    await tester.pumpWidget(host(_WorkingCustomers()));
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
  });
}

class _ThrowingCustomers implements CustomerRepository {
  @override
  Future<List<Customer>> loadAll() async => throw StateError('db is gone');

  @override
  Future<void> upsert(Customer customer) async {}
  @override
  Future<void> upsertAll(Iterable<Customer> customers) async {}
  @override
  Future<void> deleteByIdPrefix(String prefix, {Set<String> keep = const {}}) =>
      Future.value();
  @override
  Future<void> deleteAll() async {}
}

class _WorkingCustomers implements CustomerRepository {
  @override
  Future<List<Customer>> loadAll() async => [
    Customer(
      id: 'c1',
      name: 'Chị Lan',
      phone: '0901',
      location: 'Hà Nội',
      orderCount: 3,
      totalSpent: 1000000,
      lastPurchaseDate: DateTime(2026, 7, 1),
    ),
  ];

  @override
  Future<void> upsert(Customer customer) async {}
  @override
  Future<void> upsertAll(Iterable<Customer> customers) async {}
  @override
  Future<void> deleteByIdPrefix(String prefix, {Set<String> keep = const {}}) =>
      Future.value();
  @override
  Future<void> deleteAll() async {}
}
