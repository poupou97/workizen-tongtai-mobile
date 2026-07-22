# Technology Fit-Gap Analysis: Hub ↔ Tổng Tài

## Đánh Giá Phù Hợp Công Nghệ: Hub ↔ Tổng Tài

> **This document evaluates which Hub technology components can be reused, adapted, or replaced for Tổng Tài. It serves as the foundation for shared-core planning.**

**Status:** 📋 DRAFT for Review  
**Phase:** 1B — Technology Planning  
**Owner:** Architecture Team  
**Date:** 2026-07-13

---

## English — Technology Fit-Gap Analysis

### Executive Summary

Tổng Tài is a separate product built by the same team, initially sharing a codebase with Hub for MVP efficiency. This analysis identifies:

1. **What Hub has** — existing capabilities
2. **What Tổng Tài needs** — required for business functionality
3. **Fit assessment** — High / Medium / Low
4. **Reuse strategy** — Inherit / Adapt / Build New
5. **Effort & Risk** — implementation complexity

**Key Finding:** **~70% reuse potential** in infrastructure layers (storage, AI, UI framework). **~20% in UI components** (card-based pattern matches). **0% in business data models** (Tổng Tài invents new domain: Producer/Inventory/Consumer/Finance/Reports).

---

### Evaluation Dimensions

#### 1. **Local Storage Layer (SQLite + Drift)**

**Hub Has:**
- Drift ORM (type-safe database layer)
- SQLite for offline-first data persistence
- flutter_secure_storage for API keys / sensitive data
- Schema versioning & migrations

**Tổng Tài Needs:**
- SQLite for business data (users, producers/suppliers, inventory/products, consumers/customers, orders, opportunities, journeys)
- Expected scale: 100K–1M rows (suppliers, inventory, customer records)
- Same encryption/privacy model (local-first)

**Fit Assessment:** ✅ **HIGH**
- Same tech stack
- Same design principles (local-first, offline-first)
- No conflicts

**Reuse Strategy:** ✅ **ADAPT**
- Keep Drift + SQLite foundation
- Extend schema migrations for Tổng Tài tables
- Reuse encryption utilities

**Effort:** Medium
- Design business entity schemas (Producer, Inventory, Consumer, etc.)
- Write schema migration scripts
- Test concurrent access & performance

**Risk:** Low
- Migration compatibility if schema needs change mid-production (mitigated by versioning)

---

#### 2. **AI Integration Layer (xAI / OpenRouter)**

**Hub Has:**
- xAI SDK integration (chat streaming)
- OpenRouter client (fallback models, free tier)
- Model selection logic (provider-aware)
- Streaming responses for chat UI
- Token counting & cost tracking
- BYOK pattern (user's own API keys)

**Tổng Tài Needs:**
- AI chat for business copilot (advice, planning, analysis)
- Multi-provider support (xAI, OpenRouter, Claude, local Ollama)
- Model switching based on task (vision for images, reasoning for analysis)
- BYOK mandatory (user controls API keys)
- Streaming responses

**Fit Assessment:** ✅ **HIGH**
- Identical architecture
- Same provider ecosystem
- Same privacy model (BYOK)

**Reuse Strategy:** ✅ **REUSE AS-IS** (+ minimal extension)
- Inherit xAI + OpenRouter clients
- Add task-specific model selection logic (in Tổng Tài layer, not core)
- Extend prompt templates for business domain

**Effort:** Low
- Define business-domain prompts
- Test with new models (e.g., Claude for better reasoning)
- Tune cost optimization

**Risk:** Low
- No compatibility issues expected

---

#### 3. **UI/UX Component Layer**

**Hub Has:**
- Card-based UI (home cards, output cards, chat bubbles)
- Reusable Flutter widgets: Button, TextField, BottomSheet, ModalDialog, Chart, Badge
- Theme system (light/dark mode)
- Navigation framework (custom router, gesture-aware)
- Scanner UI (QR/barcode scanner screens)
- Chat UI (chat bubbles, input box, typing indicators)
- PDF viewer integration

**Tổng Tài Needs:**
- Card-based UI for business dashboard (same pattern: metric + trend + action)
- Forms for data entry (products, customers, transactions)
- Charts for analytics (revenue, inventory, customer trends)
- Search/filter UI
- List views (suppliers, products, customers)
- Same theme system

**Fit Assessment:** ✅ **HIGH**
- Card pattern is identical
- Chart components overlap
- Form components are generic

**Reuse Strategy:** ✅ **REUSE + EXTEND**
- Keep all card, button, dialog, theme components
- Extend chart library for business metrics (revenue, margin, cash flow)
- Add form-builder for data entry (reusable, not Tổng-Tài-specific)
- Add table/list components (Tổng Tài heavily uses lists)

**Effort:** Medium
- Extract generic card/form components to shared library
- Build new business-specific chart types
- Test layout responsiveness

**Risk:** Low
- UI components are decoupled; changes unlikely to break Hub

---

#### 4. **Authentication & Authorization**

**Hub Has:**
- Keycloak integration (SSO, optional account)
- BYOK API key management
- No backend login required (MVP)
- Optional Google Sign-In (for sync/backup)

**Tổng Tài Needs:**
- MVP: No authentication (offline-first, local data only)
- Future: Optional account for sync (Keycloak reusable)
- BYOK mandatory (user's own API keys)

**Fit Assessment:** ⚠️ **MEDIUM (Low for MVP)**
- Hub's Keycloak setup is overkill for Tổng Tài MVP
- BYOK pattern is identical
- No conflicts, but Tổng Tài won't use Keycloak initially

**Reuse Strategy:** ⏸️ **DEFER**
- Tổng Tài MVP: Skip Keycloak, use local-only mode
- Tổng Tài Phase 2+: Inherit Keycloak setup from Hub when sync needed

**Effort:** 
- MVP: Trivial (no auth needed)
- Phase 2: Medium (wire Keycloak for sync)

**Risk:** Low
- Delaying auth is safe; affects sync, not core features

---

#### 5. **Data Models & Business Logic**

**Hub Has:**
- Chat message model (text, attachments, metadata)
- Document model (file metadata, OCR results, chunks)
- Collection model (grouping documents)
- Output model (generated content: summary, quiz, notes, video)
- User preferences model

**Tổng Tài Needs:**
- Producer/Supplier model (sources, sourcing history, pricing)
- Inventory/Product model (SKU, stock, warehouse, pricing, document attachments)
- Consumer/Customer model (CRM data, contact, segments, purchase history)
- Order model (transactions, items, dates, status)
- Finance model (revenue, expenses, accounts, cash flow)
- Opportunity model (arbitrage, market gaps, pricing opportunities)
- Journey model (business goals, steps, progress, milestones)
- Note: These are **completely new domains**, not present in Hub

**Fit Assessment:** ❌ **LOW** (for business models)
- ✅ Hub's persistence pattern (Drift + SQLite) is reusable
- ❌ Business entities (Producer, Inventory, etc.) are Tổng-Tài-specific

**Reuse Strategy:**
- Reuse: Drift schema migration framework + SQLite infrastructure
- Build New: All business entity models (separate from Hub)

**Effort:** High
- Architect 7 new entity schemas + relationships
- Implement business logic (inventory forecasting, opportunity detection, etc.)
- Test data integrity & consistency

**Risk:** Medium
- Risk of shared database conflicts if not carefully isolated (mitigated by schema namespacing)

---

### Capability Assessment Matrix

| Capability | Hub Has? | Tổng Tài Needs? | Reuse Strategy | Effort | Risk |
|---|---|---|---|---|---|
| **Storage: SQLite + Drift** | ✅ Yes | ✅ Yes | ADAPT | Medium | Low |
| **AI Chat (xAI/OpenRouter)** | ✅ Yes | ✅ Yes | REUSE | Low | Low |
| **BYOK API Key Mgmt** | ✅ Yes | ✅ Yes | REUSE | Low | Low |
| **Card-Based UI** | ✅ Yes | ✅ Yes | REUSE+EXTEND | Medium | Low |
| **Charts & Analytics** | ✅ Partial | ✅ Yes | EXTEND | Medium | Low |
| **Forms & Data Entry** | ✅ Partial | ✅ Yes | EXTEND | Medium | Low |
| **Authentication (Keycloak)** | ✅ Yes | ⏸️ MVP No | DEFER | Low | Low |
| **Document OCR** | ✅ Yes | ❌ No | — | — | — |
| **PDF Export** | ✅ Yes | ⚠️ Maybe | ADAPT | Low | Low |
| **Business Models** | ❌ No | ✅ Yes | BUILD NEW | High | Medium |
| **CRM Features** | ❌ No | ✅ Yes | BUILD NEW | High | Medium |
| **Opportunity Engine** | ❌ No | ✅ Yes | BUILD NEW | High | High |
| **Business Analytics** | ❌ No | ✅ Yes | BUILD NEW | High | Medium |

---

### Dimension Summaries

#### ✅ Reuse as-is (Minimal change)
1. **AI Integration** — xAI + OpenRouter clients, streaming, BYOK
2. **BYOK API Key Storage** — flutter_secure_storage
3. **Theme System** — light/dark mode, design tokens

#### ✅ Reuse + Adapt (Extend for Tổng Tài)
1. **Storage Infrastructure** — Drift + SQLite, add new business schemas
2. **Card-Based UI Framework** — reuse card component, extend for business metrics
3. **Chart Components** — extend for revenue, margin, cash flow, inventory
4. **Forms & Inputs** — extend for product entry, customer entry, transaction entry

#### ⏸️ Defer (Use in Phase 2+)
1. **Authentication (Keycloak)** — not needed for MVP, defer to sync phase

#### ❌ Build New (No Hub equivalent)
1. **Business Data Models** — Producer, Inventory, Consumer, Order, Finance, Opportunity, Journey
2. **Business Logic** — sourcing algorithms, opportunity detection, journeys, financial calculations
3. **CRM Features** — customer segmentation, churn prediction, lifecycle management
4. **Workflow Engine** — journey planning, task orchestration, milestone tracking

---

### Technology Stack Alignment

| Layer | Hub | Tổng Tài | Compatible? |
|---|---|---|---|
| **Language** | Dart 3.4+ | Dart 3.4+ | ✅ Yes |
| **Framework** | Flutter 3.22+ | Flutter 3.22+ | ✅ Yes |
| **Database** | SQLite + Drift | SQLite + Drift | ✅ Yes |
| **Encryption** | flutter_secure_storage | flutter_secure_storage | ✅ Yes |
| **AI** | xAI + OpenRouter | xAI + OpenRouter | ✅ Yes |
| **UI Components** | Material 3 + Custom | Material 3 + Custom | ✅ Yes |
| **Authentication** | Keycloak (optional) | Local (MVP) | ✅ Deferred |
| **State Management** | Riverpod | Riverpod | ✅ Yes |
| **Testing** | Flutter test + Mockito | Flutter test + Mockito | ✅ Yes |

---

### Recommendations

1. **Phase 1B (Current):** Extract core packages (storage, AI, UI) into `shared/core/`
2. **Phase 1C:** Define Tổng Tài business entity schemas; start build
3. **Phase 2 (Post-Launch):** Separate repos if needed; shared packages on internal pub
4. **Phase 2+:** Add auth/sync when business logic is proven

---

## Tiếng Việt — Đánh Giá Phù Hợp Công Nghệ

### Tóm Tắt Điều Hành

Tổng Tài là sản phẩm riêng biệt được xây dựng bởi cùng một đội ngũ, ban đầu chia sẻ mã cơ sở với Hub để tiết kiệm chi phí MVP. Báo cáo này xác định:

1. **Hub có gì** — khả năng hiện tại
2. **Tổng Tài cần gì** — yêu cầu cho chức năng kinh doanh
3. **Đánh giá phù hợp** — Cao / Trung bình / Thấp
4. **Chiến lược tái sử dụng** — Kế thừa / Điều chỉnh / Xây mới
5. **Nỗ lực & Rủi ro** — độ phức tạp triển khai

**Phát hiện chính:** **~70% khả năng tái sử dụng** ở các lớp cơ sở hạ tầng (lưu trữ, AI, khung UI). **~20% ở các thành phần UI** (mô hình dựa trên thẻ). **0% ở các mô hình dữ liệu kinh doanh** (Tổng Tài tạo miền mới: Nguồn Hàng/Tồn Kho/Khách Hàng/Tài Chính/Báo Cáo).

---

### Năm Chiều Đánh Giá

#### 1. **Lớp Lưu Trữ Cục Bộ (SQLite + Drift)**

**Hub Có:**
- Drift ORM (lớp cơ sở dữ liệu an toàn loại)
- SQLite để lưu trữ dữ liệu ngoại tuyến
- flutter_secure_storage cho API key / dữ liệu nhạy cảm
- Phiên bản lược đồ & di chuyển

**Tổng Tài Cần:**
- SQLite cho dữ liệu kinh doanh (người dùng, nhà cung cấp/nguồn hàng, sản phẩm/tồn kho, khách hàng/người tiêu dùng, đơn hàng, cơ hội, hành trình)
- Quy mô dự kiến: 100K–1M hàng (nhà cung cấp, tồn kho, bản ghi khách hàng)
- Mô hình mã hóa/quyền riêng tư tương tự (cục bộ trước tiên)

**Đánh Giá Phù Hợp:** ✅ **CAO**
- Cùng ngăn xếp công nghệ
- Cùng nguyên tắc thiết kế (cục bộ trước tiên, ngoại tuyến trước tiên)
- Không xung đột

**Chiến Lược Tái Sử Dụng:** ✅ **ĐIỀU CHỈNH**
- Giữ nền tảng Drift + SQLite
- Mở rộng di chuyển lược đồ cho các bảng Tổng Tài
- Tái sử dụng tiện ích mã hóa

**Nỗ Lực:** Trung bình
- Thiết kế lược đồ thực thể kinh doanh (Nguồn Hàng, Tồn Kho, Khách Hàng, v.v.)
- Viết kịch bản di chuyển lược đồ
- Kiểm tra truy cập đồng thời & hiệu suất

**Rủi Ro:** Thấp

---

#### 2. **Lớp Tích Hợp AI (xAI / OpenRouter)**

**Hub Có:**
- Tích hợp xAI SDK (truyền phát trò chuyện)
- Máy khách OpenRouter (các mô hình dự phòng, cấp miễn phí)
- Logic lựa chọn mô hình (nhận thức về nhà cung cấp)
- Phản hồi truyền phát cho UI trò chuyện
- Đếm token & theo dõi chi phí
- Mô hình BYOK (API key của người dùng)

**Tổng Tài Cần:**
- Trò chuyện AI cho cố vấn kinh doanh (lời khuyên, lập kế hoạch, phân tích)
- Hỗ trợ nhiều nhà cung cấp (xAI, OpenRouter, Claude, Ollama cục bộ)
- Chuyển đổi mô hình dựa trên tác vụ (tầm nhìn cho hình ảnh, lý luận cho phân tích)
- BYOK bắt buộc (người dùng kiểm soát API key)
- Phản hồi truyền phát

**Đánh Giá Phù Hợp:** ✅ **CAO**
- Kiến trúc giống hệt
- Cùng hệ sinh thái nhà cung cấp
- Cùng mô hình quyền riêng tư (BYOK)

**Chiến Lược Tái Sử Dụng:** ✅ **TÁI SỬ DỤNG NGUYÊN SI** (+ mở rộng tối thiểu)
- Kế thừa máy khách xAI + OpenRouter
- Thêm logic lựa chọn mô hình cụ thể cho tác vụ (ở lớp Tổng Tài, không phải cốt lõi)
- Mở rộng mẫu dấu nhắc cho miền kinh doanh

**Nỗ Lực:** Thấp

**Rủi Ro:** Thấp

---

#### 3. **Lớp Thành Phần UI/UX**

**Hub Có:**
- UI dựa trên thẻ (thẻ trang chủ, thẻ đầu ra, bong bóng trò chuyện)
- Tiện ích Flutter có thể tái sử dụng: Nút, TextField, BottomSheet, ModalDialog, Biểu đồ, Badge
- Hệ thống chủ đề (chế độ sáng/tối)
- Khung điều hướng (bộ định tuyến tùy chỉnh, nhận thức cử chỉ)
- Giao diện máy quét (màn hình quét QR/mã vạch)
- Giao diện trò chuyện (bong bóng trò chuyện, hộp nhập, chỉ báo gõ)
- Tích hợp trình xem PDF

**Tổng Tài Cần:**
- UI dựa trên thẻ cho bảng điều khiển kinh doanh (cùng mô hình: số liệu + xu hướng + hành động)
- Biểu mẫu nhập dữ liệu (sản phẩm, khách hàng, giao dịch)
- Biểu đồ cho phân tích (doanh thu, tồn kho, xu hướng khách hàng)
- Giao diện tìm kiếm/lọc
- Chế độ xem danh sách (nhà cung cấp, sản phẩm, khách hàng)
- Cùng hệ thống chủ đề

**Đánh Giá Phù Hợp:** ✅ **CAO**
- Mô hình thẻ giống hệt
- Thành phần biểu đồ trùng lặp
- Thành phần biểu mẫu là chung

**Chiến Lược Tái Sử Dụng:** ✅ **TÁI SỬ DỤNG + MỞ RỘNG**
- Giữ tất cả thẻ, nút, hộp thoại, thành phần chủ đề
- Mở rộng thư viện biểu đồ cho số liệu kinh doanh (doanh thu, lợi nhuận, dòng tiền)
- Thêm trình tạo biểu mẫu cho nhập dữ liệu (có thể tái sử dụng, không phải Tổng-Tài-specific)
- Thêm thành phần bảng/danh sách (Tổng Tài sử dụng nhiều danh sách)

**Nỗ Lực:** Trung bình

**Rủi Ro:** Thấp

---

#### 4. **Xác Thực & Uỷ Quyền**

**Hub Có:**
- Tích hợp Keycloak (SSO, tài khoản tùy chọn)
- Quản lý API key BYOK
- Không cần đăng nhập phụ trợ (MVP)
- Đăng nhập Google tùy chọn (để đồng bộ hóa/sao lưu)

**Tổng Tài Cần:**
- MVP: Không xác thực (ngoại tuyến trước tiên, dữ liệu cục bộ)
- Tương lai: Tài khoản tùy chọn để đồng bộ hóa (Keycloak có thể tái sử dụng)
- BYOK bắt buộc (API key của người dùng)

**Đánh Giá Phù Hợp:** ⚠️ **TRUNG BÌNH (Thấp cho MVP)**
- Thiết lập Keycloak của Hub quá mức cho Tổng Tài MVP
- Mô hình BYOK giống hệt
- Không xung đột, nhưng Tổng Tài sẽ không sử dụng Keycloak ban đầu

**Chiến Lược Tái Sử Dụng:** ⏸️ **HOÃN LẠI**
- Tổng Tài MVP: Bỏ qua Keycloak, sử dụng chế độ chỉ cục bộ
- Tổng Tài Phase 2+: Kế thừa thiết lập Keycloak từ Hub khi cần đồng bộ hóa

**Nỗ Lực:** Thấp (MVP), Trung bình (Phase 2)

**Rủi Ro:** Thấp

---

#### 5. **Mô Hình Dữ Liệu & Logic Kinh Doanh**

**Hub Có:**
- Mô hình tin nhắn trò chuyện (văn bản, tệp đính kèm, siêu dữ liệu)
- Mô hình tài liệu (siêu dữ liệu tệp, kết quả OCR, đoạn)
- Mô hình bộ sưu tập (nhóm tài liệu)
- Mô hình đầu ra (nội dung được tạo: tóm tắt, câu đố, ghi chú, video)
- Mô hình tùy chọn người dùng

**Tổng Tài Cần:**
- Mô hình Nguồn Hàng/Nhà cung cấp (nguồn, lịch sử sourcing, định giá)
- Mô hình Tồn Kho/Sản phẩm (SKU, hàng tồn, nhà kho, định giá, tệp đính kèm tài liệu)
- Mô hình Khách Hàng/Người tiêu dùng (dữ liệu CRM, liên hệ, phân khúc, lịch sử mua)
- Mô hình Đơn hàng (giao dịch, mục, ngày, trạng thái)
- Mô hình Tài chính (doanh thu, chi phí, tài khoản, dòng tiền)
- Mô hình Cơ hội (chênh lệch giá, khoảng trống thị trường, cơ hội định giá)
- Mô hình Hành trình (mục tiêu kinh doanh, bước, tiến trình, mốc quan trọng)

**Đánh Giá Phù Hợp:** ❌ **THẤP** (cho mô hình kinh doanh)
- ✅ Mô hình lưu trữ của Hub (Drift + SQLite) có thể tái sử dụng
- ❌ Thực thể kinh doanh (Nguồn Hàng, Tồn Kho, v.v.) là Tổng-Tài-specific

**Chiến Lược Tái Sử Dụng:**
- Tái sử dụng: Khung di chuyển lược đồ Drift + cơ sở hạ tầng SQLite
- Xây mới: Tất cả mô hình thực thể kinh doanh (riêng với Hub)

**Nỗ Lực:** Cao

**Rủi Ro:** Trung bình

---

### Ma Trận Đánh Giá Khả Năng

| Khả Năng | Hub Có? | Tổng Tài Cần? | Chiến Lược | Nỗ Lực | Rủi Ro |
|---|---|---|---|---|---|
| **Lưu Trữ: SQLite + Drift** | ✅ Có | ✅ Có | ĐIỀU CHỈNH | Trung bình | Thấp |
| **Trò Chuyện AI** | ✅ Có | ✅ Có | TÁI SỬ DỤNG | Thấp | Thấp |
| **Quản Lý API Key BYOK** | ✅ Có | ✅ Có | TÁI SỬ DỤNG | Thấp | Thấp |
| **UI Dựa Trên Thẻ** | ✅ Có | ✅ Có | TÁI SỬ DỤNG+MỞ RỘNG | Trung bình | Thấp |
| **Biểu Đồ & Phân Tích** | ✅ Phần | ✅ Có | MỞ RỘNG | Trung bình | Thấp |
| **Biểu Mẫu & Nhập Dữ Liệu** | ✅ Phần | ✅ Có | MỞ RỘNG | Trung bình | Thấp |
| **Xác Thực (Keycloak)** | ✅ Có | ⏸️ MVP Không | HOÃN LẠI | Thấp | Thấp |
| **Mô Hình Kinh Doanh** | ❌ Không | ✅ Có | XÂY MỚI | Cao | Trung bình |
| **Tính Năng CRM** | ❌ Không | ✅ Có | XÂY MỚI | Cao | Trung bình |
| **Công Cụ Cơ Hội** | ❌ Không | ✅ Có | XÂY MỚI | Cao | Cao |

---

### Kết Luận

1. **Phase 1B (Hiện tại):** Trích xuất các gói cốt lõi (lưu trữ, AI, UI) vào `shared/core/`
2. **Phase 1C:** Định nghĩa lược đồ thực thể kinh doanh Tổng Tài; bắt đầu xây dựng
3. **Phase 2 (Sau khi phát hành):** Các kho lưu trữ riêng biệt nếu cần; các gói dùng chung trên pub nội bộ
4. **Phase 2+:** Thêm xác thực/đồng bộ hóa khi logic kinh doanh được chứng minh

---

**Version:** 1.0 (Draft)  
**Next Review:** After shared-core extraction is planned
