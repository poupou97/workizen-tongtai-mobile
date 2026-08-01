# Confluence Update Proposal

> **Trạng thái: PROPOSAL — chưa trang nào bị sửa.** Directive yêu cầu
> *"Confluence proposal đã sẵn sàng"*, không yêu cầu cập nhật. Tôi không sửa
> Confluence trước khi anh duyệt, vì các thay đổi dưới đây gắn với quyết định
> A/B/C chưa có.

---

## 1. Thực trạng — space `workizento` có gì (đã kiểm, không suy đoán)

**13 trang.** Sắp theo lần sửa gần nhất:

| # | Trang | Trạng thái |
|---|---|---|
| 1 | Error-Handling Seam (WTM-148 / ADR-TON-017) — Founder nghiệm thu 2026-07-31 | ✅ mới, đúng |
| 2 | Predictive Foundation: Capability Context, Rule Twin & AI Explanation (2026-07-30) | ✅ mới, đúng |
| 3 | Process Hardening: UI Maturity Model, One Data Path & Testing Bible (2026-07-30) | ✅ mới, đúng |
| 4 | E12/E13 — Document/Contract + Marketing/Publishing: AGPL/EE review + adapter design | ⚠️ Phase-2 reference, **liên quan Open Source** |
| 5 | 🏁 Phase 1 – COMPLETED (Approved) | 📦 lịch sử |
| 6 | Governance, Decisions & Roadmap — Phase 1B Final | ⚠️ **lỗi thời** |
| 7 | Screen Specifications — Tổng Tài Phase 1B | ⚠️ **lỗi thời** |
| 8 | Design System Overview — Tổng Tài UI/UX | ⚠️ chưa gồm token a11y mới (WTM-168) |
| 9 | Tổng Tài — Phase 1 Backlog & Plan (WTM) | 📦 lịch sử |
| 10 | Task Order — TONGTAI-BOOTSTRAP-001 (Phase 1) | 📦 lịch sử |
| 11 | workizen-tongtai-mobile (trang chủ space) | ⚠️ **trống nghĩa** |
| 12–13 | Template — Troubleshooting / How-to | — |

### Điều đáng nói

Directive yêu cầu cập nhật *"Product Bible · Blueprint · Information Architecture ·
Capability Map · Business Journey · Roadmap · Epic Mapping · Open Source
Alignment · Migration Plan"*.

**Không trang nào trong chín trang đó tồn tại trên Confluence.** Bảy trong số
chúng cũng không tồn tại dưới dạng tài liệu ở đâu cả — chúng tồn tại trong
`docs/` của repo dưới tên khác, hoặc không tồn tại.

| Directive gọi tên | Thực tế |
|---|---|
| Product Bible | `docs/01-PRODUCT/` (repo) — Confluence **không có** |
| Blueprint | **không tồn tại** dưới tên này |
| Information Architecture | **không tồn tại** dưới dạng tài liệu riêng — IA nằm trong code |
| Capability Map | gần nhất là `UI-IMPLEMENTATION-LEVELS.md` (repo) |
| Business Journey | là **capability trong sản phẩm**, không phải tài liệu |
| Roadmap | `docs/04-DELIVERY/ROADMAP.md` (repo) — Confluence **không có** |
| Epic Mapping | Jira **là** epic mapping |
| Open Source Alignment | **không tồn tại** — báo cáo 16 là bản đầu tiên |
| Migration Plan | **không tồn tại** — báo cáo 22 là bản đầu tiên |

> Đây không phải lỗi. `docs/00-START-HERE/SOURCE-OF-TRUTH.md` đã quy định:
> **quyết định sống trong `docs/` có version, Confluence là nơi báo cáo cho
> người.** Confluence thiếu chúng là **đúng thiết kế**, không phải drift.

---

## 2. Đề xuất — 3 việc, theo thứ tự

### Việc 1 — Đăng báo cáo Product Reset (làm ngay khi được duyệt)

**Trang mới:** *"Tổng Tài — Product Reset & Roadmap Reset (2026-08-01)"*

Nội dung: Executive Summary (báo cáo 1) + Recommendations (báo cáo 24) + link
tới `docs/07-PRODUCT-RESET/` trong repo cho 22 báo cáo còn lại.

**Không sao chép cả 24 báo cáo lên Confluence.** Chúng dài, và bản trong repo
có version — bản sao trên Confluence sẽ lệch trong vài tuần, như trang #6 và #7
đang lệch bây giờ.

### Việc 2 — Đánh dấu 2 trang lỗi thời (làm ngay khi được duyệt)

| Trang | Đề xuất |
|---|---|
| **Governance, Decisions & Roadmap — Phase 1B Final** | thêm banner đầu trang: *"Lịch sử Phase 1B. Roadmap hiện hành: `docs/04-DELIVERY/ROADMAP.md` + Roadmap Reset 2026-08-01."* |
| **Screen Specifications — Phase 1B** | thêm banner: *"Đặc tả Phase 1B. Sản phẩm đã vượt qua tài liệu này; nguồn sự thật là code + ma trận L0–L4."* |

**Không xoá, không archive.** Chúng là biên bản của một giai đoạn đã được duyệt.
Chỉ cần nói rõ chúng không còn là hướng dẫn.

### Việc 3 — Làm trang chủ space nói được điều gì (làm ngay khi được duyệt)

Trang **workizen-tongtai-mobile** hiện gần như trống. Đề xuất nội dung tối thiểu:
sản phẩm là gì · đọc `docs/00-START-HERE/AGENT-ONBOARDING.md` trước · trạng thái
hôm nay (8 capability, 6 ở L4, 1419 test) · link 3 trang nghiệm thu gần nhất ·
**các quyết định đang chờ Founder**.

---

## 3. Đề xuất **chờ quyết định A/B/C**

| Trang | Chờ gì |
|---|---|
| **Product Bible vNext** | chờ quyết định định vị AI (Khuyến nghị 5) — nhãn sản phẩm nằm ngay dòng đầu |
| **Information Architecture vNext** | chờ closed beta; đổi điều hướng trước khi có phản hồi thật là đổi hai lần |
| **Capability Map vNext** | chờ A/B/C — một nửa capability trong bản đồ chỉ tồn tại ở hướng B/C |
| **Connection Center Architecture** | chờ A/B/C |
| **Open Source Radar** | chờ A/B/C — mọi ứng viên nghiêm túc đều là phần mềm máy chủ |

Ba bản vNext **đã viết sẵn** trong `docs/07-PRODUCT-RESET/` và sẽ đăng lên
Confluence ngay khi có quyết định.

---

## 4. Một đề nghị về nguyên tắc

Confluence đang có **3 trang tốt** (nghiệm thu WTM-148, ADR-TON-016, ADR-TON-015)
và **2 trang lỗi thời**. Tỷ lệ đó xấu đi mỗi lần ta chép tài liệu kỹ thuật lên
đây.

**Đề nghị:** Confluence chỉ chứa **hai loại trang** —
1. **biên bản nghiệm thu** (đóng băng theo thời điểm, không bao giờ lỗi thời), và
2. **con trỏ** tới nguồn sự thật trong repo.

Không chứa tài liệu kỹ thuật sống. Tài liệu sống ở nơi có `git blame`.
