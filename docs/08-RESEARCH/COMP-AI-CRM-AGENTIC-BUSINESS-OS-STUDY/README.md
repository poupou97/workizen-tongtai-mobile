# COMP AI CRM → Tổng Tài Agentic Business OS Study

> **WTM-296 · P0 RESEARCH · 2026-08-08**
> Source: `github.com/trycompai/crm` @ `c26a08d` · branch `release` · **MIT**
> ⛔ **KHÔNG IMPLEMENT** trước Founder + GPT review.

## READ FIRST — đọc theo đúng thứ tự này

| # | File | Vì sao đọc |
|---|---|---|
| 1 | **`00-EXECUTIVE-SUMMARY.md`** | ba câu trả lời quan trọng nhất |
| 2 | `03-DURABLE-AGENT.md` | vòng lặp bền vững — cơ chế thật, 174 dòng |
| 3 | `04-EVIDENCE-BUSINESS-TRUTH.md` | **phần P0** — evidence → fact |
| 4 | `09-COMP-AI-VS-TONGTAI.md` | đối chiếu theo *vấn đề kiến trúc*, không theo feature |
| 5 | `17-TARGET-ARCHITECTURE.md` | kiến trúc đề xuất *(PROPOSAL)* |
| 6 | `18-ADOPT-ADAPT-REJECT.md` | 14 pattern, mỗi cái kèm lý do |
| 7 | `20-RECOMMENDATIONS.md` | 8 khuyến nghị, xếp theo giá trị/chi phí |
| 8 | **`21-FOUNDER-DECISIONS.md`** | **8 quyết định cần Founder — 4 cái 🔴 chặn mọi implementation** |

`SOURCE-MAP.md` — mọi kết luận trỏ về `file · symbol · dòng`.

## Toàn bộ 21 tài liệu

```
00 Executive Summary          11 Canonical Event Model (HYPOTHESIS)
01 Source Baseline            12 Canonical Action Model
02 Kiến trúc THẬT (◆1)        13 Autonomy Policy
03 Durable Agent (◆2)         14 Orchestration UX (◆8)
04 Evidence → Truth (◆3)      15 Tám luồng end-to-end
05 Identity Resolution (◆4)   16 Workizen Dogfood
06 Tools & Sandbox (◆5)       17 Target Architecture (◆6)
07 Capability Discovery       18 ADOPT / ADAPT / REJECT
08 Skills & Memory            19 Mười bài học
09 COMP AI vs Tổng Tài        20 Khuyến nghị
10 Business Conversation (◆7) 21 Founder Decisions
```

◆ = có diagram. **Tám diagram**, mỗi cái ghi rõ **CURRENT · EVIDENCE** hay **PROPOSAL**. Không trộn.

## Nguyên tắc của bộ nghiên cứu này

**Source code là bằng chứng.** README của COMP AI chỉ dùng để định hướng. Mọi kết luận quan trọng trace tới `file · symbol · call path`. README nói A mà code làm B ⇒ **code thắng**.

Ba điều quan trọng nhất phát hiện được **chỉ khi đọc code**, README không nhắc:
- `FOR UPDATE SKIP LOCKED` trong `claimDue()`
- agent **không được phép** khai confidence
- `set_field_value` bỏ qua hoàn toàn fact ledger

## Trạng thái các đề xuất

| | |
|---|---|
| ✅ Founder đã chấp nhận (2026-08-08) | không tạo `BusinessConversation` · dùng `correlationId` · `BusinessAction` là cửa ghi duy nhất · `ProposedChange` tách riêng · Autonomy Policy tối giản · không runtime mới |
| ⏸ Giữ hypothesis | `CanonicalEvent` — chưa mở rộng cho tới khi có ≥2 producer/consumer thật |
| 🔴 Chờ Founder quyết | D-1 confidence · D-2 ProposedChange · D-3 BusinessAction trước/sau · D-4 durable agent local-first *(doctrine)* |
