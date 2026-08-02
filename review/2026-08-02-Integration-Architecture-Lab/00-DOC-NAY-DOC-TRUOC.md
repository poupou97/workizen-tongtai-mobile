# External Integration Architecture Lab — gói báo cáo 2026-08-02

Epic **WTM-238**. Toàn bộ Wave 0 + Wave 1. **Không code, không dependency,
không connector** — đúng ràng buộc Task Order.

---

## Đọc theo thứ tự này (15 phút)

| # | File | Trả lời câu gì |
|---|---|---|
| 1 | `INTEGRATION-ROADMAP-AND-DECISIONS.md` | **Làm gì trước, và 6 thứ cần anh quyết** |
| 2 | `WORKIZEN-DOGFOOD-INTEGRATION-PLAN.md` | 10 nền tảng — nối bằng cách nào, cái nào cần backend |
| 3 | `MANAGED-STACK-EVALUATION.md` | Mua hay tự xây, 14 vùng |
| 4 | `DATA-MODEL-ASSUMPTIONS-TO-VERIFY.md` | Mô hình hiện tại chịu được gì, gãy ở đâu |
| 5 | `WORKIZEN-DOGFOOD-JOURNEY.md` | Vận hành Workizen trọn vòng bằng dịch vụ thật |
| 6 | `CANONICAL-DATA-MODEL-GAP.md` | 30 canonical domain: có gì, thiếu gì, **không nên lưu gì** |
| 7 | `ACTION-AUTOMATION-POLICY-MATRIX.md` | AI được làm gì, tuyệt đối không làm gì |
| 8 | `INTEGRATION-ARCHITECTURE-BASELINE.md` | Kiến trúc hiện tại, mỗi hộp trỏ tới file thật |
| — | `DOGFOOD-WORKIZEN-01.md` · `ADR-TON-023-*.md` | Bối cảnh: dogfood lần 1 và ADR nó sinh ra |

---

## Sáu quyết định chờ anh

| | Quyết định | Tôi đề xuất |
|---|---|---|
| **D-1** | Dựng Optional Integration Runtime cho RevenueCat? | **Có** — 1 service Cloud Run, hạn mức miễn phí |
| **D-2** | Xử lý `integrations_table` chết (có sẵn 4 cột token) | **Xoá**, viết lại thành `Connection` không cột token |
| **D-3** | Làm nền (provenance/identity/fee) trước hay connector trước? | **Nền trước** — chậm hơn nhưng không phải làm lại |
| **D-4** | Gmail: chốt Share Sheet, bỏ Gmail API cho sản phẩm? | **Chốt bỏ** |
| **D-5** | Thêm ngay `lazada/amazon/shopify/...` vào SalesChannel? | **Chưa** — sửa cấu trúc trước |
| **D-6** | Ghi ngược lên nền tảng (pause campaign, đổi giá)? | Có, nhưng **sau** |

---

## Năm kết luận đáng nhớ nhất

1. **Chỉ 1/10 nền tảng thật sự cần backend** (RevenueCat). Local-first sống sót
   gần như nguyên vẹn.
2. **Gmail API là thứ đắt nhất** — CASA $500–$4.500+, **tái thẩm định mỗi năm**,
   soi toàn bộ app. Việc thật làm được bằng **Share Sheet**: một chạm, không
   quyền, không thẩm định.
3. **`integrations_table` đã tồn tại, hoàn toàn chết, và mang giả định sai**
   (token trong SQLite). `.ttbk` mặc định không mã hoá; ngày 31/7 đã có sự cố
   gửi nhầm file lên Zalo.
4. **Ba thứ chặn mọi connector**: provenance · external identity ·
   freshness/confidence. Cộng một khoảng trống tài chính: **phí không gắn được
   vào đơn** ⇒ import đơn sàn sẽ cho *doanh thu đúng, lợi nhuận sai*.
5. **Năm trong mười bốn vùng năng lực đã giải xong ở tầng Native** — mua SaaS
   cho chúng làm sản phẩm **chậm hơn**. Ba chỗ trả lời ngược trực giác:
   **workflow đừng mua** (đã có Journey), **analytics tốt hơn = lý do không
   dùng**, **auth là bài toán không tồn tại và đó là tài sản**.
