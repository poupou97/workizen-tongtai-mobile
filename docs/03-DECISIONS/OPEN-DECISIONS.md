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

## Còn mở (chưa quyết)

- **Mascot species: ✅ Business Fox (Founder 2026-07-24)** — đóng mục 7 WTM-11.
  Còn: chọn 3/10 concept (WTM-109, chờ Founder xem gallery) → làm icon/splash…
- Scope còn lại của WTM-83 (QR input + key rotation) — chờ Founder.
- WTM-101 nghi trùng WTM-59 — chờ Founder đóng/làm rõ.
- SQLCipher (nâng mã hoá at-rest toàn DB) — option ghi trong ADR-TON-004.

### ⛔ Gates mở khoá "tier kế tiếp" sau khi Data Foundation xong (Autonomous V2, 2026-07-25)

> Arc persistence cho 4 capability người-dùng-tự-nhập (Finance/Inventory/Consumer/
> Journey) đã HOÀN TẤT. Mọi bước giá trị cao kế tiếp đều chạm 1 trong 3 gate dưới
> — Runtime **không tự quyết**, chờ Founder. Mỗi mục kèm **phương án an toàn nhất**
> (đề xuất, chưa thực thi) theo quy tắc "không chắc → safest option".

- **G-1 · Home dashboard: Demo-preview vs User-Data-First.** WTM-14 cố ý coi
  *sample = "real business data"* để dashboard đẹp khi demo; nhưng D-5/ADR-TON-008
  **User Data First** nói user thật thấy dữ liệu thật (RỖNG khi chưa nhập). Hai
  cái mâu thuẫn ở màn Home (đang hiển thị 28 sp / 26 khách / doanh thu sample cho
  user mới). *Safest option đề xuất:* Home đọc repo thật (0 cho user mới) + empty-state
  có CTA "Thêm…"; giữ Demo Mode riêng cho screenshot/beta. **Cần Founder chọn** vì
  đổi hành vi hiển thị + thiết kế empty-state (nhiều hướng UX hợp lệ).
- **G-2 · Orders (sales) entry — khoá Reports/Home KPI thật.** `orders_table` +
  domain `CustomerOrder` đã có, NHƯNG **chưa có form nhập đơn** và **chưa có điểm
  vào UX** (nhập từ đâu: Consumer detail? màn Sales mới?). Reports & KPI doanh thu
  dựng trên orders → thật hoá được là nhờ Orders persist. Side-effects (trừ tồn kho,
  auto tạo giao dịch Finance, line-items vs tổng đơn) là **quyết định sản phẩm**.
  *Safest option đề xuất:* form đơn tối thiểu (khách + ngày + tổng + trạng thái +
  PTTT, KHÔNG side-effect) theo đúng pattern form hiện có, đặt ở Consumer detail;
  Repository over `orders_table` (items JSON có sẵn). **Cần Founder chốt** điểm vào +
  phạm vi side-effect.
- **G-3 · Workizen AI activation (BYOK/Router) — privacy red-line.** Data Foundation
  xong ⇒ biên giới kế tiếp là AI thật (ADR-TON-006: Router + Gemini/xAI/Claude/…,
  chế độ BYOK + Local). Chạm **red-line privacy/security** (xử lý BYOK key rời thiết
  bị chỉ trong Authorization header; không telemetry nội dung) ⇒ **executive gate**.
  *Safest option đề xuất:* bắt đầu ở **Local (Ollama)** + BYOK 1 provider với key
  chỉ nằm trong secure storage, có ADR proposal chi tiết luồng key trước khi code.
  **Runtime KHÔNG tự khởi động epic này.**
