# ADR-TON-001: App Separation — Single-app + Flavors

**Status:** ✅ ACCEPTED (Founder, 2026-07-16)
**Decides:** OPEN-DECISIONS D-1
**Supersedes:** the doc-level recommendation "Multi-Package Monorepo" in earlier drafts

## Context / Bối cảnh

Tổng Tài is bootstrapped inside the Hub repo (`workizen-ai-personal-wallet`) to
reuse the platform (storage, AI client, design system ~80%). Phase-2 autonomous
development has produced 20+ verified stories under `mobile/app/lib/features/tongtai/`
and `lib/database/`. D-1 asked how the two products should be separated:
(1) single app + build flavors, (2) multi-package monorepo, (3) separate repos.

## Decision / Quyết định

**Option 1 — Single Flutter app + Flavors** (one codebase; `hub` / `tongtai`
build flavors), with three binding architecture requirements from the Founder:

1. **Platform Layer vs Product Layer must stay clearly separated.**
2. **Tổng Tài business logic must NOT depend directly on Hub feature code** —
   only on the shared platform layer.
3. **Every new module must be written to be extractable** into its own package
   or repository later (no hidden cross-product coupling).

**Long-term roadmap:** Phase 1–2 ship as single-app + flavors. At ~100k+ users
or a dedicated team, re-evaluate Multi-Package Monorepo. A separate repository
is considered only when release lifecycles genuinely need to split.

## Rationale / Lý do

- Fastest path to a shippable MVP; no premature optimization.
- Maximum reuse of the proven Hub platform (SQLite/Drift, BYOK AI, tokens).
- The 20+ stories already built follow exactly this shape — zero rework.
- The extractability requirement keeps options 2/3 open at low future cost.

## Consequences / Hệ quả

- ✅ Existing `lib/features/tongtai/` + `lib/database/` structure is confirmed.
- 🔜 A `tongtai` build flavor (Android `productFlavors` + iOS scheme) is needed
  before Tổng Tài ships as its own app (own applicationId, per D-2).
- 📏 Review rule for new code: imports from `features/tongtai/**` must not reach
  into other `features/*` (Hub) — only `core/**` / shared platform code.
- 🔁 `MIGRATION-TO-SEPARATE-REPO.md` stays as the playbook for the ~100k trigger.
