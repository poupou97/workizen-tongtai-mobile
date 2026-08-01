# ADR-TON-022 — Chấm điểm cơ hội khi thiếu dữ liệu

- **Trạng thái:** ✅ ACCEPTED (Claude, Full Autonomous Mode — Founder Directive 2026-08-01)
- **Ngày:** 2026-08-01
- **Story:** WTM-193 (O-6), phát hiện từ audit WTM-189
- **Liên quan:** ADR-TON-016 (Rule Twin authoritative, cấm bịa số) · ADR-TON-017
  (`insufficient` là một câu trả lời thật) · ADR-TON-015 (One Data Path) ·
  D-5 (Phase 2 không backend)

---

## Problem

`Opportunity.aiScore` là **hằng số theo loại luật**: `85`/`70` cho nhập lại
hàng, `65` cho khách im lặng, `75` cho mục tiêu chậm, `60` cho đà nhóm hàng.
Nó không mang thông tin nào ngoài *luật nào đã bắn*, nên **"sắp xếp theo mức độ
liên quan" thực chất là "sắp xếp theo luật"**.

`estimatedRoi` cũng là hằng số (`2.5`, `3.0`, `2.0`, `2.2`), kéo theo hai thứ
nữa cùng vô nghĩa:

- **facet sắp xếp theo ROI** — cho ra **cùng một thứ tự** với relevance, dưới
  một cái tên khác;
- **nhãn "High Risk"** — so `estimatedRoi` với ngưỡng `2.0`, tức chỉ nói lại
  luật nào đã bắn, trong khi người bán đọc nó như một **phán đoán về tiền của
  họ**.

Concept (`SCREEN-OPPORTUNITY-HUB.md`, Business Rules #1) đòi bốn yếu tố có
trọng số: **profit potential 40% · demand volume 30% · supplier quality 20% ·
competition 10%**.

**Hai trong bốn yếu tố không tính được trên thiết bị này:**

| Yếu tố | Vì sao không tính được |
|---|---|
| supplier quality (20%) | danh bạ nhà cung cấp là `SupplierSearchService.sample()` — **rating bịa ra**. Chấm điểm bằng nó chính là bịa số mà ADR-TON-016 cấm, chỉ khác là mặc áo số học |
| competition (10%) | cần dữ liệu thị trường bên ngoài; Phase 2 local-first, không backend (D-5) |

Và một yếu tố **tính được nhưng khác định nghĩa**: Concept muốn *demand volume*
là cầu **thị trường** (Google Trends, API sàn). Không có backend thì chỉ tính
được **cầu của riêng cửa hàng này** từ lịch sử đơn.

## Options

**A. Chuẩn hoá lại trên phần có dữ liệu, không nói gì thêm.**
Điểm vẫn là một con số 0–100. Rẻ. Nhưng người đọc — kể cả AI đọc prompt — không
có cách nào biết nó chỉ dựa trên 70% cân nặng, nên sẽ giải thích nó như một
phán đoán đầy đủ. Đây là bịa số ở tầng trình bày.

**B. Trả `insufficient` cho cả điểm khi chưa đủ bốn yếu tố.**
Trung thực tuyệt đối. Nhưng 70% cân nặng là **dữ liệu thật của người bán**, và
từ chối chấm nghĩa là feed **không còn thứ tự nào** — phục vụ người bán tệ hơn
một câu trả lời một phần nhưng thành thật. Cũng có nghĩa là năng lực sẽ nằm im
cho tới khi có backend, tức là mãi mãi ở Phase 2.

**C. `insufficient` ở cấp **yếu tố**, không ở cấp điểm tổng. ⭐ ĐƯỢC CHỌN**
Điểm tính trên các yếu tố có dữ liệu, **chuẩn hoá lại** để yếu tố thiếu không
bị tính như điểm 0, và đối tượng điểm **tự khai báo độ phủ** (`coverage`) cùng
lý do từng yếu tố vắng mặt.

## Trade-offs

C đắt hơn A: cần một value object có cấu trúc thay vì một `double`, mọi nơi
hiển thị điểm phải xử lý `null`, và prompt AI phải mang theo độ phủ. Đổi lại:

- **`null` không phải `0`.** Số 0 nói *"cái này vô giá trị"*; `null` nói
  *"không ai biết"*. Coi cái thứ hai như cái thứ nhất là cách một sản phẩm bắt
  đầu nói dối mà mặt không đổi sắc.
- **Ranh giới ADR-TON-016 đi vào prompt.** Một mô hình được bảo "82/100" sẽ giải
  thích nó như phán đoán hoàn chỉnh. Được bảo "82/100, dựa trên 70% yếu tố", nó
  chỉ giải thích được phần đã thực sự đo.
- Concept **giữ nguyên hình dạng** — đúng quy tắc Future Capability của Founder
  cho Producer, áp cho một công thức thay vì một màn hình.

## Selected Option

**C**, kèm bốn ràng buộc:

1. **Yếu tố là hàm thuần.** `profitPotentialFactor` và `demandVolumeFactor`
   nhận **số**, không nhận repository, nên test ghim được số học mà không cần
   database và Rule Twin chạy được không cần AI/mạng/key (ADR-TON-016).
2. **Profit potential là tỉ lệ, không phải đồng tuyệt đối.** ₫5tr với cửa hàng
   doanh thu ₫10tr khác hẳn ₫5tr với cửa hàng ₫500tr; một thang tuyệt đối sẽ
   xếp hạng mọi cơ hội của cửa hàng lớn y như nhau.
3. **Demand volume phải được gọi đúng tên.** Nó là **cầu của chính người bán**,
   không phải cầu thị trường. UI và prompt nói *"khách của bạn"*, không được nói
   *"thị trường"*.
4. **Mọi mã là canonical code**, không phải nhãn hiển thị (ADR-TON-018), nên an
   toàn cho telemetry.

## Hệ quả: ba thứ bị gỡ, không phải bị sửa

Cả ba đều dẫn xuất từ hằng số, nên "sửa" chúng là không thể — chỉ có thể **gỡ
hoặc bịa**:

- **Facet sắp xếp theo ROI** → **ẩn** (`OpportunitySort.roi` vẫn còn trong enum;
  `OpportunitySort.visible` không chứa nó). Đúng quy tắc **O-1 của Founder**:
  *giữ Domain, ẩn Capability chưa có dữ liệu*. ROI thật cần **giá vốn**, mà
  `Product` chỉ có giá bán.
- **Nhãn "High Risk"** → **không phát ra nữa**. Hằng số `kOpportunityHighRiskRoi`
  được giữ lại cho ngày `Product` có giá vốn.
- **Bước cuối của action plan** không còn trích một tỉ lệ ROI cụ thể; nó dùng
  **tác động kỳ vọng**, một con số thật từ đơn hàng của chính người bán.

## Migration Strategy

Không có migration dữ liệu: **điểm là dữ liệu dẫn xuất**, tính lại mỗi lần đọc,
và **không** nằm trong `.ttbk` — cùng lý do như chính cơ hội (WTM-190). Schema
không đổi.

Với code: `Opportunity.aiScore`/`estimatedRoi` bị thay bằng `Opportunity.score`.
`aiScore` còn lại như một getter `double?` tiện dụng. Fixture trong test dùng
`OpportunityScore.fixed`, được đánh dấu **`@visibleForTesting`** — một con số
viết tay trong `lib/` chính là khuyết tật mà ADR này gỡ bỏ, và analyzer nay sẽ
nói ra điều đó.

## Nếu dogfood chứng minh sai

- Không ai đọc bảng chia điểm ⇒ độ phủ chỉ cần một dòng chú thích, không cần
  giao diện riêng.
- `coverage` **luôn** bằng 0.7 suốt nhiều tháng ⇒ cân nhắc bỏ hẳn hai yếu tố
  khỏi mô hình Phase 2 thay vì mang chúng như chỗ trống vĩnh viễn.
- Người bán muốn tự đặt trọng số ⇒ trọng số chuyển từ hằng số sang cấu hình,
  và đó là một ADR khác.
