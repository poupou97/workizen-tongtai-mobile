# ADR-TON-017 — Shared Error-Handling Seam (Screen State Contract)

- **Status:** ✅ ACCEPTED (Founder directive "tiếp tục backlog · ưu tiên WTM-148", 2026-07-31)
- **Jira:** WTM-148
- **Extends:** ADR-TON-015 (UI Maturity L0–L4, One Data Path) · ADR-TON-005 /
  D-7 (telemetry chỉ vận hành) · ADR-TON-016 (Rule Twin trả lời "chưa đủ dữ
  liệu" thay vì bịa số)
- **Supersedes:** không.

## Vấn đề

Audit ADR-TON-015 (WTM-147) đếm được: **1 trên 34 màn** có xử lý lỗi thật
(`tongtai_ai_key_screen`). Mọi màn còn lại dùng đúng một khuôn:

```dart
initState() { _load(); }
Future<void> _load() async {
  final rows = await repo.loadAll();   // ném lỗi ⇒ future không ai bắt
  setState(() => _rows = rows);        // ⇒ không bao giờ chạy
}
```

Repository ném lỗi thì màn **đứng nguyên ở giá trị khởi tạo rỗng, vĩnh viễn**.
Người dùng — và cả chúng ta — không có tín hiệu nào. **"Không có dữ liệu" và
"không đọc được dữ liệu" hiển thị y hệt nhau.**

Đó chính là lớp lỗi đã sinh ra bug Founder báo: *Home Consumer = 1, tab Khách
hàng trống* (Testing Bible P-03). Nguy hiểm nhất ở màn tiền: doanh thu `0 ₫` do
đọc hỏng **đọc như một sự thật về công việc kinh doanh**.

Sửa từng màn = 25 phiên bản hơi khác nhau của "có gì đó sai sai" → không màn
nào phân biệt nổi *thiếu dữ liệu* với *hỏng đường dữ liệu*.

## Quyết định

**Thất bại chảy một đường, giống như dữ liệu chảy một đường.**

### 1. Sáu trạng thái, không phải hai

`ScreenState<T>` (`lib/features/tongtai/core/screen_state.dart`):

| Trạng thái | Nghĩa |
|---|---|
| `loading` | lần đọc đầu đang chạy, chưa biết gì |
| `ready` | đã có giá trị |
| `empty` | có giá trị, và nó **hợp lệ** không có bản ghi nào |
| `insufficient` | có giá trị, nhưng **domain từ chối kết luận** (ADR-TON-016) |
| `refreshing` | có giá trị, một lần đọc mới đang chạy |
| `failed` | lần đọc ném lỗi — **giữ nguyên giá trị cũ nếu có** |

`empty` và `insufficient` là **câu trả lời**. `failed` là **không có câu trả
lời**. Gộp chúng lại chính là bug này.

Bất biến ép ở constructor (bài học ADR-TON-016 — luật mà kiểu không diễn đạt
được là luật sẽ bị phá):

- `failed` ⟺ có `failure`;
- `ready`/`refreshing` ⟹ có `value`;
- có `value` ⟹ có `loadedAt` (nên "đang xem dữ liệu lúc 09:41" luôn nói được).

### 2. Lỗi được phân loại, không phải văn vẻ

`TongtaiFailure{kind, code, detail, cause}`:

- `kind` ∈ `storage · network · permission · configuration · unexpected`;
  quyết định câu chữ **và** có mời thử lại hay không. `permission` /
  `configuration` **không** có nút Thử lại — cách sửa nằm ngoài lời gọi vừa
  hỏng, mời thử lại chỉ dạy người dùng rằng nút đó vô nghĩa.
- `code` là token cố định, hữu hạn (`storage.sqlite_787`, `ai.rateLimit`).
- Phân loại theo **tên kiểu runtime**, nên file này không import sqlite3/dart:io
  — đổi package không làm vỡ seam. Module nào muốn tự khai báo phân loại thì
  implement `TongtaiClassifiedError` (AI đã làm), **phụ thuộc hướng vào trong**.

### 3. Không đánh tráo lỗi kỹ thuật bằng câu nói mơ hồ

Màn lỗi hiện: câu theo `kind` + **`code` luôn hiện** + `detail` nguyên văn sau
một lần chạm. Đây là yêu cầu của Founder, không phải tuỳ chọn: *"Không biến lỗi
kỹ thuật thành thông báo mơ hồ hoặc số liệu giả."*

### 4. Loading **không animation**

Tổng Tài local-first: một lần đọc là vài mili-giây. Spinner vô hạn (a) nháy vào
mắt người dùng rồi biến mất, (b) khiến `pumpAndSettle` treo vĩnh viễn vì luôn
có frame được lên lịch. Nên `TongtaiLoadingView` là **text tĩnh**; chỉ hành
động do người dùng chủ động bấm (gọi AI, xuất file) mới quay —
`TongtaiInlineBusy`.

Đánh đổi: `pumpAndSettle` cũng **không còn chờ** load. Idiom kèm theo:
`pumpUntilFound` trong `test/support/pump_until.dart`.

### 5. Riêng tư: cái người dùng thấy ≠ cái được gửi đi

| | Nội dung | Đi đâu |
|---|---|---|
| `detail` | nguyên văn exception (có thể chứa giá trị dòng dữ liệu) | **chỉ màn hình máy người dùng** |
| `kind` + `code` | token do lập trình viên đặt | telemetry `screen_error` |

`TongtaiFailure.toString()` **cố tình bỏ `detail`**, vì crash reporter ghi lại
`toString()`. Cái được `recordError` là `TongtaiFailure`, **không phải**
exception gốc.

### 6. Ghi dữ liệu cũng không được im lặng

`runTongtaiAction` trả `TongtaiFailure?` thay vì ném. Trước đó
`tongtai_export_screen` có `try/finally` **không có catch**: xuất file hỏng thì
spinner tắt và trông y như thành công.

### 7. Giữ nguyên dữ liệu khi refresh lỗi

`failed` giữ `value` ⇒ **stale**: dữ liệu vẫn đọc được, kèm banner nói rõ nó cũ
từ lúc nào. Refresh hỏng **không bao giờ** xoá trắng màn đang chạy được.

## Ràng buộc kiến trúc (governance bằng code, không bằng lời)

`test/features/tongtai/p0/error_handling_governance_test.dart` khoá:

1. mọi file `ui/` có gọi IO phải tham chiếu seam;
2. cấm spinner vô hạn tự chế (thanh có `value:` là **dữ liệu**, được phép);
3. **cấm `catch` trong `ui/`** — đọc qua `ScreenDataController`, ghi qua
   `runTongtaiAction`;
4. cấm `FutureBuilder` / `AsyncValue.when` (không có trạng thái *stale*);
5. **đúng một** `tongtaiDatabaseProvider`;
6. telemetry chỉ mang `kind`/`code`/`screen`; `detail` không được chạm đường
   báo cáo; `screen_error` phải có trong `TELEMETRY-EVENTS.md`.

## Hệ quả

- ~26 màn L2 → **L3**; `reports` + `opportunity_detail` → **L4** (AI đã ship).
- Hai màn predictive dùng chung trạng thái `insufficient` với Rule Twin, nên
  "chưa đủ dữ liệu" và "đọc hỏng" **không thể** trông giống nhau nữa.
- Màn mới thừa hưởng toàn bộ; ai tự chế lại sẽ trượt governance ngay trong PR.
- Test cũ dựa vào `pumpAndSettle` để chờ load phải chuyển sang `pumpUntilFound`.

## Hai lỗi thật seam phát hiện ngay khi bật

1. **`tongtaiDatabaseProvider` khai báo hai lần** (`tongtai_search_provider` tự
   khai báo một cái riêng): production mở **hai kết nối** vào cùng một file
   `.db`, và test override "database" chỉ trúng một nửa app — Home đọc hỏng mà
   mọi assertion vẫn xanh. Vi phạm One Data Path (ADR-TON-015). Đã gộp về một.
2. **Export `try/finally` không `catch`** — xuất hỏng trông như xong.

## Phương án đã cân nhắc

- **Sửa từng màn.** Rẻ trước mắt, nhưng đúng là cách sinh ra 25 dị bản; và
  không có chỗ nào để đặt ranh giới riêng tư.
- **Dùng thẳng `AsyncValue.when`.** Ba nhánh, **không có** *stale* — refresh
  hỏng sẽ xoá trắng màn đang chạy. Giữ `AsyncValue` cho provider, nhưng bọc
  qua `TongtaiAsyncScreenData` để về đúng sáu trạng thái.
- **Spinner tiêu chuẩn.** Làm treo `pumpAndSettle` ở 30 test và nháy vào mắt
  người dùng cho một lần đọc 5 ms.
