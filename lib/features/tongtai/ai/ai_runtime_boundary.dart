/// **AI Runtime Boundary** (WTM-159, ADR-TON-016 Decision 5).
///
/// ADR-TON-016 draws the standard data path as:
///
/// ```
/// Repository → Aggregation → Capability Context → Rule Twin → AI Router → AI
///                                                                    ↓
///                                          (Tool Runtime — OPTIONAL, chưa triển khai)
///                                                                    ↓
///                                                                  Human
/// ```
///
/// This file is that dotted box, and nothing more. It exists so the seam is
/// **named and typed today** and a future capability can attach without
/// refactoring the AI layer — not because anything is enabled.
///
/// ## What is deliberately NOT here
///
/// - **No tool calling.** No provider request in this app declares tools, and
///   no code path parses a tool call out of a model response.
/// - **No ReAct / no agent loop.** The AI is called exactly once per
///   explanation, with a prompt built by `predictive_ai.dart`, and its answer is
///   returned as text. There is no observe → act → observe cycle.
/// - **No autonomous agent.** Nothing schedules the AI, and nothing lets it
///   choose a next step.
///
/// ## Why enabling it is a Founder decision
///
/// Every AI surface in Tổng Tài is **read-only**: the AI explains what a
/// deterministic Rule Twin already decided (ADR-TON-013, extended to predictions
/// by ADR-TON-016). A Tool Runtime is what turns "explains" into "acts" — it
/// would let a model reach a repository, mutate business data, or execute a
/// workflow on the seller's behalf. That crosses the **G-3 red line** (Workizen
/// AI / BYOK / privacy), so opening it is a Founder Gate: an explicit decision,
/// recorded as an ADR, never an implementation detail an agent adds in passing.
///
/// ## The contract if it is ever opened
///
/// Whoever implements a real runtime must keep the invariants that make the
/// predictive layer trustworthy:
///
/// - the Rule Twin stays authoritative — a tool result may not rewrite a
///   forecast, a risk score or a reason code;
/// - no PII may enter a tool argument that leaves the device (the same red line
///   `CapabilityContext.promptBlock` honours structurally);
/// - every invocation must be surfaced to the seller before it changes data —
///   local-first means the human, not the model, commits the write.
///
/// **Nothing in the app wires an [AiToolRuntime].** `PredictiveAiService` takes
/// no runtime parameter and holds no field of this type; the only implementation
/// shipped is [DisabledAiToolRuntime], which throws.
library;

/// The point where a future Tool Runtime would attach.
///
/// A single, deliberately narrow method: a tool name and its arguments in, a
/// text result out. Narrow because the seam only has to *exist* — every design
/// question (which tools, who approves a write, how results re-enter the prompt)
/// is deferred to the Founder decision that opens it.
///
/// See the library docs above: this interface has exactly one implementation
/// today, and that implementation refuses.
abstract interface class AiToolRuntime {
  /// Would invoke [tool] with [args] and return its textual result.
  ///
  /// Implementations must never be reachable from the predictive AI pipeline
  /// while tool calling is disabled.
  Future<String> invoke(String tool, Map<String, Object?> args);
}

/// The message [DisabledAiToolRuntime] throws with — points at the ADR that
/// froze this seam, so the next reader finds the decision, not just the error.
const String kAiToolRuntimeDisabledMessage =
    'AI tool calling is disabled in Tổng Tài. ADR-TON-016 (Decision 5) designs '
    'the Tool Runtime boundary but deliberately does not implement it: no tool '
    'calling, no ReAct, no autonomous agent. The AI layer is read-only — it '
    'explains a deterministic Rule Twin and nothing else. Enabling a runtime '
    'crosses the G-3 red line (AI acting instead of reading) and is a Founder '
    'decision that must be recorded as a new ADR.';

/// The ONLY implementation today: tool calling is deliberately not enabled.
///
/// Every call throws a [StateError] carrying
/// [kAiToolRuntimeDisabledMessage]. The throw is **synchronous** (the method is
/// not `async`), so an accidental un-awaited call still fails loudly at the call
/// site rather than becoming a silent unhandled future.
///
/// This class is not a stub waiting to be filled in — it is the enforcement of
/// ADR-TON-016 Decision 5. Replacing its body is the Founder Gate, not a
/// refactor.
class DisabledAiToolRuntime implements AiToolRuntime {
  const DisabledAiToolRuntime();

  @override
  Future<String> invoke(String tool, Map<String, Object?> args) =>
      throw StateError(
        '$kAiToolRuntimeDisabledMessage (attempted tool: $tool)',
      );
}
