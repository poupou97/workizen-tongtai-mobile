# Screen Specification — AI Copilot (Chat Interface & Business Assistant)

## Chi Tiết Màn Hình — Trợ Lý AI (Giao Diện Chat & Trợ Lý Kinh Doanh)

---

## English — AI Copilot Screen

### Purpose

**AI Copilot** is the conversational business assistant. It shows:
- Chat interface for natural language questions about business
- Quick recommendation pills (5 recommended actions today)
- Business health metrics (revenue trend, active orders, low stock alerts)
- Opportunities discovered today
- Conversation history (searchable)
- Context-aware suggestions based on user's business state

**User Journey:** Open Copilot → see "Good morning, Phương. Revenue trending +18% today." → see 5 recommendation pills (one-tap actions) → ask question "Should I restock the fans?" → AI responds with analysis → approve recommendation.

### Business Goal

Help entrepreneurs get AI-powered business guidance by:
1. Answering business questions in natural language
2. Providing daily action recommendations
3. Monitoring business health metrics in real-time
4. Surfacing opportunities as they arise
5. Enabling quick one-tap decisions (e.g., "Restock Now")

### Information Architecture

```
AI Copilot Screen
├── Header
│   ├── Title: "AI Copilot - Your Business Assistant"
│   ├── Settings icon (copilot preferences)
│   └── Search button (search conversation history)
├── Daily Summary Card
│   ├── Greeting (time-aware)
│   ├── Business health summary (1-2 key metrics)
│   └── Status emoji/icon
├── Recommendation Pills Section
│   ├── "Today's Recommendations (5 items, swipeable)"
│   ├── Pill 1: "Restock Quạt Mini — 12 units"
│   ├── Pill 2: "Reply to VIP Customer — 15 messages"
│   ├── Pill 3: "Review Compliance Docs — 2 pending"
│   ├── Pill 4: "Launch Flash Sale — High demand detected"
│   ├── Pill 5: "Follow up on Supplier — Pricing pending"
│   └── Each pill is tappable (one-tap action)
├── Business Health Metrics
│   ├── Metric 1: Revenue Trend (last 7 days)
│   ├── Metric 2: Active Orders (today)
│   ├── Metric 3: Low Stock Alerts (# items)
│   ├── Metric 4: Customer Messages (unread)
│   └── Each metric tappable (drill into detail)
├── Opportunities Section
│   ├── "Hot Opportunities Today"
│   ├── Opportunity Card 1 (score: 92)
│   ├── Opportunity Card 2 (score: 88)
│   └── "See All" link
├── Chat Area (main content)
│   ├── Conversation history (scrollable)
│   │   ├── User message (right-aligned, blue bubble)
│   │   ├── AI response (left-aligned, white bubble)
│   │   ├── Timestamp
│   │   └── Message actions (copy, share)
│   ├── Input field (bottom, sticky)
│   │   ├── Text input placeholder: "Ask me anything about your business..."
│   │   ├── Mic icon (voice input)
│   │   └── Send button
│   └── Quick prompts (e.g., "Analyze my profit", "What should I do today?")
└── Bottom Navigation (5 tabs)
```

### Components

| Component | Specs | Example |
|---|---|---|
| **Header** | Safe area, 60px, white bg | Title + settings icon + search button |
| **Daily Summary Card** | Full-width, 100px | Greeting + 2 key metrics + emoji/icon + status |
| **Recommendation Pill** | 110x50px, pill-shaped, tappable | Icon + action text + confidence score (e.g., "92% confident") |
| **Health Metric Box** | 1 of 4 in grid, 80x100px | Metric name + value + small chart/icon + status indicator |
| **Chat Bubble (User)** | Right-aligned, 80% width min | Message text + timestamp |
| **Chat Bubble (AI)** | Left-aligned, 80% width min | Message text + action buttons (copy, share) + timestamp |
| **Input Field** | Full-width, 50px | Text input + mic icon + send button |
| **Quick Prompt Chip** | 120x40px, tap to insert | Prompt text (e.g., "Analyze profit") |
| **Opportunity Card** | Full-width, 100px | Score + title + market + profit + save action |
| **Bottom Nav** | 5 items, 60px height, fixed | Icons + labels |

### Navigation

| Tap | Destination | Action |
|---|---|---|
| Recommendation Pill | Action Execute Modal | Execute the recommended action (e.g., "Confirm restock 12 units of SKU-001") |
| Health Metric Box | Metric Detail | Drill into that metric (e.g., revenue chart, active orders list) |
| Opportunity Card | Opportunity Detail | Show full opportunity with supplier options |
| Message (copy) | Clipboard | Copy message text to clipboard |
| Message (share) | Share Modal | Share message via email, Slack, etc. |
| Quick Prompt | Chat Input | Insert prompt into input field (user can refine/send) |
| Mic Icon | Voice Input | Start listening for voice message (STT) |

### Mock Data

```json
{
  "summary": {
    "greeting": "Good morning, Phương! 🌟",
    "businessStatus": "Revenue trending +18% today. Great momentum!",
    "statusEmoji": "🚀"
  },
  "recommendations": [
    {
      "id": 1,
      "title": "Restock Quạt Mini",
      "description": "12 units needed in next 2 days",
      "actionType": "inventory",
      "confidence": 94,
      "icon": "box",
      "actionPayload": { "skuId": "SKU-001-A", "quantity": 12 }
    },
    {
      "id": 2,
      "title": "Reply to VIP Customers",
      "description": "15 messages waiting",
      "actionType": "customer",
      "confidence": 88,
      "icon": "message",
      "actionPayload": { "segment": "VIP", "unreadCount": 15 }
    },
    {
      "id": 3,
      "title": "Review Compliance Docs",
      "description": "2 pending US FDC requirements",
      "actionType": "compliance",
      "confidence": 85,
      "icon": "document",
      "actionPayload": { "itemCount": 2, "type": "compliance" }
    },
    {
      "id": 4,
      "title": "Launch Flash Sale",
      "description": "Mini fans trending +42% this week",
      "actionType": "marketing",
      "confidence": 92,
      "icon": "lightning",
      "actionPayload": { "productId": 1, "discountPercent": 15, "duration": "24h" }
    },
    {
      "id": 5,
      "title": "Follow up on Supplier",
      "description": "TechPro Wholesale pricing quote due",
      "actionType": "supplier",
      "confidence": 81,
      "icon": "phone",
      "actionPayload": { "supplierId": 1, "type": "pricing" }
    }
  ],
  "businessHealth": {
    "revenueTrend": {
      "label": "Revenue Trend (7 days)",
      "value": "+18%",
      "icon": "trending-up",
      "status": "excellent"
    },
    "activeOrders": {
      "label": "Active Orders (today)",
      "value": "156",
      "icon": "orders",
      "status": "good"
    },
    "lowStockAlerts": {
      "label": "Low Stock Alerts",
      "value": "3",
      "icon": "alert",
      "status": "warning"
    },
    "unreadMessages": {
      "label": "Unread Messages",
      "value": "12",
      "icon": "mail",
      "status": "attention"
    }
  },
  "opportunities": [
    {
      "id": 1,
      "score": 92,
      "title": "Quạt mini cấm tay — Arbitrage",
      "market": "Shopee → Amazon US",
      "profit": "$8.45 (42%)",
      "icon": "target"
    },
    {
      "id": 2,
      "score": 88,
      "title": "Túi chống nước du lịch",
      "market": "1688 → TikTok",
      "profit": "$6.12 (38%)",
      "icon": "target"
    }
  ],
  "conversationHistory": [
    {
      "type": "greeting",
      "sender": "AI",
      "message": "Good morning, Phương! I've analyzed your business and found some great opportunities today. How can I help you?",
      "timestamp": "08:00 AM",
      "actions": ["copy", "share"]
    },
    {
      "type": "user",
      "sender": "Phương",
      "message": "Should I restock the fans? We sold a lot yesterday.",
      "timestamp": "08:05 AM"
    },
    {
      "type": "AI",
      "sender": "Copilot",
      "message": "Yes, definitely! Your fans sold 89 units in the last 7 days. At that velocity, you have ~4 days of stock remaining. I recommend ordering 100-150 units from TechPro Wholesale (lead time: 7-14 days). Current price: $2.10/unit. Ready to place the order?",
      "timestamp": "08:06 AM",
      "actions": ["copy", "share"],
      "suggestion": "Place Order"
    },
    {
      "type": "user",
      "sender": "Phương",
      "message": "What's the profit on this product?",
      "timestamp": "08:08 AM"
    },
    {
      "type": "AI",
      "sender": "Copilot",
      "message": "Quạt mini sells for $8.45 on average (ranging from $7.99-$9.99 depending on channel). Cost is $2.10/unit. That's a 303% markup or 75% margin after platform fees (~15-20%). Very healthy!",
      "timestamp": "08:09 AM",
      "actions": ["copy", "share"]
    }
  ],
  "quickPrompts": [
    { "text": "Analyze my profit" },
    { "text": "What should I do today?" },
    { "text": "Which product should I focus on?" },
    { "text": "What are my risks?" },
    { "text": "Show my customer insights" }
  ]
}
```

### Business Rules

1. **Recommendations Daily** — AI generates 5 top recommendations each morning; refreshable on-demand
2. **Confidence Scores Shown** — All recommendations include confidence % (how certain AI is of the recommendation)
3. **Action Payloads Pre-Loaded** — Each pill carries action data; one-tap execution (with confirmation)
4. **Health Metrics Real-Time** — Updated every 30 minutes from Finance, Inventory, Consumer modules
5. **Conversation Persistent** — Chat history saved per user; searchable
6. **Context-Aware Responses** — AI responses consider user's business state (inventory, orders, revenue) + historical context
7. **Privacy First** — AI runs on-device where possible; sensitive data stays private

### AI Capabilities

| AI Feature | Example |
|---|---|
| **Natural Language Q&A** — Answer business questions: "How much did I make yesterday?" → pulls Finance data, calculates, responds |
| **Recommendation Engine** — Daily 5 actions weighted by: urgency, business impact, user's previous actions |
| **Business Analysis** — "Analyze my profit" → AI fetches data, computes by channel/product, summarizes insights |
| **Anomaly Detection** — Flag unusual patterns (revenue dip, spike in returns, supplier delays) |
| **Predictive Alerts** — "You'll run out of [product] in 3 days; should I order now?" |
| **Historical Insights** — Learn from past patterns: "Last year at this time, you had similar sales trend" |

### Required APIs

```
GET /api/copilot/summary
  Returns: greeting, businessStatus, statusEmoji

GET /api/copilot/recommendations
  Query: ?limit=5&sort=impact
  Returns: 5 recommended actions with confidence scores

GET /api/copilot/businessHealth
  Returns: 4 health metrics (revenue trend, active orders, low stock, messages)

GET /api/copilot/opportunities
  Query: ?limit=5&sort=score
  Returns: top opportunities discovered today

GET /api/copilot/conversation
  Query: ?limit=50&sort=recent
  Returns: chat history (searchable, sortable)

POST /api/copilot/message
  Body: { message, context }
  Returns: AI response + suggested actions

POST /api/copilot/recommendation/{id}/execute
  Body: { recommendationId, confirmation }
  Returns: action executed + result

GET /api/copilot/quickPrompts
  Returns: list of suggested quick prompts

POST /api/copilot/settings
  Body: { preferences, toggles }
  Returns: copilot preferences saved
```

### States

#### Loading State
```
Show skeleton/placeholder:
- Summary card (shimmer)
- Recommendation pills (5x shimmer)
- Health metrics (4x shimmer)
- Opportunities (2x shimmer)
- Chat area (typing indicator)
```

#### Empty State
```
First-time user (no chat history):
- Icon: chat icon
- Message: "Hi Phương! I'm your AI Copilot. Ask me anything about your business."
- Suggested prompts: "Analyze my profit", "What should I do today?"
```

#### Error State
```
If API fails:
- Error message: "I'm having trouble connecting. Let me try again..."
- Retry indicator
- Offline fallback: show cached summary + last 5 messages with "offline" badge
```

### Responsive Design

```
Mobile (375px): Full-width layout
  - Summary card full-width
  - Recommendation pills horizontal scroll
  - Health metrics grid (2x2)
  - Opportunities carousel horizontal scroll
  - Chat area single-column (scrollable)
  - Input field sticky at bottom

Tablet/Desktop (600px+): Side-by-side layout
  - Left: Summary + recommendations + health metrics (30%)
  - Right: Chat area + opportunities (70%)
  - Both scrollable sections
```

### Accessibility

- ✅ Heading hierarchy: H1 (AI Copilot) → H2 (Recommendations) → H3 (Individual recommendations)
- ✅ Touch targets: 44px minimum (pills, buttons, message bubbles)
- ✅ Color contrast: WCAG AA (4.5:1 for text)
- ✅ Focus states: Visible outline on tappable elements
- ✅ Labels: All buttons have text (e.g., "Send" not just icon)
- ✅ Chat: Message sender clearly labeled (User/Copilot)
- ✅ Voice Input: Clearly labeled mic button; speech-to-text output visible
- ✅ Confidence Scores: Explained (e.g., "92% confident this is a good restock opportunity")

### Future Enhancements

1. ⏳ Voice output (AI reads responses aloud, TTS)
2. ⏳ Personalized teaching (AI suggests educational resources based on questions)
3. ⏳ Integration with Actions (voice: "Restock the fans" → executes directly)
4. ⏳ Proactive alerts (push notification: "Your best customer just ordered again, 80% likely to buy more")
5. ⏳ Team chat (copilot answers group questions, coordinates team)
6. ⏳ Competitive intel (AI monitors competitor pricing, alerts if undercut)
7. ⏳ Playbook generation (AI generates playbooks for user's successful workflows)

---

## Tiếng Việt — Màn Hình Trợ Lý AI

### Mục Đích

**Trợ Lý AI** là trợ lý kinh doanh trò chuyện. Nó hiển thị:
- Giao diện chat cho các câu hỏi kinh doanh bằng ngôn ngữ tự nhiên
- Các viên gợi ý nhanh
- Các chỉ số sức khỏe kinh doanh
- Các cơ hội được khám phá hôm nay
- Lịch sử trò chuyện (có thể tìm kiếm)
- Các gợi ý nhận thức bối cảnh

### Mục Tiêu Kinh Doanh

Giúp doanh nhân nhận được hướng dẫn kinh doanh do AI cung cấp bằng cách:
1. Trả lời các câu hỏi kinh doanh bằng ngôn ngữ tự nhiên
2. Cung cấp khuyến nghị hành động hàng ngày
3. Giám sát các chỉ số sức khỏe kinh doanh theo thời gian thực
4. Bề mặt các cơ hội khi chúng phát sinh
5. Cho phép quyết định nhanh chóng một chạm

(Xem phần tiếng Anh ở trên cho chi tiết đầy đủ)

---

**Version:** 1.0  
**Component Count:** 10 main components  
**API Calls:** 8 endpoints  
**Status:** ✅ SPECIFICATION COMPLETE  
**Next Screen:** SCREEN-PRODUCER-DETAIL.md (Detail Screens)
