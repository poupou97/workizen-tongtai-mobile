# Founder Executive Summary — Product Reset

**Ngày:** 2026-08-01 · **Loại:** Founder Product Review (không phải code review)
· **Trạng thái code:** không đụng một dòng nào, đúng chỉ thị.

---

## 1. Kết luận trong một câu

**Sản phẩm KHÔNG drift khỏi Vision. Directive này mở rộng Vision** — và phần mở
rộng đó đã được chính tài liệu Scope của sản phẩm xếp vào *"Out of scope
(đừng tự thêm) — Phase 3+, opt-in, qua ADR"*.

Nói cách khác: đây không phải một cuộc **sửa lệch hướng**. Đây là một **quyết
định đổi phạm vi và đổi kiến trúc**, và nó là quyết định của Founder.

## 2. Vì sao tôi kết luận như vậy

Ba câu trích nguyên văn từ tài liệu đang có hiệu lực của chính sản phẩm:

> `docs/01-PRODUCT/PRODUCT-SCOPE.md` — **Out of scope (đừng tự thêm)**
> - Backend/server, account system, cloud sync (**Phase 3+, opt-in, qua ADR**).
> - **Tích hợp thật: Shopee/TikTok/1688 API, payment, logistics, tax engine —
>   chỉ adapter/stub interface.**

> `CLAUDE.md` — Nguyên tắc không thương lượng
> **Local First** — mọi dữ liệu kinh doanh trên máy; Phase 2 **không có backend
> và không có sync** (D-5).

> `CLAUDE.md` — **Privacy by Default** — không tài khoản (D-4).

Directive yêu cầu **Connection Center** (OAuth tới Alibaba · 1688 · Taobao · JD ·
Temu · Shopify · Shopee · Amazon · eBay · TikTok Shop · Facebook · WooCommerce ·
GHN · GHTK · VNPost · DHL · Grab · Lalamove · Cloud). **Mỗi một cái trong danh
sách đó đều cần:**

| Yêu cầu kỹ thuật | Xung đột với quyết định đang có hiệu lực |
|---|---|
| OAuth client secret | không thể nằm trên thiết bị ⇒ **cần backend** ⇒ trái D-5 |
| Lưu & làm mới token | cần máy chủ giữ trạng thái ⇒ trái D-5 |
| Webhook / polling đơn hàng | cần endpoint công khai ⇒ trái D-5 |
| Danh tính người bán trên sàn | cần tài khoản ⇒ trái **D-4** |
| Dữ liệu khách từ sàn về | dữ liệu rời thiết bị ⇒ trái **Local First** |

**Đây không phải bốn tính năng cộng thêm. Đây là một sản phẩm khác về loại
hình** — từ *"ứng dụng cục bộ, không tài khoản, dữ liệu của bạn ở trên máy bạn"*
thành *"nền tảng kết nối đa sàn có máy chủ"*.

Cả hai đều là sản phẩm hợp lý. Nhưng chúng **không thể là cùng một sản phẩm** mà
không huỷ D-4, D-5 và lời hứa quyền riêng tư vừa được viết vào app hôm qua.

## 3. Một điều tôi phải nói thẳng

Chính sách quyền riêng tư đã **có trong app** (WTM-37, merged hôm qua) và nói với
người dùng, bằng tiếng Việt, trên máy họ:

> *"Khách hàng, sản phẩm, đơn hàng, mục tiêu, giao dịch — tất cả lưu trên thiết
> bị này. Không tài khoản, không máy chủ Tổng Tài, không đồng bộ. **Chúng tôi
> không nhận được dữ liệu kinh doanh của bạn.**"*

Nếu Connection Center được xây, câu đó **thành sai**. Đổi nó là việc nhỏ; nhưng
đổi nó **sau khi đã phát hành** là chuyện khác hẳn. Vì vậy quyết định phạm vi
này nên chốt **trước** khi lên cửa hàng, không phải sau.

## 4. Nguồn tôi đã đọc — và nguồn KHÔNG tồn tại

Directive yêu cầu "không được suy đoán". Vậy phải nói rõ cái gì có, cái gì không.

**Có thật và đã đọc:**

| Nguồn | Vị trí |
|---|---|
| Product Vision · Scope · Principles · Bible | `docs/01-PRODUCT/` (11 doc) |
| Screen specs | `docs/01-PRODUCT/screens/` (14 spec) |
| Information Architecture · Navigation Map | `docs/02-ARCHITECTURE/` |
| Capability Map · Capability Bible · AI Capability Matrix | `docs/02-ARCHITECTURE/` |
| **Integration Map** (12+ hệ thống ngoài, đã thiết kế) | `docs/02-ARCHITECTURE/INTEGRATION-MAP.md` |
| 19 ADR | `docs/03-DECISIONS/` |
| Delivery reports, perf baseline | `docs/04-DELIVERY/` |
| **AI Router research** (5 doc + báo cáo cuối) | Hub: `docs/research/ai-router/` |
| Jira | **WTM · WH · WC · AWR** (+ CH, WAT, WN, WP) — cả 8 project có thật |
| Source code | 35 màn · 1419 test · CI xanh |

**KHÔNG tồn tại ở bất kỳ đâu trong workspace** (grep toàn bộ `*.md`, 10 repo):

| Directive gọi tên | Kết quả tìm |
|---|---|
| **Open Source Radar** | **0 file** |
| **Connection Center** | **0 file** |
| **Marketplace Intelligence** | **0 file** |

Ba thứ này là **khái niệm mới do directive đặt ra**, không phải tài liệu để đối
chiếu. Tôi sẽ **thiết kế đề xuất** cho chúng (Phase 4/5/6), nhưng phải ghi rõ:
đây là đề xuất mới, không phải đánh giá cái đang có.

Gần nhất với "Open Source Research" là `FIT-GAP-PREPARATION.md` (nằm ở **Hub**,
từ trước khi tách repo) và `docs/research/` của Hub — nhắc Odoo/ERPNext/Chatwoot/
Mautic ở mức liệt kê, **chưa có đánh giá ADOPT/ADAPT/WATCH/REJECT** nào.

## 5. Sản phẩm hiện tại — trạng thái thật

| | |
|---|---|
| 8/8 capability | **có màn hình, có dữ liệu thật, chạy được offline** |
| Test | **1419**, CI xanh, `analyze` sạch |
| Thiết bị | chạy release trên Galaxy S24 Ultra **và** Nokia 6.1 |
| Cold start | 778ms (rỗng) → 1.348ms (12 tháng dữ liệu) trên máy tầm thấp |
| AI | BYOK, **Rule Twin authoritative, AI chỉ giải thích** (ADR-TON-016) |
| Backup/restore | `.ttbk` v2 lossless, Replace + đường lùi, **đã kiểm chứng trên máy** |
| Jira | 62 issue mở → **10** sau audit hôm nay |
| Còn chặn phát hành | **không phải code**: địa chỉ liên hệ · điều khoản dịch vụ · ký iOS |

Đây là một sản phẩm **gần xong cho phạm vi Phase 2**, không phải một sản phẩm
lạc hướng cần reset.

## 6. Ba đường đi — Founder chọn

| | Hướng | Nghĩa là gì | Cái giá |
|---|---|---|---|
| **A** | **Phát hành Phase 2 trước** | Giữ local-first, ra store, lấy người dùng thật; Connection Center làm Phase 3 | Chậm mở kết nối; nhưng có phản hồi thật trước khi xây hạ tầng lớn |
| **B** | **Xoay sang Connection Platform ngay** | Huỷ/sửa D-4, D-5; xây backend, OAuth, sync; hoãn phát hành | Ném đi lợi thế "không tài khoản"; 6–12 tháng hạ tầng trước khi có giá trị mới cho người dùng |
| **C** | **Kết nối KHÔNG cần backend** *(đề xuất của tôi)* | Nhập/xuất file (CSV/Excel từ Shopee, GHN…), không OAuth, không máy chủ. Giữ nguyên D-4/D-5 | Không realtime, không webhook. Nhưng **80% giá trị dữ liệu với 0% hạ tầng** |

**Tôi đề xuất C rồi A.** Lý do: người bán SME Việt Nam **đã có** file xuất từ
Shopee/GHN. Đọc được file đó cho họ ngay giá trị "dữ liệu đa kênh về một chỗ" mà
không cần một dòng backend, không phá lời hứa riêng tư, và không cần chờ đối tác
API duyệt. Nếu C chứng minh nhu cầu là thật, B trở thành quyết định **có dữ liệu
chứng minh** thay vì đặt cược.

Chi tiết ba hướng: [`03-CONNECTION-CENTER.md`](03-CONNECTION-CENTER.md).

## 7. Bản đồ 24 báo cáo

| # | Báo cáo | File |
|---|---|---|
| 1 | Founder Executive Summary | file này |
| 2–6 | Current Product · Vision Drift · Blueprint Drift · IA Review · Capability Gap | [`01-PRODUCT-ASSESSMENT.md`](01-PRODUCT-ASSESSMENT.md) |
| 7 | AI-first Assessment | [`02-AI-FIRST-ASSESSMENT.md`](02-AI-FIRST-ASSESSMENT.md) |
| 8–13 | Producer · Destination · Logistics · Marketing · Finance · Connection Center | [`03-CONNECTION-CENTER.md`](03-CONNECTION-CENTER.md) |
| 14–15 | Opportunity Engine · AI Marketplace Intelligence | [`04-OPPORTUNITY-AND-MARKETPLACE.md`](04-OPPORTUNITY-AND-MARKETPLACE.md) |
| 16 | Open Source Alignment | [`05-OPEN-SOURCE-ALIGNMENT.md`](05-OPEN-SOURCE-ALIGNMENT.md) |
| 17 | Roadmap Reset | [`06-ROADMAP-RESET.md`](06-ROADMAP-RESET.md) |
| 18–21 | Epic · Story · Task Order · Dependency Graph | [`07-BACKLOG-RESET.md`](07-BACKLOG-RESET.md) |
| 22–23 | Migration Strategy · Risk Analysis | [`08-MIGRATION-AND-RISK.md`](08-MIGRATION-AND-RISK.md) |
| 24 | Founder Recommendations | [`09-RECOMMENDATIONS.md`](09-RECOMMENDATIONS.md) |

**vNext:** [Product Bible](vNext-PRODUCT-BIBLE.md) ·
[Information Architecture](vNext-INFORMATION-ARCHITECTURE.md) ·
[Capability Map](vNext-CAPABILITY-MAP.md) ·
[Confluence Update Proposal](CONFLUENCE-UPDATE-PROPOSAL.md)

## 8. Điều tôi KHÔNG làm, và vì sao

- **Không viết code, không PR code, không merge code.** Đúng chỉ thị.
- **Không tự huỷ D-4/D-5.** Workspace `CLAUDE.md` nói rõ: *"Report contradictions
  before fixing. Never resolve doctrine yourself."* Directive này mâu thuẫn với
  hai quyết định đang có hiệu lực; tôi **báo cáo**, không tự xử.
- **Không tạo Jira cho Connection Center trước khi Founder chọn hướng.** Tạo 40
  story cho một kiến trúc chưa được duyệt là cách chắc chắn nhất để backlog lại
  sai lần nữa — đúng cái tôi vừa dọn sáng nay (62 issue → 10).
  Backlog đề xuất nằm ở `07-BACKLOG-RESET.md` dưới dạng **proposal có thứ tự**,
  và tôi sẽ tạo trên Jira **ngay khi Founder chốt A / B / C**.

---

## 9. Trạng thái hoàn thành (2026-08-01)

| Hạng mục directive yêu cầu | Trạng thái |
|---|---|
| 24 báo cáo | ✅ **đủ 24** — bảng ở §7 |
| Product Bible vNext | ✅ [`vNext-PRODUCT-BIBLE.md`](vNext-PRODUCT-BIBLE.md) |
| Information Architecture vNext | ✅ [`vNext-INFORMATION-ARCHITECTURE.md`](vNext-INFORMATION-ARCHITECTURE.md) |
| Capability Map vNext | ✅ [`vNext-CAPABILITY-MAP.md`](vNext-CAPABILITY-MAP.md) |
| Long-term Roadmap vNext | ✅ [`06-ROADMAP-RESET.md`](06-ROADMAP-RESET.md) |
| Jira Reset Proposal | ✅ [`07-BACKLOG-RESET.md`](07-BACKLOG-RESET.md) |
| Ordered Backlog / Epic / Story / Task | ✅ **đã thực hiện trên Jira** |
| Confluence Update Proposal | ✅ [`CONFLUENCE-UPDATE-PROPOSAL.md`](CONFLUENCE-UPDATE-PROPOSAL.md) — **chưa sửa trang nào** |
| Migration Strategy | ✅ [`08-MIGRATION-AND-RISK.md`](08-MIGRATION-AND-RISK.md) |

### Jira đã thay đổi những gì

**Tạo 6 Epic mới**, theo đúng thứ tự ưu tiên:

| | Epic | Jira |
|---|---|---|
| P0 #1 | Release Readiness | **WTM-175** |
| P0 #2 | Local AI kiểm chứng | **WTM-176** |
| P1 #3 | AI Business Profile | **WTM-177** |
| P1 #4 | AI-first Onboarding | **WTM-178** |
| P1 #5 | AI Weekly Review | **WTM-179** |
| P1 #6 | Opportunity tầng 1 | **WTM-180** |
| P1 #7 | Capability Context Performance | **WTM-167** *(đã có, giữ)* |

**Sắp xếp lại 10 issue đang mở**: gắn nhãn thứ tự `P0/P1/P2/parked`, gắn
`blocked-on-decision` cho 5 issue phụ thuộc quyết định A/B/C, gỡ nhãn sprint cũ,
viết comment giải thích cho WTM-41 và WTM-86.

**Không tạo E8/E9** (Connection Center) — chờ Founder chọn A / B / C.

### Không có gì bị merge, không có dòng code nào bị sửa

Toàn bộ thay đổi trong vòng này nằm ở `docs/07-PRODUCT-RESET/` và Jira metadata.
`lib/` và `test/` **không bị chạm**.
