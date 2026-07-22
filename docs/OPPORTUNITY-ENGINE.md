# Opportunity Engine

## Động Cơ Cơ Hội

---

## English — What is an Opportunity?

### Definition

An **Opportunity** is an AI-discovered business situation where a user can make profitable gains within measurable time and risk parameters.

Not all market gaps are opportunities. An opportunity must have:

1. **Identifiable Gap** — Price difference, demand/supply mismatch, market trend
2. **Profitability** — Profit margin ROI > 20% (configurable)
3. **Achievability** — User can execute within their resources
4. **Timeframe** — Can be capitalized within 30-90 days
5. **Risk Quantified** — Risk score, failure scenarios known

### Opportunity Types

| Type | Example | Drivers |
|---|---|---|
| **Arbitrage** | Buy at 1688 $10/unit, sell on Shopee $25/unit | Price gap |
| **Trend** | Demand for "mini fan" up 210% YoY | Market trend |
| **Cross-border** | Product cheap in China, expensive in US | Geographic gap |
| **Supplier Gap** | 3 new suppliers entered market, lower MOQ | Sourcing innovation |
| **Channel Mismatch** | Product hot on TikTok, not on Amazon yet | Channel gap |
| **Inventory** | Competitor overstocked, discount fire sale | Supply shock |
| **Seasonal** | Winter boots demand up 300% in Dec | Time gap |

### Opportunity Scoring

Each opportunity gets a score based on:

```
Opportunity Score = (Profit Potential × Market Confidence × Achievability) / (Risk × Complexity)
```

Where:
- **Profit Potential** (1-10): Estimated profit margin %
- **Market Confidence** (1-10): Trend signal strength
- **Achievability** (1-10): User's ability to execute
- **Risk** (1-10): Downside scenarios
- **Complexity** (1-10): Steps to execution

**Result:** Score 1-100 (Higher = Better Opportunity)

### Opportunity Lifecycle

```
DISCOVERY (AI finds)
    ↓
ANALYSIS (AI scores + user reviews)
    ↓ (User acts or saves)
SAVED / REJECTED
    ↓ (If saved, user can act)
OPPORTUNITY HUB (displayed in list)
    ↓ (User can drill into)
DETAIL VIEW (all data + supplier/channel options)
    ↓ (User decides to pursue)
JOURNEY (create business journey to execute)
    ↓
EXECUTION (track as mission/task)
    ↓
COMPLETED / ABANDONED
```

### Opportunity Data

For each opportunity, Tổng Tài shows:

| Data | Purpose | Example |
|---|---|---|
| **Title** | What is the opportunity? | "Quạt mini cấm tay sạc USB — Arbitrage" |
| **Market** | Where? (Country, platform) | "Shopee → Amazon US" |
| **Profit** | Estimated margin | "$8.45 (42% profit)" |
| **Trend** | Why now? | "Demand ↑ 210%, Google Trend +180%" |
| **Suppliers** | Who to buy from? | "3 Suppliers, rated 4.7-4.9" |
| **Channels** | Where to sell? | "Amazon (best margin), eBay, Etsy" |
| **Timeline** | How long? | "21 days from sourcing to first sale" |
| **Score** | AI confidence | "Score 92/100 (Very High)" |
| **Risk** | Downside scenarios | "Market saturation, currency fluctuation" |
| **Competitors** | Who else is doing this? | "5 active sellers on Amazon (low competition)" |

### AI's Role in Opportunity Engine

| Stage | AI Does | Not AI |
|---|---|---|
| **Discovery** | ✅ Continuous scanning (1688, Alibaba, TikTok, Google Trends, Reddit) | ❌ User must propose |
| **Analysis** | ✅ Score, profit calc, risk assessment | ❌ User verifies |
| **Recommendation** | ✅ Personalized ranking based on user history | ❌ User makes final call |
| **Tracking** | ✅ Monitor market changes, alert if score drops | ❌ User executes |
| **Learning** | ✅ Learn from user's execution outcome | ❌ Human judgment trumps AI |

### Business Rules

1. **Real-Time Scoring** — Opportunity score updates continuously (hourly)
2. **Duplicate Dedup** — Don't show same opportunity twice
3. **User Preference Learning** — Learn what user acts on, what they ignore
4. **Competitive Alerting** — Alert if competitor's sale number drops (demand changing)
5. **Profit Calculator** — Factor in all costs (sourcing, shipping, fees, tax)
6. **Risk Tolerance** — User can set risk threshold (conservative/aggressive)
7. **Time Decay** — Opportunities expire or reduce in score over time

### Opportunity Hub UX

Users see:

```
[Search Opportunities | Recommended | Saved | Followed]

[Filter: Category | Market | Trend | Profit Range]

Opportunity Cards:
┌─────────────────────────────┐
│ Title + Market              │
│ Profit: $8.45 (42%)        │
│ Trend: ⬆️ 210%             │
│ Score: 92/100             │
│ Save | Follow | Drill      │
└─────────────────────────────┘
```

---

## Tiếng Việt — Cơ Hội Là Gì?

### Định Nghĩa

**Cơ Hội** là tình huống kinh doanh được AI phát hiện nơi người dùng có thể kiếm lợi nhuận trong các tham số thời gian và rủi ro có thể đo lường được.

Không phải tất cả khoảng trống thị trường đều là cơ hội. Một cơ hội phải có:

1. **Khoảng Trống Có Thể Xác Định** — Chênh lệch giá, mất cân bằng cung/cầu, xu hướng thị trường
2. **Lợi Nhuận** — Lợi nhuận ROI > 20% (có thể cấu hình)
3. **Khả Thi** — Người dùng có thể thực thi trong phạm vi tài nguyên của họ
4. **Khung Thời Gian** — Có thể được tận dụng trong 30-90 ngày
5. **Rủi Ro Được Định Lượng** — Điểm rủi ro, kịch bản thất bại đã biết

### Các Loại Cơ Hội

Xem bảng tiếng Anh ở trên cho 7 loại với ví dụ.

### Điểm Số Cơ Hội

Mỗi cơ hội nhận điểm dựa trên công thức tiếng Anh ở trên.

**Kết quả:** Điểm 1-100 (Cao hơn = Cơ Hội Tốt Hơn)

### Vòng Đời Cơ Hội

Xem sơ đồ tiếng Anh ở trên.

### Quy Tắc Kinh Doanh

1. **Tính Điểm Thời Gian Thực** — Điểm cơ hội cập nhật liên tục (mỗi giờ)
2. **Loại Bỏ Trùng Lặp** — Không hiển thị cùng một cơ hội hai lần
3. **Học Tùy Chọn Người Dùng** — Tìm hiểu người dùng hành động gì, bỏ qua gì
4. **Cảnh Báo Cạnh Tranh** — Cảnh báo nếu con số bán của đối thủ giảm (cầu thay đổi)
5. **Máy Tính Lợi Nhuận** — Tính đến tất cả chi phí (sourcing, vận chuyển, phí, thuế)
6. **Chịu Đựng Rủi Ro** — Người dùng có thể đặt ngưỡng rủi ro (bảo thủ/tích cực)
7. **Suy Giảm Thời Gian** — Cơ hội hết hạn hoặc giảm điểm theo thời gian

---

**Version:** 1.0  
**Status:** ✅ APPROVED by Founder  
**Next Doc:** AI-BUSINESS-COPILOT.md

