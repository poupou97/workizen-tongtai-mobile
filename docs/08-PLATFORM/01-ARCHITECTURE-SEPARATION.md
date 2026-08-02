# Mobile giữ gì · Backend giữ gì — và chỗ ranh giới dễ trượt

> **WTM-249 · Phase 1 của PLATFORM-001 (Epic WTM-247).**
> Trạng thái: **Draft — cần Founder review.**

Founder đã chia sẵn hai cột. Chép lại hai cột đó không phải việc; việc là chỉ ra
**chỗ ranh giới trượt**, vì mọi thứ hỏng đều hỏng ở đó chứ không hỏng ở giữa cột.

---

## Hai cột (theo Founder)

| MOBILE | BACKEND |
|---|---|
| Business Logic | OAuth |
| Business Context | Webhook |
| Rule Twin | Polling |
| Journey | Scheduler |
| Opportunity | Workflow |
| AI | Connector · Secrets · Notification · Vendor Adapter |

---

## Một câu phân định, dùng được ở mọi tranh cãi về sau

> **Backend được biết *dữ liệu đến từ đâu*. Chỉ Mobile được biết *dữ liệu đó
> NGHĨA LÀ GÌ*.**

Backend là **ống dẫn có xác thực**: lấy về, chuẩn hoá hình dạng, giao lại. Nó
không được kết luận *"tháng này lãi 12 triệu"*, không được quyết *"nên nhập
thêm hàng"*, không được chấm điểm cơ hội. Toàn bộ chỗ đó là Rule Twin trên máy
(ADR-TON-016).

Lý do không phải thẩm mỹ kiến trúc: **Rule Twin phải chạy được khi không có
mạng**. Một khi backend bắt đầu tính hộ, thì con số của người bán phụ thuộc vào
việc máy chủ có sống hay không — và sản phẩm mất đúng thứ nó đang bán.

---

## Bảy chỗ ranh giới trượt, và cách chặn

| # | Chỗ trượt | Nghe rất hợp lý | Vì sao sai | Ranh giới đúng |
|---|---|---|---|---|
| 1 | **"Backend tính sẵn tổng doanh thu cho nhanh"** | tiết kiệm pin, tiết kiệm CPU | tạo **nguồn thứ hai** cho một con số Rule Twin đã sở hữu ⇒ P-27, lệch là chắc chắn, chỉ là lúc nào | backend trả **đơn thô đã chuẩn hoá**; tổng do máy tính |
| 2 | **"Backend lọc bớt dữ liệu cho nhẹ"** | giảm băng thông | lọc = **quyết định cái gì quan trọng** = business logic | backend cắt theo **thời gian/phân trang**, không theo *ý nghĩa* |
| 3 | **"n8n sinh luôn cơ hội"** | n8n có sẵn logic node | Opportunity là kết luận kinh doanh, phải kèm `reasonCodes` mà người bán hỏi được | n8n đẩy **BusinessSignal thô**; Rule Twin quyết đó có phải cơ hội không |
| 4 | **"Lưu tạm dữ liệu trên backend cho khỏi kéo lại"** | hợp lý về hiệu năng | "tạm" hôm nay là **Core Product Backend** sáu tháng nữa — đúng thứ Founder đã đóng | chỉ giữ **cursor + trạng thái sync**, không giữ bản ghi nghiệp vụ |
| 5 | **"Backend gửi thông báo cho người dùng"** | push tiện hơn | thông báo là **kết luận** (*"sắp hết hàng"*) ⇒ backend phải tính ⇒ vi phạm câu phân định | backend đẩy **"có dữ liệu mới"**; máy tính và tự quyết có báo không |
| 6 | **"AI chạy trên backend cho mạnh"** | model lớn hơn | phá BYOK: khoá người dùng sẽ phải rời máy qua **máy chủ của mình**, khác hẳn lời hứa "chỉ nằm trong header gọi thẳng provider" | AI vẫn ở máy; Managed AI là **Phase 3, quyết định riêng** |
| 7 | **"Backend giữ luôn dữ liệu để đồng bộ nhiều máy"** | ai chẳng muốn | đây **đúng nghĩa** Core Product Backend mà Founder đã xếp là chưa mở | không làm; nếu cần thì mở bằng ADR riêng, không lẻn vào qua connector |

---

## Danh sách "Backend KHÔNG BAO GIỜ làm" — viết để sau này thành test

Founder yêu cầu đầu ra phải kiểm được. Bảy điều dưới đây đủ cụ thể để thành
kiểm tra tự động khi runtime ra đời:

1. **Không lưu bản ghi nghiệp vụ** (Order · Product · Customer · Transaction ·
   Journey · Opportunity). *Kiểm: schema backend không có bảng nào mang tên đó.*
2. **Không tính chỉ số kinh doanh.** *Kiểm: không có phép cộng tiền trong code
   backend; chỉ có ánh xạ trường.*
3. **Không sinh Opportunity / JourneyNode.** *Kiểm: hai kiểu đó không tồn tại
   trong backend.*
4. **Không giữ khoá AI của người dùng.** *Kiểm: không đọc/ghi khoá provider AI.*
5. **Không gửi thông báo mang kết luận.** *Kiểm: payload push chỉ có
   `{connectionId, hasNewData, syncedAt}`.*
6. **Không là điều kiện để app chạy.** *Kiểm: tắt toàn bộ backend, app vẫn qua
   trọn bộ test hiện có.* ← **quan trọng nhất, và là cái duy nhất kiểm được ngay hôm nay**
7. **Không giữ credential trong DB nghiệp vụ**; secret nằm ở vault, DB chỉ giữ
   tham chiếu (luật Founder 2026-08-02).

---

## SHARED — thứ cả hai bên phải nói giống nhau

Chỉ ba thứ, và cả ba là **từ vựng**, không phải mã chạy:

| Shared | Vì sao phải chung |
|---|---|
| **Canonical codes** (`ProductKind` · `SalesChannel` · `FinanceCategory` · `BusinessInputKind` · `InputCadence` · `JourneyMetric`) | Backend chuẩn hoá dữ liệu sàn về đúng mã này. Lệch một mã = dữ liệu sai âm thầm (WTM-232 đã cắn: `_ => 'Bán sỉ'`) |
| **Provenance schema** | Hai bên phải đồng ý *"bản ghi này từ đâu"* mới truy được nguồn |
| **Failure taxonomy** (`TongtaiFailure.kind/code`) | Lỗi từ backend phải hiện trên máy thành lỗi **có tên**, không phải mã HTTP trần |

**Cố ý KHÔNG shared:** Rule Twin, công thức, ngưỡng, và mọi thứ trả lời *"nên
làm gì"*. Chia sẻ chúng là chia sẻ quyền kết luận.

---

## Hệ quả cho những gì đã có

* `sync_queue_items` (bảng outbox đã tồn tại, hôm nay ghi-một-chiều) là **chỗ
  đúng** cho External Action sau này — không cần bịa cơ chế mới.
* `integrations_table` (chết, có 4 cột token) **vi phạm** điều số 7 ngay từ thiết
  kế ⇒ xoá hoặc viết lại, xem `05-DECISION-MATRIX`.
* Điều số 6 kiểm được **ngay hôm nay**: hiện chưa có backend nào, và 1818 test
  đang xanh — đó chính là đường cơ sở cần giữ.
