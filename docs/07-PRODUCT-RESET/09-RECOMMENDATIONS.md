# Founder Recommendations

*(Báo cáo 24 trong 24)*

---

## Khuyến nghị 1 — Đừng reset sản phẩm. Hãy quyết định phạm vi.

Directive gọi việc này là *Product Reset*. Sau khi đọc hết, tôi không thấy thứ
cần reset.

Cái cần là **một quyết định**: Tổng Tài là **công cụ cục bộ cho người bán** hay
**nền tảng kết nối đa sàn**? Hôm nay tài liệu của chính chúng ta nói cả hai —
Vision hứa cái sau, Scope xây cái trước. Mọi thứ khác trong 24 báo cáo này đều
là hệ quả của câu trả lời đó.

**Reset sản phẩm mà không trả lời câu này sẽ chỉ viết lại tài liệu, rồi gặp lại
đúng mâu thuẫn ở vòng sau.**

## Khuyến nghị 2 — Phát hành trước khi mở rộng

Sản phẩm cách cửa hàng **hai hạng mục nội dung** (địa chỉ liên hệ, điều khoản)
và **một chữ ký iOS**. Không có hạng mục nào là code.

Trong khi đó, mọi ưu tiên trong directive — sàn nào trước, AI làm gì, cơ hội
loại nào — đều đang được quyết bằng **phỏng đoán**, vì chưa có một người bán
thật nào dùng sản phẩm.

**Hai mươi người dùng thật trong hai tuần sẽ trả lời nhiều câu hơn hai mươi bốn
báo cáo này.** Kể cả báo cáo do tôi viết.

## Khuyến nghị 3 — Nếu mở kết nối, mở bằng file trước, không phải OAuth

Người bán **đã có** file xuất từ Shopee, TikTok, GHN. Đọc được file đó cho họ
ngay giá trị lớn nhất — *"dữ liệu đa kênh về một chỗ"* — mà không cần backend,
không cần đối tác duyệt, không phá lời hứa riêng tư vừa in vào app hôm qua.

Nếu người dùng thật sự nhập file mỗi tuần, hướng B trở thành quyết định **có
bằng chứng**. Nếu họ không nhập, ta vừa tiết kiệm 6–12 tháng.

## Khuyến nghị 4 — Kết nối API đầu tiên nên là GHN, không phải Shopee

GHN/GHTK dùng **API token đơn giản** — người bán tự dán, y hệt mô hình BYOK đang
dùng cho AI. **Không cần backend, không phá D-4/D-5, không chờ ai duyệt.**

Shopee cần OAuth ⇒ cần backend ⇒ kéo theo toàn bộ hướng B.

Bắt đầu bằng thứ rủi ro thấp nhất mà người bán chạm hằng ngày (vận đơn, phí
ship, COD) sẽ dạy ta cách xây Connection Center **trước khi** đặt cược lớn.

## Khuyến nghị 5 — Sửa định vị AI hoặc sửa sản phẩm AI, đừng để lệch

Sản phẩm hôm nay là **AI-assisted**: bỏ AI đi vẫn dùng được gần như nguyên vẹn.
Đó là hệ quả **đúng** của BYOK + Rule Twin authoritative — nhưng nó không khớp
nhãn *"AI-First Business OS"*, và phần lớn người dùng Việt sẽ không tạo khoá API.

Chọn một:
- đổi định vị cho đúng sản phẩm, **hoặc**
- làm AI dùng được không cần khoá (⇒ Managed AI ⇒ backend ⇒ cùng quyết định với B).

Để nguyên như hiện tại là hứa nhiều hơn làm, và cửa hàng ứng dụng là nơi tệ nhất
để phát hiện điều đó.

## Khuyến nghị 6 — Ba capability directive nhắc tới nên bị hạ ưu tiên

| | Vì sao |
|---|---|
| **Marketing** | không đo được hiệu quả khi chưa có kênh bán kết nối |
| **Marketplace Intelligence** | cần **mua dữ liệu** hoặc **network effect** — quyết định thương mại, không phải story kỹ thuật |
| **Alibaba/1688/Taobao/JD/Temu** | điều kiện API của họ nằm ngoài tầm kiểm soát; không khả thi trong 6 tháng |

Giữ chúng trong tầm nhìn dài hạn thì được. Đặt vào P0 thì sẽ tạo ra backlog
không ai làm được — đúng loại rác vừa dọn sáng nay.

## Khuyến nghị 7 — Giữ nguyên bốn thứ, đừng đụng vào

1. **Rule Twin authoritative, AI chỉ giải thích.** Đây là thứ tốt nhất trong
   kiến trúc này. Rất nhiều sản phẩm để AI bịa số; sản phẩm này thì không thể,
   vì cấu trúc không cho.
2. **Local-first như một lời hứa có thể kiểm chứng** — cho tới khi Founder chủ
   động đổi.
3. **Các seam** (One Data Path · Capability Context · Error seam · Snapshot
   Package). Chúng đã bắt lỗi thật nhiều lần chỉ trong tuần này.
4. **Kỷ luật đo trước khi tối ưu.** Tuần này nó đã ngăn một refactor kiến trúc
   chỉ để lấy về 5ms, và ngăn một "tối ưu" song song hoá không nhanh hơn.

---

## Điều tôi cần từ anh để đi tiếp

| # | Quyết định | Chặn cái gì |
|---|---|---|
| 1 | **Địa chỉ liên hệ** + **Điều khoản dịch vụ** | E1 — chặn phát hành |
| 2 | **Hướng A / B / C** | toàn bộ P2 và P3; E8, E9 |
| 3 | **Định vị AI**: đổi nhãn hay làm Managed AI | thông điệp cửa hàng |
| 4 | **Thứ tự roadmap**: theo đề xuất của tôi hay theo directive | thứ tự backlog |

Tôi **đã tạo E1–E7 trên Jira** vì chúng đúng dù anh chọn A, B hay C.
**E8–E9 tôi giữ ở dạng proposal** cho tới khi có câu trả lời cho #2.
