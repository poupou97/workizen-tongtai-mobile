# Roadmap Reset

*(Báo cáo 17 trong 24 · Phase 7 của directive)*

> Roadmap này **không bị ràng buộc bởi roadmap cũ** (directive cho phép).
> Roadmap cũ (`docs/04-DELIVERY/ROADMAP.md`) đã được thực tế vượt qua và hôm nay
> đã gắn bảng đối chiếu.

---

## Nguyên tắc xếp thứ tự

1. **Phát hành được trước, mở rộng sau.** Một sản phẩm chưa ra mắt không học
   được gì từ người dùng thật, và mọi ưu tiên sau đó đều là phỏng đoán.
2. **Không xây hạ tầng cho nhu cầu chưa được chứng minh.**
3. **Business capability trước UI** (đúng chỉ thị).
4. **Không mở doctrine gate mà không có quyết định Founder bằng văn bản.**

---

## NOW — 2 đến 4 tuần · mục tiêu: **ra được cửa hàng**

| # | Việc | Vì sao ở đây | Chặn bởi |
|---|---|---|---|
| 1 | **Nội dung pháp lý** — địa chỉ liên hệ + Điều khoản dịch vụ | **Chặn cứng** việc lên store | **Founder** |
| 2 | **Play Console Data Safety** khai báo | bắt buộc; phải khớp `TELEMETRY-EVENTS.md` | — |
| 3 | **iOS build + ký** | mở nửa thị trường còn lại | **tài khoản Apple** |
| 4 | **Kênh phản hồi trong app** | phát hành mà không nghe được người dùng là đi mù | — |
| 5 | **Ollama / Local AI kiểm chứng trên máy thật** | ADR-TON-006 đã hứa chế độ Local; chưa ai chạy thử | — |
| 6 | **Closed beta 20–50 người bán thật** | nguồn duy nhất cho mọi ưu tiên sau | — |

> **Không có mục nào ở NOW cần backend, cần đối tác, hay cần đổi ADR.**

## NEXT — 1 đến 2 tháng · mục tiêu: **AI đáng để mở app**

| # | Việc | Ghi chú |
|---|---|---|
| 7 | **AI Business Profile** | ngành/quy mô/mùa vụ — nền cho mọi prompt |
| 8 | **AI-first Onboarding** | hội thoại thay 6 trang giới thiệu |
| 9 | **AI Weekly Review** | dùng lại toàn bộ Rule Twin đã có |
| 10 | **Opportunity tầng 1 mở rộng** | hàng chết vốn · khách sắp rời · mua kèm · mùa vụ — **không cần kết nối** |
| 11 | **Đo tính hữu ích của gợi ý AI** | phải khai báo telemetry + cập nhật privacy |
| 12 | **Epic WTM-167 — Capability Context Performance** | đã có ADR draft + benchmark; hydration đã đo 405ms ở 12 tháng trên máy thật |

## LATER — 3 đến 6 tháng · **phụ thuộc quyết định A/B/C**

| # | Việc | Điều kiện |
|---|---|---|
| 13 | **Connection Center — xương sống** (Connector→Normalizer→Reconciler→Preview→Apply→Provenance) | Founder chốt **C** |
| 14 | **Nhập file Shopee / TikTok Shop** | sau 13 |
| 15 | **GHN qua API token** (không cần backend, mô hình BYOK) | sau 13 · **kết nối API thật đầu tiên nên là cái này** |
| 16 | **Finance: lãi thật sau phí sàn** | sau 14 — **câu hỏi số 1 của người bán** |
| 17 | **Opportunity tầng 2** — so sánh kênh | sau 14 |
| 18 | Marketing: xuất danh sách theo phân khúc RFM | độc lập, nhỏ |

## FUTURE — 6 tháng+ · **cần quyết định hạ tầng (hướng B)**

| # | Việc | Điều kiện tiên quyết |
|---|---|---|
| 19 | Backend + tài khoản + OAuth | **ADR huỷ D-4 và D-5** |
| 20 | Shopee / TikTok Shop OAuth realtime | sau 19 + phê duyệt của sàn |
| 21 | Managed AI (không cần BYOK) | sau 19 + mô hình chi phí token |
| 22 | Đồng bộ hai chiều (đẩy ngược lên sàn) | sau 20 |
| 23 | AI Marketplace Intelligence | **quyết định thương mại**: mua dữ liệu hoặc network effect |
| 24 | Cloud backup | sau 19 |

## PARKED — có lý do rõ ràng để không làm

| Việc | Vì sao park |
|---|---|
| **Alibaba / 1688 / Taobao / JD / Temu** | điều kiện API của họ nằm ngoài tầm kiểm soát; không khả thi 6 tháng tới |
| **Amazon / eBay** | không phải thị trường của SME Việt Nam |
| **Grab / Lalamove / DHL** | GHN + GHTK phủ phần lớn nhu cầu nội địa |
| **Map / ETA trực quan** | cần Google Maps API (chi phí + khoá) |
| **Marketing automation** | không đo được hiệu quả khi chưa có kênh bán kết nối |
| **WTM-122 chuẩn hoá schema** | Founder đã chủ động đóng |
| **Tool Runtime / AI hành động** | **Founder gate**, ADR-TON-016 |
| **Odoo · ERPNext · Mautic · SuiteCRM · Chatwoot** | REJECT — xem báo cáo 16 |

---

## Một quan sát về thứ tự

Directive đề nghị thứ tự P0 bắt đầu bằng *Product Reset → IA → Business Journey →
Connection Center → AI-first Onboarding → Opportunity Engine → Producer →
Destination → Logistics → Marketing → Finance Intelligence → AI Marketplace
Intelligence*.

Tôi **không xếp như vậy**, và đây là lý do:

- **Business Journey đã ở L4.** Đặt nó ở P0 số 3 sẽ là làm lại việc đã xong.
- **Connection Center ở vị trí số 4** đưa hạng mục **đắt nhất, rủi ro nhất, phụ
  thuộc bên ngoài nhiều nhất** lên trước khi sản phẩm có một người dùng thật nào.
- **Producer/Destination/Logistics** phụ thuộc Connection Center; xếp chúng thành
  các mục riêng ngang hàng tạo cảm giác chúng làm song song được — không.
- **Finance Intelligence xếp thứ 11**, nhưng *"lãi thật sau phí sàn"* có lẽ là
  giá trị đơn lẻ lớn nhất còn lại. Nó nên đi **ngay sau** dữ liệu kênh, không
  phải sau Marketing.

Nếu anh vẫn muốn thứ tự của directive, tôi làm theo — nhưng tôi có trách nhiệm
nói rằng nó đặt hạ tầng trước bằng chứng, và đó là cách các sản phẩm xây xong
thứ không ai dùng.
