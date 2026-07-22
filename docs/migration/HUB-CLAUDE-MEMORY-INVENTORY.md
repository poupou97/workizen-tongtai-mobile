# Hub `.claude` / Memory Inventory

Khảo sát 2 nguồn "bộ nhớ" phía Hub (2026-07-22, read-only, không secret nào
được chép vào đây):

## Nguồn 1 — `.claude/` trong repo Hub (2 file)

| File | Nội dung | Phân loại | Lý do |
|---|---|---|---|
| `settings.local.json` | Permission/config máy-local của Claude Code | NOT APPLICABLE | Machine-local, không phải knowledge; repo mới tự sinh khi cần |
| `HANDOFF-from-release2.md` | Handoff nội bộ nhánh release Hub | REFERENCE ONLY | Hub-only context |

## Nguồn 2 — User-level memory của agent (59 file tại `~/.claude/projects/<hub>/memory/`)

Đây mới là kho tri thức thật. Phân loại theo nhóm:

### ✅ ADOPT — luật làm việc dùng chung (→ đã hoà vào `docs/00-START-HERE/WORKING-RULES.md`, `06-GOVERNANCE/*`, `.claude/`)

`feedback_decision_levels` (L1/L2/L3 + Contract v2) · `feedback_git_workflow`
(branch+PR, main Founder-only) · `feedback_do_it_right_pre_launch` ·
`feedback_quality_over_cheap_student_docs` · `feedback_privacy_first_saas_guardrail`
(red line: monetize value ≠ data) · `feedback_agent_brief_methodology` ·
`feedback_research_application_first` · `feedback_no_ios_sim_build_in_session`
(ADAPT: giữ nguyên tắc "không build iOS trong session") ·
`feedback_version_changelog_rule` (ADAPT cho repo này khi release đầu).

### ✅ ADOPT — tri thức dự án Tổng Tài (→ `CURRENT-STATUS`, `AGENT-WORKING-MODE`, reports)

`project_tongtai_governance` · `project_tongtai_phase1c_governance` ·
`project_phase1c_final_governance` · `project_tongtai_pilot_sprint` (bài học
agent bịa kết quả → evidence-driven) · `project_evidence_driven_runtime`
(toàn bộ trạng thái runtime + model policy + split) · `project_repo_structure`
(one repo per product).

### 🔄 ADAPT — bối cảnh Founder (→ tinh thần trong PRODUCT-PRINCIPLES + cách viết doc)

`user_founder_north_star` · `user_personalization_throughline` ·
`user_banking_sa_background` (giải thích ở mức architect, ít jargon).

### 📎 REFERENCE ONLY (không copy, biết là có)

`feedback_no_auto_branch_switch` · `feedback_ui_copy_shell_to_ship_fast` ·
`feedback_draft_first_pay_driven` · `project_founder_time_constraint` ·
`project_appstore_privacy_consent` + `project_ios_appstore_push` (kho kinh
nghiệm store-compliance — dùng khi Tổng Tài lên store, qua upstream review) ·
`reference_knowledge_base` (ecosystem SSoT).

### ❌ NOT APPLICABLE — Hub-only (không mang sang)

Toàn bộ memory sản phẩm Hub: OCR/PDF, DocRAG, Knowledge Engine, Output/Studio,
Studio Video, Conversation Intelligence, Subscription/RevenueCat, Arcade/AI
Games, Gesture Nav, Home IA, Ads policy, AI Router (Hub), AI Communication,
Workflow Engine, Test triage E2E, Store assets pipeline, AI Project Office,
Agent Lab vision, Compute BYOC, Discovery Freeze/Doctrine (Hub), Release
Stabilization (Hub), Pre-OB checklist, iOS26 crash, Feature flags (Hub), Task
numbering (Hub), cùng các `reference_*` hạ tầng Hub (Firebase distribution,
Portal deploy, Keycloak/Caddy, Google Sign-In SHA-1, RevenueCat,
`reference_local_secrets` — pointer tới secret local của Hub, **không copy**).

## Kết quả

Bộ nhớ mới của Tổng Tài: (a) tri thức bền → `docs/` (version-controlled,
travel theo git); (b) memory vận hành cho agent trên máy này → seed tại
`~/.claude/projects/<tongtai-repo>/memory/`; (c) `.claude/README.md` trong repo
giải thích mô hình. Chi tiết provenance: [HUB-CONTEXT-ADOPTION-MATRIX.md](HUB-CONTEXT-ADOPTION-MATRIX.md).
