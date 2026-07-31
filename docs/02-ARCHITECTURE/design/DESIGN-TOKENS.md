# Design Tokens

## Token Thiết Kế

---

## English — Color System

### Domain-Driven Color Palette

Each business module has a primary color identity to aid visual navigation and mental mapping.

| Module | English | Tiếng Việt | Primary Color | Hex | Use Case |
|---|---|---|---|---|---|
| **Producer** | Business Sourcing | Nguồn Hàng | Green | `#10B981` | Opportunity discovery, supplier network |
| **Inventory** | Product & Warehouse | Tồn Kho | Orange | `#F59E0B` | Inventory management, stock alerts |
| **Consumer** | Customer Intelligence | Khách Hàng | Blue | `#3B82F6` | CRM, customer data, segments |
| **Finance** | Accounting & Cash | Tài Chính | Purple | `#8B5CF6` | Revenue, expenses, profit, cash flow |
| **Reports** | Analytics & Insights | Báo Cáo | Indigo | `#6366F1` | KPIs, charts, trends |
| **Business Journey** | Goal Orchestration | Hành Trình | Gold | `#FBBF24` | Journey progress, milestones |
| **AI Copilot** | AI Assistant | AI Tổng Tài | Violet | `#A78BFA` | Recommendations, alerts, guidance |
| **Document Intelligence** | AI Analysis | Document AI | Cyan | `#06B6D4` | Document scanning, OCR, extraction |
| **Integration** | System Integration | Integration | Teal | `#14B8A6` | Connectors, webhooks, APIs |
| **Business Setup** | Configuration | Cài Đặt | Gray | `#6B7280` | Settings, admin, configuration |

### ⚠️ Màu trên là màu NỀN — không mặc nhiên là màu CHỮ (WTM-168, 2026-07-31)

Đo bằng `textContrastGuideline`: trên nền sáng `#10B981` đọc ở **2.31:1** và
`#F59E0B` ở **2.15:1**; WCAG AA cần **4.5:1**. Các màu ở bước -500 dùng cho
**nền · viền · icon · biểu đồ**; khi cùng màu đó mang **chữ**, dùng **cặp song
sinh đọc được** ở bước -700 (`TongtaiDesignTokens.producerGreenText` … hoặc
`readableText(base)` cho component dùng chung):

| vai trò | nền (-500) | chữ (-700) | tỉ lệ trên trắng |
|---|---|---|---|
| Producer / Success | `#10B981` | `#047857` | 5.48 |
| Inventory / Warning | `#F59E0B` | `#B45309` | 5.02 |
| Consumer / Info | `#3B82F6` | `#1D4ED8` | 6.70 |
| Finance / Copilot | `#8B5CF6` | `#6D28D9` | 7.10 |
| Error | `#EF4444` | `#B91C1C` | 6.47 |
| Neutral / Setup | `#6B7280` | `#4B5563` | 7.56 |

**Bảng màu thương hiệu không đổi** — chỉ chỗ có chữ mới phải đọc được.

### Color Hierarchy

#### Primary Colors (Module Identity)
```
Producer (Green):     #10B981
Inventory (Orange):   #F59E0B
Consumer (Blue):      #3B82F6
Finance (Purple):     #8B5CF6
Reports (Indigo):     #6366F1
Journey (Gold):       #FBBF24
AI Copilot (Violet):  #A78BFA
Document (Cyan):      #06B6D4
Integration (Teal):   #14B8A6
Setup (Gray):         #6B7280
```

#### Semantic Colors
```
Success:    #10B981 (Green)
Warning:    #F59E0B (Orange)
Error:      #EF4444 (Red)
Info:       #3B82F6 (Blue)
Neutral:    #6B7280 (Gray)
```

#### Background & Text
```
Background:       #FFFFFF (Light) / #111827 (Dark)
Text Primary:     #111827 (Light) / #F9FAFB (Dark)
Text Secondary:   #4B5563 (Light) / #D1D5DB (Dark)   ← gray-600 từ WTM-168
Border:           #E5E7EB (Light) / #374151 (Dark)
Hover:            #F3F4F6 (Light) / #1F2937 (Dark)
```

### Using Domain Colors

**Rule:** Each screen tab or card uses its module's primary color for:
- Tab underline
- Icon color
- Progress bar
- Quick action button
- Status indicator

**Example:**
```
Producer Tab:     Green underline + green icons
Inventory Tab:    Orange underline + orange icons
Consumer Tab:     Blue underline + blue icons
Finance Tab:      Purple underline + purple icons
```

---

## Tiếng Việt — Hệ Thống Màu Sắc

### Bảng Màu Theo Miền

Mỗi mô-đun kinh doanh có bản sắc màu chính để hỗ trợ điều hướng hình ảnh và lập bản đồ tinh thần.

Xem bảng tiếng Anh ở trên cho chi tiết.

---

## Typography

### Font Families

```
Heading:  System Font (SF Pro Display / Roboto)
Body:     System Font (SF Pro Text / Roboto)
Mono:     SF Mono / Roboto Mono
```

### Type Scale

```
Display:   32px, 700, Line 40px  (Rare: major headings)
Heading 1: 28px, 700, Line 34px  (Screen titles)
Heading 2: 24px, 600, Line 32px  (Section titles)
Heading 3: 20px, 600, Line 28px  (Card titles)
Body:      16px, 400, Line 24px  (Standard text)
Small:     14px, 400, Line 20px  (Labels, secondary)
Caption:   12px, 400, Line 16px  (Hints, meta)
```

---

## Spacing Scale

```
0 px   (0)
4 px   (1 unit)
8 px   (2 units)
12 px  (3 units)
16 px  (4 units)  ← Standard
20 px  (5 units)
24 px  (6 units)
32 px  (8 units)
40 px  (10 units)
48 px  (12 units)
```

**Rule:** Use 4px-based spacing. Padding, margin, gap use multiples of 4.

---

## Component Tokens

### Card
```
Background:    White (#FFFFFF) / Dark (#1F2937)
Border:        1px solid #E5E7EB / #374151
Border Radius: 12px
Padding:       16px
Box Shadow:    0 1px 3px rgba(0,0,0,0.1)
```

### Button
```
Padding:       12px 16px
Border Radius: 8px
Font Weight:   600
Font Size:     14px
Height:        44px (touch target)
```

### Input
```
Padding:       12px 16px
Border Radius: 8px
Border:        1px solid #E5E7EB / #374151
Height:        48px
Font Size:     16px
```

### Badge
```
Padding:       4px 8px
Border Radius: 4px
Font Size:     12px
Font Weight:   600
```

---

**Version:** 1.0  
**Status:** ✅ Locked  
**Next:** COMPONENT-LIBRARY.md

