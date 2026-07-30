# 01 — Executive Summary

**Capability-Driven Predictive Foundation** · Founder Decision APPROVED 2026-07-30 ·
Epic **WTM-149** (WTM-150…163) · ADR-TON-016 · PR #76

## Câu hỏi khởi nguồn

> *"Tăng dữ liệu demo 12 tháng — hỏi agent có dự đoán được doanh thu, khách rời bỏ không?"*

**Trả lời trung thực lúc đó: không** — và lý do là **kiến trúc**, không phải
thiếu dữ liệu. Toàn bộ "thế giới" AI nhìn thấy là một **snapshot phẳng**: một
con số doanh thu tổng, một con số khách hàng. Seed 12 tháng cũng **không đổi
hình dạng prompt** — chỉ làm con số tổng to hơn. Không có chuỗi thời gian thì
không thể ngoại suy; không có "ngày mua gần nhất từng khách" thì không thể nói
ai sắp rời.

## Đã xây gì

Toàn bộ chuỗi, không chia phase:

```
Historical Data → Analytics → Capability Context → Rule Twin → AI Explanation → UI → Tests → Governance
```

| Tầng | Nội dung | Test |
|---|---|---|
| **Generator** (WTM-150) | tham số hoá + deterministic: months 3/12/24/36/60 · seed · business profile · mùa vụ Tết/hè/cuối năm · growth/decline · 6 nhóm hành vi khách; seed vào **production repository** prefix `sample-` | 27 |
| **Analytics** (WTM-152) | tính toán thuần: month bucketing (tháng lịch **địa phương**, có ghi rõ) · revenue series · RFM · cashflow; gom `isBillableOrder` từng bị chép tay 6 chỗ | 52 |
| **Capability** (WTM-153/154) | Revenue + Customer Context, tải on-demand, `promptBlock()` không PII → **BusinessContext không phình God Object** | 35 |
| **Rule Twin** (WTM-155/156/157) | `revenue-forecast/1` · `customer-risk/1` · `business-alerts/1` — authoritative, chạy không cần AI/mạng/key | 130 |
| **AI** (WTM-158/159) | chỉ giải thích, đọc Capability Context + Rule Twin output; Tool Runtime thiết kế sẵn nhưng **chứng minh chưa nối** | 19 |
| **UI** (WTM-160/161) | Dự báo doanh thu + Rủi ro khách hàng; stable keys; trạng thái thiếu dữ liệu **từ chối** thay vì render số 0 | 10 |
| **Edge + Privacy** (WTM-162/163) | file SQLite thật: biên tháng · timezone · restart · reset · user data cùng tồn tại · mọi ngưỡng sufficiency; privacy có **negative control** | 33 |

**996 → 1303 tests** (+307). `flutter analyze` sạch. CI xanh.

## Ba bug thật phát hiện & sửa

1. **Reset dữ liệu mẫu crash `FOREIGN KEY 787`** khi người dùng đã ghi đơn của
   *chính họ* cho một khách mẫu — hành vi hợp lệ theo ADR-TON-014. Nay giữ lại
   khách bị "ghim": **dữ liệu người dùng thắng**, sweep không bao giờ ném lỗi.
2. **Định nghĩa "billable"** bị chép tay ở 6 chỗ → gom về một nguồn.
3. **Màn predictive hiển thị dữ liệu cũ** sau khi seed/xoá mẫu (FutureProvider
   cache không invalidate) — phát hiện **trên máy thật**, không test nào bắt được.

## Bằng chứng trên thiết bị thật (Galaxy S24 Ultra)

- Nạp 12 tháng → **Dự báo 7/2026 = 20.769.724 ₫**, dải 4.99–36.54tr, độ tin cậy
  Thấp, chip "Rule-based (no AI needed)"; biểu đồ 12 tháng hiện rõ **mùa vụ Tết**
  (12/2025: 30,48tr · 2/2026: 31,14tr) và tháng rỗng ghi `0 ₫` trung thực.
- **Rủi ro khách hàng**: 19 Active · 5 Cooling · 4 At risk · 14 Churned · 18
  Win-back; từng khách có điểm rủi ro, số ngày im lặng, reason codes, hành động
  gợi ý — tên lấy từ repository, **twin chỉ mang id**.
- **AI giải thích bằng key thật (Grok/xAI)** và **trích đúng con số của twin**
  (20.769.724 ₫) — không tự chế số khác.
- **Restart**: dự báo giống hệt từng đồng.
- **Reset mẫu**: Home về 0/1/1/0 — **2 bản ghi của người dùng sống sót**.

Ảnh trong `screenshots/`.

## Giới hạn công bố thẳng

- Độ tin cậy dự báo trên dữ liệu mẫu là **Thấp** (biến động cao) — đúng thiết
  kế: rule không tô hồng.
- Seeding 12 tháng ban đầu mất ~4–5 phút và app từng bị OS kill giữa chừng →
  đã chuyển sang ghi theo lô (xem `07-Changed-Files`).
- Tool Runtime (AI hành động) **chưa bật** — cần quyết định riêng của Founder.
