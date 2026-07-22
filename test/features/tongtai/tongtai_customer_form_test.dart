import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_directory_controller.dart';
import 'package:tongtai/features/tongtai/consumer/customer_form.dart';
import 'package:tongtai/features/tongtai/consumer/customer_history.dart';

/// Unit tests for the WTM-76 Add/Edit Customer domain layer:
///  - AC1: form validation (required name/phone, phone + email format)
///  - AC2: multiple address entries (blank rows dropped, order kept)
///  - AC3: notes + tags survive the form -> customer conversion
///  - AC4: CustomerEditor records a full audit trail on edit
///  - AC5: duplicate detection by normalized phone / case-insensitive name
void main() {
  Customer sample({
    String id = 'c1',
    String name = 'Phương Nguyễn',
    String phone = '+84912345678',
  }) => Customer(
    id: id,
    name: name,
    phone: phone,
    location: 'Hà Nội',
    orderCount: 3,
    totalSpent: 5000000,
    lastPurchaseDate: DateTime(2026, 7, 1),
    email: 'phuong@example.com',
    addresses: const ['12 Hàng Bài, Hoàn Kiếm'],
    segments: const ['Loyal Customers'],
    tags: const ['tiktok'],
    notes: 'Prefers COD',
  );

  group('CustomerFormData.validate (AC1)', () {
    test('empty form fails on the two required fields only', () {
      const data = CustomerFormData();
      final errors = data.validate();
      expect(
        errors.keys,
        containsAll([CustomerField.name, CustomerField.phone]),
      );
      expect(errors.length, 2);
      expect(data.isValid, isFalse);
    });

    test('name + valid phone is enough (everything else optional)', () {
      const data = CustomerFormData(name: 'An', phone: '0912345678');
      expect(data.validate(), isEmpty);
      expect(data.isValid, isTrue);
    });

    test('rejects a phone with letters or too few digits', () {
      const letters = CustomerFormData(name: 'An', phone: 'not-a-phone');
      expect(letters.validate()[CustomerField.phone], isNotNull);

      const short = CustomerFormData(name: 'An', phone: '0912');
      expect(short.validate()[CustomerField.phone], isNotNull);
    });

    test('accepts spaced/dashed phone formats', () {
      const data = CustomerFormData(name: 'An', phone: '+84 912-345-678');
      expect(data.validate(), isEmpty);
    });

    test('email is optional but must be well-formed when present', () {
      const blank = CustomerFormData(name: 'An', phone: '0912345678');
      expect(blank.validate(), isEmpty);

      const bad = CustomerFormData(
        name: 'An',
        phone: '0912345678',
        email: 'not-an-email',
      );
      expect(bad.validate()[CustomerField.email], isNotNull);

      const good = CustomerFormData(
        name: 'An',
        phone: '0912345678',
        email: 'an@shop.vn',
      );
      expect(good.validate(), isEmpty);
    });
  });

  group('multiple addresses (AC2)', () {
    test('cleanedAddresses drops blank rows and trims, keeping order', () {
      const data = CustomerFormData(
        addresses: ['  12 Hàng Bài ', '', '   ', '5 Lê Lợi'],
      );
      expect(data.cleanedAddresses, ['12 Hàng Bài', '5 Lê Lợi']);
    });

    test('toCustomer persists every non-blank address', () {
      const data = CustomerFormData(
        name: 'An',
        phone: '0912345678',
        addresses: ['12 Hàng Bài', '5 Lê Lợi', ''],
      );
      final customer = data.toCustomer(id: 'x');
      expect(customer.addresses, ['12 Hàng Bài', '5 Lê Lợi']);
    });
  });

  group('form <-> customer conversion (AC1/AC3)', () {
    test('fromCustomer seeds every editable field', () {
      final data = CustomerFormData.fromCustomer(sample());
      expect(data.name, 'Phương Nguyễn');
      expect(data.phone, '+84912345678');
      expect(data.email, 'phuong@example.com');
      expect(data.location, 'Hà Nội');
      expect(data.addresses, ['12 Hàng Bài, Hoàn Kiếm']);
      expect(data.segments, ['Loyal Customers']);
      expect(data.tags, ['tiktok']);
      expect(data.notes, 'Prefers COD');
    });

    test('toCustomer trims text fields and keeps notes/tags/segments', () {
      const data = CustomerFormData(
        name: '  An Trần ',
        phone: ' 0912345678 ',
        email: ' an@shop.vn ',
        location: ' Đà Nẵng ',
        segments: ['High Value'],
        tags: ['sỉ', 'zalo'],
        notes: '  Gọi trước khi giao  ',
      );
      final customer = data.toCustomer(id: 'x');
      expect(customer.name, 'An Trần');
      expect(customer.phone, '0912345678');
      expect(customer.email, 'an@shop.vn');
      expect(customer.location, 'Đà Nẵng');
      expect(customer.segments, ['High Value']);
      expect(customer.tags, ['sỉ', 'zalo']);
      expect(customer.notes, 'Gọi trước khi giao');
    });
  });

  group('CustomerEditor (AC4 — audit trail)', () {
    test('create starts with zero stats, no purchase date, empty history', () {
      const data = CustomerFormData(name: 'An', phone: '0912345678');
      final customer = CustomerEditor.create(data, id: 'new-1');
      expect(customer.id, 'new-1');
      expect(customer.orderCount, 0);
      expect(customer.totalSpent, 0);
      expect(customer.lastPurchaseDate, isNull);
      expect(customer.history, isEmpty);
    });

    test('applyEdit records one revision with every changed field', () {
      final original = sample();
      final data = CustomerFormData.fromCustomer(original).copyWith(
        phone: '0987654321',
        addresses: ['12 Hàng Bài, Hoàn Kiếm', '5 Lê Lợi, Q1'],
      );
      final now = DateTime(2026, 7, 22, 10);

      final edited = CustomerEditor.applyEdit(original, data, now: now);

      expect(edited.history, hasLength(1));
      final revision = edited.history.first;
      expect(revision.timestamp, now);
      expect(revision.changes, hasLength(2));
      expect(
        revision.changes,
        contains(
          const CustomerFieldChange(
            field: CustomerField.phone,
            before: '+84912345678',
            after: '0987654321',
          ),
        ),
      );
      expect(
        revision.changes,
        contains(
          const CustomerFieldChange(
            field: CustomerField.addresses,
            before: '12 Hàng Bài, Hoàn Kiếm',
            after: '12 Hàng Bài, Hoàn Kiếm | 5 Lê Lợi, Q1',
          ),
        ),
      );
    });

    test('applyEdit preserves purchase stats and prepends to history', () {
      final original = sample();
      final first = CustomerEditor.applyEdit(
        original,
        CustomerFormData.fromCustomer(original).copyWith(name: 'Phương N.'),
        now: DateTime(2026, 7, 20),
      );
      final second = CustomerEditor.applyEdit(
        first,
        CustomerFormData.fromCustomer(first).copyWith(notes: 'VIP'),
        now: DateTime(2026, 7, 21),
      );

      expect(second.orderCount, original.orderCount);
      expect(second.totalSpent, original.totalSpent);
      expect(second.lastPurchaseDate, original.lastPurchaseDate);
      expect(second.history, hasLength(2));
      // Newest first.
      expect(second.history.first.timestamp, DateTime(2026, 7, 21));
      expect(second.history.last.timestamp, DateTime(2026, 7, 20));
    });

    test(
      'applyEdit with no changes returns the original — no phantom revision',
      () {
        final original = sample();
        final unchanged = CustomerEditor.applyEdit(
          original,
          CustomerFormData.fromCustomer(original),
          now: DateTime(2026, 7, 22),
        );
        expect(identical(unchanged, original), isTrue);
        expect(unchanged.history, isEmpty);
      },
    );
  });

  group('duplicate detection (AC5)', () {
    test('normalizeCustomerPhone equates +84 / 84 / 0 prefixes', () {
      expect(normalizeCustomerPhone('+84 912 345 678'), '912345678');
      expect(normalizeCustomerPhone('84912345678'), '912345678');
      expect(normalizeCustomerPhone('0912345678'), '912345678');
      expect(normalizeCustomerPhone('0912-345-678'), '912345678');
    });

    test('matches an existing customer by phone in a different format', () {
      final all = [sample()]; // stored as +84912345678
      final hits = findCustomerDuplicates(
        all,
        name: 'Someone Else',
        phone: '0912345678',
      );
      expect(hits.map((c) => c.id), ['c1']);
    });

    test('matches by name case-insensitively', () {
      final all = [sample()];
      final hits = findCustomerDuplicates(
        all,
        name: '  phương nguyễn ',
        phone: '',
      );
      expect(hits.map((c) => c.id), ['c1']);
    });

    test('excludes the customer being edited (exceptId)', () {
      final all = [sample()];
      final hits = findCustomerDuplicates(
        all,
        name: 'Phương Nguyễn',
        phone: '+84912345678',
        exceptId: 'c1',
      );
      expect(hits, isEmpty);
    });

    test('blank name + phone never match anything', () {
      final all = [sample()];
      expect(findCustomerDuplicates(all, name: '', phone: ''), isEmpty);
      expect(findCustomerDuplicates(all, name: '   ', phone: ' - '), isEmpty);
    });
  });

  group('CustomerDirectoryController', () {
    test('upsert appends a new customer and notifies', () {
      final controller = CustomerDirectoryController([sample()]);
      var notified = 0;
      controller.addListener(() => notified++);

      final replaced = controller.upsert(sample(id: 'c2', name: 'Mai'));

      expect(replaced, isFalse);
      expect(controller.count, 2);
      expect(notified, 1);
      expect(controller.service.all.map((c) => c.id), ['c1', 'c2']);
    });

    test('upsert replaces an existing customer by id', () {
      final controller = CustomerDirectoryController([sample()]);
      final replaced = controller.upsert(sample(name: 'Phương (updated)'));
      expect(replaced, isTrue);
      expect(controller.count, 1);
      expect(controller.customers.single.name, 'Phương (updated)');
    });

    test('findDuplicates delegates with exceptId', () {
      final controller = CustomerDirectoryController([sample()]);
      expect(
        controller.findDuplicates(name: '', phone: '0912345678'),
        hasLength(1),
      );
      expect(
        controller.findDuplicates(
          name: '',
          phone: '0912345678',
          exceptId: 'c1',
        ),
        isEmpty,
      );
    });
  });
}
