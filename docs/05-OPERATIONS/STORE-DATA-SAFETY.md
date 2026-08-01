# Store Data Safety Declaration — Google Play & App Store

*WTM-175 Release Readiness · 2026-08-01*

> **Đây là bản khai bắt buộc khi nộp app.** Nó phải khớp **chính xác** với
> `TELEMETRY-EVENTS.md`, `PRIVACY-POLICY.md` và `AppStrings.privacyTelemetryBody`.
> Khai nhiều hơn app làm là tự chuốc nghi ngờ; khai **ít hơn** app làm là **khai
> sai** và Google/Apple gỡ app vì điều đó.
>
> ⚠️ **Thêm một sự kiện telemetry ⇒ sửa file này trong CÙNG PR.**

---

## Google Play — Data safety form

### Câu hỏi 1: App có thu thập hoặc chia sẻ loại dữ liệu người dùng bắt buộc nào không?

**Có** — nhưng chỉ hai mục, và cả hai đều thuộc nhóm *App activity / App
info and performance*.

### Bảng khai

| Loại dữ liệu | Thu thập? | Chia sẻ? | Bắt buộc? | Mục đích | Ghi chú |
|---|---|---|---|---|---|
| **Crash logs** | ✅ Có | ❌ Không | Tuỳ chọn¹ | Analytics · App functionality | Firebase Crashlytics (ADR-TON-005) |
| **Diagnostics** | ✅ Có | ❌ Không | Tuỳ chọn¹ | Analytics · App functionality | 4 sự kiện: `app_open` · `screen_view` · `flow_error` · `screen_error` |
| Tên · Email · SĐT · Địa chỉ | ❌ | ❌ | | | **Không có tài khoản** (D-4) |
| Thông tin tài chính | ❌ | ❌ | | | Số liệu kinh doanh **nằm trên máy**, không rời đi (D-5) |
| Danh bạ · Vị trí · Ảnh · Tệp | ❌ | ❌ | | | App chỉ đọc tệp người dùng **tự chọn** khi khôi phục `.ttbk` |
| Định danh quảng cáo | ❌ | ❌ | | | **Cấm vĩnh viễn** — red line của sản phẩm |
| Lịch sử tìm kiếm trong app | ❌ | ❌ | | | Lưu **cục bộ**, không gửi đi |
| Nội dung do người dùng tạo | ❌ | ❌ | | | Kể cả nội dung chat AI |

¹ *Tuỳ chọn* vì app **chạy đầy đủ khi không có file cấu hình Firebase** —
telemetry no-op, có test khoá điều này.

### Các cam kết khác trong form

| Câu hỏi Play Console | Trả lời |
|---|---|
| Dữ liệu có được mã hoá khi truyền không? | **Có** — Firebase dùng HTTPS |
| Người dùng có yêu cầu xoá dữ liệu được không? | **Có** — gỡ app xoá toàn bộ dữ liệu cục bộ; dữ liệu chẩn đoán ẩn danh, không gắn với danh tính nào |
| App có tuân thủ Chính sách Gia đình không? | Không nhắm tới trẻ em |
| Dữ liệu có được chia sẻ với bên thứ ba không? | **Không** |

---

## Điểm cần khai riêng: khoá API của người dùng (BYOK)

Đây là mục dễ khai sai nhất, nên viết rõ:

- Người dùng **tự nhập khoá API** của chính họ (Gemini/xAI/Claude/…).
- Khoá được lưu trong **secure storage của hệ điều hành**, **không** gửi về
  Workizen, **không** nằm trong telemetry.
- Khi người dùng hỏi AI, khoá rời khỏi máy **chỉ trong header `Authorization`
  của lời gọi trực tiếp tới nhà cung cấp** mà họ đã chọn.

**Khai trên Play:** đây **không phải** *"app thu thập"* — Workizen không nhận
khoá. Nhưng **phải nêu trong Privacy Policy** rằng câu hỏi của người dùng được
gửi tới nhà cung cấp AI mà họ chọn, kèm bối cảnh kinh doanh tóm tắt.
`PRIVACY-POLICY.md` §2 và `AppStrings.privacyAiBody` **đã** nói điều này.

---

## App Store — Privacy Nutrition Label

Apple phân loại khác Play. Ánh xạ tương ứng:

| Nhóm của Apple | Khai |
|---|---|
| **Diagnostics → Crash Data** | ✅ Có · *Not linked to you* · *Not used for tracking* |
| **Diagnostics → Performance Data** | ✅ Có · *Not linked to you* · *Not used for tracking* |
| **Usage Data → Product Interaction** | ✅ Có · *Not linked to you* · *Not used for tracking* |
| Mọi nhóm còn lại | ❌ Không thu thập |
| **Tracking** | ❌ **Không** — không có ATT prompt, không có định danh quảng cáo |

⚠️ **"Not linked to you"** chỉ đúng vì **không có tài khoản** (D-4) và
telemetry không mang định danh nào. Nếu Phase 3 thêm tài khoản, **ô này phải
đổi** — và đó là thay đổi bản chất, không phải cập nhật thường.

---

## Nếu chưa cấu hình Firebase khi nộp

Nếu bản nộp **không có** `google-services.json` / `GoogleService-Info.plist`,
telemetry là no-op và app **không thu thập gì cả**. Lúc đó khai:

> *"App không thu thập hoặc chia sẻ bất kỳ loại dữ liệu người dùng nào."*

**Nhưng:** ngay khi bản build có file cấu hình được phát hành, bản khai **phải**
đổi sang bảng ở trên **trước** khi phát hành. Khai thiếu là vi phạm chính sách,
không phải sơ suất giấy tờ.

---

## Danh sách kiểm trước khi nộp

- [ ] Bản khai này khớp `TELEMETRY-EVENTS.md` (4 sự kiện, không hơn)
- [ ] Bản khai này khớp `PRIVACY-POLICY.md` §3
- [ ] Bản khai này khớp `AppStrings.privacyTelemetryBody` (VI **và** EN)
- [ ] Bản nộp **có** hay **không có** file cấu hình Firebase — chọn đúng bảng
- [ ] **URL chính sách riêng tư công khai** — `https://www.workizen.net/privacy`
      (Founder chốt 2026-08-01). ⚠️ **Public + HTTPS đạt, nội dung CHƯA đủ cho
      Tổng Tài** — trang không nhắc telemetry/crash reporting mà app có dùng.
      Nội dung bổ sung soạn sẵn: `PRIVACY-POLICY-WEB-CONTENT.md`
- [x] **Địa chỉ liên hệ nhà phát triển** — `privacy@workizen.net` ✅
- [ ] Điều khoản dịch vụ — ⚠️ **Founder gate**: `moreTerms` vẫn *coming soon*
