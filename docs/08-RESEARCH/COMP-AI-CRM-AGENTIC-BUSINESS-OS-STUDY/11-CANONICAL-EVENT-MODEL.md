# 11 · Canonical Event — giữ ở trạng thái HYPOTHESIS

> **Founder chỉ đạo 2026-08-08:** không mở rộng kiến trúc quanh `CanonicalEvent` cho tới khi có **≥2 producer hoặc ≥2 consumer thật**.

## Source nói gì: COMP AI **không có tầng event**, và họ đúng

Không bảng event nghiệp vụ nào trong 40 migration. Thay vào đó `AgentTriggerService` có phương thức **hình dạng domain** tiêm vào 7+ service:

```
mailbox-sync ──┐
calendar-sync ─┤
contacts ──────┼──► agent.contactCreated(contactId, reason) ──► agentTask
workspace ─────┤
backfill ──────┘
```

Một bước. Không normalization, không bus.

## Vì sao điều đó KHÔNG chứng minh Tổng Tài không cần

Biến quyết định là **số dạng nguồn × số bên đọc**:

| | COMP AI | Tổng Tài (dự kiến) |
|---|---|---|
| Dạng nguồn | thực chất 1 (Google) | 10+ |
| Bên đọc một tín hiệu | **1** (tạo task) | Business Context · Rule Twin · Agent · Journey · Reports |
| Tích | **1 × 1** | 10 × 5 |

Với 1×1, bảng event là **ghi-một-lần-đọc-một-lần** — thuần chi phí. Họ không làm là đúng.

## Nhưng phải nói thẳng về chính chúng ta

`CanonicalEvent` của Tổng Tài (WTM-294) hiện có:

- **0 producer** — chưa connector nào emit
- **0 consumer** — chưa gì đọc
- **0 bảng** — không persist

⇒ **Ngay lúc này nó đúng là một abstraction chưa có người đọc.** Nó là một khoản đặt cược vào tương lai, và cược chỉ hợp lệ nếu connector thứ hai hạ cánh sớm.

Điều **cứu** nó khỏi bị gọi là over-engineering: chi phí đang gần bằng không. Một file `canonical_event.dart`, không schema, không migration, không đường ghi. Nếu bỏ thì mất một buổi; nếu giữ mà không dùng thì cũng chỉ tốn một file.

## Điều kiện tốt nghiệp khỏi hypothesis

`CanonicalEvent` được phép mở rộng khi **một trong hai** điều sau là thật:

| Điều kiện | Nghĩa cụ thể |
|---|---|
| **≥2 producer** | connector thứ hai (Telegram) emit event, và GitHub connector cũng emit — cùng từ vựng |
| **≥2 consumer** | ít nhất hai trong {Business Context, Rule Twin, Agent, Journey, Reports} đọc cùng một event |

Cho tới lúc đó: **không bảng, không repository, không migration, không UI**. Giữ nguyên như hôm nay.

## Nếu tốt nghiệp — điều source dạy về hình dạng

COMP AI không có event, nhưng `agentAction` cho thấy họ hiểu vấn đề tương đương ở phía output. Ba thứ đáng bê sang:

**1. `idempotencyKey` + `requestHash`.** Cùng key mà payload khác ⇒ **ném lỗi**, không ghi đè im lặng. `CanonicalEvent.dedupeKey` hiện chỉ có key, không có hash. Thiếu hash thì hai sự việc khác nhau lỡ trùng key sẽ lặng lẽ nuốt nhau.

**2. Trạng thái, không chỉ dữ liệu.** `agentAction.status` cho biết sự việc đã được xử lý chưa. Một event **đã nhận nhưng chưa tiêu hoá** khác một event đã xong — `CanonicalEvent` hiện không phân biệt.

**3. Con trỏ ngược tới kết quả.** `agentAction.externalId` trỏ tới thứ đã tạo ra. Event nên trỏ được tới `ProposedChange`/`BusinessAction` mà nó sinh ra.

## Điều KHÔNG nên làm nếu tốt nghiệp

- **Đừng dựng bus.** COMP AI chứng minh bảng + cron là đủ ở quy mô này.
- **Đừng lưu mọi tín hiệu.** Không phải mọi thứ nền tảng có đều đáng thành sự kiện — GitHub `tag` và PR-đóng-không-merge bị **cố ý bỏ qua** ở connector đầu tiên, và WTM-294 đã cài đúng phân biệt đó (`ignored` khác `unknown`).
- **Đừng để event thành nguồn sự thật thứ hai.** Event ghi lại *việc đã xảy ra ở nền tảng*; số liệu nghiệp vụ vẫn do Rule Twin tính (ADR-TON-016).
