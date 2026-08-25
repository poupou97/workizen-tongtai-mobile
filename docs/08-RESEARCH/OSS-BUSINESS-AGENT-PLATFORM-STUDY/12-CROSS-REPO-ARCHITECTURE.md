# 12 · Cross-Repo Architecture — năm repo, năm tầng, và chỗ Workizen đứng

> WTM-453 (Epic WTM-447) · 2026-08-25 · Tổng hợp từ 02–11. Mỗi khẳng định về
> một repo đều đã có evidence FILE→SYMBOL trong file study tương ứng — file này
> không lặp lại evidence, chỉ ghép hình.

## 1. Bản đồ — mỗi repo trả lời MỘT câu hỏi

```mermaid
%% Nhãn: SOURCE EVIDENCE (5 repo, đã trace) + CURRENT (khối Workizen)
flowchart TB
    subgraph OSS["5 REPO — mỗi repo một tầng, KHÔNG ghép thành mega-platform"]
        E["ERPNext<br/>DOMAIN KNOWLEDGE<br/><i>sổ bất biến · derive-không-cộng-dồn</i>"]
        R["Relaticle<br/>AGENT-TOOL BOUNDARY<br/><i>MCP · schema-as-data · proposal</i>"]
        T["Trigger.dev<br/>DURABLE RUNTIME<br/><i>state-as-log · fencing · deadman</i>"]
        P["Plane<br/>WORK MANAGEMENT<br/><i>intake triage · 2 tầng history</i>"]
        L["Lago<br/>METERING / BILLING<br/><i>meter ≠ pricing · wallet 2 nguồn</i>"]
    end
    subgraph WZ["WORKIZEN — AI Business / Delivery layer (CURRENT)"]
        TT["Tổng Tài<br/>local-first Business OS"]
        WF["AI-WF Runtime<br/>evidence-driven agents"]
        AT["AI Teams<br/>SaaS đội agent"]
    end
    E -.->|"invariant kế toán/kho"| TT
    R -.->|"luật Tool Runtime tương lai"| TT
    T -.->|"3 cơ chế durability"| WF
    P -.->|"triage + tooling Jira"| WF
    L -.->|"domain billing"| AT
```

Điều bản đồ này nói: **không repo nào cùng tầng với Workizen.** ERPNext là hệ
ghi sổ; Relaticle là CRM có cửa cho agent; Trigger.dev là hạ tầng chạy job;
Plane là bảng việc; Lago là máy tính tiền. Workizen là **tầng ra quyết định
kinh doanh bằng AI trên dữ liệu của chính người bán** — tầng đó không repo nào
trong năm cái làm. Vì thế mọi verdict đều dừng ở LEARN/ADAPT: không có gì để
"thay thế", chỉ có invariant để học.

## 2. Ba xác nhận độc lập cho kiến trúc hiện tại

Ba quyết định Workizen từng chọn bằng lý lẽ, nay có code của người khác làm chứng:

| Quyết định Workizen | Ai xác nhận | Bằng cách nào |
|---|---|---|
| **Cửa ghi duy nhất** (BusinessAction, WTM-300) | Relaticle — bằng **phản ví dụ** | Họ có HAI kỷ luật ghi: MCP ghi thẳng không duyệt, Chat qua proposal. Đúng hình dạng lỗi WTM-300 tồn tại để chặn |
| **Derive, không cộng dồn** (WTM-297) | ERPNext — bằng **đồng dạng** | `per_received`/`per_billed`/`outstanding_amount` đều recompute từ sổ bằng SQL SUM; không counter nào tự cộng |
| **Catalog là dữ liệu, AI chỉ hứa cột verified** (ADR-TON-024 §3) | Relaticle — bằng **đồng dạng** | Schema resource per-team sinh từ DB, tool bị ép "MUST read schema first", code lạ reject |

## 3. Ba lỗ hổng chỉ lộ khi đặt cạnh code người khác

1. **`products.totalStock` là số mutable không có sự kiện nguồn** — miền duy
   nhất của Tổng Tài chưa theo kỷ luật "số có chủ + dựng lại được". Orders
   không trừ kho; tổng variant không ràng buộc tổng cha. (ERPNext: mọi thay
   đổi tồn là một `Stock Ledger Entry` bất biến.)
2. **AI-WF: hai khoá ở hai plane không thấy nhau** — bash `mkdir`-lock và TS
   pid-lock độc lập; một supervisor bash + một run TS có thể cùng cầm một
   project. (Trigger.dev: không lock nào cả — fencing bằng `snapshotId` trên
   từng lệnh.)
3. **Crash giữa attempt vô hình từ Jira** — AI-WF không có execution-state
   log; `claude -p` bị kill để lại đúng những gì đã commit vào git, không dấu
   vết trạng thái. (Trigger.dev: snapshot append-only, RECONCILE là phép đọc.)

## 4. Hình đích đề xuất — PROPOSAL, chờ Founder

```mermaid
%% Nhãn: PROPOSAL — chưa quyết, chưa cài. Từ doc 07 §5 + doc 03 §6.
flowchart LR
    subgraph AIWF["AI-WF: MỘT execution plane (PROPOSAL)"]
        J["Jira = queue<br/>(giữ — luật visibility)"] --> S["Supervisor TS duy nhất<br/>khoá theo work-order + fencing"]
        S --> X["Executor claude -p"]
        X --> EV["Evidence spine (giữ nguyên)"]
        S -. "ghi mỗi transition" .-> LOG["Execution-state log<br/>(JSON append-only)"]
        WD["Watchdog ngoài tiến trình<br/>(cron đọc status.json)"] -. "phát hiện chết im lặng" .-> S
    end
    subgraph TT2["Tổng Tài (PROPOSAL nhỏ)"]
        OI["OrderItem += costPrice snapshot<br/>(giá vốn theo thời điểm)"]
        MV["Sự kiện tồn kho<br/>(cần ADR riêng — DESIGN ONLY)"]
    end
```

Ranh giới của đề xuất: **không migrate sang framework nào** — ba cơ chế trên
xây bằng file JSON + một dòng cron; phần Workizen-specific (evidence judge ·
Jira-queue · device preflight · safe-git) giữ nguyên vì không repo nào có.
