import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../core/local_workspace.dart';
import 'external_identity.dart';

/// Đường ghi/đọc danh tính ngoài (WTM-291 · N0.3 · ADR-TON-024).
///
/// ## ⭐ Luật 4 nằm ở ĐÂY, và nó là hình dạng của API
///
/// ADR-TON-024 cấm **tự động gộp bản ghi khách** ở mọi mức tin cậy. Một nội
/// quy viết trong tài liệu sẽ bị vi phạm ngày đầu tiên có người thấy tiện.
///
/// Nên seam này được thiết kế sao cho việc đó **không viết ra được**: đọc hết
/// các hàm dưới đây, **không hàm nào nhận hai `customerId` và trả về một**.
/// Cái không tồn tại thì không gọi nhầm được, và một test governance quét
/// đúng tính chất đó (`identity_no_auto_merge_test`).
///
/// Thứ seam này làm được là **liên kết** — trỏ một danh tính ngoài về một
/// khách đã có, và gỡ ra khi sai. Liên kết sai sửa mất 5 giây; gộp sai thì hai
/// người thật đã bị nhập làm một và đơn hàng đã đổi chủ.
abstract class ExternalIdentityRepository {
  /// Mọi danh tính của một khách — "khách này đến từ những đâu".
  Future<List<ExternalIdentity>> loadForCustomer(String customerId);

  /// Tra một danh tính cụ thể.
  ///
  /// [connectionId] **bắt buộc**: cùng `externalId` ở hai tài khoản Shopee
  /// khác nhau là hai người khác nhau.
  Future<ExternalIdentity?> find({
    required String platform,
    required String externalId,
    required String connectionId,
  });

  /// Mọi danh tính do một kết nối mang về — dùng khi người bán gỡ kết nối và
  /// muốn xem trước những gì sẽ mất.
  Future<List<ExternalIdentity>> loadForConnection(String connectionId);

  /// Gắn một danh tính vào một khách **đã có**, và ghi lịch sử cùng lúc.
  ///
  /// [actor] là `IdentityLinkEvent.actorSeller` hoặc
  /// `IdentityLinkEvent.actorRule(<tên>)` — bắt buộc, không mặc định: một
  /// liên kết không biết ai tạo là một liên kết không gỡ hàng loạt được.
  Future<void> link(ExternalIdentity identity, {required String actor});

  /// Gỡ liên kết. Xoá dòng danh tính, **giữ nguyên lịch sử** — đó là lý do
  /// lịch sử không có khoá ngoại tới bảng danh tính.
  Future<void> unlink(String identityId, {required String actor});

  /// Chuyển một danh tính sang khách khác — sửa một liên kết sai.
  ///
  /// ⚠️ Đây **không phải** gộp: một danh tính đổi chủ, không bản ghi khách nào
  /// biến mất. Khách cũ vẫn còn nguyên với đơn hàng của mình.
  Future<void> moveToCustomer(
    String identityId, {
    required String toCustomerId,
    required String actor,
  });

  /// Lịch sử của một danh tính, mới nhất trước.
  Future<List<IdentityLinkEvent>> historyFor(String identityId);

  /// Mọi thứ một luật đã gắn — đầu vào của việc gỡ hàng loạt khi luật sai.
  Future<List<IdentityLinkEvent>> eventsByActor(String actor);

  /// Xoá mọi bản ghi của doanh nghiệp này (WTM-164 restore Replace).
  Future<void> deleteAll();
}

/// Bản Drift, bền vững trên máy.
class DriftExternalIdentityRepository implements ExternalIdentityRepository {
  DriftExternalIdentityRepository(
    this._db, {
    this._workspace = const LocalWorkspace(),
    required this._now,
    required this._newId,
  });

  final AppDatabase _db;
  final LocalWorkspace _workspace;

  /// Đồng hồ và bộ sinh id tiêm từ ngoài — lịch sử phải kiểm chứng được trong
  /// test, mà `DateTime.now()` trong thân hàm thì không.
  final DateTime Function() _now;
  final String Function() _newId;

  @override
  Future<List<ExternalIdentity>> loadForCustomer(String customerId) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.externalIdentitiesTable)
              ..where(
                (t) =>
                    t.businessId.equals(businessId) &
                    t.customerId.equals(customerId),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.linkedAt)]))
            .get();
    return rows.map(_toIdentity).nonNulls.toList();
  }

  @override
  Future<ExternalIdentity?> find({
    required String platform,
    required String externalId,
    required String connectionId,
  }) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final row =
        await (_db.select(_db.externalIdentitiesTable)..where(
              (t) =>
                  t.businessId.equals(businessId) &
                  t.platform.equals(platform) &
                  t.externalId.equals(externalId) &
                  t.connectionId.equals(connectionId),
            ))
            .getSingleOrNull();
    return row == null ? null : _toIdentity(row);
  }

  @override
  Future<List<ExternalIdentity>> loadForConnection(String connectionId) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.externalIdentitiesTable)..where(
              (t) =>
                  t.businessId.equals(businessId) &
                  t.connectionId.equals(connectionId),
            ))
            .get();
    return rows.map(_toIdentity).nonNulls.toList();
  }

  @override
  Future<void> link(ExternalIdentity identity, {required String actor}) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    // Một giao dịch: liên kết và bằng chứng của nó cùng sống hoặc cùng chết.
    // Tách ra thì một lần crash giữa chừng sinh ra liên kết không lịch sử —
    // đúng thứ không gỡ hàng loạt được về sau.
    await _db.transaction(() async {
      await _db
          .into(_db.externalIdentitiesTable)
          .insertOnConflictUpdate(_companion(identity, businessId));
      await _writeEvent(
        businessId: businessId,
        identityId: identity.id,
        action: IdentityLinkAction.linked,
        actor: actor,
        toCustomerId: identity.customerId,
        confidence: identity.confidence,
      );
    });
  }

  @override
  Future<void> unlink(String identityId, {required String actor}) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await _db.transaction(() async {
      final row =
          await (_db.select(_db.externalIdentitiesTable)..where(
                (t) =>
                    t.businessId.equals(businessId) & t.id.equals(identityId),
              ))
              .getSingleOrNull();
      if (row == null) return;
      await (_db.delete(_db.externalIdentitiesTable)..where(
            (t) => t.businessId.equals(businessId) & t.id.equals(identityId),
          ))
          .go();
      await _writeEvent(
        businessId: businessId,
        identityId: identityId,
        action: IdentityLinkAction.unlinked,
        actor: actor,
        fromCustomerId: row.customerId,
      );
    });
  }

  @override
  Future<void> moveToCustomer(
    String identityId, {
    required String toCustomerId,
    required String actor,
  }) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await _db.transaction(() async {
      final row =
          await (_db.select(_db.externalIdentitiesTable)..where(
                (t) =>
                    t.businessId.equals(businessId) & t.id.equals(identityId),
              ))
              .getSingleOrNull();
      if (row == null) return;
      if (row.customerId == toCustomerId) return;
      await (_db.update(_db.externalIdentitiesTable)..where(
            (t) => t.businessId.equals(businessId) & t.id.equals(identityId),
          ))
          .write(
            ExternalIdentitiesTableCompanion(
              customerId: Value(toCustomerId),
              // Người bán sửa tay thì liên kết trở thành thủ công, và thủ công
              // thắng mọi luật tự động (`outranksAutomation`). Không giữ
              // `automatic` ở đây: luật vừa bị sửa mà vẫn ghi là luật làm thì
              // lần chạy sau nó ghi đè lại đúng chỗ người bán vừa sửa.
              linkKind: Value(IdentityLinkKind.manual.code),
            ),
          );
      await _writeEvent(
        businessId: businessId,
        identityId: identityId,
        action: IdentityLinkAction.moved,
        actor: actor,
        fromCustomerId: row.customerId,
        toCustomerId: toCustomerId,
      );
    });
  }

  @override
  Future<List<IdentityLinkEvent>> historyFor(String identityId) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.identityLinkEventsTable)
              ..where(
                (t) =>
                    t.businessId.equals(businessId) &
                    t.identityId.equals(identityId),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.at)]))
            .get();
    return rows.map(_toEvent).nonNulls.toList();
  }

  @override
  Future<List<IdentityLinkEvent>> eventsByActor(String actor) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.identityLinkEventsTable)
              ..where(
                (t) => t.businessId.equals(businessId) & t.actor.equals(actor),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.at)]))
            .get();
    return rows.map(_toEvent).nonNulls.toList();
  }

  @override
  Future<void> deleteAll() async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await _db.transaction(() async {
      await (_db.delete(
        _db.externalIdentitiesTable,
      )..where((t) => t.businessId.equals(businessId))).go();
      await (_db.delete(
        _db.identityLinkEventsTable,
      )..where((t) => t.businessId.equals(businessId))).go();
    });
  }

  Future<void> _writeEvent({
    required String businessId,
    required String identityId,
    required IdentityLinkAction action,
    required String actor,
    String? fromCustomerId,
    String? toCustomerId,
    IdentityConfidence? confidence,
  }) => _db
      .into(_db.identityLinkEventsTable)
      .insert(
        IdentityLinkEventsTableCompanion.insert(
          id: _newId(),
          businessId: businessId,
          identityId: identityId,
          action: action.code,
          at: _now(),
          actor: actor,
          fromCustomerId: Value(fromCustomerId),
          toCustomerId: Value(toCustomerId),
          confidence: Value(confidence?.code),
        ),
      );

  ExternalIdentitiesTableCompanion _companion(
    ExternalIdentity i,
    String businessId,
  ) => ExternalIdentitiesTableCompanion.insert(
    id: i.id,
    businessId: businessId,
    platform: i.platform,
    externalId: i.externalId,
    connectionId: i.connectionId,
    customerId: i.customerId,
    confidence: i.confidence.code,
    linkKind: i.linkKind.code,
    linkedAt: i.linkedAt,
    displayName: Value(i.displayName),
    verifiedAt: Value(i.verifiedAt),
  );

  /// Mã lạ ⇒ `null` ⇒ dòng bị **bỏ qua**, không rơi về mặc định.
  ///
  /// ADR-TON-018: mã canonical không đọc được là bản ghi hỏng, không phải bản
  /// ghi mặc định. Ở đây hậu quả cụ thể là gì: đọc một `confidence` lạ thành
  /// `exact` sẽ cho phép tự động liên kết một thứ chưa ai duyệt.
  ExternalIdentity? _toIdentity(ExternalIdentitiesTableData row) {
    final confidence = IdentityConfidence.fromCode(row.confidence);
    final kind = IdentityLinkKind.fromCode(row.linkKind);
    if (confidence == null || kind == null) return null;
    return ExternalIdentity(
      id: row.id,
      platform: row.platform,
      externalId: row.externalId,
      connectionId: row.connectionId,
      customerId: row.customerId,
      confidence: confidence,
      linkKind: kind,
      linkedAt: row.linkedAt,
      displayName: row.displayName,
      verifiedAt: row.verifiedAt,
    );
  }

  IdentityLinkEvent? _toEvent(IdentityLinkEventsTableData row) {
    final action = IdentityLinkAction.fromCode(row.action);
    if (action == null) return null;
    return IdentityLinkEvent(
      id: row.id,
      identityId: row.identityId,
      action: action,
      at: row.at,
      actor: row.actor,
      fromCustomerId: row.fromCustomerId,
      toCustomerId: row.toCustomerId,
      confidence: IdentityConfidence.fromCode(row.confidence),
    );
  }
}
