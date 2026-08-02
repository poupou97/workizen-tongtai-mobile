# Dogfood Journey — vận hành Workizen bằng dịch vụ thật

> **WTM-245 · Wave 1 của Epic WTM-238.** Founder: *"Tôi là khách hàng đầu tiên
> của Tổng Tài. Hãy thiết kế toàn bộ hành trình vận hành doanh nghiệp của
> Workizen bằng các dịch vụ thật."*
>
> Mục tiêu **không phải** liệt kê connector, mà đi trọn **một vòng vận hành**:
> mỗi mắt xích — dữ liệu nào vào, ai là chủ con số, Rule Twin tính được gì, AI
> giải thích gì, Founder **thấy** gì.

---

## Vòng Founder vẽ, điền đầy đủ

| # | Mắt xích | Nguồn thật | Vào Tổng Tài thành gì | Ai là chủ con số | Mức tự động |
|---|---|---|---|---|---|
| 1 | **Release** | GitHub release/tag | `BusinessSignal(kind: release)` + `Evidence` cho bước hành trình | GitHub | **Automatic** (đọc) |
| 2 | **Store** | App Store Connect · Play Console | `Product`(digital) · lượt cài · phiên bản đang phát hành | Store | **Automatic** (đọc, File Bridge) |
| 3 | **Doanh thu** | RevenueCat | `Subscription` → `Order` + `Payment` + `Refund` | RevenueCat | **Automatic** (đọc qua Runtime) |
| 4 | **Analytics** | GA4 + Search Console | `BusinessSignal(kind: traffic/keyword)` | Google | **Automatic** (đọc) |
| 5 | **Crash** | Firebase Crashlytics | `BusinessSignal(kind: quality)` — *"crash tăng đột biến"* | Crashlytics | **AI Suggestion** → dừng phát hành? |
| 6 | **Support email** | Gmail → **Share Sheet** | `JourneyNode(task)` + `Evidence` | **Người bán** (họ chọn chia sẻ email nào) | **Manual → Confirm** |
| 7 | **Journey** | Rule Twin trong máy | bước có `derivedMetric` + `derivedTarget` | **Rule Twin** | **Automatic** (đo) |
| 8 | **Opportunity** | Rule Engine trong máy | `Opportunity` kèm `provenance` | **Rule Twin** | **AI Suggestion** |
| 9 | **AI Weekly Review** | Rule Twin tính → AI diễn giải | màn Review + local notification | **Rule Twin** (số) · AI (lời) | **Automatic** (sinh) → **Manual** (đọc) |
| 10 | **Founder** | — | quyết định | Founder | — |

**Điều đáng chú ý nhất của bảng này:** ở **tám trong mười** mắt xích, chủ sở hữu
con số **không phải AI**. AI chỉ xuất hiện ở hai chỗ, và cả hai đều là *giải
thích*, không phải *quyết định* — đúng ADR-TON-016.

---

## Vòng thứ hai Founder nêu: quảng cáo (Wave 3, chưa làm, nhưng đã có hình dạng)

```
Facebook Ads: CPA tăng
        ↓  (connector đọc — L0)
BusinessSignal(kind: ad_cost_spike, confidence, freshness)
        ↓  (Rule Twin so với ngưỡng người bán đặt)
Opportunity("CPA tăng 40% trong 7 ngày, chưa ra đơn tương ứng")
        ↓  (AI giải thích — L1, KHÔNG được tự quyết)
Founder duyệt  ←──────── đây là cổng bắt buộc
        ↓  (L2 — user-confirmed)
Pause Campaign  →  External Action + Evidence + audit log
```

Chỗ dễ sai nhất và phải nói trước: **"CPA tăng" không tự nó là vấn đề.** Nếu
Rule Twin không thấy dữ liệu đơn hàng cùng kỳ, nó phải trả `insufficient` chứ
không được kết luận — đúng luật *cấm bịa số khi thiếu dữ liệu*.

---

## BusinessContext có đủ 11 miền chưa

| Miền Founder yêu cầu | Hôm nay | Thiếu gì |
|---|---|---|
| Commerce | 🟡 `orders` + `metrics` | đơn từ sàn, phí, payout |
| Marketing | ❌ | chưa có slice nào |
| Customer | ✅ `customers` | định danh đa kênh |
| Support | ❌ | chưa có |
| Finance | ✅ `finance` | thuế/hoàn tiền |
| Subscription | ❌ | doanh thu định kỳ — **chính là mô hình của Workizen** |
| Infrastructure | 🟡 `BusinessInput` (WTM-229/234) | chưa vào BusinessContext |
| AI Cost | 🟡 `BusinessInput` loại `provider` | chưa tách riêng |
| Cloud Cost | 🟡 như trên | — |
| Developer Productivity | ❌ | GitHub: nhịp release, thời gian từ commit tới store |
| Founder KPI | ❌ | tổng hợp cấp cao nhất |

**5/11 miền chưa có, 4 miền có một nửa.**

### Đề xuất mở rộng — và cách KHÔNG biến nó thành God Object

ADR-TON-016 cấm nhét mọi thứ vào `BusinessContext`. Nên đề xuất là **một slice
mỏng duy nhất**, không phải năm slice mới:

```dart
// nhẹ, chỉ đủ để AI biết "có gì ngoài kia và nó tươi tới đâu"
ExternalSignalSummary {
  connections: [{platform, status, lastSyncAt, freshness}],
  headline: [{kind, value, direction, confidence}],   // tối đa ~5 dòng
  unknownCount,                                        // thứ chưa kết nối
}
```

Chi tiết (từng campaign, từng email, từng crash) nằm ở **Capability Context
on-demand**, đúng chỗ ADR-TON-016 đã chỉ định.

Ba miền `Subscription` · `Developer Productivity` · `Founder KPI` **không cần
slice riêng**: chúng là **cách đọc** dữ liệu đã có, không phải dữ liệu mới.
Founder KPI = Rule Twin tổng hợp trên các slice sẵn có.

---

## Vì sao đây cũng là kiểm chứng sản phẩm, không chỉ là tiện cho Founder

Workizen là **doanh nghiệp số**: doanh thu subscription, không tồn kho, chi phí
là hạ tầng + AI + công cụ. Ba tháng trước mô hình Tổng Tài **không biểu diễn
nổi** một doanh nghiệp như vậy — dogfood lần 1 tìm ra bốn chỗ mô hình buộc phải
nói dối, và ADR-TON-023 (WTM-227→236, xong hôm nay) sửa cả bốn.

Vòng vận hành trên là **phép thử thứ hai, khó hơn**: không chỉ *"mô hình có chứa
được không"* mà *"chuỗi có khép được không khi dữ liệu tới từ bên ngoài"*.

Và nó kiểm đúng thứ khó kiểm nhất bằng test: **liệu người bán có biết việc tiếp
theo không.** Founder sẽ là người đầu tiên trả lời — bằng cách dùng thật.
