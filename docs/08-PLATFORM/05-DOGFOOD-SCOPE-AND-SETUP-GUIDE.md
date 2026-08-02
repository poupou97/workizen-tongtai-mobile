# Dogfood scope + Founder Setup Guide — loại trước, nghiên cứu sau

> **WTM-254 · Phase 10 + 11 của PLATFORM-001.**
> Trạng thái: **Draft — cần Founder review.**
>
> Luật cắt phạm vi của chính Founder: **"Không nghiên cứu nếu không có use
> case."** Tài liệu này áp luật đó **trước**, rồi mới nghiên cứu phần còn lại.

---

## Bước 1 — Loại 14/28 platform, kèm lý do

| Platform | Loại vì | Mở lại khi |
|---|---|---|
| **Amazon · eBay · Etsy** | Workizen không bán ở đó; SME Việt hầu như không | có người bán thật hỏi |
| **Alibaba · AliExpress** | mua hàng, không phải bán — thuộc Producer, mà Producer nay là **Business Input** (ADR-TON-023) và người bán **tự khai** | có nhu cầu mua sỉ xuyên biên giới thật |
| **DHL · FedEx** | vận chuyển quốc tế; SME Việt bán nội địa dùng GHN/GHTK/VNPost | có đơn quốc tế |
| **GHN · GHTK · VNPost** | ⚠️ **có** use case cho SME, nhưng **không** cho Workizen (sản phẩm số, không giao hàng) | Wave Commerce, khi có người bán hàng vật lý dùng thật |
| **Stripe · PayPal** | Workizen thu tiền qua App Store/Play/RevenueCat, không qua Stripe | bán web/subscription trực tiếp |
| **Shopee · TikTok · Shopify · WooCommerce** | Workizen **chưa có cửa hàng** | ⚠️ **điểm cao nhất cho SME** — làm ở Wave Commerce, không phải Wave Dogfood |
| **Facebook · Facebook Ads · Google Ads** | Workizen **chưa chạy quảng cáo** | khi bắt đầu chi tiền quảng cáo |
| **Confluence** | trùng vai trò với Jira ở đây; tài liệu đã nằm trong repo | — |

**Còn lại 9 platform Workizen dùng THẬT hôm nay** — đó mới là dogfood.

---

## Bước 2 — 9 platform còn lại, theo use case có thật

| # | Platform | Use case thật | Mô hình | Ai dùng số này |
|---|---|---|---|---|
| 1 | **GitHub** | nhịp release, thời gian commit → store | Device-direct | Developer Productivity |
| 2 | **App Store Connect** | lượt cài · doanh thu · đánh giá | File Bridge → Hybrid | Commerce · Finance |
| 3 | **Google Play Console** | như trên | File Bridge | Commerce · Finance |
| 4 | **RevenueCat** | subscription · huỷ · hoàn tiền | **Optional Runtime** | Finance |
| 5 | **Firebase (Crashlytics)** | crash tăng đột biến ⇒ có nên dừng phát hành | Device-direct / đã có SDK | Quality |
| 6 | **GA4** | lưu lượng, nguồn vào | Device-direct | Marketing |
| 7 | **Search Console** | từ khoá người dùng tìm tới | Device-direct | Marketing |
| 8 | **Telegram** | kênh chạm người dùng cuối rẻ nhất | Device-direct | Support |
| 9 | **Jira** | nhịp làm việc của AI Workforce | Device-direct (đã có MCP trong phiên) | Developer Productivity |

**Gmail cố ý không có trong bảng** — thay bằng **Share Sheet**, xem
`04-VENDOR-AND-CONNECTOR-CATALOG.md` và WTM-241.

---

## Bước 3 — Founder Setup Guide

Founder yêu cầu mỗi platform có: Account · Pricing · Setup · OAuth · API ·
Webhook · Chi phí · Checklist · **Ảnh minh hoạ**.

> ⚠️ **Nói trước phần tôi KHÔNG làm được:** ảnh minh hoạ cổng quản trị đòi đăng
> nhập tài khoản của anh. Tôi **không chụp được** và **không nên** chụp. Dưới đây
> chừa chỗ và ghi rõ ảnh nào cần anh chụp — mỗi ảnh một dòng, chụp một lần dùng mãi.

### 3.1 App Store Connect

| | |
|---|---|
| **Account** | Apple Developer Program — **$99/năm** (anh đã có, vì app đã lên store) |
| **Setup** | Users and Access → **Keys** → tạo key vai trò **Sales and Reports** (không dùng Admin) |
| **Xác thực** | tải `.p8` — **Apple chỉ cho tải MỘT LẦN**; JWT ES256, token sống ≤20 phút |
| **Webhook** | ❌ không có |
| **Chi phí thêm** | 0 |
| **Checklist** | ☐ tạo key **chỉ** quyền Sales and Reports ☐ cất `.p8` vào trình quản lý mật khẩu ☐ ghi lại Key ID + Issuer ID ☐ **không** commit vào repo nào |
| 📷 **Ảnh cần anh chụp** | màn *Users and Access → Keys* (che Key ID) |

### 3.2 Google Play Console

| | |
|---|---|
| **Account** | Google Play Developer — **$25 một lần** (đã có) |
| **Setup** | Download reports → **Cloud Storage bucket riêng** (CSV theo tháng) |
| **Xác thực** | service account JSON (nếu tự động) — **hoặc tải tay, khuyến nghị cho dogfood** |
| **Chi phí thêm** | 0 (bucket miễn phí ở mức này) |
| ⚠️ **Cảnh báo** | **từ 7/2026 Google đổi cột "Fee Description" và "Program"** — parser khớp chuỗi cứng sẽ vỡ |
| **Checklist** | ☐ lấy đường dẫn bucket ☐ tải thử một file ☐ **chưa** tạo service account cho tới khi cần tự động |
| 📷 | màn *Download reports → Earnings* |

### 3.3 RevenueCat

| | |
|---|---|
| **Pricing** | miễn phí tới **$2.500 MTR/tháng**, sau đó ~1% doanh thu theo dõi |
| **Setup** | Project Settings → API Keys → tạo **secret key** (`sk_`) |
| **Xác thực** | Bearer `sk_` — ⚠️ **tài liệu chính hãng nói rõ: chỉ để trên server** |
| **Webhook** | ✅ có, cần URL HTTPS nhận ⇒ **đây là lý do cần n8n** |
| **Checklist** | ☐ tạo `sk_` **riêng** cho n8n (không dùng lại key khác) ☐ đặt Authorization Header cho webhook ☐ ghi rõ key này **không bao giờ** vào app |
| 📷 | màn *API Keys* (che toàn bộ key) |

### 3.4 GitHub

| | |
|---|---|
| **Pricing** | 0 cho repo cá nhân |
| **Xác thực** | **OAuth device flow** (không cần client secret) hoặc fine-grained PAT |
| **Quyền tối thiểu** | `contents:read` · `metadata:read` — **không** cấp quyền ghi |
| **Checklist** | ☐ PAT fine-grained, **chỉ** repo Tổng Tài ☐ đặt hạn 90 ngày ☐ lưu vào Keystore, không vào `.env` |
| 📷 | không cần |

### 3.5 Telegram

| | |
|---|---|
| **Pricing** | 0 |
| **Setup** | chat với **@BotFather** → `/newbot` → nhận token |
| **Xác thực** | bot token |
| **Webhook** | tuỳ chọn — **`getUpdates` long-polling không cần server** |
| ⚠️ | ai có token là **toàn quyền** bot ⇒ Keystore, không `.env`, không ảnh chụp |
| **Checklist** | ☐ tạo bot ☐ lấy `chat_id` của anh ☐ gửi thử một tin ☐ bật quyền riêng tư nhóm |
| 📷 | hội thoại BotFather (che token) |

### 3.6 GA4 · Search Console · Firebase

| | |
|---|---|
| **Pricing** | 0 (GA4 tiêu chuẩn) |
| **Xác thực** | OAuth2 scope **sensitive** (`analytics.readonly`, `webmasters.readonly`) |
| **Dogfood** | chế độ **Testing**, thêm chính email anh làm test user ⇒ **không cần thẩm định** |
| **Sản phẩm** | cần OAuth verification (thời gian, không phải CASA) |
| **Firebase** | đã kết nối sẵn (`workizen-hub`), Crashlytics đang chạy |
| **Checklist** | ☐ tạo OAuth client kiểu *Desktop/Installed* ☐ để app ở Testing ☐ thêm email anh vào test users |
| 📷 | màn *OAuth consent screen → Test users* |

### 3.7 Jira

Đã kết nối qua MCP trong chính phiên làm việc này. Không cần thiết lập thêm.

---

## Bước 4 — Tổng chi phí dogfood

| Khoản | Tiền |
|---|---|
| Apple Developer | **$99/năm** (đã trả) |
| Google Play | **$25** (đã trả, một lần) |
| RevenueCat | **$0** ở quy mô hiện tại |
| GitHub · Telegram · GA4 · Search Console · Firebase | **$0** |
| n8n self-host trên VM đã có | **$0** thêm |
| Block volume Oracle (nếu gắn) | vài đô/tháng |
| **Tổng phát sinh mới** | **≈ 0 → vài đô/tháng** |

**Đối chiếu để thấy vì sao Gmail bị loại:** riêng CASA cho Gmail là
**$500–$4.500+ mỗi năm** — nhiều hơn *toàn bộ* phần còn lại cộng lại, cho **một**
capability mà Share Sheet giải được miễn phí.
