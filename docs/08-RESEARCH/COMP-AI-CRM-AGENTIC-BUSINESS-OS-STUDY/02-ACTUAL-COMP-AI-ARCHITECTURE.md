# 02 · Kiến trúc THẬT của COMP AI

> **CURRENT — dựng lại từ source, không phải từ README.**

## Diagram 1 — kiến trúc thật (CURRENT · EVIDENCE)

```mermaid
flowchart TB
    subgraph ext["Nguồn ngoài"]
        G["Gmail / Google Calendar"]
        V["Vendor: RapidAPI · Perplexity · Context.dev"]
    end

    subgraph api["apps/api — NestJS"]
        SYNC["mailbox-match · calendar-sync"]
        DOM["contacts · workspace · backfill · conversations"]
        TRIG["AgentTriggerService<br/><i>phương thức hình dạng domain</i>"]
    end

    subgraph pg[("PostgreSQL")]
        TASK[("agentTask<br/>lease · attempts · dueAt")]
        FACT[("contactFact<br/>PROPOSED·APPLIED<br/>SUPERSEDED·DISMISSED")]
        ACT[("agentAction<br/>idempotencyKey")]
        DOMT[("contact · company · deal<br/>activity · fieldValue")]
    end

    subgraph agent["apps/agent — eve runtime"]
        CRON["schedule: cron mỗi phút"]
        LANE["drainAll → visible lane | research lane"]
        SESS["Agent session<br/>tối đa 30 ngày"]
        TOOLS["42 tool"]
        SBX["sandbox<br/>networkPolicy: deny-all"]
    end

    G --> SYNC --> TRIG
    DOM --> TRIG
    TRIG -->|"tạo thẳng, KHÔNG qua event"| TASK
    CRON --> LANE
    LANE -->|"claimDue: FOR UPDATE SKIP LOCKED"| TASK
    LANE --> SESS
    SESS --> TOOLS
    TOOLS --> SBX
    TOOLS -->|"record_fact"| FACT
    TOOLS -->|"web_search · research_*"| V
    FACT -->|"chỉ khi VERIFIED"| DOMT
    TOOLS -->|"set_field_value · portrait<br/><b>ghi thẳng</b>"| DOMT
    ACT -->|"1 transaction"| DOMT
    TOOLS -.->|"schedule_recheck"| TASK

    style TRIG fill:#4a5568,color:#fff
    style FACT fill:#2d5016,color:#fff
    style ACT fill:#2d5016,color:#fff
```

## Đọc diagram này thế nào

**Ba mũi tên vào `DOMT` là ba kỷ luật khác nhau** — đó là kết luận trung tâm của toàn bộ nghiên cứu:

| Mũi tên | Qua đâu | Evidence | Lifecycle | Idempotency |
|---|---|---|---|---|
| `FACT → DOMT` | ledger | ✅ | ✅ | dedup theo giá trị |
| `TOOLS → DOMT` | ghi thẳng | ❌ | ❌ | ❌ |
| `ACT → DOMT` | agentAction | ❌ | ✅ | ✅ |

Không đường nào có cả ba. Xem `12-CANONICAL-ACTION-MODEL.md`.

## Bốn quyết định nền

**1. Postgres là runtime.** Không Kafka, không Temporal, không hàng đợi ngoài. Hàng đợi là một bảng; lịch là cron; đồng thời là `FOR UPDATE SKIP LOCKED`. Toàn bộ tính bền vững nằm trong 174 dòng `lib/tasks.ts`.

**2. Không có tầng event.** `AgentTriggerService` có phương thức tên theo **việc trong miền** (`contactCreated`, `companyRequested`, `fieldBackfill`) và mỗi cái tạo thẳng một `agentTask`. Tín hiệu ngoài đi một bước tới việc.

**3. Model không chạm dữ liệu, tool chạm.** Tools chạy in-process với toàn quyền DB. Sandbox (nơi model chạy code) **không có mạng**. Ranh giới không phải DB — ranh giới là **tập tool**.

**4. Kiến thức của agent nằm trong file skill, không trong code.** `agent/skills/*.md` chứa quy trình khớp danh tính, cách chọn evidence kind, ranh giới dữ liệu. Chúng là **tài liệu thi hành được** — model đọc chúng lúc chạy.

## Chỗ README nói khác code

Không phát hiện mâu thuẫn lớn. Nhưng README **không nhắc** ba điều quan trọng nhất: `FOR UPDATE SKIP LOCKED`, việc agent không được khai confidence, và việc `set_field_value` bỏ qua ledger. Cả ba chỉ thấy khi đọc code — đúng lý do §5 của Task Order tồn tại.
