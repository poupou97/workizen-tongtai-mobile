# ADR-TON-002: Dependency Injection — Riverpod (not GetIt)

**Status:** ✅ ACCEPTED (Founder, 2026-07-16)
**Decides:** the DI-framework question raised by WTM-60's acceptance criteria

## Context / Bối cảnh

Story WTM-60 (Shared Core Integration) carried an acceptance criterion that
mandated a **GetIt** service locator. The Hub — and all 20+ Tổng Tài stories
built in Phase 2 — standardize on **Riverpod** (`Provider`/`NotifierProvider`/
`FutureProvider`) for DI and state. Introducing GetIt would add a second,
conflicting DI framework and force refactors of working code. The Pilot flagged
this as an architecture decision for the Founder.

## Decision / Quyết định

**Riverpod is the single DI/state framework for Tổng Tài.** The "GetIt" wording
in WTM-60's AC is recorded as a **spec error** (written before the author knew
the Hub convention), not a deliberate choice. WTM-60's remaining ACs are
considered satisfied by the Riverpod-based core (`lib/features/tongtai/core/`,
providers in `lib/features/tongtai/providers/`).

## Rationale / Lý do

- Consistency with the Hub platform (one mental model, one test pattern).
- Zero refactor: every existing Tổng Tài provider already uses Riverpod.
- Riverpod covers both DI and reactive state; GetIt would only duplicate DI.

## Consequences / Hệ quả

- ✅ WTM-60 can close; no GetIt dependency is ever added for Tổng Tài.
- 📏 New Tổng Tài services expose Riverpod providers (see
  `tongtai_identity_provider.dart`, `tongtai_ai_provider.dart` as templates).
- 📏 Story specs that name a concrete framework must be validated against the
  platform conventions before implementation (Runtime brief already pins this).
