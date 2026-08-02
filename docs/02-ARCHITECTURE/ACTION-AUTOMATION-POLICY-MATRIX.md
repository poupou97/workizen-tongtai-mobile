# Action & Automation Policy Matrix — AI được làm gì, và tuyệt đối không làm gì

> **WTM-243 · Wave 1 của Epic WTM-238.** Năm mức Founder đặt: **L0** chỉ đọc ·
> **L1** AI đề xuất · **L2** người dùng xác nhận · **L3** tự động theo policy ·
> **L4** cấm tự động.
>
> Ràng buộc kế thừa: `AiToolRuntime` **đang tắt cứng**
> (`ai/ai_runtime_boundary.dart:91`, có test chặn). Nên **mọi dòng L3 dưới đây
> là ĐỀ XUẤT cho tương lai, không phải cho phép bật ngay.**

---

## Bảy trường bắt buộc cho L2/L3

Founder yêu cầu mọi action L2/L3 phải khai đủ: `actor` · `permission` ·
`evidence` · `audit log` · `rollback` · `idempotency` · `confirmation policy`.

**Luật tôi đề xuất áp: thiếu một trong bảy ⇒ action đó KHÔNG được xếp L3, tự
động rơi xuống L2.** Lý do: `rollback` và `idempotency` là hai thứ dễ "để làm
sau" nhất, và cũng là hai thứ duy nhất đứng giữa *một lỗi* và *một lỗi lặp lại
50 lần trong đêm*.

---

## Ma trận theo use case

| Use case | Mức | Vì sao ở mức đó | Rollback | Idempotency |
|---|---|---|---|---|
| Đọc doanh thu store/RevenueCat | **L0** | chỉ đọc | — | — |
| Đọc GA4 / Search Console | **L0** | chỉ đọc | — | — |
| Đọc release GitHub | **L0** | chỉ đọc | — | — |
| Đọc crash Crashlytics | **L0** | chỉ đọc | — | — |
| **Giải thích** vì sao doanh thu giảm | **L1** | AI diễn giải số của Rule Twin | — | — |
| **Đề xuất** giá / gói / nội dung | **L1** | không chạm dữ liệu | — | — |
| Đề xuất trả lời email hỗ trợ | **L1** | soạn nháp, không gửi | — | — |
| Tạo bước hành trình từ cơ hội | **L2** | đổi kế hoạch của người bán | xoá node | `gen-<oppId>` |
| Cập nhật giá sản phẩm **trong app** | **L2** | đổi dữ liệu nghiệp vụ | `ProductRevision` (đã có) | id sản phẩm |
| Gửi tin Telegram cho khách | **L2** | chạm người thật | không thu hồi được ⇒ **phải xác nhận** | message key |
| Ghi một khoản chi vào sổ | **L2** | đổi sổ sách | xoá giao dịch | id giao dịch |
| **Pause campaign quảng cáo** | **L2** | tiền + hệ quả kinh doanh | resume | campaign id + trạng thái mong muốn |
| Nhập file báo cáo định kỳ | **L3** | không phá gì, có preview | huỷ batch (`batchId`) | hash file |
| Kéo dữ liệu store hằng ngày | **L3** | chỉ đọc + ghi vào bảng của mình | xoá batch | cursor |
| Sinh **AI Weekly Review** | **L3** | chỉ tạo nội dung để đọc | xoá bản review | tuần ISO |
| Cảnh báo tồn kho / cam kết chi phí | **L3** | thông báo cục bộ | tắt thông báo | key theo ngày |
| Gắn nhãn email | **L3** *(chờ)* | Founder xếp L3, nhưng cần Gmail API ⇒ **chưa làm** | bỏ nhãn | message id |
| **Chi tiền / hoàn tiền** | **L4** | tiền thật | — | — |
| **Xoá dữ liệu** | **L4** | Restore=Replace đã là hành động phá huỷ có xác nhận (ADR-TON-018) | — | — |
| **Đổi giá lớn** (>20%) | **L4** | hệ quả doanh thu | — | — |
| **Xoá campaign** | **L4** | không dựng lại được | — | — |
| **Gửi nội dung nhạy cảm** | **L4** | danh tiếng | — | — |
| **Đổi thông tin tài khoản** | **L4** | mất quyền truy cập | — | — |
| **Hành động pháp lý/tài chính** | **L4** | ngoài thẩm quyền phần mềm | — | — |

---

## Ba luật rút ra khi xếp ma trận này

### 1. Ranh giới L2/L3 không nằm ở độ khó kỹ thuật mà ở **khả năng hoàn tác**

*Nhập file* dễ hơn *gửi Telegram* về mặt kỹ thuật? Không hẳn. Nhưng nhập file
**hoàn tác được** (xoá batch), còn tin nhắn đã gửi thì **không**. Vì thế nhập
file lên được L3 còn gửi tin thì mãi ở L2.

### 2. Việc "chỉ đọc" cũng có thể gây hại nếu nó **im lặng**

Một job L3 kéo dữ liệu hằng ngày mà token hết hạn, nếu hỏng trong im lặng thì
Founder sẽ đọc một Weekly Review **thiếu dữ liệu mà không biết là thiếu**. Nên:
mọi L3 phải ghi `freshness` và màn hình phải hiện *"dữ liệu Shopee cũ 3 ngày"* —
đúng thứ Wave 0 đã chỉ ra là còn thiếu.

### 3. L4 không phải "chưa làm", mà là "**không bao giờ tự động**"

Khác biệt này phải nằm trong **code**, không nằm trong tài liệu: một danh sách
L4 kiểm bằng test (như `DisabledAiToolRuntime` hôm nay) thì không ai vô tình mở
được. Một danh sách nằm trong file `.md` thì mở được bằng một PR không ai để ý.

---

## Đề xuất governance khi Tool Runtime được bật (chưa phải bây giờ)

1. Mỗi tool khai **mức** của nó trong code, test quét toàn `lib/` để không tool
   nào không có mức — cùng khuôn `p0/journey_reachability_test.dart`.
2. Tool L4 **không tồn tại** trong runtime, không phải "bị chặn lúc chạy". Không
   có mã thì không có đường bật.
3. Mọi lần chạy L3 ghi `Evidence` — và `Evidence` là object canonical còn thiếu
   (xem [CANONICAL-DATA-MODEL-GAP](CANONICAL-DATA-MODEL-GAP.md) #31). **Không có
   Evidence thì không có L3.**
