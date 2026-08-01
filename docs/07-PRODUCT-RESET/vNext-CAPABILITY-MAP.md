# Capability Map vNext — đề xuất

> **Trạng thái: PROPOSAL.** Bản đồ này mô tả **capability**, không mô tả màn
> hình. Đúng chỉ thị: *"Business Capability đứng trước UI."*
>
> Level hiện tại lấy từ `docs/02-ARCHITECTURE/UI-IMPLEMENTATION-LEVELS.md`
> (ADR-TON-015). **Không suy đoán.**

---

## 1. Capability đang có — và chúng thiếu gì

| # | Capability | Level | Có gì | Thiếu gì | Thiếu vì |
|---|---|---|---|---|---|
| 1 | **Inventory** | L4 | tồn kho · nhập/xuất · cảnh báo · dự báo | — | ✅ trọn vẹn |
| 2 | **Finance** | L4 | thu chi · lãi lỗ · dòng tiền | **lãi thật sau phí sàn** | không có dữ liệu phí sàn |
| 3 | **Consumer** | L4 | khách hàng · RFM · rủi ro rời bỏ | khách từ nhiều kênh | không có dữ liệu sàn |
| 4 | **Reports** | L4 | báo cáo · xuất CSV | — | ✅ |
| 5 | **Business Journey** | L4 | mục tiêu · tiến độ · điều phối | — | ✅ |
| 6 | **Producer** | L3 | nhà cung cấp · lịch sử nhập | so sánh giá nguồn ngoài | không có dữ liệu 1688/nhà cung cấp |
| 7 | **Opportunity Hub** | L3 | khung cơ hội + Rule Twin | **cơ hội tầng 1 chưa khai thác hết** | ❗**không** vì thiếu dữ liệu — chỉ là chưa làm |
| 8 | **AI Copilot** | L3 | AI Router · BYOK · Rule Twin · giải thích | dùng được khi không có khoá | Local AI chưa kiểm chứng |

> **Quan sát quan trọng:** trong 6 khoảng trống, chỉ có **hai** (#7, #8) là làm
> được ngay mà không cần quyết định kiến trúc nào. Bốn cái còn lại đều chờ cùng
> một thứ: **dữ liệu từ bên ngoài máy**.
>
> Đó là lý do roadmap NEXT tập trung vào #7 và #8, chứ không phải vì chúng dễ.

---

## 2. Capability đề xuất thêm

### Nhóm A — không phụ thuộc quyết định A/B/C

| Capability | Là gì | Vì sao cần | Phase |
|---|---|---|---|
| **AI Business Profile** | ngành · quy mô · mùa vụ · kênh bán | mọi gợi ý AI hôm nay đều chung chung vì AI không biết người dùng bán gì | NEXT |
| **Weekly Review** | tổng kết tuần do Rule Twin tính, AI diễn giải | lý do định kỳ để mở app; dùng lại toàn bộ Rule Twin đã có | NEXT |
| **Opportunity tầng 1 mở rộng** | hàng chết vốn · khách sắp rời · mua kèm · mùa vụ | 4 loại cơ hội **chỉ cần dữ liệu đang có** | NEXT |
| **Feedback kênh** | báo lỗi / góp ý trong app | phát hành mà không nghe được người dùng là đi mù | NOW |

### Nhóm B — chỉ tồn tại nếu Founder chọn C hoặc B

| Capability | Là gì | Điều kiện |
|---|---|---|
| **Connection** | quản lý nguồn dữ liệu ngoài (file hoặc API) | ADR mới |
| **Normalization** | quy dữ liệu ngoài về Domain Model | sau Connection |
| **Reconciliation** | phát hiện trùng/khác biệt, người dùng quyết | sau Normalization |
| **Provenance** | mỗi bản ghi biết mình từ đâu | **bắt buộc** cùng Connection |
| **Marketplace Finance** | lãi thật sau phí sàn | sau khi có dữ liệu sàn |
| **Channel Comparison** (Opportunity tầng 2) | kênh nào lãi hơn | sau khi có dữ liệu sàn |

### Nhóm C — chỉ tồn tại nếu chọn B (có backend)

Managed AI · Sync hai chiều · Đẩy ngược lên sàn · Cloud backup · Tài khoản/đội ngũ

### Nhóm D — quyết định thương mại, không phải kỹ thuật

**Marketplace Intelligence** (dữ liệu ngành, so sánh với người bán khác) —
cần **mua dữ liệu** hoặc **đủ người dùng để có network effect**. Không có
đường kỹ thuật nào thay thế được hai điều kiện đó.

---

## 3. Ranh giới capability — quy tắc giữ kiến trúc không mục

Giữ nguyên ADR-TON-016:

```
Repository → Aggregation Services → Capability Context →
BusinessContext (summary) → Rule Twin → AI Router → AI → Human
```

**Áp dụng cho mọi capability mới:**

| Quy tắc | Nghĩa là |
|---|---|
| Mỗi capability = **một Capability Context độc lập**, tải on-demand | không nhét thêm vào BusinessContext (cấm God Object) |
| **Rule Twin authoritative** | con số do luật tính; AI **chỉ giải thích**; thiếu dữ liệu ⇒ nói thiếu, **cấm bịa** |
| Một đường dữ liệu duy nhất (ADR-TON-015) | không cache song song, không màn tự tính summary |
| Trạng thái + lỗi qua seam (ADR-TON-017) | 6 `ScreenState`; refresh lỗi giữ dữ liệu cũ |
| Capability mới ⇒ **cập nhật `.ttbk`** (ADR-TON-018) | dữ liệu mới phải nằm trong backup, nếu không restore sẽ mất |

> Quy tắc cuối cùng là thứ dễ quên nhất và **hỏng âm thầm**: một capability
> thêm bảng mới mà quên `.ttbk` ⇒ người dùng khôi phục và mất đúng phần đó,
> không có thông báo nào.

---

## 4. Thứ tự xây capability

```
NOW    Feedback kênh
NEXT   AI Business Profile → Weekly Review
       AI Business Profile → AI-first Onboarding
       Opportunity tầng 1 (độc lập)
──────── RANH GIỚI: Founder chọn A / B / C ────────
LATER  Connection → Normalization → Reconciliation → Provenance
       → Marketplace Finance → Channel Comparison
FUTURE Managed AI · Sync · Cloud (chỉ hướng B)
PARKED Marketplace Intelligence (quyết định thương mại)
```

**Không có capability nào trong danh sách này bắt đầu bằng công việc UI.**
