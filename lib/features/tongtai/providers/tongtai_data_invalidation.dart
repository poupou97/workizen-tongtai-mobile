import 'package:flutter_riverpod/flutter_riverpod.dart';
// `ProviderOrFamily` — the type `invalidate` accepts — lives in Riverpod 3's
// `misc` surface, not the default export.
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import 'tongtai_agentic_provider.dart';
import 'tongtai_commerce_provider.dart';
import 'tongtai_connection_provider.dart';
import 'tongtai_simulation_provider.dart';
import 'tongtai_capability_provider.dart';
import 'tongtai_profile_provider.dart';
import 'tongtai_journey_provider.dart';
import 'tongtai_context_provider.dart';
import 'tongtai_predictive_provider.dart';

/// **The one list of caches over the business data** (WTM-149, device defect 1).
///
/// Every entry is a non-auto-dispose `FutureProvider`: Riverpod computes it
/// once and hands the SAME value to every later reader until something
/// invalidates it. That is exactly what you want while the data is still —
/// opening Revenue forecast twice must not re-scan the order book — and exactly
/// what is WRONG the moment the data changes underneath.
///
/// The bug this list exists to kill, found on device: More → "Load 12 months of
/// sample data" → Revenue forecast (12 months) → More → "Remove sample data" →
/// Revenue forecast **still showed the full 12-month forecast**. Home looked
/// right only because it re-reads its repositories in `initState`. Nothing but
/// an app restart cleared the predictive screens. That breaks the Founder's
/// cross-screen contract (Summary Count == Domain Visible Records, ADR-TON-014 /
/// ADR-TON-015 One Data Path) and the "resetting sample data is safe and
/// observable" gate.
///
/// **Any** action that writes to a repository must therefore invalidate them —
/// through [invalidateBusinessDataProviders], never by hand. Listing them at one
/// call site would only move the bug: the next data-mutating action would have
/// to remember a list it cannot see. Add a new cached read of the business data
/// here, and every existing caller is fixed for free.
///
/// Deliberately NOT here:
/// - `businessContextServiceProvider`, `*ContextProvider`,
///   `businessMetricsServiceProvider` — plain `Provider`s returning a *service*.
///   They hold no data; each `load()` re-reads the repositories.
/// - `tongtaiUserIdProvider`, `tongtaiHasAiKeyProvider` — cached, but over
///   identity/BYOK state, which sample data cannot change.
/// - `orderRepositoryProvider` & the other repository seams — invalidating one
///   would rebuild the repository object (and, transitively, risk churning the
///   database handle) without changing a single row.
final List<ProviderOrFamily> kBusinessDataProviders = <ProviderOrFamily>[
  // Capability contexts — the heavy analysis the twins are computed over.
  revenueCapabilityProvider,
  customerCapabilityProvider,
  // Rule Twins (ADR-TON-016). Invalidating the capabilities above already
  // invalidates these transitively; they are listed anyway so the contract is
  // readable and survives a future twin that stops watching a capability.
  revenueForecastProvider,
  customerRiskProvider,
  businessAlertsProvider,
  // Tổng kết tuần (WTM-376/377). Nó đọc thẳng `orderRepositoryProvider` chứ
  // không qua một capability context, nên KHÔNG có ai vô hiệu hoá nó hộ — bỏ
  // dòng này là sáng thứ Hai sau khi nạp dữ liệu mẫu, người bán vẫn đọc bản
  // tổng kết của doanh nghiệp cũ.
  weeklyReviewProvider,
  // The Opportunity Rule Engine's output — read by Home, Reports, Timeline,
  // Producer and the Opportunity feed.
  generatedOpportunitiesProvider,
  // AI Business Profile (WTM-177). Restore replaces it in the database, so a
  // cached read here would keep feeding the PREVIOUS business's trade and
  // channels into every AI prompt until the app restarted — the same shape as
  // the WTM-149 device defect, and invisible because the answer would still
  // look plausible.
  businessProfileProvider,
  // Business Journey (WTM-185). Restore replaces the tree, so a cached read
  // would keep showing the PREVIOUS business's plan — and worse, feed it to
  // the AI as if it were this seller's. Same shape as the WTM-149 defect.
  journeysProvider,
  activeJourneyProvider,
  // The numbers the journey measures its steps against (WTM-220). A restore
  // swaps the whole business, so a cached snapshot here would tick steps
  // against the PREVIOUS seller's counts — a journey marking work done that
  // this business never did.
  journeyMetricsProvider,
  // Opportunity reactions (WTM-190). The generated feed above is invalidated
  // already, but the reactions layered on top of it is a separate read: without
  // this, a restore would show the incoming business's opportunities carrying
  // the PREVIOUS seller's saves and dismissals.
  opportunitiesWithReactionsProvider,
  // Brief hằng ngày và các quyết định đã ghi nhận (WTM-303). Đây là bề mặt
  // **đầu tiên** người bán nhìn thấy khi mở app, nên một lần đọc cũ ở đây là
  // lần đọc cũ dễ thấy nhất trong cả app: gieo dữ liệu mẫu xong mà brief vẫn
  // nói "chưa có gì đáng chú ý" thì Founder kết luận tính năng hỏng, không
  // phải cache cũ.
  businessBriefProvider,
  briefDecisionsProvider,
  agentActivityProvider,
  // Kết nối nền tảng ngoài (WTM-317). Restore = Replace chép đè cả bảng
  // `connections`, nên một lần đọc cũ ở đây sẽ hiện kết nối của **doanh
  // nghiệp trước** — và tệ hơn: hiện nó ở trạng thái `ACTIVE` trong khi khoá
  // tương ứng không tồn tại trên máy này.
  connectorCatalogProvider,
  // Lịch sử nhập (WTM-326). Restore = Replace chép đè cả bảng, và một lần nhập
  // hiện ra sau khi đã bị xoá là một nút "Bỏ lần nhập" không xoá được gì.
  importJobsProvider,
  // Lời thật và cơ hội thương mại (WTM-328/329). Chúng đọc đơn hàng, danh mục
  // và đối soát — tức là mọi thứ một lần nhập hoặc một lần đặt lại demo đổi.
  // Thiếu ở đây thì sau khi nhập 100 sản phẩm, brief vẫn nói "chưa có gì đáng
  // chú ý" cho tới lần mở app sau.
  commerceProfitProvider,
  commerceOpportunitiesProvider,
  // Chuyến giao hàng (WTM-323) — một lần nhập hoặc một lần đặt lại demo đổi
  // hết. Thiếu ở đây thì sau khi nhập, brief vẫn nói kiện cũ đứng im.
  shipmentConcernsProvider,
  // Dòng thời gian doanh nghiệp (WTM-338). Mỗi lần đẩy đồng hồ là thế giới
  // đổi — không làm mới thì Founder bấm "Ngày tiếp" mà màn hình đứng im, và
  // đó đúng là thứ phá cảm giác "doanh nghiệp đang sống".
  businessTimelineProvider,
  simulationDayProvider,
  // Hội thoại khách hàng (WTM-339) — là **chiếu** của cùng sổ sự kiện đó, nên
  // nó cũ đi vào đúng những lúc dòng thời gian cũ đi. Thiếu ở đây thì người
  // bán bấm "Gửi", tin nhắn vào sổ, mà khung chat vẫn còn nút "Gửi".
  customerConversationsProvider,
  // Nền tảng đang phát trong bản mô phỏng (WTM-340) — cùng sổ sự kiện, nên nó
  // cũ đi cùng lúc. Thiếu ở đây thì "Bắt đầu lại" xong màn nguồn dữ liệu vẫn
  // khai mười nền tảng đang phát trong khi sổ đã trống.
  liveDemoVendorsProvider,
];

/// Drops every cached read of the business data ([kBusinessDataProviders]).
///
/// Call this from a widget after **any** successful mutation of the business
/// data — seeding samples, seeding generated history, removing samples, and any
/// future bulk import/reset. It is cheap and safe when nothing is listening:
/// invalidating an uninitialised provider is a no-op, and an initialised one
/// simply recomputes the next time it is read.
///
/// ```dart
/// await ref.read(sampleDataSeederProvider).removeAll();
/// invalidateBusinessDataProviders(ref);
/// ```
/// Bumped every time the business data changes underneath the app.
///
/// Invalidating the providers above is **not enough** for a screen that is
/// already built. The four shell tabs hold their rows in a
/// `ScreenDataController` created in `initState`, and the shell keeps them
/// alive in an `IndexedStack` — so `initState` runs once per app launch and a
/// provider invalidation never reaches them.
///
/// Found on device (WTM-174): restore a backup of 7 customers over a business
/// of 42, and the success card says 7 while Home keeps showing **42** until the
/// app is killed. The database was correct the whole time; only the screen
/// lied. A seller seeing that concludes the restore failed.
///
/// The doc above this list still said *"Home looked right only because it
/// re-reads its repositories in initState"* — true when WTM-149 wrote it, and
/// made false by the WTM-148 seam migration without anyone noticing.
class BusinessDataRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final businessDataRevisionProvider =
    NotifierProvider<BusinessDataRevision, int>(BusinessDataRevision.new);

void invalidateBusinessDataProviders(WidgetRef ref) {
  for (final provider in kBusinessDataProviders) {
    ref.invalidate(provider);
  }
  ref.read(businessDataRevisionProvider.notifier).bump();
}

/// [invalidateBusinessDataProviders] for a bare [ProviderContainer].
///
/// Same list, same effect — `WidgetRef` and `ProviderContainer` share no public
/// `invalidate` interface, so the two entry points wrap one list rather than
/// letting a caller re-derive it. Used by tests and by any future non-widget
/// caller (a background import, a restore-from-backup service).
void invalidateBusinessDataProvidersIn(ProviderContainer container) {
  for (final provider in kBusinessDataProviders) {
    container.invalidate(provider);
  }
  container.read(businessDataRevisionProvider.notifier).bump();
}
