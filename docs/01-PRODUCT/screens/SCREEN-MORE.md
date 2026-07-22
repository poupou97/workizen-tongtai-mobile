# Screen Specification — More (Secondary Navigation & Settings)

## Chi Tiết Màn Hình — Thêm (Điều Hướng Phụ & Cài Đặt)

---

## English — More Screen

### Purpose

**More** is the secondary navigation and settings hub. It shows:
- Business Setup (company info, team, warehouse, API config)
- Document Intelligence (scan, OCR, extract)
- AI Studio (custom workflows, templates)
- Integration Center (Shopee, TikTok, Keycloak, etc.)
- Finance Settings (payment, accounting software sync)
- User Profile (name, email, password)
- Notifications & Privacy Settings
- Help & Support (FAQs, contact support)
- Logout

**User Journey:** Open More → see business setup section → tap "Business Setup" → configure warehouse → back to More → tap "Integrations" → connect Shopee.

### Business Goal

Help entrepreneurs configure Tổng Tài by:
1. Setting up core business information
2. Integrating with sales channels and tools
3. Managing team and permissions
4. Accessing advanced features (Document Intelligence, AI Studio)
5. Getting help and support

### Information Architecture

```
More Screen
├── Header
│   ├── Title: "More"
│   └── Search icon (search settings/help)
├── User Profile Card (at top)
│   ├── User avatar + name
│   ├── Email
│   └── "Edit Profile" link
├── Main Sections (Vertical list)
│   ├── BUSINESS SETUP
│   │   ├── Company Information
│   │   ├── Team Members
│   │   ├── Warehouse Configuration
│   │   ├── Roles & Permissions
│   │   ├── API Keys
│   │   └── Business Licenses
│   │
│   ├── FEATURES
│   │   ├── Document Intelligence (Scan & OCR)
│   │   ├── AI Studio (Custom Workflows)
│   │   ├── Integration Center
│   │   └── Financial Reports
│   │
│   ├── SETTINGS
│   │   ├── Notifications
│   │   ├── Privacy & Security
│   │   ├── Language
│   │   ├── Currency
│   │   ├── Dark Mode
│   │   └── Data Export
│   │
│   ├── HELP & SUPPORT
│   │   ├── FAQ
│   │   ├── Video Tutorials
│   │   ├── Contact Support
│   │   ├── Report Bug
│   │   ├── Request Feature
│   │   └── Feedback
│   │
│   └── ACCOUNT
│       ├── Change Password
│       ├── Two-Factor Auth
│       ├── Logout
│       └── Delete Account
│
└── Bottom Navigation (5 tabs, but "More" is active)
```

### Components

| Component | Specs | Example |
|---|---|---|
| **Header** | Safe area, 60px, white bg | Title "More" + search icon |
| **Profile Card** | Full-width, 100px, tappable | Avatar (60x60px) + name + email + "Edit Profile" link |
| **Section Header** | Full-width, 40px, sticky | Section title (e.g., "BUSINESS SETUP") in uppercase, light gray bg |
| **Menu Item** | Full-width, 60px, tappable | Icon (24x24px) + text + right arrow + optional badge (e.g., "Setup 30%") |
| **Divider** | Full-width, thin line | Visual separator between sections |
| **Badge** | 30x20px, colored | "NEW", "Setup 30%", "Incomplete", etc. |
| **Toggle Switch** | 50x30px, right-aligned | For boolean settings (notifications, dark mode, etc.) |
| **Bottom Nav** | 5 items, 60px height, fixed | Icons + labels; "More" tab active |

### Navigation

| Tap | Destination | Action |
|---|---|---|
| Edit Profile | Profile Edit Modal | Edit name, email, avatar |
| Company Information | Company Setup Form | Edit business name, registration, address, tax ID |
| Team Members | Team Management Screen | Add/remove team members, assign roles |
| Warehouse Configuration | Warehouse Setup Form | Add/edit warehouse locations, capacity |
| API Keys | API Management Screen | Generate, revoke, regenerate API keys with permissions |
| Document Intelligence | Document Scan Screen | Launch camera/file upload for OCR/extraction |
| AI Studio | Workflow Builder | Create custom AI workflows (future feature) |
| Integration Center | Integration List | View/configure integrations (Shopee, TikTok, Keycloak, etc.) |
| Notifications | Notification Settings | Toggle notification types, frequency, channels |
| Privacy & Security | Privacy Settings | Privacy policy, data deletion, data export |
| Language | Language Selector | Select app language (EN/VI) |
| FAQ | FAQ Browser | Search FAQs with common topics |
| Contact Support | Support Form | Email support team with ticket creation |
| Change Password | Password Change Form | Update password with validation |
| Logout | Logout Confirmation | Confirm logout + clear local cache |

### Mock Data

```json
{
  "user": {
    "id": 1,
    "name": "Phương Nguyễn",
    "email": "phuong@example.com",
    "avatar": "https://...",
    "tier": "Business",
    "joinedDate": "2026-01-15"
  },
  "menuItems": [
    {
      "section": "BUSINESS SETUP",
      "items": [
        { "id": 1, "icon": "building", "label": "Company Information", "badge": null, "screen": "company-setup" },
        { "id": 2, "icon": "users", "label": "Team Members", "badge": "2 members", "screen": "team-management" },
        { "id": 3, "icon": "warehouse", "label": "Warehouse Configuration", "badge": "3 configured", "screen": "warehouse-setup" },
        { "id": 4, "icon": "lock", "label": "Roles & Permissions", "badge": null, "screen": "roles-permissions" },
        { "id": 5, "icon": "code", "label": "API Keys", "badge": "1 active", "screen": "api-management" },
        { "id": 6, "icon": "file", "label": "Business Licenses", "badge": "Incomplete", "screen": "licenses" }
      ]
    },
    {
      "section": "FEATURES",
      "items": [
        { "id": 7, "icon": "camera", "label": "Document Intelligence", "badge": "NEW", "screen": "doc-scanner" },
        { "id": 8, "icon": "workflow", "label": "AI Studio", "badge": "COMING SOON", "screen": null },
        { "id": 9, "icon": "plug", "label": "Integration Center", "badge": "3 connected", "screen": "integrations" },
        { "id": 10, "icon": "chart", "label": "Financial Reports", "badge": null, "screen": "reports" }
      ]
    },
    {
      "section": "SETTINGS",
      "items": [
        { "id": 11, "icon": "bell", "label": "Notifications", "toggle": true, "value": true },
        { "id": 12, "icon": "shield", "label": "Privacy & Security", "toggle": false },
        { "id": 13, "icon": "globe", "label": "Language", "value": "English", "screen": "language-select" },
        { "id": 14, "icon": "wallet", "label": "Currency", "value": "USD", "screen": "currency-select" },
        { "id": 15, "icon": "moon", "label": "Dark Mode", "toggle": true, "value": false },
        { "id": 16, "icon": "download", "label": "Data Export", "screen": "data-export" }
      ]
    },
    {
      "section": "HELP & SUPPORT",
      "items": [
        { "id": 17, "icon": "help-circle", "label": "FAQ", "screen": "faq" },
        { "id": 18, "icon": "play", "label": "Video Tutorials", "screen": "video-tutorials" },
        { "id": 19, "icon": "mail", "label": "Contact Support", "screen": "support-form" },
        { "id": 20, "icon": "bug", "label": "Report Bug", "screen": "bug-report" },
        { "id": 21, "icon": "lightbulb", "label": "Request Feature", "screen": "feature-request" },
        { "id": 22, "icon": "message", "label": "Feedback", "screen": "feedback-form" }
      ]
    },
    {
      "section": "ACCOUNT",
      "items": [
        { "id": 23, "icon": "key", "label": "Change Password", "screen": "password-change" },
        { "id": 24, "icon": "shield-check", "label": "Two-Factor Auth", "toggle": true, "value": false },
        { "id": 25, "icon": "logout", "label": "Logout", "action": "logout" },
        { "id": 26, "icon": "trash", "label": "Delete Account", "destructive": true, "screen": "account-delete" }
      ]
    }
  ],
  "integrations": [
    { "id": 1, "name": "Shopee", "status": "connected", "lastSync": "2 hours ago" },
    { "id": 2, "name": "TikTok Shop", "status": "connected", "lastSync": "1 hour ago" },
    { "id": 3, "name": "Keycloak (Identity)", "status": "connected", "lastSync": "Real-time" },
    { "id": 4, "name": "Google Drive (Backup)", "status": "not-connected", "setup": "pending" },
    { "id": 5, "name": "Xero (Accounting)", "status": "not-connected", "setup": "available" }
  ],
  "settings": {
    "notifications": {
      "orderAlerts": true,
      "stockAlerts": true,
      "systemAlerts": true,
      "emailDigest": "daily",
      "pushNotifications": true
    },
    "privacy": {
      "dataSharing": false,
      "analytics": true,
      "cookieConsent": true
    },
    "language": "en",
    "currency": "USD",
    "darkMode": false,
    "timezone": "America/New_York"
  }
}
```

### Business Rules

1. **Setup Progress Tracked** — "Setup X%" badges motivate completion of Business Setup sections
2. **Integrations One-Click** — Tap integration, OAuth flow (if needed), auto-connection
3. **Settings Persistent** — All settings saved locally + synced to backend
4. **Privacy Defaults Secure** — Dark patterns avoided; data sharing OFF by default, users opt-in
5. **Support Ticketing** — Support messages tracked, users get response emails
6. **Feature Gating** — Some features (AI Studio) marked "COMING SOON"; available based on tier
7. **Logout Clears Cache** — Local data wiped on logout for security; can re-login anytime

### AI Capabilities

| AI Feature | Example |
|---|---|
| **Setup Assistant** — AI suggests setup steps based on business type (e.g., "You should connect Shopee next") |
| **Integration Recommendations** — Suggest integrations based on business setup (e.g., if said "selling on Shopee", recommend Shopee integration) |
| **Document Intelligence** — OCR + extraction; AI classifies documents (invoice, receipt, bill of lading, etc.) |
| **Custom Workflow Templates** — AI Studio offers templates (e.g., "Send SMS to VIP customers when they order") |
| **Help Personalization** — FAQ and tutorials tailored to user's business type and usage patterns |

### Required APIs

```
GET /api/user/profile
  Returns: user name, email, avatar, tier, joinedDate

PUT /api/user/profile
  Body: { name, email, avatar }
  Returns: profile updated

GET /api/settings/user
  Returns: all user settings (notifications, privacy, language, currency, darkMode)

PUT /api/settings/user
  Body: { settingKey, value }
  Returns: setting updated

GET /api/integrations
  Returns: list of available integrations with connection status

POST /api/integrations/{id}/connect
  Body: { authToken or credentials }
  Returns: integration connected + sync started

GET /api/business/setup
  Returns: setup progress status (% complete per section)

POST /api/auth/logout
  Returns: user logged out + session cleared

POST /api/user/password/change
  Body: { currentPassword, newPassword }
  Returns: password changed

GET /api/support/faqs
  Query: ?search=inventory
  Returns: matching FAQs with answers

POST /api/support/ticket
  Body: { subject, message, category }
  Returns: ticket created + ticket ID returned
```

### States

#### Loading State
```
Show skeleton/placeholder:
- Profile card (shimmer)
- Menu section headers (3x shimmer)
- Menu items (12x shimmer)
```

#### Empty State
```
First-time setup:
- Icon: checklist icon
- Message: "Let's set up your business! Start with Company Information."
- CTA: "Setup Now"
```

#### Error State
```
If sync fails:
- Error message: "Could not sync settings. Check your connection."
- Retry button
- Offline fallback: use cached settings with "offline" badge
```

### Responsive Design

```
Mobile (375px): Full-width layout
  - Profile card full-width
  - Section headers sticky (show current section)
  - Menu items full-width, scrollable
  - Bottom nav fixed at bottom

Tablet (600px+): Side-by-side layout
  - Left: Section list (menu index)
  - Right: Menu items (wider)
  - Profile card full-width at top
```

### Accessibility

- ✅ Heading hierarchy: H1 (More) → H2 (Section headers) → H3 (Menu items)
- ✅ Touch targets: 44px minimum (menu items, toggles)
- ✅ Color contrast: WCAG AA (4.5:1 for text)
- ✅ Focus states: Visible outline on tappable elements
- ✅ Labels: All icons have text labels
- ✅ Toggles: Clear on/off labels (not just color)
- ✅ Badges: Semantic meaning (e.g., "NEW" vs "Setup 30%")
- ✅ Destructive Actions: Require confirmation (e.g., "Delete Account")

### Future Enhancements

1. ⏳ Advanced integrations (Xero, FreshBooks, Klaviyo, etc.)
2. ⏳ Webhook management (set up webhooks for custom integrations)
3. ⏳ Role-based access control (assign team members specific roles)
4. ⏳ Activity audit log (track all changes, who changed what, when)
5. ⏳ Backup & restore (manual backups, scheduled auto-backups)
6. ⏳ Custom branding (white-label for resellers)
7. ⏳ Advanced security (SSO, IP whitelisting, device management)

---

## Tiếng Việt — Màn Hình Thêm

### Mục Đích

**Thêm** là trung tâm điều hướng phụ và cài đặt. Nó hiển thị:
- Thiết lập kinh doanh
- Tài liệu Thông Minh
- Xưởng AI
- Trung Tâm Tích Hợp
- Cài Đặt Tài Chính
- Hồ Sơ Người Dùng
- Thông Báo & Cài Đặt Quyền Riêng Tư
- Trợ Giúp & Hỗ Trợ
- Đăng Xuất

### Mục Tiêu Kinh Doanh

Giúp doanh nhân cấu hình Tổng Tài bằng cách:
1. Thiết lập thông tin kinh doanh cơ bản
2. Tích hợp với các kênh bán và công cụ
3. Quản lý nhóm và quyền
4. Truy cập các tính năng nâng cao
5. Nhận trợ giúp và hỗ trợ

(Xem phần tiếng Anh ở trên cho chi tiết đầy đủ)

---

**Version:** 1.0  
**Component Count:** 6 main components (menu items grouped by section)  
**API Calls:** 9 endpoints  
**Status:** ✅ SPECIFICATION COMPLETE  
**Documentation Complete:** All 12 screens specified
