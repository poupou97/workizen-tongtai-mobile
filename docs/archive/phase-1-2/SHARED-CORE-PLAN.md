# Shared Core Package Refactoring Plan

## Kế Hoạch Tái Cấu Trúc Gói Cốt Lõi Dùng Chung

> **Define how to extract reusable packages from Hub for sharing between Hub and Tổng Tài.**

**Status:** 📋 DRAFT for Review  
**Phase:** 1B — Technology Planning  
**Owner:** Architecture Team  
**Date:** 2026-07-13

---

## English — Shared Core Package Refactoring Plan

### Executive Summary

**Current State:** Hub code is monolithic; reusable infrastructure (storage, AI, UI) is mixed with Hub-specific features.

**Desired State:** Clear package hierarchy with separated concerns:
- `shared/core/` — reusable foundation (storage, AI, UI components)
- `hub/` — Hub product (features, screens, business logic)
- `tongtai/` — Tổng Tài product (features, screens, business logic)

**Strategy:** 4-phase extraction plan, starting with Phase 1B (MVP preparation).

---

### Vision: One Codebase, Two Products

Both Hub and Tổng Tài share:
- **Same Flutter/Dart runtime**
- **Same database foundation** (SQLite + Drift)
- **Same AI infrastructure** (xAI + OpenRouter)
- **Same UI framework** (Material 3 + custom components)

They differ in:
- **Business logic** (documents vs. business operations)
- **Data models** (chats/outputs vs. inventory/customers)
- **Screens & flows** (Hub's home ≠ Tổng Tài's dashboard)

This separation allows:
- ✅ Fast MVP delivery (code reuse)
- ✅ Clear product boundaries (no feature bleed)
- ✅ Future split (move Tổng Tài to separate repo if needed)
- ✅ Independent scaling (different databases, schemas)

---

### Refactoring Phases

#### Phase 1B: Extract Core Packages (Weeks 1-3)

**Goal:** Identify and extract reusable packages into `shared/core/`.

**Packages to Create:**

**1. `shared/core/storage/`** — Local database layer
```
shared/core/storage/
├── sqlite_provider.dart       # SQLite initialization, migrations
├── drift_schema/
│   ├── database.dart          # Drift database definition
│   ├── schema_v1.dart         # Base schema (shared entities)
│   └── schema_extension.dart  # Extension pattern for product-specific schemas
├── models/
│   ├── base_entity.dart       # Base class for all entities
│   └── metadata.dart          # Common metadata (timestamps, encryption)
└── migrations/
    ├── migration_runner.dart
    └── v1_initial.dart
```

**Responsibilities:**
- Drift ORM setup (type-safe database)
- SQLite initialization & encryption
- Schema versioning & migrations
- Base classes for entities
- Transaction management

**Used by:** Hub, Tổng Tài

**Effort:** 1 week

---

**2. `shared/core/ai/`** — AI integration layer
```
shared/core/ai/
├── client/
│   ├── ai_client.dart         # Abstract AI client interface
│   ├── xai_client.dart        # xAI SDK implementation
│   ├── openrouter_client.dart # OpenRouter implementation
│   └── models/
│       ├── ai_model.dart      # Model definitions
│       ├── message.dart       # Chat message
│       └── response.dart      # AI response
├── streaming/
│   ├── stream_handler.dart    # Stream processing for chat
│   └── token_counter.dart     # Token counting & cost tracking
├── config/
│   ├── provider_config.dart   # Provider credentials (BYOK)
│   └── model_selector.dart    # Logic to pick best model for task
└── services/
    ├── chat_service.dart      # High-level chat API
    └── embedding_service.dart # Vector embeddings (future)
```

**Responsibilities:**
- Multi-provider support (xAI, OpenRouter, Claude, Ollama)
- Streaming chat responses
- Token counting & cost tracking
- BYOK credentials management
- Model selection logic (task → model mapping)

**Used by:** Hub (chat), Tổng Tài (copilot + opportunity detection)

**Effort:** 1.5 weeks (mostly refactoring existing Hub code)

---

**3. `shared/core/ui/`** — Reusable Flutter components
```
shared/core/ui/
├── components/
│   ├── card/
│   │   ├── card.dart          # Base card component
│   │   ├── metric_card.dart   # Card + KPI (metric + trend)
│   │   └── action_card.dart   # Card + action button
│   ├── button/
│   │   ├── primary_button.dart
│   │   ├── secondary_button.dart
│   │   └── icon_button.dart
│   ├── input/
│   │   ├── text_input.dart
│   │   ├── number_input.dart
│   │   ├── dropdown.dart
│   │   ├── date_picker.dart
│   │   └── multi_select.dart
│   ├── chart/
│   │   ├── line_chart.dart    # Revenue trends, etc.
│   │   ├── bar_chart.dart     # Category breakdown
│   │   ├── pie_chart.dart     # Composition
│   │   └── metric_chart.dart  # Small inline chart
│   ├── dialog/
│   │   ├── bottom_sheet.dart
│   │   ├── modal_dialog.dart
│   │   └── confirmation_dialog.dart
│   ├── list/
│   │   ├── list_item.dart
│   │   ├── list_section.dart
│   │   └── expandable_list.dart
│   ├── badges/
│   │   ├── status_badge.dart
│   │   ├── tag_badge.dart
│   │   └── count_badge.dart
│   ├── forms/
│   │   ├── form_builder.dart  # Dynamic form from schema
│   │   ├── form_group.dart
│   │   └── validation.dart
│   └── empty_state/
│       ├── empty_state.dart   # Empty state placeholder
│       └── error_state.dart   # Error UI
├── themes/
│   ├── app_theme.dart         # Material 3 theme
│   ├── color_scheme.dart      # Tổng Tài-specific colors (override base)
│   ├── typography.dart        # Font definitions
│   └── spacing.dart           # Padding/margin scale
├── animations/
│   ├── transitions.dart       # Page transitions
│   └── entrance_animations.dart
└── utils/
    ├── responsive.dart        # Responsive layout helpers
    └── accessibility.dart     # A11y utilities
```

**Responsibilities:**
- Base Flutter widgets (buttons, cards, forms, charts)
- Material 3 design system
- Light/dark mode theming
- Responsive layout
- Animations & transitions

**Used by:** Hub (all UI), Tổng Tài (all UI)

**Effort:** 1.5 weeks (mostly refactoring Hub UI)

---

**4. `shared/core/utils/`** — Common utilities
```
shared/core/utils/
├── logger/
│   ├── logger.dart            # Structured logging
│   └── analytics.dart         # Optional analytics (privacy-first)
├── validators/
│   ├── email_validator.dart
│   ├── phone_validator.dart
│   ├── amount_validator.dart
│   └── url_validator.dart
├── formatters/
│   ├── currency_formatter.dart
│   ├── date_formatter.dart
│   ├── number_formatter.dart
│   └── file_size_formatter.dart
├── extensions/
│   ├── string_extensions.dart
│   ├── date_extensions.dart
│   ├── number_extensions.dart
│   └── list_extensions.dart
└── errors/
    ├── app_exception.dart
    ├── error_handler.dart
    └── error_messages.dart
```

**Responsibilities:**
- String validation & formatting
- Date/currency/number formatting
- Error handling
- Logging & debugging

**Used by:** Hub, Tổng Tài

**Effort:** 0.5 week

---

**5. `shared/core/models/`** — Shared data models
```
shared/core/models/
├── user_preferences.dart      # Theme, language, notification settings
├── api_key_config.dart        # BYOK API key storage
├── app_config.dart            # Feature flags, version info
└── constants.dart             # App constants
```

**Responsibilities:**
- Cross-product user preferences
- API key management
- Feature flags
- Configuration

**Used by:** Hub, Tổng Tài

**Effort:** 0.5 week

---

**Phase 1B Deliverables:**
- [ ] Extract 5 core packages
- [ ] Write integration tests for each package
- [ ] Document APIs with examples
- [ ] Create internal package documentation
- [ ] Ensure Hub still builds & runs

**Estimated Effort:** 3 weeks
**Estimated Lines of Code Moved:** ~15K lines (existing Hub code)

---

#### Phase 1C: Product-Specific Separation (Weeks 4-5)

**Goal:** Separate Hub-specific and Tổng-Tài-specific code into product folders.

**Folder Structure:**
```
mobile/
├── shared/              ← Core packages (both products use)
│   ├── core/
│   │   ├── storage/
│   │   ├── ai/
│   │   ├── ui/
│   │   └── utils/
│   ├── services/        ← Shared services (Phase 2)
│   │   └── sync/
│   └── pubspec.yaml
├── hub/                 ← Hub product (ONLY Hub uses)
│   ├── screens/
│   ├── models/
│   ├── services/
│   ├── providers/       ← Riverpod providers
│   ├── main_hub.dart
│   └── pubspec.yaml     ← Depends on shared/core
├── tongtai/             ← Tổng Tài product (ONLY Tổng Tài uses)
│   ├── screens/
│   │   ├── home.dart
│   │   ├── producer.dart
│   │   ├── inventory.dart
│   │   ├── consumer.dart
│   │   ├── finance.dart
│   │   ├── reports.dart
│   │   ├── opportunity.dart
│   │   └── copilot.dart
│   ├── models/
│   │   ├── producer.dart
│   │   ├── inventory.dart
│   │   ├── consumer.dart
│   │   ├── order.dart
│   │   ├── finance.dart
│   │   ├── opportunity.dart
│   │   └── journey.dart
│   ├── services/
│   │   ├── producer_service.dart
│   │   ├── inventory_service.dart
│   │   ├── consumer_service.dart
│   │   ├── opportunity_service.dart
│   │   └── journey_service.dart
│   ├── providers/
│   └── main_tongtai.dart
├── app/                 ← App entry points & configuration
│   ├── main_hub.dart    ← Run Hub
│   ├── main_tongtai.dart ← Run Tổng Tài
│   └── pubspec.yaml
└── pubspec.yaml         ← Workspace root
```

**Refactoring:**
1. Move Hub-specific screens to `hub/screens/`
2. Move Tổng Tài-specific screens to `tongtai/screens/`
3. Create product-specific pubspec.yaml files
4. Create main entry points
5. Enforce dependency rules (see Dependency Architecture below)

**Dependency Rules:**
```
shared/core
  ↑
shared/services
  ↑
hub/  <-- hub depends on shared/core, shared/services ONLY
  ↑
tongtai/  <-- tongtai depends on shared/core, shared/services ONLY

❌ FORBIDDEN:
  hub → tongtai
  tongtai → hub
```

**Code Review Rule:** Commits that violate dependency rules are rejected.

**Estimated Effort:** 1 week

---

#### Phase 2 (Post-MVP): Shared Services (Weeks 8+)

**Goal:** Extract shared services layer for sync, backup, notifications.

**Packages:**
```
shared/services/
├── sync/
│   ├── sync_engine.dart       # Cloud sync orchestrator
│   ├── sync_strategy.dart     # Diff-merge strategy
│   └── conflict_resolver.dart # Handle version conflicts
├── backup/
│   ├── backup_engine.dart     # Backup/restore
│   ├── encryption.dart        # Backup encryption
│   └── cloud_providers/
│       ├── google_drive.dart
│       └── icloud.dart
├── notifications/
│   ├── notification_service.dart
│   ├── local_notifications.dart
│   └── push_notifications.dart  # Firebase Cloud Messaging
└── updates/
    ├── app_updater.dart       # Auto-update checker
    └── version_manager.dart
```

**Used by:** Hub (optional), Tổng Tài (optional Phase 2+)

**Note:** These are opt-in features; MVP doesn't require them.

---

#### Phase 3 (Future): Plugin Architecture

**Goal:** Enable third-party integrations (invoicing, payment, shipping).

```
shared/plugins/
├── plugin_interface.dart      # Abstract plugin
├── plugin_loader.dart         # Plugin discovery & loading
└── built_in_plugins/
    ├── stripe_plugin.dart
    ├── shopify_plugin.dart
    └── zapier_plugin.dart
```

---

### Package Management Strategy

#### Within MVP (Phase 1B-1C)
- All packages in single Git repo (`mobile/`)
- Use relative imports: `import 'package:shared_core/storage/sqlite_provider.dart'`
- Single `pubspec.yaml` at workspace root

#### Post-MVP (Phase 2)
- **Option A (Recommended):** Publish `shared_core`, `shared_services` to **internal pub server** (Nexus/Artifactory)
  - Hub depends on: `pub.workizen.internal/shared_core`
  - Tổng Tài depends on: `pub.workizen.internal/shared_core`
  - Easier to version & distribute across repos

- **Option B:** Keep monorepo, split repos later
  - If Tổng Tài repo spins off: depends on private Git dependency
  - Still allows independent development

**Recommendation:** Go with Option A (internal pub) for scalability.

---

### Build Configuration

#### Multi-Target Build (Phase 1B-1C)

**Run Hub:**
```bash
flutter run -t lib/main_hub.dart
```

**Run Tổng Tài:**
```bash
flutter run -t lib/main_tongtai.dart
```

**Or using Gradle flavors (Android):**
```bash
flutter run --flavor hub -t lib/main_hub.dart
flutter run --flavor tongtai -t lib/main_tongtai.dart
```

#### Build Release (Phase 1B-1C)

**Hub APK:**
```bash
flutter build apk -t lib/main_hub.dart --release
```

**Tổng Tài APK:**
```bash
flutter build apk -t lib/main_tongtai.dart --release
```

**Hub AAB (for Play Store):**
```bash
flutter build appbundle -t lib/main_hub.dart --release
```

**Tổng Tài AAB (for Play Store):**
```bash
flutter build appbundle -t lib/main_tongtai.dart --release
```

---

### Testing Strategy

**Unit Tests:**
- `test/shared/core/storage_test.dart` — Test SQLite migrations
- `test/shared/core/ai_test.dart` — Test AI client, streaming
- `test/shared/core/ui_test.dart` — Widget tests for components
- `test/hub/services_test.dart` — Hub-specific business logic
- `test/tongtai/services_test.dart` — Tổng Tài-specific business logic

**Integration Tests:**
- `integration_test/hub_flow_test.dart` — End-to-end Hub flow
- `integration_test/tongtai_flow_test.dart` — End-to-end Tổng Tài flow

**No Cross-Product Tests:**
- Don't test Hub features when running Tổng Tài build
- Separate test suites per product

---

### Deliverables by Phase

| Phase | Deliverable | Effort | Date |
|---|---|---|---|
| **1B** | Core packages extracted (storage, AI, UI, utils) | 3 weeks | 2026-07-27 |
| **1C** | Product separation (hub/, tongtai/ folders) | 1 week | 2026-08-03 |
| **1C** | Build & test both products independently | 1 week | 2026-08-10 |
| **2** | Shared services (sync, backup) | TBD | Post-MVP |
| **2+** | Publish to internal pub server | TBD | Post-MVP |

---

### Isolation Enforcement

**Code Review Checklist:**
- ✅ New code in `shared/core/` uses zero product imports
- ✅ Hub code imports only from `shared/` and `hub/`
- ✅ Tổng Tài code imports only from `shared/` and `tongtai/`
- ✅ No cross-product imports (hub ← → tongtai)

**Automated CI Check:**
```bash
# Fail build if violation detected
dart pub deps --no-dev | grep -E "hub.*tongtai|tongtai.*hub" && exit 1
```

---

### Risk Mitigation

| Risk | Mitigation |
|---|---|
| **Breaking change in shared package** | Versioning + changelog + deprecation warnings |
| **Diff sync conflicts** | Start with offline (no sync) in MVP |
| **Performance regression** | Benchmark shared/ vs. monolith in Phase 1C |
| **Feature bleed (Hub → Tổng Tài)** | Code review + CI checks |

---

## Tiếng Việt — Kế Hoạch Tái Cấu Trúc Gói Cốt Lõi Dùng Chung

### Tóm Tắt Điều Hành

**Trạng Thái Hiện Tại:** Mã Hub là một khối; cơ sở hạ tầng có thể tái sử dụng (lưu trữ, AI, UI) được trộn lẫn với các tính năng riêng của Hub.

**Trạng Thái Mong Muốn:** Hệ thống phân cấp gói rõ ràng với các vấn đề được tách biệt:
- `shared/core/` — nền tảng có thể tái sử dụng (lưu trữ, AI, thành phần UI)
- `hub/` — sản phẩm Hub (tính năng, màn hình, logic kinh doanh)
- `tongtai/` — sản phẩm Tổng Tài (tính năng, màn hình, logic kinh doanh)

**Chiến Lược:** Kế hoạch trích xuất 4 giai đoạn, bắt đầu từ Phase 1B (chuẩn bị MVP).

---

### Tầm Nhìn: Một Cơ Sở Mã, Hai Sản Phẩm

Hub và Tổng Tài chia sẻ:
- **Cùng runtime Flutter/Dart**
- **Cùng nền tảng cơ sở dữ liệu** (SQLite + Drift)
- **Cùng cơ sở hạ tầng AI** (xAI + OpenRouter)
- **Cùng khung UI** (Material 3 + thành phần tùy chỉnh)

Chúng khác nhau ở:
- **Logic kinh doanh** (tài liệu vs. hoạt động kinh doanh)
- **Mô hình dữ liệu** (trò chuyện/đầu ra vs. tồn kho/khách hàng)
- **Màn hình & luồng** (trang chủ Hub ≠ bảng điều khiển Tổng Tài)

Sự tách biệt này cho phép:
- ✅ Phân phối MVP nhanh chóng (tái sử dụng mã)
- ✅ Ranh giới sản phẩm rõ ràng (không bị tính năng len lỏi)
- ✅ Chia tách trong tương lai (chuyển Tổng Tài đến kho riêng nếu cần)
- ✅ Mở rộng độc lập (cơ sở dữ liệu khác nhau, lược đồ)

---

### Giai Đoạn Tái Cấu Trúc

#### Giai Đoạn 1B: Trích Xuất Gói Cốt Lõi (Tuần 1-3)

[Chi tiết như ở trên trong tiếng Anh — tóm tắt:]

**Gói để Tạo:**
1. **`shared/core/storage/`** — Lớp cơ sở dữ liệu cục bộ (Drift + SQLite)
2. **`shared/core/ai/`** — Lớp tích hợp AI (xAI + OpenRouter)
3. **`shared/core/ui/`** — Thành phần Flutter có thể tái sử dụng
4. **`shared/core/utils/`** — Tiện ích chung (định dạng, xác thực)
5. **`shared/core/models/`** — Mô hình dữ liệu dùng chung

**Nỗ Lực Ước Tính:** 3 tuần  
**Dòng Mã Để Di Chuyển:** ~15K dòng (mã Hub hiện tại)

---

#### Giai Đoạn 1C: Tách Biệt Đặc Thù Sản Phẩm (Tuần 4-5)

[Tương tự chi tiết tiếng Anh]

**Cấu Trúc Thư Mục:**
```
mobile/
├── shared/           ← Gói cốt lõi (cả hai sản phẩm sử dụng)
├── hub/              ← Sản phẩm Hub (CHỈ Hub sử dụng)
├── tongtai/          ← Sản phẩm Tổng Tài (CHỈ Tổng Tài sử dụng)
└── app/              ← Điểm nhập app
```

---

#### Giai Đoạn 2 (Sau MVP): Dịch Vụ Dùng Chung

Dịch vụ được chia sẻ cho đồng bộ hóa, sao lưu, thông báo.

---

### Kiểm Soát Cảnh Báo Được Thực Thi

**Quy Tắc Xem Xét Mã:**
- ✅ Mã mới trong `shared/core/` không sử dụng nhập sản phẩm
- ✅ Mã Hub chỉ nhập từ `shared/` và `hub/`
- ✅ Mã Tổng Tài chỉ nhập từ `shared/` và `tongtai/`
- ✅ Không nhập chéo sản phẩm (hub ← → tongtai)

---

**Version:** 1.0 (Draft)  
**Next Review:** After fit-gap analysis is approved
