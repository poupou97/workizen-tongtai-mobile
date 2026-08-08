# 09 · COMP AI vs Tổng Tài — cùng bài toán, khác lời giải

> Không hỏi *"họ có feature gì"*. Hỏi *"họ giải quyết **cùng vấn đề kiến trúc** như thế nào"*.

## Bối cảnh khác nhau — đọc mọi so sánh qua bảng này

| | COMP AI | Tổng Tài |
|---|---|---|
| Người dùng | rep bán hàng, một tổ chức | chủ shop SME Việt Nam, hàng nghìn |
| Triển khai | **single-tenant**, self-host | **local-first trên máy người bán** (D-5) |
| Dữ liệu ở đâu | Postgres của tổ chức | SQLite trên điện thoại |
| Nguồn ngoài | thực chất **một** (Google) + 3 vendor | **10+** dự kiến |
| Miền | contact · company · deal | orders · inventory · customers · finance · settlement · journey · chat |
| Backend | có, luôn chạy | **cố ý không có** (Core Product Backend đóng) |
| AI chạy ở đâu | server, cron mỗi phút | trên máy, BYOK, không nền |

**Ba dòng cuối là lý do phần lớn thứ COMP AI làm không bê nguyên được.** Họ có một máy chủ luôn thức. Tổng Tài thì không — và đó là quyết định sản phẩm, không phải thiếu sót.

## Bảng đối chiếu theo vấn đề kiến trúc

| Vấn đề | COMP AI | Tổng Tài | Ai mạnh hơn |
|---|---|---|---|
| **Tin cậy một khẳng định** | evidence kind → hàm thuần định giá | chỗ gọi **khai** confidence | **COMP AI** |
| **Thay đổi do AI đề xuất** | 4 trạng thái, đề xuất treo cho người | **không có** — Rule Twin tính rồi hiện | **COMP AI** |
| **Người thắng máy** | `humanOwns()` — một cổng | nguyên tắc đúng, cài **rải rác** | COMP AI (gọn hơn) |
| **Không tự gộp bản ghi người** | không có API gộp (**vắng mặt**) | **3 lớp governance khoá bằng cấu trúc** | **Tổng Tài** |
| **Gỡ hàng loạt khi luật sai** | không có | `IdentityLinkEvent.actor = rule:<tên>` | **Tổng Tài** |
| **Bền vững qua restart** | Postgres + cron + `SKIP LOCKED` | **chưa có agent** | COMP AI (ta chưa có) |
| **Idempotency của side effect** | `idempotencyKey` + `requestHash` | `CanonicalEvent.dedupeKey` (chưa dùng) | COMP AI (đang chạy thật) |
| **Cửa ghi duy nhất** | **3 kỷ luật song song, không có** | chưa có agent nên chưa vỡ | hoà — cả hai đều thiếu |
| **Biết nền tảng làm được gì** | 1 boolean `enabled` | **CapabilityMatrix 3 cột** | **Tổng Tài** |
| **AI chỉ được hứa cái đã chạy thật** | không có khái niệm | `CapabilityClaim` constructor private | **Tổng Tài** |
| **Chuẩn hoá sự kiện đa nền tảng** | **không có** (không cần) | `CanonicalEvent` (0 producer/consumer) | chưa phân định |
| **Nguồn gốc bản ghi** | `method` + `sourceUrl` trong fact | `Provenance` 4 mã + `inferred` | hoà, khác mục đích |
| **Từ chối trả lời khi thiếu** | band `null` ⇒ không lưu | `ProfitInsufficient` + blockers | **Tổng Tài** (chi tiết hơn) |
| **Ngăn ghi thẳng** | **không có gì** | governance suite (đã dùng 3 lần) | **Tổng Tài** |

## Ba chỗ Tổng Tài đang đi trước

**1. Governance bằng cấu trúc.** COMP AI *không có* cơ chế nào ngăn một tool mới ghi thẳng — và hậu quả nhìn thấy được: `set_field_value` thêm 2 ngày trước, bỏ qua ledger. Tổng Tài đã dựng ba suite khoá luật bằng cấu trúc và mỗi suite có test chống PASS GIẢ.

**2. Tách "nền tảng làm được" khỏi "mình làm được" khỏi "đã chạy thật".** COMP AI không cần vì họ có 4 nguồn. Tổng Tài cần vì AI sẽ nói chuyện với người bán về 10+ sàn.

**3. Từ chối có lý do.** `ProfitInsufficient(blockers)` liệt kê **đủ** thứ còn thiếu. COMP AI trả một câu văn.

## Bốn chỗ Tổng Tài đang thiếu

**1. Confidence do chỗ gọi khai** — ngoại lệ duy nhất trong cả hai hệ. Xem `20-RECOMMENDATIONS.md` R-1.

**2. Không có nơi lưu đề xuất.** `SuggestLink` là giá trị trả về trong bộ nhớ. Không sống qua một lần đóng app. Không lên được **L2 · Prepare**. → R-2.

**3. Không có cửa ghi cho side effect.** Chưa vỡ vì chưa có agent — nhưng COMP AI cho thấy nó vỡ *trong vòng một tuần* sau khi có agent. → R-4.

**4. Không có vòng lặp bền vững.** Tổng Tài không có gì tiếp tục công việc sau khi người dùng đóng app. → R-6, và đây là chỗ **khó nhất** vì local-first.

## Điều COMP AI **không** giải quyết được cho ta

| Bài toán của Tổng Tài | COMP AI có gợi ý không |
|---|---|
| Agent bền vững **không có backend luôn thức** | ❌ họ có server; ta thì không |
| Nhiều người bán, mỗi người một bộ connection | ❌ single-tenant |
| Chi phí AI do **người dùng trả** (BYOK) | ❌ họ trả tiền vendor |
| Chuẩn hoá sự kiện qua **10+ nền tảng** | ❌ họ có một |
| Hành động **tiêu tiền thật** của người bán | ❌ hành động của họ chỉ ghi CRM |

**Dòng cuối là khoảng cách lớn nhất.** `sensitiveWrite` đủ cho một CRM nơi hành động tệ nhất là ghi sai chức danh. Không đủ cho một hệ có thể **đặt hàng nhập kho**. Xem `13-AUTONOMY-POLICY.md`.
