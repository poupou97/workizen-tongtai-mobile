# ADR-TON-015 — UI Implementation Maturity Model + One Data Path

- **Status:** ✅ ACCEPTED (Founder directive "P0 Process Hardening", 2026-07-30)
- **Context:** post P0 Regression Audit + the Consumer-count field repro
- **Supersedes:** nothing. **Extends:** ADR-TON-010 (Layered DoD),
  ADR-TON-012 (BusinessContext), ADR-TON-014 (sample seeding)
- **Jira:** WTM-147

## Vấn đề (Context)

P0 Regression Audit đóng lại được 3 lớp lỗi, nhưng bug cuối cùng — "Home
Consumer = 1, tab Khách hàng trống" — lọt qua **toàn bộ** 27 suite governance.
Lý do: `TongtaiConsumerScreen` (và `TongtaiProducerScreen`) là **màn thiết kế
tĩnh**: không đọc repository nào, số hardcode 0. Mọi scan trước đó truy tìm
*đường dữ liệu sai* (`.sample()` fallback, literal, parallel demo state) —
không scan nào bắt được màn **không có đường dữ liệu nào cả**.

Nguyên nhân sâu hơn: Jira coi WTM-26 ("Design Consumer Screen") là đã xong và
không ai phân biệt được **"đã có UI"** với **"đã nối dữ liệu thật"**. Hệ thống
thiếu một từ vựng chung để nói *màn này đang ở mức nào*.

## Quyết định 1 — UI Implementation Maturity Model (L0–L4)

Mọi screen/story có UI **phải** mang đúng một Implementation Level. Level là
**sự thật đo được từ code**, không phải ý định.

| Level | Tên | Điều kiện ĐỦ (tất cả) |
|---|---|---|
| **L0** | Design | Wireframe / UX flow. Chưa có Flutter. |
| **L1** | Static UI | Có Flutter widget. Dữ liệu dummy/hardcode. **Chưa nối repository.** |
| **L2** | Production Data | Đọc production repository (hoặc BusinessContext / provider dùng chung). Không hardcode business data. Không demo-state riêng. Số liệu khớp mọi màn khác đọc cùng nguồn. |
| **L3** | Interactive | L2 + CRUD đầy đủ · refresh sau thay đổi · navigation · persistence · empty state · **error handling** (lỗi repo/IO hiện ra cho người dùng, không nuốt, không crash). |
| **L4** | AI Enabled | L3 + ít nhất một trong: AI Summary · Recommendation · Planner · Insight · Action — đọc BusinessContext theo ADR-TON-012/013, có twin rule-based. |

**Luật vàng:** Level trong Jira phải == Level thật trong code. **Không được
đóng story ở Level cao hơn thực tế.** WTM-26 không còn được hiểu là
"Production Screen" nếu nó mới là Static UI.

Ma trận sống của toàn bộ màn: `docs/02-ARCHITECTURE/UI-IMPLEMENTATION-LEVELS.md`
(cập nhật cùng PR mỗi khi một màn đổi level).

### Vì sao "error handling" nằm ở L3 chứ không phải nice-to-have

Một màn CRUD nuốt lỗi repository trông y hệt một màn rỗng hợp lệ — đúng lớp
lỗi đã tạo ra bug Consumer. Không quan sát được lỗi = không phân biệt được
"không có dữ liệu" với "không đọc được dữ liệu".

## Quyết định 2 — One Data Path (bắt buộc)

Business data chỉ được đi **một đường duy nhất**:

```
Repository → Context Provider → BusinessContext → Screen
```

Đường tắt hợp lệ duy nhất: một màn domain đọc **thẳng repository của chính
capability đó** (ví dụ Consumer tab đọc `customerRepositoryProvider`) — vì đó
vẫn là *cùng một nguồn* mà Context Provider dùng. Mọi thứ khác bị **CẤM**:

- ❌ parallel demo state (đã cấm bởi ADR-TON-014)
- ❌ parallel cache / bản sao dữ liệu sống ngoài repository
- ❌ business data hardcode trong widget
- ❌ mỗi màn tự tính summary theo công thức riêng
  (KPI: mở rộng `BusinessMetricsService` — ADR-TON-011; count: đọc cùng nguồn)

**Hệ quả kiểm chứng được — Cross-screen Contract:**

> **Summary Count == Domain Visible Records**

Áp dụng cho mọi domain (Producer · Consumer · Inventory · Journey ·
Opportunity · Orders · Reports). Nếu domain có filter hợp lệ (ví dụ KPI đơn
hàng loại đơn đã huỷ — ADR-TON-011), thì **màn summary và màn danh sách phải
dùng CHUNG filter đó**, và filter phải được ghi rõ trong contract test.

## Quyết định 3 — Stable Test IDs

Mọi màn Level ≥ 2 phải có Widget Key ổn định cho: summary tile · list item ·
primary action · empty state · navigation entry · KPI card. Test **không được**
dựa vào text hiển thị (text đổi theo locale — ADR-TON-007).

Quy ước: `<screen>-<role>[-<qualifier>]`, kebab-case; list item mang id thật
(`customer-item-${id}`). Chi tiết + ví dụ: `docs/04-DELIVERY/TESTING-BIBLE.md`.

## Hệ quả

- `DEFINITION-OF-DONE.md` bổ sung cổng UI (production repo · no hardcode ·
  no parallel state · contract test · stable keys · smoke test release nếu
  chạm native).
- `test/support/count_list_contract.dart` — helper tái dùng để mọi domain mới
  kế thừa contract, không viết lại.
- Testing Bible ghi Root-Cause Pattern / Regression Pattern / Test Pattern /
  Prevention Rule cho từng lớp lỗi đã gặp.

## Rủi ro đã cân nhắc

Phân loại nghiêm khắc khiến **nhiều màn tụt xuống L2** (thiếu error handling).
Đây là chủ đích: con số phản ánh đúng thực tế còn hơn một bảng xanh sai. Danh
sách gap là backlog thật, không phải nợ ẩn.
