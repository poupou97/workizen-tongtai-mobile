# Product Bible vNext — đề xuất

> **Trạng thái: PROPOSAL.** Chưa thay thế `docs/01-PRODUCT/`. Chỉ có hiệu lực
> sau khi Founder duyệt và chọn hướng A/B/C (xem báo cáo 24).
>
> Product Bible hiện tại **không sai** — nó thiếu **một lát cắt phase**. Bản
> vNext này giữ nguyên phần đúng và bổ sung đúng chỗ thiếu.

---

## 1. Tổng Tài là gì

**Tổng Tài là hệ điều hành kinh doanh cho chủ SME Việt Nam** — nơi một người
bán hàng thấy được toàn cảnh việc kinh doanh của mình và biết việc cần làm tiếp
theo, ngay trên điện thoại, không cần kế toán, không cần ERP, không cần internet.

### Điều chỉnh so với bản hiện tại

| Bản hiện tại | vNext | Vì sao |
|---|---|---|
| "AI-First Business OS" | **"Business OS with an AI advisor"** *(nếu giữ hướng A/C)* | Xem báo cáo 7: sản phẩm hôm nay là AI-assisted. Nhãn AI-First chỉ đúng nếu làm Managed AI. **Founder chọn.** |
| Vision hứa omnichannel + arbitrage, Scope hoãn | **Ghi rõ capability nào thuộc phase nào** | Đây là mâu thuẫn tài liệu lớn nhất tìm được |

---

## 2. Người dùng

**Chủ SME Việt Nam bán hàng online + offline**, thường tự làm mọi việc: nhập
hàng, bán, giao, thu tiền, tính lãi. Ghi sổ bằng Excel hoặc trong đầu.

**Ba câu hỏi họ hỏi hằng ngày** — đây là thước đo mọi tính năng:

1. *"Tháng này tôi lãi bao nhiêu — thật, sau hết phí?"*
2. *"Hàng nào đang chôn vốn?"*
3. *"Tôi nên nhập gì tiếp theo?"*

> Hôm nay sản phẩm trả lời được (2) và một phần (3). **(1) chỉ trả lời được cho
> dữ liệu người dùng tự nhập** — chưa tính được phí sàn, vì chưa có dữ liệu sàn.
> Đây là khoảng trống giá trị lớn nhất còn lại.

---

## 3. Nguyên tắc bất biến

1. **Local First** — dữ liệu kinh doanh nằm trên máy; hoạt động offline.
2. **Privacy by Default** — không bắt buộc tài khoản; không quảng cáo, không
   profiling, không theo dõi tiếp thị.
3. **Rule Twin authoritative** — mọi con số do luật xác định tính ra;
   **AI chỉ giải thích, không được bịa số.** *(giữ nguyên, đây là tài sản)*
4. **Practical over ambitious.**

> **Nguyên tắc 1 và 2 là nơi hướng B đâm vào.** Nếu chọn B, hai nguyên tắc này
> phải được sửa **bằng ADR tường minh trước khi viết dòng code đầu tiên**, và
> chính sách riêng tư phải cập nhật **trước khi thu dòng dữ liệu đầu tiên**.

---

## 4. Tám capability — trạng thái thật

| # | Capability | Level | Khớp Vision |
|---|---|---|---|
| 1 | Inventory | L4 | ✅ trọn vẹn |
| 2 | Finance | L4 | ⚠️ thiếu *lãi thật sau phí sàn* |
| 3 | Consumer (CDP/CRM) | L4 | ⚠️ một kênh, chưa đa kênh |
| 4 | Reports | L4 | ✅ |
| 5 | Business Journey | L4 | ✅ |
| 6 | Producer (sourcing) | L3 | ⚠️ thiếu dữ liệu nhà cung cấp ngoài |
| 7 | Opportunity Hub | L3 | ⚠️ tầng 1 chưa khai thác hết |
| 8 | AI Copilot | L3 | ⚠️ cần khoá API mới dùng được |

**Cả ba khoảng trống đều thiếu cùng một thứ: dữ liệu từ bên ngoài máy.**
Đó là lý do Connection Center là câu hỏi trung tâm của vòng reset này.

---

## 5. Ranh giới phase — phần bổ sung quan trọng nhất

| Phase | Có gì | Điều kiện |
|---|---|---|
| **Phase 2 (hiện tại)** | 8 capability trên máy · BYOK + Local AI · `.ttbk` backup · CSV export | — |
| **Phase 2.5** *(nếu chọn C)* | Connection Center xương sống · nhập file sàn · GHN qua API token · **lãi thật sau phí sàn** | **giữ nguyên** D-4/D-5, không backend |
| **Phase 3** *(chỉ nếu chọn B)* | Backend · tài khoản · OAuth sàn · realtime · Managed AI · sync | **ADR huỷ D-4 và D-5** + cập nhật chính sách riêng tư |
| **Phase 4** | Marketplace Intelligence (dữ liệu ngành) | **quyết định thương mại**, không phải kỹ thuật |

**Quy tắc:** không có capability nào được hứa trong Vision mà không được gán
phase. Nếu chưa gán được phase, nó thuộc **Parked** và phải nói rõ.

---

## 6. Cái sản phẩm này **không** làm

- Không phải ERP. Không phải phần mềm kế toán khai thuế.
- Không quảng cáo, không bán dữ liệu, không profiling — **vĩnh viễn**.
- Không tự động hành động thay người dùng khi chưa có Tool Runtime được duyệt
  (ADR-TON-016 — Founder gate).
- Không hứa tích hợp sàn cho tới khi tồn tại một kết nối chạy được thật.
