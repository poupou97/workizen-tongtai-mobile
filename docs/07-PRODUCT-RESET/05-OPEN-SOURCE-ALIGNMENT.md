# Open Source Alignment Report

*(Báo cáo 16 trong 24 · Phase 6 của directive)*

---

## Trước hết: "Open Source Radar" không tồn tại

Directive yêu cầu *"đối chiếu toàn bộ Open Source Radar"*. Tôi đã grep **10
repo, toàn bộ `*.md`**:

| Cụm từ | Số file |
|---|---|
| "Open Source Radar" | **0** |

**Không có Radar để đối chiếu.** Thứ gần nhất đang tồn tại:

| Hiện vật | Ở đâu | Nội dung |
|---|---|---|
| `FIT-GAP-PREPARATION.md` | **Hub** (`workizen-ai-personal-wallet/docs/tongtai/tech/`), từ trước khi tách repo | liệt kê Odoo · ERPNext · Mautic · SuiteCRM · Chatwoot ở mức **tên gọi**, chưa đánh giá |
| `docs/research/` của Hub | Hub | nghiên cứu thật nhưng về **AI Router**, DeepTutor, Google AI Edge — **không phải** về thương mại điện tử |

Vậy báo cáo này là **đề xuất lập Radar lần đầu**, không phải rà soát Radar cũ.
Tôi nói rõ để anh không hiểu nhầm là đã có ai đánh giá những thứ dưới đây.

## Cảnh báo về độ tin cậy

Các đánh giá dưới đây dựa trên hiểu biết chung về từng dự án, **không phải thử
nghiệm tay**. Trước khi ADOPT bất cứ thứ gì, phải có một spike thật. Tôi đánh
dấu rõ mức tin cậy.

---

## Nhóm 1 — Nền tảng thương mại (nếu đi hướng B)

| Dự án | Là gì | Khớp Tổng Tài? | Kết luận | Tin cậy |
|---|---|---|---|---|
| **Odoo** | ERP đầy đủ, Python | Quá nặng. Tổng Tài là app mobile local-first, không phải ERP server | **REJECT** | cao |
| **ERPNext** | ERP mã nguồn mở, Frappe | Cùng lý do. Kéo theo một hệ sinh thái server | **REJECT** | cao |
| **Medusa** | commerce backend headless, Node | Nếu hướng B cần backend đơn hàng đa kênh, đây là ứng viên nghiêm túc | **WATCH** | trung bình |
| **Saleor** | commerce GraphQL, Python | Tương tự Medusa, nặng hơn | **WATCH** | trung bình |

**Nhận định:** cả bốn đều giải bài toán *"tôi cần một backend thương mại"*.
Tổng Tài **chưa quyết định là mình cần cái đó**. Đánh giá sâu hơn **trước khi
Founder chốt A/B/C là lãng phí**.

## Nhóm 2 — Kết nối / đồng bộ (lõi của Connection Center)

| Dự án | Là gì | Kết luận | Tin cậy |
|---|---|---|---|
| **Airbyte** | ELT connector, hàng trăm nguồn | Chạy server, nặng cho mobile. Nhưng **mô hình connector/normalizer của nó đáng học** | **ADAPT (ý tưởng, không phải code)** | trung bình |
| **Singer / Meltano** | đặc tả tap/target | Đặc tả nhẹ, có thể mượn **hình dạng** cho Connector Contract | **ADAPT** | trung bình |
| **n8n** | workflow automation, có node Shopee/GHN | Nếu hướng B, có thể là đường tắt cho tích hợp | **WATCH** | thấp — cần thử |

## Nhóm 3 — Thứ dùng được NGAY, không phụ thuộc A/B/C

| Dự án | Dùng vào việc gì | Kết luận | Tin cậy |
|---|---|---|---|
| **Ollama** | AI local, không cần khoá | **Đã nằm trong ADR-TON-006** như chế độ Local. Chưa kiểm chứng trên máy thật | **ADOPT (đã quyết)** | cao |
| **`file_selector`, `crypto`, `drift`, `riverpod`** | đang dùng | **ADOPT (đã dùng)** | cao |
| **`excel` / `spreadsheet_decoder` (Dart)** | đọc file `.xlsx` người bán xuất từ sàn | **Trực tiếp phục vụ hướng C** | **ADOPT — nếu chọn C** | trung bình |
| **`csv` (Dart)** | đã dùng cho export | **ADOPT** | cao |

## Nhóm 4 — Loại thẳng

| Dự án | Vì sao |
|---|---|
| **Mautic** | marketing automation server-side; Marketing đang ở Later và sản phẩm là mobile local-first |
| **SuiteCRM / Chatwoot** | CRM/chat server-side; Consumer capability đã tự làm và đang ở L4 |

---

## Kết luận thẳng về Phase 6

**Không có dự án open source nào đáng ADOPT trong vòng này ngoài những thứ đã
dùng.** Lý do đơn giản: mọi ứng viên nghiêm túc (Medusa, Airbyte, n8n) đều là
**phần mềm chạy trên máy chủ**, và Tổng Tài **chưa quyết định có máy chủ hay
không**.

Đánh giá chi tiết chúng bây giờ là làm việc cho một kiến trúc chưa được duyệt —
đúng loại lãng phí mà audit backlog sáng nay vừa dọn (51 issue mô tả việc đã
làm hoặc không còn đúng).

**Đề xuất:** lập Radar thật **sau** khi Founder chốt hướng, và giới hạn ở đúng
những dự án phục vụ hướng đó. Tôi đề nghị một spike có thời hạn (2–3 ngày) cho
mỗi ứng viên WATCH, với tiêu chí quyết định viết trước khi thử.

**Ngoại lệ duy nhất nên làm ngay:** thư viện đọc `.xlsx`. Nếu chọn hướng C, đó
là phụ thuộc kỹ thuật đầu tiên và duy nhất — và nó chỉ là một package Dart, không
phải một hệ thống.
