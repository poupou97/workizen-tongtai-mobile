# Hub Reuse Validation Checklist — Phase 1C Technical Evaluation

**Period:** Jul 20–26, 2026  
**Owner:** Tech Lead / QA  
**Status:** Checklist for Phase 1C fit-gap validation

---

## 🎯 Purpose

Validate that Hub's architecture components (storage, AI integration, UI, navigation) actually reuse for Tổng Tài without major rework. Confirms ADR decisions are sound before Phase 2 architecture lock.

---

## 1. Storage Layer (SQLite + Drift)

Hub reuses SQLite + Drift; Tổng Tài's 15-entity model must fit Hub's extracted shared layer.

### Database Schema Compatibility
- [ ] Hub's SQLite schema defined + documented
- [ ] Tổng Tài's 15-entity model (see Product Design Bible) mapped to schema
- [ ] No schema conflicts (same table names, different purposes)?
- [ ] Tổng Tài model can be added without Hub data migration?
- [ ] Test: Create Drift migrations for both products independently

### Drift Codegen & Migrations
- [ ] Hub's Drift `database.dart` abstracted (no product-specific logic)?
- [ ] Tổng Tài migrations reference shared schema, not Hub schema
- [ ] Drift codegen produces correct DAO/queries for both products
- [ ] Test: Run `flutter pub run build_runner build` — no conflicts

### Shared Storage Layer Extraction
- [ ] Folder structure created: `mobile/shared/core/storage/`
- [ ] Repository pattern encapsulates both Hub + Tổng Tài DAO calls
- [ ] No Hub-specific business logic in shared storage layer
- [ ] Tổng Tài can inject own repositories if needed
- [ ] Test: Write 3 unit tests (one Hub, one Tổng Tài, one shared)

### Performance with Larger Dataset
- [ ] Hub's schema/queries tested with 100k rows (smoke test)?
- [ ] Tổng Tài's 1M+ row estimate: query performance acceptable?
  - [ ] Indexes defined for high-query columns?
  - [ ] FTS5 full-text search enabled if needed?
- [ ] No N+1 query problems observed?
- [ ] Benchmark: insertion 1M rows → measure time + memory

### Risk Assessment
- [ ] ✅ Safe to proceed / ⚠️ Needs optimization / 🚨 Blocker found
- **Blocker action:** If found, escalate to Founder + propose mitigation

---

## 2. AI Integration Layer (xAI / OpenRouter)

Hub's AI client abstracts provider selection (xAI primary, OpenRouter fallback). Tổng Tài reuses with multi-feature routing.

### Provider Client Abstraction
- [ ] Hub's `AIProvider` interface defined (xAI, OpenRouter, etc.)?
- [ ] No Hub-specific prompt engineering in shared client
- [ ] Provider selection logic (xAI → OpenRouter fallback) tested
- [ ] Test: Unit test provider fallback (xAI fail → OpenRouter attempt)

### Multi-Feature Routing
- [ ] Routing logic accommodates Tổng Tài's 10 features (document-extract, summary, classify, etc.)
- [ ] Each feature has default provider + fallback
- [ ] Cost model (tokens + price/feature) accurate for both products
- [ ] Test: Cost estimation on 10 sample requests (5 Hub, 5 Tổng Tài)

### Shared AI Layer Extraction
- [ ] Folder structure: `mobile/shared/core/ai/`
- [ ] No Hub-specific domain knowledge in shared layer
- [ ] Tổng Tài can extend `AIProvider` for custom integrations
- [ ] Test: Write 3 integration tests (Hub feature, Tổng Tài feature, multi-provider)

### BYOK Key Handling
- [ ] Hub stores API keys in `flutter_secure_storage` (or equivalent)
- [ ] Tổng Tài uses same secure storage mechanism
- [ ] Keys never logged or exposed in debug output
- [ ] Test: Verify keys in secure storage (with `adb` / Xcode if possible)

### Cost & Billing Accuracy
- [ ] Hub's token counting accurate (verify against provider APIs)
- [ ] Tổng Tài's cost model reflects actual usage patterns
- [ ] No silent overages or unexpected charges in integration test
- [ ] Test: Run 10 requests, compare predicted vs. actual cost

### Risk Assessment
- [ ] ✅ Safe to proceed / ⚠️ Needs optimization / 🚨 Blocker found
- **Blocker action:** If found, escalate to Founder + propose mitigation

---

## 3. UI Components (Card, Button, Chart, etc.)

Hub's component library provides 80% of Tổng Tài's UI building blocks. Validation that extraction is clean and reusable.

### Component Library Coverage
- [ ] List of Hub components (card, button, dialog, form input, chart, etc.)
- [ ] 80% of Tổng Tài's 60-screen wireframes use Hub components?
- [ ] Remaining 20% (custom/unique) identified + deferred or built new?
- [ ] Test: Map each Tổng Tài wireframe to Hub component + note gaps

### Shared Components Extraction
- [ ] Folder structure: `mobile/shared/core/ui/`
- [ ] Components have zero product-specific dependencies
- [ ] Theming system (colors, typography, spacing) abstracted
- [ ] Component README documenting usage (with examples)
- [ ] Test: Build a 5-screen prototype using only shared components

### Domain Color Palette Adaptation
- [ ] Hub's color system (Light/Dark mode) documented
- [ ] Tổng Tài's 10-module color palette defined (vs. Hub's 4-color palette)
- [ ] Color system supports both palettes without collision
- [ ] Test: Render same component in Hub colors + Tổng Tài colors

### No Hub-Specific Styling
- [ ] Audit shared components for Hub-specific strings/branding
- [ ] No `if (isHub) { ... }` or product-specific logic in components
- [ ] Styling uses theme tokens, not hardcoded colors
- [ ] Test: Lint shared components for Hub references

### Performance on Lower-End Devices
- [ ] Test component rendering on Nokia 6.1 (low-end reference)
- [ ] No jank or frame drops when scrolling lists
- [ ] Chart rendering performant (real-time vs. pre-rendered)
- [ ] Test: Video record scrolling on low-end device (no stutter)

### Risk Assessment
- [ ] ✅ Safe to proceed / ⚠️ Needs optimization / 🚨 Blocker found
- **Blocker action:** If found, escalate to Founder + propose mitigation

---

## 4. Navigation Framework

Hub's bottom-nav (5 tabs) + state persistence must work for Tổng Tài's modal-driven navigation.

### Bottom Nav Pattern Reuse
- [ ] Hub's bottom nav framework uses GetX / Provider / Riverpod?
- [ ] Tab state persisted across rotations?
- [ ] Tổng Tài's 5-tab layout mockup maps to Hub nav framework?
- [ ] Test: Navigate 5 tabs, rotate device, confirm state preserved

### Deep Linking Support
- [ ] Hub's deep-link routing supports dynamic parameters?
- [ ] Tổng Tài can add own deep-link schemes without collision?
- [ ] Test: deep link to Tổng Tài screens (e.g., `tongtai://document/123`)

### Shared Navigation Layer Extraction
- [ ] Folder structure: `mobile/shared/core/navigation/`
- [ ] Router configuration agnostic to product
- [ ] No Hub-specific routes in shared navigation
- [ ] Test: Write 3 navigation tests (Hub flow, Tổng Tài flow, cross-product)

### Modal/Bottom-Sheet Handling
- [ ] Hub's modal system documented (full-screen vs. bottom-sheet)
- [ ] Tổng Tài can reuse modal patterns
- [ ] No modal nesting issues observed
- [ ] Test: Open 3 nested modals, verify dismiss chain works

### Risk Assessment
- [ ] ✅ Safe to proceed / ⚠️ Needs optimization / 🚨 Blocker found
- **Blocker action:** If found, escalate to Founder + propose mitigation

---

## 5. What's NOT Reusable (Confirm)

### Authentication: Hub ← → Tổng Tài (None Expected)
- [ ] Confirm: Hub's Keycloak OAuth NOT needed for Tổng Tài MVP?
- [ ] Tổng Tài has its own auth layer (if needed at all)?
- [ ] No cross-product login flow?
- **Decision:** BYOK API keys (no auth) per ADR-002

### Data Models: (None Expected)
- [ ] Confirm: 0% model reuse (different entities: Hub docs vs. Tổng Tài objects)?
- [ ] Each product has own Drift tables + queries?
- [ ] No shared data migrations?
- **Decision:** Separate schema + separate Drift DAO per product

### API Clients: (None Expected)
- [ ] Hub API client calls ≠ Tổng Tài API client calls?
- [ ] Different integrations: Hub (Keycloak/Portal) vs. Tổng Tài (own backend)?
- [ ] No API client sharing?
- **Decision:** Each product implements own API layer (if any)

### Risk Assessment
- [ ] ✅ All non-reusable boundaries confirmed

---

## 6. Overall Go/No-Go Decision

### All 5 Areas Passed?
- [ ] Storage: ✅ / ⚠️ / 🚨
- [ ] AI Integration: ✅ / ⚠️ / 🚨
- [ ] UI Components: ✅ / ⚠️ / 🚨
- [ ] Navigation: ✅ / ⚠️ / 🚨
- [ ] Non-Reusable Boundaries: ✅ / ⚠️ / 🚨

### Recommendation
- [ ] **GO** — All areas passed; proceed to Phase 2 architecture
- [ ] **GO with conditions** — Minor optimization needed; not blocker
  - Conditions: [list here]
- [ ] **HOLD** — Needs rework; escalate to Founder
  - Blockers: [list here]

### Sign-Off
- **Tech Lead:** _________________ **Date:** _______
- **QA/Validator:** _________________ **Date:** _______

---

---

# Bảng Kiểm Tra Xác Minh Hub Reuse — Đánh Giá Kỹ Thuật Phase 1C

**Kỳ:** 20–26 Tháng 7, 2026  
**Chủ Trì:** Tech Lead / QA  
**Trạng Thái:** Bảng kiểm để xác minh fit-gap Phase 1C

---

## 🎯 Mục Đích

Xác minh các thành phần kiến trúc của Hub (lưu trữ, tích hợp AI, UI, điều hướng) thực sự tái sử dụng được cho Tổng Tài mà không cần phải làm lại toàn bộ. Xác nhận các quyết định ADR là hợp lý trước khi khóa kiến trúc Phase 2.

---

## 1. Tầng Lưu Trữ (SQLite + Drift)

Hub tái sử dụng SQLite + Drift; mô hình 15-entity của Tổng Tài phải phù hợp với tầng chia sẻ được trích xuất của Hub.

### Tương Thích Schema Cơ Sở Dữ Liệu
- [ ] Schema SQLite của Hub được xác định + tài liệu hóa
- [ ] Mô hình 15-entity của Tổng Tài (xem Product Design Bible) được ánh xạ tới schema
- [ ] Không có xung đột schema (tên bảng giống, mục đích khác)?
- [ ] Mô hình Tổng Tài có thể được thêm vào mà không cần di chuyển dữ liệu Hub?
- [ ] Kiểm tra: Tạo các migration Drift cho cả hai sản phẩm một cách độc lập

### Drift Codegen & Migrations
- [ ] `database.dart` Drift của Hub được trích xuất (không có logic cụ thể sản phẩm)?
- [ ] Các migration Tổng Tài tham chiếu schema chia sẻ, không phải schema Hub
- [ ] Drift codegen tạo ra DAO/queries chính xác cho cả hai sản phẩm
- [ ] Kiểm tra: Chạy `flutter pub run build_runner build` — không có xung đột

### Trích Xuất Tầng Lưu Trữ Chia Sẻ
- [ ] Cấu trúc thư mục được tạo: `mobile/shared/core/storage/`
- [ ] Repository pattern đóng gói các lệnh gọi DAO của cả Hub và Tổng Tài
- [ ] Không có logic kinh doanh cụ thể Hub trong tầng lưu trữ chia sẻ
- [ ] Tổng Tài có thể chèn các repository riêng nếu cần
- [ ] Kiểm tra: Viết 3 bài kiểm tra đơn vị (một Hub, một Tổng Tài, một chia sẻ)

### Hiệu Suất với Tập Dữ Liệu Lớn Hơn
- [ ] Schema/queries của Hub được kiểm tra với 100k hàng (kiểm tra khí)?
- [ ] Ước tính 1M+ hàng của Tổng Tài: hiệu suất query có chấp nhận được không?
  - [ ] Chỉ mục được xác định cho các cột truy vấn cao?
  - [ ] FTS5 full-text search được bật nếu cần?
- [ ] Không có vấn đề truy vấn N+1 được quan sát?
- [ ] Benchmark: chèn 1M hàng → đo thời gian + bộ nhớ

### Đánh Giá Rủi Ro
- [ ] ✅ An toàn để tiếp tục / ⚠️ Cần tối ưu hóa / 🚨 Chỉ ra chặn đường
- **Hành động chặn:** Nếu tìm thấy, báo cáo cho Founder + đề xuất giảm thiểu

---

## 2. Tầng Tích Hợp AI (xAI / OpenRouter)

Client AI của Hub trích xuất lựa chọn nhà cung cấp (xAI chính, OpenRouter dự phòng). Tổng Tài tái sử dụng với định tuyến đa tính năng.

### Trích Xuất Client Nhà Cung Cấp
- [ ] Giao diện `AIProvider` của Hub được xác định (xAI, OpenRouter, v.v.)?
- [ ] Không có kỹ thuật prompt cụ thể Hub trong client chia sẻ
- [ ] Logic lựa chọn nhà cung cấp (xAI → dự phòng OpenRouter) được kiểm tra
- [ ] Kiểm tra: Bài kiểm tra đơn vị dự phòng nhà cung cấp (xAI không → nỗ lực OpenRouter)

### Định Tuyến Đa Tính Năng
- [ ] Logic định tuyến phù hợp với 10 tính năng của Tổng Tài (trích xuất tài liệu, tóm tắt, phân loại, v.v.)
- [ ] Mỗi tính năng có nhà cung cấp mặc định + dự phòng
- [ ] Mô hình chi phí (token + giá/tính năng) chính xác cho cả hai sản phẩm
- [ ] Kiểm tra: Ước tính chi phí trên 10 yêu cầu mẫu (5 Hub, 5 Tổng Tài)

### Trích Xuất Tầng AI Chia Sẻ
- [ ] Cấu trúc thư mục: `mobile/shared/core/ai/`
- [ ] Không có kiến thức miền cụ thể Hub trong tầng chia sẻ
- [ ] Tổng Tài có thể mở rộng `AIProvider` cho tích hợp tùy chỉnh
- [ ] Kiểm tra: Viết 3 bài kiểm tra tích hợp (tính năng Hub, tính năng Tổng Tài, đa nhà cung cấp)

### Xử Lý Khóa BYOK
- [ ] Hub lưu trữ khóa API trong `flutter_secure_storage` (hoặc tương đương)
- [ ] Tổng Tài sử dụng cơ chế lưu trữ an toàn giống nhau
- [ ] Khóa không bao giờ được ghi nhật ký hoặc tiếp xúc trong đầu ra gỡ lỗi
- [ ] Kiểm tra: Xác minh khóa trong lưu trữ an toàn (với `adb` / Xcode nếu có thể)

### Độ Chính Xác Chi Phí & Thanh Toán
- [ ] Đếm token của Hub chính xác (xác minh so với API nhà cung cấp)
- [ ] Mô hình chi phí của Tổng Tài phản ánh các mô hình sử dụng thực tế
- [ ] Không có quá hạn im lặng hoặc chi phí không mong muốn trong bài kiểm tra tích hợp
- [ ] Kiểm tra: Chạy 10 yêu cầu, so sánh chi phí dự đoán so với thực tế

### Đánh Giá Rủi Ro
- [ ] ✅ An toàn để tiếp tục / ⚠️ Cần tối ưu hóa / 🚨 Chỉ ra chặn đường
- **Hành động chặn:** Nếu tìm thấy, báo cáo cho Founder + đề xuất giảm thiểu

---

## 3. Thành Phần UI (Card, Button, Chart, v.v.)

Thư viện thành phần của Hub cung cấp 80% các khối xây dựng UI của Tổng Tài. Xác minh rằng việc trích xuất sạch sẽ và có thể tái sử dụng được.

### Phạm Vi Thư Viện Thành Phần
- [ ] Danh sách các thành phần Hub (card, button, dialog, form input, chart, v.v.)
- [ ] 80% của 60 wireframe màn hình Tổng Tài sử dụng các thành phần Hub?
- [ ] 20% còn lại (tùy chỉnh/duy nhất) được xác định + trì hoãn hoặc xây dựng mới?
- [ ] Kiểm tra: Ánh xạ mỗi wireframe Tổng Tài tới thành phần Hub + ghi chú khoảng cách

### Trích Xuất Thành Phần Chia Sẻ
- [ ] Cấu trúc thư mục: `mobile/shared/core/ui/`
- [ ] Các thành phần không có phụ thuộc cụ thể sản phẩm
- [ ] Hệ thống chủ đề (màu sắc, kiểu chữ, khoảng cách) được trích xuất
- [ ] README thành phần ghi lại cách sử dụng (với ví dụ)
- [ ] Kiểm tra: Xây dựng nguyên mẫu 5 màn hình chỉ sử dụng các thành phần chia sẻ

### Thích Ứng Bảng Màu Miền
- [ ] Hệ thống màu của Hub (chế độ Light/Dark) được tài liệu hóa
- [ ] Bảng màu 10-module của Tổng Tài được xác định (so với bảng 4 màu của Hub)
- [ ] Hệ thống màu hỗ trợ cả hai bảng màu mà không va chạm
- [ ] Kiểm tra: Kết xuất cùng một thành phần trong màu Hub + màu Tổng Tài

### Không Có Kiểu Dáng Cụ Thể Hub
- [ ] Kiểm toán các thành phần chia sẻ cho chuỗi cụ thể Hub/thương hiệu
- [ ] Không `if (isHub) { ... }` hoặc logic cụ thể sản phẩm trong thành phần
- [ ] Kiểu dáng sử dụng mã thông báo chủ đề, không phải màu được mã hóa cứng
- [ ] Kiểm tra: Lint các thành phần chia sẻ cho các tham chiếu Hub

### Hiệu Suất trên Thiết Bị Cấp Thấp Hơn
- [ ] Kiểm tra kết xuất thành phần trên Nokia 6.1 (tham chiếu cấp thấp)
- [ ] Không nhức hoặc rơi khung hình khi cuộn danh sách
- [ ] Kết xuất biểu đồ hiệu suất (thời gian thực so với được kết xuất trước)
- [ ] Kiểm tra: Video ghi lại cuộn trên thiết bị cấp thấp (không bị trôi)

### Đánh Giá Rủi Ro
- [ ] ✅ An toàn để tiếp tục / ⚠️ Cần tối ưu hóa / 🚨 Chỉ ra chặn đường
- **Hành động chặn:** Nếu tìm thấy, báo cáo cho Founder + đề xuất giảm thiểu

---

## 4. Khung Điều Hướng

Bottom-nav của Hub (5 tab) + khôi phục trạng thái phải hoạt động cho điều hướng do phương thức của Tổng Tài.

### Tái Sử Dụng Mẫu Bottom Nav
- [ ] Khung bottom nav của Hub sử dụng GetX / Provider / Riverpod?
- [ ] Trạng thái tab được duy trì trong các xoay?
- [ ] Bố cục 5-tab của Tổng Tài được ánh xạ tới khung nav Hub?
- [ ] Kiểm tra: Điều hướng 5 tab, xoay thiết bị, xác nhận trạng thái được bảo lưu

### Hỗ Trợ Liên Kết Sâu
- [ ] Định tuyến liên kết sâu của Hub hỗ trợ tham số động?
- [ ] Tổng Tài có thể thêm các lược đồ liên kết sâu riêng mà không va chạm?
- [ ] Kiểm tra: liên kết sâu tới màn hình Tổng Tài (ví dụ: `tongtai://document/123`)

### Trích Xuất Tầng Điều Hướng Chia Sẻ
- [ ] Cấu trúc thư mục: `mobile/shared/core/navigation/`
- [ ] Cấu hình Router không phụ thuộc vào sản phẩm
- [ ] Không có tuyến cụ thể Hub trong điều hướng chia sẻ
- [ ] Kiểm tra: Viết 3 bài kiểm tra điều hướng (luồng Hub, luồng Tổng Tài, qua sản phẩm)

### Xử Lý Modal/Bottom-Sheet
- [ ] Hệ thống modal của Hub được tài liệu hóa (toàn màn hình vs. bottom-sheet)
- [ ] Tổng Tài có thể tái sử dụng các mẫu modal
- [ ] Không có vấn đề lồng modal quan sát
- [ ] Kiểm tra: Mở 3 modal lồng nhau, xác minh chuỗi bỏ đi hoạt động

### Đánh Giá Rủi Ro
- [ ] ✅ An toàn để tiếp tục / ⚠️ Cần tối ưu hóa / 🚨 Chỉ ra chặn đường
- **Hành động chặn:** Nếu tìm thấy, báo cáo cho Founder + đề xuất giảm thiểu

---

## 5. Những Điều KHÔNG Tái Sử Dụng Được (Xác Nhận)

### Xác Thực: Hub ← → Tổng Tài (Không Dự Kiến)
- [ ] Xác nhận: Xác thực OAuth Keycloak của Hub KHÔNG cần cho Tổng Tài MVP?
- [ ] Tổng Tài có tầng xác thực riêng (nếu cần)?
- [ ] Không có luồng đăng nhập sản phẩm chéo?
- **Quyết định:** Khóa API BYOK (không xác thực) theo ADR-002

### Mô Hình Dữ Liệu: (Không Dự Kiến)
- [ ] Xác nhận: 0% tái sử dụng mô hình (các thực thể khác: tài liệu Hub so với đối tượng Tổng Tài)?
- [ ] Mỗi sản phẩm có bảng + truy vấn Drift riêng?
- [ ] Không có di chuyển dữ liệu chia sẻ?
- **Quyết định:** Schema riêng + Drift DAO riêng cho mỗi sản phẩm

### Khách Hàng API: (Không Dự Kiến)
- [ ] Lệnh gọi khách hàng API Hub ≠ lệnh gọi khách hàng API Tổng Tài?
- [ ] Các tích hợp khác nhau: Hub (Keycloak/Portal) so với Tổng Tài (backend riêng)?
- [ ] Không có chia sẻ khách hàng API?
- **Quyết định:** Mỗi sản phẩm triển khai tầng API riêng (nếu có)

### Đánh Giá Rủi Ro
- [ ] ✅ Tất cả các ranh giới không tái sử dụng được được xác nhận

---

## 6. Quyết Định Go/No-Go Tổng Thể

### Tất Cả 5 Khu Vực Được Vượt Qua?
- [ ] Lưu trữ: ✅ / ⚠️ / 🚨
- [ ] Tích hợp AI: ✅ / ⚠️ / 🚨
- [ ] Thành phần UI: ✅ / ⚠️ / 🚨
- [ ] Điều hướng: ✅ / ⚠️ / 🚨
- [ ] Ranh giới Không Tái Sử Dụng: ✅ / ⚠️ / 🚨

### Khuyến Cáo
- [ ] **GO** — Tất cả các khu vực đã vượt qua; tiến hành kiến trúc Phase 2
- [ ] **GO với điều kiện** — Cần tối ưu hóa nhỏ; không phải chặn đường
  - Điều kiện: [danh sách ở đây]
- [ ] **HOLD** — Cần làm lại; báo cáo cho Founder
  - Chặn đường: [danh sách ở đây]

### Ký Tên
- **Tech Lead:** _________________ **Ngày:** _______
- **QA/Validator:** _________________ **Ngày:** _______
