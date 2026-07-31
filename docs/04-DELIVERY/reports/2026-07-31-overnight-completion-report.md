# Completion Report — đêm 2026-07-31

**Chế độ:** Founder Autonomous Overnight Mode · **Nhánh đích:** `main`, CI xanh
sau từng lần merge · **Tests:** 1394 → **1418** · **Founder Gate chạm phải:** 0
(một gate đã mở trước đó và đã được Founder xử lý — Epic WTM-167).

> Đọc file này là đủ. Chi tiết từng story ở Jira và trong PR tương ứng.

---

## 1. Đã giao

| Jira | Việc | PR | Trạng thái |
|---|---|---|---|
| WTM-165 | `.ttbk` = **Business Snapshot Package** (chừa chỗ, không khoá đường) | #79 | Done |
| WTM-166 | **Cold start đã đo** trên máy thật | #80 | Done |
| **Epic WTM-167** | **Capability Context Performance** + ADR-TON-019 DRAFT + benchmark 3/12/24/60 tháng | #81 | mở, chờ chọn hướng |
| WTM-168 | **Accessibility** — 29 màn, 4 guideline của Android | #82 #83 #85 | Done |
| WTM-37 | **Chính sách quyền riêng tư** viết theo hành vi thật | #84 | Done |
| WTM-169 | **11 nút bấm không ra gì** ở màn Cài đặt | #86 | Done |
| WTM-170 | **13 chuỗi tiếng Anh hardcode** trong bản tiếng Việt | #87 | Done |
| WTM-171 | **2 future đọc dữ liệu không ai bắt lỗi** | #88 | Done |
| WTM-173 | **Bản sao lưu an toàn không mở lại được** (ADR-TON-018 am.2) | #89 | Done |
| WTM-172 | Badge sức khỏe Home hiện tiếng Anh | #90 | chờ CI |

⚠️ **Số Jira lệch tên nhánh** ở bốn story cuối: Jira cấp số *sau* khi tôi đặt
tên nhánh, nên `fix/wtm-171-*` = **WTM-170**, `fix/wtm-172-*` = **WTM-171**,
`feat/wtm-173-*` = **WTM-173**, `fix/wtm-174-*` = **WTM-172**. Đọc mô tả PR để
khớp, đừng đọc tên nhánh.

---

## 2. Quyết định kiến trúc quan trọng

### ADR-TON-019 (DRAFT) — Capability Context Performance

Founder đã mở Epic riêng và chỉ thị **không refactor trong WTM-166**. Đã giao
đúng ba thứ: Epic · ADR draft **cố tình không chọn hướng** · benchmark cố định.

Điểm cần nhớ khi quay lại: **mỗi lần đọc lặp đều chính đáng.** `orders` bị đọc 5
lần bởi metrics · order context · journey · timeline · rule engine — hệ quả trực
tiếp của một quyết định **đúng** (ADR-TON-016: Capability Context độc lập, tải
on-demand). Không được "sửa" nó như sửa một lỗi.

Benchmark cho hai kết quả định hướng:

| tháng | orders | 1 lượt đọc | hydration | tỉ lệ |
|---|---|---|---|---|
| 12 | 529 | 15ms | 52ms | 3.5× |
| 24 | 2.115 | 31ms | 144ms | 4.6× |
| **60** | **18.083** | **298ms** | **1.332ms** | **4.5×** |

1. Query counts **giống hệt nhau ở cả 4 mốc** ⇒ đọc lặp là thuộc tính của **cách
   nối dây**, không phải của dữ liệu ⇒ sửa được ở tầng kiến trúc.
2. Ở 60 tháng **đọc lặp chiếm ~80%** chi phí. Nhưng điều đó *không* chọn hướng
   thay Founder: hướng "Drift query optimization" vẫn có thể thắng nếu nó làm
   mỗi lần đọc **rẻ đi** thay vì **ít lần đi**.

### ADR-TON-018 amendment 2 — bản sao lưu an toàn phải mở lại được

Xem §3.

### Nguyên tắc màu (WTM-168)

Màu thương hiệu ở bước -500 là **màu nền**; khi mang **chữ** thì dùng **cặp song
sinh -700** (`readableText(base)`). Bảng màu thương hiệu **không đổi** — chỉ chỗ
có chữ mới sâu lại. Đây là hệ quả bắt buộc của WCAG 4.5:1, và nó **nhìn thấy
được**: nút chính ở Export/Inventory/Finance/onboarding đậm màu hơn.
**Nếu anh muốn giữ đúng sắc cũ**, cách còn lại là đổi sang **chữ đen trên nền
màu**. Nói một tiếng là tôi đổi.

---

## 3. Sáu lỗi thật, và cách tìm ra chúng

Điều đáng nói không phải số lượng, mà là **mỗi lỗi cần một cách tìm khác nhau** —
không lỗi nào lộ ra khi đọc code một cách bình thường.

| Cách tìm | Lỗi |
|---|---|
| Chạy **guideline của Android** | 28 vi phạm contrast/tap target trên 29 màn |
| Thêm **màn còn thiếu** vào suite overflow | 5 lỗi tràn thật, gồm pagination bar **nuốt nút "trang sau"** |
| `grep "onTap: () {}"` | **11 nút chết**, gồm **"Đăng xuất" trong app không có tài khoản** |
| Quét `Text()` tìm chữ ASCII ngoài nội suy | **13 chuỗi tiếng Anh**, gồm `Today's Missions` trên Home |
| Quét màn có `initState` ngoài seam ADR-TON-017 | **2 future đọc không ai bắt lỗi** |
| **Chụp màn hình bản release trên máy thật** | badge `Not enough data` — **không phép quét tĩnh nào bắt được** |

Ba lỗi đáng chú ý:

**Màn Rủi ro khách hàng** đọc tên khách bằng `await loadAll()` trần. Đọc hỏng ⇒
map tên rỗng — và **một map tên rỗng không trông giống lỗi**, nó trông giống một
danh sách khách hàng không có tên, còn phần đánh giá rủi ro bên cạnh **vẫn render
như sự thật**. Đây đúng lớp lỗi WTM-148 sinh ra để chặn.

**Bản sao lưu an toàn** của WTM-164 được tạo và verify đầy đủ — rồi ghi vào thư
mục riêng của app, nơi trình chọn file **không với tới**. File duy nhất tồn tại
để cứu một lần restore nhầm lại là file duy nhất người bán không mở được. Ở
WTM-164 tôi ghi việc này là *một hạn chế của phép thử trên máy*. **Nó là một lỗ
hổng an toàn dữ liệu**, và tôi đã gọi sai tên nó lúc đó.

**"Đăng xuất"** trong một sản phẩm mà D-4 nói rõ là *không cần tài khoản*. Bốn
dòng cùng loại (Hồ sơ · Đội ngũ · Phân quyền · Đăng xuất) không phải *chưa làm*
mà **không thể có** — nên gỡ hẳn, không để xám. Sáu dòng thật sự trên lộ trình
thì ghi **"Sắp có"** và không bấm được.

---

## 4. Đo trên thiết bị

**Cold start (Android tự báo, bản release, cold thật sự):**

| máy | n | min | median | max |
|---|---|---|---|---|
| Galaxy S24 Ultra | 5 | 249ms | 255ms | 316ms |
| **Nokia 6.1** (máy tầm thấp) | 5 | **750ms** | **778ms** | **794ms** |

Nokia 6.1 chậm hơn **~3×** nhưng vẫn **dưới một giây**. Đây là số quan trọng hơn
số của S24: người bán mục tiêu dùng máy như thế này. WTM-166 chỉ có số của máy
đầu bảng; giờ có cả hai.

**Smoke test bản release trên Nokia 6.1** — `adb logcat -b crash` **rỗng**:
onboarding (nút đã đổi màu, đọc được) · Home tiếng Việt · màn Cài đặt (có "Sắp
có", **không còn nút Đăng xuất**) · màn Chính sách quyền riêng tư mở được và
hiển thị đúng.

**Mốc trong app trên Nokia 6.1** (bỏ lần chạy sau khi cài vì có dexopt):
`prefs 165ms` (S24: **13ms**) · `telemetry-init 204ms` · `db-open 288ms` ·
`4 tab có dữ liệu 315–334ms` · `first-frame 425ms`. **Home vẫn có dữ liệu trước
khung hình đầu tiên** — kết luận chính của WTM-166 đúng cả trên máy yếu.

**Một tối ưu đã thử và bỏ.** Máy yếu lộ ra `SharedPreferences` tốn 165ms và chặn
`runApp`, Firebase init nối đuôi sau. Hai việc độc lập ⇒ thử gộp chạy cùng lúc.
**Đo lại: không nhanh hơn** (200/226/240ms vs 204/212ms) — cả hai đi qua **cùng
một platform channel** vốn tuần tự, nên "song song" ở tầng Dart chỉ xếp cùng một
hàng đợi. Đã bỏ, vì nó không mua được gì và **làm mất độ phân giải chẩn đoán**.
Ghi lại trong `WTM-166-cold-start.md` §7 để người sau không thử lại.

**Chưa đo:** hydration ở 24/60 tháng **trên thiết bị**. Baseline host cho thấy
60 tháng nặng gấp ~25 lần 12 tháng, nhưng **nhân tỉ lệ host lên để suy ra
mili-giây điện thoại là đúng thứ Testing Bible P-16 cấm**. Cần seed dữ liệu trên
máy rồi đọc `StartupTrace` — tôi không tự seed vì đó là ghi dữ liệu mẫu vào máy
của anh.

---

## 5. Cần anh quyết / cung cấp

1. **Địa chỉ liên hệ** cho §10 chính sách quyền riêng tư — **bắt buộc trước khi
   lên cửa hàng ứng dụng**.
2. **Epic WTM-167** — chọn hướng trong năm hướng của ADR-TON-019 (chưa cần gấp;
   Founder đã xếp sau Privacy + Accessibility).
3. **Màu nút đậm hơn** (§2) — giữ hay đổi sang chữ đen trên nền màu.
4. **"Điều khoản dịch vụ"** đang là "Sắp có". Cửa hàng thường yêu cầu có; cần
   nội dung pháp lý từ anh, tôi không tự viết.

## 6. Còn treo (không phải blocker)

* Bước **apply** của restore vẫn chưa chạy trên máy thật — nhưng giờ **đã có
  đường lùi** (WTM-173), nên lần sau chạy được mà không mất dữ liệu.
* **iOS** chưa build/sign.
* Màn `component_showcase` là tham chiếu dev-only, không có đường vào từ
  production (đã kiểm: **không có màn mồ côi nào khác**).

---

## 7. Bài học lặp lại — đáng nhớ

**Test tìm bằng chuỗi hiển thị vỡ ba lần trong một ngày.**
`find.text('Page 1 of 2')` đỏ ngay khi đổi từ ngữ, ở màn Inventory rồi màn
Customer list. Quy ước repo đã nói rõ: tìm bằng **Key**. Đã sửa cả hai và thêm
`inventory-page-indicator` / `customer-page-indicator`.

**Một suite xanh chỉ nói về danh sách trong suite.** Ba tab chính vắng mặt trong
bộ overflow của P0 suốt thời gian dài; thêm vào là lộ ra năm lỗi đã ở đó từ lâu.

**Phép quét tĩnh có trần của nó.** 13 chuỗi tiếng Anh tìm được bằng grep; chuỗi
thứ 14 — ngay trên Home — chỉ lộ ra khi **nhìn vào màn hình thật**.
