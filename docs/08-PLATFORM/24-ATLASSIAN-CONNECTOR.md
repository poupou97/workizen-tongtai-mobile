# 24 · Atlassian Connector — "công việc đang thế nào"

> **WTM-319 · C3 · Epic WTM-315** — Connector Implementation & Dogfood
> Trạng thái: **chạy được ngay** (chỉ cần Founder tạo một API token, ~1 phút).

---

## 1. ⛔ Đây KHÔNG phải Jira mobile client

Founder viết thẳng: *không board, không sprint, không backlog.*

Ý định là một câu trả lời cho một câu hỏi:

> *"Tổng Tài, cho tôi biết công việc Workizen đang thế nào."*

Nên thứ đi ra khỏi connector này là **một dòng**:

```
WTM: 12 việc đang mở · 3 đang làm · 2 ưu tiên cao · 1 bỏ quên trên hai tuần · 5 xong tuần này
```

Không phải một danh sách issue để vuốt. Nếu người bán muốn vuốt issue thì họ
đã có Jira rồi — dựng lại nó trong Tổng Tài là công sức đổi lấy một bản sao tệ
hơn.

---

## 2. Một token, hai capability, một connection

```
Atlassian Connection   (instanceUrl + email + API token)
  ├── Jira        — issue · status · priority · updated
  └── Confluence  — tiêu đề trang, làm tham chiếu tri thức
```

Cùng một API token dùng được cho cả hai (`activepieces/jira-cloud/src/auth.ts:12`
· `confluence/src/lib/auth.ts:3`). Tách thành hai connection sẽ bắt người dùng
dán cùng một chuỗi hai lần và tạo ra **hai chỗ để quên thu hồi**.

Khoá bằng test: *"MỘT connection cho cả Jira lẫn Confluence"* — một khoá trong
Keystore, một bản ghi trong DB, sau khi đã chọn cả project lẫn space.

---

## 3. Basic auth, không OAuth — và vì sao đó là lựa chọn đúng ở đây

Atlassian có OAuth 3LO, nhưng nó cần app đăng ký và `client_secret` ⇒ theo luật
WTM-309 thì **không phải mobile-direct**. API token là `email:token` base64
trong header — chạy thẳng từ máy, không backend, không xét duyệt.

**Cái giá, và nó thật:** API token mang **toàn quyền của người dùng đó**, không
giới hạn scope được như `drive.file`. Nên Tổng Tài:

- chỉ **đọc**
- chỉ đọc đúng project/space người dùng **chọn**
- ghi để phase sau, và khi làm thì **qua** `ProposedChange`/`BusinessAction`,
  không để agent gọi Atlassian API thẳng

Một khác biệt đáng nhớ so với Telegram: ở đây bí mật nằm trong **header**,
không nằm trong URL. Nên một log ghi lại URL không rò gì — ngược hẳn với
Telegram (xem `23-TELEGRAM-CONNECTOR.md` §7). Có test chốt cả hai chiều.

---

## 4. ⭐ `validate` gọi API thật **lúc nhập khoá**

Học thẳng từ Activepieces. Sai khoá phải biết **lúc dán**, không phải lúc agent
chạy rồi thất bại im lặng ba ngày sau.

| Bước | Trạng thái | Vì sao |
|---|---|---|
| khoá **sai** | `SETUP_REQUIRED`, **không lưu gì** | `/myself` hỏng ⇒ không có gì đáng lưu. Lưu bí mật vô dụng rồi đánh dấu `error` chỉ để lại rác trong Keystore |
| khoá **đúng**, chưa chọn dự án | **vẫn** `SETUP_REQUIRED` | có khoá mà chưa biết đọc dự án nào thì chưa trả lời được câu hỏi nào |
| đã chọn dự án | `ACTIVE` | |

Và bốn mã lỗi được phân biệt, vì bốn cách sửa khác nhau:

| Mã | Nghĩa | Người dùng phải làm gì |
|---|---|---|
| 401 | email/token sai | tạo lại token |
| 403 | token đúng, không có quyền vào chỗ đó | xin quyền, hoặc chọn chỗ khác |
| 404 | sai instance URL | sửa địa chỉ |
| `badInstanceUrl` | URL gõ sai ngay từ đầu | thêm `https://` |

Gộp cả bốn thành "lỗi kết nối" là đẩy người dùng đi thử ngẫu nhiên bốn thứ.

---

## 5. Đếm theo `statusCategory`, không theo tên cột

Tên cột mỗi project một kiểu — dự án WTM có `ANALYSIS` · `Ready` ·
`In Progress` · `Code Review` · `QA` · `Done` — và ai cũng đổi được từ giao
diện Jira.

`statusCategory` chỉ có ba giá trị (`new` · `indeterminate` · `done`) và
Atlassian giữ ổn định. Đếm theo tên cột là đếm theo một thứ **sẽ đổi mà không
ai báo**, và con số sẽ sai âm thầm.

Khoá bằng test: ba issue ở ba cột tên khác nhau nhưng cùng `indeterminate` phải
đếm như nhau.

---

## 6. Chưa biết ⇒ **không đoán**

| Tình huống | Cách xử | Vì sao |
|---|---|---|
| issue `done` mà **không có** mốc cập nhật | **không** đếm vào "xong tuần này" | đoán ở đây là bịa một con số cho Founder đọc |
| `priority: null` | không phải "ưu tiên thấp nhất" | project không bật priority là chuyện bình thường |
| `assignee: null` | "chưa giao", không phải lỗi | |
| chưa chọn dự án | `workContext` trả `null`, **không gọi Jira** | `null` = *chưa hỏi được*, khác một context rỗng = *đã hỏi và không có việc nào* (ADR-TON-017: `insufficient` ≠ `empty`) |
| không có issue nào | `hasData == false`, `headline == null` | Rule Twin từ chối trả lời khi thiếu dữ liệu — và từ chối là một câu trả lời, khác hẳn một câu trả lời lạc quan |

---

## 7. Confluence: tiêu đề, **không phải nội dung**

Cố ý không tải body trang.

Biến mọi đoạn văn Confluence thành "sự thật kinh doanh" là cách nhanh nhất để
một bản nháp từ năm ngoái trở thành căn cứ cho một đề xuất hôm nay. Trang là
**tham chiếu tri thức** — người đọc nó là con người, không phải một prompt.

Và người dùng **chọn space**. Không crawl toàn workspace.

---

## 8. Founder cần làm gì (~1 phút)

1. `id.atlassian.com/manage-profile/security/api-tokens` → **Create API token**
2. Trong Tổng Tài: **Kết nối** → *Công việc trong Jira & Confluence*
3. Dán ba thứ: địa chỉ (`https://workizen.atlassian.net`) · email · token
4. **Kiểm tra và lưu** → chọn dự án (`WTM`) → chọn không gian (`workizento`)

Không OAuth, không client ID, không xét duyệt — giống Telegram, khác Drive.

---

## 9. Bản đồ file

| File | Việc |
|---|---|
| `connection/atlassian/atlassian_client.dart` | REST: `/myself` · project search · JQL search · spaces · pages; đọc chuỗi lồng sâu chịu được `null` ở giữa |
| `connection/atlassian/atlassian_connection.dart` | vòng đời: khoá → chọn dự án → `ACTIVE`; phân loại lỗi ở đây để `ui/` không catch |
| `connection/atlassian/work_context.dart` | Capability Context (ADR-TON-016) — hàm thuần, không mạng, không DB |
| `ui/screens/tongtai_connections_screen.dart` | thẻ Atlassian trong màn Kết nối |
