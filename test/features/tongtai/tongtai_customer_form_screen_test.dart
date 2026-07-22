import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_directory_controller.dart';
import 'package:tongtai/features/tongtai/consumer/customer_history.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_form_screen.dart';
import 'package:tongtai/features/tongtai/ui/screens/tongtai_customer_list_screen.dart';

/// Widget tests for the WTM-76 Add/Edit Customer form screen and its wiring on
/// the Customer list screen (FAB add + tap-row edit).
void main() {
  void useTallViewport(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(500, 3400);
  }

  Customer existing({String id = 'c1'}) => Customer(
    id: id,
    name: 'Phương Nguyễn',
    phone: '+84912345678',
    location: 'Hà Nội',
    orderCount: 3,
    totalSpent: 5000000,
    lastPurchaseDate: DateTime(2026, 7, 1),
    addresses: const ['12 Hàng Bài, Hoàn Kiếm'],
    segments: const ['Loyal Customers'],
    notes: 'Prefers COD',
  );

  /// Pushes the form over a host page and records what it pops.
  Widget host({
    Customer? customer,
    List<Customer> Function(String, String)? findDuplicates,
    required void Function(Customer?) onResult,
  }) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<Customer>(
                MaterialPageRoute(
                  builder: (_) => TongtaiCustomerFormScreen(
                    customer: customer,
                    findDuplicates: findDuplicates,
                    clock: () => DateTime(2026, 7, 22, 12),
                    idFactory: () => 'generated-id',
                  ),
                ),
              );
              onResult(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  Future<void> openForm(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  // Flushes the invalid-save SnackBar's auto-dismiss timer so it isn't left
  // pending at teardown.
  Future<void> dismissSnackBar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  group('add mode (AC1)', () {
    testWidgets('saving an empty form flags name + phone, does not pop', (
      tester,
    ) async {
      useTallViewport(tester);
      Customer? result;
      var popped = false;
      await tester.pumpWidget(
        host(
          onResult: (r) {
            popped = true;
            result = r;
          },
        ),
      );
      await openForm(tester);

      await tester.tap(find.byKey(const Key('customer-save')));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Phone is required'), findsOneWidget);
      expect(popped, isFalse);
      expect(result, isNull);
      await dismissSnackBar(tester);
    });

    testWidgets('flags a malformed email but only after Save is attempted', (
      tester,
    ) async {
      useTallViewport(tester);
      await tester.pumpWidget(host(onResult: (_) {}));
      await openForm(tester);

      await tester.enterText(
        find.byKey(const Key('customer-email-field')),
        'not-an-email',
      );
      await tester.pump();
      expect(find.text('Enter a valid email address'), findsNothing);

      await tester.tap(find.byKey(const Key('customer-save')));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email address'), findsOneWidget);
      await dismissSnackBar(tester);
    });

    testWidgets(
      'saving a filled form pops a customer with every field captured',
      (tester) async {
        useTallViewport(tester);
        Customer? result;
        await tester.pumpWidget(host(onResult: (r) => result = r));
        await openForm(tester);

        await tester.enterText(
          find.byKey(const Key('customer-name-field')),
          'An Trần',
        );
        await tester.enterText(
          find.byKey(const Key('customer-phone-field')),
          '0987654321',
        );
        await tester.enterText(
          find.byKey(const Key('customer-email-field')),
          'an@shop.vn',
        );
        await tester.enterText(
          find.byKey(const Key('customer-location-field')),
          'Đà Nẵng',
        );
        await tester.enterText(
          find.byKey(const Key('customer-address-field-0')),
          '5 Lê Lợi, Hải Châu',
        );
        await tester.enterText(
          find.byKey(const Key('customer-tags-field')),
          'zalo, bán sỉ',
        );
        await tester.enterText(
          find.byKey(const Key('customer-notes-field')),
          'Giao giờ hành chính',
        );
        // Pick a suggested segment (AC1).
        await tester.tap(find.text('High Value'));
        await tester.pump();

        await tester.tap(find.byKey(const Key('customer-save')));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.id, 'generated-id');
        expect(result!.name, 'An Trần');
        expect(result!.phone, '0987654321');
        expect(result!.email, 'an@shop.vn');
        expect(result!.location, 'Đà Nẵng');
        expect(result!.addresses, ['5 Lê Lợi, Hải Châu']);
        expect(result!.segments, ['High Value']);
        expect(result!.tags, ['zalo', 'bán sỉ']);
        expect(result!.notes, 'Giao giờ hành chính');
        expect(result!.orderCount, 0);
        expect(result!.lastPurchaseDate, isNull);
        expect(result!.history, isEmpty);
      },
    );

    testWidgets('a custom segment can be typed and added', (tester) async {
      useTallViewport(tester);
      Customer? result;
      await tester.pumpWidget(host(onResult: (r) => result = r));
      await openForm(tester);

      await tester.enterText(
        find.byKey(const Key('customer-name-field')),
        'An',
      );
      await tester.enterText(
        find.byKey(const Key('customer-phone-field')),
        '0987654321',
      );
      await tester.enterText(
        find.byKey(const Key('customer-segment-input')),
        'Mối sỉ Đà Nẵng',
      );
      await tester.tap(find.byKey(const Key('customer-segment-add')));
      await tester.pump();
      // The custom segment shows up as a selected chip.
      expect(find.text('Mối sỉ Đà Nẵng'), findsOneWidget);

      await tester.tap(find.byKey(const Key('customer-save')));
      await tester.pumpAndSettle();
      expect(result!.segments, ['Mối sỉ Đà Nẵng']);
    });
  });

  group('multiple addresses (AC2)', () {
    testWidgets('rows can be added and removed; all entries are saved', (
      tester,
    ) async {
      useTallViewport(tester);
      Customer? result;
      await tester.pumpWidget(host(onResult: (r) => result = r));
      await openForm(tester);

      await tester.enterText(
        find.byKey(const Key('customer-name-field')),
        'An',
      );
      await tester.enterText(
        find.byKey(const Key('customer-phone-field')),
        '0987654321',
      );
      await tester.enterText(
        find.byKey(const Key('customer-address-field-0')),
        '12 Hàng Bài',
      );

      // Add a second and third row, fill the second, leave the third blank.
      await tester.tap(find.byKey(const Key('customer-add-address')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('customer-add-address')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('customer-address-field-1')),
        '5 Lê Lợi',
      );

      // Remove the blank third row.
      await tester.tap(find.byKey(const Key('customer-address-remove-2')));
      await tester.pump();
      expect(find.byKey(const Key('customer-address-field-2')), findsNothing);

      await tester.tap(find.byKey(const Key('customer-save')));
      await tester.pumpAndSettle();
      expect(result!.addresses, ['12 Hàng Bài', '5 Lê Lợi']);
    });
  });

  group('duplicate detection (AC5)', () {
    testWidgets('typing a matching phone shows the warning banner', (
      tester,
    ) async {
      useTallViewport(tester);
      final directory = CustomerDirectoryController([existing()]);
      await tester.pumpWidget(
        host(
          findDuplicates: (name, phone) =>
              directory.findDuplicates(name: name, phone: phone),
          onResult: (_) {},
        ),
      );
      await openForm(tester);
      expect(find.byKey(const Key('customer-duplicate-warning')), findsNothing);

      // Same number as the existing customer, domestic format.
      await tester.enterText(
        find.byKey(const Key('customer-phone-field')),
        '0912345678',
      );
      await tester.pump();

      expect(
        find.byKey(const Key('customer-duplicate-warning')),
        findsOneWidget,
      );
      // The banner lists the matching customer with a masked phone (the name
      // field's hint also contains the name, hence the bullet-row match).
      expect(find.textContaining('Phương Nguyễn • '), findsOneWidget);

      // Changing to a unique number clears the warning.
      await tester.enterText(
        find.byKey(const Key('customer-phone-field')),
        '0999999999',
      );
      await tester.pump();
      expect(find.byKey(const Key('customer-duplicate-warning')), findsNothing);
    });
  });

  group('edit mode (AC4)', () {
    testWidgets('prefills fields and records an audit-trail revision on save', (
      tester,
    ) async {
      useTallViewport(tester);
      Customer? result;
      await tester.pumpWidget(
        host(customer: existing(), onResult: (r) => result = r),
      );
      await openForm(tester);

      expect(find.text('Edit Customer'), findsOneWidget);
      expect(find.text('Phương Nguyễn'), findsOneWidget);
      expect(find.text('+84912345678'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('customer-phone-field')),
        '0987654321',
      );
      await tester.pump();
      // Live unsaved-changes preview appears.
      expect(find.textContaining('Unsaved changes'), findsOneWidget);

      await tester.tap(find.byKey(const Key('customer-save')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.phone, '0987654321');
      // Purchase stats are not form-editable and survive the edit.
      expect(result!.orderCount, 3);
      expect(result!.totalSpent, 5000000);
      expect(result!.lastPurchaseDate, DateTime(2026, 7, 1));
      // The audit trail recorded exactly this change.
      expect(result!.history, hasLength(1));
      expect(result!.history.first.timestamp, DateTime(2026, 7, 22, 12));
      expect(result!.history.first.changes.single.before, '+84912345678');
      expect(result!.history.first.changes.single.after, '0987654321');
    });

    testWidgets('a revision from a previous edit is listed on screen', (
      tester,
    ) async {
      useTallViewport(tester);
      final edited = existing().copyWith(
        history: [
          // A previous phone change, as CustomerEditor would record it.
          CustomerRevision(
            timestamp: DateTime(2026, 7, 15),
            changes: const [
              CustomerFieldChange(
                field: CustomerField.phone,
                before: '+84911111111',
                after: '+84912345678',
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(host(customer: edited, onResult: (_) {}));
      await openForm(tester);

      expect(find.text('Change history'), findsOneWidget);
      expect(find.textContaining('Phone:'), findsOneWidget);
    });

    testWidgets('saving without changes pops the original untouched', (
      tester,
    ) async {
      useTallViewport(tester);
      Customer? result;
      final original = existing();
      await tester.pumpWidget(
        host(customer: original, onResult: (r) => result = r),
      );
      await openForm(tester);

      await tester.tap(find.byKey(const Key('customer-save')));
      await tester.pumpAndSettle();

      expect(identical(result, original), isTrue);
      expect(result!.history, isEmpty);
    });
  });

  group('list screen wiring (WTM-76 on WTM-75)', () {
    testWidgets('the FAB opens the Add Customer form', (tester) async {
      useTallViewport(tester);
      final directory = CustomerDirectoryController([existing()]);
      await tester.pumpWidget(
        MaterialApp(home: TongtaiCustomerListScreen(directory: directory)),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(FloatingActionButton, 'Add customer'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TongtaiCustomerFormScreen), findsOneWidget);
      expect(find.text('Add Customer'), findsOneWidget);
    });

    testWidgets('adding a customer through the form lands it in the list', (
      tester,
    ) async {
      useTallViewport(tester);
      final directory = CustomerDirectoryController([existing()]);
      await tester.pumpWidget(
        MaterialApp(home: TongtaiCustomerListScreen(directory: directory)),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(FloatingActionButton, 'Add customer'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('customer-name-field')),
        'Khách Mới',
      );
      await tester.enterText(
        find.byKey(const Key('customer-phone-field')),
        '0987000111',
      );
      await tester.tap(find.byKey(const Key('customer-save')));
      await tester.pumpAndSettle();

      expect(directory.count, 2);
      expect(find.text('Khách Mới'), findsOneWidget);
      expect(find.text('2 customers'), findsOneWidget);
      // A brand-new customer has no purchases yet.
      expect(find.text('No purchases yet'), findsOneWidget);
    });

    testWidgets('tapping a row opens the form in Edit mode, save updates it', (
      tester,
    ) async {
      useTallViewport(tester);
      final directory = CustomerDirectoryController([existing()]);
      await tester.pumpWidget(
        MaterialApp(home: TongtaiCustomerListScreen(directory: directory)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Phương Nguyễn'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Customer'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('customer-name-field')),
        'Phương N. (VIP)',
      );
      await tester.tap(find.byKey(const Key('customer-save')));
      await tester.pumpAndSettle();

      expect(directory.count, 1);
      expect(find.text('Phương N. (VIP)'), findsOneWidget);
      expect(directory.customers.single.history, hasLength(1));
    });
  });
}
