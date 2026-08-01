import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/finance/finance_category.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_history.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/export/backup_codec.dart';
import 'package:tongtai/features/tongtai/finance/finance_transaction.dart';
import 'package:tongtai/features/tongtai/inventory/product.dart';
import 'package:tongtai/features/tongtai/inventory/product_history.dart';
import 'package:tongtai/features/tongtai/journey/business_goal.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/producer/supplier_favorite.dart';

/// WTM-164 — the codec layer alone: **every field survives**, including the
/// ones the Drift repositories currently choose not to persist (edit history).
///
/// Separated from `backup_restore_test.dart` on purpose. That suite measures
/// what the *database* keeps; this one measures what the *format* keeps. If
/// history ever becomes persisted, the format is already ready and this test
/// is what says so.
void main() {
  test('customer round-trips, edit history included', () {
    final original = Customer(
      id: 'c1',
      name: 'Chị Lan',
      phone: '0901234567',
      location: 'Hà Nội',
      orderCount: 3,
      totalSpent: 1500000.5,
      lastPurchaseDate: DateTime(2026, 7, 20, 9, 30),
      email: 'lan@example.com',
      addresses: const ['12 Hàng Bông'],
      segments: const ['khách quen'],
      tags: const ['vip'],
      notes: 'Giao buổi sáng',
      history: [
        CustomerRevision(
          timestamp: DateTime(2026, 7, 1, 8, 30),
          changes: const [
            CustomerFieldChange(
              field: CustomerField.phone,
              before: '0900000000',
              after: '0901234567',
            ),
          ],
        ),
      ],
    );

    final decoded = BackupCodec.decodeCustomer(
      BackupCodec.encodeCustomer(original),
    )!;

    expect(decoded.id, original.id);
    expect(decoded.name, original.name);
    expect(decoded.phone, original.phone);
    expect(decoded.email, original.email);
    expect(decoded.location, original.location);
    expect(decoded.addresses, original.addresses);
    expect(decoded.segments, original.segments);
    expect(decoded.tags, original.tags);
    expect(decoded.notes, original.notes);
    expect(decoded.orderCount, original.orderCount);
    expect(decoded.totalSpent, original.totalSpent);
    expect(decoded.lastPurchaseDate, original.lastPurchaseDate);
    expect(decoded.history, original.history);
  });

  test('a customer with no last purchase keeps its null', () {
    final original = Customer(
      id: 'c2',
      name: 'Khách mới',
      phone: '',
      location: '',
      orderCount: 0,
      totalSpent: 0,
      lastPurchaseDate: null,
    );
    final decoded = BackupCodec.decodeCustomer(
      BackupCodec.encodeCustomer(original),
    )!;
    expect(decoded.lastPurchaseDate, isNull);
  });

  test('product round-trips, images and history included', () {
    final original = Product(
      id: 'p1',
      sku: 'SKU-1',
      name: 'Cà phê',
      category: 'Đồ uống',
      quantity: 12,
      pricePerUnit: 85000.5,
      reorderLevel: 5,
      updatedAt: DateTime(2026, 7, 25, 10),
      description: 'Rang mộc',
      imagePaths: const ['/images/p1.jpg', '/images/p1b.jpg'],
      history: [
        ProductRevision(
          timestamp: DateTime(2026, 7, 2, 9),
          changes: const [
            ProductFieldChange(
              field: ProductField.quantity,
              before: '10',
              after: '12',
            ),
          ],
        ),
      ],
    );

    final decoded = BackupCodec.decodeProduct(
      BackupCodec.encodeProduct(original),
    )!;

    expect(decoded.sku, original.sku);
    expect(decoded.description, original.description);
    expect(decoded.imagePaths, original.imagePaths);
    expect(decoded.pricePerUnit, original.pricePerUnit);
    expect(decoded.reorderLevel, original.reorderLevel);
    expect(decoded.updatedAt, original.updatedAt);
    expect(decoded.history, original.history);
  });

  test('order round-trips with the two fields v1 CSV threw away', () {
    final original = CustomerOrder(
      id: 'o1',
      customerId: 'c1',
      orderNumber: 'DH-2026-0001',
      date: DateTime(2026, 7, 22, 14, 5),
      status: OrderStatus.shipped,
      items: const [
        OrderItem(
          productId: 'p1',
          productName: 'Cà phê',
          sku: 'SKU-1',
          category: 'Đồ uống',
          unit: 'gói',
          quantity: 3,
          unitPrice: 85000.5,
        ),
      ],
    );

    final encoded = BackupCodec.encodeOrder(original);
    expect(encoded['id'], 'o1', reason: 'v1 CSV had no order id at all');
    expect(
      (encoded['items'] as List).first,
      containsPair('productId', 'p1'),
      reason: 'without this the Inventory↔Orders link cannot be rebuilt',
    );
    expect(
      encoded['status'],
      'shipped',
      reason: 'canonical code, never the Vietnamese label',
    );

    final decoded = BackupCodec.decodeOrder(encoded)!;
    expect(decoded.id, original.id);
    expect(decoded.customerId, original.customerId);
    expect(decoded.orderNumber, original.orderNumber);
    expect(decoded.date, original.date);
    expect(decoded.status, original.status);
    expect(decoded.items.single.productId, 'p1');
    expect(decoded.items.single.sku, 'SKU-1');
    expect(decoded.items.single.unit, 'gói');
    expect(decoded.items.single.unitPrice, 85000.5);
  });

  test('goal and transaction round-trip with canonical enum codes', () {
    final goal = BusinessGoal(
      id: 'g1',
      name: 'Doanh thu',
      type: GoalType.customerGrowth,
      targetAmount: 5000000,
      achievedAmount: 1200000.25,
      growthTarget: 20,
      growthAchieved: 5,
      startDate: DateTime(2026, 8),
      endDate: DateTime(2026, 8, 31),
      notes: 'Kênh online',
      createdAt: DateTime(2026, 7, 28),
      updatedAt: DateTime(2026, 7, 30),
    );
    expect(BackupCodec.encodeGoal(goal)['type'], 'customerGrowth');
    final decodedGoal = BackupCodec.decodeGoal(BackupCodec.encodeGoal(goal))!;
    expect(decodedGoal.type, GoalType.customerGrowth);
    expect(decodedGoal.achievedAmount, 1200000.25);
    expect(decodedGoal.notes, 'Kênh online');
    expect(decodedGoal.createdAt, goal.createdAt);

    final txn = FinanceTransaction(
      id: 't1',
      type: TransactionType.income,
      category: FinanceCategory.sales,
      amount: 2500000.75,
      date: DateTime(2026, 7, 26),
      description: 'Đơn lẻ',
      paymentMethod: 'Tiền mặt',
    );
    expect(BackupCodec.encodeTransaction(txn)['type'], 'income');
    final decodedTxn = BackupCodec.decodeTransaction(
      BackupCodec.encodeTransaction(txn),
    )!;
    expect(decodedTxn.type, TransactionType.income);
    expect(decodedTxn.amount, 2500000.75);
    expect(decodedTxn.paymentMethod, 'Tiền mặt');
  });

  test('favourite round-trips', () {
    final original = SupplierFavorite(
      supplierId: 'sup-1',
      addedAt: DateTime(2026, 7, 10, 11, 22),
    );
    final decoded = BackupCodec.decodeFavourite(
      BackupCodec.encodeFavourite(original),
    )!;
    expect(decoded.supplierId, original.supplierId);
    expect(decoded.addedAt, original.addedAt);
  });

  group('decoding refuses rather than guessing', () {
    test('an unknown enum code is rejected, not defaulted', () {
      expect(
        BackupCodec.decodeOrder({
          'id': 'o1',
          'customerId': 'c1',
          'orderNumber': 'DH-1',
          'date': '2026-07-22T00:00:00.000Z',
          'status': 'teleported',
          'items': const [],
        }),
        isNull,
        reason:
            'OrderStatus.fromStorage defaults unknown values to pending — a '
            'backup must NOT: silently changing a delivered order to pending '
            'is data loss wearing a default',
      );
    });

    test('a missing required field is rejected', () {
      expect(
        BackupCodec.decodeCustomer(const {'id': 'c1', 'name': 'Lan'}),
        isNull,
      );
    });

    test('an empty id is rejected', () {
      expect(
        BackupCodec.decodeGoal({
          'id': '',
          'name': 'x',
          'type': 'revenue',
          'targetAmount': 1,
          'achievedAmount': 0,
          'growthTarget': 0,
          'growthAchieved': 0,
          'startDate': '2026-08-01T00:00:00.000Z',
          'endDate': '2026-08-31T00:00:00.000Z',
          'notes': '',
          'createdAt': '2026-07-28T00:00:00.000Z',
          'updatedAt': '2026-07-30T00:00:00.000Z',
        }),
        isNull,
      );
    });

    test('a wrong-typed field is rejected', () {
      expect(
        BackupCodec.decodeFavourite(const {
          'supplierId': 'sup-1',
          'addedAt': 12345,
        }),
        isNull,
      );
    });
  });
}
