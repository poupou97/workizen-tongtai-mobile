# CLAUDE.md — Tổng Tài Mobile

Working agreement for AI-assisted development on this repository.

## ⭐ New agent? Read IN THIS ORDER (bắt buộc)

1. `docs/00-START-HERE/AGENT-ONBOARDING.md`
2. `docs/00-START-HERE/PRODUCT-CONTEXT.md`
3. `docs/02-ARCHITECTURE/CURRENT-STATE-ARCHITECTURE.md`
4. `docs/03-DECISIONS/ADR-INDEX.md`
5. `docs/00-START-HERE/CURRENT-STATUS.md`
6. `.claude/README.md`

Everything you need is in THIS repo — no Hub repo, no old conversations.
`.claude`/memory is operating context only; decisions live version-controlled
under `docs/` (see `docs/00-START-HERE/SOURCE-OF-TRUTH.md`).

## What this is

**Tổng Tài** ("I Like a Boss") — an **AI-First Business OS** for SME
entrepreneurs in Vietnam. Flutter, Android-first + iOS. applicationId
`com.workizen.tongtai`. Split from the Workizen Hub repo on 2026-07-22
(ADR-TON-001); full pre-split history lives in
`workizen-ai-personal-wallet` branch `feat/tongtai`.

8 capabilities: Producer (sourcing) · Inventory · Consumer (CDP/CRM) ·
Finance · Reports · Business Journey (goal orchestration) · Opportunity Hub ·
AI Copilot. The Product Design Bible in `docs/` is the spec — screens,
domain model, AI matrix, ADRs.

## Non-negotiable principles (inherited from the Workizen ecosystem)

1. **Local First** — all business data on-device (SQLite/Drift); works offline.
   Phase 2 has no backend and no sync (D-5, 2026-07-23).
2. **Workizen AI** — users interact only with "Workizen AI"; an AI Router picks
   the provider (Gemini/xAI/Claude/OpenRouter/Cerebras/Ollama — ADR-TON-006).
   Phase 2 modes: BYOK (user keys leave the device only in the Authorization
   header of a direct provider call) + Local (Ollama); Managed waits for
   Phase 3.
3. **Privacy by Default** — no account required (D-4); no ad SDKs, marketing
   tracking, profiling, or personalized ads — ever. Operational telemetry
   (Firebase Analytics + Crashlytics, closed-beta quality only) is allowed per
   D-7/ADR-TON-005.
4. **Practical over ambitious** — ship the boring, working thing.

## Architecture decisions in force

- **ADR-TON-001** — single-app product (split from Hub); Platform/Product layer
  separation; every module must remain extractable.
- **ADR-TON-002** — **Riverpod** is the only DI/state framework (never GetIt).
- SQLite + Drift, schema versioned in `lib/database/migrations/`;
  FTS5 search (đ-aware tokenizer) in `lib/database/search/`.
- `lib/features/tongtai/` = product code · `lib/core/` = platform seams.
- **ADR-TON-014** — sample data seed vào production repos (prefix `sample-`);
  KHÔNG parallel demo state.
- **ADR-TON-016** — **Capability Context · Rule Twin · AI Runtime Boundary**:
  BusinessContext CHỈ giữ summary nhẹ (cấm God Object); phân tích chuyên sâu =
  Capability Context độc lập tải on-demand; `Repository → Aggregation Services →
  Capability Context → BusinessContext (summary) → Rule Twin → AI Router → AI →
  (Tool Runtime optional) → Human`. **Rule Twin authoritative** (chạy không cần
  AI/mạng/key, cấm bịa số khi thiếu dữ liệu); **AI chỉ giải thích**. Công thức
  thêm capability: `docs/02-ARCHITECTURE/CAPABILITY-BIBLE.md`.
- **ADR-TON-018** — **`.ttbk` v2 + Restore = Replace**: backup là snapshot
  **toàn miền, lossless, có version** của cả 6 repository; enum lưu bằng **mã
  canonical**, cấm nhãn hiển thị; SHA-256 **bắt buộc** (chống hỏng, KHÔNG phải
  chống giả mạo); record counts nằm **trong** payload. Restore **chỉ Replace**
  (Merge là capability riêng): validate toàn bộ → preview → xác nhận phá huỷ →
  **tạo + verify bản sao lưu an toàn** → **một transaction** → verify → commit.
  Không verify được bản an toàn ⇒ **không xoá gì**. CSV export vẫn chỉ để Excel.
- **ADR-TON-017** — **Error-Handling Seam**: mọi màn biểu diễn trạng thái bằng
  `ScreenState` (loading·ready·empty·insufficient·refreshing·failed) và lỗi bằng
  `TongtaiFailure` (kind·code·detail). Đọc qua `ScreenDataController`, ghi qua
  `runTongtaiAction`, render qua `TongtaiScreenData`. **Cấm trong `ui/`:** catch
  thủ công · spinner vô hạn tự chế · `FutureBuilder`/`AsyncValue.when` (không có
  trạng thái *stale*). Refresh lỗi **giữ dữ liệu cũ**. `detail` chỉ hiện trên
  máy người dùng — telemetry chỉ `kind`+`code`+`screen`.
- **ADR-TON-015** — **UI Implementation Maturity Model (L0–L4)** + **One Data
  Path**: `Repository → Context Provider → BusinessContext → Screen`. Cấm
  parallel cache, hardcode business data, mỗi màn tự tính summary. Contract
  bắt buộc: **Summary Count == Domain Visible Records**. Level trong Jira PHẢI
  == level thật trong code (ma trận:
  `docs/02-ARCHITECTURE/UI-IMPLEMENTATION-LEVELS.md`).

## Development workflow (Evidence-Driven Runtime)

This repo is developed by the AI Workforce Runtime
(`workizen-ai-workforce-runtime`): Developer agent → EvidenceCollector →
Judge → Supervisor → Jira. **Verdicts come from evidence (flutter analyze +
flutter test run by the Runtime), never from an agent's report.** No placebo
tests (`expect(true, true)` is auto-rejected). Model policy: Opus 4.8 default,
Fable 5 for hard tasks/retries.

- Jira: project **WTM** · Confluence space **workizento** (see `.workforce.json`).
- Run a story: `./handover.sh WTM-XX` (always-on host recommended).

## Gates

- **Autonomous merge (Founder-authorized 2026-07-29):** Tổng Tài is an
  independent repo and the AI has **full Git rights, including merging its own
  PRs to `main`**, once **CI is green · no regression · no Founder Gate touched ·
  no Accepted ADR violated**. Do **not** pause at routine Git/PR/merge steps —
  self-merge and continue to the next backlog item. Then move the story to Jira
  **Done**. (This repo-local grant deviates from the ecosystem "gates are
  Founder-only" default in the root workspace `CLAUDE.md`; it applies to this
  repo only, by the Founder's decision.)
- **Founder Gates (the only reasons to stop)** — surface and wait for these,
  nothing less: product vision/direction · ADR conflict · multiple genuinely
  valid directions · security/privacy/legal (incl. the **G-3** Workizen-AI /
  BYOK / privacy red-line) · genuinely blocked.
- **Release / tag / deploy to production remain Founder-only.**

## Conventions

- Bilingual docs (EN + VI) — nhưng **UI chỉ một locale**, mọi chuỗi qua
  `AppStrings` key (ADR-TON-007). Conventional commits with the WTM key.
- Tests are real integration/widget tests; every feature ships with them
  (~992 passing — keep it green).
- **Story có UI phải khai `IMPLEMENTATION_LEVEL=L0..L4` trong Jira** và cập
  nhật ma trận cùng PR. Cấm đóng story ở level cao hơn thực tế.
- **Stable test IDs** `<screen>-<role>` cho mọi màn L2+; test hành vi tìm bằng
  Key, không bằng text hiển thị.
- **Bug mới ⇒ thêm Pattern vào `docs/04-DELIVERY/TESTING-BIBLE.md`**
  (Root-Cause · Regression · Test Pattern · Prevention Rule), không chỉ thêm
  test case. Đọc file này trước khi viết test cho lỗi tương tự.
## ⛔ Jira visibility — luật bắt buộc cho MỌI agent (Founder 2026-08-01)

Founder đã phải hỏi **bốn lần** *"sao không thấy task thay đổi trên Jira"*. Mỗi lần nguyên
nhân một khác, nên đây là **cả bốn**, không phải một lời nhắc chung chung.

### Bốn cổng, làm đủ cả bốn

**1. Việc đang chạy phải có một STORY, không phải Epic.**
Bảng Kanban WTM **chỉ hiện Story/Task thành thẻ**. Epic là vùng chứa và **không bao giờ hiện
thành thẻ** — tạo Epic rồi tưởng xong là Founder vẫn nhìn thấy bảng trống.

**2. Tạo issue + transition TRƯỚC KHI bắt đầu hiểu vấn đề, không phải trước khi code.**
`START` = lúc issue **rời `Ideas`** sang **bất kỳ cột làm việc nào** (`ANALYSIS` · `Ready` ·
`In Progress`). **Audit, nghiên cứu, đối chiếu Concept đều tính giờ.** Trigger "trước khi
code" là sai vì audit không giống code nên trigger không bao giờ chạy.
`END` = lúc chuyển **`Done`**.

**3. Mỗi mục todo đại diện cho việc thật phải mang một mã WTM.**
Mục nào không có mã ⇒ chưa tạo issue ⇒ dừng lại tạo trước. Todo list được cập nhật vài phút
một lần trong lúc làm — đó là chỗ duy nhất có nhịp đủ dày để làm cổng chặn. Memory và file
tài liệu chỉ được đọc lúc mở phiên nên **không** chặn được gì.

**4. Kiểm chứng bằng thứ Founder NHÌN THẤY, không bằng phản hồi API.**
`{"success": true}` không có nghĩa là bảng đã đổi. Cùng họ với bài học *suite test xanh không
thay thế được mắt nhìn trên thiết bị*.

### Vì sao viết rule mạnh hơn không sửa được

Mọi việc agent làm đều đặn đều có **cổng cơ học**: CI đỏ khi merge code hỏng · analyzer đỏ khi
commit sai · test governance đỏ khi đổi schema. **Board Jira đứng im thì KHÔNG có gì thất
bại** — người phát hiện duy nhất là Founder. Đó là lý do cổng phải nằm ở todo list (mục 3),
chứ không nằm ở một đoạn văn hay hơn.

### Kèm theo mỗi story

`addWorklogToJiraIssue` (`timeSpent` + `started` = mốc START) trước khi chuyển `Done`.
Transition ID dự án WTM: `4`=ANALYSIS · `2`=Ready · `21`=In Progress · `31`=Code Review ·
`3`=QA · `41`=Done.

⚠️ **Sửa file này xong thì COMMIT NGAY.** Bản trước của luật này bị mất vì sửa trên nhánh
feature rồi `git reset --hard` lúc đổi nhánh — nên suốt nhiều giờ không agent nào đọc được nó,
trong khi tôi đã báo với Founder là "đã ghi rồi".

- **Story chạm native/gradle/Firebase**: bắt buộc smoke-launch bản **release**
  trên máy thật (`adb logcat -b crash` rỗng) trước khi coi là xong.
