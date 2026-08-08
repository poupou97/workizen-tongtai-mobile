import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../core/local_workspace.dart';
import 'business_action.dart';

/// Việc thật sự làm ra bên ngoài — hoặc vào chính DB Tổng Tài.
///
/// Trả về `externalId`: mã của kết quả ở hệ ngoài, hoặc mã nội bộ khi
/// [ActionVendor.internal]. Ném ra thì hành động chuyển `failed` và **thử lại
/// được**.
///
/// ⚠️ Chạy **bên trong một transaction**. Đó là lý do side effect và cập nhật
/// trạng thái không bao giờ lệch nhau.
typedef ActionEffect =
    Future<String> Function(AppDatabase db, BusinessAction action);

/// Vì sao một hành động không chạy được.
enum ActionRejection {
  /// Cùng khoá chống lặp nhưng payload **khác** — hai việc khác nhau.
  idempotencyConflict('idempotency_conflict'),

  /// Chưa ai duyệt.
  notApproved('not_approved'),

  /// Đang có tiến trình khác giữ lease.
  alreadyRunning('already_running'),

  /// Không có ai biết làm loại hành động này.
  noHandler('no_handler'),

  /// Loại này nằm trong danh sách tuyệt đối không tự chạy.
  autoForbidden('auto_forbidden');

  const ActionRejection(this.code);

  final String code;
}

/// Kết quả một lần chạy.
sealed class ActionRunResult {
  const ActionRunResult();
}

class ActionSucceeded extends ActionRunResult {
  const ActionSucceeded({required this.externalId, this.replayed = false});

  final String externalId;

  /// `true` = **không làm lại gì cả**, chỉ trả kết quả cũ.
  final bool replayed;
}

class ActionFailed extends ActionRunResult {
  const ActionFailed({required this.errorCode, required this.errorMessage});

  final String errorCode;
  final String errorMessage;
}

class ActionRefused extends ActionRunResult {
  const ActionRefused(this.reason);

  final ActionRejection reason;
}

/// Thực thi hành động — **giao thức bốn bước**, học nguyên từ `run-runtime.ts`
/// của COMP AI (WTM-296 §12) và bổ sung hai thứ họ thiếu.
///
/// ## Bốn bước
///
/// 1. **Tra theo khoá chống lặp.** Có rồi mà `requestHash` khác ⇒ **từ chối**,
///    không ghi đè im lặng.
/// 2. **Đã `succeeded` ⇒ trả `replayed: true`.** Không làm lại.
/// 3. **Nhận bằng lease** — `approved`/`failed`, hoặc `running` đã quá hạn.
/// 4. **Side effect và cập nhật trạng thái trong MỘT transaction.** Không thể
///    "succeeded mà chưa làm", cũng không thể "làm rồi mà ghi failed".
///
/// ## Hai thứ COMP AI thiếu
///
/// - **`riskLevel` + danh sách tuyệt đối không auto** — hành động của họ chỉ
///   ghi CRM; của ta tiêu tiền thật.
/// - **Cửa phủ cả `vendor: internal`** — đúng chỗ họ hụt.
class BusinessActionExecutor {
  BusinessActionExecutor(
    this._db, {
    this._workspace = const LocalWorkspace(),
    required this._handlers,
    required this._now,
    Duration leaseDuration = const Duration(minutes: 5),
  }) : _lease = leaseDuration;

  final AppDatabase _db;
  final LocalWorkspace _workspace;
  final Map<BusinessActionType, ActionEffect> _handlers;
  final DateTime Function() _now;
  final Duration _lease;

  /// Vân tay của payload — hai payload khác nhau phải ra hai vân tay khác nhau.
  ///
  /// Khoá được sắp xếp để cùng nội dung luôn cho cùng vân tay bất kể thứ tự.
  static String hashRequest(Map<String, Object?> parameters) {
    final keys = parameters.keys.toList()..sort();
    return jsonEncode({for (final k in keys) k: parameters[k]});
  }

  /// Dựng một hành động và ghi nó ở trạng thái `planned`.
  ///
  /// Trả về hành động **đã có** nếu khoá chống lặp trùng và payload khớp — tức
  /// gọi lại hai lần không sinh ra hai việc.
  Future<BusinessAction> plan(BusinessAction action) async {
    final businessId = await _workspace.ensureBusinessId(_db);

    final existing = await _byKey(businessId, action.idempotencyKey);
    if (existing != null) {
      if (existing.requestHash != action.requestHash) {
        throw StateError(
          'khoá chống lặp "${action.idempotencyKey}" đã dùng cho một payload '
          'KHÁC. Hai việc khác nhau trùng khoá sẽ nuốt nhau — đổi khoá.',
        );
      }
      return existing;
    }

    await _db
        .into(_db.businessActionsTable)
        .insert(_companion(action, businessId));
    return action;
  }

  /// Người bán duyệt — hoặc policy cho phép.
  ///
  /// `AUTO` **không** duyệt được loại nằm trong danh sách tuyệt đối cấm; đó là
  /// hằng số trong code, không phải cấu hình.
  Future<ActionRunResult?> approve(
    String id, {
    required String requestedBy,
    AutonomyMode mode = AutonomyMode.confirm,
  }) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final action = await _byId(businessId, id);
    if (action == null) return null;

    if (mode == AutonomyMode.auto && action.type.neverAutoByDefault) {
      return const ActionRefused(ActionRejection.autoForbidden);
    }

    final count =
        await (_db.update(_db.businessActionsTable)..where(
              (t) =>
                  t.businessId.equals(businessId) &
                  t.id.equals(id) &
                  t.status.equals(ActionStatus.planned.code),
            ))
            .write(
              BusinessActionsTableCompanion(
                status: Value(ActionStatus.approved.code),
                requestedBy: Value(requestedBy),
              ),
            );
    return count > 0 ? null : const ActionRefused(ActionRejection.notApproved);
  }

  /// Người bán **từ chối** một hành động đang chờ.
  ///
  /// `cancelled` là trạng thái cuối, nên một việc bị bỏ qua không quay lại
  /// vào sáng hôm sau — đó chính là thứ phân biệt một trợ lý với một cái
  /// chuông báo.
  ///
  /// Chỉ đóng được từ `planned`: hành động đã duyệt hoặc đang chạy thì có thể
  /// đã chạm ra ngoài, và "huỷ" một việc đã xảy ra là nói dối.
  Future<bool> cancel(String id) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final count =
        await (_db.update(_db.businessActionsTable)..where(
              (t) =>
                  t.businessId.equals(businessId) &
                  t.id.equals(id) &
                  t.status.equals(ActionStatus.planned.code),
            ))
            .write(
              BusinessActionsTableCompanion(
                status: Value(ActionStatus.cancelled.code),
                completedAt: Value(_now()),
              ),
            );
    return count > 0;
  }

  /// Chạy một hành động đã duyệt. **Đây là chỗ duy nhất side effect xảy ra.**
  Future<ActionRunResult> run(String id) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final action = await _byId(businessId, id);
    if (action == null) return const ActionRefused(ActionRejection.noHandler);

    // Bước 2 — đã xong thì không làm lại.
    if (action.status == ActionStatus.succeeded) {
      return ActionSucceeded(
        externalId: action.externalId ?? '',
        replayed: true,
      );
    }
    if (action.status.isTerminal) {
      return const ActionRefused(ActionRejection.notApproved);
    }

    final effect = _handlers[action.type];
    if (effect == null) return const ActionRefused(ActionRejection.noHandler);

    // Bước 3 — nhận bằng lease. `approved`/`failed`, hoặc `running` quá hạn.
    final now = _now();
    final claimed =
        await (_db.update(_db.businessActionsTable)..where((t) {
              final mine = t.businessId.equals(businessId) & t.id.equals(id);
              final free =
                  t.status.equals(ActionStatus.approved.code) |
                  t.status.equals(ActionStatus.failed.code);
              final stale =
                  t.status.equals(ActionStatus.running.code) &
                  t.leasedUntil.isSmallerThanValue(now);
              return mine & (free | stale);
            }))
            .write(
              BusinessActionsTableCompanion(
                status: Value(ActionStatus.running.code),
                startedAt: Value(action.startedAt ?? now),
                leasedUntil: Value(now.add(_lease)),
                attemptCount: Value(action.attemptCount + 1),
                errorCode: const Value(null),
                errorMessage: const Value(null),
              ),
            );

    if (claimed == 0) {
      final current = await _byId(businessId, id);
      if (current?.status == ActionStatus.succeeded) {
        return ActionSucceeded(
          externalId: current?.externalId ?? '',
          replayed: true,
        );
      }
      if (current?.status == ActionStatus.planned) {
        return const ActionRefused(ActionRejection.notApproved);
      }
      return const ActionRefused(ActionRejection.alreadyRunning);
    }

    // Bước 4 — side effect và trạng thái trong MỘT transaction.
    try {
      late String externalId;
      await _db.transaction(() async {
        externalId = await effect(_db, action);
        await (_db.update(_db.businessActionsTable)
              ..where((t) => t.businessId.equals(businessId) & t.id.equals(id)))
            .write(
              BusinessActionsTableCompanion(
                status: Value(ActionStatus.succeeded.code),
                externalId: Value(externalId),
                completedAt: Value(_now()),
                leasedUntil: const Value(null),
              ),
            );
      });
      return ActionSucceeded(externalId: externalId);
    } on Object catch (error) {
      final message = error.toString();
      await (_db.update(
        _db.businessActionsTable,
      )..where((t) => t.businessId.equals(businessId) & t.id.equals(id))).write(
        BusinessActionsTableCompanion(
          status: Value(ActionStatus.failed.code),
          errorCode: const Value('effect_failed'),
          errorMessage: Value(message),
          completedAt: Value(_now()),
          leasedUntil: const Value(null),
        ),
      );
      return ActionFailed(errorCode: 'effect_failed', errorMessage: message);
    }
  }

  Future<List<BusinessAction>> loadByCorrelation(String correlationId) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.businessActionsTable)
              ..where(
                (t) =>
                    t.businessId.equals(businessId) &
                    t.correlationId.equals(correlationId),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.plannedAt)]))
            .get();
    return rows.map(_toAction).nonNulls.toList();
  }

  /// Mọi hành động, mới nhất trước — nguồn của màn Hoạt động.
  Future<List<BusinessAction>> loadRecent({int limit = 50}) async {
    final businessId = await _workspace.ensureBusinessId(_db);
    final rows =
        await (_db.select(_db.businessActionsTable)
              ..where((t) => t.businessId.equals(businessId))
              ..orderBy([(t) => OrderingTerm.desc(t.plannedAt)])
              ..limit(limit))
            .get();
    return rows.map(_toAction).nonNulls.toList();
  }

  Future<BusinessAction?> byId(String id) async =>
      _byId(await _workspace.ensureBusinessId(_db), id);

  Future<void> deleteAll() async {
    final businessId = await _workspace.ensureBusinessId(_db);
    await (_db.delete(
      _db.businessActionsTable,
    )..where((t) => t.businessId.equals(businessId))).go();
  }

  Future<BusinessAction?> _byId(String businessId, String id) async {
    final row =
        await (_db.select(_db.businessActionsTable)
              ..where((t) => t.businessId.equals(businessId) & t.id.equals(id)))
            .getSingleOrNull();
    return row == null ? null : _toAction(row);
  }

  Future<BusinessAction?> _byKey(String businessId, String key) async {
    final row =
        await (_db.select(_db.businessActionsTable)..where(
              (t) =>
                  t.businessId.equals(businessId) &
                  t.idempotencyKey.equals(key),
            ))
            .getSingleOrNull();
    return row == null ? null : _toAction(row);
  }

  BusinessActionsTableCompanion _companion(
    BusinessAction a,
    String businessId,
  ) => BusinessActionsTableCompanion.insert(
    id: a.id,
    businessId: businessId,
    correlationId: Value(a.correlationId),
    type: a.type.code,
    vendor: a.vendor.code,
    subjectKind: a.subjectKind,
    subjectId: a.subjectId,
    subjectLabel: Value(a.subjectLabel),
    summary: a.summary,
    parameters: jsonEncode(a.parameters),
    proposedBy: a.proposedBy,
    requestedBy: Value(a.requestedBy),
    idempotencyKey: a.idempotencyKey,
    requestHash: a.requestHash,
    status: a.status.code,
    attemptCount: Value(a.attemptCount),
    leasedUntil: Value(a.leasedUntil),
    plannedAt: a.plannedAt,
    startedAt: Value(a.startedAt),
    completedAt: Value(a.completedAt),
    externalId: Value(a.externalId),
    errorCode: Value(a.errorCode),
    errorMessage: Value(a.errorMessage),
  );

  /// Mã canonical lạ ⇒ **bỏ qua dòng**, không rơi về mặc định (ADR-TON-018).
  ///
  /// Hậu quả cụ thể nếu rơi về mặc định: một `status` lạ đọc thành `approved`
  /// sẽ khiến một hành động **chưa ai duyệt** được chạy.
  BusinessAction? _toAction(BusinessActionsTableData row) {
    final type = BusinessActionType.fromCode(row.type);
    final vendor = ActionVendor.fromCode(row.vendor);
    final status = ActionStatus.fromCode(row.status);
    if (type == null || vendor == null || status == null) return null;

    Map<String, Object?> params;
    try {
      final decoded = jsonDecode(row.parameters);
      params = decoded is Map ? Map<String, Object?>.from(decoded) : {};
    } on FormatException {
      return null;
    }

    return BusinessAction(
      id: row.id,
      correlationId: row.correlationId,
      type: type,
      vendor: vendor,
      subjectKind: row.subjectKind,
      subjectId: row.subjectId,
      subjectLabel: row.subjectLabel,
      summary: row.summary,
      parameters: params,
      proposedBy: row.proposedBy,
      requestedBy: row.requestedBy,
      idempotencyKey: row.idempotencyKey,
      requestHash: row.requestHash,
      status: status,
      attemptCount: row.attemptCount,
      leasedUntil: row.leasedUntil,
      plannedAt: row.plannedAt,
      startedAt: row.startedAt,
      completedAt: row.completedAt,
      externalId: row.externalId,
      errorCode: row.errorCode,
      errorMessage: row.errorMessage,
    );
  }
}
