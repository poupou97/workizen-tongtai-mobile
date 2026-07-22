# Screen Specification — Business Journey (Goal Orchestration & Progress Tracking)

## Chi Tiết Màn Hình — Hành Trình Kinh Doanh (Điều Phối Mục Tiêu & Theo Dõi Tiến Độ)

---

## English — Business Journey Screen

### Purpose

**Business Journey** is the goal orchestration hub. It shows:
- Active business goals (e.g., "Enter US Market", "Launch Product Line X")
- Goal progress visualization (% complete, timeline)
- Step-by-step plan (8-10 steps with status: done/in-progress/waiting/blocked)
- Milestones and key metrics (cost estimate, timeline, forecast)
- AI Assistant guidance (chat sidebar with recommendations)
- Playbook references (similar goals completed by other users)

**User Journey:** Open Journey → see active goal at 80% complete → review 8-step plan → click step to view details/sub-tasks → chat with AI assistant → mark step done.

### Business Goal

Help entrepreneurs execute complex business initiatives by:
1. Breaking down big goals into manageable steps
2. Tracking progress against milestones
3. Keeping teams aligned on priorities
4. Getting AI guidance and recommendations
5. Learning from similar goals (playbooks)

### Information Architecture

```
Business Journey Screen
├── Header
│   ├── Title: "Business Journey - Goal Orchestration"
│   ├── Filter button (by status, priority)
│   └── "Create Goal" button
├── Active Goal Section
│   ├── Goal Title: "Enter US Market"
│   ├── Progress Circle: 80% complete
│   ├── Timeline: Start date - End date (12 days remaining)
│   ├── Visual progress bar with milestones marked
│   └── Goal status badge (In Progress)
├── Milestones Section
│   ├── Tasks: 12 completed / 15 total
│   ├── Timeline: 12 days remaining
│   ├── Cost: $4,560 spent / $8,000 budget (57%)
│   ├── Forecast Revenue: $28,500 (expected from achieving goal)
│   └── ROI: 312% (forecast)
├── Step-by-Step Plan
│   ├── Timeline visualization (horizontal or vertical)
│   ├── Step 1: Research US Suppliers (DONE ✓)
│   ├── Step 2: Negotiate Pricing (IN PROGRESS →)
│   ├── Step 3: Source Samples (WAITING ◄)
│   ├── Step 4: Compliance Check (BLOCKED ✕)
│   ├── Step 5-8: (not yet started)
│   └── Expand any step to see sub-tasks
├── AI Assistant Sidebar (right panel, desktop; collapsed on mobile)
│   ├── "Phương, here's what I recommend today:"
│   ├── 3-5 action pills (tap to execute)
│   ├── Chat area (scrollable message history)
│   ├── Input field for custom questions
│   └── "Quick Help" suggestions (FAQ)
├── Related Playbooks Section
│   ├── "Similar Goals"
│   ├── Playbook 1: "Expand to Thailand (Completed by Huy)"
│   ├── Playbook 2: "Launch Product Line (Completed by Linh)"
│   └── Tap to view template
├── All Goals List (collapsed, expandable)
│   ├── Goal 1: Enter US Market (80%, active)
│   ├── Goal 2: Expand to EU (30%, in progress)
│   ├── Goal 3: Launch Subscription (0%, planned)
│   └── Tap to switch to different goal
└── Bottom Navigation (5 tabs)
```

### Components

| Component | Specs | Example |
|---|---|---|
| **Header** | Safe area, 60px, white bg | Title + filter + "Create Goal" button |
| **Progress Circle** | 120x120px, centered | Animated progress ring (80%), percentage text, color coded (green = on track) |
| **Milestone Card** | Full-width, 120px | 4 stat boxes (Tasks, Timeline, Cost, Forecast) with icons |
| **Step Item** | Full-width, 80px, collapsible | Step number + title + status badge + expandable details |
| **Status Badge** | 60x20px | DONE (green ✓), IN PROGRESS (blue →), WAITING (yellow ◄), BLOCKED (red ✕) |
| **AI Recommendation Pill** | 100x40px, tappable | Icon + text (e.g., "Contact Supplier") |
| **Chat Bubble** | Full-width, 60px min | Message text + timestamp (AI left, user right) |
| **Playbook Card** | 1 of 2 in scroll, 150x100px | Title + author + completion status |
| **Goal List Item** | Full-width, 70px, tappable | Goal title + progress bar + status |
| **Bottom Nav** | 5 items, 60px height, fixed | Icons + labels |

### Navigation

| Tap | Destination | Action |
|---|---|---|
| Step Item (collapsed) | Step Detail | Expand to show sub-tasks, notes, linked documents, AI guidance |
| "Expand" link on Step | Step Full View | Full-screen view of step details, sub-tasks, timeline |
| Status Badge | Status Change Modal | Change step status (done/in-progress/waiting/blocked) with notes |
| AI Recommendation Pill | Action Execute | Execute recommended action (e.g., "Send Email to Supplier") |
| Playbook Card | Playbook Detail | Show template, step-by-step instructions, adapt for new goal |
| Goal List Item | Goal Switch | Switch to viewing different goal (active goal changes) |
| Chat Message | Context | Long press to copy, share, or get more info on AI recommendation |

### Mock Data

```json
{
  "activeGoal": {
    "id": 1,
    "title": "Enter US Market",
    "description": "Source products from Vietnam, establish US distributor, launch on Amazon FBA",
    "status": "in-progress",
    "startDate": "2026-06-01",
    "targetDate": "2026-07-15",
    "daysRemaining": 2,
    "progressPercent": 80,
    "owner": "Phương Nguyễn",
    "priority": "high"
  },
  "milestones": {
    "tasksDone": 12,
    "tasksTotal": 15,
    "timelineRemaining": "2 days",
    "costSpent": "$4,560",
    "costBudget": "$8,000",
    "costPercentUsed": 57,
    "forecastedRevenue": "$28,500",
    "expectedROI": 312
  },
  "steps": [
    {
      "id": 1,
      "number": 1,
      "title": "Research US Suppliers & Market",
      "status": "done",
      "completedDate": "2026-06-05",
      "subtasks": [
        { "title": "Review supplier lists", "done": true },
        { "title": "Contact 5 suppliers", "done": true },
        { "title": "Analyze pricing", "done": true }
      ],
      "notes": "Found 3 quality suppliers in Shenzhen. Average pricing: $2.40/unit."
    },
    {
      "id": 2,
      "number": 2,
      "title": "Negotiate Pricing & MOQ",
      "status": "in-progress",
      "startedDate": "2026-06-10",
      "subtasks": [
        { "title": "Request quotes from 3 suppliers", "done": true },
        { "title": "Negotiate pricing", "done": false },
        { "title": "Confirm MOQ", "done": false },
        { "title": "Get payment terms", "done": false }
      ],
      "assignee": "Phương Nguyễn",
      "dueDate": "2026-07-01"
    },
    {
      "id": 3,
      "number": 3,
      "title": "Source & Test Samples",
      "status": "waiting",
      "dueDate": "2026-07-05",
      "subtasks": [
        { "title": "Wait for sample shipment", "done": false },
        { "title": "Quality inspection", "done": false },
        { "title": "Product testing", "done": false }
      ],
      "blockedReason": "Waiting for samples from TechPro Wholesale (ETA: 2026-07-03)"
    },
    {
      "id": 4,
      "number": 4,
      "title": "Compliance & Certification",
      "status": "blocked",
      "dueDate": "2026-07-08",
      "subtasks": [
        { "title": "FCC compliance check", "done": false },
        { "title": "CE mark for EU", "done": false }
      ],
      "blockedReason": "Waiting for compliance consultant appointment (scheduled 2026-07-15)"
    },
    {
      "id": 5,
      "number": 5,
      "title": "Place Initial Order (100 units)",
      "status": "not-started",
      "dueDate": "2026-07-10"
    },
    {
      "id": 6,
      "number": 6,
      "title": "Prepare for FBA Shipment",
      "status": "not-started",
      "dueDate": "2026-07-12"
    }
  ],
  "aiAssistant": {
    "message": "Phương, tuyệt vời! Bạn đã hoàn thành 80% hành trình. Hôm nay tôi đề xuất:",
    "recommendations": [
      { "id": 1, "text": "Follow up on pricing negotiation", "actionType": "message", "actionTarget": "supplier" },
      { "id": 2, "text": "Prepare compliance documentation", "actionType": "document", "actionTarget": "compliance" },
      { "id": 3, "text": "Create FBA shipment plan", "actionType": "template", "actionTarget": "amazon" }
    ]
  },
  "playbooks": [
    {
      "id": 1,
      "title": "Expand to Thailand",
      "author": "Huy Đặng",
      "completion": "completed",
      "steps": 8,
      "timeline": "45 days",
      "revenue": "$45,000"
    },
    {
      "id": 2,
      "title": "Launch Product Line",
      "author": "Linh Trần",
      "completion": "completed",
      "steps": 6,
      "timeline": "30 days",
      "revenue": "$28,500"
    }
  ],
  "allGoals": [
    { "id": 1, "title": "Enter US Market", "progress": 80, "status": "in-progress", "daysRemaining": 2 },
    { "id": 2, "title": "Expand to EU", "progress": 30, "status": "in-progress", "daysRemaining": 60 },
    { "id": 3, "title": "Launch Subscription", "progress": 0, "status": "planned", "daysRemaining": 90 }
  ]
}
```

### Business Rules

1. **Goal Status Auto-Updated** — Progress calculated based on step completion % (weighted by step importance)
2. **Step Status Manual** — User marks steps done/in-progress/waiting/blocked; AI suggests when to advance
3. **Milestone Alerts** — Alert if cost exceeds budget by 20%; alert if timeline at risk (>50% time used, <80% steps complete)
4. **Playbook Adaptation** — When user views playbook, can "Adapt" it to create new goal with pre-filled steps
5. **AI Recommendations Real-Time** — Updated daily; can be manually refreshed
6. **Role Assignments Optional** — Steps can be assigned to team members (future phase)
7. **Documents Linkable** — Each step can link to related docs (supplier quotes, compliance forms, etc.)

### AI Capabilities

| AI Feature | Example |
|---|---|
| **Next Action Suggestion** — Analyze goal state; recommend 3-5 actions for today |
| **Risk Detection** — Flag if timeline at risk (cost overage, timeline behind), suggest mitigation |
| **Playbook Recommendation** — Suggest similar playbooks from community; offer to adapt |
| **Supplier Matching** — Recommend suppliers from Producer module that fit this goal |
| **Financial Projection** — Forecast revenue/ROI based on market data, historical similar goals |
| **Step Optimization** — Suggest reordering steps for faster timeline or lower cost |

### Required APIs

```
GET /api/journey/activeGoal
  Returns: current active goal with all details (title, progress, milestones, steps)

GET /api/journey/goal/{id}
  Returns: full goal detail including steps, subtasks, notes, timeline

GET /api/journey/steps
  Query: ?goalId=1&status=all
  Returns: list of steps with status, subtasks, assignments

GET /api/journey/step/{id}
  Returns: full step detail with subtasks, linked documents, notes, AI guidance

GET /api/journey/recommendations
  Query: ?goalId=1&limit=5
  Returns: AI-generated action recommendations for current goal

GET /api/journey/playbooks
  Query: ?category=market-expansion&limit=10
  Returns: list of playbooks (completed goals) users can adapt

GET /api/journey/playbook/{id}
  Returns: full playbook with steps, instructions, author notes, expected timeline/revenue

POST /api/journey/goal
  Body: { title, description, targetDate, budget, strategy }
  Returns: newly created goal with generated steps

PUT /api/journey/step/{id}/status
  Body: { status, notes }
  Returns: updated step with milestone recalculation

GET /api/journey/allGoals
  Returns: list of all goals (active, in-progress, planned, completed) with progress
```

### States

#### Loading State
```
Show skeleton/placeholder:
- Progress circle (shimmer)
- Milestone card (4x shimmer)
- Step items (6x shimmer)
- AI chat area (shimmer)
- Playbook cards (2x shimmer)
```

#### Empty State
```
No active goal:
- Icon: flag icon
- Message: "No active goal. Let's set one! What do you want to achieve?"
- CTA: "Create Business Goal" (opens goal creation flow)
```

#### Error State
```
If API fails:
- Error message: "Could not load goal. Check your connection."
- Retry button
- Offline fallback: show last-known goal state with "offline" badge
```

### Responsive Design

```
Mobile (375px): Full-width layout
  - Progress circle full-width
  - Milestone card stacked
  - Steps single-column, collapsible
  - AI chat collapsed (tap to expand)
  - Playbook cards horizontal scroll

Tablet/Desktop (600px+): Side-by-side layout
  - Left: Active goal + steps (70%)
  - Right: AI Assistant sidebar (30%) + playbooks below
  - Both scrollable sections
```

### Accessibility

- ✅ Heading hierarchy: H1 (Business Journey) → H2 (Active Goal) → H3 (Steps) → H4 (Subtasks)
- ✅ Touch targets: 44px minimum (steps, pills, buttons)
- ✅ Color contrast: WCAG AA (4.5:1 for text)
- ✅ Focus states: Visible outline on tappable elements
- ✅ Labels: All status badges have text (e.g., "Done" not just checkmark)
- ✅ Progress circle: Include % text inside, not just visual ring
- ✅ Chat: Screen reader friendly message history

### Future Enhancements

1. ⏳ Team collaboration (assign steps to team members, track who did what)
2. ⏳ Dependent steps (mark step B blocked until step A done)
3. ⏳ Budget tracking per step (allocate budget, track spending)
4. ⏳ Resource planning (identify required skills/equipment per step)
5. ⏳ Document collaboration (attach files, markup, version control)
6. ⏳ Time tracking (log hours per step, compare to estimate)
7. ⏳ Goal templates (pre-built templates for common goals: launch product, expand market, etc.)

---

## Tiếng Việt — Màn Hình Hành Trình Kinh Doanh

### Mục Đích

**Hành Trình Kinh Doanh** là trung tâm điều phối mục tiêu. Nó hiển thị:
- Các mục tiêu kinh doanh đang hoạt động
- Trực quan hóa tiến độ mục tiêu
- Kế hoạch từng bước
- Các mốc quan trọng và chỉ số chính
- Hướng dẫn của Trợ lý AI
- Sách hướng dẫn tham khảo

### Mục Tiêu Kinh Doanh

Giúp doanh nhân thực hiện các sáng kiến kinh doanh phức tạp bằng cách:
1. Chia nhỏ các mục tiêu lớn thành các bước có thể quản lý
2. Theo dõi tiến độ so với các mốc
3. Giữ các nhóm phù hợp với các ưu tiên
4. Nhận hướng dẫn và khuyến nghị của AI
5. Học tập từ các mục tiêu tương tự

(Xem phần tiếng Anh ở trên cho chi tiết đầy đủ)

---

**Version:** 1.0  
**Component Count:** 10 main components  
**API Calls:** 11 endpoints  
**Status:** ✅ SPECIFICATION COMPLETE  
**Next Screen:** SCREEN-OPPORTUNITY-HUB.md
