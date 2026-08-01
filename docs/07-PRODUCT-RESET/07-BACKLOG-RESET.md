# Epic Reset · Story Reset · Task Order · Dependency Graph

*(Báo cáo 18–21 trong 24 · Phase 8 của directive)*

---

## Nguyên tắc

- **Không tạo task trùng.** Backlog vừa được dọn sáng nay: 62 issue mở → 10.
  Danh sách dưới đây đã đối chiếu với 10 issue còn mở đó.
- **Không tạo Implementation trước Architecture** (đúng chỉ thị).
- **Không tạo Epic cho kiến trúc chưa được duyệt.** Epic phụ thuộc quyết định
  A/B/C được ghi ở đây dưới dạng **proposal**, và chỉ tạo trên Jira sau khi
  Founder chốt.
- Mỗi Epic theo Task Order: **Business Goal → Capability → Architecture → UX →
  API → Integration → Implementation → Testing → Documentation → Release**.

## 10 issue đang mở — xử lý (✅ đã thực hiện trên Jira 2026-08-01)

| Jira | Xử lý | Nhãn đã gắn |
|---|---|---|
| **WTM-167** Epic Capability Context Performance | **GIỮ** → thành **E7** | `P1` `architecture` `performance` |
| **WTM-41** Sync Queue & Conflict | **GIỮ, chờ A/B/C** + comment giải thích | `P2` `blocked-on-decision` `connection` |
| **WTM-86** Offline indicator | **GIỮ, thu hẹp** → gộp vào hướng AI + comment | `P1` `ai` |
| **WTM-66** Supplier scoring AI | **GIỮ, chờ A/B/C** — cần dữ liệu ngoài | `P2` `blocked-on-decision` |
| **WTM-71** Pricing optimizer AI | **GIỮ, chờ A/B/C** — cần giá đối thủ | `P2` `blocked-on-decision` |
| **WTM-67** 1688/Shopee API | **GIỮ, chờ A/B/C** | `P2` `blocked-on-decision` `connection` |
| **WTM-79** Omnichannel | **GIỮ, chờ A/B/C** | `P2` `blocked-on-decision` `connection` |
| **WTM-90** Journey guidance | **PARK** — giá trị biên | `parked` |
| **WTM-112** Mascot hi-fi | **PARK** — cần designer người thật | `parked` `needs-human-designer` |
| **WTM-122** Persistence normalization | **PARK** — chỉ kéo vào khi có trigger nghiệp vụ thật (ADR-TON-009) | `parked` `tech-debt` |

**Không có issue nào cần archive.** Việc dọn đã làm sáng nay.

### Hai điều chỉnh so với dự định ban đầu — nói rõ để khỏi lệch

1. **Tôi KHÔNG đổi tên WTM-41 và WTM-67.** Dự định ban đầu là đổi tên chúng
   theo hướng C (*"hàng đợi nhập"*, *"nhập file từ sàn"*). Nhưng đổi tên là
   **ngầm chọn hướng thay Founder**. Thay vào đó: gắn `blocked-on-decision` +
   viết comment nêu rõ story sẽ mang nghĩa gì ở mỗi hướng.
2. **WTM-122 đang MỞ, không phải đã đóng.** Bản nháp trước của tài liệu này ghi
   *"giữ đóng"* — sai. Nó ở trạng thái `Ideas`, nay gắn `parked` với điều kiện
   kéo vào sprint đúng như ADR-TON-009 quy định (chỉ khi có trigger thật).

### Nhãn sprint cũ đã gỡ

`sprint-2` · `sprint-3` · `sprint-4` bị gỡ khỏi WTM-66/67/71/79/86/90. Chúng
trỏ tới các sprint không còn tồn tại — đúng loại metadata *trông có vẻ hợp lệ*
mà audit sáng nay vừa dọn.

---

# 18–19. Epic Reset — 9 Epic

### Nhóm 1 — ✅ ĐÃ TẠO TRÊN JIRA 2026-08-01 (không phụ thuộc quyết định nào)

| Epic | Jira | Thứ tự |
|---|---|---|
| E1 · Release Readiness | **WTM-175** | P0 · #1 |
| E2 · Local AI kiểm chứng | **WTM-176** | P0 · #2 |
| E3 · AI Business Profile | **WTM-177** | P1 · #3 |
| E4 · AI-first Onboarding | **WTM-178** | P1 · #4 (cần E3) |
| E5 · AI Weekly Review | **WTM-179** | P1 · #5 (cần E3) |
| E6 · Opportunity tầng 1 | **WTM-180** | P1 · #6 |
| E7 · Capability Context Performance | **WTM-167** *(đã có)* | P1 · #7 |

**E1 · Release Readiness** (WTM-175) — *Đưa Tổng Tài lên cửa hàng*
> Business Goal: người bán thật tải được app.
> Capability: không mới. Architecture: không đổi.
> Stories: nội dung pháp lý (chặn bởi Founder) · Data Safety · iOS build+ký ·
> kênh phản hồi · smoke release cuối · release checklist.
> **Dependency: chặn bởi Founder (2 hạng mục) và tài khoản Apple.**

**E2 · Local AI kiểm chứng** (WTM-176) — *Ollama chạy thật trên thiết bị*
> Business Goal: người dùng không có khoá API vẫn dùng được AI.
> ADR-TON-006 đã hứa; chưa ai chạy thử trên máy.
> Stories: khảo sát khả thi trên máy tầm thấp · đo lượng RAM/thời gian · seam đã
> có · UX khi model chưa tải · quyết định giữ hay bỏ lời hứa Local.

**E3 · AI Business Profile** (WTM-177) — *AI biết người dùng bán gì*
> Business Goal: gợi ý bớt chung chung.
> Architecture: một model nhỏ + prompt block; **không PII rời máy**.
> Stories: model + persistence · UX thu thập · nối vào prompt block · test
> negative control (profile không được chứa PII) · docs.

**E4 · AI-first Onboarding** (WTM-178) — *Ấn tượng đầu là hội thoại, không phải slide*
> Business Goal: người mới hiểu sản phẩm làm gì cho họ trong 2 phút.
> Depends: **E3**.
> Stories: luồng hội thoại · sinh danh mục/mục tiêu đầu tiên · đường thoát cho
> người không có khoá AI · a11y + l10n · thay thế onboarding cũ · test.

**E5 · AI Weekly Review** (WTM-179) — *Lý do mở app hằng tuần*
> Business Goal: giữ chân người dùng bằng giá trị định kỳ.
> Depends: **E3**. Dùng lại toàn bộ Rule Twin.
> Stories: tổng hợp tuần từ Rule Twin · AI diễn giải · thông báo cục bộ · màn
> review · trạng thái "chưa đủ dữ liệu" · test.

**E6 · Opportunity tầng 1 mở rộng** (WTM-180) — *Khai thác hết dữ liệu đang có*
> Business Goal: cơ hội hữu ích mà không cần kết nối gì.
> Stories: hàng chết vốn · khách sắp rời (nối RFM sang cơ hội) · sản phẩm mua
> kèm · mùa vụ lặp lại · **mỗi cái là một Rule Twin có reason code** · test.

**E7 · Capability Context Performance** *(= WTM-167 đang có)*
> Đã có ADR-TON-019 DRAFT + benchmark 3/12/24/60 tháng + số trên máy thật.
> Stories: khảo sát 5 hướng · bảng so sánh 8 trục · **Founder chọn hướng** →
> triển khai → đo lại → cập nhật baseline.

### Nhóm 2 — CHỜ QUYẾT ĐỊNH A/B/C (không tạo trên Jira hôm nay)

**E8 · Connection Center — Xương sống** *(chỉ khi chọn C hoặc B)*
> Business Goal: dữ liệu ngoài vào được mà không phá dữ liệu đang có.
> **Architecture trước tiên**: Connector Contract · Normalizer · Reconciler ·
> Staging+Preview · Apply một transaction · **Provenance**.
> Stories theo Task Order: ADR Connection · mở rộng Domain Model
> (Connection/Provenance) · Connector Contract · Normalizer · Reconciler ·
> Preview UX · Apply · Provenance · test SQLite thật · docs.
> **Không có story Implementation nào trước 3 story Architecture đầu.**

**E9 · Kết nối đầu tiên** *(sau E8)*
> Đề xuất **GHN qua API token** làm phép thử đầu tiên — không cần backend, đúng
> mô hình BYOK, giá trị hằng ngày. Sau đó mới tới nhập file Shopee/TikTok.

---

# 20. Task Order — thứ tự tuyệt đối

```
P0  (NOW — ra cửa hàng)
 1. E1 Release Readiness           (WTM-175)
 2. E2 Local AI kiểm chứng         (WTM-176)

P1  (NEXT — AI đáng mở app)
 3. E3 AI Business Profile         (WTM-177)
 4. E4 AI-first Onboarding         (WTM-178)  ← cần E3
 5. E5 AI Weekly Review            (WTM-179)  ← cần E3
 6. E6 Opportunity tầng 1          (WTM-180)
 7. E7 Capability Context Perf     (WTM-167)  ← độc lập, song song được

P2  (LATER — chỉ sau khi Founder chốt A/B/C)
 8. E8 Connection Center xương sống ← cần ADR mới
 9. E9 Kết nối đầu tiên (GHN)       ← cần E8
10.    Nhập file Shopee/TikTok      ← cần E8
11.    Finance: lãi thật sau phí sàn ← cần 10
12.    Opportunity tầng 2            ← cần 10

P3  (FUTURE — chỉ sau ADR huỷ D-4/D-5)
13.    Backend + tài khoản + OAuth
14.    Sàn realtime · Managed AI · Sync 2 chiều · Marketplace Intelligence

UI / Animation / Theme / Dark mode  → SAU TOÀN BỘ trên (đúng chỉ thị)
```

---

# 21. Dependency Graph

```
Founder: nội dung pháp lý ─┐
Apple account ─────────────┼─→ E1 Release ─→ Closed beta ─→ (phản hồi thật)
                           │                                    │
E2 Local AI ───────────────┘                                    │
                                                                ↓
E3 AI Profile ─→ E4 Onboarding                          ưu tiên lại
      │                                                  P1/P2 dựa trên
      └────────→ E5 Weekly Review                        dữ liệu thật
E6 Opportunity T1 ── (độc lập)
E7 Capability Perf ── (độc lập) ─→ cần Founder chọn 1/5 hướng

════════ RANH GIỚI DOCTRINE ════════
FOUNDER QUYẾT A / B / C
   │
   ├─ A: dừng ở đây
   │
   ├─ C: E8 xương sống ─→ E9 GHN ─→ nhập file sàn ─→ lãi thật ─→ Opp T2
   │        (giữ nguyên D-4/D-5, không backend)
   │
   └─ B: ADR huỷ D-4+D-5 ─→ backend ─→ OAuth ─→ realtime ─→ Managed AI
            │
            └─ cập nhật CHÍNH SÁCH RIÊNG TƯ trước khi thu dòng dữ liệu đầu tiên
```

**Ba điểm chặn cứng nằm ngoài tay đội phát triển:**

1. **Founder** — nội dung pháp lý (chặn E1, chặn phát hành)
2. **Founder** — quyết định A/B/C (chặn toàn bộ P2 và P3)
3. **Bên thứ ba** — tài khoản Apple; phê duyệt của sàn (chỉ hướng B)

---

## Vì sao tôi chưa tạo E8/E9 trên Jira

Sáng nay tôi vừa đóng **51 issue mô tả việc đã làm xong hoặc không còn đúng**.
Trong đó có **WTM-85**, mà điều kiện nghiệm thu của nó *mâu thuẫn trực tiếp* với
một ràng buộc Founder đặt ra — bằng chứng sống rằng backlog viết cho một kiến
trúc chưa chốt sẽ thành rác, và tệ hơn: thành rác **trông có vẻ hợp lệ**.

Tôi không muốn tạo thêm 30 story như thế trong cùng một ngày vừa dọn chúng đi.

**E1–E7 tôi tạo ngay** vì chúng đúng dù Founder chọn A, B hay C.
**E8–E9 chờ một câu trả lời.**
