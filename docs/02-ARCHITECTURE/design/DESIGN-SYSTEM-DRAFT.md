# Design System — Tổng Tài
## Hệ Thống Thiết Kế

Complete visual language and token reference for Tổng Tài product ecosystem.  
Ngôn ngữ hình ảnh hoàn chỉnh và tài liệu tham khảo token cho hệ sinh thái sản phẩm Tổng Tài.

**Extends:** DESIGN-TOKENS.md (foundation colors, typography base)  
**Complements:** COMPONENT-LIBRARY.md (component specifications)  
**Terminology:** TERMINOLOGY.md (consistent naming across all docs)

---

## Color Palette — Bảng Màu Sắc

### Domain Colors (Module Identity)

Each business module has a primary color for visual navigation and mental mapping.  
Mỗi mô-đun kinh doanh có một màu chính cho điều hướng hình ảnh và lập bản đồ tinh thần.

| Module | English | Tiếng Việt | Hex | Use Case | Trường Hợp Sử Dụng |
|---|---|---|---|---|---|
| **Producer** | Business Sourcing | Nguồn Hàng | `#10B981` | Opportunity discovery, supplier network | Khám phá cơ hội, mạng nhà cung cấp |
| **Inventory** | Product & Warehouse | Tồn Kho | `#F59E0B` | Stock management, alerts, pricing | Quản lý kho, cảnh báo, giá cả |
| **Consumer** | Customer Intelligence | Khách Hàng | `#3B82F6` | CRM, customer data, segments | CRM, dữ liệu khách hàng, phân đoạn |
| **Finance** | Accounting & Cash | Tài Chính | `#8B5CF6` | Revenue, expenses, profit, cash flow | Doanh thu, chi phí, lợi nhuận, dòng tiền |
| **Reports** | Analytics & Insights | Báo Cáo | `#6366F1` | KPIs, trends, dashboards | KPI, xu hướng, bảng điều khiển |
| **Business Journey** | Goal Orchestration | Hành Trình | `#FBBF24` | Progress, milestones, goals | Tiến độ, mốc, mục tiêu |
| **AI Copilot** | AI Intelligence | AI Tổng Tài | `#A78BFA` | Recommendations, alerts, guidance | Đề xuất, cảnh báo, hướng dẫn |
| **Document Intelligence** | Document Analysis | Phân Tích Tài Liệu | `#06B6D4` | Scanning, OCR, extraction | Quét, OCR, trích xuất |
| **Integration** | System Connectors | Tích Hợp | `#14B8A6` | APIs, webhooks, connectors | API, webhook, bộ kết nối |
| **Business Setup** | Configuration | Cài Đặt | `#6B7280` | Settings, admin, preferences | Cài đặt, quản trị, tùy chọn |

### Color Usage Rules — Quy Tắc Sử Dụng Màu

#### Principle: Domain-Driven Identity
**Rule:** Each screen tab uses its module's primary color for visual consistency.

| Element | Rule | Example |
|---|---|---|
| **Tab Underline** | Domain color | Producer tab = green underline |
| **Icon (active)** | Domain color, 24px | Producer icon = green when selected |
| **Progress Bar** | Domain color | Journey progress = gold bar |
| **Quick Action Button** | Domain color, primary variant | Producer "Add Opportunity" = green button |
| **Status Indicator** | Domain color dot/badge | Active opportunity = green dot |
| **Chip/Badge** | Domain color or semantic | "Arbitrage" chip in Producer = green |
| **Chart Accent** | Domain color | Revenue chart line = blue (Consumer context) |

**Example:**
```
Home Screen Navigation:
├─ Home Tab (Teal/Cyan) ← Home module
├─ Producer Tab (Green) ← Producer module
├─ Inventory Tab (Orange) ← Inventory module
├─ Consumer Tab (Blue) ← Consumer module
└─ More Tab (Gray) ← Secondary/Settings
```

### Semantic Colors

Semantic colors express meaning across modules. Use for status, feedback, alerts.  
Các màu ngữ nghĩa biểu lộ ý nghĩa trên các mô-đun. Sử dụng cho trạng thái, phản hồi, cảnh báo.

| Semantic | Hex | Usage | Sử Dụng |
|---|---|---|---|
| **Success** | `#10B981` | Completed, saved, success toast | Hoàn thành, lưu, thành công |
| **Warning** | `#F59E0B` | Alert, low stock, caution | Cảnh báo, tồn kho thấp, cân trọng |
| **Error** | `#EF4444` | Failed, destructive action, error toast | Thất bại, hành động xóa, lỗi |
| **Info** | `#3B82F6` | Information, helpful hint | Thông tin, gợi ý hữu ích |
| **Neutral** | `#6B7280` | Disabled, secondary, setup | Vô hiệu, phụ, cài đặt |

### Neutral/Achromatic Colors

Background, text, border colors that work across all modules.  
Các màu nền, văn bản, viền hoạt động trên tất cả các mô-đun.

| Element | Light Mode | Dark Mode | Hex Light | Hex Dark |
|---|---|---|---|---|
| **Background** | White | Dark Slate | `#FFFFFF` | `#111827` |
| **Surface Secondary** | Light Gray | Dark Blue-Gray | `#F9FAFB` | `#1F2937` |
| **Text Primary** | Dark Slate | Off-White | `#111827` | `#F9FAFB` |
| **Text Secondary** | Medium Gray | Light Gray | `#6B7280` | `#D1D5DB` |
| **Text Tertiary** | Light Gray | Dark Gray | `#9CA3AF` | `#6B7280` |
| **Border** | Light Gray | Dark Gray | `#E5E7EB` | `#374151` |
| **Divider** | Very Light Gray | Very Dark Gray | `#F3F4F6` | `#2D3748` |
| **Hover** | Very Light Gray | Slightly Lighter Dark | `#F3F4F6` | `#1F2937` |
| **Disabled** | Light Gray (60% opacity) | Gray (40% opacity) | `#D1D5DB` | `#6B7280` |

---

## Typography — Chữ

### Font Families

| Role | Family | Fallback | Use |
|---|---|---|---|
| **Headings** | System Font (SF Pro Display / Roboto) | -apple-system, sans-serif | Large titles, screen headers |
| **Body Text** | System Font (SF Pro Text / Roboto) | -apple-system, sans-serif | Normal reading text, labels |
| **Monospace** | SF Mono / Roboto Mono | monospace | Code snippets, prices, IDs |

**Implementation:**
```
iOS:        SF Pro Display (headings), SF Pro Text (body)
Android:    Roboto (both, system default)
Web:        -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif
```

### Type Scale — Cấp Độ Kiểu Chữ

| Scale | Size | Weight | Line-height | Letter-spacing | Usage | Sử Dụng |
|---|---|---|---|---|---|---|
| **Display** | 32px | 700 | 40px | -0.5px | Rare: major headings only | Hiếm: chỉ tiêu đề chính |
| **Heading 1** | 28px | 700 | 34px | -0.3px | Screen titles, module header | Tiêu đề màn hình, tiêu đề mô-đun |
| **Heading 2** | 24px | 600 | 32px | -0.2px | Section titles, card titles | Tiêu đề phần, tiêu đề thẻ |
| **Heading 3** | 20px | 600 | 28px | 0px | Subsection, strong label | Tiểu phần, nhãn mạnh |
| **Heading 4** | 16px | 600 | 24px | 0px | Small title, input label | Tiêu đề nhỏ, nhãn nhập |
| **Body** | 16px | 400 | 24px | 0px | Standard reading text | Văn bản đọc tiêu chuẩn |
| **Body Medium** | 16px | 500 | 24px | 0px | Emphasis in body (stronger than 400) | Nhấn mạnh trong nội dung |
| **Small** | 14px | 400 | 20px | 0px | Labels, secondary text, helper | Nhãn, văn bản phụ, trợ giúp |
| **Small Bold** | 14px | 600 | 20px | 0px | Strong label, badge | Nhãn mạnh, huy hiệu |
| **Caption** | 12px | 400 | 16px | 0.3px | Hints, timestamps, meta | Gợi ý, dấu thời gian, meta |
| **Caption Bold** | 12px | 600 | 16px | 0.3px | Badge text, emphasis | Văn bản huy hiệu, nhấn mạnh |

### Typography Usage Rules

| Context | Style | Example |
|---|---|---|
| **Screen Title** | Heading 1 (28px, 700) | "Producer Hub" |
| **Section Header** | Heading 2 (24px, 600) | "Opportunities", "Suppliers" |
| **Card Title** | Heading 3 (20px, 600) | Opportunity card title |
| **Input Label** | Heading 4 (16px, 600) | "Supplier Name" |
| **Body Text** | Body (16px, 400) | Paragraph descriptions |
| **Metric Value** | Heading 2 (24px, 600) | "18" opportunities |
| **Metric Unit** | Small (14px, 400) | "Opportunities" |
| **Button Label** | Small Bold (14px, 600) | "Add Product" |
| **Chip/Badge** | Caption Bold (12px, 600) | "Arbitrage" |
| **Helper Text** | Caption (12px, 400) | "Field is required" |
| **Timestamp** | Caption (12px, 400) | "Updated 2 hours ago" |

---

## Spacing System — Hệ Thống Khoảng Cách

### Spacing Scale — Thang Đo Khoảng Cách

Tất cả khoảng cách sử dụng bội số của 4px (4, 8, 12, 16, 20, 24, 32, 40, 48, 56, 64px).  
All spacing uses multiples of 4px (4, 8, 12, 16, 20, 24, 32, 40, 48, 56, 64px).

| Token | Value | Mnemonic | Usage | Sử Dụng |
|---|---|---|---|---|
| `$space-xs` | 4px | 1 unit | Tight spacing, micro interactions | Khoảng chặt, tương tác vi mô |
| `$space-sm` | 8px | 2 units | Padding inside components | Đệm bên trong thành phần |
| `$space-md` | 12px | 3 units | Vertical spacing between elements | Khoảng cách dọc giữa các phần tử |
| `$space-base` | 16px | 4 units | **Standard** — most common | **Tiêu chuẩn** — phổ biến nhất |
| `$space-lg` | 20px | 5 units | Large gap between sections | Khoảng cách lớn giữa các phần |
| `$space-xl` | 24px | 6 units | Section margins, card gaps | Lề phần, khoảng cách thẻ |
| `$space-2xl` | 32px | 8 units | Screen-level padding, top margin | Đệm cấp màn hình, lề trên cùng |
| `$space-3xl` | 40px | 10 units | Large section gap | Khoảng cách phần lớn |
| `$space-4xl` | 48px | 12 units | Major section separation | Tách biệt phần chính |

### Spacing Applications — Ứng Dụng Khoảng Cách

| Component | Usage | Example |
|---|---|---|
| **Screen Padding** | 16px sides | Card edge margin = 16px |
| **Card Padding** | 16px inside | Card content padding = 16px |
| **Button Height** | 44px (touch safe) | All buttons min-height = 44px |
| **Bottom Nav Height** | 56px + safe area | Navigation bar = 56px |
| **List Item Height** | 48px / 56px | Tappable row height |
| **Icon Size** | 24px (navigation), 16px (inline) | Tab icons = 24px, status icons = 16px |
| **Column Gap** | 16px or 12px | Space between grid columns |
| **Row Gap** | 12px or 16px | Space between list items |
| **Section Gap** | 24px or 32px | Major section separation |

---

## Border & Corner Radius

### Radius Scale — Thang Đo Bán Kính

| Token | Value | Usage | Sử Dụng |
|---|---|---|---|
| `$radius-none` | 0px | Sharp corners (rare) | Góc sắc (hiếm) |
| `$radius-sm` | 4px | Badges, chips, small buttons | Huy hiệu, chip, nút nhỏ |
| `$radius-md` | 8px | Buttons, input fields | Nút, trường nhập |
| `$radius-lg` | 12px | Cards, modals, larger components | Thẻ, modal, thành phần lớn hơn |
| `$radius-xl` | 16px | Large containers, featured cards | Vùng chứa lớn, thẻ nổi bật |
| `$radius-full` | 50% | Circles, avatars, pill buttons | Vòng tròn, đại diện, nút pill |

### Border — Viền

| Element | Thickness | Color | Usage |
|---|---|---|---|
| **Card Border** | 1px | `$color-border` (light/dark) | Card separation |
| **Input Border** | 1px | `$color-border` (light/dark) | Input container |
| **Input Focus** | 2px | Domain color | Active input state |
| **Button Border** | 1px (outline only) | Domain color | Secondary button |
| **Divider** | 1px | `$color-border` | Section separator |

---

## Elevation / Shadow

Shadows create depth and hierarchy. Use sparingly on mobile.  
Bóng tạo ra độ sâu và phân cấp. Sử dụng một cách hợp lý trên di động.

| Level | Shadow | Usage | Sử Dụng |
|---|---|---|---|
| **Elevation 0** | None | Flat surfaces (rare) | Bề mặt phẳng (hiếm) |
| **Elevation 1** | `0 1px 3px rgba(0,0,0,0.1)` | Cards, subtle lift | Thẻ, nâng lên tinh tế |
| **Elevation 2** | `0 4px 6px rgba(0,0,0,0.1)` | Hovered cards, floating action | Thẻ khi hover, hành động nổi |
| **Elevation 3** | `0 10px 15px rgba(0,0,0,0.1)` | Modals, dropdown menus | Modal, menu thả xuống |
| **Elevation 4** | `0 20px 25px rgba(0,0,0,0.1)` | Highest priority overlays | Phủ lớp ưu tiên cao nhất |

**Mobile Guideline:**
- Prefer elevation over heavy shadows on small screens
- Max 2-3 elevation levels in view at once
- Use color + position instead of shadow when possible

---

## Animation & Motion

### Duration / Timing — Thời Gian / Hẹn Giờ

| Token | Value | Usage | Sử Dụng |
|---|---|---|---|
| `$anim-fast` | 100ms | Micro interactions, opacity toggle | Tương tác vi mô, chuyển đổi độ mờ |
| `$anim-standard` | 300ms | **Default** — transitions, state change | **Mặc định** — chuyển tiếp, thay đổi trạng thái |
| `$anim-slow` | 500ms | Large container animations, page transition | Hoạt ảnh vùng chứa lớn, chuyển tiếp trang |
| `$anim-slowest` | 800ms | Rare: hero animations, splash screens | Hiếm: hoạt ảnh chính, màn hình splash |

### Easing Functions

| Function | Curve | Usage | Sử Dụng |
|---|---|---|---|
| **Linear** | `cubic-bezier(0, 0, 1, 1)` | Progress bars, loading | Thanh tiến độ, tải |
| **Ease In** | `cubic-bezier(0.4, 0, 1, 1)` | Fade out, shrink | Mờ dần, co lại |
| **Ease Out** | `cubic-bezier(0, 0, 0.2, 1)` | Fade in, expand, slide | Hiện lên, mở rộng, trượt |
| **Ease In Out** | `cubic-bezier(0.4, 0, 0.2, 1)` | **Default** — smooth transitions | **Mặc định** — chuyển tiếp mượt mà |
| **Custom Bounce** | `cubic-bezier(0.68, -0.55, 0.265, 1.55)` | Playful highlights (rare) | Nhấn mạnh vui nhộn (hiếm) |

### Animation Guidelines

| Interaction | Duration | Easing | Example |
|---|---|---|---|
| **Button Hover** | 100ms | Ease Out | Color + lift change |
| **Tab Switch** | 300ms | Ease In Out | Slide + fade content |
| **Modal Enter** | 300ms | Ease Out | Scale up + fade in |
| **Modal Exit** | 200ms | Ease In | Scale down + fade out |
| **Toast Appear** | 200ms | Ease Out | Slide + fade in |
| **Refresh Pull** | 400ms | Spring | Bounce at top |
| **Chart Draw** | 800ms | Linear | Animated bars/lines fill |
| **Loading Shimmer** | 1500ms | Linear | Infinite loop |

---

## Dark Mode — Chế Độ Tối

### Dark Mode Support

Tổng Tài supports automatic dark mode (system preference).  
Tổng Tài hỗ trợ chế độ tối tự động (tùy chọn hệ thống).

| Element | Light Mode | Dark Mode | Contrast |
|---|---|---|---|
| **Background** | `#FFFFFF` | `#111827` | 21:1 ✅ |
| **Text Primary** | `#111827` | `#F9FAFB` | 21:1 ✅ |
| **Text Secondary** | `#6B7280` | `#D1D5DB` | 7.3:1 ✅ |
| **Border** | `#E5E7EB` | `#374151` | 5.5:1 ✅ |
| **Hover** | `#F3F4F6` | `#1F2937` | Inverted lightness |

### Dark Mode Rules

- **Domain Colors:** Same hex value (works in both modes)
- **Text:** Auto-invert via theme (no hardcoded black/white)
- **Icons:** Inherit color from text color token
- **Images:** Optional dark overlay (10-20% black) in dark mode
- **Charts:** Line/bar colors remain domain color (high contrast)

### Implementation

```
Light Mode (default):
- Background: #FFFFFF
- Text: #111827
- Border: #E5E7EB

Dark Mode (system dark):
- Background: #111827
- Text: #F9FAFB
- Border: #374151
```

---

## Accessibility Standards

### Color Contrast

**WCAG AA Minimum Requirements:**
- **Text** (normal): 4.5:1 contrast ratio
- **Text** (large 18px+): 3:1 contrast ratio
- **UI Components** (borders, icons): 3:1 contrast ratio

**Guideline:** Always test with Contrast Checker before shipping.

### Touch Targets

**Minimum safe touch targets:**
- **Interactive elements:** 44px × 44px
- **Icons (actionable):** 24px × 24px minimum, with 16px padding around
- **Buttons:** 44px height minimum, 48-56px for navigation

**Mobile First:** Tổng Tài is Android-first; iOS follows same targets.

### Typography Accessibility

| Rule | Example |
|---|---|
| **No text smaller than 12px** | Use 12px minimum for readability |
| **Line-height ≥ 1.5** | Ensures spacing for dyslexic readers |
| **Font weight variance** | Use 400/500/600/700 (not 300, 800) |
| **Letter-spacing:** Avoid tight spacing | Use default or +0.3px |

### Icon Labels

- **Standalone icons:** Always include aria-label or visible text
- **Icon + text:** Icon should be decorative (aria-hidden) or semantic label
- **Never rely on color alone:** Use shape + color + text

---

## Component-Level Design Tokens

Specific token usage for common components (defined in COMPONENT-LIBRARY.md).

### Button Tokens

```
Padding:        $space-sm (8px) x $space-base (16px) → 12px x 16px
Height:         44px (touch safe)
Border Radius:  $radius-md (8px)
Font:           $typography-small-bold (14px, 600)
Transition:     200ms ease-out
Focus Ring:     2px domain color
```

### Card Tokens

```
Background:     $color-background (#FFFFFF)
Border:         1px solid $color-border
Border Radius:  $radius-lg (12px)
Padding:        $space-base (16px)
Shadow:         $elevation-1 (subtle)
Hover Shadow:   $elevation-2 (on interactive)
```

### Input Tokens

```
Height:         48px
Padding:        $space-md (12px) x $space-base (16px)
Border:         1px solid $color-border
Border Radius:  $radius-md (8px)
Font:           $typography-body (16px)
Focus Border:   2px solid domain-color
Error Border:   2px solid #EF4444
```

### Avatar Tokens

```
Size Options:   24px / 32px / 48px / 64px / 128px
Border Radius:  50% (circle)
Border:         Optional 2px #FFFFFF
Font:           $typography-caption-bold (initials)
Background:     Domain color or hash(initials)
```

---

## Design Token Reference File

**Location:** `DESIGN-TOKENS.md`  
**Status:** ✅ Locked  
**Maintenance:** Update here, sync to DESIGN-TOKENS.md weekly

---

## Color Palette Export

**For Figma, Sketch, XD:**

```
Producer Green:      #10B981
Inventory Orange:    #F59E0B
Consumer Blue:       #3B82F6
Finance Purple:      #8B5CF6
Reports Indigo:      #6366F1
Journey Gold:        #FBBF24
AI Copilot Violet:   #A78BFA
Document Cyan:       #06B6D4
Integration Teal:    #14B8A6
Setup Gray:          #6B7280

Success:             #10B981
Warning:             #F59E0B
Error:               #EF4444
Info:                #3B82F6

Light Background:    #FFFFFF
Dark Background:     #111827
```

---

## Related Documentation

- **Design Tokens (Foundation):** DESIGN-TOKENS.md
- **Component Specifications:** COMPONENT-LIBRARY.md
- **Terminology:** TERMINOLOGY.md
- **Information Architecture:** INFORMATION-ARCHITECTURE.md
- **UI/UX Concepts:** UI-UX-CONCEPT-INVENTORY.md

---

**Version:** 1.0  
**Date:** 2026-07-13  
**Status:** ✅ DRAFT (ready for design review)  
**Maintained By:** Claude Code (Developer Agent)  
**Next Review:** 2026-08-13

