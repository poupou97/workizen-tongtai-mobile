import 'package:flutter/foundation.dart';

import '../analytics/customer_rfm.dart';
import '../analytics/month_bucket.dart';
import '../consumer/customer.dart';
import '../consumer/customer_repository.dart';
import '../core/capability_context_provider.dart';
import '../core/tongtai_formatters.dart';
import '../orders/order.dart';
import '../orders/order_repository.dart';
import 'capability_context.dart';

/// Machine name of the Customer capability.
const String kCustomerCapability = 'customer';

/// Schema version of [CustomerCapabilityContext] (ADR-TON-016). Bump on any
/// field/meaning change — **including a threshold change**, because a "churned"
/// count means something different afterwards.
const int kCustomerCapabilityVersion = 1;

/// Default analysis window for [CustomerRfm.ordersInWindow]: 12 calendar months
/// **including** the running one — for recency work the partial month is the
/// whole point (the opposite of the revenue series' completed-months rule).
const int kCustomerCapabilityWindowMonths = 12;

// ── Lifecycle thresholds ────────────────────────────────────────────────────
//
// Two ladders, deliberately: a customer's OWN cadence when they have one, and
// fixed day windows when they do not (see [customerLifecycleStage]).

/// Fixed-window ladder — silence of at most this many days still counts as
/// [CustomerLifecycleStage.active].
///
/// 30 days ≈ one monthly buying cycle, the rhythm most Vietnamese SME retail
/// customers actually have, and the horizon a seller thinks in ("mua tháng
/// này chưa?").
const int kCustomerActiveMaxDays = 30;

/// Fixed-window ladder — 31…60 days is [CustomerLifecycleStage.cooling]: one
/// missed cycle. Worth noticing, not worth panicking about.
const int kCustomerCoolingMaxDays = 60;

/// Fixed-window ladder — 61…90 days is [CustomerLifecycleStage.atRisk]: two
/// missed cycles, the last moment a win-back is cheap.
const int kCustomerAtRiskMaxDays = 90;

/// Beyond [kCustomerAtRiskMaxDays] the customer is
/// [CustomerLifecycleStage.churned] — a full quarter of silence.

/// Cadence ladder — silence up to 1.0× the customer's own median gap is still
/// [CustomerLifecycleStage.active]: they are simply not due yet.
const double kCustomerCoolingGapRatio = 1.0;

/// Cadence ladder — up to 1.5× their own gap is [CustomerLifecycleStage.cooling]
/// (half a cycle late).
const double kCustomerAtRiskGapRatio = 1.5;

/// Cadence ladder — up to 3.0× their own gap is [CustomerLifecycleStage.atRisk];
/// beyond that they are [CustomerLifecycleStage.churned]. Three missed cycles is
/// where "late" stops being a plausible explanation.
const double kCustomerChurnedGapRatio = 3.0;

/// Floor under the cadence ladder, in days.
///
/// A customer buying every two days would otherwise be "churned" after a quiet
/// week, which no seller would accept. Cadences below this are treated as this
/// (`recency / max(gap, 14)`, via [CustomerRfm.gapRatioWithFloor]). Two weeks is
/// the shortest silence that is not just a weekend plus a holiday.
const double kCustomerCadenceFloorDays = 14;

/// A customer whose **first** order is at most this old is counted as *new*.
/// Same 30-day cycle as [kCustomerActiveMaxDays], so "new" and "active" line up.
const int kCustomerNewMaxDays = 30;

/// Lifetime orders that make a customer *returning* rather than a one-off.
const int kCustomerReturningMinOrders = 2;

/// Lifetime orders that qualify a lapsed customer as a win-back candidate even
/// when their spend is unremarkable — they proved they come back at least once.
const int kCustomerWinBackMinOrders = 2;

/// Quantiles used to band lifetime spend: the median and the top-20% cut-off →
/// three bands (thấp / trung / cao).
const List<double> kCustomerMonetaryQuantiles = [0.5, 0.8];

/// Quantiles used to band lifetime order counts — same shape as
/// [kCustomerMonetaryQuantiles].
const List<double> kCustomerFrequencyQuantiles = [0.5, 0.8];

/// Where a customer stands in their purchase lifecycle.
///
/// **Mutually exclusive** — every customer lands in exactly one stage, so the
/// counts sum to the directory size. "New", "returning" and "win-back
/// candidate" are deliberately *not* stages: they overlap with the stages (a
/// new customer is usually also active), and forcing them into one ladder would
/// make the numbers lie. They are reported as separate, overlapping counts.
enum CustomerLifecycleStage {
  /// In the directory, has never placed a billable order.
  neverPurchased,

  /// Bought inside their own cadence (or inside the fixed active window).
  active,

  /// One missed cycle.
  cooling,

  /// Two missed cycles — the last cheap moment for a win-back.
  atRisk,

  /// Silent long enough that "late" is no longer a plausible explanation.
  churned;

  /// Vietnamese label used in the AI prompt block (UI strings live in l10n).
  String get labelVi => switch (this) {
    CustomerLifecycleStage.neverPurchased => 'chưa mua',
    CustomerLifecycleStage.active => 'đang hoạt động',
    CustomerLifecycleStage.cooling => 'đang nguội',
    CustomerLifecycleStage.atRisk => 'rủi ro',
    CustomerLifecycleStage.churned => 'đã rời bỏ',
  };
}

/// A coarse recency histogram bucket — the **raw** days-since-last-order
/// distribution, always on the fixed windows.
///
/// This is not the same statement as [CustomerLifecycleStage]: the stages are
/// cadence-aware (a quarterly buyer silent for 100 days is only "cooling"),
/// while the distribution answers the flat question "how long since each
/// customer last bought". Keeping both means a UI can show the honest histogram
/// next to the smarter segmentation.
enum CustomerRecencyBand {
  days0to30,
  days31to60,
  days61to90,
  over90,
  never;

  String get labelVi => switch (this) {
    CustomerRecencyBand.days0to30 => '≤30 ngày',
    CustomerRecencyBand.days31to60 => '31–60 ngày',
    CustomerRecencyBand.days61to90 => '61–90 ngày',
    CustomerRecencyBand.over90 => '>90 ngày',
    CustomerRecencyBand.never => 'chưa mua',
  };
}

/// Classifies one RFM profile into its lifecycle stage.
///
/// **The customer's own cadence wins.** When [CustomerRfm.medianGapDays] exists
/// (≥ 2 orders) the ladder is relative — 1.0× / 1.5× / 3.0× of their own median
/// gap, floored at [kCustomerCadenceFloorDays] — so a weekly buyer who has been
/// silent for 40 days is *at risk* even though a fixed 30/60/90 ladder would
/// call them merely "cooling", and a quarterly buyer silent for 100 days is only
/// *cooling* even though the fixed ladder would write them off as churned.
///
/// **Fallback:** a single-purchase customer has no rhythm to be late against, so
/// there is nothing to derive — the fixed 30/60/90-day windows apply. A customer
/// with no orders at all is [CustomerLifecycleStage.neverPurchased], never
/// "churned": they never left, they never arrived.
///
/// Pure and total: same profile → same stage, no clock read (recency is already
/// baked into the profile by `CustomerRfmService.compute`).
CustomerLifecycleStage customerLifecycleStage(CustomerRfm profile) {
  final recency = profile.recencyDays;
  if (!profile.hasOrders || recency == null) {
    return CustomerLifecycleStage.neverPurchased;
  }
  final ratio = profile.gapRatioWithFloor(kCustomerCadenceFloorDays);
  if (ratio != null) {
    if (ratio <= kCustomerCoolingGapRatio) return CustomerLifecycleStage.active;
    if (ratio <= kCustomerAtRiskGapRatio) return CustomerLifecycleStage.cooling;
    if (ratio <= kCustomerChurnedGapRatio) return CustomerLifecycleStage.atRisk;
    return CustomerLifecycleStage.churned;
  }
  if (recency <= kCustomerActiveMaxDays) return CustomerLifecycleStage.active;
  if (recency <= kCustomerCoolingMaxDays) return CustomerLifecycleStage.cooling;
  if (recency <= kCustomerAtRiskMaxDays) return CustomerLifecycleStage.atRisk;
  return CustomerLifecycleStage.churned;
}

/// The raw recency bucket of [profile] — fixed windows only (see
/// [CustomerRecencyBand]).
CustomerRecencyBand customerRecencyBand(CustomerRfm profile) {
  final recency = profile.recencyDays;
  if (recency == null) return CustomerRecencyBand.never;
  if (recency <= kCustomerActiveMaxDays) return CustomerRecencyBand.days0to30;
  if (recency <= kCustomerCoolingMaxDays) return CustomerRecencyBand.days31to60;
  if (recency <= kCustomerAtRiskMaxDays) return CustomerRecencyBand.days61to90;
  return CustomerRecencyBand.over90;
}

/// Whether [profile]'s **first** order is at most [kCustomerNewMaxDays] old at
/// [now] — i.e. this is a newly acquired customer, however many orders they have
/// since placed.
bool isNewCustomer(CustomerRfm profile, {required DateTime now}) {
  final first = profile.firstOrderAt;
  if (first == null) return false;
  return wholeDaysBetween(first, now) <= kCustomerNewMaxDays;
}

/// Whether a lapsed customer is worth chasing: they must be
/// [CustomerLifecycleStage.atRisk] or [CustomerLifecycleStage.churned] **and**
/// either sit in the top lifetime-spend band or have come back at least
/// [kCustomerWinBackMinOrders] times before.
///
/// [monetaryCutoffs] are the ascending cut-offs from
/// [CustomerRfmService.monetaryQuantiles]; a degenerate all-zero directory
/// yields no top band, and spend of 0 never qualifies — otherwise "everyone is
/// top band" in a business with no sales.
bool isWinBackCandidate(
  CustomerRfm profile, {
  required CustomerLifecycleStage stage,
  required List<double> monetaryCutoffs,
}) {
  if (stage != CustomerLifecycleStage.atRisk &&
      stage != CustomerLifecycleStage.churned) {
    return false;
  }
  final topBand = monetaryCutoffs.length;
  final inTopBand =
      monetaryCutoffs.isNotEmpty &&
      monetaryCutoffs.last > 0 &&
      profile.monetary > 0 &&
      CustomerRfmService.band(profile.monetary, monetaryCutoffs) == topBand;
  return inTopBand || profile.frequency >= kCustomerWinBackMinOrders;
}

/// **Customer Capability Context** (WTM-154, ADR-TON-016) — the deep consumer
/// analysis, loaded on demand by the Customer Risk screen and by the churn /
/// win-back Rule Twin.
///
/// It carries the per-customer [profiles] (`CustomerRfm`), the lifecycle
/// segmentation, the raw recency distribution, and monetary/frequency bands
/// with the cut-offs they were computed from. `BusinessContext` keeps only the
/// lightweight `CustomerSummary` (total + tier counts) — none of this belongs
/// there (the God-Object rule).
///
/// **Every number is delegated to `analytics/`**: recency, frequency, monetary,
/// cadence, quantiles and banding all come from [CustomerRfmService]; this class
/// only applies the *policy* (which threshold means what) declared above.
///
/// **Privacy:** the context holds customer **ids** and numbers — never names,
/// phones, emails, addresses, notes or tags. The PII-free [promptBlock] is
/// therefore structural, not a filter that could be forgotten.
@immutable
class CustomerCapabilityContext implements CapabilityContext {
  /// Prefer [CustomerCapabilityContext.from] — this constructor exists so a
  /// test or a future cache can rebuild an exact context from its parts.
  const CustomerCapabilityContext({
    required this.generatedAt,
    required this.profiles,
    required this.stageCounts,
    required this.recencyDistribution,
    required this.monetaryCutoffs,
    required this.monetaryBandCounts,
    required this.frequencyCutoffs,
    required this.frequencyBandCounts,
    required this.newCount,
    required this.returningCount,
    required this.winBackCandidateCount,
    required this.windowMonths,
  });

  /// Builds the context from the customer directory and the raw [orders] at
  /// instant [now].
  ///
  /// Every customer in [customers] gets a profile — including those who never
  /// bought, which are exactly the ones a "never converted" rule needs. Orders
  /// referencing an unknown customer are ignored, and cancelled orders are
  /// invisible (the shared `isBillableOrder` rule), both by
  /// [CustomerRfmService.compute].
  factory CustomerCapabilityContext.from({
    required Iterable<Customer> customers,
    required Iterable<CustomerOrder> orders,
    required DateTime now,
    int windowMonths = kCustomerCapabilityWindowMonths,
  }) {
    final profiles = CustomerRfmService.compute(
      customers,
      orders,
      now: now,
      windowMonths: windowMonths,
    );

    final monetaryCutoffs = CustomerRfmService.monetaryQuantiles(
      profiles,
      kCustomerMonetaryQuantiles,
    );
    final frequencyCutoffs = CustomerRfmService.frequencyQuantiles(
      profiles,
      kCustomerFrequencyQuantiles,
    );

    final stageCounts = <CustomerLifecycleStage, int>{
      for (final stage in CustomerLifecycleStage.values) stage: 0,
    };
    final recency = <CustomerRecencyBand, int>{
      for (final band in CustomerRecencyBand.values) band: 0,
    };
    final monetaryBands = List<int>.filled(monetaryCutoffs.length + 1, 0);
    final frequencyBands = List<int>.filled(frequencyCutoffs.length + 1, 0);
    var newCount = 0;
    var returningCount = 0;
    var winBackCount = 0;

    for (final profile in profiles) {
      final stage = customerLifecycleStage(profile);
      stageCounts[stage] = stageCounts[stage]! + 1;
      final band = customerRecencyBand(profile);
      recency[band] = recency[band]! + 1;
      if (isNewCustomer(profile, now: now)) newCount += 1;
      if (profile.frequency >= kCustomerReturningMinOrders) {
        returningCount += 1;
      }
      if (isWinBackCandidate(
        profile,
        stage: stage,
        monetaryCutoffs: monetaryCutoffs,
      )) {
        winBackCount += 1;
      }
      monetaryBands[CustomerRfmService.band(
            profile.monetary,
            monetaryCutoffs,
          )] +=
          1;
      frequencyBands[CustomerRfmService.band(
            profile.frequency,
            frequencyCutoffs,
          )] +=
          1;
    }

    return CustomerCapabilityContext(
      generatedAt: now,
      profiles: profiles,
      stageCounts: Map<CustomerLifecycleStage, int>.unmodifiable(stageCounts),
      recencyDistribution: Map<CustomerRecencyBand, int>.unmodifiable(recency),
      monetaryCutoffs: monetaryCutoffs,
      monetaryBandCounts: List<int>.unmodifiable(monetaryBands),
      frequencyCutoffs: frequencyCutoffs,
      frequencyBandCounts: List<int>.unmodifiable(frequencyBands),
      newCount: newCount,
      returningCount: returningCount,
      winBackCandidateCount: winBackCount,
      windowMonths: windowMonths,
    );
  }

  /// One profile per customer, in directory order — ids and numbers only.
  final List<CustomerRfm> profiles;

  /// How many customers sit in each lifecycle stage. Mutually exclusive: the
  /// values sum to [totalCustomers], and every stage is present (as 0 when
  /// empty) so a consumer never has to guess whether a missing key means zero.
  final Map<CustomerLifecycleStage, int> stageCounts;

  /// Raw days-since-last-order histogram (fixed windows — see
  /// [CustomerRecencyBand]). Also sums to [totalCustomers].
  final Map<CustomerRecencyBand, int> recencyDistribution;

  /// Ascending lifetime-spend cut-offs from [kCustomerMonetaryQuantiles];
  /// empty for an empty directory.
  final List<double> monetaryCutoffs;

  /// Customers per spend band, lowest → highest; length is
  /// `monetaryCutoffs.length + 1`.
  final List<int> monetaryBandCounts;

  /// Ascending lifetime-order-count cut-offs from
  /// [kCustomerFrequencyQuantiles].
  final List<double> frequencyCutoffs;

  /// Customers per frequency band, lowest → highest.
  final List<int> frequencyBandCounts;

  /// Customers whose **first** order is at most [kCustomerNewMaxDays] old.
  /// Overlaps the stages on purpose (a new customer is normally also active).
  final int newCount;

  /// Customers with at least [kCustomerReturningMinOrders] lifetime orders —
  /// also an overlapping count.
  final int returningCount;

  /// Lapsed customers worth chasing — see [isWinBackCandidate]. A subset of
  /// `atRisk + churned`.
  final int winBackCandidateCount;

  /// The `ordersInWindow` window, in calendar months (running month included).
  final int windowMonths;

  @override
  final DateTime generatedAt;

  @override
  String get capability => kCustomerCapability;

  @override
  int get version => kCustomerCapabilityVersion;

  /// True when there is a directory to segment at all. A directory whose
  /// customers have never bought still *is* data — "5 khách chưa từng mua" is a
  /// real, actionable statement, not a fake zero.
  @override
  bool get hasData => profiles.isNotEmpty;

  int get totalCustomers => profiles.length;

  /// Customers with at least one billable order.
  int get purchasingCustomers =>
      profiles.where((profile) => profile.hasOrders).length;

  /// Count for [stage] — always defined (0 rather than absent).
  int stage(CustomerLifecycleStage stage) => stageCounts[stage] ?? 0;

  /// Count for a recency [band] — always defined.
  int recency(CustomerRecencyBand band) => recencyDistribution[band] ?? 0;

  /// Lapsed = at risk + churned; the population a win-back rule works on.
  int get lapsedCount =>
      stage(CustomerLifecycleStage.atRisk) +
      stage(CustomerLifecycleStage.churned);

  /// PII-free consumer block for the AI layer.
  ///
  /// Counts, bands and thresholds only — the context carries no name, phone,
  /// email or address to begin with, and customer **ids** are deliberately left
  /// out too (the AI reasons about segments, not about individuals). When
  /// [hasData] is false it says so instead of printing a segmentation of zeros.
  @override
  String promptBlock() {
    final buffer = StringBuffer()..writeln(capabilityPromptHeader(this));

    if (!hasData) {
      buffer
        ..writeln(
          '- CHƯA ĐỦ DỮ LIỆU: danh bạ khách hàng đang trống, không có gì để '
          'phân khúc.',
        )
        ..write(
          '- Không được suy ra tỉ lệ rời bỏ, phân khúc hay rủi ro từ khối này.',
        );
      return buffer.toString();
    }

    buffer
      ..writeln(
        '- Cửa sổ: $windowMonths tháng (gồm tháng đang chạy)'
        ' · ngưỡng cố định: hoạt động ≤$kCustomerActiveMaxDays ngày'
        ' · nguội ≤$kCustomerCoolingMaxDays'
        ' · rủi ro ≤$kCustomerAtRiskMaxDays'
        ' · rời bỏ >$kCustomerAtRiskMaxDays',
      )
      ..writeln(
        '- Ưu tiên nhịp mua riêng của từng khách khi có (≥2 đơn): '
        '${capabilityDecimal(kCustomerCoolingGapRatio, decimals: 1)}× / '
        '${capabilityDecimal(kCustomerAtRiskGapRatio, decimals: 1)}× / '
        '${capabilityDecimal(kCustomerChurnedGapRatio, decimals: 1)}× khoảng '
        'cách mua trung vị, sàn '
        '${capabilityDecimal(kCustomerCadenceFloorDays, decimals: 0)} ngày.',
      )
      ..writeln(
        '- Khách hàng: $totalCustomers'
        ' · đã từng mua: $purchasingCustomers'
        ' · chưa mua: ${stage(CustomerLifecycleStage.neverPurchased)}',
      )
      ..writeln(
        '- Vòng đời: '
        '${[for (final s in CustomerLifecycleStage.values) '${s.labelVi} ${stage(s)}'].join(' · ')}',
      )
      ..writeln(
        '- Mới (đơn đầu ≤$kCustomerNewMaxDays ngày): $newCount'
        ' · quay lại (≥$kCustomerReturningMinOrders đơn): $returningCount'
        ' · ứng viên win-back: $winBackCandidateCount/$lapsedCount khách đã lapse',
      )
      ..writeln(
        '- Phân bố recency: '
        '${[for (final b in CustomerRecencyBand.values) '${b.labelVi} ${recency(b)}'].join(' · ')}',
      )
      ..writeln(
        '- Dải chi tiêu trọn đời (cắt tại '
        '${monetaryCutoffs.map(TongtaiFormatters.vnd).join(' · ')}): '
        '${monetaryBandCounts.join(' · ')} khách (thấp → cao)',
      )
      ..write(
        '- Dải tần suất mua (cắt tại '
        '${frequencyCutoffs.map((c) => capabilityDecimal(c, decimals: 1)).join(' · ')} đơn): '
        '${frequencyBandCounts.join(' · ')} khách (thấp → cao)',
      );
    return buffer.toString();
  }

  @override
  String toString() =>
      'CustomerCapabilityContext(v$version, $totalCustomers customers, '
      'lapsed: $lapsedCount, winBack: $winBackCandidateCount)';
}

/// The Customer capability's **on-demand** context provider (WTM-154).
///
/// Same [CapabilityContextProvider] seam as every capability (WTM-131), but
/// deliberately **not** wired into `BusinessContextService`: per-customer RFM is
/// exactly the heavy analysis ADR-TON-016 keeps off the aggregate root. It reads
/// both repositories because a customer's lifecycle is a fact about their
/// orders, not about their directory row.
class CustomerCapabilityProvider
    implements CapabilityContextProvider<CustomerCapabilityContext> {
  const CustomerCapabilityProvider(
    this._customers,
    this._orders, {
    this.clock = DateTime.now,
    this.windowMonths = kCustomerCapabilityWindowMonths,
  });

  final CustomerRepository _customers;
  final OrderRepository _orders;

  /// The only clock in the chain — read once per [load], never inside the
  /// computation.
  final DateTime Function() clock;

  final int windowMonths;

  @override
  Future<CustomerCapabilityContext> load() async =>
      CustomerCapabilityContext.from(
        customers: await _customers.loadAll(),
        orders: await _orders.loadAll(),
        now: clock(),
        windowMonths: windowMonths,
      );
}
