# Concept-1 — Phân tích 12 màn & đề xuất thứ tự dựng

> Đọc trọn 14 ảnh trong thư mục này (12 màn duy nhất: `cp9 ≡ cp10`, `cp1a ≡ cp2`).
> Trạng thái đối chiếu: `main` sau PR #212 · 2526 test xanh · 2026-08-11.
> **Tài liệu này KHÔNG code.** Nó chỉ trả lời: *cái gì đã có, cái gì thiếu, thiếu
> loại nào, và nên dựng theo thứ tự nào.*

---

## ⭐ Kết luận đọc trước

**Không màn nào trong concept-1 là màn mới.** Cả 12 màn đều đã có file tương ứng
trong `lib/features/tongtai/ui/screens/`. Vậy khoảng cách không phải "thiếu màn"
— nó là **ba loại khoảng cách khác nhau**, và trộn lẫn chúng là cách một backlog
concept biến thành một đống việc không ước lượng được:

| Loại | Nghĩa | Giá | Rủi ro |
|---|---|---|---|
| **A · Trình bày** | Dữ liệu có, luật có, chỉ chưa bày ra theo cách concept vẽ | Rẻ | Thấp |
| **B · Luật** | Màn hiện một con số **chưa ai tính**. Tính được từ dữ liệu đã có | Vừa | Thấp — nếu viết luật trước, vẽ sau |
| **C · Miền** | Concept vẽ một con số **không có nguồn nào trên máy sinh ra được** | Đắt | ⛔ **Cao — đây là chỗ bịa số** |

Và **một quan sát chiến lược**: ma trận trải nghiệm hiện tại là *Dòng thời gian
19✅ / Hành động 5✅* — Tổng Tài đã **thấy** gần hết doanh nghiệp và **làm** được
rất ít. Concept-1 gần như toàn bộ là **thấy thêm nữa** (điểm số, biểu đồ, thẻ
KPI). Dựng hết concept-1 sẽ **nới rộng** khoảng cách đó, không thu hẹp nó. Đề
xuất dưới đây vì thế ưu tiên những màn concept mà mỗi con số **dẫn tới một nút
bấm**, và hoãn những màn chỉ thêm mặt đồng hồ.

---

## Ba mâu thuẫn phải chốt trước khi dựng

### 1. ⛔ Concept chưa tự giải được thanh điều hướng của chính nó

Ba cấu hình khác nhau xuất hiện trong cùng một bộ ảnh:

| Nguồn | Thanh dưới |
|---|---|
| `cp_home`, `cp3`, `cp4`, `cp5` | Trang chủ · Nguồn hàng · Kho hàng · Khách hàng · **Cơ hội** · Thêm |
| `cp7` | … · **Tài chính** · Thêm |
| `cp8` | … · **Báo cáo** · Thêm |
| `cp10` | Trang chủ · … · **Báo cáo · Kế hoạch** |
| `cp12` | Trang chủ · Khách hàng · Cơ hội · Báo cáo · Thêm (**5 ô**) |
| **App thật hôm nay** | Trang chủ · Nguồn hàng · Kho · Khách hàng · Cơ hội (**5 ô, không có Thêm**) |

Sáu ô, nhưng **ít nhất bảy đích** muốn vào ô thứ năm. Concept không chọn — nó
chỉ tô sáng đích nào đang mở. Đây là quyết định phải chốt **trước** mọi màn khác,
vì nó đổi trí nhớ ngón tay của người dùng và đổi cả `tongtai_app_shell.dart`.

**Đề xuất:** 6 ô — **Trang chủ · Nguồn hàng · Kho · Khách hàng · Tiền · Thêm**.

* **Cơ hội rời thanh nav, về Trang chủ.** `cp_home` đã tự vẽ điều đó: khối "Việc
  Tổng Tài đề xuất" chính là Cơ hội. Hai đích cùng trả lời *"tôi nên làm gì
  tiếp"* là đúng cái trùng lặp mà câu hỏi concept #1 đang treo.
* **Tài chính + Báo cáo gộp thành "Tiền".** Cả hai đều là *con số về quá khứ và
  hiện tại*; tách chúng buộc người bán phải học trước mình đang muốn xem "tài
  chính" hay "báo cáo" — một phân biệt của phần mềm kế toán, không phải của
  người bán hàng.
* **`Thêm` vào nav** (đã có `tongtai_more_screen.dart`, hiện chưa có ô).

### 2. ⛔ Trọng số điểm cơ hội trong concept ≠ trọng số trong code

| | Nhu cầu | Biên LN | Cạnh tranh | Rủi ro NCC | Logistics |
|---|---|---|---|---|---|
| `cp5a/cp5b` | 30% | 25% | 20% | 15% | 10% |
| Code (`opportunity_score.dart`, theo `SCREEN-OPPORTUNITY-HUB.md`) | 30% | **40%** | 10% | 20% | **—** |

Code hiện chỉ có **4 yếu tố** và tự khai *chỉ 70% trọng số là thật* (cạnh tranh
và chất lượng NCC chưa có nguồn). Concept thêm yếu tố thứ năm (Logistics) và đổi
trọng số. **Không được lặng lẽ sửa bên nào** — đây là mâu thuẫn giữa tài liệu
màn hình đã duyệt và concept mới. Cần một quyết định ghi vào ADR.

### 3. Linh vật con cáo có mặt trên 12/12 màn concept — app không có

`icon app.png` / `icon_1.png` / `icon 2.png` đã có ⇒ **icon ứng dụng giải quyết
xong**. Còn thiếu là **bộ tư thế**: giơ ngón cái (`cp7`), ngồi máy tính (`cp4`
onboarding), ăn mừng (`cp5` onboarding), chỉ tay (`cp8`). Mỗi màn concept dùng
một tư thế khác nhau — đây là thứ **Founder phải cung cấp**, không dựng bằng code.

---

## Ma trận 12 màn

Cột **Gap** dùng ký hiệu A/B/C ở trên. Cột **Đề xuất** là quyết định, không phải
lựa chọn.

| # | Màn concept | Đã có trong app | Concept thêm gì | Gap | Đề xuất |
|---|---|---|---|---|---|
| `cp11` | **Chi tiết NCC** | `supplier_detail_screen` + `supplier_comparison.dart` (đã tính chênh giá / MOQ / thời gian giao) | Điểm 87/100 trên 5 trục + **"Vì sao Tổng Tài đánh giá như vậy"** 5 gạch đầu dòng | Bảng so sánh = **A** · điểm 5 trục = **B** | ⭐ **DỰNG ĐẦU TIÊN** |
| `cp5b` | **Cơ hội chi tiết** | `opportunity_detail_screen` + `opportunity_score.dart` (4 yếu tố, có trọng số, tự khai độ phủ 70%) | **Bung trọng số ra màn hình** | **A** | ⭐ **DỰNG** — chốt §2 trước |
| `cp3` | **Kho hàng** | `inventory_screen`, `stock_alerts_screen` | Vòng "Sức khỏe tồn kho" 4 nhóm · **giá trị tồn kho** · **vốn nằm trong hàng chậm bán** · thẻ "cần bạn xử lý" có nút | **B** (cần giá vốn — đã có trên `Product`) | ⭐ **DỰNG** — tỉ lệ giá trị/giá cao nhất nhóm |
| `cp7` | **Tài chính** | `finance_screen`, `true_profit.dart`, `settlement*` | **Cash runway** · **điểm hòa vốn** · **dự báo dòng tiền 90 ngày** · điểm sức khỏe 82/100 · 3 thẻ "Tổng Tài phát hiện" | **B** — `grep` cho `runway|breakEven` ra **0** kết quả trong `finance/` | ⭐ **DỰNG** — năng lực **mới lớn nhất** của cả bộ concept |
| `cp4` | **Khách hàng** | `consumer_screen`, `customer_list`, `customer_risk`, `customer_history` | **6 phân khúc** · tab Kênh bán · tab **Đánh giá** · kênh bán hiệu quả | Phân khúc = **B** · Đánh giá = **C** | **DỰNG** phân khúc · **HOÃN** Đánh giá |
| `cp_home` | **Trang chủ** | `home_screen` + `business_brief_service` | 4 thẻ module có **sparkline + delta** · "Sức khỏe doanh nghiệp" 4 KPI · chip ưu tiên trên đề xuất | **A** + sparkline = **B** nhẹ | **GIỮ + nâng** |
| `cp8` | **Báo cáo** | `reports_screen`, `business_report.dart` | Hero "Tổng Tài tóm tắt (AI)" · 4 KPI + sparkline · xu hướng 6 tháng · 6 nhóm báo cáo | **A** | **GỘP vào "Tiền"** (§1) |
| `cp12` | **Thêm** | `more_screen` (đã có, **chưa có ô nav**) | Gom 5 nhóm: Doanh nghiệp · Dữ liệu & Kết nối · Tổng Tài AI · Ứng dụng · Hỗ trợ | **A** | **DỰNG** — rẻ, và §1 cần nó |
| `cp2` | **Nguồn hàng** | `producer_screen`, `supplier_search`, `supplier_favorites` | Tab con Sản phẩm/NCC/**Xu hướng**/So sánh · thẻ *giá nguồn → giá bán → logistics → lợi nhuận dự kiến* · FAB "+" giữa nav | So sánh = **A/B** · **Xu hướng = C** · "giá bán" của hàng chưa từng bán = **C** | **DỰNG So sánh** · ⛔ **TỪ CHỐI Xu hướng** |
| `cp6` | **Phân tích sản phẩm** | *(chưa có màn riêng — gần nhất là `product_form` + `opportunity_detail`)* | 6 tab: Tổng quan/**Thị trường**/Nguồn hàng/Kênh bán/Tài chính/AI Insight · **4 thị trường tiềm năng** · máy tính lợi nhuận | Tổng quan + Tài chính = **B** · **Thị trường = C** | **CHẺ ĐÔI** — dựng 2 tab, bỏ 4 |
| `cp10` | **Kế hoạch kinh doanh** | `journey_screen`, `goals_screen`, `journey_planner` | 12 bước có **%** · **dự kiến đầu tư** · **dự kiến kết quả (+45% doanh thu)** | **C** — cả ba trường không tồn tại trong miền | ⛔ **HOÃN** — rủi ro bịa cao nhất bộ |
| `cp5a` | Cơ hội (biến thể) | — | Bố cục gọn hơn `cp5b` | — | **BỎ** — chọn `cp5b` |

---

## ⛔ Luật chống bịa áp cho cả bộ concept

Mỗi con số trên ảnh concept là **số mockup**. Trước khi bất kỳ con số nào lên
màn thật, nó phải qua ba cửa (ADR-TON-016 · ADR-TON-023):

1. **Có chủ.** Một luật Rule Twin cụ thể sinh ra nó, chạy được không cần mạng /
   khoá / AI. Không có chủ ⇒ không lên màn.
2. **Có trạng thái từ chối.** Thiếu dữ liệu ⇒ *"chưa đủ dữ liệu"*, **khác hẳn**
   *"đã xét và không có gì"* (`SeasonalVerdict.insufficient` vs `.ready` là
   khuôn mẫu). Gộp hai câu đó là cách màn im lặng biến thành lời trấn an sai.
3. **Có lý do đọc được.** `cp11` và `cp5b` làm đúng điều này ("Vì sao Tổng Tài
   đánh giá như vậy") — đó là phần **giá trị nhất** của cả concept-1, và nó rẻ.

**Bốn thứ trong concept không qua nổi cửa 1 và phải để trống, không phải để đẹp:**

| Con số | Vì sao không có nguồn |
|---|---|
| `cp2` **Xu hướng** thị trường | Không sàn nào được kết nối thật. Bịa xu hướng = bịa nhu cầu. |
| `cp6` **4 thị trường tiềm năng** | Không có bất kỳ nguồn dữ liệu thị trường nào trên máy. |
| `cp10` **dự kiến đầu tư / kết quả +45%** | Không trường nào trong miền chứa nó. Đây là *lời hứa lợi nhuận* — nguy hiểm nhất. |
| `cp4` tab **Đánh giá** | Chỉ có đánh giá trong kịch bản demo, chưa có miền review. |

---

## Đề xuất thứ tự dựng — ba đợt

### Đợt 0 · Chốt (không code)
Ba mâu thuẫn §1 §2 §3. **Chặn đợt 1** vì §1 đổi shell và §2 đổi `cp5b`.

### Đợt 1 · "Cùng dữ liệu, nói được nhiều hơn" — không luật mới, không schema mới

| Thứ tự | Việc | Vì sao trước |
|---|---|---|
| 1 | `cp11` bảng so sánh NCC + **"vì sao"** | `supplier_comparison.dart` đã tính xong. Rẻ nhất, và là **bản trình diễn mẫu** của "luật quyết định, chữ chỉ giải thích" |
| 2 | `cp5b` bung trọng số điểm cơ hội | Dữ liệu đã có kèm cả *độ phủ 70%* — bày ra là tự nó thành lời thú nhận trung thực |
| 3 | `cp12` + ô `Thêm` vào nav | §1 cần nó; màn đã có sẵn |
| 4 | `cp_home` / `cp8` sparkline + delta | Chuỗi 12 tháng đã có từ `historical_data_generator` |

### Đợt 2 · "Luật mới, dữ liệu đã có" — Rule Twin mới, **không** đổi schema

| Thứ tự | Việc | Ghi chú |
|---|---|---|
| 5 | **`cp7` cash runway + điểm hòa vốn + dự báo 90 ngày** | Năng lực mới lớn nhất. Suy hoàn toàn từ giao dịch của chính người bán ⇒ trung thực. Cần trạng thái *insufficient* khi chưa đủ 3 tháng |
| 6 | `cp3` vòng sức khỏe tồn + **vốn nằm trong hàng chậm bán** | Đúng chỗ người bán Việt Nam chôn tiền mà không nhìn thấy |
| 7 | `cp4` 6 phân khúc khách | RFM từ đơn thật; khách chưa mua ⇒ không xếp phân khúc |
| 8 | `cp11` điểm NCC 5 trục | Sau #1, vì cần đủ 5 trục mới chấm được |
| 9 | `cp6` chỉ 2 tab: Tổng quan + Tài chính | Máy tính lợi nhuận từ giá vốn/giá bán thật |

### Đợt 3 · Chờ nguồn thật
`cp2` Xu hướng · `cp6` Thị trường · `cp10` đầu tư/kết quả · `cp4` Đánh giá.
**Không dựng dưới dạng "tạm điền số"** — mỗi cái cần một connector thật hoặc một
trường miền mới, và cả hai đều là quyết định riêng.

---

## Ba điều concept-1 làm đúng mà app đang thiếu

1. **Mỗi điểm số đi kèm cách chấm.** `cp11` và `cp5b` bày cả trọng số lẫn lý do.
   App hôm nay tính đúng nhưng **giấu cách tính** — mà cách tính chính là thứ
   khiến người bán tin.
2. **Mỗi thẻ phát hiện có một nút.** `cp3`, `cp7`, `cp8` không thẻ nào chỉ để
   đọc — luôn có *Tạo đơn nhập* / *Xem danh sách* / *Xem đề xuất*. Đây là câu trả
   lời của concept cho khoảng cách *thấy 19 / làm 5*.
3. **Cảnh báo nói hậu quả, không nói triệu chứng.** *"Nếu nhập hàng theo kế hoạch
   hiện tại, cash runway có thể giảm từ 94 xuống 61 ngày"* — đó là một câu nói
   được vì nó gắn một **hành động sắp xảy ra** với một **con số sẽ đổi**. App
   hôm nay báo trạng thái, chưa báo hậu quả.

Điều 3 là thứ đáng học nhất, và nó là lý do `cp7` nằm ở đợt 2 chứ không đợt 3.

---

# Phụ lục · `luồng onboarding.png` — Onboarding V2 (7 bước)

> Ảnh bổ sung, nhận 2026-08-11. Đây **không phải màn thứ 13** — nó là một luồng,
> và nó là phần **quan trọng nhất** của cả bộ concept-1.

## Vì sao nó quan trọng hơn 12 màn kia

Onboarding hôm nay ([`onboarding_conversation.dart`](../../../lib/features/tongtai/onboarding/onboarding_conversation.dart))
hỏi **4 câu hồ sơ** — `trade` · `channels` · `size` · `seasonality` — rồi thả
người bán vào một ứng dụng **trống rỗng**. Người bán trả lời xong bốn câu và
không nhận lại gì.

Concept V2 đảo ngược: `CONNECT/TELL → AI LEARNS → FIRST INSIGHT → CHOOSE GOAL →
FIRST PLAN → HOME`. Onboarding kết thúc bằng việc người bán **đã nhìn thấy một
điều đúng về chính doanh nghiệp mình**, không phải bằng một hồ sơ đã điền.

Đó là chẩn đoán đúng, và **rẻ hơn nó trông** — vì mọi luật cần cho bước 5 đều
đã chạy trong `main` rồi.

## Bảy bước · gap từng bước

| Bước | Concept vẽ gì | Đã có gì | Gap | Đề xuất |
|---|---|---|---|---|
| **1 · Gặp Tổng Tài** | Chào + 3 lời hứa + `Bắt đầu` + **`Đã có tài khoản? Đăng nhập`** | Màn chào đã có | **A** | GIỮ · ⛔ **BỎ "Đăng nhập"** (xem §G-1) |
| **2 · Bạn đang kinh doanh gì?** | 5 **loại hình** (online / cửa hàng / thương mại-nhập / dịch vụ / đang chuẩn bị / khác) + 4 **quy mô** | `size` đã có; `trade` hỏi **ngành hàng**, không phải loại hình | **A/B** | GỘP — **giữ cả `trade` lẫn `seasonality`** (xem §G-3) |
| **3 · Đưa dữ liệu cho Tổng Tài** | 6 cửa: 4 sàn · Excel/CSV · Google Drive · dữ liệu mẫu · chưa có · để sau | `import_screen` ✅ · `sample_business_seeder` ✅ (WTM-343) | 3 cửa = **A** · **sàn + Drive = C** | ⭐ **XƯƠNG SỐNG** — ship 3 cửa, **giấu** cửa chưa có |
| **4 · Tổng Tài đang phân tích** | 5 dòng tiến trình có số thật (328 sản phẩm, 1.246 đơn…) | — | **B** | DỰNG · ⛔ số phải THẬT (xem §G-2) |
| **5 · Insight đầu tiên** | 4 phát hiện + 4 KPI tổng quan | **Cả 4 luật đã chạy** — xem bảng dưới | **A** | ⭐ **GIÁ TRỊ CAO NHẤT, RẺ NHẤT** |
| **6 · Chọn mục tiêu** | 8 mục tiêu, chọn 1–2 | `business_goal` · `goals_screen` · `journey_planner` ✅ | **A** | DỰNG bằng **tái dùng**, không module mới |
| **7 · Kế hoạch đầu tiên** | 2 việc + **"Tác động dự kiến +8,4 triệu"** | `business_brief_service` ✅ | Kế hoạch = **A** · **tác động dự kiến = C** | DỰNG · ⛔ **BỎ con số tác động** |

### Bước 5 — bốn phát hiện, bốn luật đã có

| Phát hiện trên ảnh | Luật đã chạy trong `main` |
|---|---|
| *3 SKU có thể hết hàng trong 5 ngày tới* | luật sắp hết hàng — `business_brief_service` ✅ |
| *2 sản phẩm có cơ hội biên lợi nhuận > 40%* | `true_profit.dart` + `opportunity_score` ✅ |
| *8 khách hàng có khả năng mua lại cao* | **`repeat-due`** — vừa merge tuần này (WTM-180) ✅ |
| *TikTok Shop đang tăng 27%* | doanh thu theo kênh — có `vendor` trên đơn, **chưa có luật xu hướng** ◐ |

Ba trên bốn đã xong. Bước 5 vì thế là **cách rẻ nhất để những luật vừa dựng trở
nên nhìn thấy được** — hôm nay chúng nằm trong Brief mà người bán mới chưa từng
mở tới.

## ⛔ Bốn điều phải chặn / chốt

### G-1 · "Đã có tài khoản? Đăng nhập" — **Founder Gate**

Concept lặng lẽ đưa **tài khoản** vào màn đầu tiên của sản phẩm. Điều đó mâu
thuẫn trực tiếp với **D-4 (không cần tài khoản)** và Local First. Không dựng, và
không tự quyết. Nếu concept thật sự muốn có tài khoản thì đó là một ADR mới,
không phải một dòng chữ dưới cái nút.

### G-2 · Bước 4 là chỗ dễ thành sân khấu nhất trong cả sản phẩm

Một thanh tiến trình chạy theo `Duration` cố định, kể cả khi không có dữ liệu, là
**diễn**. Ba ràng buộc:

1. Mỗi dòng gắn với **một lượt quét thật** trên bản ghi thật, hiện **số đếm thật**.
2. Người bán chọn *"chưa có dữ liệu"* ⇒ **bỏ hẳn bước 4 và bước 5**. Concept
   không vẽ nhánh này — nhưng đó là nhánh **phổ biến nhất** của người dùng mới.
3. Không dòng nào được ghi *"đang phân tích"* trong khi thật ra đang `sleep`.

### G-3 · Đừng đánh mất `seasonality`

Concept V2 bỏ câu hỏi mùa vụ. Nhưng `SeasonalRule` (WTM-180) ăn chính câu đó, và
mùa vụ là tín hiệu mạnh nhất của người bán Việt Nam (Tết). Giữ lại — gộp vào
bước 2 chứ đừng bỏ.

Ngược lại, **câu hỏi "loại hình kinh doanh" của concept là câu app đang thiếu**:
online / cửa hàng / thương mại / dịch vụ chính là trục
Physical·Digital·Service·Hybrid của **ADR-TON-023**, mà onboarding chưa hề hỏi.
⇒ **Giữ 4 câu cũ + thêm 1 câu mới**, không phải thay thế.

### G-4 · "Tác động dự kiến +8,4 triệu" — cùng lỗi với `cp10`

*"Giá trị tồn kho nguy cơ: 12,4 triệu"* là một **dữ kiện** (hàng đang có, giá vốn
đã biết). *"Tác động dự kiến +8,4 triệu"* là một **lời hứa lợi nhuận** cho một
việc chưa ai làm. Không luật nào sinh ra nó một cách trung thực. Bỏ.

### Ghi thêm · thanh nav thứ **tư**

Màn Home thu nhỏ ở góc dưới phải vẽ *Trang chủ · Cơ hội · Kho · Khách hàng ·
Thêm*. Cộng với ba cấu hình ở §1 là **bốn**. Càng củng cố: nav phải chốt trước.

## Đề xuất — Onboarding V2 **chen lên trước Đợt 1**

Lý do: nó là màn **duy nhất** quyết định người bán mới có bao giờ tới được 12 màn
kia hay không, và bước 5 tái dùng đúng những luật vừa dựng tuần này.

| | Việc | Loại |
|---|---|---|
| 1 | Bước 3 *Đưa dữ liệu* — 3 cửa thật (Excel/CSV · dữ liệu mẫu · chưa có) | A |
| 2 | Bước 4 *Đang phân tích* — số đếm thật, có nhánh bỏ qua | B |
| 3 | Bước 5 *Insight đầu tiên* — 3 luật đã có + trạng thái *chưa đủ dữ liệu* | A |
| 4 | Bước 2 — thêm câu loại hình, giữ `seasonality` | A |
| 5 | Bước 6–7 — tái dùng `goals` + `brief`, **không** con số tác động | A |
| 6 | Bước 1 — bỏ "Đăng nhập" | A |

Toàn bộ là **A trừ một B**. Không schema mới, không connector, không AI.

**Giữ nguyên hai ranh giới của onboarding hiện tại:** không ô nhập chữ nào (mọi
đáp án là chip từ từ vựng đóng, nên không gì người bán gõ lọt vào prompt AI), và
luồng chạy **không cần khoá AI** — vì phần lớn người dùng mục tiêu không có khoá,
và một màn đầu tiên báo lỗi thiếu khoá là cách tệ nhất để mở đầu sản phẩm.

---

# ⚠️ KIỂM LẠI 2026-08-16 (WTM-438) — ba kết luận ở trên KHÔNG còn đúng

Tài liệu trên viết ngày **2026-08-11**, đối chiếu `main` lúc **2526 test**. Nay
là `main` **2895 test**, sau **18 story** và **bốn quyết định Founder** mà bản
gốc chưa biết. Đọc phần trên mà bỏ qua phần này sẽ dẫn tới việc **dựng lại đúng
thứ vừa bị gỡ**.

## ⛔ 1. `cp11` "DỰNG ĐẦU TIÊN" nay bị CẤM

Bảng ma trận xếp `cp11` — *Chi tiết NCC, điểm 87/100 trên 5 trục* — là **⭐ DỰNG
ĐẦU TIÊN**, gap **B**.

**WTM-421** (Founder duyệt 2026-08-15) đã **gỡ khỏi sản phẩm** đúng lớp nội dung
ấy: chứng chỉ ISO gán cho mọi NCC · số sản phẩm sinh bằng công thức · số đơn
suy từ số sao. Kèm cổng `business_truth_gate_test` chặn nó quay lại.

Founder chốt thêm: ***`cp11` bị CHẶN cho tới khi từng trục có nguồn dữ liệu
thật*** — không dựng điểm tổng hợp từ dữ liệu bịa hay suy diễn.

⇒ Gap thật của `cp11` **không phải B mà là C**. Bản gốc đánh giá bằng câu hỏi
*"có dựng được không"*; câu đúng là *"có nguồn thật không"*.

## ✅ 2. §3 "app không có linh vật" — nay CÓ

Bản gốc: *"Linh vật có mặt 12/12 màn concept — app không có… Founder phải cung
cấp bộ tư thế."*

Đã xong: **WTM-417** cắt 24 tư thế vào `assets/mascot/brand/`. Nay linh vật có ở
**header Trang chủ** (WTM-437) và **màn chào** (WTM-433, tư thế vẫy tay).

⚠️ Kèm một luật bản gốc chưa biết: **mỗi màn chỉ MỘT con cáo.** Bản dựng đầu có
cáo ở header + dòng chào + avatar ⇒ ba khuôn mặt giống hệt nhau; Founder nói
*"không ra sao cả"*. `cp_home` chỉ vẽ một con, dòng chào là chữ trơn.

## ⚠️ 3. Đề xuất thanh nav KHÔNG được chọn

Bản gốc đề xuất 6 ô: *Trang chủ · Nguồn hàng · Kho · Khách hàng · **Tiền** · Thêm*,
tức **Cơ hội rời nav**.

Thực tế `main` hôm nay: *Trang chủ · Nguồn hàng · Kho · Khách hàng · **Cơ hội** ·
Thêm*. Đề xuất "Tiền" **chưa bao giờ được chốt**, và Founder đã ra hai quyết
định khác về nav mà bản gốc không có: **WTM-426** (màu định danh tách khỏi màu
trạng thái, Option B) và **WTM-439** (sắc lấy theo concept).

⇒ Ai đọc bản gốc rồi đi gộp Báo cáo vào "Tiền" là làm theo một đề xuất **chưa
được duyệt**.

## Trạng thái các màn còn lại — kiểm nhanh 2026-08-16

| Màn | Bản gốc | Nay |
|---|---|---|
| `cp_home` | "GIỮ + nâng", thiếu sparkline | ✅ **có sparkline + delta + chip ưu tiên + nút Xử lý ngay** (WTM-437 xác nhận trên máy) |
| `cp7` Tài chính | ⭐ DỰNG, `runway`/`breakEven` = 0 kết quả | ⛔ **WTM-410 chờ Founder** — nửa "runway" thiếu **số dư tiền**, không có nguồn |
| `cp2` Xu hướng | ⛔ TỪ CHỐI | ⛔ giữ nguyên — chưa sàn nào nối thật |
| `cp6` 4 thị trường | ⛔ TỪ CHỐI | ⛔ giữ nguyên |
| `cp10` dự kiến +45% | ⛔ HOÃN | ⛔ giữ nguyên — *lời hứa lợi nhuận*, rủi ro cao nhất bộ |
| `cp12` Thêm | DỰNG (chưa có ô nav) | ✅ **có tab Thêm** (WTM-405) |
| `cp4` Đánh giá | HOÃN | ⛔ giữ nguyên — chưa có miền review |

## Luật rút ra cho lần rà sau

**Rà concept phải MỞ MÀN THẬT MÀ NHÌN.** Ở WTM-437 tôi lập bảng khác biệt bằng
cách `grep` tên widget và kết luận *"không thấy ⇒ không có"* — bảng ấy **sai
4/5**: badge, ô hỏi AI, chip ưu tiên, thanh CTA đều đã tồn tại dưới tên khác.
Làm theo nó thì Trang chủ đã có hai badge, hai ô hỏi AI, hai thanh CTA.

Và **một tài liệu rà soát có hạn dùng.** Bản gốc đúng vào ngày nó được viết;
ba tuần sau, ưu tiên số 1 của nó đã thành thứ bị cấm. Trước khi làm theo bất kỳ
đề xuất nào ở trên, kiểm lại mục ấy còn hợp với quyết định Founder gần nhất
không.
