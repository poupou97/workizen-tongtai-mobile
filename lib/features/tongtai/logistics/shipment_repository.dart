import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../core/local_workspace.dart';
import '../core/provenance.dart';
import 'shipment.dart';

/// Kho chuyến giao hàng — WTM-323.
class ShipmentRepository {
  ShipmentRepository(this._db, {this.workspace = const LocalWorkspace()});

  final AppDatabase _db;
  final LocalWorkspace workspace;

  Future<List<Shipment>> loadAll() async {
    final businessId = await workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.shipmentsTable)
              ..where((t) => t.businessId.equals(businessId))
              ..orderBy([(t) => OrderingTerm.desc(t.lastUpdate)]))
            .get();
    return rows.map(_toShipment).nonNulls.toList();
  }

  Future<void> upsertAll(Iterable<Shipment> shipments) async {
    final rows = shipments.toList(growable: false);
    if (rows.isEmpty) return;
    final businessId = await workspace.ensureBusinessId(_db);
    await _db.batch((batch) {
      for (final s in rows) {
        batch.insert(
          _db.shipmentsTable,
          ShipmentsTableCompanion.insert(
            id: s.id,
            businessId: businessId,
            orderId: Value(s.orderId),
            trackingNumber: s.trackingNumber,
            carrier: Value(s.carrier?.code),
            status: s.status.code,
            lastUpdate: Value(s.lastUpdate),
            eta: Value(s.eta),
            origin: Value(s.origin),
            destination: Value(s.destination),
            notes: Value(s.notes),
            externalId: Value(s.externalId),
            provenanceCode: Value(s.provenance.code),
            importJobId: Value(s.importJobId),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// **Phạm vi: đúng một lần nhập** — cùng kỷ luật `CommerceRepository`.
  Future<int> deleteImport(String importJobId) async {
    final businessId = await workspace.ensureBusinessId(_db);
    return (_db.delete(_db.shipmentsTable)..where(
          (t) =>
              t.businessId.equals(businessId) &
              t.importJobId.equals(importJobId),
        ))
        .go();
  }

  /// **Phạm vi: mọi chuyến.** Chỉ dùng cho restore Replace.
  Future<void> deleteAll() async {
    final businessId = await workspace.ensureBusinessId(_db);
    await (_db.delete(
      _db.shipmentsTable,
    )..where((t) => t.businessId.equals(businessId))).go();
  }

  /// Mã trạng thái lạ ⇒ **bỏ dòng**. Rơi về "đang giao" sẽ khiến một kiện đã
  /// hoàn về kho trông như đang trên đường tới khách — và không ai đi tìm nó.
  Shipment? _toShipment(ShipmentsTableData row) {
    final status = ShipmentStatus.fromCode(row.status);
    if (status == null) return null;
    return Shipment(
      id: row.id,
      orderId: row.orderId,
      trackingNumber: row.trackingNumber,
      carrier: Carrier.fromCode(row.carrier),
      status: status,
      lastUpdate: row.lastUpdate,
      eta: row.eta,
      origin: row.origin,
      destination: row.destination,
      notes: row.notes,
      externalId: row.externalId,
      provenance:
          ProvenanceSource.fromCode(row.provenanceCode) ??
          ProvenanceSource.manual,
      importJobId: row.importJobId,
    );
  }
}
