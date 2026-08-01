# Migration Strategy · Risk Analysis

*(Báo cáo 22–23 trong 24)*

---

# 22. Migration Strategy

## Không có migration source code trong vòng này

Directive cấm migration code, và **cũng không cần**: sản phẩm hiện tại không
phải thứ phải bỏ đi. 6/8 capability ở L4, 1419 test xanh, kiến trúc có seam
chịu lực. Migration ở đây là **migration của tài liệu và của quyết định**, không
phải của code.

## Migration tài liệu

| Việc | Từ → Đến | Vì sao |
|---|---|---|
| `INTEGRATION-MAP.md` | `02-ARCHITECTURE/` → `research/` **hoặc** viết lại | Nó mô tả một kiến trúc chưa duyệt và **mâu thuẫn `PRODUCT-SCOPE.md`**. Để nguyên ở thư mục Architecture là nói với người đọc mới rằng đó là kiến trúc đã chốt |
| `PRODUCT-VISION.md` | thêm mục **"Phase nào cho capability nào"** | Vision hứa arbitrage/omnichannel; Scope hoãn. Không phải sửa Vision — mà **ghi rõ lát cắt nào thuộc phase nào** |
| `ROADMAP.md` | ✅ đã sửa hôm nay | thêm bảng đối chiếu thực tế |
| `docs/07-PRODUCT-RESET/` | **mới** | các báo cáo này |

## Migration nếu chọn hướng C (File Bridge)

Không có migration dữ liệu. Domain Model **mở rộng thêm**, không sửa:

```
+ Connection      (nguồn: tên, loại, lần nhập cuối)
+ ImportBatch     (mẻ nhập: file nào, lúc nào, bao nhiêu dòng)
+ Provenance      (mỗi bản ghi: do người dùng nhập tay hay từ mẻ nào)
```

Ba bảng **thêm mới**, không đụng 17 bảng đang có ⇒ migration cộng thêm, không
phá vỡ, đúng nguyên tắc ADR-TON-009.

`.ttbk` v2 đã **chừa sẵn chỗ** cho việc này (WTM-165: `packageKind`, `datasets`,
`redaction`) — đó chính là lý do vòng đó được làm.

## Migration nếu chọn hướng B (Platform)

Đây **không phải migration, mà là xây mới**:

| Việc | Quy mô |
|---|---|
| ADR huỷ D-4 và D-5 | quyết định Founder |
| Backend (auth, token vault, webhook, queue) | dự án riêng |
| Tài khoản + đăng nhập trong app | ảnh hưởng mọi màn |
| Đồng bộ + giải quyết xung đột | bài toán khó nhất |
| **Cập nhật chính sách riêng tư TRƯỚC khi thu dữ liệu** | bắt buộc pháp lý |
| Migration dữ liệu người dùng hiện có lên cloud | cần đồng ý tường minh |

**Điểm quan trọng:** nếu app đã phát hành theo hướng A/C rồi mới chuyển sang B,
thì đây là một **thay đổi bản chất sản phẩm sau khi người dùng đã cài**. Phải có
đồng ý mới, không được coi là cập nhật thường.

→ **Kết luận migration:** nếu định đi B, tốt nhất là quyết **trước khi phát
hành**, không phải sau.

---

# 23. Risk Analysis

## Rủi ro cao

| # | Rủi ro | Hệ quả | Giảm thiểu |
|---|---|---|---|
| R1 | **Xây Connection Center trước khi có người dùng thật** | 6–12 tháng cho thứ chưa ai xác nhận cần | Hướng C trước; hoặc phát hành A rồi mới quyết |
| R2 | **Lời hứa riêng tư thành sai sau khi phát hành** | mất niềm tin, rủi ro pháp lý | Chốt A/B/C **trước** khi lên store |
| R3 | **Nhãn "AI-First" hứa quá lời** | đánh giá 1 sao: "cài xong không thấy AI đâu" | Đổi định vị, hoặc làm AI dùng được không cần khoá |
| R4 | **Phụ thuộc phê duyệt của sàn** | roadmap bị bên ngoài quyết định | Ưu tiên GHN (token đơn giản) trước Shopee (OAuth) |
| R5 | **Dữ liệu khách hàng cuối từ sàn** | nghĩa vụ theo Nghị định 13/2023 | **Ý kiến pháp lý trước khi kéo dòng đầu tiên** |

## Rủi ro trung bình

| # | Rủi ro | Giảm thiểu |
|---|---|---|
| R6 | **Hydration ở 24/60 tháng chưa đo trên máy** — 12 tháng đã là 405ms | Epic WTM-167; đo trước khi hứa |
| R7 | **iOS chưa từng build** — có thể lộ vấn đề native muộn | Đưa vào NOW |
| R8 | **Không có kênh phản hồi** khi phát hành | Đưa vào NOW |
| R9 | **Backlog lại phình theo kiến trúc chưa chốt** | Chính là lý do E8/E9 chưa được tạo |
| R10 | **Một người viết toàn bộ doctrine** (agent) | Founder gate đang hoạt động đúng — directive này là ví dụ |

## Rủi ro thấp nhưng đáng ghi

| # | Rủi ro |
|---|---|
| R11 | 35 nhánh remote cũ chưa dọn |
| R12 | `component_showcase` dev-only còn trong repo |
| R13 | Telemetry chỉ 2 sự kiện ⇒ gần như không biết gì về hành vi người dùng thật |

## Rủi ro **không** tồn tại (để anh yên tâm)

- ❌ *"Sản phẩm đã drift khỏi vision"* — không. 5/8 capability khớp trọn, 3/8
  khớp một phần và đều thiếu **cùng một thứ**: dữ liệu ngoài.
- ❌ *"Kiến trúc mục nát cần reset"* — không. Các seam đã bắt được lỗi thật
  nhiều lần trong tuần qua.
- ❌ *"Backlog hỗn loạn"* — đã dọn sáng nay, 62 → 10, có bằng chứng từng dòng.
