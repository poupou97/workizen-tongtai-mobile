import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../action/business_action_executor.dart';
import '../action/demo_action_handlers.dart';
import '../agent/agent_task_queue.dart';
import '../agent/brief_inbox.dart';
import '../agent/business_brief.dart';
import '../agent/business_brief_service.dart';
import '../proposal/proposed_change_repository.dart';
import 'tongtai_capability_provider.dart';
import 'tongtai_chat_provider.dart' show tongtaiDatabaseProvider;
import 'tongtai_consumer_provider.dart';
import 'tongtai_inventory_provider.dart';
import 'tongtai_predictive_provider.dart';

/// **Nền Agentic, nối vào app** — WTM-303 (Epic WTM-302).
///
/// Epic WTM-297 dựng năm tầng và để chúng ở `L0`: có bảng, có luật, có test —
/// và **không một provider nào**, nên không màn hình nào chạm tới được. File
/// này là chỗ khoảng cách đó đóng lại.
///
/// Riverpod-only (ADR-TON-002). Test ghi đè các provider repository bằng bản
/// trong bộ nhớ, đúng như mọi capability khác trong repo này.

/// Đề xuất đổi sự thật, trên cơ sở dữ liệu thật (schema v21).
final proposedChangeRepositoryProvider = Provider<ProposedChangeRepository>(
  (ref) => DriftProposedChangeRepository(
    ref.watch(tongtaiDatabaseProvider),
    now: DateTime.now,
  ),
);

/// Hàng đợi việc bền vững (schema v23).
final agentTaskQueueProvider = Provider<AgentTaskQueue>((ref) {
  const uuid = Uuid();
  return AgentTaskQueue(
    ref.watch(tongtaiDatabaseProvider),
    now: DateTime.now,
    newId: uuid.v4,
  );
});

/// **Cửa ghi duy nhất** cho mọi side effect của agent (schema v22).
///
/// ## Vì sao `demo` là một handler thật, không phải một nhánh `if`
///
/// Chưa connector nào chạy thật, nên hôm nay mọi hành động đi qua
/// [demoActionHandlers]. Nhưng chúng vẫn đi **trọn vòng đời thật**:
/// `plan → approve → run` trong một transaction, có lease, có chống lặp.
///
/// Nghĩa là ngày Telegram thật xuất hiện, thứ thay đổi là **một handler** —
/// không phải màn hình, không phải bảng, không phải luật duyệt. Nếu thay vào
/// đó ta bỏ qua `run` ở chế độ demo, thì đường chạy thật sẽ là đường **chưa ai
/// từng chạy**, và nó sẽ hỏng đúng vào ngày đầu tiên có người dùng.
final businessActionExecutorProvider = Provider<BusinessActionExecutor>(
  (ref) => BusinessActionExecutor(
    ref.watch(tongtaiDatabaseProvider),
    now: DateTime.now,
    handlers: demoActionHandlers,
  ),
);

/// Hộp việc — nơi brief trở thành bản ghi có vòng đời.
final briefInboxProvider = Provider<BriefInbox>(
  (ref) => BriefInbox(
    proposals: ref.watch(proposedChangeRepositoryProvider),
    actions: ref.watch(businessActionExecutorProvider),
    tasks: ref.watch(agentTaskQueueProvider),
  ),
);

/// Động cơ dựng brief — hàm thuần, không phụ thuộc gì.
final businessBriefServiceProvider = Provider<BusinessBriefService>(
  (ref) => const BusinessBriefService(),
);

/// **Có gì đáng chú ý hôm nay.**
///
/// Đọc Rule Twin đã có (`customerRiskProvider`, `businessAlertsProvider`) cộng
/// danh bạ và kho, rồi dựng danh sách việc. Chạy được **không cần khoá AI,
/// không cần mạng** — đó là điều kiện của ADR-TON-016 và cũng là lý do brief
/// hiện ra ngay khi mở app.
///
/// Danh sách được **ghi xuống máy** ngay sau khi dựng: quyết định của người
/// bán phải sống qua một lần tắt app, và một brief chỉ để đọc thì mai lại nói
/// y hệt.
final businessBriefProvider = FutureProvider<List<BriefItem>>((ref) async {
  final risk = await ref.watch(customerRiskProvider.future);
  final alerts = await ref.watch(businessAlertsProvider.future);
  final customerCtx = await ref.watch(customerCapabilityProvider.future);
  final customers = await ref.watch(customerRepositoryProvider).loadAll();
  final products = await ref.watch(productRepositoryProvider).loadAll();

  final items = ref
      .watch(businessBriefServiceProvider)
      .derive(
        now: DateTime.now(),
        // `result` có thể là `null` — Rule Twin **từ chối trả lời** khi thiếu
        // dữ liệu, và từ chối là một câu trả lời. Ép nó thành danh sách rỗng ở
        // đây sẽ biến "chưa biết" thành "không có gì đáng lo".
        risk: risk.result,
        profiles: customerCtx.profiles,
        customers: customers,
        products: products,
        alerts: alerts.result ?? const [],
      );

  await ref.watch(briefInboxProvider).publish(items);
  return items;
});

/// Quyết định đã ghi nhận cho từng việc trong brief.
///
/// Tách khỏi [businessBriefProvider] vì hai thứ đổi theo nhịp khác nhau: brief
/// đổi khi *dữ liệu nghiệp vụ* đổi, quyết định đổi khi *người bán bấm*. Gộp
/// lại thì mỗi lần bấm một nút sẽ tính lại toàn bộ Rule Twin.
final briefDecisionsProvider = FutureProvider<Map<String, BriefDecision>>((
  ref,
) async {
  final items = await ref.watch(businessBriefProvider.future);
  final inbox = ref.watch(briefInboxProvider);
  final out = <String, BriefDecision>{};
  for (final item in items) {
    final decision = await inbox.statusOf(item);
    if (decision != null) out[item.id] = decision;
  }
  return out;
});
