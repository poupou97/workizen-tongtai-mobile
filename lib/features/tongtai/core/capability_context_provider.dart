/// The seam each capability implements to contribute its slice of the business
/// snapshot (WTM-131, Founder). One provider per capability; `BusinessContext`
/// aggregates them all. Kept in `core/` so a capability depends on this seam,
/// not on the metrics/context layer that composes it.
///
/// The producer of a slice ([T], typically a small read-only summary) owns its
/// own loading — `BusinessContextService` just composes the results. AI reads
/// only the aggregated `BusinessContext`, never a provider or repository.
abstract interface class CapabilityContextProvider<T> {
  Future<T> load();
}
