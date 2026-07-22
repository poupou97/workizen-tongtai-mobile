# PROJECT_TEMPLATE — Stand up an AI team in a new repo / Dựng đội AI cho repo mới

- **AI Workforce V1** · Bilingual EN/VI. Use when adding a product (Compute / Portal / CodeCanyon / future) per ADR-059 (one repo per product; **Hub PC dropped 2026-07-11** — folded into Compute).

## Copy checklist / Checklist sao chép
EN:
1. Copy the whole `docs/pm/workforce/` folder into the new repo (all 4 role files + COMMANDS + AI_CONTEXT + templates + the V1 FINAL).
2. Edit **PROJECT_CONTEXT.md** only — the `<…>` identity/stack/env fields.
3. Keep the 4 roles, the Kanban workflow, and COMMANDS **unchanged** (they are the ecosystem standard).
4. Founder creates the **Jira project** (UI) with the workflow columns (§Kanban) + the **Confluence product space**.
5. Set branch protection on `main` (PR + Founder merge).

VI:
1. Sao chép cả folder `docs/pm/workforce/` sang repo mới (4 file role + COMMANDS + AI_CONTEXT + template + V1 FINAL).
2. Chỉ sửa **PROJECT_CONTEXT.md** — các trường `<…>` định danh/stack/môi trường.
3. Giữ nguyên 4 role, luồng Kanban, và COMMANDS (đây là chuẩn hệ sinh thái).
4. Founder tạo **Jira project** (UI) với các cột workflow (§Kanban) + **Confluence product space**.
5. Bật branch protection cho `main` (PR + Founder merge).

## The 4 conversations / 4 hội thoại
EN: Create exactly 4 agent conversations for the repo: 📁 Founder · 📁 PM/Tech Lead · 📁 Developer · 📁 QA/Deploy. One project = one AI team.
VI: Tạo đúng 4 hội thoại agent cho repo: 📁 Founder · 📁 PM/Tech Lead · 📁 Developer · 📁 QA/Deploy. Một project = một đội AI.

## Kanban columns to create in Jira / Cột Kanban cần tạo trong Jira
`Ideas · Analysis · Ready · In Progress · Code Review · QA · Done`

## Do not / Không được
EN: Do not add roles · do not fork the workflow · do not change COMMANDS · do not put non-mobile targets in a mobile repo (each target = its own repo, ADR-059).
VI: Không thêm role · không sửa workflow · không đổi COMMANDS · không để target không phải mobile vào repo mobile (mỗi target = repo riêng, ADR-059).
