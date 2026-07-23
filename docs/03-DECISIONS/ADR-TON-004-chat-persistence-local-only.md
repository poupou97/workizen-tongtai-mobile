# ADR-TON-004: Chat Persistence — Local-Only in MVP

**Status:** 🟡 PROPOSED (agent, 2026-07-22 — awaiting Founder ratification;
implemented per the recommendation, per the self-planning mandate)
**Decides:** how WTM-81's ACs "encryption" and "automatic syncing to cloud
backend" are read against recorded doctrine
**Relates to:** OPEN-DECISIONS D-5 (Backend & Sync) · D-7 (Analytics/Privacy) ·
PRODUCT-CONTEXT ("No backend in MVP") · ADR-TON-002 precedent (spec wording
overridden by recorded conventions)

## Context / Bối cảnh

WTM-81 (Chat Message Persistence) carries two AC phrases that conflict with
recorded doctrine:

1. *"Automatic sync to backend when connection available"* — PRODUCT-CONTEXT
   and PRODUCT-PRINCIPLES state the MVP has **no backend**; D-5's standing
   recommendation is "No Backend (pure local)" with sync revisited in Phase 3.
2. *"stored in SQLite with encryption"* — the database holds 17 tables of
   equally sensitive business data (customers, orders, finance) with **no
   app-layer encryption**; protection relies on the OS app sandbox + device
   encryption, and secrets (BYOK keys) live in `flutter_secure_storage`.
   App-layer DB encryption (SQLCipher) would be a new dependency affecting the
   whole platform layer — an L2/L3 change, not something to smuggle in via one
   story.

Per SOURCE-OF-TRUTH, ADRs and principles outrank Jira story wording, and the
ADR-TON-002 precedent (WTM-60's "GetIt" AC ruled a spec error) applies.

## Decision / Quyết định

1. **Chat messages persist locally only** (Drift/SQLite, new per-message
   `chat_messages_table`, schema v4). **No sync**: chat content is
   deliberately NOT enqueued into the WTM-54 sync outbox — conversations may
   contain the most sensitive business data in the app, and nothing should
   position them to leave the device before D-5 is decided.
2. **Encryption at rest = platform baseline** (OS sandbox + device
   encryption), identical to the other 17 tables. SQLCipher/full-DB
   encryption is recorded below as an option for the Founder, not adopted
   unilaterally.
3. WTM-81's sync AC is **deferred to D-5**; its encryption AC is satisfied at
   the platform baseline with the stronger option left to the Founder.

Tin nhắn chat lưu cục bộ (Drift, bảng mới v4), KHÔNG đưa vào sync outbox —
chờ D-5. Mã hoá = chuẩn nền tảng (sandbox + device encryption) như 17 bảng
còn lại; SQLCipher là option chờ Founder.

## Options considered / Các phương án

| # | Option | Pros | Cons |
|---|---|---|---|
| A ⭐ | Local-only, no outbox, platform-baseline encryption | Consistent with D-5/privacy; zero new deps; Phase-3 sync can add outbox later | Sync AC deferred |
| B | Persist + enqueue to WTM-54 outbox now | Sync-ready day one | Positions chat content to leave the device before D-5 is decided — privacy risk |
| C | Add SQLCipher for chat (and thus the whole DB) | Strongest at-rest story | New platform dependency (L2/L3), perf cost, migration of existing installs — needs Founder |

**Recommendation: A** (implemented). B/C remain open to the Founder; adopting
C later is a platform ADR.

## Consequences / Hệ quả

- ✅ Chat survives restarts; metadata (sender, timestamp, status) is queryable
  and indexed; keyword/date search is a store capability (UI lands in WTM-84).
- ✅ Schema v4 migration follows the WTM-52 stepwise pattern; fresh installs
  get the table via `createAll`.
- 🔜 If the Founder approves a sync backend (D-5), enqueueing chat ops into
  the existing outbox is a small follow-up story.
- 📏 The legacy `ai_chats` JSON-blob table stays untouched (Hub-era shape);
  new chat code reads/writes only `chat_messages_table`.
