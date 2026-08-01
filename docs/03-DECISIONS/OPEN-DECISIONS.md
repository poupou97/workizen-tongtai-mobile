# Founder Decisions — Single Source of Truth

**Cập nhật:** 2026-07-23 — Founder phê duyệt toàn bộ D-2…D-10 (nguyên văn bên
dưới). Bản phân tích phương án gốc (2026-07-13) đã archive tại
[../archive/phase-1-2/OPEN-DECISIONS-ANALYSIS-2026-07-13.md](../archive/phase-1-2/OPEN-DECISIONS-ANALYSIS-2026-07-13.md).
Quyết định kiến trúc có ADR riêng (xem [ADR-INDEX.md](ADR-INDEX.md)).

| # | Quyết định | Kết luận Founder (2026-07-23) | Ghi chú thực thi |
|---|---|---|---|
| D-1 | App separation | ✅ 2026-07-16: single-app + flavors → **repo riêng** | ADR-TON-001 + ADR-TON-003 |
| D-2 | Package/Bundle ID | ✅ `com.workizen.tongtai` (Android + iOS) | Đã implement từ split |
| D-3 | MVP Launch | ✅ Closed Beta → Open Beta → Production (tái dùng quy trình Hub) | Ảnh hưởng kế hoạch QA/release Phase 2 |
| D-4 | Authentication | ✅ Phase 2: **không login**, identity local (UUID thiết bị). Phase 3: Keycloak optional (backup/restore/sync/team) | Local-First giữ nguyên; khớp WTM-58 đã ship |
| D-5 | Backend | ✅ Phase 2: **không backend, không sync** — SQLite + AI provider only. Portal để phase sau | Xác nhận ADR-TON-004 (chat không vào outbox) |
| D-6 | Monetization | ✅ Phase 2: Free MVP. Phase 3: RevenueCat — subscription, credits, premium AI | Không thêm SDK billing ở Phase 2 |
| D-7 | Analytics | ✅ **UPDATED — supersede đề xuất cũ**: Phase 2 CHO PHÉP Firebase Analytics (operational events cơ bản) + Crashlytics, mục đích duy nhất: giám sát chất lượng closed beta. CẤM: ad SDK, marketing tracking, user profiling, personalized ads | **ADR-TON-005**; cần story tích hợp Firebase |
| D-8 | Ngôn ngữ | ✅ Tiếng Việt primary, English secondary; thêm ngôn ngữ dần | Khớp bilingual convention hiện tại |
| D-9 | AI Provider | ✅ **UPDATED — supersede xAI-first**: kiến trúc **Workizen AI → AI Router → (Gemini · xAI · Claude · OpenRouter · Cerebras · Ollama local)**, 3 chế độ Managed / BYOK / Local. User chỉ tương tác với "Workizen AI"; Router chọn provider | **ADR-TON-006**; Phase 2 khả thi: BYOK + Local (Managed cần backend → Phase 3 theo D-5) |
| D-10 | Export & BI | ✅ **UPDATED**: Phase 2 có **CSV Export**; Reports/Dashboards/BI để Phase 3. Phase 2 tập trung core workflow + Opportunity Engine | WTM-99 chuyển vào Phase 2 (Ready) |

## Uỷ quyền kèm theo (nguyên văn)

PM Agent được phép: cập nhật file này, đánh dấu SUPERSEDED, sync ADR/
Confluence/Jira, xoá khuyến nghị lỗi thời — **không cần Founder duyệt thêm
cho việc đồng bộ tài liệu.**

**Standing Authorization (2026-07-23):** việc thuộc category đã duyệt trước
đó (docs sync, ADR status, Jira, CI, refactor, dependency update, cleanup,
backlog, claim story, branch, merge khi policy cho phép) → tự động APPROVED,
tiếp tục ngay. Chỉ ngắt Founder khi cần quyết định chiến lược MỚI; không chắc
→ ADR proposal + phương án an toàn nhất. Chi tiết:
[../06-GOVERNANCE/APPROVAL-RULES.md](../06-GOVERNANCE/APPROVAL-RULES.md).

### ✅ Frontier gates — APPROVED (Founder 2026-07-29 tối, "tôi approve, để các agent tự động chạy")

- **WTM-100 Backup encryption — ✅ APPROVED** (kèm duyệt thêm **crypto dependency**, L2).
  Agent tự chạy: mã hoá backup/export bằng passphrase (AEAD), round-trip test, không đổi
  flow export mặc định (mã hoá = tuỳ chọn).
- **WTM-83 (phần còn lại) QR key input + key rotation — ✅ APPROVED** (kèm duyệt dependency
  QR scanner nếu cần). Agent tự chạy.
- **WTM-108 Firebase Analytics + Crashlytics — ✅ APPROVED** (chính sách đã có từ D-7/
  ADR-TON-005). ⚠️ Vẫn cần Founder cấp **Firebase project + `google-services.json`** —
  agent implement seam trước (build không được vỡ khi CHƯA có config; file config Founder
  bổ sung sau là chạy).
- Thứ tự agent tự chọn theo Backlog Selection (value/self-executable trước).

## Còn mở (chưa quyết)

- **Mascot species: ✅ Business Fox (Founder 2026-07-24)** — đóng mục 7 WTM-11.
  Còn: chọn 3/10 concept (WTM-109, chờ Founder xem gallery) → làm icon/splash…
- WTM-101 nghi trùng WTM-59 — chờ Founder đóng/làm rõ.
- SQLCipher (nâng mã hoá at-rest toàn DB) — option ghi trong ADR-TON-004 (KHÔNG nằm trong
  approval WTM-100 ở trên; cần quyết riêng vì đụng migration DB).

### ✅ Gates tier kế tiếp — ĐÃ QUYẾT (Founder 2026-07-25 → **ADR-TON-010**)

> Arc persistence cho 4 capability người-dùng-tự-nhập (Finance/Inventory/Consumer/
> Journey) đã HOÀN TẤT. Founder đã quyết 3 gate mở khoá tier kế tiếp:

- **G-1 · Home = User Data First — ✅ APPROVED.** Home **luôn** hiển thị dữ liệu
  kinh doanh THẬT; user mới thấy **zero-state + CTA onboarding**, KHÔNG sample.
  Demo data chỉ tồn tại trong **Demo Mode**; không trộn demo + production.
- **G-2 · Orders = capability độc lập — ✅ APPROVED (điều chỉnh).** Orders **sở
  hữu** lifecycle · revenue · order items · payment · (sau) invoice · shipment ·
  returns. **KHÔNG nhúng logic order vào Consumer**; Consumer Detail chỉ được
  *launch* "Create Order". **Reports + Home KPI consume Orders Repository.**
  → module `orders/` + `OrderRepository`/`OrderController` (WTM-125).
- **G-3 · AI — ▶️ OPENED IN STAGES (Founder 2026-07-29 → ADR-TON-013).** Data
  Foundation đã xong (BusinessContext snapshot phi-AI hoàn chỉnh WTM-134) →
  Founder mở G-3 theo bậc pre-approved, auto-progress, tất cả **read-only**:
  **G-3A** AI Summary (WTM-116, ✅ shipped) → **G-3B** AI Recommendation →
  **G-3C** AI Planner → **G-3D** BusinessHealth AI (rule vẫn là fallback).
  Kèm defaults: Opportunity giữ Rule Engine + AI chỉ scoring/ranking/explanation;
  Journey progress auto-derived; **WTM-122 vẫn CLOSED** (không migration).

### 📏 Product Rule mới — Layered Definition of Done (Founder 2026-07-25)

Capability chỉ **DONE** khi đủ tầng: **UI → Repository → Persistence →
Report/Dashboard → BusinessContext → AI-Ready** — và **không downstream nào còn
xài Sample**. Không đánh Done nếu Reports/Home… vẫn đọc dữ liệu mẫu. (Chi tiết:
ADR-TON-010.)

## PROPOSED (Founder, 2026-08-01) — Business Context Builder

**Nguồn:** Founder gửi giữa phiên audit SSoT/Derived Data. **Không phải việc
của sprint này** — ghi lại để một ADR tương lai giải quyết.

**Ý tưởng.** Hôm nay mỗi chỉ số nghiệp vụ có đúng một nguồn (Revenue, Profit,
Cashflow, Customer…). Bước tiếp theo: một **Business Context Builder** — trách
nhiệm **không phải tính lại** chỉ số nào, mà **gom đầu ra của mọi capability**
thành một ảnh chụp doanh nghiệp duy nhất: Finance · Inventory · Customer ·
Opportunity · Journey progress · Goals · đầu ra AI capability · tín hiệu thị
trường ngoài · supplier intelligence · Documents/Memory. **AI Copilot suy luận
từ ảnh chụp này** thay vì tự truy vấn từng module — SSoT còn nguyên, AI có
toàn cảnh SME.

**Căng thẳng phải giải khi viết ADR** (ghi trước để người viết không né):

1. **ADR-TON-016 cấm God Object** — BusinessContext hiện tại *chỉ giữ summary
   nhẹ*, phân tích sâu là Capability Context tải on-demand. "Gom tất cả" và
   "cấm God Object" chỉ sống chung được nếu Builder **gom summary + tham chiếu**,
   không gom dữ liệu thô — ADR sẽ phải vẽ ranh giới đó bằng kiểu, không bằng
   lời hứa.
2. **Builder không được thành nơi tính thứ hai.** Toàn bộ chuỗi
   WTM-196→205 là bốn lần một khái niệm bị tính hai chỗ. Builder chỉ được
   **gọi** các owner (FinanceService, CustomerRfmService, RuleTwin…), và
   governance suite hiện có (P-27, derived-data) phải phủ luôn nó.
3. **Tín hiệu ngoài / supplier intelligence** là Future Capability (D-5 chưa
   backend) — chỗ trong ảnh chụp nên khai `insufficient` như ADR-TON-022, không
   để trống im lặng.
4. Điểm chạm hiện có: `workizen_ai_context.dart` đã là phôi thai của ý này
   (gom counts cho prompt) — ADR nên nói rõ Builder thay thế hay bọc nó.

**Điều kiện bắt đầu:** mọi capability P0 PASS trong Capability PASS Matrix
(điều kiện Founder đặt cho việc mở tính năng mới).
