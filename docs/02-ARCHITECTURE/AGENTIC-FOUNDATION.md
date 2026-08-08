# Agentic Foundation — năm tầng, và cái gì khoá cái gì

> **Epic WTM-297** · Founder + GPT duyệt 2026-08-08 · nguồn: nghiên cứu
> **WTM-296** (`docs/08-RESEARCH/COMP-AI-CRM-AGENTIC-BUSINESS-OS-STUDY/`).
>
> Trạng thái: **bốn phase xong**, tất cả `L0` — domain + persistence, **chưa
> nối UI**, chưa connector nào ghi vào.

## Chuỗi

```
Evidence → Derived Confidence → ProposedChange → BusinessAction → Durable Agent
                                      ↑                                ↓
                                      └──────── correlationId ─────────┘
```

| Tầng | Ở đâu | Schema | Story |
|---|---|---|---|
| Evidence + Confidence | `consumer/identity_evidence.dart` | — | WTM-298 |
| ProposedChange | `proposal/` | v21 | WTM-299 |
| BusinessAction | `action/` | v22 | WTM-300 |
| Durable Agent | `agent/` | v23 | WTM-301 |

## Năm luật, và **cấu trúc nào** giữ mỗi luật

| Luật | Giữ bằng |
|---|---|
| Confidence **tính**, không khai | `IdentityCandidate` không có trường `confidence`; **đúng một** hàm sinh ra nó |
| Thay đổi do AI có **vòng đời** | bốn cổng trong một **hàm thuần** không chạm DB; **đúng một** chỗ chuyển khỏi `proposed` |
| **Người thắng máy** | cổng 3, chặn trước mọi bằng chứng |
| Mọi side effect qua **một cửa** | `BusinessAction` phủ cả `vendor: internal`; **đúng một** chỗ gọi effect, nằm trong transaction |
| Task **độc lập nơi chạy** | seam không import Flutter; giao thức nhận việc chạy được trong test **thuần Dart** |

## Ba tính chất chống cộng dồn giả (WTM-298)

1. **Cùng `source` ⇒ một quan sát** — thẻ liên hệ cho tên + số + email là *một* lần nhìn
2. **Cùng `EvidenceFamily` ⇒ một tín hiệu** — "tên khớp" và "tên gần giống" là cùng một thuộc tính
3. **`exact` không đạt được bằng cộng dồn** — chỉ đến từ `platformAccountId`

Trọng số rút từ thực tế bán lẻ Việt Nam, **không chép COMP AI**: `phone` 0.55
nhẹ hơn `email` 0.65 *(hai người thật dùng chung số là chuyện phổ biến)*;
`nameExactMatch` chỉ 0.20 *(trùng tên là chuyện thường)*.

## `DISMISSED` không vĩnh viễn cho mọi miền (WTM-299)

| Miền | Xét lại sau |
|---|---|
| `identity` | **không bao giờ** |
| `pricing` · `supplier` · `forecast` · `inventory` | 30 ngày |
| `customerProfile` | 90 ngày |

Cộng một đường cho **mọi miền**: bằng chứng **mạnh hơn** lần bị bỏ qua mở lại
được ngay.

## ⛔ Bảy hành động tuyệt đối không auto (WTM-300)

`finance.transfer_money` · `customer.merge_records` ·
`customer.send_cold_message` · `product.update_price` ·
`inventory.order_above_limit` · `customer.contact_outside_book` ·
`data.overwrite_seller_entered`

**Hằng số trong code kèm assert**, không phải mặc định cấu hình — một mặc định
sửa được bằng một lần bấm nhầm. Duyệt tay vẫn được: cấm `AUTO`, không cấm hẳn.

## Điều kiện execution-location independence (WTM-301)

Bốn phép kiểm, lớp 3 là lớp quyết định:

1. seam **không import Flutter** — `@immutable` lấy từ `meta` khai tường minh
2. không trường nào mang nghĩa mobile, ở **cả model lẫn bảng**
3. ⭐ giao thức nhận việc chạy được trong test **thuần Dart** (`package:test`)
4. **đúng một** chỗ đóng một việc

`flutter_test` **tự dựng binding** nên không chứng minh được gì về worker.
`package:test` thì không — logic chạy được ở đó thì chạy được trên Oracle VM.

⇒ Đổi runner về sau **chỉ đổi runner**: không đổi bảng, không đổi luật.

## Suite governance của Epic

| Suite | Khoá gì |
|---|---|
| `identity_confidence_is_derived_governance_test` | confidence tính, không khai |
| `proposed_change_lifecycle_governance_test` | vòng đời đề xuất |
| `business_action_single_write_boundary_test` | cửa ghi duy nhất |
| `durable_task_is_location_independent_test` | độc lập nơi chạy |
| `agentic_foundation_end_to_end_test` | **năm tầng chạy CÙNG NHAU** |

Bốn suite đầu khoá từng luật; suite thứ năm tồn tại vì **bốn suite xanh không
chứng minh chúng ráp lại được** — mỗi suite dựng dữ liệu riêng và không bao giờ
thấy hàng xóm.

Mỗi suite có **test chống PASS GIẢ**. Không thừa: ba lần trong Epic này một
suite báo động giả ở bản nháp đầu, và một lần một lớp governance xanh oan vì
regex `\bdb\.` không khớp `_db`.

## Cái Epic này **không** làm

- ❌ `BusinessConversation` entity — `correlationId` + projection là đủ
- ❌ memory store / vector DB — trí nhớ là bản ghi nghiệp vụ
- ❌ policy engine — `AutonomyRule` bốn trường
- ❌ Temporal · Kafka · microservices — SQLite + lease là đủ
- ⏸ `CanonicalEvent` giữ **hypothesis**: 0 producer, 0 consumer

## Còn lại

- **UI** — cả năm tầng đang `L0`. Automation Card + màn "chuyện gì đã xảy ra"
  (thiết kế ở `docs/08-RESEARCH/…/14-ORCHESTRATION-UX.md`).
- **Runner** — V1 chạy lúc mở app. Chuyển sang Managed Worker/Oracle VM là
  story riêng và **chỉ đổi runner**.
- **Connector thứ hai (Telegram)** — nền đã đủ chỗ đặt chân.
