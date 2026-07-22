# Component Library
## Thư Viện Thành Phần

Reusable UI components for Tổng Tài. Tái sử dụng các thành phần UI cho Tổng Tài.

**Source:** Extracted from UI/UX Concept Inventory (25 concept screens)  
**Bilingual Reference:** TERMINOLOGY.md (consistent naming)  
**Design Tokens:** DESIGN-TOKENS.md (colors, typography, spacing)

---

## 1. Card — Thẻ

**Purpose / Mục đích:**
General-purpose content container for metrics, products, opportunities, customers, suppliers.
Vùng chứa nội dung đa mục đích cho chỉ số, sản phẩm, cơ hội, khách hàng, nhà cung cấp.

**Variants:**
- **Default** — neutral background, subtle border
- **Metric Card** — icon + value + trend indicator + label
- **Opportunity Card** — image/icon + title + market + profit + score
- **Product Card** — image + SKU + price + stock status
- **Supplier Card** — avatar + name + rating + location + MOQ
- **Customer Card** — avatar + name + tier + LTV + order count
- **Elevated** — shadow, used for featured content
- **Actionable** — hover lift, tappable

**Props:**
| Prop | Type | Default | Example |
|---|---|---|---|
| backgroundColor | string | #FFFFFF (light) / #1F2937 (dark) | `#FFFFFF` |
| borderColor | string | #E5E7EB (light) / #374151 (dark) | `#E5E7EB` |
| borderRadius | number | 12px | `12` |
| padding | number | 16px | `16` |
| elevation | 0-4 | 1 | `2` |
| onTap | callback | — | navigate to detail |
| icon | widget | — | leading icon |
| title | string | — | card title |
| subtitle | string | — | secondary text |
| tag | string / list | — | `["Opportunity", "Arbitrage"]` |
| actionButton | widget | — | trailing action |

**Usage Examples:**
- **Metric Card** — SC-6 (Home: Producer card shows "18 Opportunities")
- **Opportunity Card** — SC-7, SC-13 (arbitrage/trend/cross-border with pricing)
- **Product Card** — SC-8 (Inventory product list with SKU, stock, price)
- **Supplier Card** — SC-7, SC-15 (supplier rating, location, capabilities)

**Accessibility:**
- Min height: 60px (touch target, avoid cramping)
- Icon + label always paired for meaning
- High contrast: text ≥ 4.5:1 WCAG AA
- Hover state clear: border highlight or lift shadow

**Design Tokens Used:**
```
background:   $color-background
border:       1px solid $color-border
borderRadius: $radius-large (12px)
padding:      $spacing-4 (16px)
shadow:       $elevation-1 or $elevation-2
```

---

## 2. Button — Nút

**Purpose / Mục đích:**
Trigger actions: navigate, submit, cancel, create, edit, delete, save.
Kích hoạt hành động: điều hướng, gửi, hủy, tạo, chỉnh sửa, xóa, lưu.

**Variants:**
- **Primary** — filled, branded color (domain-driven: green/orange/blue/purple)
- **Secondary** — outlined, same color as primary
- **Ghost** — text-only, minimal
- **Danger** — red background (delete, destructive)
- **Disabled** — grayed, no interaction
- **Loading** — spinner inside, disabled state
- **Icon Button** — icon-only, 24px or 32px
- **Pill Button** — very rounded (24px), often with icon left

**Props:**
| Prop | Type | Default | Example |
|---|---|---|---|
| variant | enum | "primary" | `"secondary"` |
| size | enum | "medium" | `"large"` / `"small"` |
| label | string | — | `"Add Product"` |
| icon | widget | — | `Icons.add` |
| iconPosition | enum | "left" | `"right"` |
| onPressed | callback | — | button action |
| isLoading | bool | false | `true` |
| isDisabled | bool | false | `true` |
| width | enum | "fill" | `"fixed"` (200px) |
| color | string | module color | `$producer-green` |

**Usage Examples:**
- **Primary Button** — SC-6 (Home: "Add Mission" or "Create Goal")
- **Secondary Button** — SC-12 (Business Journey: "Edit Step", "View Playbook")
- **Icon Button** — SC-7 (Producer: "Save" heart icon, "Share" icon)
- **Danger Button** — SC-8 (Inventory: "Delete Product")

**Accessibility:**
- Height: 44px minimum (touch target)
- Labels must be visible text, not just icon
- Clear focus state (outline or color change)
- Disabled state must be visually distinct

**Design Tokens Used:**
```
height:        $button-height (44px)
padding:       $spacing-3 (12px) $spacing-4 (16px)
borderRadius:  $radius-medium (8px)
fontSize:      $typography-button (14px, 600 weight)
color:         domain-specific ($producer-green, $inventory-orange, etc.)
```

---

## 3. Chip / Badge — Nhãn

**Purpose / Mục đích:**
Compact tag for status, category, AI insight, metric badge.
Nhãn nhỏ gọn cho trạng thái, danh mục, insight AI, huy hiệu chỉ số.

**Variants:**
- **Status Chip** — "Active", "Pending", "Completed", "Blocked", "At Risk"
- **Category Chip** — "Arbitrage", "Trend", "Cross-border", "New Supplier"
- **AI Badge** — "🧠 AI" or "AI Insight", violet/gradient background
- **Metric Badge** — "↑ 12%" (trend indicator)
- **Filled** — solid background (primary action)
- **Outlined** — border only (secondary category)
- **Removable** — with X icon (filter tag)

**Props:**
| Prop | Type | Default | Example |
|---|---|---|---|
| label | string | — | `"Opportunity"` |
| backgroundColor | string | domain color | `#10B981` (green) |
| textColor | string | white | `#FFFFFF` |
| icon | widget | — | `Icons.lightning` |
| onRemove | callback | — | filter removal |
| variant | enum | "filled" | `"outlined"` |
| size | enum | "medium" | `"small"` |

**Usage Examples:**
- **Status Chip** — SC-12 (Journey steps: "✓ Done", "⏳ In Progress", "⊘ Blocked")
- **Category Chip** — SC-7, SC-13 (Opportunity cards: "Arbitrage", "Trend", "Cross-border")
- **AI Badge** — SC-6, SC-14 (AI Copilot summary: "🧠 AI Insight")
- **Metric Badge** — SC-7, SC-16 (trend: "↑ 18%" green, "↓ 5%" red)

**Accessibility:**
- Min height: 24px (adequate padding around text)
- Sufficient contrast on background
- Text label always present (not icon-only for semantic meaning)

**Design Tokens Used:**
```
backgroundColor: domain-driven or status color
textColor:       #FFFFFF or $text-primary
padding:         $spacing-1 (4px) $spacing-2 (8px)
borderRadius:    $radius-small (4px)
fontSize:        $typography-caption (12px, 600 weight)
```

---

## 4. Input — Trường Nhập

**Purpose / Mục đích:**
Text entry, search, date picker, dropdown, number input.
Nhập văn bản, tìm kiếm, chọn ngày, danh sách thả xuống, nhập số.

**Variants:**
- **Text Input** — single-line text field
- **Search Input** — with search icon, clear button
- **Number Input** — keyboard: numeric, spinner buttons
- **Date Input** — date picker (calendar popup)
- **Dropdown** — select from predefined list
- **Multi-select** — checkbox list or dropdown with multiple
- **Text Area** — multi-line, resizable
- **Read-only** — display value without edit capability
- **Error State** — red border, error message below
- **Focused State** — blue/domain color border, hint text

**Props:**
| Prop | Type | Default | Example |
|---|---|---|---|
| label | string | — | `"Supplier Name"` |
| placeholder | string | — | `"Enter supplier name..."` |
| value | string | "" | `"XYZ Import Co."` |
| onChanged | callback | — | input handler |
| onSubmitted | callback | — | enter key handler |
| inputType | enum | "text" | `"number"` / `"email"` / `"date"` |
| error | string | null | `"Name is required"` |
| hint | string | — | `"Required field"` |
| icon | widget | — | `Icons.search` |
| prefix | string | — | `"$"` (for price) |
| suffix | string | — | `"kg"` (for weight) |
| enabled | bool | true | `false` (disabled) |
| maxLength | number | — | `50` |
| minLines / maxLines | number | 1 | `3` (textarea) |

**Usage Examples:**
- **Text Input** — SC-6, SC-14 (Chat: "Ask AI..." search bar)
- **Search Input** — SC-7, SC-8 (Producer, Inventory: search suppliers/products)
- **Date Input** — SC-12 (Business Journey: select milestone dates)
- **Dropdown** — SC-8, SC-9 (Inventory: filter by category; Consumer: filter by segment)
- **Number Input** — SC-16 (Product Detail: adjust quantity, price)

**Accessibility:**
- Height: 48px minimum
- Label always visible above input (not placeholder-only)
- Focus ring: 2px, domain color
- Error message linked to input (aria-describedby)

**Design Tokens Used:**
```
height:        $input-height (48px)
padding:       $spacing-3 (12px) $spacing-4 (16px)
borderRadius:  $radius-medium (8px)
border:        1px solid $color-border
fontSize:      $typography-body (16px)
focusBorder:   2px solid $domain-color
errorBorder:   2px solid #EF4444
```

---

## 5. Avatar — Đại Diện

**Purpose / Mục đích:**
Display user, business, customer, or supplier profile picture.
Hiển thị ảnh hồ sơ của người dùng, doanh nghiệp, khách hàng, hoặc nhà cung cấp.

**Variants:**
- **User Avatar** — circular, initials fallback
- **Business Avatar** — square, logo fallback
- **Status Indicator** — green dot (online), gray (offline)
- **Badge Overlay** — small icon on corner (role, certification)
- **Sized** — 24px, 32px, 48px, 64px, 128px
- **Placeholder** — colored background + initials when no image

**Props:**
| Prop | Type | Default | Example |
|---|---|---|---|
| imageUrl | string | — | `"https://...jpg"` |
| initials | string | "?" | `"AB"` (John Anderson) |
| backgroundColor | string | domain color | `#10B981` |
| size | enum | 48px | `24` / `32` / `64` |
| borderColor | string | none | `#FFFFFF` |
| borderWidth | number | 0 | `2` (profile highlight) |
| badge | widget | — | certification icon |
| onTap | callback | — | navigate to profile |

**Usage Examples:**
- **User Avatar** — SC-6 (Home: AI Copilot greeting with fox mascot)
- **Supplier Avatar** — SC-15 (Supplier Detail: supplier logo + name)
- **Customer Avatar** — SC-9 (Consumer: customer profile photos in CRM list)
- **Status Indicator** — SC-14 (AI Copilot: online indicator)

**Accessibility:**
- Min size: 24px
- Sufficient contrast between initials and background
- If linked, proper focus state

**Design Tokens Used:**
```
size:          24px / 32px / 48px / 64px / 128px
borderRadius:  50% (circle) or $radius-large (12px, square)
backgroundColor: $domain-color or initials-hash
border:        optional 2px $color-white
```

---

## 6. Chart — Biểu Đồ

**Purpose / Mục đích:**
Visualize metrics, trends, distribution, performance.
Trực quan hóa chỉ số, xu hướng, phân phối, hiệu suất.

**Variants:**
- **Line Chart** — trend over time (revenue, traffic, ROI)
- **Area Chart** — stacked area for composition (channel revenue breakdown)
- **Bar Chart** — categorical comparison (sales by region, product)
- **Pie Chart** — composition, percentage of total (inventory by category)
- **Combo Chart** — line + bar (profit + volume)
- **Sparkline** — mini inline chart (metric card trend)
- **Progress Chart** — circular progress (journey completion %)
- **Heatmap** — grid with color intensity (sales by day/region)

**Props:**
| Prop | Type | Default | Example |
|---|---|---|---|
| data | list | — | `[{x: "Jan", y: 1200}, ...]` |
| title | string | — | `"Monthly Revenue"` |
| xAxisLabel | string | — | `"Month"` |
| yAxisLabel | string | — | `"Revenue (VND)"` |
| color | string / list | domain color | `#10B981` or `[#10B981, #F59E0B]` |
| height | number | 200 | `300` |
| showLegend | bool | true | `false` |
| showGrid | bool | true | `false` |
| animationDuration | ms | 300 | `600` |
| tooltip | bool | true | show on hover |

**Usage Examples:**
- **Line Chart** — SC-11 (Reports: revenue trend, KPI trend)
- **Area Chart** — SC-16 (Product Detail: sales by channel over time)
- **Pie Chart** — SC-8 (Inventory: stock distribution by warehouse)
- **Bar Chart** — SC-11, SC-16 (channel sales comparison)
- **Sparkline** — SC-6 (Home: small trend indicator on metric card)
- **Progress Circle** — SC-12 (Business Journey: 80% goal completion)

**Accessibility:**
- Always provide data table alternative or download CSV
- Color not sole differentiator (use patterns, labels)
- Sufficient contrast between series colors
- Legend or label for each series

**Design Tokens Used:**
```
color:        domain-driven ($producer-green, etc.) or semantic ($success, $warning)
strokeWidth:  2px (line chart)
height:       200px / 300px / 400px
animationDuration: $animation-standard (300ms)
```

---

## 7. Table — Bảng

**Purpose / Mục đích:**
Display structured data: products, transactions, customers, suppliers.
Hiển thị dữ liệu có cấu trúc: sản phẩm, giao dịch, khách hàng, nhà cung cấp.

**Variants:**
- **Sortable Table** — tap column header to sort
- **Filterable Table** — filter row above headers
- **Selectable Table** — checkbox for bulk actions
- **Expanded Row** — tap to show detail row
- **Sticky Header** — header stays on scroll
- **Striped** — alternate row colors for readability
- **Compact** — dense rows (12px padding)
- **Spacious** — loose rows (20px padding)

**Props:**
| Prop | Type | Default | Example |
|---|---|---|---|
| columns | list | — | `[{label: "SKU", key: "sku", width: 80}, ...]` |
| rows | list | — | data rows |
| sortable | bool | true | false (disable) |
| filterable | bool | false | true (show filter) |
| selectable | bool | false | true (checkbox column) |
| onRowTap | callback | — | row selection |
| onSort | callback | — | sort handler |
| headerBackgroundColor | string | $domain-color | colored headers |
| stickyHeader | bool | false | true |
| minRowHeight | number | 48 | 56 |

**Usage Examples:**
- **Product Table** — SC-8 (Inventory: product list with SKU, stock, price, status)
- **Transaction Table** — SC-10 (Finance: revenue/expense transactions)
- **Supplier Table** — SC-7, SC-15 (Supplier list, products list)
- **Customer Table** — SC-9 (Consumer: customer order history)

**Accessibility:**
- Headers must be semantic `<thead>` or role="columnheader"
- Focus must be manageable (arrow keys for row nav)
- Sort direction icon must be clear (↑/↓)
- Min row height: 48px for touch

**Design Tokens Used:**
```
headerBackground:  $domain-color
headerTextColor:   #FFFFFF
rowHeight:         48px / 56px
borderBottom:      1px solid $color-border
padding:           $spacing-3 (12px) $spacing-4 (16px)
fontSize:          $typography-small (14px)
```

---

## 8. Modal / Dialog — Cửa Sổ Bật Lên

**Purpose / Mục đích:**
Overlay for critical actions: confirm delete, create record, detailed forms.
Lớp phủ cho các hành động quan trọng: xác nhận xóa, tạo bản ghi, biểu mẫu chi tiết.

**Variants:**
- **Alert Dialog** — single choice (OK, Close)
- **Confirmation Dialog** — two choices (Cancel, Confirm)
- **Bottom Sheet** — slides up from bottom, full-width, optimized for mobile
- **Full Screen Modal** — takes entire screen (complex form)
- **Centered Dialog** — small, medium, large size options
- **Loading Dialog** — spinner, "Processing..."
- **Error Dialog** — red accent, error icon, recovery action

**Props:**
| Prop | Type | Default | Example |
|---|---|---|---|
| title | string | — | `"Delete Product?"` |
| message | string | — | `"This action cannot be undone."` |
| primaryButton | widget | — | confirm button |
| secondaryButton | widget | — | cancel button |
| dismissible | bool | true | false (force choice) |
| backgroundColor | string | #FFFFFF | dialog bg |
| borderRadius | number | 12 | rounded corners |
| maxWidth | number | 400 | dialog width |
| position | enum | "center" | `"bottom"` |

**Usage Examples:**
- **Confirmation Dialog** — SC-8 (delete product confirmation)
- **Bottom Sheet** — SC-6, SC-7 (create opportunity, add product, add supplier)
- **Alert Dialog** — SC-14 (AI alert: "Would you like to update this?")
- **Full Screen Modal** — SC-16 (Edit product detail with many fields)

**Accessibility:**
- Focus trap: focus stays inside modal
- Dismiss only with button, not backdrop (unless explicitly shown)
- Heading must be first focusable element
- Backdrop must be visible (not transparent)

**Design Tokens Used:**
```
backgroundColor:  #FFFFFF / #1F2937 (dark)
borderRadius:     $radius-large (12px)
boxShadow:        $elevation-4 (high elevation)
padding:          $spacing-6 (24px) / $spacing-8 (32px)
backdropColor:    rgba(0, 0, 0, 0.5)
```

---

## 9. Toast / Alert — Thông Báo Nhanh

**Purpose / Mục đích:**
Non-blocking notification: success, error, warning, info.
Thông báo không chặn: thành công, lỗi, cảnh báo, thông tin.

**Variants:**
- **Success Toast** — green, checkmark icon ("Product saved successfully")
- **Error Toast** — red, X icon ("Unable to connect. Try again?")
- **Warning Toast** — orange, alert icon ("Low stock warning")
- **Info Toast** — blue, info icon ("3 new opportunities found")
- **Action Toast** — with action button ("Undo", "Retry")
- **Duration** — auto-dismiss (3-5s) or persistent

**Props:**
| Prop | Type | Default | Example |
|---|---|---|---|
| message | string | — | `"Product added"` |
| type | enum | "info" | `"success"` / `"error"` / `"warning"` |
| duration | ms | 3000 | 0 (persistent) |
| action | widget | — | action button |
| icon | widget | — | custom icon |
| position | enum | "bottom" | `"top"` |

**Usage Examples:**
- **Success Toast** — SC-6 (Mission added), SC-8 (Product saved)
- **Error Toast** — SC-7 (Supplier load failed), SC-10 (Transaction failed)
- **Warning Toast** — SC-8 (Low stock alert)
- **Info Toast** — SC-6 (Daily opportunities summary)

**Accessibility:**
- Announce to screen readers (role="alert" or role="status")
- High contrast colors (WCAG AAA)
- If dismissible, clear close button

**Design Tokens Used:**
```
successColor:   #10B981
errorColor:     #EF4444
warningColor:   #F59E0B
infoColor:      #3B82F6
padding:        $spacing-4 (16px)
borderRadius:   $radius-large (12px)
duration:       3000ms (auto) or 0 (persistent)
```

---

## 10. Skeleton / Loading — Trạng Thái Tải

**Purpose / Mục đích:**
Placeholder during data fetch to prevent layout shift.
Giữ chỗ trong khi tải dữ liệu để ngăn chặn sự thay đổi bố cục.

**Variants:**
- **Card Skeleton** — placeholder card shape with shimmer
- **List Skeleton** — 3-5 skeleton rows
- **Text Skeleton** — 1-3 line placeholders
- **Avatar Skeleton** — circular gray placeholder
- **Chart Skeleton** — bar/line chart outline
- **Shimmer Effect** — animated gradient overlay
- **Pulse Effect** — fade in/out animation

**Props:**
| Prop | Type | Default | Example |
|---|---|---|---|
| type | enum | "card" | `"list"` / `"text"` / `"avatar"` |
| count | number | 1 | `5` (for list) |
| width | number | 100% | `200` (in pixels) |
| height | number | 100 | `300` (in pixels) |
| borderRadius | number | 8 | custom rounding |
| shimmer | bool | true | animated loading |
| duration | ms | 1500 | animation speed |

**Usage Examples:**
- **Card Skeleton** — SC-6 (Home: loading module cards)
- **List Skeleton** — SC-7, SC-8 (loading product/supplier list)
- **Chart Skeleton** — SC-11, SC-16 (loading analytics chart)
- **Shimmer** — all screens during network fetch

**Accessibility:**
- Must have aria-hidden="true" (it's a placeholder, not content)
- Avoid confusing with actual data (clear visual difference)
- Remove when real content loads (no 0.1s flash)

**Design Tokens Used:**
```
backgroundColor:  $color-hover (light gray)
shimmerColor:     $color-border
shimmerDuration:  1500ms
shimmerOpacity:   0.5
```

---

## 11. Icon — Biểu Tượng

**Purpose / Mục đích:**
Visual identification for actions, navigation, status, modules.
Nhận dạng hình ảnh cho hành động, điều hướng, trạng thái, mô-đun.

**Variants:**
- **Navigation Icons** — home, producer, inventory, consumer, more (24px, bottom nav)
- **Action Icons** — add, edit, delete, save, share, star, search (24px)
- **Status Icons** — check, close, warning, info, clock, flag (16px, inline)
- **Module Icons** — green (producer), orange (inventory), blue (consumer), purple (finance)
- **Filled / Outline** — solid or stroked variants
- **Sizes** — 16px, 24px, 32px, 48px

**Props:**
| Prop | Type | Default | Example |
|---|---|---|---|
| name | string | — | `"add"` |
| size | number | 24 | `16` / `32` / `48` |
| color | string | #111827 | `$producer-green` |
| semanticColor | bool | false | true (auto green/red) |
| onTap | callback | — | action handler |

**Usage Examples:**
- **Navigation Icons** — SC-6 (bottom bar: home, producer, inventory, consumer, more)
- **Action Icons** — SC-7, SC-8 (add, edit, delete, favorite)
- **Status Icons** — SC-12 (journey steps: ✓, ⏳, ⊘)
- **Module Icons** — SC-6, SC-14 (color-coded by domain)

**Accessibility:**
- If standalone (no text label), must have aria-label
- Semantic icons (trash = delete) can use color meaning
- Sufficient contrast: 3:1 minimum

**Design Tokens Used:**
```
size:        16px / 24px / 32px / 48px
color:       domain-specific or $text-primary
opacity:     1.0 (normal) / 0.5 (disabled)
```

---

## 12. Tab Bar — Thanh Tab

**Purpose / Mục đích:**
Switch between sections within a screen: Overview, Details, Analytics.
Chuyển đổi giữa các phần trong một màn hình: Tổng quan, Chi tiết, Phân tích.

**Variants:**
- **Horizontal Tab Bar** — underline indicator (default)
- **Vertical Tab Bar** — left-aligned sidebar tabs
- **Scrollable Tabs** — many tabs, swipe to scroll
- **Centered Tabs** — 3-4 tabs centered (module picker)
- **Icon + Label Tabs** — icon above label (mobile optimized)
- **Icon-Only Tabs** — no label (space constrained)
- **Segmented Control** — 2-3 toggle options

**Props:**
| Prop | Type | Default | Example |
|---|---|---|---|
| tabs | list | — | `[{label: "Overview", icon: Icons.info}, ...]` |
| activeIndex | int | 0 | current selection |
| onTabChanged | callback | — | tab switch handler |
| backgroundColor | string | transparent | `#FFFFFF` |
| indicatorColor | string | domain color | auto-select |
| scrollable | bool | false | true (many tabs) |
| indicatorStyle | enum | "underline" | `"background"` |
| isScrollable | bool | false | true |
| labelStyle | enum | "text" | `"icon"` |

**Usage Examples:**
- **Horizontal Underline** — SC-7, SC-8, SC-9, SC-14 (module tab: Overview, Details, Analytics)
- **Scrollable Tabs** — SC-8 (Inventory: Products, Categories, SKU, Warehouse, Pricing, Documents)
- **Icon Tabs** — SC-6, SC-7 (module bottom navigation: 5 color-coded tabs)
- **Vertical Tabs** — SC-15, SC-16 (detail screen sidebar tabs)

**Accessibility:**
- Focus must move between tabs with arrow keys
- Active tab has aria-selected="true"
- Indicator must be visible (not color-only)

**Design Tokens Used:**
```
indicatorColor:   $domain-color (auto per module)
indicatorHeight:  3px (underline) or full height
padding:          $spacing-4 (16px)
fontSize:         $typography-body (16px)
activeWeight:     600
inactiveWeight:   400
```

---

## 13. Bottom Navigation — Thanh Điều Hướng Dưới

**Purpose / Mục đích:**
Primary navigation: Home, Producer, Inventory, Consumer, More.
Điều hướng chính: Trang Chủ, Nguồn Hàng, Tồn Kho, Khách Hàng, Thêm.

**Variants:**
- **5-Tab Bottom Nav** — standard layout (home, producer, inventory, consumer, more)
- **Badge Indicator** — red dot for unread (notifications, new opportunities)
- **Icon + Label** — both visible below nav (recommended ≤5 tabs)
- **Icon-Only** — space-constrained (rare)
- **Active State** — bold icon, colored, label visible
- **Inactive State** — gray icon, dim label

**Props:**
| Prop | Type | Default | Example |
|---|---|---|---|
| items | list | — | `[{icon, label, badge}, ...]` |
| activeIndex | int | 0 | current tab |
| onItemTapped | callback | — | navigation handler |
| backgroundColor | string | #FFFFFF | nav bg |
| iconSize | number | 24 | icon size |
| showLabels | bool | true | show text labels |
| itemColor | string | #6B7280 | inactive color |
| activeItemColor | string | $domain-color | active color |
| elevation | number | 2 | shadow |

**Usage Examples:**
- **5-Tab Bottom Nav** — SC-6 (Home: Home, Producer, Inventory, Consumer, More) in all screens
- **Badge Indicator** — SC-7 (Producer: "12" opportunity count on tab badge)
- **Module Colors** — each tab uses its domain color when active

**Accessibility:**
- Height: min 56px (touch safe)
- Tab spacing: min 48px between centers
- Active tab announcement (screen reader)
- Icon + label always together (not icon-only)

**Design Tokens Used:**
```
backgroundColor:    #FFFFFF / #1F2937
height:             56px + safe-area (iOS)
iconSize:           24px
activeForeground:   $domain-color
inactiveForeground: $text-secondary
elevation:          $elevation-2
```

---

## 14. Divider — Đường Phân Cách

**Purpose / Mục đích:**
Visual separation between sections, lists, content groups.
Phân tách hình ảnh giữa các phần, danh sách, nhóm nội dung.

**Variants:**
- **Horizontal** — full-width or inset
- **Vertical** — column separator (rarely used on mobile)
- **Colored** — domain color accent
- **Dotted / Dashed** — alternative styles
- **With Text** — label in center ("or", "and", "continue")
- **Subtle** — light gray (default)
- **Prominent** — darker or colored

**Props:**
| Prop | Type | Default | Example |
|---|---|---|---|
| orientation | enum | "horizontal" | `"vertical"` |
| thickness | number | 1 | `2` |
| color | string | #E5E7EB | `$domain-color` |
| indent | number | 0 | `16` (inset left/right) |
| endIndent | number | 0 | `16` (right inset) |
| height | number | 1 | `24` (vertical spacing) |
| label | string | — | `"or"` |

**Usage Examples:**
- **Horizontal Divider** — SC-8 (between inventory sections)
- **Inset Divider** — SC-9 (between customer list items)
- **Colored Divider** — SC-7 (accent color per module)

**Accessibility:**
- Decorative dividers: aria-hidden="true"
- Semantic divider with label: use role="separator"

**Design Tokens Used:**
```
color:      $color-border
thickness:  1px (subtle) or 2px (prominent)
height:     $spacing-4 (horizontal spacing)
```

---

## 15. Progress Bar — Thanh Tiến Độ

**Purpose / Mục đích:**
Show completion percentage: journey goal, task, file upload, sync.
Hiển thị phần trăm hoàn thành: mục tiêu hành trình, tác vụ, tải tệp, đồng bộ.

**Variants:**
- **Linear Progress** — horizontal bar (0-100%)
- **Circular Progress** — donut chart (journey goal 80%)
- **Determinate** — known progress (50% complete)
- **Indeterminate** — unknown duration (loading)
- **Animated** — smooth transition
- **Colored** — domain color or semantic (success/warning/error)
- **With Label** — percentage text inside or beside
- **Segmented** — step-based progress (step 3 of 8)

**Props:**
| Prop | Type | Default | Example |
|---|---|---|---|
| progress | float | 0.0 | `0.80` (80%) |
| isIndeterminate | bool | false | `true` |
| color | string | domain color | `#10B981` |
| backgroundColor | string | #E5E7EB | `#F3F4F6` |
| height | number | 4 | `8` (thicker bar) |
| borderRadius | number | 2 | `8` (rounded ends) |
| showLabel | bool | false | true (show %) |
| animationDuration | ms | 500 | `300` |
| striped | bool | false | true (animated stripes) |

**Usage Examples:**
- **Circular Progress** — SC-12 (Business Journey: 80% goal completion)
- **Linear Progress** — SC-6 (Home: journey progress bar)
- **Segmented Progress** — SC-12 (Journey: step 3 of 8)
- **Indeterminate** — SC-6, SC-7 (data loading)

**Accessibility:**
- Must include aria-valuenow, aria-valuemin, aria-valuemax
- Label must be visible (not color-only)
- High contrast: background vs bar color

**Design Tokens Used:**
```
progressColor:      $domain-color
backgroundColor:    #E5E7EB / #F3F4F6
height:             4px / 8px
borderRadius:       $radius-full
animationDuration:  $animation-standard (300ms)
```

---

## 16. Switch / Toggle — Công Tắc

**Purpose / Mục đích:**
Binary choice: on/off, enable/disable, yes/no.
Lựa chọn nhị phân: bật/tắt, bật/vô hiệu, có/không.

**Variants:**
- **Toggle Switch** — on/off indicator
- **Compact Switch** — small form (settings)
- **Labeled Switch** — label on left or right
- **Color-Coded** — green (on), gray (off)
- **Disabled State** — grayed, no interaction

**Props:**
| Prop | Type | Default | Example |
|---|---|---|---|
| value | bool | false | `true` (on) |
| onChanged | callback | — | toggle handler |
| label | string | — | `"Enable AI Insights"` |
| labelPosition | enum | "right" | `"left"` |
| activeColor | string | $domain-color | custom on-color |
| inactiveColor | string | #D1D5DB | custom off-color |
| enabled | bool | true | `false` (disabled) |

**Usage Examples:**
- **Settings Toggle** — (Settings screen, not shown in concepts: "Dark mode", "Push notifications")
- **Feature Toggle** — (More: "Enable auto-import", "AI recommendations")

**Accessibility:**
- Must have aria-label or associated label
- Keyboard: Space or Enter to toggle
- Clear visual difference between on/off
- Min height: 44px (touch target)

**Design Tokens Used:**
```
activeColor:      $domain-color
inactiveColor:    #D1D5DB
toggleSize:       20px diameter
trackHeight:      24px
animationDuration: $animation-fast (200ms)
```

---

## 17. Rating Display — Hiển Thị Đánh Giá

**Purpose / Mục đích:**
Show rating (stars), review count, reputation breakdown.
Hiển thị đánh giá (sao), số lượng bài đánh giá, phân tích danh tiếng.

**Variants:**
- **Star Rating** — 1-5 stars (filled, half-filled, empty)
- **With Count** — "4.5 ⭐ (234 reviews)"
- **Reputation Breakdown** — bar chart: 5⭐ 60%, 4⭐ 25%, 3⭐ 10%, 2⭐ 5%, 1⭐ 0%
- **Interactive** — tap to rate (rare on mobile, read-only common)
- **Read-Only** — display only, no interaction

**Props:**
| Prop | Type | Default | Example |
|---|---|---|---|
| rating | float | 0 | `4.5` |
| maxRating | int | 5 | `5` |
| reviewCount | int | 0 | `234` |
| onRatingChanged | callback | — | (if interactive) |
| interactive | bool | false | `true` |
| starSize | number | 16 | `24` |
| color | string | #FBBF24 | gold/amber |
| breakdown | list | — | `[{stars: 5, count: 60}, ...]` |

**Usage Examples:**
- **Star + Count** — SC-7, SC-15 (Supplier rating: "4.8 ⭐ (127 reviews)")
- **Reputation Breakdown** — SC-15 (Supplier Detail: 5-star distribution chart)
- **Review Count** — SC-9 (Customer: "3.2 ⭐ (12 reviews)")

**Accessibility:**
- Stars must be text: "4.5 out of 5 stars"
- Not icon-only (no meaning without label)
- Color-blind safe: shape + number + text

**Design Tokens Used:**
```
starColor:     #FBBF24 (gold/amber)
emptyColor:    #D1D5DB (gray)
starSize:      16px / 24px
spacing:       $spacing-1 (4px) between stars
```

---

## 18. Trend Indicator — Chỉ Số Xu Hướng

**Purpose / Mục đích:**
Show direction and magnitude: ↑ 12%, ↓ 5%, → 0%.
Hiển thị hướng và độ lớn: ↑ 12%, ↓ 5%, → 0%.

**Variants:**
- **Up Trend** — green arrow, positive percentage
- **Down Trend** — red arrow, negative percentage
- **Neutral Trend** — gray arrow, 0%
- **Inline** — small badge (metric card)
- **Standalone** — prominent display (KPI)
- **With Label** — "Revenue ↑ 18% vs last month"

**Props:**
| Prop | Type | Default | Example |
|---|---|---|---|
| value | float | 0 | `12.5` (percentage) |
| showPercent | bool | true | show % symbol |
| showArrow | bool | true | show ↑/↓ |
| color | string | auto | green/red/gray |
| size | enum | "medium" | `"large"` / `"small"` |
| label | string | — | `"vs last month"` |

**Usage Examples:**
- **Metric Trend** — SC-6, SC-7, SC-16 (card badges: "↑ 18%", "↓ 5%")
- **KPI Trend** — SC-11 (Reports: revenue trend "↑ 23% vs Q2")
- **Opportunity Score** — SC-13 (Opportunity card profit trend)

**Accessibility:**
- Arrow + percentage + label all text (no icon-only)
- Color + symbol for meaning (red-down, green-up)

**Design Tokens Used:**
```
upColor:      #10B981 (green)
downColor:    #EF4444 (red)
neutralColor: #6B7280 (gray)
fontSize:     $typography-small or $typography-caption
```

---

## 19. List Item — Mục Danh Sách

**Purpose / Mục đích:**
Reusable row for lists: products, customers, suppliers, transactions.
Hàng tái sử dụng cho danh sách: sản phẩm, khách hàng, nhà cung cấp, giao dịch.

**Variants:**
- **Avatar + Title + Subtitle** — standard list item
- **Avatar + Title + Metadata** — with badges, counts
- **With Trailing Icon** — arrow, button, menu
- **Selectable** — checkbox or radio button
- **Disabled** — grayed state
- **Divider** — separator line below
- **Swipeable** — tap to reveal actions (delete, edit)

**Props:**
| Prop | Type | Default | Example |
|---|---|---|---|
| avatar | widget | — | user/product image |
| title | string | — | primary text |
| subtitle | string | — | secondary text |
| metadata | list | — | `["SKU: 12345", "Stock: 50"]` |
| trailing | widget | — | icon, badge, menu |
| onTap | callback | — | list item action |
| divider | bool | true | show line below |
| trailing | widget | — | action button/icon |

**Usage Examples:**
- **Product List** — SC-8 (Inventory: product rows with SKU, stock, price)
- **Supplier List** — SC-7, SC-15 (suppliers with rating, location)
- **Customer List** — SC-9 (customers with tier, LTV, order count)
- **Transaction List** — SC-10 (revenue/expense rows with date, amount, category)

**Accessibility:**
- Height: min 48px (touch target)
- Title + metadata always visible (not truncated)
- If selectable, checkbox clearly visible

**Design Tokens Used:**
```
height:          48px / 56px
padding:         $spacing-3 (12px) $spacing-4 (16px)
avatar:          32px / 48px
divider:         1px solid $color-border
hover:           background $color-hover
```

---

## 20. Metric Card — Thẻ Chỉ Số

**Purpose / Mục đích:**
Display KPI: value, trend, status, description.
Hiển thị KPI: giá trị, xu hướng, trạng thái, mô tả.

**Variants:**
- **Vertical Layout** — icon top, value center, trend bottom
- **Horizontal Layout** — icon left, value + trend right
- **Colorful** — domain-colored background
- **Minimal** — white background, icon accent only
- **Actionable** — tappable to detail view
- **Large** — featured KPI (home screen)
- **Small** — compact KPI (grid layout)

**Props:**
| Prop | Type | Default | Example |
|---|---|---|---|
| icon | widget | — | module icon |
| value | string | — | `"18"` |
| unit | string | — | `"Opportunities"` |
| trend | float | — | `0.12` (12% up) |
| trendLabel | string | — | `"vs last week"` |
| description | string | — | `"New suppliers found"` |
| color | string | domain color | `#10B981` |
| backgroundColor | string | domain color opacity 0.1 | `#F0FDF4` |
| onTap | callback | — | navigate to detail |

**Usage Examples:**
- **Module Cards** — SC-6 (Home: 4 cards for Producer, Inventory, Consumer, Business)
- **KPI Cards** — SC-11 (Reports: Revenue, Profit, Margin, etc.)
- **Metric Badge** — SC-7 (Producer: opportunity count "18" with trend)

**Accessibility:**
- Value + unit always together (not icon-only)
- High contrast on colored background
- Tappable area: 48x48px minimum

**Design Tokens Used:**
```
background:       $domain-color with 0.1 opacity
textColor:        $domain-color (value), $text-secondary (unit)
icon:             24px / 32px in domain color
value:            $typography-heading-2 (24px, 600 weight)
trend:            green (up) or red (down), $typography-caption
padding:          $spacing-4 (16px)
borderRadius:     $radius-large (12px)
```

---

## Cross-Component Usage Guide

### Example: Home Screen (SC-6)
```
Container (Full Screen)
├─ AppBar (greeting + menu)
├─ Metric Card (4 cards per row or 2x2 grid)
│  └ Producer, Inventory, Consumer, Business Journey
├─ Section Title ("Mission Today")
├─ Card (Opportunity)
│  ├─ Chip ("Arbitrage")
│  ├─ Title + Profit + Trend
│  └─ Button ("View")
├─ Section Title ("Business Summary")
└─ Chart (Line or Pie)
```

### Example: Opportunity Card (SC-7, SC-13)
```
Card
├─ Avatar or Image (product photo)
├─ Row (Title, Chips)
│  ├─ Chip ("Arbitrage" or "Trend" or "Cross-border")
│  └─ Chip (Category)
├─ Row (Metric: Profit + Trend Indicator)
├─ Row (Rating + Review Count)
└─ Button Row
   ├─ Button.Ghost ("Share")
   ├─ Button.Ghost ("Save")
   └─ Button.Primary ("View Detail")
```

### Example: Detail Screen (SC-15, SC-16)
```
Screen
├─ Hero Section (Image + Metrics)
├─ Tab Bar (Overview, Details, Analytics)
├─ Content per Tab
│  ├─ Overview: Key facts, Chips, Ratings
│  ├─ Details: Table or List Items
│  └─ Analytics: Charts
├─ Related Items Section
│  └─ List Item (with trailing icon)
└─ Bottom Navigation (module tabs)
```

---

## Component Deprecation Policy

- **Never break existing usage** — add variants before removing
- **Announce changes** — update this doc and CHANGELOG.md
- **Provide migration** — code example showing old → new pattern
- **Sunset period** — 2 weeks before removal, mark deprecated

---

## Related Documentation

- **Design Tokens:** DESIGN-TOKENS.md (colors, typography, spacing)
- **Terminology:** TERMINOLOGY.md (consistent naming)
- **UI/UX Concepts:** UI-UX-CONCEPT-INVENTORY.md (screen references)
- **Information Architecture:** INFORMATION-ARCHITECTURE.md (module flows)

---

**Version:** 1.0  
**Date:** 2026-07-13  
**Status:** ✅ COMPLETE  
**Maintained By:** Claude Code (Developer Agent)  
**Next Review:** 2026-08-13

