# ADR-TON-020 — Product Direction: Local-first → File Bridge → Validate

- **Trạng thái:** ✅ ACCEPTED (Founder)
- **Ngày:** 2026-08-01
- **Nguồn:** Founder Decision *"Product Reset Completed"*, sau
  `docs/07-PRODUCT-RESET/` (24 báo cáo)
- **Thay thế:** giải quyết câu hỏi mở A/B/C trong báo cáo 8–13
- **Liên quan:** D-4 · D-5 · ADR-TON-018 · ADR-TON-016 · ADR-TON-009

---

## Bối cảnh

Product Reset 2026-08 tìm ra một mâu thuẫn tài liệu: `PRODUCT-VISION.md` hứa
omnichannel và so sánh nguồn hàng, còn `PRODUCT-SCOPE.md` xếp mọi tích hợp thật
vào *out of scope* và chỉ cho phép adapter/stub.

Ba capability đang khớp một phần với Vision (Producer · Opportunity ·
Consumer đa kênh) đều thiếu **cùng một thứ**: dữ liệu từ bên ngoài máy.

Câu hỏi trung tâm không phải *"kết nối sàn nào trước"* mà là **credential sống ở
đâu** — vì OAuth Shopee cần một máy chủ giữ token, kéo theo backend, và đâm
thẳng vào D-4 (không cần tài khoản) + D-5 (Phase 2 không backend/sync).

Ba hướng được trình bày: **A** giữ nguyên cục bộ · **C** File Bridge (đọc file
người bán tự xuất) · **B** Platform (backend + OAuth).

## Quyết định

**Chốt hướng C, đi qua A trước:**

```
Release  →  Local-first  →  File Bridge  →  Validate với người dùng thật
                                             │
                                             └─→ Managed Platform
                                                 CHỈ KHI có đủ bằng chứng
```

Bốn điều khoản:

1. **Không xây backend hoặc OAuth trước nhu cầu thực tế.** D-4 và D-5 **giữ
   nguyên hiệu lực**. Managed Platform không bị loại bỏ — nó bị **hoãn cho tới
   khi có bằng chứng từ người dùng thật**.

2. **File Bridge là capability chính thức của sản phẩm**, không phải giải pháp
   tạm thời. Nó được thiết kế, kiểm thử và bảo trì như mọi capability khác;
   không ai được coi nó là chỗ chờ để sau này thay bằng API.

3. **Ưu tiên cao nhất là đưa sản phẩm đến người dùng thật.** Mọi quyết định sau
   đây ưu tiên **giá trị sản phẩm** hơn mở rộng tài liệu hoặc quy trình.

4. **Product Reset không còn là backlog.** Các đề xuất còn lại trong
   `docs/07-PRODUCT-RESET/` chỉ được hiện thực hoá khi có **Epic hoặc ADR mới**.

## Hệ quả

### Có hiệu lực ngay

| | |
|---|---|
| **D-4, D-5** | giữ nguyên — không tài khoản, không backend, không sync trong Phase 2 |
| **`PRODUCT-SCOPE.md`** | dòng *"tích hợp thật … chỉ adapter/stub"* **không còn đúng cho việc đọc file**. Đọc file người dùng tự chọn **không phải** tích hợp API và **không** cần backend |
| **Thứ tự delivery** | WTM-175 → 176 → 177 → 178 → 179 → 180 → 167, rồi mới tới File Bridge |
| **Hướng B** | mọi story phụ thuộc backend/OAuth giữ nhãn `blocked-on-decision`; mở lại **chỉ khi** có bằng chứng từ closed beta |

### File Bridge phải tuân thủ khi được xây

Ràng buộc kế thừa từ ADR-TON-018 và ADR-TON-016 — ghi ở đây để Epic sau không
phải suy đoán:

1. **Không ghi thẳng vào dữ liệu thật.** Luồng bắt buộc:
   `Đọc file → Chuẩn hoá → Đối chiếu → Xem trước → Người dùng xác nhận → Áp dụng`
2. **Áp dụng trong một transaction**, verify sau khi ghi — như Restore.
3. **Provenance bắt buộc**: mỗi bản ghi phải biết mình do người dùng nhập tay
   hay đến từ mẻ nhập nào. Người bán phải luôn phân biệt được số nào là của
   mình.
4. **Vào `.ttbk` v2**: bảng mới của File Bridge phải nằm trong backup, nếu không
   người dùng khôi phục sẽ mất đúng phần đó **mà không có thông báo nào**.
5. **Migration cộng thêm** (ADR-TON-009): không sửa 17 bảng đang có.
6. **File không hợp lệ là lỗi có tên**, không phải crash — `TongtaiFailure`
   theo ADR-TON-017.

### Không có hệ quả nào lên code hôm nay

Quyết định này **không** yêu cầu sửa dòng code nào ngay. Nó xác định thứ tự và
ranh giới cho các Epic sắp tới.

## Vì sao không chọn B ngay

Không phải vì B sai, mà vì **chưa có bằng chứng cho B**. Sản phẩm chưa có một
người bán thật nào dùng. Xây backend + OAuth trước closed beta là đặt 6–12 tháng
cược vào một nhu cầu chưa ai xác nhận (rủi ro R1, báo cáo 23).

Nếu người dùng thật sự nhập file mỗi tuần, B trở thành quyết định **có bằng
chứng**. Nếu họ không nhập, ta vừa tiết kiệm 6–12 tháng.

## Vì sao File Bridge không phải giải pháp tạm

Người bán **đã có** file xuất từ Shopee, TikTok Shop, GHN — hôm nay, không cần
xin phép ai. Đọc được file đó giao đúng giá trị lớn nhất mà Vision hứa — *dữ
liệu đa kênh về một chỗ* — mà không cần backend, không cần đối tác duyệt, và
không phá lời hứa riêng tư đã in vào app.

Kể cả khi Managed Platform ra đời, File Bridge vẫn là con đường duy nhất cho:
người bán ở sàn chưa có API · dữ liệu lịch sử trước ngày kết nối · người dùng
**không muốn** đưa khoá sàn cho bất kỳ ai. Đó là lý do nó được ghi là capability
chính thức, không phải chỗ chờ.
