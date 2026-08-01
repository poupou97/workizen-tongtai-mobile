import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/database/database.dart';
import 'package:tongtai/features/tongtai/consumer/customer.dart';
import 'package:tongtai/features/tongtai/consumer/customer_repository.dart';
import 'package:tongtai/features/tongtai/core/tongtai_enums.dart';
import 'package:tongtai/features/tongtai/export/backup_codec.dart';
import 'package:tongtai/features/tongtai/orders/order.dart';
import 'package:tongtai/features/tongtai/orders/order_repository.dart';
import 'package:tongtai/features/tongtai/profile/business_profile.dart';
import 'package:tongtai/features/tongtai/reports/business_report.dart';

/// WTM-209 — the sales channel reaches the domain, self-recorded (D-5).
///
/// `channelId` sat in the schema since v1 with nothing wiring it — the second
/// of three such columns (`costPrice` WTM-204, `paymentStatus` WTM-211).
/// The vocabulary is the profile's own [SalesChannel], so an order cannot
/// claim a channel the app does not know.
void main() {
  CustomerOrder order(
    String id, {
    SalesChannel? channel,
    String? paymentStatus,
    double amount = 1000000,
  }) => CustomerOrder(
    id: id,
    customerId: 'c1',
    orderNumber: 'DH-$id',
    date: DateTime(2026, 7, 10),
    status: OrderStatus.delivered,
    channel: channel,
    paymentStatus: paymentStatus,
    items: [
      OrderItem(
        productName: 'SP',
        category: 'Home',
        quantity: 1,
        unitPrice: amount,
      ),
    ],
  );

  test('channel and payment status survive closing and reopening', () async {
    final dir = await Directory.systemTemp.createTemp('tongtai_channel');
    final file = File('${dir.path}/t.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    var db = AppDatabase.forExecutor(NativeDatabase(file));
    await DriftCustomerRepository(db).upsert(
      const Customer(
        id: 'c1',
        name: 'Khách',
        phone: '09',
        location: 'HN',
        orderCount: 0,
        totalSpent: 0,
        lastPurchaseDate: null,
      ),
    );
    await DriftOrderRepository(db).upsertAll([
      order('o1', channel: SalesChannel.shopee, paymentStatus: kPaymentUnpaid),
      order('o2'),
    ]);
    await db.close();

    db = AppDatabase.forExecutor(NativeDatabase(file));
    final loaded = await DriftOrderRepository(db).loadAll();
    await db.close();

    final o1 = loaded.singleWhere((o) => o.id == 'o1');
    final o2 = loaded.singleWhere((o) => o.id == 'o2');
    expect(o1.channel, SalesChannel.shopee);
    expect(o1.paymentStatus, kPaymentUnpaid);
    expect(o2.channel, isNull, reason: 'not recorded stays not recorded');
  });

  group('.ttbk', () {
    test('carries channel AND payment status', () {
      // The second half is the hole this story found: WTM-211 wired
      // `paymentStatus` into the domain but not into this codec, so a backup →
      // restore would have silently erased the seller's receivables.
      final decoded = BackupCodec.decodeOrder(
        BackupCodec.encodeOrder(
          order(
            'o1',
            channel: SalesChannel.tiktok,
            paymentStatus: kPaymentPartial,
          ),
        ),
      );

      expect(decoded!.channel, SalesChannel.tiktok);
      expect(decoded.paymentStatus, kPaymentPartial);
    });

    test('a file from an older build restores with both null', () {
      final json = BackupCodec.encodeOrder(order('o1'))
        ..remove('channel')
        ..remove('paymentStatus');

      final decoded = BackupCodec.decodeOrder(json);

      expect(decoded, isNotNull);
      expect(decoded!.channel, isNull);
      expect(decoded.paymentStatus, isNull);
    });

    test('an unknown channel code becomes null, never a guess', () {
      // A .ttbk written by a NEWER build may know channels this build does
      // not. Guessing would put the revenue in the wrong bucket; null keeps
      // the money in the total and out of the breakdown.
      final json = BackupCodec.encodeOrder(order('o1'))..['channel'] = 'temu';

      expect(BackupCodec.decodeOrder(json)!.channel, isNull);
    });
  });

  group('revenue by channel (Reports)', () {
    test('groups by recorded channel, highest first', () {
      final breakdown = ReportsService([
        order('a', channel: SalesChannel.shopee, amount: 3000000),
        order('b', channel: SalesChannel.shopee, amount: 2000000),
        order('c', channel: SalesChannel.tiktok, amount: 1000000),
      ]).breakdownForRange(DateTime(2026, 7, 1), DateTime(2026, 7, 31));

      expect(breakdown.channelRevenue, hasLength(2));
      expect(breakdown.channelRevenue.first.channel, SalesChannel.shopee);
      expect(breakdown.channelRevenue.first.revenue, 5000000);
      expect(breakdown.channelRevenue.first.orders, 2);
    });

    test('unrecorded orders stay in the total but out of the breakdown', () {
      // Inventing a bucket for them would fabricate a breakdown the seller
      // never gave — while dropping them from the total would lose money.
      final breakdown = ReportsService([
        order('a', channel: SalesChannel.shopee, amount: 3000000),
        order('b', amount: 2000000),
      ]).breakdownForRange(DateTime(2026, 7, 1), DateTime(2026, 7, 31));

      expect(breakdown.revenue, 5000000);
      expect(breakdown.channelRevenue, hasLength(1));
    });

    test('no recorded channels means an empty list — the section hides', () {
      final breakdown = ReportsService([
        order('a', amount: 3000000),
      ]).breakdownForRange(DateTime(2026, 7, 1), DateTime(2026, 7, 31));

      expect(breakdown.channelRevenue, isEmpty);
    });
  });
}
