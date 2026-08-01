# AI-first Assessment

*(Báo cáo 7 trong 24 · Phase 3 của directive)*

---

## 1. AI hiện đóng vai trò gì — sự thật, không phải quảng cáo

| Nơi | AI làm gì | Ai quyết định con số |
|---|---|---|
| Reports → thẻ "Workizen AI" | tóm tắt · gợi ý · kế hoạch tuần · đánh giá sức khoẻ (G-3A→D, ADR-TON-013) | **Rule** |
| Dự báo doanh thu | **Rule Twin tính**, AI diễn giải | **Rule** |
| Rủi ro khách hàng | **Rule Twin tính** (RFM), AI diễn giải | **Rule** |
| Opportunity detail | AI giải thích cơ hội, có parse `ĐIỂM: NN` | **Rule** (điểm rule authoritative) |
| Chat Copilot | hỏi đáp trên BusinessContext | — |

**Nguyên tắc đang được thực thi bằng cấu trúc, không bằng nội quy:**
`PredictiveAiService` chỉ giữ `TongtaiAiService`, **không** giữ `Ref` hay
repository. "AI không đọc DB" vì nó **không có đường** để đọc, không phải vì có
người dặn nó đừng đọc. Có ratchet test quét `lib/` để giữ điều đó.

**Đánh giá thẳng:** đây là **AI-assisted**, chưa phải **AI-first**.

Khác biệt: trong sản phẩm AI-first, AI là **cách chính** người dùng vận hành sản
phẩm. Ở Tổng Tài hôm nay, người dùng vận hành bằng menu và form; AI là một thẻ
người ta **bấm vào khi muốn**. Bỏ AI đi, sản phẩm vẫn dùng được gần như nguyên
vẹn — đó là định nghĩa của AI-assisted.

Điều này **không phải lỗi**. Nó là hệ quả trực tiếp và đúng đắn của hai ràng
buộc Founder đặt ra: BYOK (nhiều người dùng sẽ không có khoá) và Rule Twin
authoritative (sản phẩm phải chạy được khi không có AI). **Một sản phẩm bắt buộc
phải chạy không cần AI thì không thể đặt AI vào đường đi chính.**

Đây là căng thẳng nền tảng cần Founder nhìn thẳng:

> **Không thể vừa "AI-first" vừa "chạy đầy đủ khi không có AI".** Phải chọn AI là
> *bắt buộc* (và trả lời câu hỏi ai trả tiền token) hay *tăng cường* (và bỏ nhãn
> AI-first khỏi định vị).

## 2. AI còn thiếu gì

| Thiếu | Vì sao quan trọng |
|---|---|
| **AI không có trí nhớ** | mỗi lần hỏi là một lần bắt đầu lại; không học được thói quen người bán |
| **AI không chủ động** | 100% do người dùng bấm. Không có "AI phát hiện điều bất thường và báo" |
| **AI không có dữ liệu thị trường** | chỉ thấy dữ liệu của chính người dùng ⇒ không thể tư vấn "giá thị trường", "đối thủ", "xu hướng" |
| **AI không hành động** | Tool Runtime **thiết kế sẵn nhưng chưa bật** (`DisabledAiToolRuntime`, cần Founder gate) |
| **Không đo được AI có ích không** | không có tín hiệu người dùng thấy gợi ý hữu ích hay vô dụng |

## 3. Bảy đề xuất của directive — đánh giá từng cái

| Đề xuất | Khả thi với kiến trúc hiện tại | Ghi chú |
|---|---|---|
| **AI-first Onboarding** | ✅ **được ngay** | Thay 6 trang giới thiệu bằng hội thoại: "Bạn bán gì? Bao nhiêu khách?" → tạo sẵn danh mục + mục tiêu đầu tiên. Không cần backend. **Giá trị cao nhất / chi phí thấp nhất trong bảy cái** |
| **AI Business Profile** | ✅ được | Một hồ sơ ngắn (ngành, quy mô, mùa vụ) làm ngữ cảnh cho mọi prompt. Là cách rẻ nhất để AI bớt chung chung |
| **AI Opportunity Engine** | ⚠️ **một phần** | Rule engine đã có. Nâng cấp thật cần **dữ liệu ngoài** ⇒ phụ thuộc quyết định A/B/C |
| **AI Weekly Review** | ✅ được | Rule Twin đã tính đủ số. Chỉ cần một điểm chạm định kỳ + thông báo cục bộ. **Không cần backend** |
| **AI Recommendation** | ✅ đã có (G-3B) | Cần **đo tính hữu ích**, không cần xây lại |
| **AI Marketplace Intelligence** | ❌ **cần dữ liệu ngoài** | Không thể làm mà không có nguồn thị trường. Xem báo cáo 15 |
| **AI Business Copilot** | ✅ đã có | Thiếu **trí nhớ** và **chủ động** |

## 4. Thứ tự tôi đề xuất

**Làm được ngay, không phụ thuộc quyết định kiến trúc nào:**

1. **AI Business Profile** — nền cho mọi thứ sau; nhỏ nhất
2. **AI-first Onboarding** — biến ấn tượng đầu tiên từ "một app quản lý nữa"
   thành "nó hiểu việc kinh doanh của mình"
3. **AI Weekly Review** — lý do để mở app hằng tuần; dùng lại toàn bộ Rule Twin
4. **Đo tính hữu ích của gợi ý** — không có nó thì không biết AI đang giúp hay
   đang ồn (chú ý: phải khai báo trong `TELEMETRY-EVENTS.md` + chính sách riêng
   tư, và **không được** gửi nội dung kinh doanh)

**Phụ thuộc quyết định A/B/C:**

5. AI Opportunity Engine nâng cấp
6. AI Marketplace Intelligence

**Cần Founder gate riêng, không tự mở:**

7. **Tool Runtime / AI hành động.** ADR-TON-016 nói rõ mọi thứ có thể mở đường
   cho Tool Calling đều dừng ở Founder gate. Tôi **không** đề xuất bật trong
   vòng này.

## 5. Một cảnh báo về định vị

Nếu Tổng Tài giữ nhãn **"AI-First Business OS"** trong khi AI là tuỳ chọn và cần
người dùng tự mang khoá, thì mô tả trên cửa hàng sẽ **hứa nhiều hơn sản phẩm
làm**. Người dùng Việt Nam phần lớn **không có khoá API** và sẽ không tạo.

Hai lối ra trung thực:

- **Đổi định vị** thành *"Business OS có AI khi bạn muốn"* — đúng với sản phẩm
  hôm nay; hoặc
- **Làm AI dùng được mà không cần khoá** — nghĩa là Managed AI ⇒ cần backend +
  ai đó trả tiền token ⇒ **cùng một quyết định hạ tầng với hướng B**.

Đây là quyết định định vị, không phải kỹ thuật. Tôi không tự chọn.
