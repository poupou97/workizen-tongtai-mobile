# Information Architecture vNext — đề xuất

> **Trạng thái: PROPOSAL.** Không được implement trước khi Founder duyệt.
> Directive nói rõ: **UI đứng sau Business Capability**. Tài liệu này mô tả
> **chỗ đứng của capability trong sản phẩm**, không phải thiết kế màn hình.

---

## 1. IA hiện tại (đã xác minh trong code)

`lib/features/tongtai/ui/tongtai_app_shell.dart` — 5 tab:

```
[ Trang chủ ] [ Nguồn hàng ] [ Kho ] [ Khách hàng ] [ Thêm ]
```

Bên trong tab **Thêm** (`tongtai_more_screen.dart`) là một danh sách cài đặt,
và nó đang chứa:

```
Dòng thời gian · Tài chính · Báo cáo · Dự báo · Rủi ro khách hàng ·
Mục tiêu kinh doanh · Xuất dữ liệu · Sao lưu
```

### Ba vấn đề

| # | Vấn đề | Bằng chứng |
|---|---|---|
| 1 | **Tab "Thêm" là kho chứa capability, không phải cài đặt** | 4/8 capability (Finance · Reports · Business Journey · một phần Opportunity) sống trong một danh sách cài đặt |
| 2 | **Opportunity Hub không có chỗ nào trong điều hướng chính** | Đây là capability *"nói cho người dùng biết nên làm gì tiếp"* — thứ đáng ra là lý do mở app |
| 3 | **AI Copilot chỉ là một icon ở góc** | Nếu định vị là AI-First thì đây là mâu thuẫn IA rõ nhất |

**Ba vấn đề này là hệ quả của một nguyên nhân:** thanh tab được xếp theo
**đối tượng dữ liệu** (nguồn hàng / kho / khách), không theo **việc người dùng
đang làm**.

---

## 2. Nguyên tắc IA vNext

1. **Điều hướng chính phản ánh việc người dùng làm, không phản ánh bảng dữ liệu.**
2. **Mỗi capability phải có đúng một chỗ ở, không nằm trong "Thêm".**
3. **"Thêm" chỉ chứa cài đặt, dữ liệu, pháp lý — không chứa capability.**
4. **Vị trí trong điều hướng phải tương xứng mức độ dùng hằng ngày**, không
   tương xứng công sức xây.

---

## 3. IA vNext — đề xuất

```
[ Hôm nay ] [ Bán hàng ] [ Hàng hoá ] [ Tiền ] [ Thêm ]
                                              + AI luôn trong tầm với
```

| Tab | Chứa | Trả lời câu hỏi |
|---|---|---|
| **Hôm nay** | sức khoẻ kinh doanh · **việc nên làm** (Opportunity tầng 1) · nhật ký tuần · Business Journey | *"Hôm nay tôi nên làm gì?"* |
| **Bán hàng** | đơn hàng · khách hàng · rủi ro rời bỏ · phân khúc RFM | *"Ai đang mua, ai sắp bỏ tôi?"* |
| **Hàng hoá** | tồn kho · nhà cung cấp/nguồn hàng · dự báo nhập · hàng chôn vốn | *"Nhập gì tiếp theo?"* |
| **Tiền** | thu chi · lãi lỗ · báo cáo · *(sau này: lãi thật sau phí sàn)* | *"Tôi lãi bao nhiêu?"* |
| **Thêm** | cài đặt · AI · dữ liệu mẫu · sao lưu · xuất · pháp lý · *(sau này: Kết nối)* | — |

### Thay đổi so với hiện tại

| Thay đổi | Vì sao |
|---|---|
| **Opportunity Hub lên "Hôm nay"** | capability quan trọng nhất về giữ chân người dùng, hôm nay không có chỗ |
| **Finance + Reports lên tab "Tiền"** | rời khỏi danh sách cài đặt; đây là câu hỏi số 1 của người bán |
| **Producer gộp vào "Hàng hoá"** | *nguồn hàng* và *tồn kho* là hai nửa của cùng một quyết định nhập hàng |
| **Consumer đổi tên thành "Bán hàng"** | người bán không nghĩ theo từ "khách hàng" — họ nghĩ theo *đơn* |
| **"Thêm" chỉ còn cài đặt** | ✅ đúng vai trò |

> **Chi phí:** đây là thay đổi điều hướng chạm mọi màn, mọi test tìm bằng Key,
> và toàn bộ deeplink. **Không nên làm trước closed beta** — làm sau khi có
> phản hồi thật, để đổi một lần thay vì hai.

---

## 4. Chỗ của Connection Center trong IA

**Chỉ khi Founder chọn hướng B hoặc C.**

| Không nên | Nên |
|---|---|
| ❌ tab riêng ở điều hướng chính | ✅ **mục "Kết nối" trong tab Thêm** |

Lý do: người bán **thiết lập kết nối vài lần một năm**, nhưng **xem tiền và
hàng mỗi ngày**. Vị trí trong điều hướng phải theo tần suất dùng.

Còn **kết quả** của kết nối thì hiện ở nơi nó có ý nghĩa: dữ liệu sàn xuất hiện
trong *Tiền* (lãi thật sau phí) và *Bán hàng* (đơn đa kênh), kèm **dấu nguồn
gốc** (Provenance) để người dùng luôn biết số nào do mình nhập, số nào từ đâu về.

---

## 5. Chỗ của AI trong IA

Phụ thuộc quyết định định vị (Khuyến nghị 5, báo cáo 24):

| Nếu giữ **AI-assisted** | Nếu làm thật **AI-first** |
|---|---|
| AI là **lớp giải thích** gắn vào từng màn: mỗi con số có thể hỏi *"vì sao?"* | AI là **cửa vào**: hội thoại là màn đầu, các tab là nơi xác nhận |
| Icon góc như hiện tại là **hợp lý** | Icon góc là **mâu thuẫn với nhãn sản phẩm** |

**Không được chọn cả hai.** Đây là quyết định Founder, và IA phải theo sau nó —
không phải ngược lại.
