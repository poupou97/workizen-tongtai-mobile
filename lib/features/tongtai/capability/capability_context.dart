/// The **Capability Context** layer (ADR-TON-016, Founder directive
/// "Capability-Driven Predictive Foundation", 2026-07-30).
///
/// ```
/// Repository → Aggregation Services → Capability Context → Rule Twin → AI
/// ```
///
/// A Capability Context is the *unit of deep analysis* for one capability
/// (revenue, customer, …). It is loaded **on demand** by the screen or twin that
/// needs it — never folded into `BusinessContext`, which stays a flat snapshot
/// of lightweight per-capability summaries. That separation is the whole point
/// of ADR-TON-016: a new capability adds its own context instead of growing
/// another heavy array on the aggregate root (the God-Object rule).
///
/// Every context is a **read-only value object**: no widgets, no mutation, no
/// repository access of its own. All arithmetic is delegated to
/// `features/tongtai/analytics/` so a number exists in exactly one place
/// (One Data Path, ADR-TON-015 — duplicate aggregation is forbidden).
library;

/// The contract every Capability Context implements.
///
/// ## `promptBlock()` — the AI-facing surface, and its privacy red-line
///
/// Under ADR-TON-016 the AI reads **Capability Context + Rule Twin output**,
/// nothing else. [promptBlock] is therefore the exact text that leaves the
/// device on a BYOK call, and it MUST be free of personal data:
///
/// - **never** a customer name, phone number, email address or raw street
///   address — not even masked;
/// - **never** free-form seller text (notes, tags, order numbers) that can carry
///   a person's identity by accident;
/// - only **aggregates**: counts, totals, averages, ratios, bands and cut-offs.
///
/// The safest way to honour this is structural: a context simply does not carry
/// the PII in the first place (the customer context holds ids + numbers, never
/// names). A test per capability asserts that fixture names and phone numbers
/// cannot be found in the emitted block (privacy by default, D-7/ADR-TON-005).
///
/// ## Honesty rule
///
/// [hasData] must be true only when there is something real to analyse, and
/// [promptBlock] must **say so plainly** when it is false — a block of zeros
/// reads to an LLM exactly like a business that earned nothing, which is a
/// different (and much worse) statement than "no data yet".
abstract class CapabilityContext {
  /// Stable machine name of the capability, e.g. `'revenue'`, `'customer'`.
  String get capability;

  /// Schema version of **this capability context** — independent of
  /// `kBusinessContextVersion`. Bump when the fields or the meaning of a field
  /// change, so a consumer (UI, twin, AI) can tell the shapes apart.
  int get version;

  /// When the context was built — the injected clock's reading, never a
  /// `DateTime.now()` taken mid-computation.
  DateTime get generatedAt;

  /// Whether there is genuinely something to analyse (see the honesty rule).
  bool get hasData;

  /// PII-free text block for the AI layer (see the privacy red-line above).
  String promptBlock();
}

/// The first line of every capability's [CapabilityContext.promptBlock], so all
/// blocks are recognisable and versioned in the same way.
String capabilityPromptHeader(CapabilityContext context) =>
    '# Capability: ${context.capability} (v${context.version})';

/// Formats a fractional change as a signed Vietnamese-style percentage with one
/// decimal: `0.2` → `+20,0%`, `-0.075` → `-7,5%`, `0` → `0,0%`.
///
/// Returns [absent] for `null`, which is what every analytics helper returns
/// when a percentage is genuinely undefined (growth out of a zero month). A
/// fabricated `+∞%`/`0%` would read as a real number to the AI.
String capabilityPercent(double? fraction, {String absent = 'không xác định'}) {
  if (fraction == null) return absent;
  final percent = fraction * 100;
  final sign = percent > 0 ? '+' : '';
  return '$sign${percent.toStringAsFixed(1).replaceAll('.', ',')}%';
}

/// Formats a plain ratio/index with [decimals] decimals and the VN decimal
/// comma (`0.848…` → `0,85`). [absent] is used for `null` — same reasoning as
/// [capabilityPercent].
String capabilityDecimal(
  double? value, {
  int decimals = 2,
  String absent = 'không xác định',
}) => value == null
    ? absent
    : value.toStringAsFixed(decimals).replaceAll('.', ',');
