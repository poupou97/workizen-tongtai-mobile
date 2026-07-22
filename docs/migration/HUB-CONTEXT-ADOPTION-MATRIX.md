# Hub Context Adoption Matrix

Provenance chung: source = user-level agent memory của repo Hub
(`workizen-ai-personal-wallet`), snapshot **2026-07-22**; docs nguồn = Hub repo
commit **`145a5c5`** (`feat/tongtai`). Migration date: 2026-07-22.

| Context | Source | Classification | Đích trong repo này | Chỉnh sửa? |
|---|---|---|---|---|
| Nguyên tắc sản phẩm (local-first/BYOK/privacy) | Hub CLAUDE.md + memory | ADOPT | `01-PRODUCT/PRODUCT-PRINCIPLES.md`, `CLAUDE.md` | Bỏ phần Hub-specific |
| Evidence-driven runtime + bài học WTM-51 | `project_evidence_driven_runtime`, `project_tongtai_pilot_sprint` | ADOPT | `06-GOVERNANCE/AGENT-WORKING-MODE.md`, `04-DELIVERY/TEST-STRATEGY.md` | Tóm gọn |
| Founder gates / git workflow (Contract v2) | `feedback_git_workflow`, `feedback_decision_levels` | ADOPT | `00-START-HERE/WORKING-RULES.md`, `06-GOVERNANCE/APPROVAL-RULES.md` | Đổi ngữ cảnh repo |
| Model policy (Opus 4.8 / Fable 5) | `project_evidence_driven_runtime` | ADOPT | `AGENT-WORKING-MODE.md`, `03-DECISIONS/ADR-INDEX.md` | — |
| Self-planning principle | như trên | ADOPT | `APPROVAL-RULES.md` | — |
| D-1/D-2/DI decisions | memory + `docs/tongtai` | ADOPT | `03-DECISIONS/*` (ADR-TON-001/002, ADR-INDEX) | — |
| Privacy red-line (value ≠ data) | `feedback_privacy_first_saas_guardrail` | ADOPT | `SECURITY-BOUNDARIES.md`, `PRODUCT-PRINCIPLES.md` | — |
| Quality/do-it-right rules | `feedback_quality_over_cheap…`, `feedback_do_it_right…` | ADOPT | `WORKING-RULES.md`, `DEFINITION-OF-DONE.md` | — |
| sharedPreferencesProvider pattern | Hub `mascot_state.dart` @145a5c5 | ADAPT | `lib/core/prefs.dart` | Tách khỏi mascot, doc comment mới |
| "No iOS build in session" | `feedback_no_ios_sim_build_in_session` | ADAPT | `05-OPERATIONS/BUILD-AND-RELEASE.md` | Ghi thành policy build |
| Changelog rule | `feedback_version_changelog_rule` | ADAPT | `BUILD-AND-RELEASE.md` | Áp khi release đầu |
| Store-compliance lessons (4 vòng Apple reject) | `project_appstore_privacy_consent`, `project_ios_appstore_push` | REFERENCE ONLY | `upstream/HUB-UPSTREAM.md` (mục ưu tiên) | Không copy chi tiết |
| Ecosystem SSoT (knowledge-base) | `reference_knowledge_base` | REFERENCE ONLY | `SOURCE-OF-TRUTH.md` | — |
| Toàn bộ Hub product/infra memory | (danh sách trong INVENTORY) | NOT APPLICABLE | — | — |
| Secrets/pointers (`reference_local_secrets`, keys) | — | NOT APPLICABLE | **Không copy** | — |

REQUIRES FOUNDER CONFIRMATION: *(không có mục nào — mọi adoption trên đều nằm
trong quyết định Founder đã ban hành)*.
