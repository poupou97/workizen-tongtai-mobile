# 09 — Jira Audit

## Epic + 14 story (đều priority **Highest**, label `predictive-foundation`)

| Key | Story | Kết quả |
|---|---|---|
| **WTM-149** | **[EPIC] Predictive Foundation** | Done · 2h 31m |
| WTM-150 | Historical Data Generator tham số hoá | Done · 27 test |
| WTM-151 | ADR + Capability Context architecture | Done · ADR-TON-016 |
| WTM-152 | Aggregation Services | Done · 52 test |
| WTM-153 | Revenue Capability Context | Done |
| WTM-154 | Customer Capability Context | Done · 35 test (cùng 153) |
| WTM-155 | Rule Twin — Revenue forecast | Done · 92 test |
| WTM-156 | Rule Twin — Customer risk | Done · 16 test |
| WTM-157 | Rule Twin — Business alerts | Done · 22 test |
| WTM-158 | AI Explanation layer | Done · 19 test |
| WTM-159 | AI Runtime Boundary | Done · ratchet |
| WTM-160 | UI Revenue Forecast | Done · 5 test |
| WTM-161 | UI Customer Risk | Done · 5 test |
| WTM-162 | Data sufficiency & edge cases | Done · 19 test + **bug FK 787** |
| WTM-163 | Testing + Privacy + Review Package | Done · 14 test + package |

## Time tracking (theo yêu cầu Founder)

Mỗi issue có **⏱ START** (comment lúc chuyển In Progress) và **⏱ END** +
**worklog** (`started` + `timeSpent`) lúc chuyển Done. Epic mang tổng thời gian.
Bắt đầu **2026-07-30 20:21 ICT** → kết thúc **22:52 ICT**.

## Implementation Level (ADR-TON-015)

| Story | Level | Vì sao |
|---|---|---|
| WTM-160 · WTM-161 | **L2** *(cập nhật từ L0 lúc tạo)* | đọc production provider · không hardcode · không parallel state · có contract/stable keys. **Chưa L3** vì thiếu error handling — cùng gap hệ thống của **WTM-148** |

Ma trận cập nhật: `docs/02-ARCHITECTURE/UI-IMPLEMENTATION-LEVELS.md` (34 màn).

## Story liên quan không thuộc epic

| Key | Liên quan |
|---|---|
| **WTM-148** | Error-handling seam — 2 màn mới cũng nằm trong phạm vi nâng L2→L3 |
| **WTM-93** (Opportunity Scoring AI) · **WTM-78** (Customer Segmentation & AI) | Nay có nền để làm: Capability Context + Rule Twin + AI-explain đã sẵn khuôn |
| **WTM-122** | GIỮ CLOSED — capability này **không** cần migration schema |

## Không reopen story nào

Ba bug đã sửa đều **phát sinh trong chính capability này** (hoặc là nợ kỹ thuật
được dọn kèm), không phải regression của story đã Done trước đó:
FK 787 sinh từ hành vi mới (đơn user trỏ vào khách mẫu, chỉ khả thi sau
ADR-TON-014); billable trùng lặp là nợ cũ đã gom; cache staleness sinh từ chính
provider mới của capability này.
