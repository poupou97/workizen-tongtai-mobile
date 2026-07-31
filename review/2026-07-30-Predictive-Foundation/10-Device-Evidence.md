# 10 — Device Evidence (Galaxy S24 Ultra, bản release)

Ảnh trong `screenshots/`. Mọi lần đo đều trên **APK release** cài bằng
`adb install -r`, `adb logcat -b crash` **rỗng** ở mọi bước.

| # | Ảnh | Chứng minh điều gì |
|---|---|---|
| 02 | `02-more-menu-with-12month-entry.png` | Mục **"Load 12 months of sample data"** có trong More |
| 03 | `03-seed-confirm-dialog.png` | Xác nhận trước khi seed, nói rõ "bản ghi mẫu bình thường, xoá bất cứ lúc nào, dữ liệu của bạn không bị ảnh hưởng" |
| 08 | `08-finance-12-months-seeded.png` | Dữ liệu 12 tháng vào **DB thật**: chi phí nhập hàng 87,8tr · mặt bằng 17,5tr · lương 17,5tr · marketing 12,7tr + doanh thu theo đơn |
| 10 | `10-forecast-headline-and-chart.png` | **Dự báo 7/2026 = 20.769.724 ₫**, dải 4,99–36,54tr, "Confidence: Low", chip **"Rule-based (no AI needed)"**; biểu đồ 12 tháng, tháng rỗng ghi `0 ₫` |
| 11 | `11-forecast-comparison-and-why.png` | So kỳ: 71,32tr → 55,49tr (**−22,2%**), 128 → 106 đơn; **Why** = reason codes đã dịch; "Based on months" đúng 11 tháng (đã cắt tháng rỗng đầu) |
| 12 | `12-customer-risk.png` | **4 khách nguy cơ**; 19 Active · 5 Cooling · 4 At risk · 14 Churned · 18 Win back; từng khách: tên (join từ repository), điểm rủi ro 79/78, "109/264 ngày chưa mua", reason codes, hành động gợi ý |
| 13 | `13-ai-explains-twin-number.png` | **AI (Grok/xAI, key thật) trích đúng con số của twin**: *"Rule Twin dự báo doanh thu tháng 2026-07 là 20.769.724 ₫…"* — không tự chế số |
| 15 | `15-forecast-identical-after-restart.png` | Sau **force-stop + mở lại**: dự báo **giống hệt từng đồng** |
| 20 | `20-home-after-reset-user-data-survives.png` | Sau **Xoá dữ liệu mẫu**: Home về Producer 0 · Inventory 1 · Consumer 1 · Journey 0 · Revenue 0 ₫ — **2 bản ghi của người dùng sống sót** |
| 16 | `16-forecast-after-seed-no-restart.png` | Sau fix invalidation: seed → mở Dự báo **không restart** → số đúng |
| 17 | `17-insufficient-after-remove-no-restart.png` | Sau fix: xoá mẫu → mở lại **không restart** → **"Not enough data to forecast"** + 3 reason code. Trước fix: vẫn hiện nguyên 12 tháng |

## Đo hiệu năng seed (12 tháng, trên máy)

| | Trước | Sau |
|---|---|---|
| Nạp 12 tháng | **~4–5 phút**, UI đơ, OS từng **kill app** giữa chừng (`lmkd` relaunch) | **< 20 giây**, không kill |

Desktop (file SQLite thật, 42 khách/14 SP/529 đơn/544 giao dịch): pha ghi
634–644 ms → **68–69 ms (~9,4×)**. Máy thật hưởng lợi nhiều hơn vì chi phí
fsync mỗi statement trên flash Android đắt hơn NVMe.

## Điều KHÔNG chứng minh được ở đây

- Độ chính xác dự báo so với tương lai thật — dữ liệu là mẫu; cái được chứng
  minh là **tính xác định, tính minh bạch và sự trung thực khi thiếu dữ liệu**.
- iOS: chưa build/ký (ngoài phạm vi).
