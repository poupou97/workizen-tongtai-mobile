# Tổng Tài Design System v1.0

> Epic **WTM-362** · directive Founder 2026-08-11 · cập nhật 2026-08-11.
> **Visual reference:** `docs/01-PRODUCT/concept-1/concepts.png`.
> Khi ảnh và tài liệu này lệch nhau, **tài liệu thắng** — ảnh là tham chiếu thị
> giác, không phải bảng màu để lấy mẫu pixel.
>
> Mã nguồn: `lib/core/design/` — nhập một dòng là đủ:
> `import 'package:tongtai/core/design/tt.dart';`

---

## 1 · Ba câu phải nhớ trước mọi thứ khác

**CAM = tôi bấm được · TÍM = Tổng Tài đang hiểu · XÁM = chưa biết.**

Ba lỗi dưới đây làm người dùng hiểu sai sản phẩm, và cả ba đều dễ mắc:

| ⛔ Đừng | Vì sao |
|---|---|
| Tô câu kết luận của AI màu **cam** | Nó dạy người bán rằng chữ cam nghĩa là *"AI nói"*, rồi họ thôi bấm những nút thật sự bấm được |
| Tô *"chưa đủ dữ liệu"* màu **xanh** | Một ô trống tô xanh là lời trấn an cho điều chưa ai kiểm |
| Bọc mọi đoạn chữ vào một **thẻ** | Màn hình thành bảng điều khiển và không còn thứ tự đọc |

## 2 · Brand principles

Thông minh · Chủ động · Đáng tin · Thực dụng · Bình tĩnh.

Cảm giác phải tạo ra: *"AI hiểu doanh nghiệp, phát hiện điều quan trọng và giúp
tôi hành động."* — **không** phải chatbot, không phải ERP thu nhỏ, không phải
dashboard BI trên điện thoại.

---

## 3 · Color tokens · `TtColors`

| Vai | Token | Hex |
|---|---|---|
| Thương hiệu (biểu tượng, viền, chữ trên nền sáng) | `brand` | `#F97316` |
| ⚠️ **Nền cho chữ trắng** | `brandOnDark` | `#C2410C` |
| Nhấn | `brandPressed` | `#9A3412` |
| Nền cam nhạt | `brandSoft` | `#FFF7ED` |
| **AI / trí tuệ** | `ai` | `#7C3AED` |
| Nền AI | `aiSoft` · `aiBorder` | `#F5F3FF` · `#DDD6FE` |
| Tích cực | `success` · `successSoft` | `#16A34A` · `#F0FDF4` |
| Thông tin | `info` · `infoSoft` | `#2563EB` · `#EFF6FF` |
| Cần chú ý | `warning` · `warningSoft` | `#F59E0B` · `#FFFBEB` |
| Nguy cấp | `danger` · `dangerSoft` | `#DC2626` · `#FEF2F2` |
| **CHƯA BIẾT** | `unknown` · `unknownSoft` | `#94A3B8` · `#F1F5F9` |
| Chữ | `textPrimary/Secondary/Tertiary` | `#0F172A` · `#475569` · `#94A3B8` |
| Mặt nền | `surface/Secondary/Tertiary` | `#FFFFFF` · `#F8FAFC` · `#F1F5F9` |
| Viền | `border` · `borderStrong` · `divider` | `#E2E8F0` · `#CBD5E1` · `#E5E7EB` |

### ⚠️ Một chỗ lệch khỏi spec, và lý do

Spec ghi nền nút chính là `#F97316` với chữ trắng. Tỉ lệ tương phản của cặp đó
là **2,80:1** — dưới ngưỡng WCAG AA 4,5:1, và suite `accessibility_test` của
repo bắt được ngay khi thử.

Nên `brand` tách làm hai vai: giữ `#F97316` cho biểu tượng/viền/chữ trên nền
sáng, và **`brandOnDark` `#C2410C` (5,18:1)** làm nền cho chữ trắng — sắc cam
sáng nhất còn qua được ngưỡng. `tt_tokens_test.dart` tính tỉ lệ tại chỗ theo
công thức WCAG, không chép sẵn con số.

Cùng bài học mà `TongtaiDesignTokens` đã ghi cho `inventoryOrange` (2,15:1).

### `TtStatus` — một chủ duy nhất cho ánh xạ mức → màu

`success · info · warning · danger · ai · unknown`. Màn hình **không** được
viết `switch` màu riêng: hai bảng ánh xạ sẽ lệch nhau đúng vào ngày ai đó sửa
một bên (P-27/P-28, repo này đã dọn bốn lần).

---

## 4 · Typography · `TtType`

Inter, dự phòng SF Pro (iOS) → Roboto (Android) → hệ thống. Khai
`fontFamilyFallback` là bắt buộc: tiếng Việt có dấu chồng, và máy thiếu Inter mà
không có fallback sẽ dựng dấu bằng font mặc định trông rất khác.

| Token | px / weight / line-height |
|---|---|
| `display` | 28 / 700 / 34 |
| `h1` `h2` `h3` | 24/700/30 · 20/700/26 · 18/600/24 |
| `title` | 16 / 600 / 22 |
| `bodyLarge` `body` `bodyMedium` | 16/400/24 · 14/400/20 · 14/500/20 |
| `caption` `label` | 12/400/16 · 12/600/16 |
| `metricLarge` `metric` | 28/700/34 · 20/700/26 |

**KPI đậm · tiêu đề semibold · thân bài thường · hành động semibold.** Không
biến cả UI thành đậm.

## 5 · Spacing · `TtSpace` — lưới 4px

`x1 4 · x2 8 · x3 12 · x4 16 · x5 20 · x6 24 · x8 32 · x10 40 · x12 48`

Lề ngang màn `screenH` 16 · giữa hai khối `section` 24 · tiêu đề→nội dung
`headingToContent` 12 · thẻ `cardPadding` 16 · hero `heroPadding` 20.

Ưu tiên khoảng thở. Không nhét thêm chỉ vì màn còn chỗ.

## 6 · Radius · `TtRadius`

`xs 6 · sm 8 · md 12 · lg 16 · xl 20 · sheet 24 · full 999`

Nút và ô nhập **12** · thẻ tiêu chuẩn **16** · thẻ AI/hero **20** · chip **full**.

> ⚠️ **Migration:** tên ở đây lệch tên cũ một bậc. `TongtaiDesignTokens.radiusLg`
> = 12 ↔ `TtRadius.md`; `radiusXl` = 16 ↔ `TtRadius.lg`. **Di trú theo giá trị,
> không theo tên** — đổi tên tại chỗ sẽ âm thầm bo lại góc của mọi màn đang chạy.

## 7 · Elevation · `TtElevation`

**Mặc định là KHÔNG có bóng.** Trên nền sáng viền đọc rõ hơn, và một màn mà mọi
thẻ đều nổi lên thì không thẻ nào còn nổi.

`soft` chỉ khi thật cần · `floating` chỉ cho FAB, modal, thanh dính đáy, overlay.

## 8 · Motion · `TtMotion`

`fast 120ms · normal 200ms · slow 300ms`, `easeOutCubic`. Insight hiện ra: mờ
dần + trượt lên 8px.

⛔ **Không có hằng số "thời lượng loading".** Nó là chỗ để đặt một thanh chạy
giả vào ngày mai — có test quét tên bị cấm.

---

## 9 · Component catalog

| Component | Khi nào |
|---|---|
| `TtPrimaryButton` | một **việc kinh doanh thật** — cam |
| `TtSecondaryButton` | xem · lưu · so sánh — trắng + viền |
| `TtAiActionButton` | hỏi/xem thứ **AI** nói — nền tím **nhạt**, chữ tím |
| `TtTextAction` | *"xem tất cả →"* |
| `TtCard` | một **đối tượng nghiệp vụ** rõ ràng |
| `TtAiCard` | *"Tổng Tài phát hiện"* · AI Insight · AI Brief |
| `TtStatusCard` | mang một mức khẩn — **vạch đặc** bên trái |
| `TtStatusBadge` | nhãn trạng thái |
| `TtMetric` · `TtMetricRow` | 3–4 KPI trên **cùng một mặt** |
| `TtEmptyState` | *"đã xét và không có gì"* |
| `TtInsufficientData` | *"chưa xét được"* — **xám**, bắt buộc nói thiếu gì |
| `TtSectionHeader` | tiêu đề khối + lối "xem tất cả" |
| `TtAiStory` | **ngôn ngữ thị giác AI** — xem §10 |

Chiều cao nút **48**, vùng chạm tối thiểu **44×44** — nằm ở `TtButtonMetrics`,
không rải trong màn.

⛔ **Không có nút tím đặc.** Nút AI phải **mời**, không **giục**; tím đặc trông
ngang hàng nút cam và dạy người bán rằng hai thứ đó cùng loại.

---

## 10 · ⭐ Ngôn ngữ thị giác AI · `TtAiStory`

```
QUAN SÁT   (tím)      "Tổng Tài phát hiện 3 SKU có nguy cơ hết hàng."
   ↓
LÝ LẼ      (neutral)  "Bán trung bình 12/ngày. Tồn còn 31."
   ↓
ĐỀ XUẤT    (tím)      "Nên nhập thêm 120 sản phẩm."
   ↓
HÀNH ĐỘNG  (cam)      [Tạo đơn nhập]
   ↓
KẾT QUẢ    (semantic) xanh / đỏ / lam
```

**Đây là component, không phải guideline.** Một guideline được tuân thủ đúng
tới lúc có người vội; đặt trật tự vào **kiểu dữ liệu** thì màn hình muốn kể sai
cũng không có chỗ để làm.

Ba ràng buộc kiểu ép được:

1. **`observation` bắt buộc** — thẻ mở đầu bằng đề xuất là lời khuyên không căn cứ.
2. **`reasoning` là neutral** — tô tím cả phần *"vì sao"* làm cả thẻ thành khối
   tím, và người bán mất chỗ bấu để phân biệt điều AI **thấy** với điều AI
   **suy ra**.
3. **`TtAiAction.onPressed` không nullable** — không ai dựng được một hành động
   chưa nối vào đâu. Lỗi CTA chết của dogfood WTM-360 nay là lỗi biên dịch.

---

## 11 · Thứ tự thông tin trên mọi màn

```
TRẠNG THÁI DOANH NGHIỆP → AI INSIGHT → QUYẾT ĐỊNH → HÀNH ĐỘNG → CHI TIẾT QUẢN TRỊ
```

Ví dụ **Tài chính**: sức khoẻ tài chính → cảnh báo AI → KPI → dòng tiền → phát
hiện → tài khoản/giao dịch. **Không** phải giao dịch → tài khoản → sổ cái → AI ở
cuối.

Ví dụ **Khách hàng**: dữ liệu khách → AI insight → phân khúc → hành động giữ chân.

## 12 · Mascot · `MascotPose`

25 tư thế trong `assets/mascot/poses/`, cắt từ `icon mascot.png` bằng phân tích
thành phần liên thông. Tên theo **việc** (`greeting` · `working` · `explaining`
· `planning` · `warning` · `celebrating` · `calm` · `idle`), không theo vị trí.

Xuất hiện khi AI **tự giới thiệu · đang phân tích · đang trình bày · đang đề
xuất · đang cảnh báo · đang mừng một mốc**. Không rải khắp nơi: một con cáo ở
mọi màn thì không màn nào còn nghĩa là *"chỗ này AI đang nói"*.

Tư thế đổi theo **kết luận**, không theo màn. Một con cáo hớn hở trên màn *"chưa
đủ dữ liệu"* là hình ảnh nói dối trước cả chữ.

Nhãn trợ năng nói **AI đang làm gì**, không tả con cáo.

---

## 13 · ⛔ Trust rule

Design System **không được làm capability giả trông như thật**.

Không nhà cung cấp giả · không phân tích giả · **không tiến trình giả** · không
lợi nhuận kỳ vọng giả · không sàn "đã kết nối" giả.

Thiếu dữ liệu ⇒ `TtInsufficientData`, hoặc ẩn hẳn. Không tự tạo số đẹp chỉ để
giống `concepts.png`.

Hai chỗ concept vẽ sai và **không được chép**:
- thanh khởi động đứng ở **68%** — phần trăm chỉ hợp lệ khi là *bước thật đã
  xong / tổng bước thật*;
- *"đang kiểm tra… các mô hình AI"* — app **không tải mô hình nào** lúc khởi
  động.

---

## 14 · Migration rules

1. **Không big-bang.** Màn nào chạm tới thì đưa màn đó về DS.
2. **Không kiến trúc song song.** `TongtaiDesignTokens` vẫn sống; DS không thay
   nó bằng một bản sao mà thay dần theo **giá trị**.
3. **Không đổi business logic để sửa hình.** Bốn bản sửa dogfood WTM-360 phải
   giữ nguyên hành vi qua mọi lần đổi giao diện.
4. **Nút trong `Row` phải khai `expand: false`** — mặc định giãn hết chiều rộng,
   và trong `Row` đó là ràng buộc ngang vô hạn làm cả màn không dựng được.
5. Test đo **nghĩa**, không đo cách component được dựng bên trong: khẳng định
   chữ hiện ra, đừng chọc vào `FilledButton.child`.

### Đã migrate

| Màn | Story |
|---|---|
| `tongtai_onboarding_v2_screen` | WTM-365 |
| `tongtai_startup_screen` | WTM-367 (dựng mới trên DS) |
| `tongtai_home_screen` | WTM-369 |
| `tongtai_producer_screen` | WTM-370 |
| `tongtai_inventory_screen` | WTM-370 |
| `tongtai_consumer_screen` | WTM-370 |
| `tongtai_opportunity_feed_screen` | WTM-370 |
| `tongtai_reports_screen` | WTM-371 |
| `tongtai_finance_screen` | WTM-371 |
| `tongtai_supplier_detail_screen` | WTM-371 |
| `tongtai_customer_risk_screen` | WTM-371 |
| `tongtai_customer_history_screen` | WTM-371 |
| `tongtai_opportunity_detail_screen` | WTM-371 |
| `tongtai_journey_screen` | WTM-372 |
| `tongtai_goals_screen` | WTM-372 |
| `tongtai_brief_story_screen` | WTM-372 |
| `tongtai_agent_screen` | WTM-372 |
| `tongtai_import_screen` | WTM-373 |
| `tongtai_stock_alerts_screen` | WTM-373 |
| `tongtai_more_screen` | WTM-373 |
| `tongtai_create_order_screen` | WTM-373 |
| `tongtai_forecast_screen` | WTM-373 |
| `tongtai_product_form_screen` | WTM-374 |
| `tongtai_customer_form_screen` | WTM-374 |
| `tongtai_goal_form_screen` | WTM-374 |
| `tongtai_transaction_form_screen` | WTM-374 |
| `tongtai_business_input_form_screen` | WTM-374 |
| `tongtai_goal_detail_screen` | WTM-374 |
| `tongtai_inventory_picker_screen` | WTM-374 |

### Đã đi **một nửa**

| Màn | Còn gì |
|---|---|
| `tongtai_business_life_screen` | bảng màu **chủ thể** (WTM-338) |
| `tongtai_conversations_screen` | bảng màu **chủ thể** |
| `tongtai_conversation_screen` | bảng màu **chủ thể** |
| `tongtai_customer_list_screen` | thang hạng khách **vàng/đồng** (WTM-75) |
| `tongtai_connections_screen` | **tím demo-connected** (WTM-340) |

Năm màn giữ một bảng màu **mang nghĩa riêng**, không phải màu vô chủ:

* ba màn dòng thời gian phân biệt **ai đã làm việc này** — người bán · nền tảng
  · khách;
* danh sách khách dùng **vàng/đồng** cho thang hạng — tên **kim loại**, không
  phải mức ngữ nghĩa. Ép `vip` thành `warning` sẽ biến *"khách quý nhất"* thành
  *"khách cần chú ý"*;
* màn kết nối dùng **tím demo-connected** (WTM-340), một trạng thái thứ bảy cố ý
  không mượn nhãn của `connected`. Đó là một **nghĩa thật**, không phải màu vô chủ: ép nó vào khe
ngữ nghĩa của Design System (success/info/warning) sẽ **mất đúng thứ nó đang
nói**. Chuyển bảng ấy là một quyết định sản phẩm riêng, không phải một phép thay.

Khai ở đây thay vì im lặng: một màn đi nửa đường mà không ai ghi lại thì lần sau
người ta tưởng nó đã xong. Test vẫn khoá phần **đã** đi (không còn token cũ).

> Danh sách này **được test khoá**: `test/core/design/migrated_screens_test.dart`
> quét từng màn đã migrate và bắt màu viết thẳng, token cũ, hay `switch` màu
> theo mức khẩn. Migration tăng dần chỉ có nghĩa nếu phần đã đi không trôi
> ngược. Quét cả `ui/` thì suite sẽ đỏ thường trực vì ~40 màn chưa đi — và một
> suite đỏ thường trực thì không ai đọc nữa.

### Chưa migrate

**31/50 màn đã đi** (26 trọn vẹn + 5 đi một nửa). Mọi màn ĐỌC trên đường demo,
mọi đích deep-link của kế hoạch đầu tiên, và toàn bộ đường GHI đều đã đi.

Còn lại: Sao lưu · Tìm kiếm hợp nhất · Tìm nhà cung cấp · Yêu thích NCC · Trò
chuyện + tìm trong hội thoại · Tự chủ · Hoạt động · Nguồn đầu vào · Xuất dữ
liệu · Khoá AI · Hồ sơ kinh doanh · Góp ý · Giới thiệu · Chính sách riêng tư ·
Quét khoá.

Nhóm này **người bán ít mở trong một phiên bình thường** — nên nó xuống sau
những gì họ chạm hằng ngày, đúng thứ tự ưu tiên PRODUCT EXPERIENCE.

Script di trú dùng lại được: `tools/migrate_ds.py` — nhưng đọc bảng ánh xạ dưới
đây **trước khi chạy nó trên một màn mới**.

### ⛔ Nút chính không mượn màu ngữ nghĩa của thứ khác

Lỗi tìm thấy khi làm WTM-374: **cùng một nút *Lưu* mang năm màu khác nhau** tuỳ
màn.

| Màn | Màu nút Lưu (trước) | Nó nói gì |
|---|---|---|
| Sản phẩm | hổ phách | *cần chú ý* |
| Khách | xanh dương | *thông tin* |
| Mục tiêu | tím | ***AI đang làm việc này*** |
| Giao dịch | tím | ***AI đang làm việc này*** |
| Nguồn đầu vào | mặc định theme | không nói gì |

Đây là di sản của bảng màu **theo năng lực** cũ: mỗi form ăn theo màu của
capability chứa nó. Dưới luật mới thì đó là nói **sai** — `Lưu` là một **HÀNH
ĐỘNG**, nên nó phải **cam**. Một nút *"Lưu giao dịch"* màu tím nói rằng AI đang
làm việc này, trong khi người bán mới là người làm. Đúng chỗ chỉ thị gọi tên:
***ORANGE ≠ AI***.

Bốn nút nữa cùng hình dạng: `story-accept` (xanh dương — nút hệ trọng nhất của
Business Story), `opportunity-detail-interested` và hai nút của màn nhà cung cấp
(xanh lá — *"thành công"*, trong khi chúng là **hành động chưa xảy ra**).

Cả chín nay là `TtPrimaryButton`. `migrated_screens_test.dart` bắt chiều ngược
lại: một `FilledButton` **tự sơn** màu ngữ nghĩa.

### ⚠️ Bảng ánh xạ chữ — **theo giá trị, không theo tên**

Đây là lỗi đã xảy ra thật (WTM-370): một phép thay tự động ánh xạ theo **tên**
và vì tên lệch một bậc so với giá trị, mọi tiêu đề lẫn thân bài của bốn màn bị
thu nhỏ. Triệu chứng duy nhất lộ ra là một chỗ tràn **1 pixel** — suýt trôi qua.

| Legacy | px/weight/line | → DS | px/weight/line |
|---|---|---|---|
| `displayStyle` | 32/700/40 | `TtType.display` | 28/700/34 (spec dừng ở 28) |
| `heading1Style` | 28/700/34 | `TtType.display` | 28/700/34 ✅ khớp hẳn |
| `heading2Style` | 24/600/32 | `TtType.h1` | 24/700/30 |
| `heading3Style` | 20/600/28 | `TtType.h2` | 20/700/26 |
| `bodyStyle` | **16**/400/24 | `TtType.bodyLarge` | 16/400/24 ✅ khớp hẳn |
| `smallStyle` | 14/400/20 | `TtType.body` | 14/400/20 ✅ khớp hẳn |
| `captionStyle` | 12/400/16 | `TtType.caption` | 12/400/16 ✅ khớp hẳn |

Bảng này là **mã chạy được**, không phải một dòng trong tài liệu:
`migrated_screens_test.dart` khẳng định cỡ chữ và line-height của từng cặp.

`readableOn` là một **hàm**, nên nó không dùng được trong biểu thức `const` —
mà rất nhiều chỗ dựng màu ở vị trí const. Bốn hằng `successOnLight` ·
`infoOnLight` · `aiOnLight` · `dangerOnLight` là cùng giá trị, và hàm trả về
**chính chúng** nên hai đường không thể lệch nhau.

`TongtaiDesignTokens.readableText` nay **chuyển tiếp** sang
`TtColors.readableOn` — một bảng ánh xạ, một chủ. Bảng đó phủ cả màu cũ lẫn mới
vì hai bảng màu còn sống song song trong lúc di trú.

---

## 15 · Do / Don't

| ✅ | ⛔ |
|---|---|
| Tím cho câu Tổng Tài kết luận | Cam cho câu Tổng Tài kết luận |
| Xám cho *"chưa đủ dữ liệu"* | Xanh cho *"chưa đủ dữ liệu"* |
| Thẻ khi nội dung là một đối tượng nghiệp vụ | Thẻ cho mọi đoạn chữ |
| 3–4 KPI trên một mặt | Mỗi KPI một thẻ gradient |
| Viền nhẹ | Bóng khắp nơi |
| Vạch đặc cho mức khẩn | Sắc độ viền khác nhau |
| Mascot ở sáu chỗ có nghĩa | Mascot ở mọi thẻ |
| `TtStatus` cho mọi ánh xạ mức→màu | `switch` màu riêng trong màn |
| Số đo từ luật thật | Số chép từ `concepts.png` |
