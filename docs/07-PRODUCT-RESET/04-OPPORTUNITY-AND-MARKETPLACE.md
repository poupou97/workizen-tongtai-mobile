# Opportunity Engine Proposal · AI Marketplace Intelligence Proposal

*(Báo cáo 14–15 trong 24)*

---

# 14. Opportunity Engine

## Hiện trạng — chính xác

`lib/features/tongtai/opportunity/opportunity_rule_engine.dart` sinh cơ hội
**tất định** từ dữ liệu của chính người dùng:

| Loại | Điều kiện | Điểm |
|---|---|---|
| Restock | hàng hết/sắp hết **mà có bán** | 85 / 70 |
| Win-back | khách quen im lặng > 30 ngày | 65 |
| Goal catch-up | mục tiêu chậm so với nhịp | 75 |
| Category momentum | danh mục đang lên | 60 |

Deterministic (`gen-*`), doanh nghiệp rỗng ⇒ 0 cơ hội, và **điểm rule là
authoritative** — AI chỉ giải thích (WTM-141).

## Khoảng cách với Vision

`OPPORTUNITY-ENGINE.md` và `PRODUCT-VISION.md` hứa: **arbitrage · market gap ·
cross-border · trend**. Cả bốn đều cần **dữ liệu ngoài**. Cái đang có là
**"nhắc việc thông minh"**, không phải **"phát hiện cơ hội thị trường"**.

Nói thẳng: hai thứ này khác nhau về bản chất, và người dùng sẽ nhận ra ngay.

## Đề xuất — ba tầng, tăng dần theo dữ liệu sẵn có

**Tầng 1 — Cơ hội nội bộ (đã có, nên hoàn thiện trước)**

Chưa khai thác hết dữ liệu đang có trong máy:

- *Hàng chết vốn* — tồn kho không bán được > 90 ngày ⇒ tiền đang nằm im
- *Khách sắp rời* — RFM đã tính risk nhưng chưa thành cơ hội hành động
- *Sản phẩm hay mua kèm* — giỏ hàng đã có, chưa ai phân tích
- *Mùa vụ lặp lại* — generator đã mô hình hoá mùa vụ; dữ liệu thật cũng có

**Bốn cái này làm được ngay, không cần bất kỳ kết nối nào.** Tôi cho rằng chúng
có giá trị thực tế cao hơn "arbitrage xuyên biên giới" đối với người bán SME.

**Tầng 2 — Cơ hội từ dữ liệu kênh** *(cần hướng B hoặc C)*

- Chênh giá cùng SKU giữa các kênh
- Kênh nào lãi thật cao hơn sau phí
- Đơn bị huỷ/hoàn bất thường theo kênh

**Tầng 3 — Cơ hội thị trường** *(cần nguồn dữ liệu thị trường)*

Arbitrage, market gap, trend. **Cần nguồn dữ liệu mà hiện chúng ta không có và
directive cũng chưa chỉ ra.** Không nên hứa tầng này trên cửa hàng cho tới khi
có nguồn thật.

## Nguyên tắc phải giữ

Dù lên tầng nào: **Rule Twin vẫn tính, AI vẫn chỉ giải thích** (ADR-TON-016).
Một "cơ hội" do AI bịa ra, người bán nhập hàng theo, rồi ôm hàng — đó là thiệt
hại thật. Sản phẩm này đã chọn đúng bên; đừng đổi.

---

# 15. AI Marketplace Intelligence

## Đánh giá thẳng: **chưa làm được, và lý do không phải kỹ thuật**

"Marketplace Intelligence" nghĩa là biết về **thị trường**, không chỉ về **cửa
hàng của người dùng**. Cần ít nhất một trong:

| Nguồn | Tình trạng thực tế |
|---|---|
| API dữ liệu sàn (giá/bán chạy đối thủ) | các sàn **không cung cấp** cho bên thứ ba |
| Crawl | vi phạm điều khoản; rủi ro pháp lý và bị chặn |
| Nhà cung cấp dữ liệu bên thứ ba (Metric.vn, ...) | **có tồn tại**, tốn phí, cần hợp đồng |
| Dữ liệu tổng hợp từ chính người dùng Tổng Tài | cần **nhiều người dùng** + **backend** + **đồng ý chia sẻ** |

Không có nguồn nào miễn phí, tức thời và hợp pháp. **Vì vậy đây là một quyết
định thương mại (mua dữ liệu / xây network effect), không phải một story kỹ
thuật.**

## Đường khả dĩ duy nhất trong 6 tháng

Nếu Founder muốn thứ gì đó gọi được là "marketplace intelligence" mà không mua
dữ liệu:

> **So sánh trong nội bộ chính người bán** — cùng một SKU bán ở Shopee vs TikTok
> vs bán trực tiếp: giá nào, lãi thật nào, tỉ lệ hoàn nào.

Đó **là** intelligence có thật, dựa trên dữ liệu người dùng sở hữu, không cần
mua gì. Nhưng nó **cần dữ liệu đa kênh** ⇒ quay lại đúng quyết định A/B/C.

## Cảnh báo về network effect

Ý tưởng "gộp dữ liệu người dùng Tổng Tài để làm benchmark ngành" rất hấp dẫn và
**trực tiếp phá vỡ** lời hứa riêng tư hiện tại. Nếu đi hướng đó, nó phải là:

- **opt-in tường minh**, mặc định tắt,
- ẩn danh và tổng hợp ở mức không truy ngược được,
- và **viết vào chính sách quyền riêng tư trước khi thu thập dòng đầu tiên**.

Đây là Founder Gate loại "privacy red-line" (G-3). Tôi không đề xuất tự làm.
