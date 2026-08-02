# Vendor Catalog + Connector Catalog — theo CAPABILITY, không theo platform

> **WTM-252 (Phase 6+7) · WTM-253 (Phase 8+9) của PLATFORM-001.**
> Trạng thái: **Draft — cần Founder review · cần GPT phản biện phần chấm điểm.**

Founder: *"Nghiên cứu theo Capability. Không theo Platform. Sau đó mới chọn
Platform đại diện."*

---

## Vì sao thứ tự đó quan trọng — một ví dụ thật từ hôm nay

Nếu bắt đầu từ platform, danh sách sẽ mở đầu bằng Gmail và Facebook: ai cũng
dùng, ai cũng biết. Bắt đầu từ **capability** thì câu hỏi đổi thành *"năng lực
Support cần gì?"* — và câu trả lời hoá ra là **"biến một email thành một việc
có thể theo dõi"**, thứ làm được bằng **Share Sheet** trong khi Gmail API đòi
**kiểm định CASA vài nghìn đô mỗi năm** (đã tra ở WTM-241).

Cùng một nhu cầu, hai con đường, chênh nhau vài nghìn đô một năm — và chỉ nhìn
thấy nếu xuất phát từ capability.

---

## 8 capability → nhu cầu thật → platform đại diện

| Capability | Nhu cầu thật của SME | Platform đại diện | Ưu tiên |
|---|---|---|---|
| **Commerce** | đơn hàng · phí · payout · tồn kho theo kênh | WooCommerce · Shopify · Shopee · TikTok Shop | **P0** |
| **Finance** | doanh thu định kỳ · hoàn tiền · đối soát | RevenueCat · Stripe · PayPal | **P0** |
| **Customer** | một khách nhiều kênh · lịch sử mua | (suy từ Commerce) + Facebook Page | P1 |
| **Support** | email/tin nhắn → **một việc theo dõi được** | **Share Sheet** (không phải Gmail API) · Telegram | P1 |
| **Marketing** | chi phí quảng cáo vs đơn ra | Facebook Ads · Google Ads · GA4 · Search Console | P2 |
| **Operations** | vận đơn · trạng thái giao | GHN · GHTK · VNPost | P2 |
| **Developer** | release · crash · nhịp phát hành | GitHub · Firebase Crashlytics · App Store · Play | P1 (dogfood) |
| **Infrastructure** | chi phí hạ tầng/AI/công cụ | **đã có** `BusinessInput` (ADR-TON-023) | ✅ xong |

Điểm đáng chú ý: **Infrastructure đã xong** — không cần connector nào, vì
WTM-229/234 đã cho người bán tự khai nguồn đầu vào. Một capability không cần
tích hợp vẫn là một capability hoàn chỉnh.

---

## Vendor Catalog — hình dạng dữ liệu (Phase 7)

Founder liệt kê 18 trường. Đề nghị thêm **2 trường bắt buộc** mà danh sách gốc
thiếu, và thiếu chúng thì catalog sẽ mục lặng lẽ:

```yaml
vendor:
  category: commerce | finance | marketing | support | operations | developer
  name: "Shopee"
  logo: assets/vendors/shopee.svg
  pricing: "miễn phí cho người bán; phí sàn theo đơn"
  auth: [oauth2]
  webhook: true
  api: partner-api
  mcp: none
  app_to_app: android-intent
  http_api: true
  sdk: [php, java]
  file_import: true            # xuất đơn ra .xlsx
  region: [VN, SEA]
  popularity: high-vn
  documentation: "https://open.shopee.com/"
  alternative: [lazada, tiktok-shop]
  recommended: partner-api + file-bridge
  business_value: "đơn + phí + payout — mở khoá lãi-trên-một-đơn"
  # ── hai trường tôi đề nghị thêm ──
  last_verified: 2026-08-02      # ⭐ không có ⇒ catalog mục mà không ai biết
  verified_by: "tài liệu công khai" | "đã thử thật"   # ⭐ hai mức tin cậy rất khác nhau
```

**Vì sao `last_verified` không phải là chi tiết vụn:** ngày 7/2026 Google đổi cột
báo cáo earnings của Play (đã ghi ở WTM-241). Một catalog không ghi ngày kiểm sẽ
được đọc như sự thật hiện tại trong khi nó là ảnh chụp của quá khứ — đúng họ lỗi
"tài liệu mô tả thứ không tồn tại" mà Phase 0 vừa bắt được với n8n.

---

## Connector Catalog — hình dạng dữ liệu (Phase 8)

```yaml
connector:
  capability: commerce
  connector: shopee-orders
  authentication: oauth2
  oauth: true
  webhook: true
  polling: true              # dự phòng khi webhook chết
  manual_import: true        # .xlsx từ Seller Centre
  app_to_app: false
  backend_required: true     # ← OAuth callback + token refresh
  canonical_objects: [Order, OrderItem, Fee, Refund, Payout, CustomerIdentity]
  priority: P0
  status: researched | spiked | built | live | deprecated
  owner: platform
  last_verified: 2026-08-02
```

**Trường quyết định nhất là `backend_required`** — nó là thứ phân biệt connector
làm được ngay (device-direct) với connector phải chờ Optional Integration
Runtime. Kết quả từ WTM-241: **9/10 nền tảng dogfood KHÔNG cần backend.**

---

## Đánh giá platform (Phase 9) — bảng gộp, thêm cột n8n

Cột **n8n Support** là thứ Wave trước chưa có; nó đổi thứ tự ưu tiên.

| Platform | API | Webhook | OAuth | File Import | **n8n node** | Backend cần? | Kiến trúc khuyến nghị |
|---|:--:|:--:|:--:|:--:|:--:|:--:|---|
| **WooCommerce** | ✅ REST | ✅ | key/secret | ✅ CSV | ✅ **có sẵn** | ❌ | Device-direct (chủ tự cấp khoá) |
| **Shopify** | ✅ Admin | ✅ | custom app token | ✅ CSV | ✅ **có sẵn** | ❌ custom app · ✅ public app | Device-direct |
| **Shopee** | partner | ✅ | OAuth2 | ✅ xlsx | ⚠️ community | ✅ | File Bridge trước → Runtime sau |
| **TikTok Shop** | partner | ✅ | OAuth2 | ✅ | ⚠️ community | ✅ | như Shopee |
| **RevenueCat** | ✅ v2 | ✅ | secret key | ❌ | ⚠️ HTTP node | ✅ | **Optional Runtime** |
| **Stripe** | ✅ | ✅ | secret key | ✅ CSV | ✅ **có sẵn** | ✅ (webhook) | Runtime cho webhook |
| **GitHub** ⭐ | ✅ | ✅ | **PAT chỉ-đọc** | ❌ | ⚠️ dùng HTTP node | ❌ | Device-direct — **ĐÃ KIỂM** |
| **Telegram** | ✅ bot | tuỳ chọn | bot token | ❌ | ✅ **có sẵn** | ❌ (long-poll) | Device-direct |
| **GA4 / Search Console** | ✅ | ❌ | OAuth2 | ✅ | ✅ **có sẵn** | ❌ | Device-direct |
| **Facebook Ads** | ✅ | ✅ | OAuth2 | ✅ | ✅ **có sẵn** | ✅ | Runtime |
| **App Store Connect** | ✅ | ❌ | JWT ES256 | ✅ TSV | ⚠️ HTTP node | ❌ | Hybrid: File Bridge |
| **Google Play** | ✅ | ❌ | service acct | ✅ CSV (GCS) | ⚠️ HTTP node | ❌ | Hybrid: File Bridge |
| **GHN / GHTK** | ✅ | ✅ | API key | ⚠️ | ❌ | ⚠️ | chưa đánh giá — chờ use case |
| **Gmail** | ✅ | ✅ Pub/Sub | OAuth **restricted** | ⚠️ | ✅ có sẵn | ✅ | **từ chối** → Share Sheet |

### ⭐ GitHub — dòng duy nhất trong bảng này đã đi qua thực tế (WTM-268)

Bảng trên vốn dựng từ tài liệu vendor. Sau khi connector GitHub chạy thật, **hai
ô phải sửa** — và cả hai đều lệch theo hướng "tài liệu lạc quan hơn thực tế":

| Ô | Ghi ban đầu | Thực tế | Vì sao lệch |
|---|---|---|---|
| Xác thực | `device flow` | **fine-grained PAT chỉ-đọc** | device flow dành cho app thay mặt *nhiều* người dùng. Ở đây chỉ một chủ sở hữu tự cấp khoá cho chính mình ⇒ PAT phạm vi hẹp hơn **và** đơn giản hơn |
| n8n node | `✅ có sẵn` | **không dùng** — HTTP Request + Header Auth | node GitHub có sẵn nhưng không phân trang được theo cách cần; 208 commit nằm trên 3 trang, node HTTP có cơ chế phân trang tự động |

⇒ Bài học cho mọi dòng còn lại: **"n8n có node sẵn" không đồng nghĩa "dùng node đó
là đúng".** Node có sẵn tối ưu cho thao tác đơn lẻ; connector cần *quét theo cửa
sổ thời gian, có phân trang, biết mình có bị cắt hay không*.

Một cột nữa hoá ra đúng và quan trọng: **Webhook ❌ ⇒ phải poll ⇒
`freshness.mode = poll`** trong canonical envelope. Đó là lý do trường `freshness`
có mặt từ đầu — AI đọc lẫn dữ liệu poll cũ với dữ liệu webhook tức thời mà không
biết thì sẽ nói sai một cách tự tin.

**Điều bảng này nói mà bảng Wave trước không nói:** n8n có node sẵn cho phần lớn
platform phương Tây, nhưng **Shopee/TikTok Shop chỉ có node cộng đồng** — tức
đúng hai sàn quan trọng nhất với SME Việt Nam lại là chỗ n8n giúp ít nhất. Đó là
lý do thực tế để **File Bridge đi trước** ở thị trường Việt, không phải vì
File Bridge "an toàn hơn" một cách trừu tượng.

---

## Kết luận cho Vendor/Connector Catalog

1. **Catalog là dữ liệu, không phải văn bản.** Đề nghị lưu YAML trong repo
   Platform để sau này sinh được UI, và diff được khi vendor đổi điều kiện.
2. **Hai trường `last_verified` + `verified_by` là bắt buộc.** Không có chúng,
   catalog trở thành thứ mà Phase 0 vừa bắt gặp: một sơ đồ vẽ n8n trong khi
   không có n8n nào.
3. **Không điền catalog cho platform chưa có use case** — luật của chính Founder
   ở Phase 10, áp luôn cho Phase 7.
