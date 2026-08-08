# 21 · Quyết định cần Founder

> Mỗi mục: **hỏi gì · các lựa chọn · khuyến nghị · hệ quả nếu hoãn**.
> Không mục nào tôi tự quyết được — chúng là quyết định sản phẩm hoặc doctrine.

## D-1 · Có đổi `confidence` từ *khai* sang *tính* không? 🔴

**Bối cảnh:** COMP AI không cho phép khai confidence ở bất kỳ đâu. Tổng Tài cho khai ở `IdentityCandidate`.

| Lựa chọn | Được | Mất |
|---|---|---|
| **A · Đổi ngay** *(khuyến nghị)* | rẻ nhất lúc này — 0 connector, 0 migration | một buổi làm |
| B · Đổi khi có connector thứ 2 | chưa mất gì hôm nay | mỗi connector thêm một chỗ khai sai |
| C · Giữ nguyên | không làm gì | luật 1 có ngoại lệ vĩnh viễn |

**Hoãn thì sao:** chi phí tăng tuyến tính theo số connector. Hôm nay là điểm rẻ nhất.

## D-2 · `ProposedChange` — có làm vòng đề xuất không? 🔴

**Bối cảnh:** không có nó, Tổng Tài **không thể** lên L2 · Prepare trong 4 mức tự chủ. Hiện `SuggestLink` chỉ sống trong bộ nhớ.

| Lựa chọn | Được | Mất |
|---|---|---|
| **A · Làm, dùng cho Identity trước** *(khuyến nghị)* | mở đường L2; kiểm chứng trên một miền hẹp | schema v21 |
| B · Làm cho mọi miền cùng lúc | nhất quán ngay | phạm vi lớn, chưa có agent để dùng |
| C · Chưa làm | — | kẹt ở L1 vô thời hạn |

**Kèm câu hỏi con:** mặc định `reconsiderAfter` cho từng miền — tôi đề xuất danh tính = vĩnh viễn, giá/dự báo/tồn kho = 30 ngày. Founder chốt?

## D-3 · `BusinessAction` làm cửa ghi duy nhất — làm TRƯỚC hay SAU agent đầu tiên? 🔴

**Bối cảnh:** COMP AI có đủ mảnh nhưng không hợp nhất; **5 ngày** sau khi thêm bề mặt mới đã sinh đường ghi thứ ba.

| Lựa chọn | Được | Mất |
|---|---|---|
| **A · Trước** *(khuyến nghị)* | mọi tool sinh sau buộc đi qua cửa | chậm agent đầu tiên |
| B · Sau, rồi hồi tố | agent sớm hơn | bằng chứng cho thấy hồi tố **không xảy ra** |

## D-4 · Durable agent trên local-first — chọn hướng nào? 🔴 **Doctrine**

**Đây là quyết định kiến trúc lớn nhất và tôi không tự quyết.**

| | A · Chạy lúc mở app | B · WorkManager | C · Optional Runtime |
|---|---|---|---|
| Backend | không | không | **có** |
| App đóng | không chạy | chạy (Android) | chạy 24/7 |
| iOS | như Android | hạn chế nhiều | như Android |
| Chạm doctrine D-5 | không | không | **có** |
| BYOK key lúc nền | n/a | phải giải | phải giải |

**Khuyến nghị: bắt đầu A**, vì `AgentTask` có giá trị ngay cả khi chỉ chạy lúc mở app, và nó **không khoá** đường lên B/C sau này.

⚠️ Founder đã gỡ doctrine backend ở **cấp connector** (2026-08-02). Agent là **phạm vi khác** — cần quyết riêng.

## D-5 · Hành động nào TUYỆT ĐỐI không auto? 🟠

Tôi đề xuất 7 mục (`13-AUTONOMY-POLICY.md`): chuyển tiền · xoá/gộp khách · nhắn khách chưa từng mua · đổi giá bán · nhập hàng vượt hạn mức · liên hệ người ngoài danh bạ · sửa dữ liệu người bán nhập tay.

**Founder duyệt/sửa danh sách này?** Nó sẽ thành **hằng số + assert trong code**, không phải mặc định cấu hình.

## D-6 · Điều kiện tốt nghiệp của `CanonicalEvent` 🟢

Tôi đề xuất: **≥2 producer HOẶC ≥2 consumer thật**.

Producer #1 sẽ là GitHub connector (đã chạy thật). Producer #2 là Telegram. **Founder xác nhận ngưỡng này?**

## D-7 · Orchestration UX — Automation Card cho MVP? 🟢

Tôi đề xuất hướng **A · Automation Cards** (1 thẻ = 1 `AutonomyRule`), hoãn Business Flow / AI-generated / Templates.

## D-8 · Dogfood bắt đầu từ luồng nào? 🟢

Tôi đề xuất **nhịp giao hàng GitHub** (connector đã có bằng chứng thật: 211 commit · 155 pull · 360 event_id ổn định), rồi **chi phí AI/cloud nhập tay**.

---

## Bảng tóm tắt

| # | Quyết định | Mức | Khuyến nghị |
|---|---|---|---|
| D-1 | confidence tính thay vì khai | 🔴 | **A — đổi ngay** |
| D-2 | ProposedChange | 🔴 | **A — làm, Identity trước** |
| D-3 | BusinessAction trước/sau agent | 🔴 | **A — trước** |
| D-4 | durable agent local-first | 🔴 doctrine | **A — chạy lúc mở app** |
| D-5 | 7 hành động cấm auto | 🟠 | duyệt danh sách |
| D-6 | ngưỡng tốt nghiệp CanonicalEvent | 🟢 | ≥2 producer/consumer |
| D-7 | Automation Card MVP | 🟢 | A |
| D-8 | dogfood bắt đầu | 🟢 | GitHub delivery |

**Không mở implementation story nào trước khi D-1…D-4 có câu trả lời.**
