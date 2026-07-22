# ADR-TON-003: Standalone Repository — repo split

**Status:** ✅ ACCEPTED (Founder, 2026-07-22)
**Supersedes:** the packaging/roadmap portion of ADR-TON-001 ("single-app +
flavors"; a separate repository only at the ~100k-user / release-lifecycle
trigger)
**Keeps in force:** ADR-TON-001's three architecture requirements — clear
Platform/Product layer separation · no dependency on Hub feature code · every
module extractable

## Context / Bối cảnh

ADR-TON-001 (2026-07-16) chose single-app + build flavors inside the Hub repo
and deferred a separate repository until release lifecycles genuinely split.
That trigger arrived earlier than forecast: Tổng Tài is developed autonomously
by the Evidence-Driven Runtime with its own Jira project (WTM), its own gates,
and a Founder-only `main` — a lifecycle already independent of the Hub's.
Keeping two products in one repo made evidence gates, knowledge handoff, and
release control harder, not easier.

## Decision / Quyết định

Tổng Tài ships from its own repository (`workizen-tongtai-mobile`,
applicationId `com.workizen.tongtai`), split from Hub `feat/tongtai`
@ `145a5c5` on 2026-07-22 (tag `split-baseline`). The Hub becomes a
**fetch-only upstream reference** ([../upstream/HUB-UPSTREAM.md](../upstream/HUB-UPSTREAM.md));
no `hub`/`tongtai` build flavors will be added. The flavors roadmap of
ADR-TON-001 is superseded; its three architecture requirements remain binding
unchanged.

Tổng Tài xuất bản từ repo riêng (`workizen-tongtai-mobile`); Hub chỉ còn là
upstream tham chiếu fetch-only. Phần lộ trình "single-app + flavors" của
ADR-TON-001 bị supersede; ba yêu cầu kiến trúc của nó **giữ nguyên hiệu lực**.

## Rationale / Lý do

- Release lifecycles had already split in practice (per-product Jira, gates,
  runtime) — the exact condition ADR-TON-001 named as the trigger.
- A standalone repo gives the simplest evidence-driven gate: `flutter analyze`
  + `flutter test` verdicts cover exactly one product.
- Cold-start review verified the repo is self-sufficient: a new agent needs no
  Hub checkout and no prior conversation.

## Consequences / Hệ quả

- ✅ This repo is the sole source of truth for Tổng Tài code; anything adopted
  from the Hub goes through the manual HUB-UPSTREAM process with provenance
  logged in `HUB-ADOPTION-LOG.md`.
- ✅ Review rule unchanged: `lib/features/tongtai/**` imports only `core/**` /
  `database/**` — never another product's feature code.
- ⚠️ Split regressions are possible where the Hub previously provided wiring —
  WTM-105 (`main.dart` bypassed `TongtaiRootGate`) is the known instance; new
  entry points must ship with app-level tests.
- 📏 `MIGRATION-TO-SEPARATE-REPO.md` (archive) is fulfilled and historical;
  `docs/migration/` records how the split was executed.
